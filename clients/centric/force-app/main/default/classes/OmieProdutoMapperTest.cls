/**
 * Testes do OmieProdutoMapper: validação e de-para nos dois sentidos.
 * Não faz callout — o mapper é puro.
 */
@IsTest
private class OmieProdutoMapperTest {

    @IsTest
    static void validoQuandoTemCodigoEDescricao() {
        Assert.isNull(OmieProdutoMapper.validar(OmieTestData.produto('SKU1')),
            'Produto com ProductCode e Name é válido.');
    }

    @IsTest
    static void recusaSemProductCode() {
        Product2 p = OmieTestData.produto('SKU1');
        p.ProductCode = null;

        String erro = OmieProdutoMapper.validar(p);
        Assert.isNotNull(erro, 'Sem ProductCode não dá para enviar.');
        Assert.isTrue(erro.contains('ProductCode'), 'A mensagem deve dizer qual campo falta: ' + erro);
    }

    @IsTest
    static void recusaSemName() {
        Product2 p = OmieTestData.produto('SKU1');
        p.Name = null;

        String erro = OmieProdutoMapper.validar(p);
        Assert.isNotNull(erro, 'Sem Name não dá para enviar.');
        Assert.isTrue(erro.contains('Name'), 'A mensagem deve dizer qual campo falta: ' + erro);
    }

    @IsTest
    static void separarValidosDividePelaValidacao() {
        Product2 ok   = OmieTestData.produto('SKU1');
        Product2 ruim = OmieTestData.produto('SKU2');
        insert new List<Product2>{ ok, ruim };

        // Invalidado só em memória: a org tem validation rule exigindo
        // ProductCode, então não existe registro assim gravado no banco.
        ruim.ProductCode = null;

        OmieProdutoMapper.Resultado r =
            OmieProdutoMapper.separarValidos(new List<Product2>{ ok, ruim });

        Assert.areEqual(1, r.validos.size(), 'Só o produto completo é válido.');
        Assert.areEqual(ok.Id, r.validos[0].Id, 'O válido deve ser o que tem ProductCode.');
        Assert.isTrue(r.erros.containsKey(ruim.Id), 'O inválido deve vir com o motivo.');
    }

    @IsTest
    static void toOmieUsaOIdComoChaveDeIntegracao() {
        Product2 p = OmieTestData.produto('SKU1');
        insert p;
        // SOQL dinâmico não aceita caminho (:p.Id), só variável.
        Id pid = p.Id;
        p = Database.query('SELECT ' + OmieProdutoMapper.CAMPOS_SOQL + ' FROM Product2 WHERE Id = :pid');

        OmieProduto o = OmieProdutoMapper.toOmie(p);

        Assert.areEqual(String.valueOf(p.Id), o.codigo_produto_integracao,
            'O Id do Product2 é a chave de integração: é o que garante idempotência.');
        Assert.areEqual('SKU1', o.codigo, 'O ProductCode vira codigo.');
        Assert.areEqual('UN', o.unidade, 'A unidade deve subir em maiúscula.');
        Assert.areEqual('85176255', o.ncm, 'O MCN__c vira ncm.');
        Assert.areEqual('N', o.inativo, 'Produto ativo é inativo = N.');
    }

    @IsTest
    static void toOmieMandaOCodigoDoOmieQuandoJaExiste() {
        Product2 p = OmieTestData.produto('SKU1');
        p.Id_Codigo_de_Servico__c = '4811189079';
        insert p;
        // SOQL dinâmico não aceita caminho (:p.Id), só variável.
        Id pid = p.Id;
        p = Database.query('SELECT ' + OmieProdutoMapper.CAMPOS_SOQL + ' FROM Product2 WHERE Id = :pid');

        OmieProduto o = OmieProdutoMapper.toOmie(p);

        Assert.areEqual(4811189079L, o.codigo_produto,
            'Com o código do Omie em mãos, mandá-lo torna o upsert inequívoco.');
    }

    @IsTest
    static void toOmieEmListaConverteTodos() {
        Product2 a = OmieTestData.produto('SKU1');
        Product2 b = OmieTestData.produto('SKU2');
        insert new List<Product2>{ a, b };
        List<Product2> lidos = Database.query(
            'SELECT ' + OmieProdutoMapper.CAMPOS_SOQL + ' FROM Product2 ORDER BY ProductCode');

        Assert.areEqual(2, OmieProdutoMapper.toOmie(lidos).size(), 'Deve converter os dois.');
    }

    @IsTest
    static void fromOmieReaproveitaOIdQuandoAChaveEUmId() {
        Product2 p = OmieTestData.produto('SKU1');
        insert p;

        OmieProduto o = new OmieProduto();
        o.codigo_produto_integracao = String.valueOf(p.Id);
        o.codigo_produto = 4811189079L;
        o.codigo         = 'SKU1';
        o.descricao      = 'Do Omie';
        o.inativo        = 'N';

        Product2 convertido = OmieProdutoMapper.fromOmie(o);

        Assert.areEqual(p.Id, convertido.Id,
            'Chave de integração que é Id permite update direto, sem consulta extra.');
        Assert.areEqual('Do Omie', convertido.Name, 'A descrição do Omie vira Name.');
        Assert.areEqual('4811189079', convertido.Id_Codigo_de_Servico__c, 'O código do Omie deve ser gravado.');
        Assert.isTrue(convertido.IsActive, 'inativo = N significa ativo.');
        Assert.isTrue(convertido.Omie_FlagIntegrado__c, 'Veio do Omie, então está integrado.');
    }

    @IsTest
    static void fromOmieIgnoraChaveQueNaoEId() {
        OmieProduto o = new OmieProduto();
        o.codigo_produto_integracao = 'CRIADO-FORA-DO-SALESFORCE';
        o.codigo_produto = 99L;
        o.inativo = 'S';

        Product2 convertido = OmieProdutoMapper.fromOmie(o);

        Assert.isNull(convertido.Id,
            'Chave criada fora do Salesforce deve seguir como registro novo, não estourar.');
        Assert.isFalse(convertido.IsActive, 'inativo = S significa inativo.');
    }
}