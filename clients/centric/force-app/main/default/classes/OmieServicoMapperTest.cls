/**
 * Testes do OmieServicoMapper: validação, de-para e a troca do bloco de
 * identificação entre inclusão e upsert.
 */
@IsTest
private class OmieServicoMapperTest {

    @IsTest
    static void validoQuandoTemCodigoEDescricao() {
        Assert.isNull(OmieServicoMapper.validar(OmieTestData.servico('SRV1')),
            'Serviço com ProductCode e Name é válido.');
    }

    @IsTest
    static void recusaSemProductCode() {
        Product2 p = OmieTestData.servico('SRV1');
        p.ProductCode = null;

        String erro = OmieServicoMapper.validar(p);
        Assert.isNotNull(erro, 'Sem ProductCode não dá para enviar.');
        Assert.isTrue(erro.contains('ProductCode'), 'A mensagem deve dizer o campo: ' + erro);
    }

    @IsTest
    static void recusaSemName() {
        Product2 p = OmieTestData.servico('SRV1');
        p.Name = null;

        Assert.isNotNull(OmieServicoMapper.validar(p), 'Sem Name não dá para enviar.');
    }

    /**
     * Truncar o código criaria um serviço ERRADO no Omie e quebraria o vínculo
     * depois, então o mapper recusa em vez de aparar.
     */
    @IsTest
    static void recusaCodigoMaiorQueOLimiteDoOmie() {
        Product2 p = OmieTestData.servico('X');
        p.ProductCode = 'A'.repeat(21);

        String erro = OmieServicoMapper.validar(p);
        Assert.isNotNull(erro, 'Código de 21 caracteres deve ser recusado.');
        Assert.isTrue(erro.contains('20'), 'A mensagem deve citar o limite: ' + erro);
    }

    @IsTest
    static void aceitaCodigoExatamenteNoLimite() {
        Product2 p = OmieTestData.servico('X');
        p.ProductCode = 'A'.repeat(20);

        Assert.isNull(OmieServicoMapper.validar(p), '20 caracteres está dentro do limite.');
    }

    @IsTest
    static void separarValidosDividePelaValidacao() {
        Product2 ok   = OmieTestData.servico('SRV1');
        Product2 ruim = OmieTestData.servico('SRV2');
        insert new List<Product2>{ ok, ruim };

        // Invalidado só em memória: Name é obrigatório no Product2, então não
        // existe registro assim gravado no banco.
        ruim.Name = null;

        OmieServicoMapper.Resultado r =
            OmieServicoMapper.separarValidos(new List<Product2>{ ok, ruim });

        Assert.areEqual(1, r.validos.size(), 'Só o serviço completo é válido.');
        Assert.isTrue(r.erros.containsKey(ruim.Id), 'O inválido deve vir com o motivo.');
    }

    @IsTest
    static void toOmieMontaOBlocoDoUpsert() {
        Product2 p = OmieTestData.servico('SRV1');
        p.Id_Codigo_de_Servico__c = '4811189079';
        insert p;
        // SOQL dinâmico não aceita caminho (:p.Id), só variável.
        Id pid = p.Id;
        p = Database.query('SELECT ' + OmieServicoMapper.CAMPOS_SOQL + ' FROM Product2 WHERE Id = :pid');

        OmieServico s = OmieServicoMapper.toOmie(p);

        Assert.isNotNull(s.intEditar, 'O Upsert espera o bloco intEditar.');
        Assert.isNull(s.intIncluir, 'O bloco de inclusão não deve ir junto.');
        Assert.areEqual(String.valueOf(p.Id), s.intEditar.cCodIntServ,
            'O Id do Product2 é a chave de integração.');
        Assert.areEqual(4811189079L, s.intEditar.nCodServ, 'O código conhecido deve ir.');
        Assert.areEqual('SRV1', s.cabecalho.cCodigo, 'O ProductCode vira cCodigo.');
        Assert.areEqual(250, s.cabecalho.nPrecoUnit, 'O Valor__c vira nPrecoUnit.');
        Assert.areEqual('Descrição de SRV1', s.descricao.cDescrCompleta,
            'A Description vira cDescrCompleta.');
    }

    /**
     * O nome do bloco muda por método. Mandar intEditar no IncluirCadastroServico
     * faz o Omie criar o cadastro SEM cCodIntServ, e aí o vínculo se perde.
     */
    @IsTest
    static void paraIncluirTrocaOBlocoENaoMandaCodigo() {
        Product2 p = OmieTestData.servico('SRV1');
        p.Id_Codigo_de_Servico__c = '4811189079';
        insert p;
        // SOQL dinâmico não aceita caminho (:p.Id), só variável.
        Id pid = p.Id;
        p = Database.query('SELECT ' + OmieServicoMapper.CAMPOS_SOQL + ' FROM Product2 WHERE Id = :pid');

        OmieServico s = OmieServicoMapper.paraIncluir(p);

        Assert.isNotNull(s.intIncluir, 'A inclusão espera o bloco intIncluir.');
        Assert.isNull(s.intEditar, 'O bloco de edição precisa sair, senão vão os dois.');
        Assert.areEqual(String.valueOf(p.Id), s.intIncluir.cCodIntServ,
            'A chave de integração é o que permite reencontrar o serviço depois.');
        Assert.isNull(s.intIncluir.nCodServ, 'Numa inclusão o código do Omie ainda não existe.');
    }

    @IsTest
    static void toOmieTruncaDescricaoNoLimiteDoOmie() {
        Product2 p = OmieTestData.servico('SRV1');
        p.Name = 'A'.repeat(150);
        insert p;
        // SOQL dinâmico não aceita caminho (:p.Id), só variável.
        Id pid = p.Id;
        p = Database.query('SELECT ' + OmieServicoMapper.CAMPOS_SOQL + ' FROM Product2 WHERE Id = :pid');

        OmieServico s = OmieServicoMapper.toOmie(p);

        Assert.areEqual(100, s.cabecalho.cDescricao.length(),
            'A descrição resumida do Omie aceita 100; truncar aqui é seguro porque não é chave.');
    }

    @IsTest
    static void toOmieEmListaConverteTodos() {
        insert new List<Product2>{ OmieTestData.servico('SRV1'), OmieTestData.servico('SRV2') };
        List<Product2> lidos = Database.query(
            'SELECT ' + OmieServicoMapper.CAMPOS_SOQL + ' FROM Product2 ORDER BY ProductCode');

        Assert.areEqual(2, OmieServicoMapper.toOmie(lidos).size(), 'Deve converter os dois.');
    }

    @IsTest
    static void codigoInvalidoNoCampoNaoDerrubaOEnvio() {
        Product2 p = OmieTestData.servico('SRV1');
        p.Id_Codigo_de_Servico__c = 'nao-e-numero';
        insert p;
        // SOQL dinâmico não aceita caminho (:p.Id), só variável.
        Id pid = p.Id;
        p = Database.query('SELECT ' + OmieServicoMapper.CAMPOS_SOQL + ' FROM Product2 WHERE Id = :pid');

        OmieServico s = OmieServicoMapper.toOmie(p);

        Assert.isNull(s.intEditar.nCodServ,
            'Lixo no campo deve virar null, não exceção: o upsert ainda casa pela chave.');
    }

    @IsTest
    static void fromOmieReaproveitaOIdEMarcaComoServico() {
        Product2 p = OmieTestData.servico('SRV1');
        insert p;

        OmieServico s = new OmieServico();
        s.intListar  = new OmieServico.Chave(String.valueOf(p.Id), 4811189079L);
        s.cabecalho  = new OmieServico.Cabecalho();
        s.cabecalho.cCodigo    = 'SRV1';
        s.cabecalho.cDescricao = 'Do Omie';
        s.cabecalho.nPrecoUnit = 300;
        s.descricao = new OmieServico.Descricao();
        s.descricao.cDescrCompleta = 'Completa';
        s.info = new OmieServico.Info();
        s.info.inativo = 'N';

        Product2 convertido = OmieServicoMapper.fromOmie(s);

        Assert.areEqual(p.Id, convertido.Id, 'Chave que é Id permite update direto.');
        Assert.areEqual(OmieServicoMapper.FAMILY_SERVICO, convertido.Family,
            'É o Family que separa serviço de produto no Product2.');
        Assert.areEqual('Do Omie', convertido.Name, 'A cDescricao vira Name.');
        Assert.areEqual('4811189079', convertido.Id_Codigo_de_Servico__c, 'O nCodServ deve ser gravado.');
        Assert.areEqual(300, convertido.Valor__c, 'O nPrecoUnit vira Valor__c.');
        Assert.isTrue(convertido.IsActive, 'inativo = N significa ativo.');
    }

    @IsTest
    static void fromOmieIgnoraChaveQueNaoEId() {
        OmieServico s = new OmieServico();
        s.intListar = new OmieServico.Chave('CRIADO-NO-OMIE', 99L);
        s.info = new OmieServico.Info();
        s.info.inativo = 'S';

        Product2 convertido = OmieServicoMapper.fromOmie(s);

        Assert.isNull(convertido.Id, 'Chave de fora deve seguir como registro novo.');
        Assert.isFalse(convertido.IsActive, 'inativo = S significa inativo.');
    }

    @IsTest
    static void fromOmieEmListaConverteTodos() {
        OmieServico a = new OmieServico();
        a.intListar = new OmieServico.Chave('A', 1L);
        OmieServico b = new OmieServico();
        b.intListar = new OmieServico.Chave('B', 2L);

        Assert.areEqual(2, OmieServicoMapper.fromOmie(new List<OmieServico>{ a, b }).size(),
            'Deve converter os dois.');
    }
}