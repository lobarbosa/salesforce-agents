public class AccountTaskGPSController {
    private ApexPages.StandardController ctr;
    private Account acc;
    public Task newTask {get; private set;}
    
    public String valueLong { get; set; }
    public String valueLat { get; set; }
    public String completado = 'Completo';
    public String checkin = 'Checkin';
    
    public AccountTaskGPSController(ApexPages.StandardController controller){
        this.ctr = controller;
        newTask = new Task();
		newTask.WhatId = ctr.getId();
    } 
    public PageReference salvaAtividade(){
        newTask.Latitude__c = valueLat;
        newTask.Longitude__c = valueLong;
        newTask.Status = completado;
        DateTime dT = System.now();
        Date Hoje = date.newinstance(dT.year(), dT.month(), dT.day());
        newTask.ActivityDate = Hoje;
        newTask.Type = 'Check in - ' + newTask.Tipo__c;
        newTask.Subject = 'Check in - ' + newTask.Tipo__c;
        insert newTask;
		PageReference pageRef = new PageReference('/'+ctr.getId());        
	    pageRef.getParameters().put('inline','0');
	    pageRef.setRedirect(true);
    	return pageRef;
    }
}