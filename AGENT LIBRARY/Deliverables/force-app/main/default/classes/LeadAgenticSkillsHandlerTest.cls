/**
 * Smoke tests for LeadAgenticSkillsHandler (package deploy / RunSpecifiedTests).
 */
@isTest
private class LeadAgenticSkillsHandlerTest {
    @isTest
    static void smoke_unsupportedSkill() {
        LeadAgenticSkillsHandler h = new LeadAgenticSkillsHandler();
        String r = h.executeMethod('__no_such_skill__', new Map<String, Object>());
        Map<String, Object> m = (Map<String, Object>) JSON.deserializeUntyped(r);
        System.Assert.areEqual(false, m.get('success'));
    }

    @isTest
    static void smoke_blankMethodName() {
        LeadAgenticSkillsHandler h = new LeadAgenticSkillsHandler();
        String r = h.executeMethod('', null);
        Map<String, Object> m = (Map<String, Object>) JSON.deserializeUntyped(r);
        System.Assert.areEqual(false, m.get('success'));
    }
}
