@isTest
public class ProdutoTest {
    @IsTest
    static void test_method_one(){
        
        Test.startTest();
            RestRequest req = new RestRequest();
			req.requestBody = Blob.valueOf('{  "Products": [    {      "productCode": "ABS99999",      "productName": "ABS99999",      "description": "High Perform ABS",      "techDescription": "High Perform ABS for tires",      "family": "ESPEC",      "familyDescription": "ACRILONITRILO BUTADIENO ESTIRE",      "isActive": true    },    {      "productCode": "ABS88888",      "productName": "ABS88888",      "description": "High Perform ABS",      "techDescription": "High Perform ABS for slim tires",      "family": "ESPEC",      "familyDescription": "ACRILONITRILO BUTADIENO ESTIRED 2 PACKS",      "isActive": true    }  ]}');
            RestContext.request = req;
			RestResponse res = new RestResponse();
			RestContext.response = res;
			RESTProduto.doUpsert();
        Test.stopTest();
        
    }

    @IsTest
    static void test_method_two(){
        
        Test.startTest();
            RestRequest req = new RestRequest();
			req.requestBody = Blob.valueOf('{  "Products": [    {      "productName": "ABS99999",      "description": "High Perform ABS",      "techDescription": "High Perform ABS for tires",      "family": "ESPEC",      "familyDescription": "ACRILONITRILO BUTADIENO ESTIRE",      "isActive": true    },    {      "productCode": "ABS88888",      "productName": "ABS88888",      "description": "High Perform ABS",      "techDescription": "High Perform ABS for slim tires",      "family": "ESPEC",      "familyDescription": "ACRILONITRILO BUTADIENO ESTIRED 2 PACKS",      "isActive": true    }  ]}');
            RestContext.request = req;
			RestResponse res = new RestResponse();
			RestContext.response = res;
			RESTProduto.doUpsert();
        Test.stopTest();
        
    }
}