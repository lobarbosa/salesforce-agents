({
    navigateToCriacaso : function(component, event, helper) {
        var flowName = component.get("v.flowName");
        var communityUrl = "https://konectabr--konectdev.sandbox.my.site.com/cskonecta/s/criacaso?flow=" + encodeURIComponent(flowName); // Passa o nome do Flow na URL

        var navService = component.find("navService");
        var pageReference = {
            type: "standard__webPage",
            attributes: {
                url: communityUrl
            }
        };
        navService.navigate(pageReference);
    }
})