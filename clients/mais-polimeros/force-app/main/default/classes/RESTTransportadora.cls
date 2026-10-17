@RestResource(urlMapping='/api/v1/transportadora')
global class RESTTransportadora  {
    @HttpPost
    global static void doUpsert() {       

        String status;
        String mensagem;        
        String jsonResult = RestContext.request.requestBody.toString();

        try {
            Queue__c queue  = QueueBO.getInstance().createQueue( QueueEventNames.TRANSPORTADORA_TOTVS_TO_SALESFORCE.name(), jsonResult, false );
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
/* JSON Exemplo de Request
{
  "Transportadoras": [
    {
      "cnpj": "02342730000104",
      "codigo": "ABS99999",
      "nomeFantasia": "Transportadora 1",
      "razaoSocial": "Transportadora teste 1"
    },
    {
      "cnpj": "13109978000138",
      "codigo": "ABS88888",
      "nomeFantasia": "Transportadora 2",
      "razaoSocial": "Transportadora teste 2"
    }
  ]
}
*/