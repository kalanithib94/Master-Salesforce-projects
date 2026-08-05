/**
 * Smoke tests for OpportunityAgenticSkillsHandler (package deploy / RunSpecifiedTests).
 */
@isTest
private class OpportunityAgenticSkillsHandlerTest {
    @isTest
    static void smoke_unsupportedSkill() {
        OpportunityAgenticSkillsHandler h = new OpportunityAgenticSkillsHandler();
        String r = h.executeMethod('__no_such_skill__', new Map<String, Object>());
        Map<String, Object> m = (Map<String, Object>) JSON.deserializeUntyped(r);
        System.Assert.areEqual(false, m.get('success'));
    }

    @isTest
    static void smoke_blankMethodName() {
        OpportunityAgenticSkillsHandler h = new OpportunityAgenticSkillsHandler();
        String r = h.executeMethod('', null);
        Map<String, Object> m = (Map<String, Object>) JSON.deserializeUntyped(r);
        System.Assert.areEqual(false, m.get('success'));
    }
}
