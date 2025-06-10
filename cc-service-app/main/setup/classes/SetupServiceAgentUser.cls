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
        // Check all security permissions upfront
        checkSecurityAccess();

        // Get agent profile
        Profile p = getAgentProfile();

        // Create user or use existing one
        User u = getOrCreateUser(p);

        // Assign permission set licenses (PSL)
        assignPermissionSetLicenses(u);

        // Assign permission sets (PS)
        assignPermissionSets(u);
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

    private static User getOrCreateUser(Profile p) {
        List<User> users = [
            SELECT Id
            FROM User
            WHERE Username = :USERNAME
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];
        if (users.isEmpty()) {
            User u = new User();
            u.LastName = 'Coral Cloud Agent User';
            u.Email = USERNAME;
            u.Alias = 'ccagent';
            u.Username = USERNAME;
            u.CommunityNickname = NICKNAME;
            u.LocaleSidKey = 'en_US';
            u.TimeZoneSidKey = 'GMT';
            u.ProfileID = p.Id;
            u.LanguageLocaleKey = 'en_US';
            u.EmailEncodingKey = 'UTF-8';
            insert u;
            System.debug('Created user: ' + u.Username);
            return u;
        } else {
            System.debug('Skipped user creation');
            return users[0];
        }
    }

    private static void assignPermissionSetLicenses(User u) {
        Set<Id> targetPslIds = new Map<Id, PermissionSetLicense>(
                [
                    SELECT Id
                    FROM PermissionSetLicense
                    WHERE DeveloperName IN :PERM_SET_LICENSES
                    WITH SECURITY_ENFORCED
                ]
            )
            .keySet();

        List<PermissionSetLicenseAssign> userPslas = [
            SELECT PermissionSetLicenseId
            FROM PermissionSetLicenseAssign
            WHERE AssigneeId = :u.Id AND PermissionSetLicenseId IN :targetPslIds
            WITH SECURITY_ENFORCED
        ];
        Set<Id> userPslIds = new Set<Id>();
        for (PermissionSetLicenseAssign userPsla : userPslas) {
            userPslIds.add(userPsla.PermissionSetLicenseId);
        }
        targetPslIds.removeAll(userPslIds);

        if (!targetPslIds.isEmpty()) {
            List<PermissionSetLicenseAssign> pslas = new List<PermissionSetLicenseAssign>();
            for (Id pslId : targetPslIds) {
                PermissionSetLicenseAssign psla = new PermissionSetLicenseAssign();
                psla.AssigneeId = u.Id;
                psla.PermissionSetLicenseId = pslId;
                pslas.add(psla);
            }
            insert pslas;
            System.debug('Assigned permission set licenses: ' + PERM_SET_LICENSES);
        } else {
            System.debug('Skipped permission set license assignment.');
        }
    }

    private static void assignPermissionSets(User u) {
        Set<Id> targetPsIds = new Map<Id, PermissionSet>(
                [
                    SELECT Id
                    FROM PermissionSet
                    WHERE Name IN :PERM_SETS
                    WITH SECURITY_ENFORCED
                ]
            )
            .keySet();

        List<PermissionSetAssignment> userPsas = [
            SELECT PermissionSetId
            FROM PermissionSetAssignment
            WHERE AssigneeId = :u.Id AND PermissionSetId IN :targetPsIds
            WITH SECURITY_ENFORCED
        ];
        Set<Id> userPsIds = new Set<Id>();
        for (PermissionSetAssignment userPsa : userPsas) {
            userPsIds.add(userPsa.PermissionSetId);
        }
        targetPsIds.removeAll(userPsIds);

        if (!targetPsIds.isEmpty()) {
            List<PermissionSetAssignment> psaas = new List<PermissionSetAssignment>();
            for (Id psId : targetPsIds) {
                PermissionSetAssignment psa = new PermissionSetAssignment();
                psa.AssigneeId = u.Id;
                psa.PermissionSetId = psId;
                psaas.add(psa);
            }
            insert psaas;
            System.debug('Assigned permission set: ' + PERM_SETS);
        } else {
            System.debug('Skipped permission set assignment.');
        }
    }

    @TestVisible
    private static void checkSecurityAccess() {
        checkProfileAccess();
        checkUserAccess();
        checkPermissionSetLicenseAccess();
        checkPermissionSetLicenseAssignAccess();
        checkPermissionSetAccess();
        checkPermissionSetAssignmentAccess();
    }

    private static void checkProfileAccess() {
        if (!Schema.sObjectType.Profile.isAccessible()) {
            throw new SecurityException('Insufficient permissions to access Profile');
        }
    }

    private static void checkUserAccess() {
        if (!Schema.sObjectType.User.isAccessible() || !Schema.sObjectType.User.isCreateable()) {
            throw new SecurityException('Insufficient permissions to access or create User');
        }
    }

    private static void checkPermissionSetLicenseAccess() {
        if (!Schema.sObjectType.PermissionSetLicense.isAccessible()) {
            throw new SecurityException('Insufficient permissions to access PermissionSetLicense');
        }
    }

    private static void checkPermissionSetLicenseAssignAccess() {
        if (!Schema.sObjectType.PermissionSetLicenseAssign.isAccessible() || !Schema.sObjectType.PermissionSetLicenseAssign.isCreateable()) {
            throw new SecurityException('Insufficient permissions to access or create PermissionSetLicenseAssign');
        }
    }

    private static void checkPermissionSetAccess() {
        if (!Schema.sObjectType.PermissionSet.isAccessible()) {
            throw new SecurityException('Insufficient permissions to access PermissionSet');
        }
    }

    private static void checkPermissionSetAssignmentAccess() {
        if (!Schema.sObjectType.PermissionSetAssignment.isAccessible() || !Schema.sObjectType.PermissionSetAssignment.isCreateable()) {
            throw new SecurityException('Insufficient permissions to access or create PermissionSetAssignment');
        }
    }
}