({
    init : function (component, event) {
        // Find the component whose aura:id is "flowData"
        var flow = component.find("flowData");
        var inputVariables = [
            {
                name: "recordId",
                type: "String",
                value: component.get("v.recordId")
            }
        ]
        var flowName = "";
        switch (component.get("v.opp.StageName")) {
            case "Registro da Oportunidade":
                component.set("v.waitMap", true);
                component.set("v.waitPSL", false);
                component.set("v.showFlow", false);
                break;
            case "Proposta Comercial":
                component.set("v.waitMap", false);
                component.set("v.waitPSL", true);
                component.set("v.showFlow", false);
                break;
            case "Engajamento": 
                flowName = "KN_EngajamentoOportunidade";
                component.set("v.showFlow", true);
                component.set("v.waitMap", false);
                component.set("v.waitPSL", false);
                break;
            case "Negociação e Proposta":
                flowName = "NegociacaoProposta";
                component.set("v.showFlow", true);
                component.set("v.waitMap", false);
                component.set("v.waitPSL", false);
                break;
            case "Fechamento":
                flowName = "Fechamento";
                component.set("v.showFlow", true);
                component.set("v.waitMap", false);
                component.set("v.waitPSL", false);
                break;
            default:
                component.set("v.showFlow", false);
                component.set("v.waitMap", false);
                component.set("v.waitPSL", false);
        }
        console.log(component.get("v.opp.StageName"));
        flow.startFlow(flowName, inputVariables);
        
    },
    changeStage : function (component){
        $A.get('e.force:refreshView').fire();
        switch (component.get("v.opp.StageName")) {
        }
    },
})