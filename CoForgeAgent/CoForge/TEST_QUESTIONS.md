# Credit Line Assistant - Test Questions

## Test Questions for Credit Line Assistant Agent

### 1. Credit Increase Requests (Should Create Case)
1. **"can i increase my limit"**
   - Expected: Creates case, displays CaseNumber and CaseUrl
   - Should NOT say "Please wait" or repeat messages

2. **"I want to raise my credit limit"**
   - Expected: Creates case, displays CaseNumber and CaseUrl

3. **"Can you increase my credit to $15,000?"**
   - Expected: Creates case with RequestedAmount, displays CaseNumber and CaseUrl

### 4. Balance/Limit Inquiries (Should NOT Create Case)
4. **"What is my current credit limit?"**
   - Expected: Shows contact details only, NO case created

5. **"What's my available balance?"**
   - Expected: Shows contact details only, NO case created

6. **"Show me my payment history"**
   - Expected: Shows contact details only, NO case created

### 7. Lost Card Reports (Should Create Urgent Case)
7. **"I lost my credit card"**
   - Expected: Creates urgent lost card case, displays CaseNumber and CaseUrl

8. **"My card was stolen"**
   - Expected: Creates urgent lost card case, displays CaseNumber and CaseUrl

### 9. Account Closure (Should Create Case)
9. **"I want to close my account"**
   - Expected: Creates account closure case, displays CaseNumber and CaseUrl

### 10. General Inquiry (Should NOT Create Case)
10. **"What are my account details?"**
    - Expected: Shows contact details only, NO case created

---

## Quick Test Checklist

For each question, verify:
- ✅ Correct function is called (check debug logs)
- ✅ Case is created (if applicable) with correct CaseNumber
- ✅ CaseUrl is displayed (if case created)
- ✅ No "Please wait" or "being processed" messages
- ✅ No message repetition
- ✅ Response is concise and clear

---

## Expected Behavior Summary

| Question Type | Should Create Case? | Case Type | Priority |
|--------------|---------------------|-----------|----------|
| Credit increase | ✅ Yes | Service Request | Medium |
| Balance inquiry | ❌ No | N/A | N/A |
| Lost card | ✅ Yes | Problem | High |
| Account closure | ✅ Yes | Service Request | Medium |
| General inquiry | ❌ No | N/A | N/A |


