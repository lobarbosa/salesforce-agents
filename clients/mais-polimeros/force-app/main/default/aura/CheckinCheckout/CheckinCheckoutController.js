({
    onInit: function(component, event, helper) {

        helper.carregaTipoCheckin(
            $A.getCallback(function handleServerResponse(serverResponse) {
                component.set('v.tipoOptions', serverResponse.tipos);
                component.set('v.tipoSelectedValue', serverResponse.selectedTipoId);
            })
            
        );

        var action = component.get("c.getSearchRelated");
        action.setParams({
            "accId": component.get("v.recordId")
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var res = response.getReturnValue();
                component.set("v.wrapperList", res);
            }
        });
        $A.enqueueAction(action);

        // helper.carregaTipoContato(
        //     $A.getCallback(function handleServerResponse(serverResponse) {
        //         component.set('v.tipoContatoOptions', serverResponse.tipos);
        //         component.set('v.tipoContatoSelectedValue', serverResponse.selectedTipoId);
        //     })
        // );

        function positionSuccess(position) {
            component.set('v.lat', position.coords.latitude);
            component.set('v.lon', position.coords.longitude);
            component.set('v.disableSave', false);
            component.set('v.loaded', true);
        }

        function positionError(error){

            component.set('v.disableSave', false);

            var errorMessage = '';
            switch(error.code) {
                case error.PERMISSION_DENIED:
                    errorMessage = "Requisição de geolocalização negada para o usuário.";
                    break;
                case error.POSITION_UNAVAILABLE:
                    errorMessage = "Informação de geolocalização indisponível.";
                    break;
                case error.TIMEOUT:
                    errorMessage = "O tempo da requisição expirou.";
                    break;
                case error.UNKNOWN_ERROR:
                    errorMessage = "Ocorreu um erro desconhecido.";
                    break;
            }

            var toast = $A.get("e.force:showToast");
            toast.setParams({
                "type"      : "error",
                "title"     : "Error",
                "message"   : errorMessage
            });
            component.set('v.loaded', true);
            toast.fire();

            $A.get("e.force:closeQuickAction").fire();
        }
        
        if (navigator.geolocation) {
            navigator.geolocation.getCurrentPosition($A.getCallback(positionSuccess), $A.getCallback(positionError), {enableHighAccuracy: true, timeout: 5000, maximumAge: 0});
        } else {

            var toast = $A.get("e.force:showToast");
            toast.setParams({
                "type"      : "error",
                "title"     : "Erro na geolocalização",
                "message"   : "Geolocalização indisponível"
            });
            component.set('v.loaded', true);
            component.set('v.disableSave', false);
            toast.fire();

            $A.get("e.force:closeQuickAction").fire();
        }
    },

    saveTask : function(component, event, helper) {

        var idConta = component.get('v.recordId');
        var comentario = component.get('v.comentario');
        var tipo = component.get('v.tipoSelectedValue');
        var latitude = component.get('v.lat');
        var longitude = component.get('v.lon');
        var contato = component.get('v.contatoSelectedValue');

        component.set("v.showSpinner", true);

        var action = component.get("c.checkIn"); 
        action.setParams({
            idConta: idConta,
            lat: latitude,
            lon: longitude,
            tipo: tipo,
            idContato: contato,
            comentario: comentario
        });
        action.setCallback(this, function(response) {
            
            if(response.getState() === "SUCCESS") {
                window.setTimeout(
                    $A.getCallback(function() {
                        $A.get('e.force:closeQuickAction').fire();						                        
                    }), 500
                );

            } else {
                var showToast = $A.get("e.force:showToast");
                showToast.setParams({
                    "type"      : "error",
                    "title"     : "Erro",
                    "message"   : "Erro ao criar efetuar o Checkin"
                });
            }
            $A.get('e.force:refreshView').fire();
            
        });	         
        $A.enqueueAction(action);
        component.set("v.showSpinner", false);
    },

    cancelTask : function(component, event, helper) {

        component.set("v.showSpinner", false);
        window.setTimeout(
            $A.getCallback(function() {
                $A.get('e.force:closeQuickAction').fire();						                        
            }), 100
        );

    },

    // searchResult: function(component, event, helper) {

    //     var action = component.get("c.getSearchRelated");
    //     action.setParams({
    //         "tipo": component.get("v.tipoContatoSelectedValue"),
    //         "searchName": component.get("v.searchName"),
    //         "accId": component.get("v.recordId")
    //     });
    //     action.setCallback(this, function(response) {
    //         var state = response.getState();
    //         if (state === "SUCCESS") {
    //             var res = response.getReturnValue();
    //             component.set("v.wrapperList", res);
    //         }
    //     });
    //     $A.enqueueAction(action);
    // },

    limpaContato: function(component, event, helper) {
        component.set("v.searchName", '');
        component.set("v.wrapperList", '');
    }

})