/**
 * @description Field Service skills for the GPTfy Agent Library (work orders, appointments, resources).
 * @author      : Plumcloud Labs
 * @group       : GPTfy Agent Library
 * @jira        : V2-8418
 */
global with sharing class FieldServiceAgenticSkillsHandler implements ccai.AIAgenticInterface {

    private static final String WO_OBJ = 'WorkOrder';
    private static final String SA_OBJ = 'ServiceAppointment';
    private static final String SR_OBJ = 'ServiceResource';

    global String executeMethod(String methodName, Map<String, Object> parameters) {
        try {
            if (parameters == null) parameters = new Map<String, Object>();
            String m = String.isBlank(methodName) ? '' : methodName.trim();
            switch on m {
                when 'fetch_work_order_details'           { return handleFetchWorkOrderDetails(parameters); }
                when 'create_work_order'                 { return handleCreateWorkOrder(parameters); }
                when 'update_work_order_fields'          { return handleUpdateWorkOrderFields(parameters); }
                when 'fetch_service_appointment'         { return handleFetchServiceAppointment(parameters); }
                when 'schedule_service_appointment'      { return handleScheduleServiceAppointment(parameters); }
                when 'update_service_appointment'      { return handleUpdateServiceAppointment(parameters); }
                when 'fetch_service_resource_availability' { return handleFetchServiceResourceAvailability(parameters); }
                when else { return AgenticSkillsBase.errorJson('Unsupported skill: ' + methodName); }
            }
        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'FieldServiceAgenticSkillsHandler | ' + methodName + ' | ' + ex.getMessage());
            return AgenticSkillsBase.errorJson(ex.getMessage());
        }
    }

    private static Schema.SObjectType resolveType(String apiName) {
        Schema.SObjectType sot = Schema.getGlobalDescribe().get(apiName);
        return (sot != null && sot.getDescribe().isAccessible()) ? sot : null;
    }

    private String handleFetchWorkOrderDetails(Map<String, Object> p) {
        Schema.SObjectType sot = resolveType(WO_OBJ);
        if (sot == null) return AgenticSkillsBase.errorJson('Field Service WorkOrder object is not available in this org.');
        String woid = AgenticSkillsBase.toText(AgenticSkillsBase.firstNonNull(p, new List<String>{ 'work_order_id', 'recordId', 'Id' }));
        if (String.isBlank(woid)) return AgenticSkillsBase.errorJson('Missing required parameter: work_order_id');
        Map<String, Schema.SObjectField> fmap = sot.getDescribe().fields.getMap();
        List<String> fields = new List<String>{ 'Id', 'WorkOrderNumber', 'Subject', 'Status', 'Priority', 'AccountId', 'ContactId' };
        for (String f : new List<String>{ 'AssetId', 'Description', 'StartDate', 'EndDate', 'ServiceTerritoryId' }) {
            if (fmap.containsKey(f)) fields.add(f);
        }
        String soql = 'SELECT ' + String.join(fields, ', ') + ' FROM WorkOrder WHERE Id = :woid WITH USER_MODE LIMIT 1';
        List<SObject> rows = Database.query(soql);
        if (rows.isEmpty()) return AgenticSkillsBase.errorJson('No work order found for provided Id.');
        SObject wo = rows[0];
        Map<String, Object> result = new Map<String, Object>{ 'recordUrl' => AgenticSkillsBase.recordUrl((Id) wo.get('Id')) };
        for (String f : fields) result.put(f, wo.get(f));
        return AgenticSkillsBase.successJson(result);
    }

    private String handleCreateWorkOrder(Map<String, Object> p) {
        Schema.SObjectType sot = Schema.getGlobalDescribe().get(WO_OBJ);
        if (sot == null || !sot.getDescribe().isCreateable()) {
            return AgenticSkillsBase.errorHtml('Could not create work order', 'WorkOrder is not available or creatable in this org.');
        }
        Map<String, Object> fields = AgenticSkillsBase.buildFieldMap(p, null);
        Map<String, Schema.SObjectField> fmap = sot.getDescribe().fields.getMap();
        Boolean hasSubject = fields.containsKey('Subject') && String.isNotBlank(AgenticSkillsBase.toText(fields.get('Subject')));
        if (!hasSubject) return AgenticSkillsBase.errorHtml('Could not create work order', 'Subject is required.');
        try {
            SObject wo = sot.newSObject();
            AgenticSkillsBase.applyFieldsToSObject(wo, fields, false);
            insert wo;
            String label = fmap.containsKey('WorkOrderNumber') ? String.valueOf(wo.get('WorkOrderNumber')) : String.valueOf(fields.get('Subject'));
            String body = '<ul><li><b>Subject:</b> ' + AgenticSkillsBase.escapeHtml(String.valueOf(fields.get('Subject'))) + '</li></ul>';
            return AgenticSkillsBase.successHtml('Work Order Created', body, (Id) wo.get('Id'), 'View Work Order');
        } catch (Exception ex) {
            return AgenticSkillsBase.errorHtml('Could not create work order', ex.getMessage());
        }
    }

    private String handleUpdateWorkOrderFields(Map<String, Object> p) {
        Schema.SObjectType sot = Schema.getGlobalDescribe().get(WO_OBJ);
        if (sot == null || !sot.getDescribe().isUpdateable()) {
            return AgenticSkillsBase.errorHtml('Could not update work order', 'WorkOrder is not updateable in this org.');
        }
        String woid = AgenticSkillsBase.toText(AgenticSkillsBase.firstNonNull(p, new List<String>{ 'work_order_id', 'recordId', 'Id' }));
        if (String.isBlank(woid)) return AgenticSkillsBase.errorHtml('Could not update work order', 'Missing parameter: work_order_id');
        Map<String, Object> fields = AgenticSkillsBase.buildFieldMap(p, new Set<String>{ 'work_order_id', 'recordId', 'Id' });
        if (fields.isEmpty()) return AgenticSkillsBase.errorHtml('Could not update work order', 'Missing parameter: at least one field to update');
        List<SObject> rows = Database.query('SELECT Id, Subject, WorkOrderNumber FROM WorkOrder WHERE Id = :woid WITH USER_MODE LIMIT 1');
        if (rows.isEmpty()) return AgenticSkillsBase.errorHtml('Could not update work order', 'No work order found for provided Id.');
        String label = String.valueOf(rows[0].get('Subject'));
        if (String.isBlank(label)) label = String.valueOf(rows[0].get('WorkOrderNumber'));
        return AgenticSkillsBase.performGenericUpdate(WO_OBJ, woid, fields, 'Work Order Updated', 'View Work Order', label);
    }

    private String handleFetchServiceAppointment(Map<String, Object> p) {
        Schema.SObjectType sot = resolveType(SA_OBJ);
        if (sot == null) return AgenticSkillsBase.errorJson('ServiceAppointment object is not available in this org.');
        String said = AgenticSkillsBase.toText(AgenticSkillsBase.firstNonNull(p, new List<String>{ 'service_appointment_id', 'appointment_id', 'recordId', 'Id' }));
        if (String.isBlank(said)) return AgenticSkillsBase.errorJson('Missing required parameter: service_appointment_id');
        Map<String, Schema.SObjectField> fmap = sot.getDescribe().fields.getMap();
        List<String> fields = new List<String>{ 'Id', 'AppointmentNumber', 'Subject', 'Status', 'SchedStartTime', 'SchedEndTime' };
        for (String f : new List<String>{ 'ParentRecordId', 'ServiceTerritoryId', 'Description', 'EarliestStartTime', 'DueDate' }) {
            if (fmap.containsKey(f)) fields.add(f);
        }
        String soql = 'SELECT ' + String.join(fields, ', ') + ' FROM ServiceAppointment WHERE Id = :said WITH USER_MODE LIMIT 1';
        List<SObject> rows = Database.query(soql);
        if (rows.isEmpty()) return AgenticSkillsBase.errorJson('No service appointment found for provided Id.');
        SObject sa = rows[0];
        Map<String, Object> result = new Map<String, Object>{ 'recordUrl' => AgenticSkillsBase.recordUrl((Id) sa.get('Id')) };
        for (String f : fields) result.put(f, sa.get(f));
        return AgenticSkillsBase.successJson(result);
    }

    private String handleScheduleServiceAppointment(Map<String, Object> p) {
        Schema.SObjectType sot = Schema.getGlobalDescribe().get(SA_OBJ);
        if (sot == null || !sot.getDescribe().isCreateable()) {
            return AgenticSkillsBase.errorHtml('Could not schedule appointment', 'ServiceAppointment is not available or creatable in this org.');
        }
        Map<String, Object> fields = AgenticSkillsBase.buildFieldMap(p, null);
        if (!fields.containsKey('ParentRecordId') || AgenticSkillsBase.isBlankish(fields.get('ParentRecordId'))) {
            return AgenticSkillsBase.errorHtml('Could not schedule appointment', 'ParentRecordId (work order or other parent) is required.');
        }
        if (!fields.containsKey('SchedStartTime') || AgenticSkillsBase.isBlankish(fields.get('SchedStartTime'))) {
            return AgenticSkillsBase.errorHtml('Could not schedule appointment', 'SchedStartTime is required.');
        }
        if (!fields.containsKey('SchedEndTime') || AgenticSkillsBase.isBlankish(fields.get('SchedEndTime'))) {
            return AgenticSkillsBase.errorHtml('Could not schedule appointment', 'SchedEndTime is required.');
        }
        try {
            SObject sa = sot.newSObject();
            if (!fields.containsKey('Status') || AgenticSkillsBase.isBlankish(fields.get('Status'))) {
                fields.put('Status', 'Scheduled');
            }
            AgenticSkillsBase.applyFieldsToSObject(sa, fields, false);
            insert sa;
            String body = '<ul><li><b>Start:</b> ' + AgenticSkillsBase.escapeHtml(String.valueOf(fields.get('SchedStartTime'))) + '</li>'
                        + '<li><b>End:</b> ' + AgenticSkillsBase.escapeHtml(String.valueOf(fields.get('SchedEndTime'))) + '</li></ul>';
            return AgenticSkillsBase.successHtml('Service Appointment Scheduled', body, (Id) sa.get('Id'), 'View Appointment');
        } catch (Exception ex) {
            return AgenticSkillsBase.errorHtml('Could not schedule appointment', ex.getMessage());
        }
    }

    private String handleUpdateServiceAppointment(Map<String, Object> p) {
        Schema.SObjectType sot = Schema.getGlobalDescribe().get(SA_OBJ);
        if (sot == null || !sot.getDescribe().isUpdateable()) {
            return AgenticSkillsBase.errorHtml('Could not update appointment', 'ServiceAppointment is not updateable in this org.');
        }
        String said = AgenticSkillsBase.toText(AgenticSkillsBase.firstNonNull(p, new List<String>{ 'service_appointment_id', 'appointment_id', 'recordId', 'Id' }));
        if (String.isBlank(said)) return AgenticSkillsBase.errorHtml('Could not update appointment', 'Missing parameter: service_appointment_id');
        Map<String, Object> fields = AgenticSkillsBase.buildFieldMap(p, new Set<String>{ 'service_appointment_id', 'appointment_id', 'recordId', 'Id' });
        if (fields.isEmpty()) return AgenticSkillsBase.errorHtml('Could not update appointment', 'Missing parameter: at least one field to update');
        List<SObject> rows = Database.query('SELECT Id, Subject, AppointmentNumber FROM ServiceAppointment WHERE Id = :said WITH USER_MODE LIMIT 1');
        if (rows.isEmpty()) return AgenticSkillsBase.errorHtml('Could not update appointment', 'No appointment found for provided Id.');
        String label = String.valueOf(rows[0].get('Subject'));
        if (String.isBlank(label)) label = String.valueOf(rows[0].get('AppointmentNumber'));
        return AgenticSkillsBase.performGenericUpdate(SA_OBJ, said, fields, 'Appointment Updated', 'View Appointment', label);
    }

    private String handleFetchServiceResourceAvailability(Map<String, Object> p) {
        Schema.SObjectType srType = resolveType(SR_OBJ);
        if (srType == null) return AgenticSkillsBase.errorJson('ServiceResource object is not available in this org.');
        Datetime startDt = parseDatetimeParam(p, 'StartDate', 'start_datetime');
        if (startDt == null) startDt = parseDatetimeParam(p, 'start_date', 'StartDateTime');
        Datetime endDt = parseDatetimeParam(p, 'EndDate', 'end_datetime');
        if (endDt == null) endDt = parseDatetimeParam(p, 'end_date', 'EndDateTime');
        if (startDt == null) startDt = Datetime.now();
        if (endDt == null) endDt = startDt.addDays(7);
        Integer lim = 50;
        Object lRaw = p.get('limit');
        if (lRaw != null && String.isNotBlank(AgenticSkillsBase.toText(lRaw))) {
            try { lim = Integer.valueOf(AgenticSkillsBase.toText(lRaw)); } catch (Exception e) { lim = 50; }
        }
        lim = Math.max(1, Math.min(lim, 200));
        Map<String, Schema.SObjectField> fmap = srType.getDescribe().fields.getMap();
        List<String> fields = new List<String>{ 'Id', 'Name', 'IsActive', 'ResourceType' };
        if (fmap.containsKey('RelatedRecordId')) fields.add('RelatedRecordId');
        Id resourceFilter = AgenticSkillsBase.resolvePrimaryId(p, 'ServiceResource');
        if (resourceFilter == null) {
            resourceFilter = AgenticSkillsBase.resolveLookupId(p, 'ServiceResourceId');
        }
        String srSoql = 'SELECT ' + String.join(fields, ', ') + ' FROM ServiceResource WHERE IsActive = true';
        if (resourceFilter != null) {
            srSoql += ' AND Id = :resourceFilter';
        }
        srSoql += ' WITH USER_MODE ORDER BY Name ASC LIMIT :lim';
        List<SObject> resources = Database.query(srSoql);
        Set<Id> resourceIds = new Set<Id>();
        for (SObject r : resources) resourceIds.add((Id) r.get('Id'));
        Map<Id, List<Map<String, Object>>> busyByResource = new Map<Id, List<Map<String, Object>>>();
        Schema.SObjectType saType = resolveType(SA_OBJ);
        if (saType != null && !resourceIds.isEmpty() && Schema.getGlobalDescribe().containsKey('AssignedResource')) {
            try {
                String apptSoql = 'SELECT Id, ServiceResourceId, ServiceAppointmentId, ServiceAppointment.SchedStartTime,'
                                + ' ServiceAppointment.SchedEndTime, ServiceAppointment.Status'
                                + ' FROM AssignedResource WHERE ServiceResourceId IN :resourceIds'
                                + ' AND ServiceAppointment.SchedStartTime <= :endDt AND ServiceAppointment.SchedEndTime >= :startDt'
                                + ' WITH USER_MODE LIMIT 500';
                for (SObject ar : Database.query(apptSoql)) {
                    Id srId = (Id) ar.get('ServiceResourceId');
                    if (!busyByResource.containsKey(srId)) busyByResource.put(srId, new List<Map<String, Object>>());
                    SObject appt = ar.getSObject('ServiceAppointment');
                    busyByResource.get(srId).add(new Map<String, Object>{
                        'appointmentId' => ar.get('ServiceAppointmentId'),
                        'start' => appt != null ? String.valueOf(appt.get('SchedStartTime')) : null,
                        'end' => appt != null ? String.valueOf(appt.get('SchedEndTime')) : null,
                        'status' => appt != null ? appt.get('Status') : null
                    });
                }
            } catch (Exception e) {
                System.debug(LoggingLevel.WARN, 'AssignedResource query skipped: ' + e.getMessage());
            }
        }
        List<Map<String, Object>> rows = new List<Map<String, Object>>();
        for (SObject r : resources) {
            Id rid = (Id) r.get('Id');
            List<Map<String, Object>> conflicts = busyByResource.containsKey(rid) ? busyByResource.get(rid) : new List<Map<String, Object>>();
            rows.add(new Map<String, Object>{
                'Id' => rid, 'Name' => r.get('Name'), 'ResourceType' => r.get('ResourceType'),
                'IsActive' => r.get('IsActive'), 'RelatedRecordId' => r.get('RelatedRecordId'),
                'conflictCount' => conflicts.size(), 'conflicts' => conflicts,
                'likelyAvailable' => conflicts.isEmpty(),
                'recordUrl' => AgenticSkillsBase.recordUrl(rid)
            });
        }
        return AgenticSkillsBase.successJson(new Map<String, Object>{
            'windowStart' => String.valueOf(startDt), 'windowEnd' => String.valueOf(endDt),
            'count' => rows.size(), 'resources' => rows
        });
    }

    private Datetime parseDatetimeParam(Map<String, Object> p, String primary, String fallback) {
        String raw = AgenticSkillsBase.toText(AgenticSkillsBase.firstNonNull(p, new List<String>{ primary, fallback }));
        if (String.isBlank(raw)) return null;
        try { return Datetime.valueOfGmt(raw.replace('T', ' ').replace('Z', '')); } catch (Exception e) {}
        try { return Datetime.valueOf(raw); } catch (Exception e) {}
        Date d = AgenticSkillsBase.parseToDate(raw);
        return d != null ? Datetime.newInstance(d, Time.newInstance(0, 0, 0, 0)) : null;
    }
}
