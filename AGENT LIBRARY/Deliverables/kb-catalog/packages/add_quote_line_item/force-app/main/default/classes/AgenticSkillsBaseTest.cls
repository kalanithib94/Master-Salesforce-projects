/**
 * Smoke tests for AgenticSkillsBase (shared skill utilities).
 */
@isTest
private class AgenticSkillsBaseTest {
    @isTest
    static void smoke_errorJsonEnvelope() {
        String r = AgenticSkillsBase.errorJson('test error');
        Map<String, Object> m = (Map<String, Object>) JSON.deserializeUntyped(r);
        System.Assert.areEqual(false, m.get('success'));
        System.Assert.isTrue(String.valueOf(m.get('error')).contains('test error'));
    }

    @isTest
    static void smoke_idHelpers() {
        System.Assert.isFalse(AgenticSkillsBase.isSalesforceIdToken('not-an-id'));
        System.Assert.isTrue(AgenticSkillsBase.escapeHtml('<b>x</b>').contains('&lt;')
            || AgenticSkillsBase.escapeHtml('<b>x</b>').contains('&#'));
    }
}
