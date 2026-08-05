/**
 * Smoke tests for OrderAgenticSkillsHandler (package deploy / RunSpecifiedTests).
 */
@isTest
private class OrderAgenticSkillsHandlerTest {
    @isTest
    static void smoke_unsupportedSkill() {
        OrderAgenticSkillsHandler h = new OrderAgenticSkillsHandler();
        String r = h.executeMethod('__no_such_skill__', new Map<String, Object>());
        Map<String, Object> m = (Map<String, Object>) JSON.deserializeUntyped(r);
        System.Assert.areEqual(false, m.get('success'));
    }

    @isTest
    static void smoke_blankMethodName() {
        OrderAgenticSkillsHandler h = new OrderAgenticSkillsHandler();
        String r = h.executeMethod('', null);
        Map<String, Object> m = (Map<String, Object>) JSON.deserializeUntyped(r);
        System.Assert.areEqual(false, m.get('success'));
    }
}
