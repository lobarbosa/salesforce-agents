@isTest
public with sharing class SearchAccountInfoByCNPJTDF {
    // Bases 00.000.000 e 10.000.000 não são CNPJ de cliente. Dígitos calculados.
    public static final String CNPJ_VALIDO = '00.000.000/0001-91';
    public static final String CNPJ_OUTRO = '00.000.000/0002-72';
    public static final String CNPJ_TERCEIRO = '00.000.000/0003-53';
    public static final String CNPJ_QUARTO = '00.000.000/0004-34';
    public static final String CNPJ_INCOMPLETO = '00.000.000/0001';
    public static final String CNPJ_DIGITO_1_ERRADO = '00.000.000/0001-81';
    public static final String CNPJ_DIGITO_2_ERRADO = '00.000.000/0001-90';

    public static Account aplicarEnderecoUnico(Account acc, String token){
        Integer n = Math.mod(Math.abs(token.hashCode()), 7000) + 1000;
        acc.Name = token + ' TESTE';
        acc.CompanyName__c = token + ' LTDA TESTE';
        acc.BillingCity = 'Cid' + token;
        acc.BillingStreet = 'Rua ' + token;
        acc.BillingState = 'SP';
        acc.BillingCountry = 'BR';
        acc.BillingNeighborhood__c = 'Bairro ' + token;
        acc.BillingPostalCode = String.valueOf(21000000 + n);
        acc.Phone = '(11)' + String.valueOf(31000000 + n);
        acc.Email__c = token.toLowerCase() + '@example.com';
        return acc;
    }

    public static Account createAccountWithNullCNPJ(){
        return new Account(
            Name = 'TESTE EPLAST Apex Conta',
            Phone = '(11)33334444',
            MobilePhone__c = '(11)933334444',
            TaxContact__c = '(11)33334444',
            WhatsApp__c = '(11)933334444'
        );
    }

    public static Account createAccountWithEmptyCNPJ(){
        Account acc = createAccountWithNullCNPJ();
        acc.CompanyDocument__c = '';
        return acc;
    }

    public static Account createAccountWithIncompleteCNPJ(){
        Account acc = createAccountWithNullCNPJ();
        acc.CompanyDocument__c = CNPJ_INCOMPLETO;
        return acc;
    }

    public static Account createAccountWithWrongFirstVerifyingDigitCNPJ(){
        Account acc = createAccountWithNullCNPJ();
        acc.CompanyDocument__c = CNPJ_DIGITO_1_ERRADO;
        return acc;
    }

    public static Account createAccountWithWrongSecondVerifyingDigitCNPJ(){
        Account acc = createAccountWithNullCNPJ();
        acc.CompanyDocument__c = CNPJ_DIGITO_2_ERRADO;
        return acc;
    }

    public static Account createAccountWithCorrectCNPJ(){
        Account acc = createAccountWithNullCNPJ();
        acc.CompanyDocument__c = CNPJ_VALIDO;
        return acc;
    }

    public static Account createAccountWithAnotherCorrectCNPJ(){
        Account acc = createAccountWithNullCNPJ();
        acc.Name = 'TESTE EPLAST Apex Conta Dois';
        acc.CompanyDocument__c = CNPJ_OUTRO;
        return acc;
    }

    public static Account createAccountWithValidButInexistentCNPJ(){
        Account acc = createAccountWithNullCNPJ();
        acc.Name = 'TESTE EPLAST Apex Conta Inexistente';
        acc.CompanyDocument__c = CNPJ_TERCEIRO;
        return acc;
    }

    public static String createBrasilAPISuccessBodyResponse(){
        return syntheticCompanyBody(false);
    }

    public static String createBrasilAPICompanyWithEmptyQSASuccessBodyResponse(){
        return syntheticCompanyBody(true);
    }

    public static String createBrasilAPIErrorBodyResponse(){
        return '{"message":"CNPJ não encontrado.","type":"not_found","name":"NotFoundError"}';
    }

    private static String syntheticCompanyBody(Boolean emptyQsa){
        String qsa = emptyQsa
            ? '[]'
            : '[{"nome_socio":"SOCIO TESTE UM","qualificacao_socio":"Socio-Administrador"},{"nome_socio":"SOCIO TESTE DOIS","qualificacao_socio":"Socio"}]';
        return '{"uf":"SP","cep":"01310100","qsa":' + qsa + ',"cnpj":"00000000000191","pais":null,"email":"teste.eplast.apex@example.com","bairro":"BAIRRO TESTE","numero":"100","municipio":"CIDADE TESTE","logradouro":"RUA TESTE","cnae_fiscal":"6201501","complemento":"SALA TESTE","razao_social":"TESTE EPLAST COMERCIO LTDA","ddd_telefone_1":"1133334444","data_inicio_atividade":"2020-01-15","descricao_tipo_de_logradouro":"RUA"}';
    }

    @isTest
    static void fabricaEntregaCnpjSinteticoComDigito(){
        Assert.isTrue(AccountUtility.validateCNPJ(createAccountWithCorrectCNPJ().CompanyDocument__c));
        Assert.isTrue(AccountUtility.validateCNPJ(createAccountWithAnotherCorrectCNPJ().CompanyDocument__c));
        Assert.isTrue(AccountUtility.validateCNPJ(CNPJ_TERCEIRO));
        Assert.isTrue(AccountUtility.validateCNPJ(CNPJ_QUARTO));
        Assert.isFalse(AccountUtility.validateCNPJ(createAccountWithIncompleteCNPJ().CompanyDocument__c));
        Assert.isFalse(AccountUtility.validateCNPJ(createAccountWithWrongFirstVerifyingDigitCNPJ().CompanyDocument__c));
        Assert.isFalse(AccountUtility.validateCNPJ(createAccountWithWrongSecondVerifyingDigitCNPJ().CompanyDocument__c));
        Assert.isTrue(createAccountWithCorrectCNPJ().Name.startsWith('TESTE'));
    }
}
