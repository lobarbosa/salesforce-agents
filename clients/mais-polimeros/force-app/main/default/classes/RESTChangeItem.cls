/**
 *    @author Pedro Castilho
 *    @class WS for integration of Product2 object
*/
@RestResource(urlMapping='/api/v1/changeStatusItems')
global class RESTChangeItem  {
    @HttpPost
    global static void changeStatusItem() {       

        String status;
        String mensagem;        
        String jsonResult = RestContext.request.requestBody.toString();

        try {
            Queue__c queue  = QueueBO.getInstance().createQueue( QueueEventNames.CHANGE_STATUS_ITEMS.name(), jsonResult, false );
            Queue__c result = QueueDAO.getInstance().getQueueById( queue.Id )[0];
            status = result.Status__c ;
            mensagem = Util.getString( result.ExceptionStackTrace__c ).replace('\n', ' ');
        } catch ( Exception ex ) {
            status = 'ERROR';
            mensagem = ex.getMessage();
        }

        RestContext.response.addHeader('Content-Type', 'application/json');
        RestContext.response.responseBody = Blob.valueOf( Util.jsonResponse( status, mensagem ) );
    }
}
/* JSON RECIVED SAMPLE
{
  "Items": [
    {
      "id": "0060S000006z61XQAQ",
      "status": "Faturado"
    },
	{
      "id": "00k0S0000055vCUQAY",
      "status": "Cancelado"
    }
  ]
}
*/