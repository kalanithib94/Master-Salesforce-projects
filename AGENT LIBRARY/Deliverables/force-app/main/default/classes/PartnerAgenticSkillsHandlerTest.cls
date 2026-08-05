/**
 * Smoke tests for PartnerAgenticSkillsHandler (package deploy / RunSpecifiedTests).
 */
@isTest
private class PartnerAgenticSkillsHandlerTest {
    @isTest
    static void smoke_unsupportedSkill() {
        PartnerAgenticSkillsHandler h = new PartnerAgenticSkillsHandler();
        String r = h.executeMethod('__no_such_skill__', new Map<String, Object>());
        Map<String, Object> m = (Map<String, Object>) JSON.deserializeUntyped(r);
        System.Assert.areEqual(false, m.get('success'));
    }

    @isTest
    static void smoke_blankMethodName() {
        PartnerAgenticSkillsHandler h = new PartnerAgenticSkillsHandler();
        String r = h.executeMethod('', null);
        Map<String, Object> m = (Map<String, Object>) JSON.deserializeUntyped(r);
        System.Assert.areEqual(false, m.get('success'));
    }
}
