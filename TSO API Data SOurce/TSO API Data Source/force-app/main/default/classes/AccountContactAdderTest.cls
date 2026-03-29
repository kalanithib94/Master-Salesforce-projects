@IsTest
private class AccountContactAdderTest {
    @IsTest static void testAddContactWhenNoneExist() {
        // Create test account with no contacts
        Account acct = new Account(Name = 'Test Account');
        insert acct;

        // Call utility to add a contact
        Test.startTest();
        AccountContactAdder.addContactIfNone(
            new List<Id>{acct.Id}, 'Test', 'Contact');
        Test.stopTest();

        // Verify a contact was inserted
        Integer contactCount = [SELECT COUNT() FROM Contact WHERE AccountId = :acct.Id];
        System.assertEquals(1, contactCount, 'A contact should have been added');
    }

    @IsTest static void testNoDuplicateContactWhenExists() {
        // Create test account and a contact
        Account acct = new Account(Name = 'Test Account 2');
        insert acct;
        insert new Contact(AccountId = acct.Id, FirstName = 'Existing', LastName = 'Contact');

        // Call utility to add a contact
        Test.startTest();
        AccountContactAdder.addContactIfNone(
            new List<Id>{acct.Id}, 'New', 'Contact');
        Test.stopTest();

        // Should still be one contact
        Integer contactCount = [SELECT COUNT() FROM Contact WHERE AccountId = :acct.Id];
        System.assertEquals(1, contactCount, 'No new contact should have been added');
    }

    @IsTest static void testBulkAccounts() {
        // Create multiple accounts
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < 5; i++) {
            accounts.add(new Account(Name = 'Bulk Account ' + i));
        }
        insert accounts;

        // Add a contact to one account beforehand
        insert new Contact(AccountId = accounts[0].Id, FirstName = 'Existing', LastName = 'C');

        // Call utility on all accounts
        List<Id> ids = new List<Id>();
        for (Account a : accounts) ids.add(a.Id);

        Test.startTest();
        AccountContactAdder.addContactIfNone(ids, 'Bulk', 'Contact');
        Test.stopTest();

        // Verify that contacts were added only to accounts without existing ones
        Map<Id, Integer> counts = new Map<Id, Integer>();
        for (AggregateResult ar : [SELECT AccountId accId, COUNT(Id) cnt FROM Contact WHERE AccountId IN :ids GROUP BY AccountId]) {
            counts.put((Id)ar.get('accId'), (Integer)ar.get('cnt'));
        }
        // First account had one, rest should now have one each
        System.assertEquals(1, counts.get(accounts[0].Id));
        for (Integer i = 1; i < accounts.size(); i++) {
            System.assertEquals(1, counts.get(accounts[i].Id));
        }
    }
}
