/**
 * Smoke tests for UtilityAgenticSkillsHandler (package deploy / RunSpecifiedTests).
 */
@isTest
private class UtilityAgenticSkillsHandlerTest {
    @isTest
    static void smoke_unsupportedSkill() {
        UtilityAgenticSkillsHandler h = new UtilityAgenticSkillsHandler();
        String r = h.executeMethod('__no_such_skill__', new Map<String, Object>());
        Map<String, Object> m = (Map<String, Object>) JSON.deserializeUntyped(r);
        System.Assert.areEqual(false, m.get('success'));
    }

    @isTest
    static void smoke_blankMethodName() {
        UtilityAgenticSkillsHandler h = new UtilityAgenticSkillsHandler();
        String r = h.executeMethod('', null);
        Map<String, Object> m = (Map<String, Object>) JSON.deserializeUntyped(r);
        System.Assert.areEqual(false, m.get('success'));
    }
}
