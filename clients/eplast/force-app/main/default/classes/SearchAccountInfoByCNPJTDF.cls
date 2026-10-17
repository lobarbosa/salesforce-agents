@isTest
public with sharing class SearchAccountInfoByCNPJTDF {
    public static Account createAccountWithNullCNPJ(){
        return new Account(
            Name = 'Test Account',
            Phone = '(11)12341234',
            MobilePhone__c = '(11)912341234',
            TaxContact__c = '(11)12341234',
            WhatsApp__c = '(11)912341234'
        );
    }

    public static Account createAccountWithEmptyCNPJ(){
        return new Account(
            Name = 'Test Account',
            CompanyDocument__c = '',
            Phone = '(11)12341234',
            MobilePhone__c = '(11)912341234',
            TaxContact__c = '(11)12341234',
            WhatsApp__c = '(11)912341234'
        );
    }

    public static Account createAccountWithIncompleteCNPJ(){
        Account acc = createAccountWithNullCNPJ();
        acc.CompanyDocument__c = '1234';

        return acc;
    }

    public static Account createAccountWithWrongFirstVerifyingDigitCNPJ(){
        Account acc = createAccountWithNullCNPJ();

        acc.CompanyDocument__c = '29190753000189';

        return acc;
    }

    public static Account createAccountWithWrongSecondVerifyingDigitCNPJ(){
        Account acc = createAccountWithNullCNPJ();

        acc.CompanyDocument__c = '29190753000198';

        return acc;
    }

    public static Account createAccountWithCorrectCNPJ(){
        Account acc = createAccountWithNullCNPJ();

        acc.CompanyDocument__c = '29.190.753/0001-99';

        return acc;
    }

    public static Account createAccountWithAnotherCorrectCNPJ(){
        Account acc = createAccountWithNullCNPJ();

        acc.CompanyDocument__c = '42.601.881/0001-46';

        return acc;
    }

    public static Account createAccountWithValidButInexistentCNPJ(){
        Account acc = createAccountWithNullCNPJ();

        acc.CompanyDocument__c = '81.520.758/0001-52';

        return acc;
    }

    public static String createBrasilAPISuccessBodyResponse(){
        return '{"uf":"SP","cep":"03323040","qsa":[{"pais":null,"nome_socio":"ANTONIO WAGNER MATHIAS JUNIOR","codigo_pais":null,"faixa_etaria":"Entre 21 a 30 anos","cnpj_cpf_do_socio":"***500498**","qualificacao_socio":"Sócio-Administrador","codigo_faixa_etaria":3,"data_entrada_sociedade":"2020-03-12","identificador_de_socio":2,"cpf_representante_legal":"***000000**","nome_representante_legal":"","codigo_qualificacao_socio":49,"qualificacao_representante_legal":"Não informada","codigo_qualificacao_representante_legal":0},{"pais":null,"nome_socio":"VICTOR BILOTTO DE LIMA","codigo_pais":null,"faixa_etaria":"Entre 21 a 30 anos","cnpj_cpf_do_socio":"***980538**","qualificacao_socio":"Sócio-Administrador","codigo_faixa_etaria":3,"data_entrada_sociedade":"2020-03-12","identificador_de_socio":2,"cpf_representante_legal":"***000000**","nome_representante_legal":"","codigo_qualificacao_socio":49,"qualificacao_representante_legal":"Não informada","codigo_qualificacao_representante_legal":0}],"cnpj":"29190753000199","pais":null,"email":"dummy@mail.com","porte":"MICRO EMPRESA","bairro":"CIDADE MAE DO CEU","numero":"442","ddd_fax":"","municipio":"SAO PAULO","logradouro":"COELHO LISBOA","cnae_fiscal":7319003,"codigo_pais":null,"complemento":"SALA 94","codigo_porte":1,"razao_social":"ELEVEADS MARKETING E VENDAS LTDA","nome_fantasia":"ELEVEADS","capital_social":10000,"ddd_telefone_1":"1120849636","ddd_telefone_2":"1123430000","opcao_pelo_mei":false,"descricao_porte":"","codigo_municipio":7107,"cnaes_secundarios":[{"codigo":7319004,"descricao":"Consultoria em publicidade"},{"codigo":7311400,"descricao":"Agências de publicidade"},{"codigo":7319002,"descricao":"Promoção de vendas"},{"codigo":8599604,"descricao":"Treinamento em desenvolvimento profissional e gerencial"},{"codigo":6201501,"descricao":"Desenvolvimento de programas de computador sob encomenda"},{"codigo":6202300,"descricao":"Desenvolvimento e licenciamento de programas de computador customizáveis"},{"codigo":6203100,"descricao":"Desenvolvimento e licenciamento de programas de computador não-customizáveis"},{"codigo":6201502,"descricao":"Web design"}],"natureza_juridica":"Sociedade Empresária Limitada","situacao_especial":"","opcao_pelo_simples":true,"situacao_cadastral":2,"data_opcao_pelo_mei":"2017-12-01","data_exclusao_do_mei":"2019-05-31","cnae_fiscal_descricao":"Marketing direto","codigo_municipio_ibge":3550308,"data_inicio_atividade":"2017-12-01","data_situacao_especial":null,"data_opcao_pelo_simples":"2017-12-01","data_situacao_cadastral":"2017-12-01","nome_cidade_no_exterior":"","codigo_natureza_juridica":2062,"data_exclusao_do_simples":null,"motivo_situacao_cadastral":0,"ente_federativo_responsavel":"","identificador_matriz_filial":1,"qualificacao_do_responsavel":49,"descricao_situacao_cadastral":"ATIVA","descricao_tipo_de_logradouro":"RUA","descricao_motivo_situacao_cadastral":"SEM MOTIVO","descricao_identificador_matriz_filial":"MATRIZ"}';
    }

    public static String createBrasilAPICompanyWithEmptyQSASuccessBodyResponse(){
        return '{"uf":"SP","cep":"03323040","qsa":[],"cnpj":"29190753000199","pais":null,"email":"dummy@mail.com","porte":"MICRO EMPRESA","bairro":"CIDADE MAE DO CEU","numero":"442","ddd_fax":"","municipio":"SAO PAULO","logradouro":"COELHO LISBOA","cnae_fiscal":7319003,"codigo_pais":null,"complemento":"SALA 94","codigo_porte":1,"razao_social":"ELEVEADS MARKETING E VENDAS LTDA","nome_fantasia":"ELEVEADS","capital_social":10000,"ddd_telefone_1":"1120849636","ddd_telefone_2":"1123430000","opcao_pelo_mei":false,"descricao_porte":"","codigo_municipio":7107,"cnaes_secundarios":[{"codigo":7319004,"descricao":"Consultoria em publicidade"},{"codigo":7311400,"descricao":"Agências de publicidade"},{"codigo":7319002,"descricao":"Promoção de vendas"},{"codigo":8599604,"descricao":"Treinamento em desenvolvimento profissional e gerencial"},{"codigo":6201501,"descricao":"Desenvolvimento de programas de computador sob encomenda"},{"codigo":6202300,"descricao":"Desenvolvimento e licenciamento de programas de computador customizáveis"},{"codigo":6203100,"descricao":"Desenvolvimento e licenciamento de programas de computador não-customizáveis"},{"codigo":6201502,"descricao":"Web design"}],"natureza_juridica":"Sociedade Empresária Limitada","situacao_especial":"","opcao_pelo_simples":true,"situacao_cadastral":2,"data_opcao_pelo_mei":"2017-12-01","data_exclusao_do_mei":"2019-05-31","cnae_fiscal_descricao":"Marketing direto","codigo_municipio_ibge":3550308,"data_inicio_atividade":"2017-12-01","data_situacao_especial":null,"data_opcao_pelo_simples":"2017-12-01","data_situacao_cadastral":"2017-12-01","nome_cidade_no_exterior":"","codigo_natureza_juridica":2062,"data_exclusao_do_simples":null,"motivo_situacao_cadastral":0,"ente_federativo_responsavel":"","identificador_matriz_filial":1,"qualificacao_do_responsavel":49,"descricao_situacao_cadastral":"ATIVA","descricao_tipo_de_logradouro":"RUA","descricao_motivo_situacao_cadastral":"SEM MOTIVO","descricao_identificador_matriz_filial":"MATRIZ"}';
    }

    public static String createBrasilAPIErrorBodyResponse(){
        return '{"message":"CNPJ 00.000.000/0000-00 não encontrado.","type":"not_found","name":"NotFoundError"}';
    }
}