public class MSProjectTokenIntegrations {
    public static MSProjectIntegration__c sett = MSProjectIntegration__c.getOrgDefaults();

    @future(callout=true)
    public static void refreshTokens() {
        authUser();
    }

    public static void authUser() {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(sett.MicrosoftloginURL__c + '/extSTS.srf');
        req.setMethod('POST');

        req.setHeader('Content-Type', 'application/x-www-form-urlencoded'); 
        req.setHeader('Accept', 'application/json; odata=verbose'); 

        String userName = sett.Username__c;
        String password = sett.Password__c;

        String body = '<s:Envelope xmlns:s="http://www.w3.org/2003/05/soap-envelope" xmlns:a="http://www.w3.org/2005/08/addressing" xmlns:u="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd"> <s:Header> <a:Action s:mustUnderstand="1">http://schemas.xmlsoap.org/ws/2005/02/trust/RST/Issue</a:Action> <a:ReplyTo> <a:Address>http://www.w3.org/2005/08/addressing/anonymous</a:Address> </a:ReplyTo> <a:To s:mustUnderstand="1">https://login.microsoftonline.com/extSTS.srf</a:To> <o:Security s:mustUnderstand="1" xmlns:o="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd"> <o:UsernameToken>' + 
        '<o:Username>' + userName + '</o:Username>' +
        '<o:Password>' + password + '</o:Password>' +
        '</o:UsernameToken> </o:Security> </s:Header> <s:Body> <t:RequestSecurityToken xmlns:t="http://schemas.xmlsoap.org/ws/2005/02/trust"> <wsp:AppliesTo xmlns:wsp="http://schemas.xmlsoap.org/ws/2004/09/policy"> <a:EndpointReference> <a:Address>agilitynetworksbrazil.sharepoint.com</a:Address> </a:EndpointReference> </wsp:AppliesTo> <t:KeyType>http://schemas.xmlsoap.org/ws/2005/05/identity/NoProofKey</t:KeyType> <t:RequestType>http://schemas.xmlsoap.org/ws/2005/02/trust/Issue</t:RequestType> <t:TokenType>urn:oasis:names:tc:SAML:1.0:assertion</t:TokenType> </t:RequestSecurityToken> </s:Body> </s:Envelope>';
        req.setBody(body);

        Http http = new Http();
        HTTPResponse res = http.send(req);
        
        Dom.Document doc = new Dom.Document();
        doc.load(res.getBody());
        String json = MyXmlParser.parseDocumentToJson(doc);

        MSProjectSecurityTokenResponse r = (MSProjectSecurityTokenResponse) System.JSON.deserialize(json, MSProjectSecurityTokenResponse.class);

        getAccessToken(r.Body.RequestSecurityTokenResponse.RequestedSecurityToken.BinarySecurityToken);
    }

    private static void getAccessToken(String binarySecurityToken) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(sett.SharepointURL__c + '/_forms/default.aspx?wa=wsignin1.0');
        req.setMethod('POST');

        req.setHeader('Content-Type', 'application/x-www-form-urlencoded'); 
        req.setHeader('Accept', 'application/json; odata=verbose'); 

        req.setBody(binarySecurityToken);

        Http http = new Http();
        HTTPResponse res = http.send(req);

        String cookies = res.getHeader('Set-Cookie');
        String rtFa = 'rtFa=' + cookies.substringBetween('rtFa=', 'HttpOnly') + 'HttpOnly;';
        String FedAuth = 'FedAuth=' + cookies.substringBetween('FedAuth=', 'HttpOnly') + 'HttpOnly;';

        sett.rtFaPart1__c = rtFa.substring(0, 255); 
        sett.rtFaPart2__c = rtFa.substring(255, 510); 
        if(rtFa.length() <= 765)
            sett.rtFaPart3__c = rtFa.substring(510, rtFa.length());
        else {
            sett.rtFaPart3__c = rtFa.substring(510, 765);
            sett.rtFaPart4__c = rtFa.substring(765, rtFa.length());
        }

        sett.FedAuthPart1__c = FedAuth.substring(0, 255); 
        sett.FedAuthPart2__c = FedAuth.substring(255, 510); 
        if(FedAuth.length() <= 765)
            sett.FedAuthPart3__c = FedAuth.substring(510, FedAuth.length());
        else {
            sett.FedAuthPart3__c = FedAuth.substring(510, 765);

            if(FedAuth.length() <= 1020)
                sett.FedAuthPart4__c = FedAuth.substring(765, FedAuth.length());
            else {
                sett.FedAuthPart4__c = FedAuth.substring(765, 1020);
                sett.FedAuthPart5__c = FedAuth.substring(1020, rtFa.length());
            }
        }

        getDigestValue(rtFa + FedAuth);
    }

    private static void getDigestValue(String cookies) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(sett.SharepointURL__c + '/_api/contextinfo');
        req.setMethod('POST');

        req.setHeader('Content-Type', 'application/x-www-form-urlencoded'); 
        req.setHeader('Content-Length', '0'); 
        req.setHeader('Cookie', cookies);

        Http http = new Http();
        HTTPResponse res = http.send(req);

        String json;
        if(!Test.isRunningTest()) {
            Dom.Document doc = new Dom.Document();
            doc.load(res.getBody());
            json = MyXmlParser.parseDocumentToJson(doc);
        } else {
            json = res.getBody();
        }

        MSProjectDigestValueResponse r = (MSProjectDigestValueResponse) System.JSON.deserialize(json, MSProjectDigestValueResponse.class);
        sett.FormDigestValue__c = r.FormDigestValue;
        update sett;
    }
}