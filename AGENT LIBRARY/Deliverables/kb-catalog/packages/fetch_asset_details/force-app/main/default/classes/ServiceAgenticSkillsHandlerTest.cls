/**
 * Smoke tests for ServiceAgenticSkillsHandler (package deploy / RunSpecifiedTests).
 */
@isTest
private class ServiceAgenticSkillsHandlerTest {
    @isTest
    static void smoke_unsupportedSkill() {
        ServiceAgenticSkillsHandler h = new ServiceAgenticSkillsHandler();
        String r = h.executeMethod('__no_such_skill__', new Map<String, Object>());
        Map<String, Object> m = (Map<String, Object>) JSON.deserializeUntyped(r);
        System.Assert.areEqual(false, m.get('success'));
    }

    @isTest
    static void smoke_blankMethodName() {
        ServiceAgenticSkillsHandler h = new ServiceAgenticSkillsHandler();
        String r = h.executeMethod('', null);
        Map<String, Object> m = (Map<String, Object>) JSON.deserializeUntyped(r);
        System.Assert.areEqual(false, m.get('success'));
    }
}
