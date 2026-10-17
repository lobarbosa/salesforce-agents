public class MSProjectIntegrations {
    public static MSProjectIntegration__c sett = MSProjectIntegration__c.getOrgDefaults();
    /*
    public static void getProject(PPM_Project__c ppmProject) {
        if(ppmProject.IdMSProject__c == null)
            throw new CustomException('Id MS Project inválido.');

        HttpRequest req = setDefaultRequest();
        req.setEndpoint(sett.SharepointURL__c + '/sites/ppm/_api/ProjectServer/Projects(\'' + ppmProject.IdMSProject__c + '\')/CustomFields');
        req.setMethod('GET');

        Http http = new Http();
        HTTPResponse res = http.send(req);
        
        MSProjectObjectResponse r = (MSProjectObjectResponse)JSON.deserialize(res.getBody(), MSProjectObjectResponse.class);

        if(r.Error != null)
            throw new CustomException('Erro no retorno do MS Project: ' + r.error.message.value);
    }

    public static void deleteProject(PPM_Project__c ppmProject) {
        if(ppmProject.IdMSProject__c == null)
            throw new CustomException('Id MS Project inválido.');

        MSProjectObjectToSend project = convertProjectToClass(ppmProject);

        HttpRequest req = setDefaultRequest();
        req.setEndpoint(sett.SharepointURL__c + '/sites/ppm/_api/ProjectServer/Projects(\'' + ppmProject.IdMSProject__c + '\')/deleteObject()');
        req.setMethod('POST');
        req.setBody('{ \"__metadata\": { \"type\": \"PS.PublishedProject\" }, ' + JSON.serialize(project).replaceFirst('\\{', ''));
        //req.setBody('{ \"__metadata\": { \"type\": \"PS.PublishedProject\" }, \"Description\": \"Teste\", \"Name\": \"Teste Konecta Salesforce\" }');

        Http http = new Http();
        HTTPResponse res = http.send(req);

        MSProjectObjectResponse r = (MSProjectObjectResponse)JSON.deserialize(res.getBody(), MSProjectObjectResponse.class);
        
        if(r.d != null) {
            ppmProject.IdMSProject__c = r.d.Id;
            update ppmProject;
        }else if(r.Error != null) {
            throw new CustomException('Erro no retorno do MS Project: ' + r.error.message.value);
        }
    }
*/
    public static void insertProject(PPM_Project__c ppmProject) {
        if(ppmProject.IdMSProject__c != null)
            throw new CustomException('Projeto já criado no MS Project.');

        MSProjectObjectToSend project = convertProjectToClass(ppmProject);

        HttpRequest req = setDefaultRequest();
        req.setEndpoint(sett.SharepointURL__c + '/sites/ppm/_api/ProjectServer/Projects');
        req.setMethod('POST');
        req.setBody('{ \"__metadata\": { \"type\": \"PS.DraftProject\" }, ' + JSON.serialize(project).replaceFirst('\\{', ''));

        Http http = new Http();
        HTTPResponse res = http.send(req);

        MSProjectObjectResponse r = (MSProjectObjectResponse)JSON.deserialize(res.getBody(), MSProjectObjectResponse.class);
        
        if(r.d != null) {
            ppmProject.IdMSProject__c = r.d.Id;

            checkOutProject(ppmProject);    
            updateProjectCustomFields(ppmProject);
            publishProject(ppmProject);

            update ppmProject;   
        }else if(r.Error != null) {
            throw new CustomException('Erro no retorno do MS Project: ' + r.error.message.value);
        }
    }

    public static void updateProjectCustomFields(PPM_Project__c ppmProject) {
        if(ppmProject.IdMSProject__c == null)
            throw new CustomException('Id MS Project inválido.');

        List<MSProjectObjectStatusResponse.response> listStatus = getStatus();

        MSProjectObjectStatusResponse.response choosedStatus;

        for(MSProjectObjectStatusResponse.response status : listStatus) {
            if(status.Value == ppmProject.Project_Status__c) {
                choosedStatus = status;
            }
        }
        
        if(choosedStatus == null)
            throw new CustomException('Status não existe no MS Project.');

        HttpRequest req = setDefaultRequest();
        req.setEndpoint(sett.SharepointURL__c + '/sites/ppm/_api/ProjectServer/Projects(\'' + ppmProject.IdMSProject__c + '\')/Draft/UpdateCustomFields');
        req.setMethod('POST');
        req.setBody('{ \"customFieldDictionary\": [' + 
        + '{ \"Key\": \"Custom_985e566c984bea11bf8200155db0b607\", \"Value\": \"'+ choosedStatus.InternalName + '\", \"ValueType\": \"Edm.String\" },'
        + '{ \"Key\": \"Custom_36be289e6a40ea11bf7400155da89706\", \"Value\": \"' + ppmProject.Despesas_Realizadas__c + '\", \"ValueType\": \"Edm.Double\" },'
        + '{ \"Key\": \"Custom_3431723dac75ea11bf9700155dbccf18\", \"Value\": \"' + ppmProject.Total_de_creditos_de_despesas__c + '\", \"ValueType\": \"Edm.Double\" }'
        + ']}');

        Http http = new Http();
        HTTPResponse res = http.send(req);

        MSProjectObjectResponse r = (MSProjectObjectResponse)JSON.deserialize(res.getBody(), MSProjectObjectResponse.class);

        if(r.Error != null)
            throw new CustomException('Erro no retorno do MS Project: ' + r.error.message.value);
    }

    public static void updateProject(PPM_Project__c ppmProject) {
        if(ppmProject.IdMSProject__c == null)
            throw new CustomException('Id MS Project inválido.');

        MSProjectObjectToSend project = convertProjectToClass(ppmProject);

        checkOutProject(ppmProject);

        HttpRequest req = setDefaultRequest();
        req.setEndpoint(sett.SharepointURL__c + '/sites/ppm/_api/ProjectServer/Projects(\'' + ppmProject.IdMSProject__c + '\')/Draft/update()');
        req.setMethod('POST');
        req.setBody('{ \"__metadata\": { \"type\": \"PS.PublishedProject\" }, ' + JSON.serialize(project).replaceFirst('\\{', ''));

        Http http = new Http();
        HTTPResponse res = http.send(req);

        MSProjectObjectResponse r = (MSProjectObjectResponse)JSON.deserialize(res.getBody(), MSProjectObjectResponse.class);
    
        updateProjectCustomFields(ppmProject);

        publishProject(ppmProject);

        if(r.Error != null)
            throw new CustomException('Erro no retorno do MS Project: ' + r.error.message.value);
    }
    /*
    public static void createTask(PPM_Project__c ppmProject) {
        if(ppmProject.In_cio_Planejado__c == null || ppmProject.Termino_planejado__c == null)
            throw new CustomException('Preencha a data de início e de término planejada.');

        if(ppmProject.IdMSProject__c == null)
            throw new CustomException('Id MS Project inválido.');
        checkOutProject(ppmProject);

        String inicio = DateTime.newInstance(ppmProject.In_cio_Planejado__c.year(), ppmProject.In_cio_Planejado__c.month(), ppmProject.In_cio_Planejado__c.day()).format('yyyy-MM-dd');
        String fim = DateTime.newInstance(ppmProject.Termino_planejado__c.year(), ppmProject.Termino_planejado__c.month(), ppmProject.Termino_planejado__c.day()).format('yyyy-MM-dd');

        HttpRequest req = setDefaultRequest();
        req.setEndpoint(sett.SharepointURL__c + '/sites/ppm/_api/ProjectServer/Projects(\'' + ppmProject.IdMSProject__c + '\')/Draft/Tasks/add()');
        req.setMethod('POST');
        req.setBody('{ \"parameters\": {\"ActualCost\": \"00.00\", \"Start\": \"' + inicio + '\", \"Finish\": \"' + fim + '\", \"Name\": \"' + ppmProject.Nome_do_Projeto__c + '\" }}');

        Http http = new Http();
        HTTPResponse res = http.send(req);

        MSProjectObjectResponse r = (MSProjectObjectResponse)JSON.deserialize(res.getBody(), MSProjectObjectResponse.class); 

        publishProject(ppmProject); 

        if(r.d != null) {
            ppmProject.IdTaskMSProject__c = r.d.Id;

            update ppmProject;
        }else if(r.Error != null)
            throw new CustomException('Erro no retorno do MS Project: ' + r.error.message.value);
    }

    public static void updateTask(PPM_Project__c ppmProject) {
        if(ppmProject.In_cio_Planejado__c == null || ppmProject.Termino_planejado__c == null)
            throw new CustomException('Preencha a data de início e de término planejada.');

        if(ppmProject.IdMSProject__c == null)
            throw new CustomException('Id MS Project inválido.');

        if(ppmProject.IdTaskMSProject__c == null)
            throw new CustomException('Id da Task MS Project inválido.');

        checkOutProject(ppmProject);

        String inicio = DateTime.newInstance(ppmProject.In_cio_Planejado__c.year(), ppmProject.In_cio_Planejado__c.month(), ppmProject.In_cio_Planejado__c.day()).formatGMT('yyyy-MM-dd');
        String fim = DateTime.newInstance(ppmProject.Termino_planejado__c.year(), ppmProject.Termino_planejado__c.month(), ppmProject.Termino_planejado__c.day()).formatGMT('yyyy-MM-dd');
        
        HttpRequest req = setDefaultRequest();
        req.setEndpoint(sett.SharepointURL__c + '/sites/ppm/_api/ProjectServer/Projects(\'' + ppmProject.IdMSProject__c + '\')/Draft/Tasks(\'' + ppmProject.IdTaskMSProject__c + '\')');
        req.setMethod('PUT');
        req.setHeader('X-HTTP-Method-Override','MERGE');
        req.setBody('{ \"__metadata\": { \"type\": \"PS.DraftTask\" }, \"Start\": \"' + inicio + '\", \"Finish\": \"' + fim + '\", \"Name\": \"' + ppmProject.Nome_do_Projeto__c + '\" }');

        Http http = new Http();
        HTTPResponse res = http.send(req);
        
        MSProjectObjectResponse r = (MSProjectObjectResponse)JSON.deserialize(res.getBody(), MSProjectObjectResponse.class);

        publishProject(ppmProject); 
        
        if(r.Error != null)
            throw new CustomException('Erro no retorno do MS Project: ' + r.error.message.value);
    }*/

    public static void checkOutProject(PPM_Project__c ppmProject) {
        HttpRequest req = setDefaultRequest();
        req.setEndpoint(sett.SharepointURL__c + '/sites/ppm/_api/ProjectServer/Projects(\'' + ppmProject.IdMSProject__c + '\')/checkout()');
        req.setMethod('POST');
        req.setBody('');

        Http http = new Http();
        HTTPResponse res = http.send(req);

        MSProjectObjectResponse r = (MSProjectObjectResponse)JSON.deserialize(res.getBody(), MSProjectObjectResponse.class);
        
        if(r.Error != null)
            throw new CustomException('Erro no retorno do MS Project: ' + r.error.message.value);
    }

    public static void publishProject(PPM_Project__c ppmProject) {
        HttpRequest req = setDefaultRequest();
        req.setEndpoint(sett.SharepointURL__c + '/sites/ppm/_api/ProjectServer/Projects(\'' + ppmProject.IdMSProject__c + '\')/Draft/publish(true)');
        req.setMethod('POST');
        req.setBody('');

        Http http = new Http();
        HTTPResponse res = http.send(req);

        MSProjectObjectResponse r = (MSProjectObjectResponse)JSON.deserialize(res.getBody(), MSProjectObjectResponse.class);
        System.debug(res.getBody());
        if(r.Error != null)
            throw new CustomException('Erro no retorno do MS Project: ' + r.error.message.value);
    }
/*
    public static void getQueuesForProject(PPM_Project__c ppmProject) {
        HttpRequest req = setDefaultRequest();
        req.setEndpoint(sett.SharepointURL__c + '/sites/ppm/_api/ProjectServer/Projects(\'' + ppmProject.IdMSProject__c + '\')/QueueJobs(\'f80ff33f-0585-ea11-bfa8-00155dbc841a\')');
        req.setMethod('GET');
        req.setBody('');

        Http http = new Http();
        HTTPResponse res = http.send(req);

        MSProjectObjectResponse r = (MSProjectObjectResponse)JSON.deserialize(res.getBody(), MSProjectObjectResponse.class);
        System.debug(res.getBody());
        if(r.Error != null)
            throw new CustomException('Erro no retorno do MS Project: ' + r.error.message.value);
    }
*/
    private static MSProjectObjectToSend convertProjectToClass(PPM_Project__c ppmProject) {
        MSProjectObjectToSend project = new MSProjectObjectToSend();

        project.Name = ppmProject.Nome_do_Projeto__c;
        project.Description = 'Projeto Agility';

        return project;
    }

    private static HttpRequest setDefaultRequest() {
        HttpRequest req = new HttpRequest();

        String cookies = setCookiesString();
        String formDigestValue = sett.FormDigestValue__c;

        req.setHeader('Cookie', cookies);
        req.setHeader('X-RequestDigest', formDigestValue);
        req.setHeader('Authorization', 'Bearer ' + formDigestValue);
        req.setHeader('Content-Type', 'application/json; odata=verbose');  
        req.setHeader('Accept', 'application/json; odata=verbose'); 

        return req;
    }

    private static String setCookiesString() {
        return  (sett.rtFaPart1__c == null ? '' : sett.rtFaPart1__c) +
                (sett.rtFaPart2__c == null ? '' : sett.rtFaPart2__c) +
                (sett.rtFaPart3__c == null ? '' : sett.rtFaPart3__c) +
                (sett.rtFaPart4__c == null ? '' : sett.rtFaPart4__c) +
                (sett.FedAuthPart1__c == null ? '' : sett.FedAuthPart1__c) +
                (sett.FedAuthPart2__c == null ? '' : sett.FedAuthPart2__c) +
                (sett.FedAuthPart3__c == null ? '' : sett.FedAuthPart3__c) +
                (sett.FedAuthPart4__c == null ? '' : sett.FedAuthPart4__c) +
                (sett.FedAuthPart5__c == null ? '' : sett.FedAuthPart5__c) ;
    }

    public static List<MSProjectObjectStatusResponse.response> getStatus() {
        HttpRequest req = setDefaultRequest();
        req.setEndpoint(sett.SharepointURL__c + '/sites/ppm/_api/ProjectServer/CustomFields(\'985e566c-984b-ea11-bf82-00155db0b607\')/LookupEntries');
        req.setMethod('GET');

        Http http = new Http();
        HTTPResponse res = http.send(req);
        
        MSProjectObjectStatusResponse r = (MSProjectObjectStatusResponse)JSON.deserialize(res.getBody(), MSProjectObjectStatusResponse.class);

        if(r.Error != null)
            throw new CustomException('Erro no retorno do MS Project: ' + r.error.message.value);

        return r.d.results; 
    }
    
    public class CustomException extends Exception {}
}