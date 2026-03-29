/**
 * CaseResolutionController
 *
 * Architecture (polling model):
 *   1. LWC "Find a Solution" -> createSupportCase() -> Case inserted (Status: New, Origin: Web)
 *   2. Case insert fires Case_Resolution_RTF (Record-Triggered Flow, async path)
 *      -> Flow calls ccai__AIPromptProcessingInvokable
 *      -> Flow updates Case.Proposed_Resolution__c with the GPTfy response
 *   3. LWC polls getRecommendation() every 2.5 s until Case.Proposed_Resolution__c is populated
 *   4. "Yes, I'm good"  -> resolveCase() sets Status = 'Closed'
 *   5. "No, still need help" -> LWC shows caseNumber; case stays open (Status: New)
 *
 * "without sharing" required for Experience Cloud guest user access.
 * Guest User Profile must have:
 *   - Apex Class Access : CaseResolutionController
 *   - Object CRUD       : Case (Create, Read, Edit)
 */
public without sharing class CaseResolutionController {

    // ─────────────────────────────────────────────────────────────────────────
    // Wrapper returned after case creation
    // ─────────────────────────────────────────────────────────────────────────

    public class CaseCreationResult {
        @AuraEnabled public String caseId;
        @AuraEnabled public String caseNumber;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 1. Create Case — called immediately when "Find a Solution" is clicked.
    //    The Record-Triggered Flow fires asynchronously after this returns.
    // ─────────────────────────────────────────────────────────────────────────

    @AuraEnabled(cacheable=false)
    public static CaseCreationResult createSupportCase(
        String firstName,
        String lastName,
        String email,
        String category,
        String subject,
        String description
    ) {
        if (String.isBlank(subject) || String.isBlank(description)) {
            throw new AuraHandledException('Please provide both subject and case details before submitting.');
        }

        try {
            String suppliedName = (firstName + ' ' + lastName).trim();
            String caseSubject  = subject.substring(0, Math.min(255, subject.length()));
            String caseDescription = description.substring(0, Math.min(32000, description.length()));
            String productName  = String.isBlank(category) ? null : category.trim();

            Case c = new Case();
            c.Subject       = caseSubject;
            c.Description   = caseDescription;
            c.SuppliedName  = suppliedName;
            c.SuppliedEmail = email;
            c.Status        = 'New';
            c.Origin        = 'Web';
            c.Priority      = 'Medium';

            // Store selected product into Case.GPTfy_Product__c.
            Map<String, Schema.SObjectField> fields = Schema.SObjectType.Case.fields.getMap();
            if (String.isNotBlank(productName)) {
                if (fields.containsKey('GPTfy_Product__c')) {
                    c.put('GPTfy_Product__c', productName);
                } else if (fields.containsKey('GPTfy_procduct__c')) {
                    // Backward compatibility for orgs where the typo field still exists.
                    c.put('GPTfy_procduct__c', productName);
                }
            }

            insert c;

            Case inserted = [SELECT Id, CaseNumber FROM Case WHERE Id = :c.Id LIMIT 1];

            CaseCreationResult result = new CaseCreationResult();
            result.caseId     = inserted.Id;
            result.caseNumber = inserted.CaseNumber;
            return result;

        } catch (AuraHandledException ahe) {
            throw ahe;
        } catch (Exception e) {
            throw new AuraHandledException('Unable to create case: ' + e.getMessage());
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 2. Poll for Recommendation — LWC calls this every 2.5 s until non-blank.
    //    Returns null/empty while the async Flow is still running.
    // ─────────────────────────────────────────────────────────────────────────

    @AuraEnabled(cacheable=false)
    public static String getRecommendation(String caseId) {
        if (String.isBlank(caseId)) return null;
        try {
            Case c = [
                SELECT Proposed_Resolution__c
                FROM   Case
                WHERE  Id = :caseId
                LIMIT  1
            ];
            return String.isBlank(c.Proposed_Resolution__c) ? null : c.Proposed_Resolution__c;
        } catch (Exception e) {
            return null;
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 3. Resolve Case — called when user clicks "Yes, I'm good".
    //    Sets Status = 'Closed'.
    // ─────────────────────────────────────────────────────────────────────────

    @AuraEnabled(cacheable=false)
    public static void resolveCase(String caseId) {
        if (String.isBlank(caseId)) {
            throw new AuraHandledException('Case ID is required to close the case.');
        }
        try {
            update new Case(Id = caseId, Status = 'Closed');
        } catch (Exception e) {
            throw new AuraHandledException('Unable to close the case: ' + e.getMessage());
        }
    }
}
