/**
 * @description Activity object skills for the GPTfy Agent Library (7 skills).
 *              Implements ccai.AIAgenticInterface; shared helpers live in AgenticSkillsBase.
 * @author      : Plumcloud Labs
 * @group       : GPTfy Agent Library
 * @jira        : V2-8418
 */
global with sharing class ActivityAgenticSkillsHandler implements ccai.AIAgenticInterface {

    global String executeMethod(String methodName, Map<String, Object> parameters) {
        try {
            if (parameters == null) parameters = new Map<String, Object>();
            String m = String.isBlank(methodName) ? '' : methodName.trim();
            switch on m {
                when 'log_activity' { return handleLogActivity(parameters); }
                when 'create_task' { return handleCreateTask(parameters); }
                when 'update_task' { return handleUpdateTask(parameters); }
                when 'create_event' { return handleCreateEvent(parameters); }
                when 'update_event' { return handleUpdateEvent(parameters); }
                when 'fetch_my_open_tasks' { return handleFetchMyOpenTasks(parameters); }
                when 'complete_task' { return handleCompleteTask(parameters); }
                when else { return AgenticSkillsBase.errorJson('Unsupported skill: ' + methodName); }
            }
        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'ActivityAgenticSkillsHandler | ' + methodName + ' | ' + ex.getMessage());
            return AgenticSkillsBase.errorJson(ex.getMessage());
        }
    }

    /**
     * @description Skill — log_activity. Logs a completed Task on any CRM record.
     *              Sets WhoId for Contact/Lead; WhatId for Account/Opportunity/Case and others.
     * @jira V2-8418
     */
    private String handleLogActivity(Map<String, Object> p) {
        String subject = AgenticSkillsBase.toText(AgenticSkillsBase.firstNonBlank(p, new List<String>{
            'activity_subject', 'subject', 'Subject'
        }));
        String descr = AgenticSkillsBase.toText(AgenticSkillsBase.firstNonBlank(p, new List<String>{
            'activity_description', 'description', 'Description'
        }));
        if (String.isBlank(subject)) {
            return AgenticSkillsBase.errorHtml('Could not log activity', 'Missing the activity subject.');
        }
        if (!Schema.sObjectType.Task.isCreateable()) {
            return AgenticSkillsBase.errorHtml('Could not log activity', 'Task is not creatable.');
        }

        Id recordId = AgenticSkillsBase.resolveRelatedRecordId(p);
        if (recordId == null) {
            return AgenticSkillsBase.errorHtml(
                'Could not log activity',
                'Missing parent. Pass WhatId (Account/Opportunity/Case/…) or WhoId (Contact/Lead).'
            );
        }

        // Reject unusable Id types before DML (avoids vague INVALID_CROSS_REFERENCE_KEY)
        Boolean useWho = AgenticSkillsBase.isWhoIdObject(recordId);
        Boolean useWhat = !useWho && AgenticSkillsBase.isWhatIdObject(recordId);
        if (!useWho && !useWhat) {
            return AgenticSkillsBase.errorHtml(
                'Could not log activity',
                'Parent Id type is not supported for Tasks (WhoId/WhatId): ' + recordId.getSObjectType().getDescribe().getName()
            );
        }

        // Parent must exist and be visible — empty/wrong org Ids produce INVALID_CROSS_REFERENCE_KEY
        try {
            String objApi = recordId.getSObjectType().getDescribe().getName();
            List<SObject> parent = Database.query(
                'SELECT Id FROM ' + objApi + ' WHERE Id = :recordId WITH USER_MODE LIMIT 1'
            );
            if (parent.isEmpty()) {
                return AgenticSkillsBase.errorHtml(
                    'Could not log activity',
                    'No accessible ' + objApi + ' found for Id ' + String.valueOf(recordId) + '. Use a record Id from this org.'
                );
            }
        } catch (Exception ex) {
            return AgenticSkillsBase.errorHtml('Could not log activity', 'Could not verify parent record: ' + ex.getMessage());
        }

        try {
            Task t = new Task();
            t.Subject = subject;
            if (String.isNotBlank(descr)) t.Description = descr;
            t.Priority = 'Normal';
            t.ActivityDate = Date.today();
            // Prefer Completed; some orgs rename the status — fall back to first closed value
            t.Status = resolveCompletedTaskStatus();

            if (useWho) {
                t.WhoId = recordId;
            } else {
                t.WhatId = recordId;
            }
            insert t;
            return AgenticSkillsBase.successHtml(
                'Activity Logged: ' + subject,
                '<ul><li><b>Status:</b> ' + AgenticSkillsBase.escapeHtml(t.Status)
                    + '</li><li><b>Date:</b> '
                    + AgenticSkillsBase.escapeHtml(String.valueOf(Date.today())) + '</li></ul>',
                t.Id,
                'View Task'
            );
        } catch (Exception ex) {
            return AgenticSkillsBase.errorHtml('Could not log activity', ex.getMessage());
        }
    }

    /** Task Status API value for a completed activity (org picklist–safe). */
    private static String resolveCompletedTaskStatus() {
        try {
            Schema.DescribeFieldResult d = Task.Status.getDescribe();
            for (Schema.PicklistEntry pe : d.getPicklistValues()) {
                if (!pe.isActive()) continue;
                String v = pe.getValue();
                String lab = pe.getLabel();
                if (v != null && (v.equalsIgnoreCase('Completed') || (lab != null && lab.equalsIgnoreCase('Completed')))) {
                    return v;
                }
            }
            for (Schema.PicklistEntry pe : d.getPicklistValues()) {
                if (pe.isActive() && pe.isClosed()) return pe.getValue();
            }
        } catch (Exception e) {
            // fall through
        }
        return 'Completed';
    }

/**
     * @description Skill 29 — create_task on any record. Accepts Task field API
     *              names as flat top-level parameters (e.g. Subject, Status,
     *              Priority, ActivityDate, WhoId, WhatId, Description, …).
     *              Subject is required. The legacy nested { "fields": { … } }
     *              shape is still accepted for backward compatibility.
     * @jira V2-8418
     */
    private String handleCreateTask(Map<String, Object> p) {
        if (!Schema.sObjectType.Task.isCreateable()) return AgenticSkillsBase.errorHtml('Could not create task', 'Task is not creatable.');
        Map<String, Object> fields = AgenticSkillsBase.buildFieldMap(p, null);
        if (!fields.containsKey('Subject') || String.isBlank(AgenticSkillsBase.toText(fields.get('Subject')))) {
            return AgenticSkillsBase.errorHtml('Could not create task', 'Subject is required.');
        }
        try {
            Task t = new Task();
            AgenticSkillsBase.applyFieldsToSObject(t, fields, false);
            insert t;
            String body = '<ul><li><b>Subject:</b> ' + AgenticSkillsBase.escapeHtml(String.valueOf(fields.get('Subject'))) + '</li></ul>';
            return AgenticSkillsBase.successHtml('Task Created', body, t.Id, 'View Task');
        } catch (Exception ex) {
            return AgenticSkillsBase.errorHtml('Could not create task', ex.getMessage());
        }
    }

    /**
     * @description Skill 30 — create_event. Accepts Event field API names as
     *              flat top-level parameters (e.g. Subject, StartDateTime,
     *              EndDateTime, DurationInMinutes, WhoId, WhatId, Description, …).
     *              Subject and StartDateTime are required; DurationInMinutes
     *              defaults to 30 when neither EndDateTime nor DurationInMinutes
     *              is supplied. The legacy nested { "fields": { … } } shape is
     *              still accepted for backward compatibility.
     * @jira V2-8418
     */
    private String handleCreateEvent(Map<String, Object> p) {
        if (!Schema.sObjectType.Event.isCreateable()) return AgenticSkillsBase.errorHtml('Could not create event', 'Event is not creatable.');
        Map<String, Object> fields = AgenticSkillsBase.buildFieldMap(p, null);
        for (String required : new List<String>{ 'Subject', 'StartDateTime' }) {
            if (!fields.containsKey(required) || String.isBlank(AgenticSkillsBase.toText(fields.get(required)))) {
                return AgenticSkillsBase.errorHtml('Could not create event', required + ' is required.');
            }
        }
        try {
            Event e = new Event();
            if (!fields.containsKey('EndDateTime') && !fields.containsKey('DurationInMinutes')) {
                fields.put('DurationInMinutes', 30);
            }
            AgenticSkillsBase.applyFieldsToSObject(e, fields, false);
            insert e;
            String body = '<ul><li><b>Subject:</b> ' + AgenticSkillsBase.escapeHtml(String.valueOf(fields.get('Subject'))) + '</li></ul>';
            return AgenticSkillsBase.successHtml('Event Created', body, e.Id, 'View Event');
        } catch (Exception ex) {
            return AgenticSkillsBase.errorHtml('Could not create event', ex.getMessage());
        }
    }

    /**
     * @description Skill — update_task. Partial update on an open or completed Task.
     * @jira V2-8418
     */
    private String handleUpdateTask(Map<String, Object> p) {
        String tid = AgenticSkillsBase.toText(AgenticSkillsBase.firstNonNull(p, new List<String>{ 'task_id', 'recordId', 'Id' }));
        if (String.isBlank(tid)) return AgenticSkillsBase.errorHtml('Could not update task', 'Missing parameter: task_id');
        Map<String, Object> fields = AgenticSkillsBase.buildFieldMap(p, new Set<String>{ 'task_id', 'recordId', 'Id' });
        if (fields.isEmpty()) return AgenticSkillsBase.errorHtml('Could not update task', 'Missing parameter: at least one field to update');
        if (!Schema.sObjectType.Task.isUpdateable()) return AgenticSkillsBase.errorHtml('Could not update task', 'Task is not updateable.');
        List<Task> rows = [SELECT Id, Subject FROM Task WHERE Id = :tid WITH USER_MODE LIMIT 1];
        if (rows.isEmpty()) return AgenticSkillsBase.errorHtml('Could not update task', 'No task found for provided Id.');
        return AgenticSkillsBase.performGenericUpdate('Task', tid, fields, 'Task Updated', 'View Task', rows[0].Subject);
    }

    /**
     * @description Skill — update_event. Partial update on a calendar Event.
     * @jira V2-8418
     */
    private String handleUpdateEvent(Map<String, Object> p) {
        String eid = AgenticSkillsBase.toText(AgenticSkillsBase.firstNonNull(p, new List<String>{ 'event_id', 'recordId', 'Id' }));
        if (String.isBlank(eid)) return AgenticSkillsBase.errorHtml('Could not update event', 'Missing parameter: event_id');
        Map<String, Object> fields = AgenticSkillsBase.buildFieldMap(p, new Set<String>{ 'event_id', 'recordId', 'Id' });
        if (fields.isEmpty()) return AgenticSkillsBase.errorHtml('Could not update event', 'Missing parameter: at least one field to update');
        if (!Schema.sObjectType.Event.isUpdateable()) return AgenticSkillsBase.errorHtml('Could not update event', 'Event is not updateable.');
        List<Event> rows = [SELECT Id, Subject FROM Event WHERE Id = :eid WITH USER_MODE LIMIT 1];
        if (rows.isEmpty()) return AgenticSkillsBase.errorHtml('Could not update event', 'No event found for provided Id.');
        return AgenticSkillsBase.performGenericUpdate('Event', eid, fields, 'Event Updated', 'View Event', rows[0].Subject);
    }

    /**
     * @description Skill 31 — fetch_my_open_tasks.
     * @jira V2-8418
     */
    private String handleFetchMyOpenTasks(Map<String, Object> p) {
        if (!Schema.sObjectType.Task.isAccessible()) return AgenticSkillsBase.errorJson('Task is not accessible.');
        Integer lim = 25;
        Object lRaw = p.get('limit');
        if (lRaw != null && String.isNotBlank(AgenticSkillsBase.toText(lRaw))) {
            try { lim = Integer.valueOf(AgenticSkillsBase.toText(lRaw)); } catch (Exception e) { lim = 25; }
        }
        lim = Math.max(1, Math.min(lim, 200));
        Id me = UserInfo.getUserId();
        List<Task> tasks = [
            SELECT Id, Subject, Status, Priority, ActivityDate, WhatId, WhoId
            FROM Task WHERE OwnerId = :me AND IsClosed = false
            WITH USER_MODE ORDER BY ActivityDate ASC NULLS LAST LIMIT :lim
        ];
        List<Map<String, Object>> rows = new List<Map<String, Object>>();
        for (Task t : tasks) {
            rows.add(new Map<String, Object>{
                'Id' => t.Id, 'Subject' => t.Subject, 'Status' => t.Status,
                'Priority' => t.Priority, 'DueDate' => String.valueOf(t.ActivityDate),
                'WhatId' => t.WhatId, 'WhoId' => t.WhoId, 'recordUrl' => AgenticSkillsBase.recordUrl(t.Id)
            });
        }
        return AgenticSkillsBase.successJson(new Map<String, Object>{ 'count' => rows.size(), 'tasks' => rows });
    }

    /**
     * @description Skill 32 — complete_task (sets Status = Completed).
     * @jira V2-8418
     */
    private String handleCompleteTask(Map<String, Object> p) {
        String tid = AgenticSkillsBase.toText(AgenticSkillsBase.firstNonNull(p, new List<String>{ 'task_id', 'recordId', 'Id' }));
        if (String.isBlank(tid)) return AgenticSkillsBase.errorHtml('Could not complete task', 'Missing parameter: task_id');
        if (!Schema.sObjectType.Task.isUpdateable()) return AgenticSkillsBase.errorHtml('Could not complete task', 'Task is not updateable.');
        List<Task> rows = [SELECT Id, Subject, Status FROM Task WHERE Id = :tid WITH USER_MODE LIMIT 1];
        if (rows.isEmpty()) return AgenticSkillsBase.errorHtml('Could not complete task', 'No task found for provided Id.');
        try {
            update new Task(Id = tid, Status = 'Completed');
            return AgenticSkillsBase.successHtml('Task Completed', '<ul><li><b>Subject:</b> ' + AgenticSkillsBase.escapeHtml(rows[0].Subject) + '</li></ul>', tid, 'View Task');
        } catch (Exception ex) {
            return AgenticSkillsBase.errorHtml('Could not complete task', ex.getMessage());
        }
    }
}
