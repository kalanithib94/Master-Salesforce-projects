/**
 * Smoke tests for CampaignAgenticSkillsHandler (package deploy / RunSpecifiedTests).
 */
@isTest
private class CampaignAgenticSkillsHandlerTest {
    @isTest
    static void smoke_unsupportedSkill() {
        CampaignAgenticSkillsHandler h = new CampaignAgenticSkillsHandler();
        String r = h.executeMethod('__no_such_skill__', new Map<String, Object>());
        Map<String, Object> m = (Map<String, Object>) JSON.deserializeUntyped(r);
        System.Assert.areEqual(false, m.get('success'));
    }

    @isTest
    static void smoke_blankMethodName() {
        CampaignAgenticSkillsHandler h = new CampaignAgenticSkillsHandler();
        String r = h.executeMethod('', null);
        Map<String, Object> m = (Map<String, Object>) JSON.deserializeUntyped(r);
        System.Assert.areEqual(false, m.get('success'));
    }
}
