/**
 * Testes do OmieServicoCadastro: o ciclo de criar no Omie, guardar o código e
 * reconsultar pelo código guardado.
 */
@IsTest
private class OmieServicoCadastroTest {

    @IsTest
    static void criarGravaOCodigoRetornado() {
        Product2 p = OmieTestData.servico('SRV1');
        insert p;
        OmieTestData.Mock m = OmieTestData.instalar(
            OmieTestData.statusServico(4811189079L, '0', 'Serviço cadastrado com sucesso!'));

        Test.startTest();
        OmieServicoCadastro.Resultado r = OmieServicoCadastro.criar(p.Id);
        Test.stopTest();

        Assert.isTrue(r.ok, 'Com nCodServ no retorno, é sucesso.');
        Assert.areEqual(4811189079L, r.codigoOmie, 'O código deve vir no resultado.');
        Assert.areEqual('4811189079',
            [SELECT Id_Codigo_de_Servico__c FROM Product2 WHERE Id = :p.Id].Id_Codigo_de_Servico__c,
            'É o ponto do método: o código precisa ficar gravado no Product2.');
        Assert.isTrue(m.requisicoes[0].contains('IncluirCadastroServico'),
            'O método pedido é inclusão, não upsert.');
    }

    /**
     * Mandar intEditar na inclusão faz o Omie criar o cadastro SEM cCodIntServ,
     * e aí o vínculo se perde para sempre.
     */
    @IsTest
    static void criarEnviaOBlocoDeInclusaoComAChave() {
        Product2 p = OmieTestData.servico('SRV1');
        insert p;
        OmieTestData.Mock m = OmieTestData.instalar(OmieTestData.statusServico(1L, '0', 'ok'));

        Test.startTest();
        OmieServicoCadastro.criar(p.Id);
        Test.stopTest();

        Assert.isTrue(m.requisicoes[0].contains('intIncluir'), 'A inclusão usa o bloco intIncluir.');
        Assert.isFalse(m.requisicoes[0].contains('intEditar'), 'O bloco de edição não deve ir.');
        Assert.isTrue(m.requisicoes[0].contains(String.valueOf(p.Id)),
            'O Id do Product2 precisa ir como cCodIntServ.');
    }

    @IsTest
    static void criarMarcaComoIntegrado() {
        Product2 p = OmieTestData.servico('SRV1');
        insert p;
        OmieTestData.instalar(OmieTestData.statusServico(1L, '0', 'ok'));

        Test.startTest();
        OmieServicoCadastro.criar(p.Id);
        Test.stopTest();

        Product2 depois = [
            SELECT Omie_FlagIntegrado__c, Omie_Data_da_ltima_Integra_o__c
            FROM Product2 WHERE Id = :p.Id
        ];
        Assert.isTrue(depois.Omie_FlagIntegrado__c, 'Cadastrado no Omie é integrado.');
        Assert.isNotNull(depois.Omie_Data_da_ltima_Integra_o__c, 'A data deve ser registrada.');
    }

    @IsTest
    static void criarRecusaProdutoInexistente() {
        OmieTestData.Mock m = OmieTestData.instalar(OmieTestData.statusServico(1L, '0', 'ok'));

        Test.startTest();
        OmieServicoCadastro.Resultado r =
            OmieServicoCadastro.criar('01t000000000000AAA');   // Id que não existe
        Test.stopTest();

        Assert.isFalse(r.ok, 'Sem Product2 não há o que cadastrar.');
        Assert.areEqual(0, m.chamadas, 'E não deve gastar requisição com o Omie.');
    }

    @IsTest
    static void criarRecusaAntesDoCalloutQuandoODadoEInvalido() {
        Product2 p = OmieTestData.servico('SRV1');
        p.ProductCode = 'A'.repeat(21);
        insert p;
        OmieTestData.Mock m = OmieTestData.instalar(OmieTestData.statusServico(1L, '0', 'ok'));

        Test.startTest();
        OmieServicoCadastro.Resultado r = OmieServicoCadastro.criar(p.Id);
        Test.stopTest();

        Assert.isFalse(r.ok, 'Dado inválido não deve ser enviado.');
        Assert.areEqual(0, m.chamadas,
            'Requisição que não sai não conta para o bloqueio de 30 minutos do Omie.');
        Assert.isTrue(r.mensagem.contains('20'), 'A mensagem deve explicar o motivo: ' + r.mensagem);
    }

    @IsTest
    static void criarDevolveFalhaQuandoOOmieRecusa() {
        Product2 p = OmieTestData.servico('SRV1');
        insert p;
        OmieTestData.instalar(OmieTestData.statusServico(0L, '101', 'Descricao obrigatoria'));

        Test.startTest();
        OmieServicoCadastro.Resultado r = OmieServicoCadastro.criar(p.Id);
        Test.stopTest();

        Assert.isFalse(r.ok, 'Status diferente de 0 é falha.');
        Assert.areEqual('Descricao obrigatoria', r.mensagem, 'A mensagem do Omie deve ser repassada.');
        Assert.isNull([SELECT Id_Codigo_de_Servico__c FROM Product2 WHERE Id = :p.Id]
                        .Id_Codigo_de_Servico__c,
            'Sem sucesso não se grava código.');
    }

    @IsTest
    static void criarTrataErroHttpSemEstourar() {
        Product2 p = OmieTestData.servico('SRV1');
        insert p;
        OmieTestData.instalarErro(500, 'ERROR: Servico ja cadastrado!');

        Test.startTest();
        OmieServicoCadastro.Resultado r = OmieServicoCadastro.criar(p.Id);
        Test.stopTest();

        Assert.isFalse(r.ok, 'Erro do Omie é falha, não exceção para quem chamou.');
        Assert.isTrue(r.mensagem.contains('ja cadastrado'),
            'A mensagem do Omie deve chegar a quem chamou: ' + r.mensagem);
    }

    // =================================================================
    // A outra ponta do ciclo
    // =================================================================

    @IsTest
    static void consultarUsaOCodigoJaGravado() {
        Product2 p = OmieTestData.servico('SRV1');
        p.Id_Codigo_de_Servico__c = '4811189079';
        insert p;
        OmieTestData.Mock m = OmieTestData.instalar(
            '{"intListar":{"nCodServ":4811189079},"cabecalho":{"cCodigo":"SRV1"}}');

        Test.startTest();
        OmieServico s = OmieServicoCadastro.consultar(p.Id);
        Test.stopTest();

        Assert.areEqual(4811189079L, s.codigoOmie(), 'Deve devolver o serviço do Omie.');
        Assert.isTrue(m.requisicoes[0].contains('nCodServ'),
            'Com o código em mãos, a consulta é direta pelo código.');
    }

    @IsTest
    static void consultarCaiParaAChaveQuandoNaoHaCodigo() {
        Product2 p = OmieTestData.servico('SRV1');
        insert p;
        OmieTestData.Mock m = OmieTestData.instalar('{"intListar":{"nCodServ":1}}');

        Test.startTest();
        OmieServicoCadastro.consultar(p.Id);
        Test.stopTest();

        Assert.isTrue(m.requisicoes[0].contains('cCodIntServ'),
            'Sem código gravado, a chave de integração é o caminho.');
    }

    @IsTest
    static void consultarDevolveNuloParaProdutoInexistente() {
        OmieTestData.Mock m = OmieTestData.instalar('{"intListar":{"nCodServ":1}}');

        Test.startTest();
        OmieServico s = OmieServicoCadastro.consultar('01t000000000000AAA');
        Test.stopTest();

        Assert.isNull(s, 'Sem Product2 não há o que consultar.');
        Assert.areEqual(0, m.chamadas, 'E não deve gastar requisição.');
    }

    /**
     * O ciclo criar + consultar NÃO pode ser testado num método só, e isso não é
     * limitação de teste: o criar() termina com DML e o consultar() começa com
     * callout, e o Apex proíbe callout depois de gravação na mesma transação.
     * Chamar os dois em sequência lança "You have uncommitted work pending" —
     * inclusive em Execute Anonymous. São duas execuções separadas, sempre.
     *
     * O ciclo fica coberto pelas duas metades: criarGravaOCodigoRetornado prova
     * que o código é gravado, e consultarUsaOCodigoJaGravado prova que a consulta
     * parte justamente desse código.
     */

    @IsTest
    static void resumoDoResultadoEhLegivel() {
        Product2 p = OmieTestData.servico('SRV1');
        insert p;
        OmieTestData.instalar(OmieTestData.statusServico(4811189079L, '0', 'Cadastrado'));

        Test.startTest();
        String resumo = String.valueOf(OmieServicoCadastro.criar(p.Id));
        Test.stopTest();

        Assert.isTrue(resumo.startsWith('OK'), 'O toString deve abrir com o veredito: ' + resumo);
        Assert.isTrue(resumo.contains('4811189079'), 'E mostrar o código: ' + resumo);
    }
}