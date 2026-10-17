({
    handleClick : function(component, event, helper) {
        let button 		= component.find('btnSync');
        button.set('v.disabled',true);
        var recordId    = component.get("v.recordId"); 
        var action      = component.get("c.getQuote"); 
        var sendToTotvs = component.get("c.sendToTotvs"); 
        var actionToast = component.get("c.getMessage");
        
        component.set("v.showSpinner", true);

        action.setParams({
            recordId : recordId
        });
        
        action.setCallback(this, function(response) {
            if(response.getState() === "SUCCESS") {
                sendToTotvs.setParams({
                    queue : response.getReturnValue() 
                });
                
                sendToTotvs.setCallback(this, function(responseTotvs){
                    if(responseTotvs.getState() === "SUCCESS") {
                        window.setTimeout(
                                $A.getCallback(function() {
                                    component.set("v.showSpinner", false);						                        
                                }), 500
                            );
                        if(responseTotvs.getReturnValue().Status__c === "ERROR"){
                        	alert("Erro na integração.");
                        }else{
                            
                            actionToast.setParams({
                                recordId : recordId
                            });
                                            
                            actionToast.setCallback(this, function(response) {
                                if(response.getState() === "SUCCESS") { 
                                    alert(response.getReturnValue());
                                }
                                $A.get('e.force:refreshView').fire();
                            });
                            $A.enqueueAction(actionToast); 
                    	}
                        button.set('v.disabled',false);
                    }
                    $A.get('e.force:refreshView').fire();
                });
                $A.enqueueAction(sendToTotvs);
            }             
            $A.get('e.force:refreshView').fire();
        });	         
        $A.enqueueAction(action);
        
        
        
    }
})