@isTest
public class fsl_TestDataFactory {
    
    /***********************************
     * Static Variables
     ***********************************/    

    private static Id householdRecordTypeId;
    private static Id organizationRecordTypeId;
    
    /***********************************
     * Constants
     ***********************************/

    // Accounts
	private static final String ACCOUNT_BASE_NAME = 'Wright Household';
    private static final String ORGANIZATION_BASE_NAME = 'Big Corp';
    // Affiliations
    private static final String AFFILIATION_STATUS_CURRENT = 'Current';
    private static final String AFFILIATION_STATUS_FORMER = 'Former';
    // Contacts
    private static final String CONTACT_BASE_FIRST_NAME = 'David';
    private static final String CONTACT_BASE_MIDDLE_NAME = 'Captain';
    private static final String CONTACT_BASE_LAST_NAME = 'Wright';
    private static final Date CONTACT_BASE_BIRTHDATE = Date.today().addYears(-21);
    // Groups
    private static final String PUBLIC_GROUP_NAME = 'Test Group Test';
    private static final String GROUP_TYPE_REGULAR = 'Regular';
    // Users
    private static final String EMAIL_ENCODING_KEY = 'UTF-8';
    private static final String STANDARD_USER_USERNAME = 'standarduser' + DateTime.now().getTime() + '@agtests.com';
    private static final String STANDARD_USER_EMAIL = 'testing@testthings.com';
    private static final String STANDARD_USER_FIRSTNAME = 'Tester';
    private static final String STANDARD_USER_LASTNAME = 'Testerson';
    private static final String STANDARD_USER_ALIAS = 'tester';
    private static final String STANDARD_USER_NICKNAME = 'TestUser193948';
    private static final String STANDARD_USER_PROFILE_NAME = 'Standard User';


    /***********************************
     * Accounts
     ***********************************/

    /**
     * Create accounts with a household record type
     * No DML - returns unsaved list of sObjects
     * @param Integer Number of records to create
     */

    public static List<Account> createHouseholdAccounts(
        Integer numberOfHouseholds
    ) {
        List<Account> lstHouseholds = new List<Account>();
        if (householdRecordTypeId == null) {
            householdRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('HH_Account').getRecordTypeId();
        }
        for (Integer i = 0; i < numberOfHouseholds; i++) {
            lstHouseholds.add( 
                new Account(
                    Name = ACCOUNT_BASE_NAME + String.valueOf(i), 
                    RecordTypeId = householdRecordTypeId
                )
            );
        }
        return lstHouseholds;
    }

    /**
     * Create accounts with an organization record type
     * No DML - returns unsaved list of sObjects
     * @param Integer Number of records to create
     */

    public static List<Account> createOrganizationAccounts(
        Integer numberOfOrganizations
    ) {
        List<Account> lstOrganizations = new List<Account>();
        if (organizationRecordTypeId == null) {
            organizationRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Organization').getRecordTypeId();
        }
        for (Integer i = 0; i < numberOfOrganizations; i++) {
            lstOrganizations.add( 
                new Account(
                    Name = ORGANIZATION_BASE_NAME + String.valueOf(i), 
                    RecordTypeId = organizationRecordTypeId
                )
            );
        }
        return lstOrganizations;
    }


    /***********************************
     * Affiliations
     ***********************************/

    /**
     * Create affiliations
     * No DML - returns unsaved list of sObjects
     * @param lstOrganizations Accounts for Contacts to be affiliated with
     * @param lstContacts Contacts to create affiliations for
     */

    public static List<npe5__Affiliation__c> createAffiliations(
        List<Account> lstOrganizations,
        List<Contact> lstContacts
    ) {
        List<npe5__Affiliation__c> lstAffiliations = new List<npe5__Affiliation__c>();
        for (Account org : lstOrganizations) {
            for (Contact ct : lstContacts) {
                lstAffiliations.add( 
                    new npe5__Affiliation__c(
                        npe5__Status__c = AFFILIATION_STATUS_CURRENT,
                        npe5__Contact__c = ct.Id,
                        npe5__Organization__c = org.Id
                    )
                );
            }
        }
        return lstAffiliations;
    }


    /***********************************
     * Contacts
     ***********************************/

    /**
     * Create contact sObjects without accounts
     * No DML - returns unsaved list of sObjects
     * @param Integer Number of contacts to create for each account
     */

    public static List<Contact> createContacts(
        Integer numberOfContacts
    ) {
        return generateContactsWithDefaults(numberOfContacts);
    }

    /**
     * Create contact sObjects for a preexisting list of accounts
     * No DML - returns unsaved list of sObjects
     * @param List<Account> Parent accounts for created contacts
     * @param Integer Number of contacts to create for each account
     * @return Contact[] New contacts
     */

    public static List<Contact> createContacts(
        List<Account> lstParentAccounts, Integer numberOfContacts
    ) {
        List<Contact> lstContacts = new List<Contact>();
        for (Account acc : lstParentAccounts) {
            List<Contact> lstAccountContacts = generateContactsWithDefaults(numberOfContacts);
            for (Contact ct : lstAccountContacts) {
                ct.AccountId = acc.Id;
            }
            lstContacts.addAll(lstAccountContacts);
        }
        return lstContacts;
    }

    /**
     * Create a list of default contacts with FirstName, LastName, Email, and Birthdate
     *     to be used by overloaded createContacts method
     * @param numberOfContacts Number of contacts to create
     */

    private static List<Contact> generateContactsWithDefaults(
        Integer numberOfContacts
    ) {
        List<Contact> lstDefaultCts = new List<Contact>();
        for (Integer i = 0; i < numberOfContacts; i++) {
            lstDefaultCts.add(
                new Contact(
                    FirstName  = CONTACT_BASE_FIRST_NAME + String.valueOf(i),
                    MiddleName = CONTACT_BASE_MIDDLE_NAME + String.valueOf(i),
                    LastName   = CONTACT_BASE_LAST_NAME + String.valueOf(i),
                    Email      = CONTACT_BASE_FIRST_NAME + CONTACT_BASE_LAST_NAME + String.valueOf(i) + '@testingstuff.com',
                    Birthdate  = CONTACT_BASE_BIRTHDATE.addYears(-i).addMonths(i)
                )
            );
        }
        return lstDefaultCts;
    }


    /***********************************
     * Groups
     ***********************************/

    /**
     * Create regular public group
     * No DML - returns a single, unsaved public group
     */

    public static Group createRegularGroup() {
        Group newGroup = new Group(
            Name = PUBLIC_GROUP_NAME, 
            Type = GROUP_TYPE_REGULAR, 
            DoesIncludeBosses = false, 
            DoesSendEmailToMembers = false
        );
        return newGroup;
    }

    /***********************************
     * Opportunities
     ***********************************/

    /**
     * Create opportunity sObjects for a list of contacts
     * No DML - returns unsaved list of sObjects
     * @param List<Contact> Parent primary contacts for created opps
     * @param Integer Number of opportunities to create for each contact
     * @return Opportunity[] List of opportunity sObjects
     */

     public static List<Opportunity> createOpportunities(
        List<Contact> lstContacts, 
        Integer numberOfOpportunities
     ) {
        List<Opportunity> lstOpps = new List<Opportunity>();
        for (Integer i = 0; i < numberOfOpportunities; i++) {
            lstOpps.add(
                new Opportunity(
                    npsp__Primary_Contact__c = lstContacts[0].Id
                )
            );
        }
        return lstOpps;
     }


    /***********************************
     * Users
     ***********************************/

    /**
     * Create internal standard user
     * No DML - returns unsaved sObject
     */

    public static User createStandardInternalUser() {
        
        Profile profile = [SELECT Id FROM Profile WHERE Name = :STANDARD_USER_PROFILE_NAME LIMIT 1];

        User u = new User();
        u.IsActive          = true;
        u.ProfileId         = profile.Id;
        u.TimeZoneSidKey    = UserInfo.getTimeZone().toString();
        u.LocaleSidKey      = UserInfo.getLocale();
        u.LanguageLocaleKey = UserInfo.getLocale();
        u.EmailEncodingKey  = EMAIL_ENCODING_KEY;
        u.Username          = STANDARD_USER_USERNAME;
        u.Email             = STANDARD_USER_EMAIL;
        u.FirstName         = STANDARD_USER_FIRSTNAME;
        u.LastName          = STANDARD_USER_LASTNAME;
        u.Alias             = STANDARD_USER_ALIAS;
        return u;
    }


}