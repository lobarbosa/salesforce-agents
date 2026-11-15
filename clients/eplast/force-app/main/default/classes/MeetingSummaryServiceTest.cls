/**
 * MeetingSummaryServiceTest (EPLAST-34)
 *
 * Cenarios: caminho feliz dos 4 tipos, bulk de 200 Opportunities e 200 Orders,
 * negativos (tipo invalido, periodo invalido, periodo longo, erro inesperado, volume
 * excedido, vazio) e permissao (usuario sem leitura de Opportunity e Order).
 * Sem SeeAllData. Dados via TESTE-EPLAST34 criados no proprio teste.
 */
@IsTest
private class MeetingSummaryServiceTest {

    private static final String PREFIXO = 'TESTE-EPLAST34';
    private static final Date HOJE = Date.today();

    @TestSetup
    static void preparar() {
        // Dono das contas precisa de ProtheusSellerId (validation rule de Opportunity).
        update new User(Id = UserInfo.getUserId(), ProtheusSellerId__c = 'T34');
    }

    private static Integer seqCnpj = 10000000;

    // CNPJ sintetico com digitos verificadores validos (regra de Account exige CNPJ valido).
    private static String gerarCnpj() {
        seqCnpj++;
        String base = String.valueOf(seqCnpj) + '0001';
        base += digito(base, new List<Integer>{ 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2 });
        base += digito(base, new List<Integer>{ 6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2 });
        return base.substring(0, 2) + '.' + base.substring(2, 5) + '.' + base.substring(5, 8) + '/'
            + base.substring(8, 12) + '-' + base.substring(12, 14);
    }

    private static String digito(String base, List<Integer> pesos) {
        Integer soma = 0;
        for (Integer i = 0; i < base.length(); i++) {
            soma += Integer.valueOf(base.substring(i, i + 1)) * pesos[i];
        }
        Integer resto = Math.mod(soma, 11);
        return String.valueOf(resto < 2 ? 0 : 11 - resto);
    }

    // Fixture apenas: desliga o trigger custom de Account/Opportunity (CNPJ via BrasilAPI e envio ao
    // Protheus, com callout e Queueable) para criar dado sintetico. A classe testada nao usa isso.
    private static void prepararFixture() {
        TriggerUtility.bypassTrigger = true;
    }

    private static Account criarConta(String nome) {
        return criarContas(new List<String>{ nome })[0];
    }

    private static List<Account> criarContas(List<String> nomes) {
        prepararFixture();
        List<Account> contas = new List<Account>();
        for (String nome : nomes) {
            contas.add(novaConta(nome));
        }
        // A trigger de Account consulta a BrasilAPI pelo CNPJ: resposta simulada de erro, sem rede.
        Test.setMock(HttpCalloutMock.class, new MockBrasilAPISearchCNPJErrorResponse());
        Database.DMLOptions opcoes = new Database.DMLOptions();
        opcoes.DuplicateRuleHeader.AllowSave = true;
        Database.insert(contas, opcoes);
        return contas;
    }

    private static Account novaConta(String nome) {
        return new Account(
            CompanyDocument__c = gerarCnpj(),
            Name = nome,
            Phone = '(11) 91234-5678',
            BillingStreet = 'Rua Teste 1',
            BillingCity = 'Sao Paulo',
            BillingState = 'SP',
            BillingPostalCode = '01000-000',
            BillingNeighborhood__c = 'Centro',
            CNAE__c = '1234567',
            CompanyName__c = nome,
            Email__c = 'teste34@example.com',
            Store__c = '01'
        );
    }

    private static List<Opportunity> criarOpps(Account conta, Integer qtd, Decimal valor) {
        prepararFixture();
        String etapa = [SELECT MasterLabel FROM OpportunityStage WHERE IsClosed = false AND IsActive = true LIMIT 1].MasterLabel;
        Id rt = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Industria').getRecordTypeId();
        List<Opportunity> opps = new List<Opportunity>();
        for (Integer i = 0; i < qtd; i++) {
            opps.add(new Opportunity(
                Name = PREFIXO + ' ' + i, AccountId = conta.Id, StageName = etapa,
                CloseDate = HOJE, Amount = valor, RecordTypeId = rt
            ));
        }
        insert opps;
        return opps;
    }

    private static void criarOrders(Account conta, Integer qtd) {
        prepararFixture();
        String status = Order.Status.getDescribe().getPicklistValues()[0].getValue();
        List<Order> ords = new List<Order>();
        for (Integer i = 0; i < qtd; i++) {
            ords.add(new Order(AccountId = conta.Id, EffectiveDate = HOJE, Status = status));
        }
        insert ords;
    }

    private static MeetingSummaryService.MeetingSummaryResult chamar(String tipo, Date ini, Date fim) {
        MeetingSummaryService.MeetingSummaryRequest req = new MeetingSummaryService.MeetingSummaryRequest();
        req.tipo = tipo;
        req.dataInicio = ini;
        req.dataFim = fim;
        List<MeetingSummaryService.MeetingSummaryResult> rs =
            MeetingSummaryService.resumir(new List<MeetingSummaryService.MeetingSummaryRequest>{ req });
        System.assertEquals(1, rs.size(), 'Uma resposta por requisicao.');
        return rs[0];
    }

    @IsTest
    static void deveGerarComercialGddSopBoardComDados() {
        Account a = criarConta(PREFIXO + ' Conta A');
        criarOpps(a, 3, 1000);
        criarOrders(a, 2);

        Test.startTest();
        MeetingSummaryService.MeetingSummaryResult com = chamar('COMERCIAL', null, null);
        MeetingSummaryService.MeetingSummaryResult gdd = chamar('GDD', null, null);
        MeetingSummaryService.MeetingSummaryResult sop = chamar('S&OP', null, null);
        MeetingSummaryService.MeetingSummaryResult brd = chamar('board', null, null);
        Test.stopTest();

        System.assertEquals('OK', com.status, com.textoResumo);
        System.assert(com.textoResumo.contains('3 oportunidade(s)'), com.textoResumo);
        System.assert(com.textoResumo.contains('R$ 3.000,00'), com.textoResumo);
        System.assert(com.textoResumo.contains('por vendedor'), com.textoResumo);
        System.assert(com.textoResumo.contains('Dados ate '), 'Rodape com data de corte.');
        System.assertNotEquals(null, com.dataHoraCorte);

        System.assertEquals('OK', gdd.status, gdd.textoResumo);
        System.assert(gdd.textoResumo.contains(PREFIXO + ' Conta A'), gdd.textoResumo);

        System.assertEquals('OK', sop.status, sop.textoResumo);
        System.assert(sop.textoResumo.contains('2 pedido(s)'), sop.textoResumo);

        System.assertEquals('OK', brd.status, brd.textoResumo);
        System.assert(brd.textoResumo.contains('3) Total geral'), brd.textoResumo);
        System.assert(!brd.textoResumo.contains(PREFIXO + ' Conta A'), 'Board nao mostra nome de conta.');
    }

    @IsTest
    static void deveSomarBulkDe200OportunidadesE200Pedidos() {
        Account a = criarConta(PREFIXO + ' Conta Bulk');
        criarOpps(a, 200, 10);
        criarOrders(a, 200);

        Test.startTest();
        MeetingSummaryService.MeetingSummaryResult brd = chamar('BOARD', null, null);
        Integer consultas = Limits.getQueries();
        Test.stopTest();

        System.assertEquals('OK', brd.status, brd.textoResumo);
        System.assert(brd.textoResumo.contains('200 oportunidade(s), R$ 2.000,00'), brd.textoResumo);
        System.assert(brd.textoResumo.contains('200 pedido(s)'), brd.textoResumo);
        System.assert(consultas <= 20, 'Consultas por geracao devem ser poucas: ' + consultas);
    }

    @IsTest
    static void deveMostrarDemaisContasQuandoHaMaisQueOTop() {
        List<String> nomes = new List<String>();
        for (Integer i = 0; i < 22; i++) {
            nomes.add(PREFIXO + ' C' + i);
        }
        List<Account> contas = criarContas(nomes);
        String etapa = [SELECT MasterLabel FROM OpportunityStage WHERE IsClosed = false AND IsActive = true LIMIT 1].MasterLabel;
        Id rt = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Industria').getRecordTypeId();
        List<Opportunity> opps = new List<Opportunity>();
        for (Account c : contas) {
            opps.add(new Opportunity(Name = PREFIXO + ' O', AccountId = c.Id, StageName = etapa,
                CloseDate = HOJE, Amount = 100, RecordTypeId = rt));
        }
        insert opps;
        Test.startTest();
        MeetingSummaryService.MeetingSummaryResult gdd = chamar('GDD', null, null);
        Test.stopTest();
        System.assert(gdd.textoResumo.contains('Demais contas: 2 registro(s)'), gdd.textoResumo);
    }

    @IsTest
    static void deveRespeitarPeriodoInformado() {
        Account a = criarConta(PREFIXO + ' Conta P');
        criarOpps(a, 2, 500);
        Date ini = HOJE.addYears(-2);
        Test.startTest();
        MeetingSummaryService.MeetingSummaryResult fora = chamar('COMERCIAL', ini, ini.addDays(10));
        MeetingSummaryService.MeetingSummaryResult soInicio = chamar('COMERCIAL', HOJE, null);
        MeetingSummaryService.MeetingSummaryResult soFim = chamar('COMERCIAL', null, HOJE);
        Test.stopTest();
        System.assertEquals('OK', fora.status, 'Secao vazia continua OK.');
        System.assert(fora.textoResumo.contains('[VAZIO]'), fora.textoResumo);
        System.assert(fora.textoResumo.contains('Nenhum registro no periodo.'), fora.textoResumo);
        System.assert(soInicio.textoResumo.contains('2 oportunidade(s)'), soInicio.textoResumo);
        System.assert(soFim.textoResumo.contains('2 oportunidade(s)'), soFim.textoResumo);
    }

    @IsTest
    static void deveRecusarTipoInvalidoPeriodoInvertidoEPeriodoLongo() {
        Test.startTest();
        MeetingSummaryService.MeetingSummaryResult tipo = chamar('XYZ', null, null);
        MeetingSummaryService.MeetingSummaryResult vazio = chamar(null, null, null);
        MeetingSummaryService.MeetingSummaryResult invertido = chamar('GDD', HOJE, HOJE.addDays(-1));
        MeetingSummaryService.MeetingSummaryResult longo = chamar('GDD', HOJE.addDays(-400), HOJE);
        Test.stopTest();
        System.assertEquals('ERRO', tipo.status);
        System.assert(tipo.textoResumo.contains('Tipo de reuniao invalido'), tipo.textoResumo);
        System.assertEquals('ERRO', vazio.status);
        System.assertEquals('ERRO', invertido.status);
        System.assert(invertido.textoResumo.contains('posterior'), invertido.textoResumo);
        System.assertEquals('ERRO', longo.status);
        System.assert(longo.textoResumo.contains('366'), longo.textoResumo);
    }

    @IsTest
    static void deveDevolverListaVaziaOuErroSemExplodir() {
        System.assertEquals(0, MeetingSummaryService.resumir(null).size());
        System.assertEquals(0, MeetingSummaryService.resumir(new List<MeetingSummaryService.MeetingSummaryRequest>()).size());

        MeetingSummaryService.forcarErro = true;
        MeetingSummaryService.MeetingSummaryResult r = chamar('GDD', null, null);
        System.assertEquals('ERRO', r.status);
        System.assert(r.textoResumo.contains('Nao foi possivel gerar o resumo'), r.textoResumo);
    }

    @IsTest
    static void deveSinalizarVolumeExcedido() {
        Account a = criarConta(PREFIXO + ' Conta V');
        criarOpps(a, 3, 100);
        MeetingSummaryService.tetoLinhas = 1;
        Test.startTest();
        MeetingSummaryService.MeetingSummaryResult r = chamar('COMERCIAL', null, null);
        Test.stopTest();
        System.assertEquals('PARCIAL', r.status, r.textoResumo);
        System.assert(r.textoResumo.contains('VOLUME_EXCEDIDO'), r.textoResumo);
        System.assert(r.textoResumo.contains('Reduza o periodo'), r.textoResumo);
    }

    @IsTest
    static void deveFormatarMoedaEmPtBr() {
        System.assertEquals('R$ 0,00', MeetingSummaryService.moeda(null));
        System.assertEquals('R$ 1.234.567,89', MeetingSummaryService.moeda(1234567.891));
        System.assertEquals('-R$ 10,50', MeetingSummaryService.moeda(-10.5));
        System.assertEquals('R$ 999,00', MeetingSummaryService.moeda(999));
    }

    @IsTest
    static void deveInformarSemAcessoParaUsuarioSemLeituraDeOpportunityEOrder() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Minimum Access - Salesforce' LIMIT 1];
        User u = new User(
            Alias = 'm34', Email = 'm34@example.com', Username = 'm34' + System.currentTimeMillis() + '@example.com.test',
            LastName = 'M34', ProfileId = p.Id, TimeZoneSidKey = 'America/Sao_Paulo', LocaleSidKey = 'pt_BR',
            EmailEncodingKey = 'UTF-8', LanguageLocaleKey = 'en_US'
        );
        insert u;

        MeetingSummaryService.MeetingSummaryResult com;
        MeetingSummaryService.MeetingSummaryResult brd;
        System.runAs(u) {
            com = chamar('COMERCIAL', null, null);
            brd = chamar('BOARD', null, null);
        }
        System.assertEquals('SEM_ACESSO', com.status, com.textoResumo);
        System.assert(com.textoResumo.contains('nao tem acesso de leitura a Opportunity'), com.textoResumo);
        System.assertEquals('SEM_ACESSO', brd.status, brd.textoResumo);
    }
}
