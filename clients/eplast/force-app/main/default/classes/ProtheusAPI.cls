public with sharing class ProtheusAPI {

    public static ProtheusResponse getClientByCNPJ(String cnpj){
        Map<String, String> queryParams = new Map<String, String>{'param1' => cnpj};
        RequestInfo requestInfo = ProtheusRequest.get('/WSEPLCLI', queryParams);

        return treatGetClientResponse(requestInfo);
    }

    public static void sendClientToProtheus(Account acc){
        ProtheusInsertClientModel client = AccountAdapter.toProtheus(acc);
        Map<String, ProtheusInsertClientModel[]> body = new Map<String, ProtheusInsertClientModel[]>{
                                                                                'Cliente' => new ProtheusInsertClientModel[]{
                                                                                    client
                                                                                }
                                                                            };

        RequestInfo requestInfo = ProtheusRequest.post('/WSEPLCLI', body);   

        treatSendClientResponse(requestInfo, acc);
    }

    private static ProtheusResponse treatGetClientResponse(RequestInfo requestInfo){
        if(requestInfo.response.getStatusCode() >= 400)
            return null;

        Logger.save('Get Client from Protheus', requestInfo.request, requestInfo.response);

        return ((ProtheusGetClientModel) JSON.deserialize(requestInfo.response.getBody(), ProtheusGetClientModel.class));
    }

    private static void treatSendClientResponse(RequestInfo requestInfo, Account acc){
        if(requestInfo.response.getStatusCode() == 201){
            ProtheusInsertClientSuccessBody success = (ProtheusInsertClientSuccessBody) JSON.deserialize(requestInfo.response.getBody(), ProtheusInsertClientSuccessBody.class);
            acc.ProtheusId__c = success.Ret_cliente.codigo_erp;

            update acc;
        }

        Logger.save('Send Client To Protheus', requestInfo.request, requestInfo.response);
    }
}