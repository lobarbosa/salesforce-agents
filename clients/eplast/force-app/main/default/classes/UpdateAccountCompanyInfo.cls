public with sharing class UpdateAccountCompanyInfo implements Queueable, Database.AllowsCallouts {
    private Account triggerAccount;

    public UpdateAccountCompanyInfo(Account triggerAccount) {
        this.triggerAccount = triggerAccount;
    }

    public void execute(QueueableContext qContext){
        System.debug('CNPJ ' + this.triggerAccount.CompanyDocument__c);
        CNPJBrasilAPISearchResponse company = BrasilAPI.searchCNPJ(this.triggerAccount.CompanyDocument__c);

        this.triggerAccount.CompanyDocument__c = AccountUtility.formatCNPJ(this.triggerAccount.CompanyDocument__c);
        
        if(company != null){ 
            this.triggerAccount.CompanyName__c = company.razao_social;
            this.triggerAccount.CNAE__c = company.cnae_fiscal;
            this.triggerAccount.OpeningDate__c = this.createDate(company.data_inicio_atividade);
            this.triggerAccount.Email__c = company.email;
            this.triggerAccount.Phone = PhoneUtility.formatPhone(company.ddd_telefone_1);
            this.triggerAccount.BillingPostalCode = company.cep;
            this.triggerAccount.BillingStreet = this.buildAccountBillingStreet(company.descricao_tipo_de_logradouro, company.logradouro, company.numero, company.complemento);
            this.triggerAccount.BillingCity = company.municipio;
            this.triggerAccount.BillingState = company.uf;
            this.triggerAccount.BillingCountry = company.pais;
            this.triggerAccount.BillingNeighborhood__c = company.bairro;
            this.triggerAccount.Description = fillCompanyQSA(company.qsa);
        }
        else
            this.triggerAccount.CompanyName__c = 'CNPJ não encontrado';

        upsert this.triggerAccount;

        // System.enqueueJob(new SendAccountToProtheus(this.triggerAccount));
        (new SendAccountToProtheus(this.triggerAccount)).execute(null); // Executes synchronously
    }

    private Date createDate(String openingDate){
        String[] openingDateParts = openingDate.split('-');

        return Date.newInstance(Integer.valueOf(openingDateParts[0]), Integer.valueOf(openingDateParts[1]), Integer.valueOf(openingDateParts[2]));
    }

    private String buildAccountBillingStreet(String placeType, String placeName, String placeNumber, String placeComplement){
        String[] addressComponents = new String[]{ placeType, placeName, placeNumber, placeComplement };

        return String.format('{0} {1}, {2} - {3}', addressComponents);
    }

    private String fillCompanyQSA(CNPJBrasilAPISearchResponse.QSA[] qsaList){
        String returnValue = 'Quadro Societário: \n\n';

        if(qsaList.isEmpty())
            returnValue = 'Não há quadro societário';

        for(CNPJBrasilAPISearchResponse.QSA qsa : qsaList)
            returnValue += qsa.nome_socio + ' - ' + qsa.qualificacao_socio + '\n';

        return returnValue;
    }
}