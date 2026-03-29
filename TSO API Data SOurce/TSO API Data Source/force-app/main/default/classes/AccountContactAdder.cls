/**
 * Utility class to add a Contact to Accounts with no existing Contacts.
 * Follows bulkification and governor limits best practices.
 */
public with sharing class AccountContactAdder {
    /**
     * Inserts one Contact for each Account that has no contacts.
     *
     * @param accountIds List of Account Ids to process.
     * @param contactFirstName First name for the new Contact.
     * @param contactLastName Last name for the new Contact.
     */
    public static void addContactIfNone(List<Id> accountIds, String contactFirstName, String contactLastName) {
        if (accountIds == null || accountIds.isEmpty()) {
            return;
        }
        // Query only accounts with no contacts.
        List<Account> accountsWithoutContacts = [
            SELECT Id
            FROM Account
            WHERE Id IN :accountIds
            AND Id NOT IN (SELECT AccountId FROM Contact)
        ];
        if (accountsWithoutContacts.isEmpty()) {
            return;
        }
        List<Contact> newContacts = new List<Contact>();
        for (Account acc : accountsWithoutContacts) {
            newContacts.add(new Contact(
                AccountId = acc.Id,
                FirstName = contactFirstName,
                LastName = contactLastName
            ));
        }
        insert newContacts;
    }
}
