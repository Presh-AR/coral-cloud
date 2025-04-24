public with sharing class ExperienceController {
    @TestVisible
    private static Integer PAGE_SIZE = 9;

    /**
     * Endpoint that retrieves the sessions associated with an experience and a date
     * @param experienceId Experience ID
     * @param timestamp Timestamp representing the date on which the sessions take place
     * @return List of Session__c records
     */
    @AuraEnabled(cacheable=true scope='global')
    public static List<Session__c> getExperienceSessionsForDate(
        Id experienceId,
        Long timestamp
    ) {
        if (timestamp == null) {
            throw new IllegalArgumentException('Timestamp cannot be null');
        }
        Date dateFilter = Datetime.newInstance(timestamp).date();
        return [
            SELECT
                Id,
                Booked_Slots__c,
                Capacity__c,
                End_Time__c,
                Percentage_Booked__c,
                Start_Time__c,
                Status__c,
                Experience__r.Price__c
            FROM Session__c
            WHERE Experience__c = :experienceId AND Date__c = :dateFilter
            WITH USER_MODE
            ORDER BY Start_Time__c ASC
            LIMIT 10
        ];
    }

    /**
     * Retrieves experiences of a given type in a paginated format
     * @param type Experience type
     * @param pageNumber Page number. First page starts at 1.
     * @return Paginated set of experiences
     */
    @AuraEnabled(Cacheable=true scope='global')
    public static PagedResult getExperiences(String type, Integer pageNumber) {
        String whereClause = '';
        if (type != null || type != '') {
            whereClause = 'WHERE Type__c = :type';
        }
        Integer pageSize = ExperienceController.PAGE_SIZE;
        Integer offset = (pageNumber - 1) * pageSize;
        return new PagedResult(
            pageSize,
            pageNumber,
            Database.countQuery(
                'SELECT count() FROM Experience__c ' + whereClause
            ),
            Database.query(
                'SELECT Id, Name, Description__c, Rating__c, Picture_URL__c FROM Experience__c ' +
                    whereClause +
                    ' WITH USER_MODE' +
                    ' ORDER BY Name LIMIT :pageSize OFFSET :offset'
            )
        );
    }

    public with sharing class PagedResult {
        @AuraEnabled
        public Integer pageSize { get; set; }

        @AuraEnabled
        public Integer pageNumber { get; set; }

        @AuraEnabled
        public Integer totalItemCount { get; set; }

        @AuraEnabled
        public SObject[] records { get; set; }
    }
}
