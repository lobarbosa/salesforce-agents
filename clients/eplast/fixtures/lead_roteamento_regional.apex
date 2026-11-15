// EPLAST-38 - dado de teste do roteamento regional de Lead.
// Executar com: sf apex run --file fixtures/lead_roteamento_regional.apex --target-org sbx-eplast-dev
// Todos os registros levam o prefixo EPLAST38-TESTE- (LastName), sinteticos, sem dado pessoal.
// Phone e MobilePhone ficam vazios por causa das validation rules Celular e Telefone.
//
// MODO (editar antes de rodar):
//   'REGRA'   : insere um Lead por UF da tabela do design (3.1), mais 'sp', vazio e 'Sao Paulo' por extenso,
//               com assignmentRuleHeader.useDefaultRule = true (caminhos A e D).
//   'SIMPLES' : insert sem cabecalho; o usuario de execucao precisa do permission set
//               PS_Integracao_DistribuicaoLead (caminho C, assincrono: esperar antes de consultar OwnerId).
//   'MASSA_REGRA' / 'MASSA_SIMPLES' : 200 Leads em UFs de regioes diferentes (CA-06), pelo caminho A/D ou C.
//   'MANTER_DONO' : insert com OwnerId do usuario de execucao e sem cabecalho (CA-04, ramo sem regra).
//   'LIMPAR'  : apaga so Leads com LastName iniciado por EPLAST38-TESTE-.
String MODO = 'REGRA';

String PREFIXO = 'EPLAST38-TESTE-';

List<String> ufs = new List<String>{
    'SP','RJ','MG','ES','PR','SC','RS','GO','DF','MT','MS','TO',
    'AC','AP','AM','PA','RO','RR','AL','BA','CE','MA','PB','PE','PI','RN','SE'
};

Lead novo(String sufixo, String uf, Integer i) {
    return new Lead(
        LastName = PREFIXO + sufixo + '-' + i,
        Company = 'Empresa Ficticia EPLAST38 ' + i,
        State = uf,
        Status = 'Aberto - Não contatado',
        LeadSource = 'Evento',
        Sector__c = 'Alimentos'
    );
}

if (MODO == 'LIMPAR') {
    List<Lead> apagar = [SELECT Id FROM Lead WHERE LastName LIKE 'EPLAST38-TESTE-%' LIMIT 10000];
    delete apagar;
    System.debug('Apagados: ' + apagar.size());
} else {
    List<Lead> leads = new List<Lead>();
    Boolean usaRegra = (MODO == 'REGRA' || MODO == 'MASSA_REGRA');
    if (MODO == 'REGRA' || MODO == 'SIMPLES') {
        Integer i = 0;
        for (String uf : ufs) { leads.add(novo('UF', uf, i++)); }
        leads.add(novo('MINUSC', 'sp', i++));      // esperado Leads_SP
        leads.add(novo('VAZIO', null, i++));       // esperado Leads_Triagem
        leads.add(novo('EXTENSO', 'São Paulo', i++)); // esperado Leads_Triagem
    } else if (MODO == 'MASSA_REGRA' || MODO == 'MASSA_SIMPLES') {
        for (Integer i = 0; i < 200; i++) { leads.add(novo('MASSA', ufs[Math.mod(i, ufs.size())], i)); }
    } else if (MODO == 'MANTER_DONO') {
        Lead l = novo('DONO', 'SP', 0);
        l.OwnerId = UserInfo.getUserId();
        leads.add(l);
    }
    Database.DMLOptions opt = new Database.DMLOptions();
    opt.assignmentRuleHeader.useDefaultRule = usaRegra;
    opt.optAllOrNone = false;
    List<Database.SaveResult> res = Database.insert(leads, opt);
    Integer ok = 0;
    for (Database.SaveResult r : res) { if (r.isSuccess()) { ok++; } else { System.debug('Falha: ' + r.getErrors()); } }
    System.debug('Modo ' + MODO + ': inseridos ' + ok + ' de ' + leads.size());
}
