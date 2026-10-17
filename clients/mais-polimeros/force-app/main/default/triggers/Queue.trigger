trigger Queue on Queue__c( after insert ){
	if( trigger.isAfter ) {
		if( trigger.isInsert ) {
			QueueBO.getInstance().executeProcessingQueue( trigger.new );
		}
	}
}