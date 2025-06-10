public with sharing class SetupServiceAgentUser {
    private final static String USERNAME = Test.isRunningTest()
        ? 'agent-user@mock.com'
        : 'agent-%%SF_CC_PLACEHOLDER_USERNAME%%';
    private final static String NICKNAME = Test.isRunningTest()
        ? 'ccagent-mock'
        : 'ccagent';

    @TestVisible
    private final static Set<String> PERM_SET_LICENSES = new Set<String>{
        'AgentforceServiceAgentUserPsl',
        'GenieDataPlatformStarterPsl'
    };

    private final static Set<String> PERM_SETS = new Set<String>{
        'AgentforceServiceAgentUser',
        'GenieUserEnhancedSecurity',
        'Coral_Cloud_Service_Agent'
    };

    public static void setup() {
        checkSecurityAccess();
        Profile profile = getAgentProfile();
        User user = createOrRetrieveUser(profile);
        assignPermissionSetLicenses(user);
        assignPermissionSets(user);
    }

    private static Profile getAgentProfile() {
        return [
            SELECT Id
            FROM Profile
            WHERE Name = 'Einstein Agent User'
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];
    }

    private static User createOrRetrieveUser(Profile profile) {
        List<User> users = [
            SELECT Id
            FROM User
            WHERE Username = :USERNAME
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];
        if (users.isEmpty()) {
            User user = new User();
            user.LastName = 'Coral Cloud Agent User';
            user.Email = USERNAME;
            user.Alias = 'ccagent';
            user.Username = USERNAME;
            user.CommunityNickname = NICKNAME;
            user.LocaleSidKey = 'en_US';
            user.TimeZoneSidKey = 'GMT';
            user.ProfileID = profile.Id;
            user.LanguageLocaleKey = 'en_US';
            user.EmailEncodingKey = 'UTF-8';
            insert user;
            System.debug('Created user: ' + user.Username);
            return user;
        } else {
            System.debug('Skipped user creation');
            return users[0];
        }
    }

    private static void assignPermissionSetLicenses(User user) {
        Set<Id> targetPslIds = new Map<Id, PermissionSetLicense>([
            SELECT Id
            FROM PermissionSetLicense
            WHERE DeveloperName IN :PERM_SET_LICENSES
            WITH SECURITY_ENFORCED
        ]).keySet();

        List<PermissionSetLicenseAssign> userPslas = [
            SELECT PermissionSetLicenseId
            FROM PermissionSetLicenseAssign
            WHERE AssigneeId = :user.Id AND PermissionSetLicenseId IN :targetPslIds
            WITH SECURITY_ENFORCED
        ];
        for (PermissionSetLicenseAssign userPsla : userPslas) {
            targetPslIds.remove(userPsla.PermissionSetLicenseId);
        }

        if (!targetPslIds.isEmpty()) {
            List<PermissionSetLicenseAssign> pslas = new List<PermissionSetLicenseAssign>();
            for (Id pslId : targetPslIds) {
                PermissionSetLicenseAssign psla = new PermissionSetLicenseAssign();
                psla.AssigneeId = user.Id;
                psla.PermissionSetLicenseId = pslId;
                pslas.add(psla);
            }
            insert pslas;
            System.debug('Assigned permission set licenses: ' + PERM_SET_LICENSES);
        } else {
            System.debug('Skipped permission set license assignment.');
        }
    }

    private static void assignPermissionSets(User user) {
        Set<Id> targetPsIds = new Map<Id, PermissionSet>([
            SELECT Id
            FROM PermissionSet
            WHERE Name IN :PERM_SETS
            WITH SECURITY_ENFORCED
        ]).keySet();

        List<PermissionSetAssignment> userPsas = [
            SELECT PermissionSetId
            FROM PermissionSetAssignment
            WHERE AssigneeId = :user.Id AND PermissionSetId IN :targetPsIds
            WITH SECURITY_ENFORCED
        ];
        for (PermissionSetAssignment userPsa : userPsas) {
            targetPsIds.remove(userPsa.PermissionSetId);
        }

        if (!targetPsIds.isEmpty()) {
            List<PermissionSetAssignment> psas = new List<PermissionSetAssignment>();
            for (Id psId : targetPsIds) {
                PermissionSetAssignment psa = new PermissionSetAssignment();
                psa.AssigneeId = user.Id;
                psa.PermissionSetId = psId;
                psas.add(psa);
            }
            insert psas;
            System.debug('Assigned permission sets: ' + PERM_SETS);
        } else {
            System.debug('Skipped permission set assignment.');
        }
    }

    @TestVisible
    private static void checkSecurityAccess() {
        // Check CRUD permissions for Profile
        if (!Schema.sObjectType.Profile.isAccessible()) {
            throw new SecurityException(
                'Insufficient permissions to access Profile'
            );
        }

        // Check CRUD permissions for User
        if (
            !Schema.sObjectType.User.isAccessible() ||
            !Schema.sObjectType.User.isCreateable()
        ) {
            throw new SecurityException(
                'Insufficient permissions to access or create User'
            );
        }

        // Check CRUD permissions for PermissionSetLicense
        if (!Schema.sObjectType.PermissionSetLicense.isAccessible()) {
            throw new SecurityException(
                'Insufficient permissions to access PermissionSetLicense'
            );
        }

        // Check CRUD permissions for PermissionSetLicenseAssign
        if (
            !Schema.sObjectType.PermissionSetLicenseAssign.isAccessible() ||
            !Schema.sObjectType.PermissionSetLicenseAssign.isCreateable()
        ) {
            throw new SecurityException(
                'Insufficient permissions to access or create PermissionSetLicenseAssign'
            );
        }

        // Check CRUD permissions for PermissionSet
        if (!Schema.sObjectType.PermissionSet.isAccessible()) {
            throw new SecurityException(
                'Insufficient permissions to access PermissionSet'
            );
        }

        // Check CRUD permissions for PermissionSetAssignment
        if (
            !Schema.sObjectType.PermissionSetAssignment.isAccessible() ||
            !Schema.sObjectType.PermissionSetAssignment.isCreateable()
        ) {
            throw new SecurityException(
                'Insufficient permissions to access or create PermissionSetAssignment'
            );
        }
    }
}
