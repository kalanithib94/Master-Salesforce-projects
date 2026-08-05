/**
 * Smoke tests for ProductAgenticSkillsHandler (package deploy / RunSpecifiedTests).
 */
@isTest
private class ProductAgenticSkillsHandlerTest {
    @isTest
    static void smoke_unsupportedSkill() {
        ProductAgenticSkillsHandler h = new ProductAgenticSkillsHandler();
        String r = h.executeMethod('__no_such_skill__', new Map<String, Object>());
        Map<String, Object> m = (Map<String, Object>) JSON.deserializeUntyped(r);
        System.Assert.areEqual(false, m.get('success'));
    }

    @isTest
    static void smoke_blankMethodName() {
        ProductAgenticSkillsHandler h = new ProductAgenticSkillsHandler();
        String r = h.executeMethod('', null);
        Map<String, Object> m = (Map<String, Object>) JSON.deserializeUntyped(r);
        System.Assert.areEqual(false, m.get('success'));
    }
}
