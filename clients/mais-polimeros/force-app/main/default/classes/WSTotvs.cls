public class WSTotvs {

    // public String responseBody;
    private String endApi;
    private String payload;

    public WSTotvs(){
        endApi = '';
        payload = '';
    }

    public WSTotvs(String paramEndApi, String paramPayload) {
        System.debug('endApi: ' + paramEndApi);
        System.debug('payload: ' + paramPayload);
        endApi = paramEndApi;
        payload = paramPayload;
    }

    public String Invoke(){

        IntegrationParams__c ip = IntegrationParams__c.getInstance();

        Integer timeout = (Integer.valueOf(ip.Timeout__c ?? 120));
        if (timeout > 120){
            timeout = 120000;
        } else {
            timeout = timeout * 1000;
        }

        String endpoint = '';
        String metodo = 'POST';

        switch on endApi {
            when 'priceProcessor' {
                endpoint = ip.URI_PriceProcessor__c;
            }
            when 'estoqueProcessor' {
                endpoint = ip.URI_StorageProcessor__c;
            }
            when 'accountProcessor' {
                endpoint = ip.URI_ClientProcessor__c;
            }
            when 'opportunityProcessor' {
                endpoint = ip.URI_OrderProcessor__c;
            }
            when 'freteProcessor' {
                endpoint = ip.URI_FreteProcessor__c;
            }
            when 'estoqueFiliaisProcessor' {
                metodo = 'GET';
                endpoint = ip.URI_EstoqueFiliaisProcessor__c;
            }
        }

        System.debug('endpoint: ' + endpoint);

        HttpRequest request = new HttpRequest();
        request.setMethod(metodo);
        request.setHeader('Content-Type', 'application/json');
        request.setBody(payload);

        System.debug('timeout: ' + timeout);
        request.setTimeout(timeout);

        if(!ip.AtivarAutenticacao__c){
            request.setEndpoint(ip.URI_API__c + endpoint);
        } else if(ip.AtivarAutenticacao__c && ip.UsarSSL__c){
            request.setEndpoint('callout:Protheus' + endpoint);
        } else {
            request.setHeader('Authorization', 'Basic ' + EncodingUtil.base64Encode((Blob.valueOf(ip.Username__c + ':' + ip.Password__c))));
            System.debug('setEndpoint: ' + ip.URI_API__c + endpoint);
            request.setEndpoint(ip.URI_API__c + endpoint);
        }

        Http http = new Http();
        HTTPResponse resp = http.send(request);
        System.debug('WSTotvs resp: ' + resp);

        String responseBody = '';
        if(resp.getStatusCode() == 201 || resp.getStatusCode() == 200 ){
            responseBody = resp.getBody();
        } else {
            resp.setStatusCode(500);
            responseBody = String.valueOf(resp.getStatusCode());
        }

        System.debug('WSTotvs responseBody: ' + responseBody);
        return responseBody;
    }


    // public String priceProcessor(String payload) {
    //     Map<String, Object> result = new Map<String, Object>();                        
    //     HttpRequest req            = new HttpRequest();
    //     HTTPResponse res           = new HTTPResponse();            
    //     Http http                  = new Http(); 
        

    //     if(auth.AtivarAutenticacao__c){
    //         req.setEndpoint('callout:Protheus' + auth.URI_PriceProcessor__c);
    //     } else {
    //         String uri = auth.URI_API__c+auth.URI_PriceProcessor__c;
    //         System.debug('>>> uri: ' + uri);
    //         req.setEndpoint( uri );
    //     }

    //     req.setMethod( 'POST' ); 
    //     req.setBody( payload );         
    //     System.debug('>>> payload: ' + payload);  
    //     req.setTimeout( timeout );
    //     req.setHeader('Content-Type', 'application/json');
        
    //     res = http.send(req);
    //     System.debug('>>> WSTotvs res: ' + res);

    //     if( res.getStatusCode() != 201 && res.getStatusCode() != 200 ){
    //         res.setStatusCode( 500 );
    //         return String.valueOf(res.getStatusCode());
    //     }                
        
    //     return res.getBody();
    // }

    // public String estoqueProcessor(String payload) {
    //     Map<String, Object> result = new Map<String, Object>();                        
    //     HttpRequest req            = new HttpRequest();
    //     HTTPResponse res           = new HTTPResponse();            
    //     Http http                  = new Http(); 
        
    //     if(auth.AtivarAutenticacao__c){
    //         req.setEndpoint('callout:Protheus' + auth.URI_StorageProcessor__c);
    //     } else {
    //         String uri = auth.URI_API__c+auth.URI_StorageProcessor__c;
    //         System.debug('>>> uri: ' + uri);
    //         req.setEndpoint( uri );
    //     }

    //     req.setMethod( 'POST' ); 
    //     req.setBody( payload );           
    //     req.setTimeout( timeout );
    //     req.setHeader('Content-Type', 'application/json');
        
    //     res = http.send(req);

    //     if( res.getStatusCode() != 201 && res.getStatusCode() != 200 ){
    //         res.setStatusCode( 500 );
    //         return String.valueOf(res.getStatusCode());
    //     }                 
        
    //     return res.getBody();
    // }   
    
    // public String accountProcessor(String payload) {
    //     Map<String, Object> result = new Map<String, Object>();                                
    //     HttpRequest req            = new HttpRequest();
    //     HTTPResponse res           = new HTTPResponse();            
    //     Http http                  = new Http(); 

    //     if(auth.AtivarAutenticacao__c){
    //         req.setEndpoint('callout:Protheus' + auth.URI_ClientProcessor__c);
    //     } else {
    //         String uri = auth.URI_API__c+auth.URI_ClientProcessor__c;
    //         System.debug('>>> uri: ' + uri);
    //         req.setEndpoint( uri );
    //     }

    //     req.setMethod( 'POST' ); 
    //     req.setBody( payload );           
    //     req.setTimeout( timeout );
    //     req.setHeader('Content-Type', 'application/json');
        
    //     res = http.send(req);

    //     if( res.getStatusCode() != 201 && res.getStatusCode() != 200){
    //         res.setStatusCode( 500 );
    //         return String.valueOf(res.getStatusCode());
    //     }                 
        
    //     return res.getBody();
    // }   
    
    // public String opportunityProcessor(String payload) {
    //     Map<String, Object> result = new Map<String, Object>();                            
    //     HttpRequest req            = new HttpRequest();
    //     HTTPResponse res           = new HTTPResponse();            
    //     Http http                  = new Http(); 
        
    //     if(auth.AtivarAutenticacao__c){
    //         req.setEndpoint('callout:Protheus' + auth.URI_OrderProcessor__c);
    //     } else {
    //         String uri = auth.URI_API__c + auth.URI_OrderProcessor__c;
    //         System.debug('>>> uri: ' + uri);
    //         req.setEndpoint( uri );
    //     }

    //     req.setMethod( 'POST' ); 
    //     req.setBody( payload );           
    //     req.setTimeout( timeout );
    //     req.setHeader('Content-Type', 'application/json');
        
    //     res = http.send(req);

    //     if( res.getStatusCode() != 201  && res.getStatusCode() != 200){
    //         res.setStatusCode( 500 );
    //         return String.valueOf(res.getStatusCode());
    //     }                 
        
    //     return res.getBody();
    // }

    // public String freteProcessor(String payload) {
    //     Map<String, Object> result = new Map<String, Object>();                           
    //     HttpRequest req            = new HttpRequest();
    //     HTTPResponse res           = new HTTPResponse();            
    //     Http http                  = new Http(); 
        
    //     if(auth.AtivarAutenticacao__c){
    //         req.setEndpoint('callout:Protheus' + auth.URI_FreteProcessor__c);
    //     } else {
    //         String uri = auth.URI_API__c + auth.URI_FreteProcessor__c;
    //         System.debug('>>> uri: ' + uri);
    //         req.setEndpoint( uri );
    //     }

    //     req.setMethod( 'POST' ); 
    //     req.setBody( payload );           
    //     req.setTimeout( timeout );
    //     req.setHeader('Content-Type', 'application/json');
        
    //     res = http.send(req);

    //     if( res.getStatusCode() != 201  && res.getStatusCode() != 200 ){
    //         res.setStatusCode( 500 );
    //         return String.valueOf(res.getStatusCode());
    //     }                 
        
    //     return res.getBody();
    // }
    
    public String priceProcessor(String payload) {
        return '';
    }

    public String estoqueProcessor(String payload) {
        return '';
    }

    public String accountProcessor(String payload) {
        return '';
    }

    public String opportunityProcessor(String payload) {
        return '';
    }

    public String freteProcessor(String payload) {
        return '';
    }
}