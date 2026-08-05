# Skill: `fuzzy_search_contacts`

**Sources:** `Deliverables/force-app/main/default/classes/GenericAgenticSkillsHandler.cls`, `Deliverables/docs/GenericCRMAssistant_SystemPrompt.txt` (v1.3.1), `Deliverables/docs/GPTfy_Agent_Prompt_Commands.md`.

## Apex Code Snippet

```apex
when 'fuzzy_search_contacts'        { return handleFuzzySearchContacts(parameters); }

    private String handleFuzzySearchContacts(Map<String, Object> p) {
        String term = toText(firstNonNull(p, new List<String>{ 'search_term', 'contact_name', 'name', 'email' }));
        if (String.isBlank(term)) return errorJson('Missing required parameter: search_term');
        if (!Schema.sObjectType.Contact.isAccessible()) return errorJson('Contact is not accessible.');
        List<SObject> all = fuzzyQueryMulti(
            'Contact',
            new List<String>{ 'Name', 'Email' },
            new List<String>{ 'Phone', 'Title', 'AccountId', 'Account.Name' },
            term
        );
        if (all.isEmpty()) return errorJson('No contact found matching "' + term + '".');
        Map<String, Object> sliced = applyTopNAndCount(all, FUZZY_DISPLAY_LIMIT);
        List<SObject> top = (List<SObject>) sliced.get('rows');
        List<Map<String, Object>> records = new List<Map<String, Object>>();
        for (SObject r : top) {
            Contact c = (Contact) r;
            records.add(new Map<String, Object>{
                'Id'         => c.Id,  'Name'    => c.Name,  'Email'   => c.Email,
                'Phone'      => c.Phone, 'Title'  => c.Title,
                'Account'    => c.Account != null ? c.Account.Name : null,
                'recordUrl'  => recordUrl(c.Id),
                'viewRecord' => viewRecordAnchor(c.Id)
            });
        }
        return successJson(new Map<String, Object>{
            'status'     => 'found',
            'totalFound' => sliced.get('totalFound'),
            'displayed'  => sliced.get('displayed'),
            'remaining'  => sliced.get('remaining'),
            'records'    => records
        });
    }
```

## System Prompt Excerpt

<!-- Lines 45-47 -->
STANDARD CRUD PATTERN (per object)
- fuzzy_search_<plural>     → JSON   find records by name (Opportunity also accepts an Id)
- fetch_<object>_details    → JSON   full record + key related data

<!-- Lines 120-134 -->
FUZZY SEARCH RESULT RENDERING (applies to every fuzzy_search_* skill):

Every fuzzy_search_* skill returns a JSON envelope with these keys:
- "records"     — array of matching records (always at most 5; the LATEST 5 by LastModifiedDate DESC)
- "totalFound"  — total number of records that matched in the database (may be > 5)
- "displayed"   — number of records actually present in `records` (always equal to records.length)
- "remaining"   — totalFound − displayed (the count NOT shown to the user)

How to render:
- 0 matches (totalFound = 0) → tell the user no records were found and ask for a different name.
- 1 match (totalFound = 1) → present Name + key fields and ask the user to confirm before proceeding.
- 2 to 5 matches (totalFound ≤ 5) → list all `records` and ask the user to pick one.
- More than 5 matches (totalFound > 5, remaining > 0) → list the 5 records returned in `records` and, in the SAME message, append one sentence stating how many more exist:
        "Showing the latest 5 of {totalFound} matching {object} records — {remaining} more not shown. Refine your search (e.g. add the city / company / last name) to narrow it down."
  Never silently drop the leftover count and never claim the list is exhaustive when remaining > 0.

<!-- Lines 139-139 -->
- fuzzy_search_contacts        → Name | Title | Account | Email | View Record

<!-- Lines 363-377 -->
RULE 9 — SEARCH RESULTS DISPLAY
═══════════════════════════════════════════════════
When the user explicitly asks to find/search/list records, after calling the matching fuzzy_search_* skill, render results using the envelope from Rule 2 (FUZZY SEARCH RESULT RENDERING).

Header line (always show this):
**Found [totalFound] matching [Object]s — showing the latest [displayed]:**

Then a list/table — one row per record, columns per Rule 2 (Account: Name | Type | Industry | Website | View Record; Contact: Name | Title | Account | Email | View Record; Lead: Name | Company | Status | Email | View Record; Opportunity: Name | StageName | CloseDate | Amount | View Record; Case: CaseNumber | Subject | Status | Priority | View Record).

The "View Record" cell MUST be a clickable hyperlink to the record's `recordUrl` (use Markdown `[View Record](recordUrl)` or the pre-built `viewRecord` HTML anchor returned by the skill — both work).

Footer line (only when remaining > 0):
"{remaining} more not shown. Refine your search (e.g. add the company / city / last name) to narrow it down."

If totalFound = 0: "No [object] found matching '[term]'. Try a different name or pattern."

## JSON Prompt Command

```json
{
  "type": "object",
  "properties": {
    "search_term": {
      "type": "string",
      "description": "The Contact name OR email (or partial) to search for. Examples: 'John Smith', 'john@acme.com', 'Khan'."
    }
  },
  "required": [
    "search_term"
  ]
}
```
