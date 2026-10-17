({

    doInit: function(component, event, helper) {

        var recordId = component.get("v.recordId"); 
        var action = component.get("c.oppStatus");
        var actionPedido = component.get("c.checaPedidoDuplicado");
        
        action.setParams({
            recordId : recordId
        });
        action.setCallback(this, function(response) {

            if(response.getState() === "SUCCESS") {
                var stage = response.getReturnValue().StageName;
                var conferencia = response.getReturnValue().ConferenciaOK__c;
                var statusPreco = response.getReturnValue().StatusPreco__c;
                var statusCredito = response.getReturnValue().StatusCredito__c;
                var horarioLimite = response.getReturnValue().HorarioLimitePedido__c;
                var pedidoBloqueado = response.getReturnValue().PedidoBloqueadoHorario__c;

                component.set("v.observacaoHorario", '(Pedidos podem ser enviados até ' + horarioLimite + ')');

                if(stage == 'Conferência' && statusPreco.toLowerCase() == 'preço aprovado' && (statusCredito.toLowerCase() == 'cliente sem bloqueio' || statusCredito.toLowerCase() == 'crédito aprovado')){
                    // Checa pedido duplicado
                    console.log('>> Checa pedido duplicado');
                    
                    actionPedido.setParams({
                        oppId : recordId
                    });        
                    actionPedido.setCallback(this, function(response) {
                        component.set("v.disableBtnPreco", true);
                        component.set("v.disableBtnEnviar", true);

                        if(response.getState() === "SUCCESS") {
                            var pedidoDuplicado = response.getReturnValue();
                            console.log('>> Pedido duplicado: ' + pedidoDuplicado);

                            if (pedidoDuplicado != null && pedidoDuplicado != ''){
                                component.set("v.observacao", '*Esta Oportunidade já possui um pedido no Protheus: ' + pedidoDuplicado);
                                console.log('>> Set observação');
                            } else {
                                if(pedidoBloqueado != true){
                                    component.set("v.disableBtnEnviar", false);
                                }
                            }

                        } else {
                            let errors = response.getError();
                            if (errors && Array.isArray(errors) && errors.length > 0) {
                                console.log(errors[0].message);
                            }

                            var toast = $A.get("e.force:showToast");
                            toast.setParams({
                                "type"      : "error",
                                "title"     : "Erro ao checar duplicidade de pedido",
                                "message"   : errors[0].message
                            });
                            toast.fire();
                            $A.get("e.force:closeQuickAction").fire();

                        }

                    });	         
                    $A.enqueueAction(actionPedido);

                } else if (stage == 'Negociação' && conferencia == false) {
                    component.set("v.disableBtnPreco", false);
                    component.set("v.disableBtnEnviar", true);
                } else {
                    component.set("v.disableBtnPreco", true);
                    component.set("v.disableBtnEnviar", true);
                }

            } else {
                let errors = response.getError();
                if (errors && Array.isArray(errors) && errors.length > 0) {
                    console.log(errors[0].message);
                }

                var toast = $A.get("e.force:showToast");
                toast.setParams({
                    "type"      : "error",
                    "title"     : "Erro ao inicializar componente",
                    "message"   : errors[0].message
                });
                toast.fire();
                $A.get("e.force:closeQuickAction").fire();
            }
        });	         
        $A.enqueueAction(action);

    },
    
    handleClickSyncOpp : function(component, event, helper) {

        var recordId = component.get("v.recordId");
        var action = component.get("c.converteOportunidade");
        var sendToTotvs = component.get("c.sendOrderToTotvs"); 
        var actionToast = component.get("c.getMessage");
        // let button = component.find('btnSyncOpp');

        // button.set('v.disabled',true);
        component.set("v.showSpinner", true);
        component.set("v.disableBtnEnviar", true);

        action.setParams({
            recordId : recordId
        });
        action.setCallback(this, function(response) {
            console.log('>> response.getState(): ' + response.getState());
            console.log(+ response);

            if(response.getState() === "SUCCESS") {
                sendToTotvs.setParams({
                    queue : response.getReturnValue() 
                });

                sendToTotvs.setCallback(this, function(responseTotvs){
                    console.log('>> responseTotvs.getState(): ' + response.getState());
                    if(responseTotvs.getState() === "SUCCESS") {
                        window.setTimeout(
                                $A.getCallback(function() {
                                    component.set("v.showSpinner", false);
                                    $A.get('e.force:closeQuickAction').fire();						                        
                                }), 500
                            );
                        if(responseTotvs.getReturnValue().Status__c === "ERROR"){
                            alert("Erro na integração.");
                            component.set("v.disableBtnEnviar", false);
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
                        // button.set('v.disabled',false);
                    }
                    $A.get('e.force:refreshView').fire();
                });
                $A.enqueueAction(sendToTotvs);
            }  else {

                let errors = response.getError();
                if (errors && Array.isArray(errors) && errors.length > 0) {
                    console.log(errors[0].message);
                }

                var toast = $A.get("e.force:showToast");
                toast.setParams({
                    "type"      : "error",
                    "title"     : "Atenção",
                    "message"   : errors[0].message
                });
                toast.fire();
                $A.get("e.force:closeQuickAction").fire();

                window.setTimeout(
                    $A.getCallback(function() {
                        component.set("v.showSpinner", false);
                        $A.get('e.force:closeQuickAction').fire();						                        
                    }), 500
                );
            }           
            $A.get('e.force:refreshView').fire();
        });	         
        $A.enqueueAction(action);
    },

    handleClickSyncPreco : function(component, event, helper) {
        
        let button 		= component.find('btnSyncPreco');
        button.set('v.disabled',true);
        var recordId    = component.get("v.recordId"); 
        var action      = component.get("c.getPrecoOppQueue"); 
        var sendToTotvs = component.get("c.sendPriceToTotvs"); 
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
                                    $A.get('e.force:closeQuickAction').fire();					                        
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