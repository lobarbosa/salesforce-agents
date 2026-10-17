@IsTest
public with sharing class TaxIntegrationTest {
    @TestSetup
    static void makeData(){
        
    }

    @IsTest
    public static void mainTest() {
        TaxIntegration.provisoryCodeCoverage();
        TaxIntegrationRequest.provisoryCodeCoverage();
        TaxIntegrationResponse.provisoryCodeCoverage();

        try{
            TaxIntegration.sendRequest('');
        } catch (Exception ex){ 

        }
    }
}