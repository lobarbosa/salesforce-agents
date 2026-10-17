@isTest
public  class TransportadoraTest {
    @IsTest
    static void test_method_one(){
        
        Test.startTest();
            RestRequest req = new RestRequest();
			req.requestBody = Blob.valueOf('{  "Transportadoras": [    {      "cnpj": "02342730000104",      "codigo": "ABS99999",      "nomeFantasia": "Transportadora 1",      "razaoSocial": "Transportadora teste 1"    },    {      "cnpj": "13109978000138",      "codigo": "ABS88888",      "nomeFantasia": "Transportadora 2",      "razaoSocial": "Transportadora teste 2"    }  ]}');
            RestContext.request = req;
			RestResponse res = new RestResponse();
			RestContext.response = res;
			RESTTransportadora.doUpsert();
        Test.stopTest();
        
    }

    @IsTest
    static void test_method_two(){
        
        Test.startTest();
            RestRequest req = new RestRequest();
			req.requestBody = Blob.valueOf('{  "Transportadoras": [    {      "nomeFantasia": "Transportadora 1",      "razaoSocial": "Transportadora teste 1"    },    {      "cnpj": "13109978000138",      "codigo": "ABS88888",      "nomeFantasia": "Transportadora 2",      "razaoSocial": "Transportadora teste 2"    }  ]}');
            RestContext.request = req;
			RestResponse res = new RestResponse();
			RestContext.response = res;
			RESTTransportadora.doUpsert();
        Test.stopTest();
        
    }
}