public class QueueBO {
    private static final QueueBO instance = new QueueBO();    
    private QueueBO(){}
    
    public static QueueBO getInstance() {
        return instance;
    }

    public enum QueueStatus { CREATED, SUCCESS, ERROR }

    private static map<String, IProcessingQueue> mapToExecute;     
    static {
        mapToExecute = new map<String, IProcessingQueue>();  
        mapToExecute.put( QueueEventNames.QUOTE_SALESFORCE_TO_TOTVS.name(),   new QuoteIntegrationBO() );                 
        mapToExecute.put( QueueEventNames.ESTOQUE_SALESFORCE_TO_TOTVS.name(), new EstoqueIntegrationBO() );                  
        mapToExecute.put( QueueEventNames.ACCOUNT_SALESFORCE_TO_TOTVS.name(), new AccountIntegrationBO() );                  
        mapToExecute.put( QueueEventNames.ACCOUNT_TOTVS_TO_SALESFORCE.name(), new AccountIntegrationBO() );                  
        mapToExecute.put( QueueEventNames.CONDICAOPAGAMENTO_TOTVS_TO_SALESFORCE.name(), new CondicaoPagamentoIntegrationBO() );                  
        mapToExecute.put( QueueEventNames.PRODUTO_TOTVS_TO_SALESFORCE.name(), new ProdutoIntegrationBO() );                 
        mapToExecute.put( QueueEventNames.NF_TOTVS_TO_SALESFORCE.name(), new NotaFiscalIntegrationBO() );
        mapToExecute.put( QueueEventNames.NF_DEVOLUCAO.name(), new NotaFiscalIntegrationBO() );
        mapToExecute.put( QueueEventNames.OPPORTUNIDADE_SALESFORCE_TO_TOTVS.name(), new OrderIntegrationBO() );                      
        mapToExecute.put( QueueEventNames.ALT_OPPORTUNIDADE_SALESFORCE_TO_TOTVS.name(), new OrderIntegrationBO() );                      
        mapToExecute.put( QueueEventNames.EXC_OPPORTUNIDADE_SALESFORCE_TO_TOTVS.name(), new OrderIntegrationBO() );                      
        mapToExecute.put( QueueEventNames.CHANGE_STATUS_ITEMS.name(), new OrderIntegrationBO() );  
        mapToExecute.put( QueueEventNames.FRETE_SALESFORCE_TO_TOTVS.name(), new FreteIntegrationBO() );                         
        mapToExecute.put( QueueEventNames.TRANSPORTADORA_TOTVS_TO_SALESFORCE.name(), new TransportadoraIntegrationBO() );                 
    }  
     
    public Queue__c createQueue( String eventName, String payLoad, Boolean ignoredByTrigger ) {
        Queue__c queue              = new Queue__c();
        queue.EventName__c          = eventName;
        queue.Payload__c            = payLoad;
        queue.Status__c             = QueueStatus.CREATED.name();
        queue.IgnoredByTrigger__c   = ignoredByTrigger;

        System.debug('queue: ' + queue);
        
        insert queue;
        return queue;
    }
     
    public Queue__c createQueue( String recordId, String eventName, String payLoad, Boolean ignoredByTrigger ) {
        Queue__c queue              = new Queue__c();
        queue.EventName__c          = eventName;
        queue.Payload__c            = payLoad;
        queue.Status__c             = QueueStatus.CREATED.name();
        queue.RecordId__c           = recordId;
        queue.IgnoredByTrigger__c   = ignoredByTrigger;
        
        insert queue;
        return queue;
    }    
    
    public void updateQueue( String queueId, String dmlExceptionStackTrace ) {
        Queue__c queue                  = new Queue__c();
        queue.Id                        = queueId;
        queue.Status__c                 = dmlExceptionStackTrace.equals('') ? QueueStatus.SUCCESS.name() : QueueStatus.ERROR.name();
        queue.ExceptionStackTrace__c    = dmlExceptionStackTrace;       
        
        QueueDAO.getInstance().updateData( queue );  
    }

    public void updateQueue( String queueId, String response, String dmlExceptionStackTrace ) {
        Queue__c queue                  = new Queue__c();
        queue.Id                        = queueId;
        queue.Status__c                 = dmlExceptionStackTrace.equals('') ? QueueStatus.SUCCESS.name() : QueueStatus.ERROR.name();
        queue.Response__c               = response;
        queue.ExceptionStackTrace__c    = dmlExceptionStackTrace;    
        
        QueueDAO.getInstance().updateData( queue );
    }
    
    public void reprocessQueue() {
        List<Queue__c> queuesResult = QueueDAO.getInstance().getQueueByStatus( new List<String>{ QueueStatus.CREATED.name() } );
        executeProcessingQueue( queuesResult );
    }    

    public void executeProcessingQueue( List<Queue__c> queueToProcessing ) {
        for( Queue__c queue : queueToProcessing ) {
            //if( Test.isRunningTest() ) return;
            if( queue.IgnoredByTrigger__c ) continue;
            mapToExecute.get( queue.EventName__c ).executeQueue( queue.Id, queue.RecordId__c, queue.EventName__c, queue.Payload__c );  
        }
    }
}