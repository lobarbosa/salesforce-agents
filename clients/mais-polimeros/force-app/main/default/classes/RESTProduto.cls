/**
 *    @author Lucas Oliveira
 *    @class WS for integration of Product2 object
*/
@RestResource(urlMapping='/api/v1/product')
global class RESTProduto  {
    @HttpPost
    global static void doUpsert() {       

        String status;
        String mensagem;        
        String jsonResult = RestContext.request.requestBody.toString();

        try {
            Queue__c queue  = QueueBO.getInstance().createQueue( QueueEventNames.PRODUTO_TOTVS_TO_SALESFORCE.name(), jsonResult, false );
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
/* JSON RECIVED SAMPLE
{
  "Products": [
    {
      "productCode": "ABS99999",
      "productName": "ABS99999",
      "description": "High Perform ABS",
      "techDescription": "High Perform ABS for tires",
      "family": "ESPEC",
      "familyDescription": "ACRILONITRILO BUTADIENO ESTIRE",
      "isActive": true
    },
    {
      "productCode": "ABS88888",
      "productName": "ABS88888",
      "description": "High Perform ABS",
      "techDescription": "High Perform ABS for slim tires",
      "family": "ESPEC",
      "familyDescription": "ACRILONITRILO BUTADIENO ESTIRED 2 PACKS",
      "isActive": true
    }
  ]
}
*/