/**
 * Testes do OmieServicoVinculoQueueable: casar uma fatia do cadastro do Omie
 * com os Product2 de serviço e gravar o código.
 *
 * Só uma execução por teste: a produção não se reenfileira sob Test.isRunningTest,
 * o que mantém o teste determinístico.
 */
@IsTest
private class OmieServicoVinculoQueueableTest {

    @IsTest
    static void casaPelaChaveDeIntegracao() {
        Product2 p = OmieTestData.servico('SRV1');
        insert p;
        OmieTestData.instalar(
            OmieTestData.listaServicos(1, 4811189079L, String.valueOf(p.Id), 'OUTRO-CODIGO'));

        Test.startTest();
        System.enqueueJob(new OmieServicoVinculoQueueable());
        Test.stopTest();

        Assert.areEqual('4811189079',
            [SELECT Id_Codigo_de_Servico__c FROM Product2 WHERE Id = :p.Id].Id_Codigo_de_Servico__c,
            'A chave de integração é inequívoca, então casa mesmo com código diferente.');
    }

    @IsTest
    static void casaPeloCodigoQuandoNaoHaChaveDeIntegracao() {
        Product2 p = OmieTestData.servico('SRV1');
        insert p;
        OmieTestData.instalar(OmieTestData.listaServicos(1, 999L, 'NAO-E-UM-ID', 'SRV1'));

        Test.startTest();
        System.enqueueJob(new OmieServicoVinculoQueueable());
        Test.stopTest();

        Assert.areEqual('999',
            [SELECT Id_Codigo_de_Servico__c FROM Product2 WHERE Id = :p.Id].Id_Codigo_de_Servico__c,
            'Sem chave utilizável, o ProductCode é o desempate.');
    }

    @IsTest
    static void naoRegravaQuandoOCodigoJaEOMesmo() {
        Product2 p = OmieTestData.servico('SRV1');
        p.Id_Codigo_de_Servico__c = '999';
        insert p;
        OmieTestData.instalar(OmieTestData.listaServicos(1, 999L, 'NAO-E-UM-ID', 'SRV1'));

        Test.startTest();
        System.enqueueJob(new OmieServicoVinculoQueueable());
        Test.stopTest();

        Assert.areEqual('999',
            [SELECT Id_Codigo_de_Servico__c FROM Product2 WHERE Id = :p.Id].Id_Codigo_de_Servico__c,
            'O valor deve continuar o mesmo, sem gastar DML.');
    }

    /**
     * O vínculo NÃO filtra por Family, e isso é intencional: a maior parte do
     * Product2 desta org está com Family em branco, e filtrar por 'Serviço'
     * deixaria de fora quase todo serviço real. Quem manda é o cadastro do Omie —
     * se o código bate com um serviço de lá, o vínculo vale.
     */
    @IsTest
    static void vinculaIndependenteDoFamily() {
        Product2 semFamily = OmieTestData.servico('SRV-SEM-FAMILY');
        semFamily.Family = null;
        Product2 comOutroFamily = OmieTestData.produto('SRV-OUTRO-FAMILY');
        insert new List<Product2>{ semFamily, comOutroFamily };

        OmieTestData.instalar(
            '{"nPagina":1,"nTotPaginas":1,"nRegistros":2,"nTotRegistros":2,"cadastros":['
          + '{"intListar":{"nCodServ":111},"cabecalho":{"cCodigo":"SRV-SEM-FAMILY"},"info":{"inativo":"N"}},'
          + '{"intListar":{"nCodServ":222},"cabecalho":{"cCodigo":"SRV-OUTRO-FAMILY"},"info":{"inativo":"N"}}]}');

        Test.startTest();
        System.enqueueJob(new OmieServicoVinculoQueueable());
        Test.stopTest();

        Assert.areEqual('111',
            [SELECT Id_Codigo_de_Servico__c FROM Product2 WHERE Id = :semFamily.Id]
                .Id_Codigo_de_Servico__c,
            'Family em branco é o caso mais comum na org e precisa ser vinculado.');
        Assert.areEqual('222',
            [SELECT Id_Codigo_de_Servico__c FROM Product2 WHERE Id = :comOutroFamily.Id]
                .Id_Codigo_de_Servico__c,
            'Quem decide é o cadastro do Omie, não o Family do Salesforce.');
    }

    /**
     * Código repetido no Salesforce não serve para casar: dois serviços daqui
     * apontando para o mesmo cadastro do Omie brigariam na sincronização.
     */
    @IsTest
    static void codigoRepetidoNaoEVinculado() {
        List<Product2> servicos = new List<Product2>{
            OmieTestData.servico('DUPLICADO'), OmieTestData.servico('DUPLICADO')
        };
        insert servicos;
        OmieTestData.instalar(OmieTestData.listaServicos(1, 999L, 'NAO-E-UM-ID', 'DUPLICADO'));

        Test.startTest();
        System.enqueueJob(new OmieServicoVinculoQueueable());
        Test.stopTest();

        Assert.areEqual(0, [SELECT COUNT() FROM Product2 WHERE Id_Codigo_de_Servico__c = '999'],
            'Com código ambíguo é melhor não gravar nada.');
    }

    /**
     * Código ambíguo não impede o match quando a chave de integração resolve:
     * ela é específica de um registro só.
     */
    @IsTest
    static void chaveDeIntegracaoSalvaOMatchMesmoComCodigoRepetido() {
        List<Product2> servicos = new List<Product2>{
            OmieTestData.servico('DUPLICADO'), OmieTestData.servico('DUPLICADO')
        };
        insert servicos;
        OmieTestData.instalar(
            OmieTestData.listaServicos(1, 999L, String.valueOf(servicos[0].Id), 'DUPLICADO'));

        Test.startTest();
        System.enqueueJob(new OmieServicoVinculoQueueable());
        Test.stopTest();

        Assert.areEqual('999',
            [SELECT Id_Codigo_de_Servico__c FROM Product2 WHERE Id = :servicos[0].Id]
                .Id_Codigo_de_Servico__c,
            'O que tem chave de integração deve ser vinculado.');
        Assert.isNull([SELECT Id_Codigo_de_Servico__c FROM Product2 WHERE Id = :servicos[1].Id]
                        .Id_Codigo_de_Servico__c,
            'O outro não: só o código, que é ambíguo, apontaria para ele.');
    }

    @IsTest
    static void cadastroVazioNaoGravaNada() {
        Product2 p = OmieTestData.servico('SRV1');
        insert p;
        OmieTestData.instalar('{"nPagina":1,"nTotPaginas":0,"nRegistros":0,"nTotRegistros":0}');

        Test.startTest();
        System.enqueueJob(new OmieServicoVinculoQueueable());
        Test.stopTest();

        Assert.isNull([SELECT Id_Codigo_de_Servico__c FROM Product2 WHERE Id = :p.Id]
                        .Id_Codigo_de_Servico__c,
            'Sem serviço no Omie não há o que vincular.');
    }

    // =================================================================
    // Filtro dinâmico no modo completo
    // =================================================================

    @IsTest
    static void filtroRestringeQuemEVinculado() {
        Product2 servico = OmieTestData.servico('SRV1');
        Product2 produto = OmieTestData.produto('SRV2');
        insert new List<Product2>{ servico, produto };
        OmieTestData.instalar(
            '{"nPagina":1,"nTotPaginas":1,"nRegistros":2,"nTotRegistros":2,"cadastros":['
          + '{"intListar":{"nCodServ":111},"cabecalho":{"cCodigo":"SRV1"},"info":{"inativo":"N"}},'
          + '{"intListar":{"nCodServ":222},"cabecalho":{"cCodigo":"SRV2"},"info":{"inativo":"N"}}]}');

        Test.startTest();
        OmieServicoVinculoQueueable.vincularComFiltro(
            'Family = \'' + OmieServicoMapper.FAMILY_SERVICO + '\'');
        Test.stopTest();

        Assert.areEqual('111',
            [SELECT Id_Codigo_de_Servico__c FROM Product2 WHERE Id = :servico.Id]
                .Id_Codigo_de_Servico__c,
            'Quem passa pelo filtro deve ser vinculado.');
        Assert.isNull([SELECT Id_Codigo_de_Servico__c FROM Product2 WHERE Id = :produto.Id]
                        .Id_Codigo_de_Servico__c,
            'Quem o filtro exclui não deve ser tocado, mesmo estando na mesma página do Omie.');
    }

    /**
     * O filtro ENTRA ALÉM da condição de sempre, não no lugar dela: um produto que
     * o Omie não mencionou continua de fora, por mais largo que seja o filtro.
     */
    @IsTest
    static void filtroNaoAfrouxaACondicaoDeBase() {
        Product2 naoMencionado = OmieTestData.servico('SRV-FORA-DO-OMIE');
        insert naoMencionado;
        OmieTestData.instalar(OmieTestData.listaServicos(1, 999L, 'NAO-E-UM-ID', 'OUTRO-CODIGO'));

        Test.startTest();
        OmieServicoVinculoQueueable.vincularComFiltro('Id != null');   // o mais largo possível
        Test.stopTest();

        Assert.isNull([SELECT Id_Codigo_de_Servico__c FROM Product2 WHERE Id = :naoMencionado.Id]
                        .Id_Codigo_de_Servico__c,
            'Sem menção na fatia lida do Omie não há código para gravar.');
    }

    /** Filtro com OR dentro fica entre parênteses e não vaza para a base. */
    @IsTest
    static void filtroComOrNaoVazaParaABase() {
        Product2 mencionado   = OmieTestData.servico('SRV1');
        Product2 semPrecoNemOmie = OmieTestData.servico('SRV-INVISIVEL');
        insert new List<Product2>{ mencionado, semPrecoNemOmie };
        OmieTestData.instalar(OmieTestData.listaServicos(1, 111L, 'NAO-E-UM-ID', 'SRV1'));

        Test.startTest();
        OmieServicoVinculoQueueable.vincularComFiltro('IsActive = true OR IsActive = false');
        Test.stopTest();

        Assert.areEqual('111',
            [SELECT Id_Codigo_de_Servico__c FROM Product2 WHERE Id = :mencionado.Id]
                .Id_Codigo_de_Servico__c,
            'O mencionado deve passar.');
        Assert.isNull([SELECT Id_Codigo_de_Servico__c FROM Product2 WHERE Id = :semPrecoNemOmie.Id]
                        .Id_Codigo_de_Servico__c,
            'O OR do filtro não pode anular a condição de base.');
    }

    @IsTest
    static void filtroVazioSeComportaComoSemFiltro() {
        Product2 p = OmieTestData.servico('SRV1');
        insert p;
        OmieTestData.instalar(OmieTestData.listaServicos(1, 111L, 'NAO-E-UM-ID', 'SRV1'));

        Test.startTest();
        OmieServicoVinculoQueueable.vincularComFiltro('   ');
        Test.stopTest();

        Assert.areEqual('111',
            [SELECT Id_Codigo_de_Servico__c FROM Product2 WHERE Id = :p.Id].Id_Codigo_de_Servico__c,
            'Filtro em branco não deve virar SOQL inválido nem barrar ninguém.');
    }

    @IsTest
    static void filtroPorCampoDeIntegracaoFunciona() {
        Product2 pendente = OmieTestData.servico('SRV1');
        Product2 jaFeito  = OmieTestData.servico('SRV2');
        jaFeito.Id_Codigo_de_Servico__c = '555';
        insert new List<Product2>{ pendente, jaFeito };
        OmieTestData.instalar(
            '{"nPagina":1,"nTotPaginas":1,"nRegistros":2,"nTotRegistros":2,"cadastros":['
          + '{"intListar":{"nCodServ":111},"cabecalho":{"cCodigo":"SRV1"},"info":{"inativo":"N"}},'
          + '{"intListar":{"nCodServ":222},"cabecalho":{"cCodigo":"SRV2"},"info":{"inativo":"N"}}]}');

        Test.startTest();
        OmieServicoVinculoQueueable.vincularComFiltro('Id_Codigo_de_Servico__c = null');
        Test.stopTest();

        Assert.areEqual('111',
            [SELECT Id_Codigo_de_Servico__c FROM Product2 WHERE Id = :pendente.Id]
                .Id_Codigo_de_Servico__c,
            'O pendente deve ser vinculado.');
        Assert.areEqual('555',
            [SELECT Id_Codigo_de_Servico__c FROM Product2 WHERE Id = :jaFeito.Id]
                .Id_Codigo_de_Servico__c,
            'Quem já tinha código ficou fora do recorte e não foi reescrito.');
    }

    // =================================================================
    // Modo de um serviço só
    // =================================================================

    @IsTest
    static void umSoVinculaPeloCodigo() {
        Product2 alvo  = OmieTestData.servico('SRV-ALVO');
        Product2 outro = OmieTestData.servico('SRV-OUTRO');
        insert new List<Product2>{ alvo, outro };
        // A mesma página menciona os dois serviços.
        OmieTestData.instalar(
            '{"nPagina":1,"nTotPaginas":1,"nRegistros":2,"nTotRegistros":2,"cadastros":['
          + '{"intListar":{"nCodServ":111},"cabecalho":{"cCodigo":"SRV-ALVO"},"info":{"inativo":"N"}},'
          + '{"intListar":{"nCodServ":222},"cabecalho":{"cCodigo":"SRV-OUTRO"},"info":{"inativo":"N"}}]}');

        Test.startTest();
        OmieServicoVinculoQueueable.vincular(alvo.Id);
        Test.stopTest();

        Assert.areEqual('111',
            [SELECT Id_Codigo_de_Servico__c FROM Product2 WHERE Id = :alvo.Id].Id_Codigo_de_Servico__c,
            'O alvo deve ser vinculado ao seu código.');
        Assert.isNull([SELECT Id_Codigo_de_Servico__c FROM Product2 WHERE Id = :outro.Id]
                        .Id_Codigo_de_Servico__c,
            'Quem não foi pedido não deve ser tocado, mesmo estando na mesma página.');
    }

    @IsTest
    static void umSoVinculaPelaChaveDeIntegracao() {
        Product2 alvo = OmieTestData.servico('SRV1');
        insert alvo;
        OmieTestData.instalar(
            OmieTestData.listaServicos(1, 4811189079L, String.valueOf(alvo.Id), 'OUTRO-CODIGO'));

        Test.startTest();
        OmieServicoVinculoQueueable.vincular(alvo.Id);
        Test.stopTest();

        Assert.areEqual('4811189079',
            [SELECT Id_Codigo_de_Servico__c FROM Product2 WHERE Id = :alvo.Id].Id_Codigo_de_Servico__c,
            'A chave de integração casa mesmo com código diferente.');
    }

    /**
     * É o ponto do modo de um só: parar de varrer assim que achou, em vez de ler
     * o cadastro inteiro.
     */
    @IsTest
    static void umSoParaDeVarrerQuandoAcha() {
        Product2 alvo = OmieTestData.servico('SRV1');
        insert alvo;
        // Cadastro de 50 páginas, e o alvo está já na primeira.
        OmieTestData.Mock m = OmieTestData.instalar(
            OmieTestData.listaServicos(50, 999L, 'NAO-E-UM-ID', 'SRV1'));

        Test.startTest();
        OmieServicoVinculoQueueable.vincular(alvo.Id);
        Test.stopTest();

        Assert.areEqual(1, m.chamadas,
            'Achou na primeira página: não deve ler as outras 49.');
        Assert.areEqual('999',
            [SELECT Id_Codigo_de_Servico__c FROM Product2 WHERE Id = :alvo.Id].Id_Codigo_de_Servico__c,
            'E o vínculo deve estar gravado.');
    }

    @IsTest
    static void umSoVarreAFatiaInteiraQuandoNaoAcha() {
        Product2 alvo = OmieTestData.servico('SRV-QUE-NAO-ESTA-NO-OMIE');
        insert alvo;
        OmieTestData.Mock m = OmieTestData.instalar(
            OmieTestData.listaServicos(50, 999L, 'NAO-E-UM-ID', 'OUTRO'));

        Test.startTest();
        OmieServicoVinculoQueueable.vincular(alvo.Id);
        Test.stopTest();

        Assert.areEqual(20, m.chamadas,
            'Sem achar, consome a fatia de 20 páginas e se reenfileiraria para a próxima.');
        Assert.isNull([SELECT Id_Codigo_de_Servico__c FROM Product2 WHERE Id = :alvo.Id]
                        .Id_Codigo_de_Servico__c,
            'Nada a gravar se o serviço não existe no Omie.');
    }

    @IsTest
    static void umSoNaoRegravaQuandoOCodigoJaEOMesmo() {
        Product2 alvo = OmieTestData.servico('SRV1');
        alvo.Id_Codigo_de_Servico__c = '999';
        insert alvo;
        OmieTestData.Mock m = OmieTestData.instalar(
            OmieTestData.listaServicos(50, 999L, 'NAO-E-UM-ID', 'SRV1'));

        Test.startTest();
        OmieServicoVinculoQueueable.vincular(alvo.Id);
        Test.stopTest();

        Assert.areEqual(1, m.chamadas,
            'Já vinculado também encerra a varredura: o serviço foi encontrado.');
        Assert.areEqual('999',
            [SELECT Id_Codigo_de_Servico__c FROM Product2 WHERE Id = :alvo.Id].Id_Codigo_de_Servico__c,
            'O valor deve continuar o mesmo.');
    }

    @IsTest
    static void umSoIgnoraProdutoInexistente() {
        OmieTestData.Mock m = OmieTestData.instalar(
            OmieTestData.listaServicos(1, 999L, 'NAO-E-UM-ID', 'SRV1'));

        Test.startTest();
        OmieServicoVinculoQueueable.vincular('01t000000000000AAA');
        Test.stopTest();

        Assert.areEqual(0, m.chamadas,
            'Sem Product2 não vale nem chamar a API: requisição que não sai não conta para o Omie.');
    }

    /**
     * O modo completo continua varrendo tudo mesmo depois de vincular alguém: só
     * o modo de um só tem motivo para parar antes do fim.
     */
    @IsTest
    static void modoCompletoNaoParaAoPrimeiroVinculo() {
        Product2 p = OmieTestData.servico('SRV1');
        insert p;
        OmieTestData.Mock m = OmieTestData.instalar(
            OmieTestData.listaServicos(50, 999L, 'NAO-E-UM-ID', 'SRV1'));

        Test.startTest();
        System.enqueueJob(new OmieServicoVinculoQueueable());
        Test.stopTest();

        Assert.areEqual(20, m.chamadas,
            'O modo completo consome a fatia inteira, mesmo tendo achado na primeira página.');
    }
}