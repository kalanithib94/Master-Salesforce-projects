/**
 * Smoke tests for CpqAgenticSkillsHandler (package deploy / RunSpecifiedTests).
 */
@isTest
private class CpqAgenticSkillsHandlerTest {
    @isTest
    static void smoke_unsupportedSkill() {
        CpqAgenticSkillsHandler h = new CpqAgenticSkillsHandler();
        String r = h.executeMethod('__no_such_skill__', new Map<String, Object>());
        Map<String, Object> m = (Map<String, Object>) JSON.deserializeUntyped(r);
        System.Assert.areEqual(false, m.get('success'));
    }

    @isTest
    static void smoke_blankMethodName() {
        CpqAgenticSkillsHandler h = new CpqAgenticSkillsHandler();
        String r = h.executeMethod('', null);
        Map<String, Object> m = (Map<String, Object>) JSON.deserializeUntyped(r);
        System.Assert.areEqual(false, m.get('success'));
    }
}
