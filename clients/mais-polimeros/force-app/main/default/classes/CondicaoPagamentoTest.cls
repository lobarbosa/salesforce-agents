@isTest
public class CondicaoPagamentoTest {

    @IsTest
    static void test_method_one(){

        Test.startTest();
			RestRequest req = new RestRequest();
			req.requestBody = Blob.valueOf('{  "paymentConditions": [    {      "code": "AXidgus78",      "paymentCondition": "40 / 50 / 94",      "description": "A prazo",      "isActive": false    },    {      "code": "AXidgus9",      "paymentCondition": "40 / 50 / 94",      "description": "A prazo escalonavel",      "isActive": false    }  ]}');
            RestContext.request = req;
			RestResponse res = new RestResponse();
			RestContext.response = res;
			RESTCondicaoPagamento.doUpsert();
        Test.stopTest();
        
    }

    @IsTest
    static void test_method_two(){

        Test.startTest();
			RestRequest req = new RestRequest();
			req.requestBody = Blob.valueOf('{  "paymentConditions": [    {      "code": "AXidgus78",      "paymentCondition": "40 / 50 / 94",      "description": "A prazo",      "isActive": true    },    {      "paymentCondition": "40 / 50 / 94",      "description": "A prazo escalonavel",      "isActive": false    }  ]}');
            RestContext.request = req;
			RestResponse res = new RestResponse();
			RestContext.response = res;
			RESTCondicaoPagamento.doUpsert();
        Test.stopTest();
        
    }

    
}