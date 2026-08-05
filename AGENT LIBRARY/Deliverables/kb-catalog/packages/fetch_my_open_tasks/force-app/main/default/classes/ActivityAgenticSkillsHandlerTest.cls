/**
 * Smoke tests for ActivityAgenticSkillsHandler (package deploy / RunSpecifiedTests).
 */
@isTest
private class ActivityAgenticSkillsHandlerTest {
    @isTest
    static void smoke_unsupportedSkill() {
        ActivityAgenticSkillsHandler h = new ActivityAgenticSkillsHandler();
        String r = h.executeMethod('__no_such_skill__', new Map<String, Object>());
        Map<String, Object> m = (Map<String, Object>) JSON.deserializeUntyped(r);
        System.Assert.areEqual(false, m.get('success'));
    }

    @isTest
    static void smoke_blankMethodName() {
        ActivityAgenticSkillsHandler h = new ActivityAgenticSkillsHandler();
        String r = h.executeMethod('', null);
        Map<String, Object> m = (Map<String, Object>) JSON.deserializeUntyped(r);
        System.Assert.areEqual(false, m.get('success'));
    }
}
