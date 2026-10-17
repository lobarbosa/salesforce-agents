@isTest
public class ScheduleRefreshTokenMSProjectTest {
    @isTest
    static void testOne() {
        Test.setMock(HttpCalloutMock.class, new MSProjectIntegrationsMock());
        insert new MSProjectIntegration__c( FedAuthPart1__c = 'FedAuth=77u/PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0idXRmLTgiPz48U1A+VjcsMGguZnxtZW1iZXJzaGlwfDEwMDMyMDAwOWNjY2Q5YmVAbGl2ZS5jb20sMCMuZnxtZW1iZXJzaGlwfjdGFbS5iciAc29tb3NGtvwMDAwMDAsMTMyMjY3Nzk1bmVhZ2lsaXR5LmNvwxMzIzMjIzMzA2MzANTgwMDAwMDAwLDEzMjMyMzE5NDYzNjk',
                                            FedAuthPart2__c = '5NjYyOSwwLjAuMC4wMDE4ZS00YjA3LWIxNjYtODVjNmI1YWFkYzE2LCwsZThiNTk0YLDIsNGU1MWE2YTctTMtOGFlNS00ZmU5LDM3LGU4YjU5NGEzLThhZTUtNGZlOLDAsLCwsMjY1MN3VWZHS05YWY2LTcDQ2Nzc0Mzk5OTk5OTk5OTlhZjYtNzAyMTY0NThiMSxQZFVDbjBawMjE2NDU4YjAzNywsMCwwptcjVUTHNSZFBwQ1hCQzZYSDVPZn', 
                                            FedAuthPart3__c = '3JJZU5pcy94TTFjY29QRVUydUJkby9kVkswMHM5UnplekhBbW8xdWxaYXVlbENPOWNwNWgzR1JlUW1CMkhWdjhFTi9lcE1POHZzeWxzUVk4Ukk0MFVOWlN0Y2kzdHVRWkxrYdFMxYXlJK2dYdnMrUWI4ZUpPNXSNms5V2tlWjlHVjcwcUJYRkllZOVUlaMXBhdBEYXFWZGFBYmM1bmVpTlZ5Y1BkbU9FK2VQTm15VlIvlloa3RGYVlqWDJrKysz', 
                                            FedAuthPart4__c = 'FBhVkFxT1BsGS1M5R0E5NU4xQ09QcmhDajZd0hKcWFFV1FvUHNtQ1VNWStOVWVjbDlGTUcxQ3FIcWo2WjJIOHpSMkxNdWtJa0kyRU5hMlpVKanErbzZ2Yk04ckNqZVh5OUlvZDlsU2ZDdnZhbzlIdHBGVE2S2c9PTwvU1A+; path=/; SameSite=None; secure; HttpOnly;',
                                            FormDigestValue__c = '0xDB9098012AEF0AF44AA5FB247A4661CB2930E9DAB6F010F4C63FA82878A52E1DCB27442AFE6075988ACBCC5D03C55057687F9F7D76F8A3AE2CEA50861D6DF99B,24 Apr 2020 20:17:43 -0000', 
                                            MicrosoftLoginURL__c = 'Test', 
                                            rtFaPart1__c = 'rtFa=f4TAcOS0pB76eWsaKxfFocKGTLohXC12456z4epoDjgmNEU1MUE2QTctMDE4RS00QjA3LUIxNjYtODVDNkI1QUFEQzE2u2O+QpJulVByqX+AZ8d0VSUIDChz+o8tjHdhEGJW+bBUjNA3LW+2O8tp12341HesqY2VG/JlXG4x0lZN7UGoD1QU1pKlfa5zB123456BUN9KjakYvZJnbdwzZrXzazFPnsVJurwE+d4bF45H+efU73dgjM06QI', 
                                            rtFaPart2__c = 'yYibjBSCX7rlnuTMf5xxBG4Hf5JJTp8FdNo4bLsGFsOp6zG/Mj+zC7j6aCXEh5BuQ44tJcefDVXgyNeStoDIOaiNVhmektr+bvCx+11LvTIttuzinEmCLPPmOKuqbWE/4rnqG+0HGtFjR1iyRbVmQ6ac6mXx375vsrljw2GXYqbRshX7K2BpHu+0UAAAA=; domain=sharepoint.com; path=/; SameSite=None; secure; HttpOnly;', 
                                            SharepointURL__c = 'Test', 
                                            Username__c = 'Test', 
                                            Password__c = 'Test' 
                                            );

        Test.startTest();
        String sch = '0 0 23 * * ? *';
        String jobID = System.schedule('Refresh MSProject Tokens' + system.now(), sch, new ScheduleRefreshTokenMSProject());
        Test.stopTest();
    }
}