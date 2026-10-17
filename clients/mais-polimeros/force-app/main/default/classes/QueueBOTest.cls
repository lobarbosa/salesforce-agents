/*
	@autor Lucas Oliveira
	@class Classe de teste do objeto Queue
*/

@isTest(SeeAllData=TRUE)
private class QueueBOTest {
	
	@isTest static void test1() {
		Queue__c queue = InstanceToClassCoverage.QUEUE_ESTOQUE();
		insert queue;

		String  queueId 				= queue.ID;
		String  queueEventName 			= queue.EventName__c;
		String  queuepayload			= queue.Payload__c;
		Boolean queueIgnoredByTrigger	= queue.IgnoredByTrigger__c;
		String  queueDmlException		= queue.ExceptionStackTrace__c;
		String  queueStatus 			= queue.Status__c;

		QueueBO.getInstance().createQueue(queueEventName, queuepayload, queueIgnoredByTrigger);
		QueueBO.getInstance().createQueue(queueId, queueEventName, queuepayload, queueIgnoredByTrigger);
		QueueBO.getInstance().updateQueue(queueId, queueDmlException);
		QueueBO.getInstance().updateQueue(queueId, queueDmlException, queueDmlException );
		//QueueBO.getInstance().reprocessQueue();
		QueueDAO.getInstance().getQueueById(queueId);
		QueueDAO.getInstance().getQueueByStatus(queueStatus);

		QueueDAO.getInstance().getQueueByEventName(QueueEventNames.ESTOQUE_SALESFORCE_TO_TOTVS.name());

	}

}