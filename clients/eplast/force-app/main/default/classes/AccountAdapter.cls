public with sharing class AccountAdapter {
    public static ProtheusInsertClientModel toProtheus(Account acc){
        ProtheusInsertClientModel client = new ProtheusInsertClientModel();
        Map<String, String> phoneParts = PhoneUtility.getPhoneInParts(acc.Phone);
        Map<String, Object> limitInfo = getLimitInfo(acc);

        //Fazer a query de relacionamento entre conta e cond pagamento, utilizando acc como parâmetro.
        List<RelationshipAccountsPaymentTerm__c> lstAccPayment = [SELECT Id, Account__c, PaymentTerms__c, PaymentTerms__r.Codigo__c  FROM RelationshipAccountsPaymentTerm__c WHERE Account__c =: acc.Id];
        //Adicionar um loop para adicionar o código da condição de pagamento na lista de String
        List<String> CodPagto = new List<String>();
        for(RelationshipAccountsPaymentTerm__c rAccPay : lstAccPayment){
            CodPagto.add(rAccPay.PaymentTerms__r.Codigo__c);
        }
        System.debug('Códigos das Condições de Pagamento ' + CodPagto);
        

        client.CodCRM = acc.Id;
        client.Loja = (acc.Store__c.length() == 1 ? '0' + acc.Store__c : acc.Store__c);
        client.Nome = acc.CompanyName__c;
        client.Cidade = acc.BillingCity;
        client.UF = acc.BillingState;
        client.Bairro = acc.BillingNeighborhood__c;
        client.Endereco = acc.BillingStreet;
        client.CEP = AddressUtility.getFormattedPostalCode(acc.BillingPostalCode);
        client.DDD = phoneParts.get('ddd');
        client.Telefone = phoneParts.get('phone');
        client.CGC = acc.CompanyDocument__c;
        client.Email = acc.Email__c;
        client.Vend1 = acc.Owner.ProtheusSellerId__c;
        client.Vend2 = (AccountUtility.checkAccountTeamMembers(acc.AccountTeamMembers) ? acc.AccountTeamMembers.get(0).User.ProtheusSellerId__c : '');
        client.Risco = acc.Risk__c;
        client.LimCred = (Decimal) limitInfo.get('limCred');
        client.VencLimCred = (String) limitInfo.get('vencLimCred');
        client.Cnae = acc.CNAE__c.replaceAll('[-/.]', '');
        client.CONDPAGTO = CodPagto.toString();

        return client;
    }

    private static Map<String, Object> getLimitInfo(Account acc){
        Map<String, Object> limitInfo = new Map<String, Object>();

        if(acc.Parent != null){
            limitInfo.put('limCred', (acc.Parent.LimitAmount__c == null ? 0.00 : acc.Parent.LimitAmount__c));
            limitInfo.put('vencLimCred', DateTimeUtility.formatDate(acc.Parent.LimitAmountDueDate__c));
        }
        else{
            limitInfo.put('limCred', (acc.LimitAmount__c == null ? 0.00 : acc.LimitAmount__c));
            limitInfo.put('vencLimCred', DateTimeUtility.formatDate(acc.LimitAmountDueDate__c));
        }

        return limitInfo;
    }
}