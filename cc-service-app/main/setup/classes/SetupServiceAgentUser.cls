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
        try {
            validateSecurityAccess();
            Profile profile = getAgentProfile();
            User user = getOrCreateUser(profile);
            assignPermissionSetLicenses(user);
            assignPermissionSets(user);
        } catch (Exception e) {
            System.debug('Error during setup: ' + e.getMessage());
            throw new SecurityException('Setup failed due to security issues.');
        }
    }

    private static void validateSecurityAccess() {
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

    private static Profile getAgentProfile() {
        return [
            SELECT Id
            FROM Profile
            WHERE Name = 'Einstein Agent User'
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];
    }

    private static User getOrCreateUser(Profile profile) {
        List<User> users = [
            SELECT Id
            FROM User
            WHERE Username = :USERNAME
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];
        if (users.isEmpty()) {
            User newUser = new User(
                LastName = 'Coral Cloud Agent User',
                Email = USERNAME,
                Alias = 'ccagent',
                Username = USERNAME,
                CommunityNickname = NICKNAME,
                LocaleSidKey = 'en_US',
                TimeZoneSidKey = 'GMT',
                ProfileID = profile.Id,
                LanguageLocaleKey = 'en_US',
                EmailEncodingKey = 'UTF-8'
            );
            insert newUser;
            System.debug('Created user: ' + newUser.Username);
            return newUser;
        } else {
            System.debug('Skipped user creation');
            return users[0];
        }
    }

    private static void assignPermissionSetLicenses(User user) {
        // Get permission set licenses (PSL)
        Set<Id> targetPslIds = new Map<Id, PermissionSetLicense>(
                [
                    SELECT Id
                    FROM PermissionSetLicense
                    WHERE DeveloperName IN :PERM_SET_LICENSES
                    WITH SECURITY_ENFORCED
                ]
            )
            .keySet();

        // Exclude already assigned PSLs
        List<PermissionSetLicenseAssign> userPslas = [
            SELECT PermissionSetLicenseId
            FROM PermissionSetLicenseAssign
            WHERE AssigneeId = :user.Id AND PermissionSetLicenseId IN :targetPslIds
            WITH SECURITY_ENFORCED
        ];
        Set<Id> userPslIds = new Set<Id>();
        for (PermissionSetLicenseAssign userPsla : userPslas) {
            userPslIds.add(userPsla.PermissionSetLicenseId);
        }
        targetPslIds.removeAll(userPslIds);

        // Assign PSLs to user
        if (targetPslIds.size() > 0) {
            List<PermissionSetLicenseAssign> pslas = new List<PermissionSetLicenseAssign>();
            for (Id pslId : targetPslIds) {
                PermissionSetLicenseAssign psla = new PermissionSetLicenseAssign();
                psla.AssigneeId = user.Id;
                psla.PermissionSetLicenseId = pslId;
                pslas.add(psla);
            }
            insert pslas;
            System.debug(
                'Assigned permission set licenses: ' + PERM_SET_LICENSES
            );
        } else {
            System.debug('Skipped permission set license assignment.');
        }
    }

    private static void assignPermissionSets(User user) {
        // Get permission sets (PS)
        Set<Id> targetPsIds = new Map<Id, PermissionSet>(
                [
                    SELECT Id
                    FROM PermissionSet
                    WHERE Name IN :PERM_SETS
                    WITH SECURITY_ENFORCED
                ]
            )
            .keySet();

        // Exclude already assigned PSs
        List<PermissionSetAssignment> userPsas = [
            SELECT PermissionSetId
            FROM PermissionSetAssignment
            WHERE AssigneeId = :user.Id AND PermissionSetId IN :targetPsIds
            WITH SECURITY_ENFORCED
        ];
        Set<Id> userPsIds = new Set<Id>();
        for (PermissionSetAssignment userPsa : userPsas) {
            userPsIds.add(userPsa.PermissionSetId);
        }
        targetPsIds.removeAll(userPsIds);

        // Assign PSs to user
        if (targetPsIds.size() > 0) {
            List<PermissionSetAssignment> psaas = new List<PermissionSetAssignment>();
            for (Id psId : targetPsIds) {
                PermissionSetAssignment psa = new PermissionSetAssignment();
                psa.AssigneeId = user.Id;
                psa.PermissionSetId = psId;
                psaas.add(psa);
            }
            insert psaas;
            System.debug('Assigned permission set: ' + PERM_SETS);
        } else {
            System.debug('Skipped permission set assignment.');
        }
    }
}
