/**
 * Smoke tests for AccountAgenticSkillsHandler (package deploy / RunSpecifiedTests).
 */
@isTest
private class AccountAgenticSkillsHandlerTest {
    @isTest
    static void smoke_unsupportedSkill() {
        AccountAgenticSkillsHandler h = new AccountAgenticSkillsHandler();
        String r = h.executeMethod('__no_such_skill__', new Map<String, Object>());
        Map<String, Object> m = (Map<String, Object>) JSON.deserializeUntyped(r);
        System.Assert.areEqual(false, m.get('success'));
    }

    @isTest
    static void smoke_blankMethodName() {
        AccountAgenticSkillsHandler h = new AccountAgenticSkillsHandler();
        String r = h.executeMethod('', null);
        Map<String, Object> m = (Map<String, Object>) JSON.deserializeUntyped(r);
        System.Assert.areEqual(false, m.get('success'));
    }
}
