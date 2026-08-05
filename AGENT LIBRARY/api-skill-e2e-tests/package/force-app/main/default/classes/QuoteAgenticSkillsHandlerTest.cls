/**
 * Smoke tests for QuoteAgenticSkillsHandler (package deploy / RunSpecifiedTests).
 */
@isTest
private class QuoteAgenticSkillsHandlerTest {
    @isTest
    static void smoke_unsupportedSkill() {
        QuoteAgenticSkillsHandler h = new QuoteAgenticSkillsHandler();
        String r = h.executeMethod('__no_such_skill__', new Map<String, Object>());
        Map<String, Object> m = (Map<String, Object>) JSON.deserializeUntyped(r);
        System.Assert.areEqual(false, m.get('success'));
    }

    @isTest
    static void smoke_blankMethodName() {
        QuoteAgenticSkillsHandler h = new QuoteAgenticSkillsHandler();
        String r = h.executeMethod('', null);
        Map<String, Object> m = (Map<String, Object>) JSON.deserializeUntyped(r);
        System.Assert.areEqual(false, m.get('success'));
    }
}
