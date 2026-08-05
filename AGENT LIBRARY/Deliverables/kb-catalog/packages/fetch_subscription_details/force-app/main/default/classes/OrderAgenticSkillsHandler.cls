/**
 * @description Order & subscription skills for the GPTfy Agent Library.
 * @author      : Plumcloud Labs
 * @group       : GPTfy Agent Library
 * @jira        : V2-8418
 */
global with sharing class OrderAgenticSkillsHandler implements ccai.AIAgenticInterface {

    global String executeMethod(String methodName, Map<String, Object> parameters) {
        try {
            if (parameters == null) parameters = new Map<String, Object>();
            String m = String.isBlank(methodName) ? '' : methodName.trim();
            switch on m {
                when 'fetch_order_details'        { return handleFetchOrderDetails(parameters); }
                when 'create_order'               { return handleCreateOrder(parameters); }
                when 'update_order_fields'        { return handleUpdateOrderFields(parameters); }
                when 'add_order_item'             { return handleAddOrderItem(parameters); }
                when 'update_order_item'          { return handleUpdateOrderItem(parameters); }
                when 'fetch_subscription_details' { return handleFetchSubscriptionDetails(parameters); }
                when 'update_subscription_fields' { return handleUpdateSubscriptionFields(parameters); }
                when else { return AgenticSkillsBase.errorJson('Unsupported skill: ' + methodName); }
            }
        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'OrderAgenticSkillsHandler | ' + methodName + ' | ' + ex.getMessage());
            return AgenticSkillsBase.errorJson(ex.getMessage());
        }
    }

    private static String subscriptionObjectApi() {
        Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
        for (String candidate : new List<String>{ 'Subscription', 'SBQQ__Subscription__c' }) {
            if (gd.containsKey(candidate) && gd.get(candidate).getDescribe().isAccessible()) return candidate;
        }
        return null;
    }

    private String handleFetchOrderDetails(Map<String, Object> p) {
        String oid = AgenticSkillsBase.toText(AgenticSkillsBase.firstNonNull(p, new List<String>{ 'order_id', 'recordId', 'Id' }));
        if (String.isBlank(oid)) return AgenticSkillsBase.errorJson('Missing required parameter: order_id');
        if (!Schema.sObjectType.Order.isAccessible()) return AgenticSkillsBase.errorJson('Order is not accessible.');
        List<Order> rows = [
            SELECT Id, OrderNumber, Status, EffectiveDate, EndDate, TotalAmount, AccountId, Account.Name,
                   ContractId, Pricebook2Id, Type, Description
            FROM Order WHERE Id = :oid WITH USER_MODE LIMIT 1
        ];
        if (rows.isEmpty()) return AgenticSkillsBase.errorJson('No order found for provided Id.');
        Order o = rows[0];
        List<OrderItem> items = [
            SELECT Id, OrderItemNumber, Product2Id, Product2.Name, Quantity, UnitPrice, TotalPrice, ListPrice
            FROM OrderItem WHERE OrderId = :oid WITH USER_MODE ORDER BY OrderItemNumber ASC LIMIT 100
        ];
        List<Map<String, Object>> itemRows = new List<Map<String, Object>>();
        for (OrderItem oi : items) {
            itemRows.add(new Map<String, Object>{
                'Id' => oi.Id, 'OrderItemNumber' => oi.OrderItemNumber,
                'ProductName' => oi.Product2 != null ? oi.Product2.Name : null,
                'Quantity' => oi.Quantity, 'UnitPrice' => oi.UnitPrice, 'TotalPrice' => oi.TotalPrice
            });
        }
        return AgenticSkillsBase.successJson(new Map<String, Object>{
            'Id' => o.Id, 'OrderNumber' => o.OrderNumber, 'Status' => o.Status,
            'EffectiveDate' => String.valueOf(o.EffectiveDate), 'EndDate' => String.valueOf(o.EndDate),
            'TotalAmount' => o.TotalAmount, 'Account' => o.Account != null ? o.Account.Name : null,
            'ContractId' => o.ContractId, 'Type' => o.Type, 'Description' => o.Description,
            'itemCount' => itemRows.size(), 'items' => itemRows,
            'recordUrl' => AgenticSkillsBase.recordUrl(o.Id)
        });
    }

    private String handleCreateOrder(Map<String, Object> p) {
        if (!Schema.sObjectType.Order.isCreateable()) return AgenticSkillsBase.errorHtml('Could not create order', 'Order is not creatable.');
        Map<String, Object> fields = AgenticSkillsBase.buildFieldMap(p, new Set<String>{ 'Id', 'id', 'recordId', 'Name' });
        Id accountId = AgenticSkillsBase.resolveLookupId(p, 'AccountId');
        if (accountId != null) fields.put('AccountId', accountId);
        for (String required : new List<String>{ 'AccountId', 'EffectiveDate', 'Status' }) {
            if (!fields.containsKey(required) || AgenticSkillsBase.isBlankish(fields.get(required))) {
                return AgenticSkillsBase.errorHtml('Could not create order', required + ' is required.');
            }
        }
        if (!fields.containsKey('Pricebook2Id') || AgenticSkillsBase.isBlankish(fields.get('Pricebook2Id'))) {
            Id stdPb = Test.isRunningTest() ? Test.getStandardPricebookId() : [
                SELECT Id FROM Pricebook2 WHERE IsStandard = true WITH USER_MODE LIMIT 1
            ].Id;
            fields.put('Pricebook2Id', stdPb);
        }
        try {
            Order o = new Order();
            AgenticSkillsBase.applyFieldsToSObject(o, fields, false);
            insert o;
            String body = '<ul><li><b>Status:</b> ' + AgenticSkillsBase.escapeHtml(String.valueOf(fields.get('Status'))) + '</li>'
                        + '<li><b>Effective Date:</b> ' + AgenticSkillsBase.escapeHtml(String.valueOf(fields.get('EffectiveDate'))) + '</li></ul>';
            return AgenticSkillsBase.successHtml('Order Created', body, o.Id, 'View Order');
        } catch (Exception ex) {
            return AgenticSkillsBase.errorHtml('Could not create order', ex.getMessage());
        }
    }

    private String handleUpdateOrderFields(Map<String, Object> p) {
        String oid = AgenticSkillsBase.toText(AgenticSkillsBase.firstNonNull(p, new List<String>{ 'order_id', 'recordId', 'Id' }));
        if (String.isBlank(oid)) return AgenticSkillsBase.errorHtml('Could not update order', 'Missing parameter: order_id');
        Map<String, Object> fields = AgenticSkillsBase.buildFieldMap(p, new Set<String>{ 'order_id', 'recordId', 'Id' });
        if (fields.isEmpty()) return AgenticSkillsBase.errorHtml('Could not update order', 'Missing parameter: at least one field to update');
        if (!Schema.sObjectType.Order.isUpdateable()) return AgenticSkillsBase.errorHtml('Could not update order', 'Order is not updateable.');
        List<Order> rows = [SELECT Id, OrderNumber FROM Order WHERE Id = :oid WITH USER_MODE LIMIT 1];
        if (rows.isEmpty()) return AgenticSkillsBase.errorHtml('Could not update order', 'No order found for provided Id.');
        return AgenticSkillsBase.performGenericUpdate('Order', oid, fields, 'Order Updated', 'View Order', rows[0].OrderNumber);
    }

    private String handleAddOrderItem(Map<String, Object> p) {
        Id oid = AgenticSkillsBase.resolveLookupId(p, 'OrderId');
        if (oid == null) {
            oid = AgenticSkillsBase.parseSalesforceId(AgenticSkillsBase.toText(
                AgenticSkillsBase.firstNonBlank(p, new List<String>{ 'order_id', 'recordId', 'Id' })
            ));
        }
        Object qtyRaw = AgenticSkillsBase.firstNonBlank(p, new List<String>{ 'Quantity', 'quantity' });
        Object priceRaw = AgenticSkillsBase.firstNonBlank(p, new List<String>{ 'UnitPrice', 'unit_price', 'unitPrice' });
        if (oid == null) return AgenticSkillsBase.errorHtml('Could not add order item', 'Missing parameter: OrderId');
        if (qtyRaw == null) return AgenticSkillsBase.errorHtml('Could not add order item', 'Missing parameter: Quantity');
        if (priceRaw == null) return AgenticSkillsBase.errorHtml('Could not add order item', 'Missing parameter: UnitPrice');
        if (!Schema.sObjectType.OrderItem.isCreateable()) return AgenticSkillsBase.errorHtml('Could not add order item', 'OrderItem is not creatable.');
        List<Order> orders = [SELECT Id, Pricebook2Id, Status FROM Order WHERE Id = :oid WITH USER_MODE LIMIT 1];
        if (orders.isEmpty()) return AgenticSkillsBase.errorHtml('Could not add order item', 'No order found for provided OrderId.');
        Id pbeId;
        String pbeRaw = AgenticSkillsBase.toText(AgenticSkillsBase.firstNonBlank(p, new List<String>{
            'PricebookEntryId', 'pricebook_entry_id', 'pricebookEntryId'
        }));
        if (String.isNotBlank(pbeRaw)) {
            try { pbeId = Id.valueOf(pbeRaw); } catch (Exception e) { return AgenticSkillsBase.errorHtml('Could not add order item', 'Invalid PricebookEntryId.'); }
        } else {
            String pname = AgenticSkillsBase.toText(AgenticSkillsBase.firstNonBlank(p, new List<String>{
                'Name', 'product_name', 'productName'
            }));
            if (String.isBlank(pname)) return AgenticSkillsBase.errorHtml('Could not add order item', 'Provide PricebookEntryId or product Name.');
            List<PricebookEntry> pbes = [
                SELECT Id FROM PricebookEntry
                WHERE Product2.Name = :pname AND IsActive = true AND Pricebook2Id = :orders[0].Pricebook2Id
                WITH USER_MODE LIMIT 1
            ];
            if (pbes.isEmpty()) return AgenticSkillsBase.errorHtml('Could not add order item', 'No active PricebookEntry found for "' + pname + '".');
            pbeId = pbes[0].Id;
        }
        try {
            OrderItem oi = new OrderItem(
                OrderId = oid, PricebookEntryId = pbeId,
                Quantity = Decimal.valueOf(String.valueOf(qtyRaw)),
                UnitPrice = Decimal.valueOf(String.valueOf(priceRaw))
            );
            insert oi;
            String body = '<ul><li><b>Quantity:</b> ' + AgenticSkillsBase.escapeHtml(String.valueOf(qtyRaw)) + '</li>'
                        + '<li><b>Unit Price:</b> ' + AgenticSkillsBase.escapeHtml(String.valueOf(priceRaw)) + '</li></ul>';
            return AgenticSkillsBase.successHtml('Order Item Added', body, oi.Id, 'View Order Item');
        } catch (Exception ex) {
            return AgenticSkillsBase.errorHtml('Could not add order item', ex.getMessage());
        }
    }

    private String handleUpdateOrderItem(Map<String, Object> p) {
        String oiId = AgenticSkillsBase.toText(AgenticSkillsBase.firstNonNull(p, new List<String>{ 'order_item_id', 'line_item_id', 'recordId', 'Id' }));
        if (String.isBlank(oiId)) return AgenticSkillsBase.errorHtml('Could not update order item', 'Missing parameter: order_item_id');
        Map<String, Object> fields = AgenticSkillsBase.buildFieldMap(p, new Set<String>{ 'order_item_id', 'line_item_id', 'recordId', 'Id', 'order_id' });
        if (fields.isEmpty()) return AgenticSkillsBase.errorHtml('Could not update order item', 'Missing parameter: at least one field to update');
        if (!Schema.sObjectType.OrderItem.isUpdateable()) return AgenticSkillsBase.errorHtml('Could not update order item', 'OrderItem is not updateable.');
        List<OrderItem> rows = [SELECT Id, OrderItemNumber, Quantity, UnitPrice FROM OrderItem WHERE Id = :oiId WITH USER_MODE LIMIT 1];
        if (rows.isEmpty()) return AgenticSkillsBase.errorHtml('Could not update order item', 'No order item found for provided Id.');
        String label = rows[0].OrderItemNumber + ' (' + rows[0].Quantity + ' @ ' + rows[0].UnitPrice + ')';
        return AgenticSkillsBase.performGenericUpdate('OrderItem', oiId, fields, 'Order Item Updated', 'View Order Item', label);
    }

    private String handleFetchSubscriptionDetails(Map<String, Object> p) {
        String subApi = subscriptionObjectApi();
        String sid = AgenticSkillsBase.toText(AgenticSkillsBase.firstNonNull(p, new List<String>{ 'subscription_id', 'recordId', 'Id' }));
        String orderId = AgenticSkillsBase.toText(p.get('order_id'));
        if (String.isBlank(sid) && String.isBlank(orderId)) {
            return AgenticSkillsBase.errorJson('Missing required parameter: subscription_id or order_id');
        }
        if (subApi != null) {
            return fetchSubscriptionFromObject(subApi, sid, orderId);
        }
        if (String.isNotBlank(orderId) && Schema.sObjectType.Order.isAccessible()) {
            List<Order> orders = [SELECT Id, OrderNumber, ContractId, AccountId FROM Order WHERE Id = :orderId WITH USER_MODE LIMIT 1];
            if (orders.isEmpty()) return AgenticSkillsBase.errorJson('No order found for provided order_id.');
            Order o = orders[0];
            if (o.ContractId != null && Schema.sObjectType.Contract.isAccessible()) {
                List<Contract> contracts = [
                    SELECT Id, ContractNumber, Status, StartDate, EndDate, AccountId
                    FROM Contract WHERE Id = :o.ContractId WITH USER_MODE LIMIT 1
                ];
                if (!contracts.isEmpty()) {
                    Contract c = contracts[0];
                    return AgenticSkillsBase.successJson(new Map<String, Object>{
                        'source' => 'Contract via Order',
                        'orderId' => o.Id, 'orderNumber' => o.OrderNumber,
                        'Id' => c.Id, 'ContractNumber' => c.ContractNumber, 'Status' => c.Status,
                        'StartDate' => String.valueOf(c.StartDate), 'EndDate' => String.valueOf(c.EndDate),
                        'recordUrl' => AgenticSkillsBase.recordUrl(c.Id)
                    });
                }
            }
            return AgenticSkillsBase.successJson(new Map<String, Object>{
                'source' => 'Order',
                'message' => 'No Subscription object found; returning order context only.',
                'orderId' => o.Id, 'orderNumber' => o.OrderNumber, 'contractId' => o.ContractId
            });
        }
        return AgenticSkillsBase.errorJson('Subscription object is not available in this org.');
    }

    private String fetchSubscriptionFromObject(String subApi, String sid, String orderId) {
        Schema.SObjectType sot = Schema.getGlobalDescribe().get(subApi);
        Map<String, Schema.SObjectField> fmap = sot.getDescribe().fields.getMap();
        List<String> fields = new List<String>{ 'Id', 'Name' };
        for (String f : new List<String>{ 'Status', 'StartDate', 'EndDate', 'AccountId', 'ContractId' }) {
            if (fmap.containsKey(f)) fields.add(f);
        }
        String orderField = null;
        for (String f : new List<String>{ 'OrderId', 'SBQQ__Order__c' }) {
            if (fmap.containsKey(f)) { orderField = f; fields.add(f); break; }
        }
        List<SObject> rows;
        if (String.isNotBlank(sid)) {
            String soql = 'SELECT ' + String.join(fields, ', ') + ' FROM ' + subApi + ' WHERE Id = :sid WITH USER_MODE LIMIT 1';
            rows = Database.query(soql);
        } else if (String.isNotBlank(orderId) && orderField != null) {
            String soql = 'SELECT ' + String.join(fields, ', ') + ' FROM ' + subApi + ' WHERE ' + orderField + ' = :orderId WITH USER_MODE LIMIT 25';
            rows = Database.query(soql);
        } else {
            return AgenticSkillsBase.errorJson('Could not resolve subscription by order_id — no order lookup field on ' + subApi + '.');
        }
        if (rows.isEmpty()) return AgenticSkillsBase.errorJson('No subscription found.');
        if (rows.size() == 1) {
            SObject s = rows[0];
            Map<String, Object> result = new Map<String, Object>{ 'object' => subApi, 'recordUrl' => AgenticSkillsBase.recordUrl((Id) s.get('Id')) };
            for (String f : fields) result.put(f, s.get(f));
            return AgenticSkillsBase.successJson(result);
        }
        List<Map<String, Object>> subs = new List<Map<String, Object>>();
        for (SObject s : rows) {
            Map<String, Object> row = new Map<String, Object>{ 'Id' => s.get('Id'), 'Name' => s.get('Name') };
            if (fmap.containsKey('Status')) row.put('Status', s.get('Status'));
            subs.add(row);
        }
        return AgenticSkillsBase.successJson(new Map<String, Object>{ 'object' => subApi, 'count' => subs.size(), 'subscriptions' => subs });
    }

    private String handleUpdateSubscriptionFields(Map<String, Object> p) {
        String subApi = subscriptionObjectApi();
        if (subApi == null) return AgenticSkillsBase.errorHtml('Could not update subscription', 'Subscription object is not available in this org.');
        Schema.SObjectType sot = Schema.getGlobalDescribe().get(subApi);
        if (!sot.getDescribe().isUpdateable()) return AgenticSkillsBase.errorHtml('Could not update subscription', subApi + ' is not updateable.');
        String sid = AgenticSkillsBase.toText(AgenticSkillsBase.firstNonNull(p, new List<String>{ 'subscription_id', 'recordId', 'Id' }));
        if (String.isBlank(sid)) return AgenticSkillsBase.errorHtml('Could not update subscription', 'Missing parameter: subscription_id');
        Map<String, Object> fields = AgenticSkillsBase.buildFieldMap(p, new Set<String>{ 'subscription_id', 'recordId', 'Id' });
        if (fields.isEmpty()) return AgenticSkillsBase.errorHtml('Could not update subscription', 'Missing parameter: at least one field to update');
        String soql = 'SELECT Id, Name FROM ' + subApi + ' WHERE Id = :sid WITH USER_MODE LIMIT 1';
        List<SObject> rows = Database.query(soql);
        if (rows.isEmpty()) return AgenticSkillsBase.errorHtml('Could not update subscription', 'No subscription found for provided Id.');
        return AgenticSkillsBase.performGenericUpdate(subApi, sid, fields, 'Subscription Updated', 'View Subscription', String.valueOf(rows[0].get('Name')));
    }
}
