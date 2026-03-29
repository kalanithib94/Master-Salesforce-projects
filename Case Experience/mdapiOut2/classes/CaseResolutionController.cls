/**
 * CaseResolutionController
 *
 * Architecture (polling model):
 *   1. LWC "Find a Solution" -> createSupportCase() -> Case inserted (Status: New, Origin: Web)
 *   2. Case insert fires Case_Resolution_RTF (Record-Triggered Flow, async path)
 *      -> Flow calls ccai__AIPromptProcessingInvokable
 *      -> Flow creates a CaseComment with the GPTfy response
 *   3. LWC polls getRecommendation() every 2.5 s until a CaseComment exists
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
        String subject
    ) {
        if (String.isBlank(subject)) {
            throw new AuraHandledException('Please provide a subject before submitting.');
        }

        try {
            String suppliedName = (firstName + ' ' + lastName).trim();
            String caseSubject  = subject.substring(0, Math.min(255, subject.length()));
            String productName  = String.isBlank(category) ? null : category.trim();

            Case c = new Case();
            c.Subject       = caseSubject;
            c.Description   = subject; // store full user query here
            c.SuppliedName  = suppliedName;
            c.SuppliedEmail = email;
            c.Status        = 'New';
            c.Origin        = 'Web';
            c.Priority      = 'Medium';

            // Store selected product into Case Product when available.
            // If ProductId isn't enabled in the org, fall back to Type.
            Map<String, Schema.SObjectField> fields = Schema.SObjectType.Case.fields.getMap();
            if (String.isNotBlank(productName) && fields.containsKey('ProductId')) {
                try {
                    Product2 p = [
                        SELECT Id
                        FROM   Product2
                        WHERE  Name = :productName
                        LIMIT  1
                    ];
                    c.put('ProductId', p.Id);
                } catch (Exception e) {
                    // If product doesn't exist or field isn't usable, fall back.
                    c.Type = productName;
                }
            } else if (String.isNotBlank(productName)) {
                c.Type = productName;
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
            List<CaseComment> comments = [
                SELECT CommentBody
                FROM   CaseComment
                WHERE  ParentId = :caseId
                ORDER  BY CreatedDate DESC
                LIMIT  1
            ];
            if (comments.isEmpty()) return null;
            return String.isBlank(comments[0].CommentBody) ? null : comments[0].CommentBody;
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
