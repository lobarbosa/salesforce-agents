@isTest public class EmailSendNotificationTest {
    
    @TestSetup 
    public static void setupData (){
        EmailTemplate validEmailTemplate = new EmailTemplate();
        validEmailTemplate.isActive = true;
        validEmailTemplate.Name = 'Test Account Alert Email';
        validEmailTemplate.DeveloperName = 'unique_name_addSomethingSpecialHere';
        validEmailTemplate.TemplateType = 'text';
        validEmailTemplate.FolderId = UserInfo.getUserId();
        validEmailTemplate.Subject = 'Your Subject Here';


		insert validEmailTemplate;
    }
    
    @isTest
    Public static void test()
    {
         Municipio__c municipio = new Municipio__c(
            Name = 'MUNICIPIO'
            
        );
        insert municipio;
        
        Account acc = new Account(
            Name                = 'ACC TESTE',
            NomeFantasia__c = 'nome fantasia',
            Municipio__c        = municipio.Id, 
            MunicipioEntrega__c = municipio.Id,
            Classificacao__c    = 'Tipo A'
        );
        insert acc;
        
        Contact ctt = new Contact(
            LastName = 'Testado',
            AccountId = acc.id,
            Email = 'teste.costa@teste.com.br'
        );
       
       	insert ctt;
        try{
            EmailSendNotification.sendNotification(ctt.Id);
        }catch(Exception ex){
            system.debug(ex.getMessage());
        }
    }

}