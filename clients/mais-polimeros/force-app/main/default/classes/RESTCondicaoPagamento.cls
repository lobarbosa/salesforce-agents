/**
 *    @author Lucas Oliveira
 *    @class WS for integration of CondicaoPagamento__c object
*/
@RestResource(urlMapping='/api/v1/condpag')
global with sharing class RESTCondicaoPagamento  {
    @HttpPost
    global static void doUpsert() {       

        String status;
        String mensagem;        
        String jsonResult = RestContext.request.requestBody.toString();

        try {
            Queue__c queue  = QueueBO.getInstance().createQueue( QueueEventNames.CONDICAOPAGAMENTO_TOTVS_TO_SALESFORCE.name(), jsonResult, false );
            Queue__c result = QueueDAO.getInstance().getQueueById( queue.Id )[0]; 
            status = result.Status__c ;
            mensagem = Util.getString( result.ExceptionStackTrace__c ).replace('\n', ' ');
        } catch ( Exception ex ) {
            status = 'ERROR';
            mensagem = ex.getMessage();
        }

        RestContext.response.addHeader('Content-Type', 'application/json');
        if(status == 'ERROR'){
          RestContext.response.responseBody = Blob.valueOf( mensagem );  
          return;
        }
        RestContext.response.responseBody = Blob.valueOf( Util.jsonResponse( status, mensagem ) );
    }
}