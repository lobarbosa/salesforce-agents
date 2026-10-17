/**
 *    @author Lucas Oliveira
 *    @class WS for integration of NotaFiscal__c object
*/
@RestResource(urlMapping='/api/v1/nf')
global class RESTNotaFiscal {
    @HttpPost
    global static void doUpsert() {       

        String status;
        String mensagem;        
        String jsonResult = RestContext.request.requestBody.toString();

        try {
            Queue__c queue  = QueueBO.getInstance().createQueue( QueueEventNames.NF_TOTVS_TO_SALESFORCE.name(), jsonResult, false );
            Queue__c result = QueueDAO.getInstance().getQueueById( queue.Id )[0]; 
            status = result.Status__c ;
            mensagem = Util.getString( result.ExceptionStackTrace__c ).replace('\n', ' ');
        } catch ( Exception ex ) {
            status = 'ERROR';
            mensagem = ex.getMessage();
        }

        RestContext.response.addHeader('Content-Type', 'application/json');
        if(status == 'ERROR'){
          RestContext.response.responseBody =  Blob.valueOf( mensagem ) ;  
          return;
        }
        RestContext.response.responseBody = Blob.valueOf( Util.jsonResponse( status, mensagem ) );
    }
}

/* JSON RECIVED SAMPLE
{
  "invoices": [
    {
      "clientCode": "A84VWK01",
      "issueDate": "21/12/2012",
      "number": 15478966354789520,
      "status": "Faturado"
      "items": [
        {
          "itemId": "HWQML0293QWE"
        },
        {
          "itemId": "HWQML0293QTW"
        },
        {
          "itemId": "HWQML0293QZX"
        }
      ]
    }
  ]
}
*/