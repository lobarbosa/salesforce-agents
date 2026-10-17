({
    handleClick : function (component) {
        var recordId = component.get("v.recordId");
        
        if(recordId !== undefined ){
            var button 		= component.find('btnClone');
        	button.set('v.disabled',true);
            var action = component.get("c.toCloneQuote"); 
            action.setParams({
                recordId : recordId 
            });
            action.setCallback(this, function(response) {    
                if(response.getState() === "SUCCESS") {
                var navToObj = $A.get("e.force:navigateToSObject");
    			navToObj.setParams({
                  "recordId": response.getReturnValue(),
                  "slideDevName": "related"
                });
                navToObj.fire();
                window.setTimeout( $A.getCallback(function() {
                    		var editRec = $A.get("e.force:editRecord");
                            editRec.setParams({
                              "recordId": response.getReturnValue()
                            });
                            editRec.fire();
              		  }), 500);
                button.set('v.disabled',false);
            }            
            });
            $A.enqueueAction(action);
            
            
        }
    }
})