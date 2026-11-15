/**
 * EPLAST-35. Testes de LeadAssignmentService e do Flow Lead_AfterInsert_AplicaRegraAtribuicao.
 * Dados sinteticos (sem CPF, e-mail ou telefone). Phone e MobilePhone ficam vazios porque as
 * validation rules ativas de Lead (Celular, Telefone) exigem formato especifico quando preenchidos.
 * A regra Distribuicao_Regional_Leads e as filas Leads_* sao metadata do mesmo pacote.
 */
@IsTest
private class LeadAssignmentServiceTest {

    private static final Map<String, String> FILA_POR_UF = new Map<String, String>{
        'SP' => 'Leads_SP',
        'RJ' => 'Leads_RJ',
        'MG' => 'Leads_MG',
        'ES' => 'Leads_ES',
        'PR' => 'Leads_Sul',
        'GO' => 'Leads_CO',
        'BA' => 'Leads_NO_NE'
    };

    private static Map<String, Id> filasPorNome() {
        Map<String, Id> result = new Map<String, Id>();
        for (Group g : [SELECT Id, DeveloperName FROM Group WHERE Type = 'Queue' AND DeveloperName LIKE 'Leads_%']) {
            result.put(g.DeveloperName, g.Id);
        }
        return result;
    }

    private static List<Lead> novosLeads(Integer total, List<String> ufs) {
        List<Lead> leads = new List<Lead>();
        for (Integer i = 0; i < total; i++) {
            leads.add(new Lead(
                LastName = 'Teste' + i,
                Company = 'Empresa Sintetica ' + i,
                State = ufs[Math.mod(i, ufs.size())]
            ));
        }
        return leads;
    }

    private static User usuarioIntegracao(Boolean comPermissionSet) {
        Profile p = [SELECT Id FROM Profile WHERE PermissionsModifyAllData = true AND UserType = 'Standard' LIMIT 1];
        String sufixo = String.valueOf(Math.abs(Crypto.getRandomInteger()));
        User u = new User(
            Alias = 'int' + sufixo.left(5),
            Username = 'int' + sufixo + '@leadassign.test.invalid',
            Email = 'int' + sufixo + '@leadassign.test.invalid',
            LastName = 'Integracao',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Sao_Paulo',
            LocaleSidKey = 'pt_BR',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'pt_BR'
        );
        insert u;
        if (comPermissionSet) {
            PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'PS_Integracao_DistribuicaoLead' LIMIT 1];
            insert new PermissionSetAssignment(AssigneeId = u.Id, PermissionSetId = ps.Id);
        }
        return u;
    }

    @IsTest
    static void caminhoFelizDistribuiPorRegiao() {
        Map<String, Id> filas = filasPorNome();
        List<String> ufs = new List<String>(FILA_POR_UF.keySet());
        List<Lead> leads = novosLeads(ufs.size(), ufs);
        insert leads;

        Test.startTest();
        LeadAssignmentService.aplicarRegraPadrao(new List<Id>(new Map<Id, Lead>(leads).keySet()));
        Test.stopTest();

        for (Lead l : [SELECT Id, State, OwnerId FROM Lead WHERE Id IN :leads]) {
            System.assertEquals(filas.get(FILA_POR_UF.get(l.State)), l.OwnerId,
                'UF ' + l.State + ' deve cair em ' + FILA_POR_UF.get(l.State));
        }
    }

    @IsTest
    static void ufVaziaOuForaDoPadraoVaiParaTriagem() {
        Map<String, Id> filas = filasPorNome();
        List<Lead> leads = new List<Lead>{
            new Lead(LastName = 'SemUf', Company = 'Sintetica A'),
            new Lead(LastName = 'UfPorExtenso', Company = 'Sintetica B', State = 'Sao Paulo')
        };
        insert leads;

        Test.startTest();
        LeadAssignmentService.aplicarRegraPadrao(new List<Id>(new Map<Id, Lead>(leads).keySet()));
        Test.stopTest();

        for (Lead l : [SELECT OwnerId FROM Lead WHERE Id IN :leads]) {
            System.assertEquals(filas.get('Leads_Triagem'), l.OwnerId, 'Sem UF valida deve cair na Triagem');
        }
    }

    @IsTest
    static void loteDe200DistribuiTodos() {
        Map<String, Id> filas = filasPorNome();
        List<String> ufs = new List<String>(FILA_POR_UF.keySet());
        List<Lead> leads = novosLeads(200, ufs);
        insert leads;

        Test.startTest();
        LeadAssignmentService.aplicarRegraPadrao(new List<Id>(new Map<Id, Lead>(leads).keySet()));
        Integer dmls = Limits.getDmlStatements();
        Integer soqls = Limits.getQueries();
        Test.stopTest();

        System.assertEquals(1, dmls, 'Um unico DML para o lote inteiro');
        System.assertEquals(1, soqls, 'Uma unica SOQL para o lote inteiro');
        Set<Id> idsFilas = new Set<Id>(filas.values());
        Integer distribuidos = 0;
        for (Lead l : [SELECT OwnerId FROM Lead WHERE Id IN :leads]) {
            if (idsFilas.contains(l.OwnerId)) {
                distribuidos++;
            }
        }
        System.assertEquals(200, distribuidos, 'Os 200 Leads devem ter fila como dono');
    }

    @IsTest
    static void listaVaziaOuNulaNaoFazNada() {
        Test.startTest();
        LeadAssignmentService.aplicarRegraPadrao(null);
        LeadAssignmentService.aplicarRegraPadrao(new List<Id>());
        Test.stopTest();

        System.assertEquals(0, Limits.getDmlStatements(), 'Sem Ids nao ha DML');
        System.assertEquals(0, Limits.getQueries(), 'Sem Ids nao ha SOQL');
    }

    @IsTest
    static void leadInexistenteEIgnorado() {
        Lead l = new Lead(LastName = 'Apagado', Company = 'Sintetica C', State = 'SP');
        insert l;
        Id idApagado = l.Id;
        delete l;

        Test.startTest();
        LeadAssignmentService.aplicarRegraPadrao(new List<Id>{ idApagado });
        System.assertEquals(0, Limits.getDmlStatements(), 'Lead inexistente nao gera DML');
        System.assertEquals(1, Limits.getQueries(), 'Apenas a consulta de filtro');
        Test.stopTest();
    }

    // O caminho assincrono do Flow nao executa dentro de teste Apex (testado: o Lead criado
    // por usuario com o PS seguiu com o dono original). A entrega do Flow e provada na sandbox
    // pela verificacao. Aqui fica provado o que e determinista: quem tem a custom permission
    // (condicao de entrada do Flow) e quem nao tem.
    @IsTest
    static void customPermissionLigadaSoParaUsuarioComPermissionSet() {
        User comPs = usuarioIntegracao(true);
        User semPs = usuarioIntegracao(false);

        Boolean temComPs;
        Boolean temSemPs;
        System.runAs(comPs) {
            temComPs = FeatureManagement.checkPermission('Lead_DistribuicaoAutomaticaViaApi');
        }
        System.runAs(semPs) {
            temSemPs = FeatureManagement.checkPermission('Lead_DistribuicaoAutomaticaViaApi');
        }

        System.assertEquals(true, temComPs, 'O PS liga a custom permission que o Flow exige');
        System.assertEquals(false, temSemPs, 'Sem o PS a custom permission fica desligada');
    }

    @IsTest
    static void permissionSetDaIntegracaoDaAcessoAClasse() {
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'PS_Integracao_DistribuicaoLead' LIMIT 1];
        Integer acessoClasse = [
            SELECT COUNT() FROM SetupEntityAccess
            WHERE ParentId = :ps.Id
            AND SetupEntityId IN (SELECT Id FROM ApexClass WHERE Name = 'LeadAssignmentService')
        ];
        System.assertEquals(1, acessoClasse, 'O PS deve dar acesso a LeadAssignmentService');
    }
}