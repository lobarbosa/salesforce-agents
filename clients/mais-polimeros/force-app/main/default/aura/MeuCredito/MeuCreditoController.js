({
    doInit: function(component, event, helper) {
        var action = component.get("c.getAccountData");
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var data = response.getReturnValue();

                // Aplicando formatação de moeda
                data.formattedPolimeros = data.SaldoLimiteMaisPolimeros__c ? 
                    "R$ " + parseFloat(data.SaldoLimiteMaisPolimeros__c).toLocaleString("pt-BR", { minimumFractionDigits: 2 }) : "R$ 0,00";

                data.formattedBv = data.SaldoLimiteBv__c ? 
                    "R$ " + parseFloat(data.SaldoLimiteBv__c).toLocaleString("pt-BR", { minimumFractionDigits: 2 }) : "R$ 0,00";

                data.formattedSifra = data.SaldoLimiteSifra__c ? 
                    "R$ " + parseFloat(data.SaldoLimiteSifra__c).toLocaleString("pt-BR", { minimumFractionDigits: 2 }) : "R$ 0,00";

                component.set("v.accountData", data);
            }
        });
        $A.enqueueAction(action);
    }
})