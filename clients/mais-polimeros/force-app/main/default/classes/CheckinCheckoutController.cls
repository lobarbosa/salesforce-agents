public without sharing class CheckinCheckoutController {

    @AuraEnabled
    public static void checkIn(string idConta, decimal lat, decimal lon, String tipo, String comentario, String idContato){

        DateTime dataHora = System.now();

        Task newTask = new Task(
            WhatId = idConta,
            ActivityDate = date.newinstance(dataHora.year(), dataHora.month(), dataHora.day()),
            Status = 'Completo',
            Type = 'Check in - ' + tipo,
            Subject = 'Check in - ' + tipo,
            WhoId = idContato,
            Latitude__c = String.valueOf(truncaDecimal(lat, 7)),
            Longitude__c = String.valueOf(truncaDecimal(lon, 7)),
            Description = comentario
        );
        insert newTask;
    }

    public static decimal truncaDecimal(decimal numero, integer precisao){
        string strNumero = numero.toPlainString();
        
        if(precisao > strNumero.length()){
            precisao = strNumero.length();
        }

        strNumero = strNumero.subString(0, strNumero.indexOf('.') + precisao + 1);
        return Decimal.valueOf(strNumero);
    }

    @AuraEnabled  
    Public static List<Contact> getSearchRelated(String accId){
    
        List<Contact> lstResultado = new List<Contact>([    SELECT  Id
                                                                    , Name
                                                            FROM    Contact 
                                                            WHERE   Account.Id =:accId  ]);
        return lstResultado;

    }

    // @AuraEnabled  
    // Public static List<Object> getSearchRelated(String tipo, String accId, String searchName){
    
    //     List<Object> lstResultado = new List<Object>();
    //     if(searchName != null && searchName != ' '){

    //         String searchQuery = '';

    //         if (tipo == 'contato'){
    //             searchQuery = 'FIND \'' + searchName + '\' RETURNING Contact(Id,Name where Account.Id =:accId) LIMIT 20';
    //         } else {
    //             searchQuery = 'FIND \'' + searchName + '\' RETURNING Lead(Id,Name) LIMIT 20';
    //         }

    //         list<list<Sobject>> totalResults = search.query(searchQuery); 

    //         lstResultado = totalResults[0];
    //     }

    //     return lstResultado;   
    // }

    // @AuraEnabled  
    // Public static WraperForStorage getSearchRelated(String accId, String searchName){
 
    //     WraperForStorage wrperObj = new WraperForStorage();

    //     if(searchName != null && searchName != ' ') {       

    //         String searchQuery = 'FIND \'' + searchName + '\' RETURNING Contact(Id,Name where Account.Id =:accId), Lead(Id,Name)';  

    //         list<list<Sobject>> totalResults = search.query(searchQuery); 

    //         Contact[] lstContact = (Contact[])totalResults[0];
    //         Lead[] lstLead = (Lead[])totalResults[1];  

    //         wrperObj.lstContact = lstContact;  
    //         wrperObj.lstLead = lstLead;         
    //     }
    //     return wrperObj;   
    // }  

    // Public class WraperForStorage{  
    //     @AuraEnabled Public List<Contact> lstContact {get;set;}  
    //     @AuraEnabled Public List<Lead> lstLead {get;set;}  
    //     Public WraperForStorage(){}    
    // }
}