@RestResource(urlMapping='/api/v1/nfdev')
global class RESTNotaFiscalDevolucao  {

    @HttpPost
    global static void RESTNotaFiscalDevolucao() {       

        String status;
        String mensagem;        
        String jsonResult = RestContext.request.requestBody.toString();
        system.debug('jsonResult: ' + jsonResult);

        try {
            Queue__c queue  = QueueBO.getInstance().createQueue( QueueEventNames.NF_DEVOLUCAO.name(), jsonResult, false );
            Queue__c result = QueueDAO.getInstance().getQueueById(queue.Id)[0];
            status = result.Status__c ;
            mensagem = Util.getString(result.ExceptionStackTrace__c).replace('\n', ' ');
        } catch ( Exception ex ) {
            status = 'ERROR';
            mensagem = ex.getMessage();
        }

        RestContext.response.addHeader('Content-Type', 'application/json');
        RestContext.response.responseBody = Blob.valueOf( Util.jsonResponse(status, mensagem) );
    }
}