// Fixture EPLAST-35 (rodada 3). Dado SINTETICO para exercitar o Flow Lead_AfterSave_DistribuiDonoRodizio na dev (sbx-eplast-dev).
// Executado e corrigido na verificacao (17/11): DML de Account e GroupMember nao cabem na mesma transacao (MIXED_DML), por isso as acoes 'filas' e 'limparfilas' sao separadas.
// Mude 'acao' abaixo: 'preparar' (so contas), 'filas' (membros de fila), 'leads' (Leads de teste), 'limpar' (Leads e contas), 'limparfilas' (membros).
// Cada acao em uma execucao separada.
// Cria (preparar): 3 contas TESTE EPLAST-35 com CNPJ sintetico (A: 99000000000100 so digitos (= 99.000.000/0001-00 do Lead); B: 99.000.000/0002-00 com mascara;
//   C e D: mesmo CNPJ, donos diferentes), via TriggerUtility.bypassTrigger (sem Protheus/BrasilAPI), dono = usuario de teste do CLAUDE.md;
//   (conta com dono inativo NAO da: INACTIVE_OWNER_OR_USER, T9 nao e exercitavel por insert); acao 'filas': membros em Leads_MG/SP/RJ_ES (teste+outro), Leads_Sul (teste+outro+terceiro), Leads_CO (so o inativo).
// Exige: Leads_RJ_ES, DIST_SequenciaRodizio__c e o Flow implantados; DistribuicaoAtiva__c ligado so para a verificacao (passo de Setup).
// Telefones vazios (VRs Celular e Telefone). Proprietario de conta exige ProtheusSellerId__c? Conta nao; Oportunidade sim (nao usada aqui).
// Limpar: acao='limpar' apaga Leads/Contas 'TESTE EPLAST-35' e os GroupMember que este script criou (DurableId nao e guardado: removemos so
//   os membros de Leads_MG cujo UserOrGroupId esta no conjunto dos 2 usuarios escolhidos E que NAO existiam antes -> registre antes com a query abaixo).
// Rodar: sf apex run --target-org sbx-eplast-dev -f fixtures/lead_rodizio_dono_conta.apex
String acao = 'preparar';
String TAG = 'TESTE EPLAST-35';
Id teste = [SELECT Id FROM User WHERE Username LIKE 'projetos@konectabr.com%' AND IsActive = true LIMIT 1].Id;
Id outro = [SELECT Id FROM User WHERE IsActive = true AND UserType = 'Standard' AND Id != :teste AND Profile.Name LIKE 'Comercial%' ORDER BY Id LIMIT 1].Id;
Id inativo = [SELECT Id FROM User WHERE IsActive = false AND UserType = 'Standard' AND Username LIKE 'projetos@konectabr.com%' LIMIT 1].Id;
Id terceiro = [SELECT Id FROM User WHERE IsActive = true AND UserType = 'Standard' AND Id NOT IN (:teste, :outro) AND Profile.Name LIKE 'Comercial%' ORDER BY Id LIMIT 1].Id;
Id filaMG = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'Leads_MG' LIMIT 1].Id;
if (acao == 'preparar') {
  TriggerUtility.bypassTrigger = true;
  List<Account> cs = new List<Account>();
  for (String[] p : new List<String[]>{
      new String[]{'A','99000000000100'}, new String[]{'B','99.000.000/0002-00'},
      new String[]{'C','99000000000003'}, new String[]{'D','99000000000003'}}) {
    cs.add(new Account(Name=TAG+' '+p[0], CompanyDocument__c=p[1], OwnerId=(p[0]=='D' ? outro : (p[0]=='E' ? inativo : teste)),
      BillingState='SP', BillingCity='Cidade Teste', BillingStreet='Rua Teste 1', BillingPostalCode='01000000',
      BillingNeighborhood__c='Bairro Teste', CNAE__c='0000000', CompanyName__c=TAG+' Ltda',
      Email__c='teste35@example.invalid', Phone='(11)30000000', Store__c='01'));
  }
  insert cs;
  System.debug('PREPARAR_OK contas='+cs.size()+' teste='+teste+' outro='+outro);
} else if (acao == 'filas') {
  Map<String,Id> fq = new Map<String,Id>();
  for (Group g : [SELECT Id, DeveloperName FROM Group WHERE Type='Queue' AND DeveloperName IN ('Leads_MG','Leads_SP','Leads_RJ_ES','Leads_Sul','Leads_CO')]) fq.put(g.DeveloperName, g.Id);
  List<GroupMember> gm = new List<GroupMember>();
  for (String q : new List<String>{'Leads_MG','Leads_SP','Leads_RJ_ES'}) { gm.add(new GroupMember(GroupId=fq.get(q), UserOrGroupId=teste)); gm.add(new GroupMember(GroupId=fq.get(q), UserOrGroupId=outro)); }
  for (Id u : new List<Id>{teste, outro, terceiro}) gm.add(new GroupMember(GroupId=fq.get('Leads_Sul'), UserOrGroupId=u));
  gm.add(new GroupMember(GroupId=fq.get('Leads_CO'), UserOrGroupId=inativo)); // so inativo: T11
  insert gm;
  System.debug('FILAS_OK');
} else if (acao == 'leads') {
  List<Lead> ls = new List<Lead>();
  for (Integer i = 0; i < 4; i++) ls.add(new Lead(LastName=TAG+' MG '+i, Company=TAG, State='MG', Status='Aberto - Não contatado'));
  ls.add(new Lead(LastName=TAG+' CNPJ A mascara (conta A so digitos)', Company=TAG, State='RS', CompanyDocument__c='99.000.000/0001-00', Status='Aberto - Não contatado'));
  ls.add(new Lead(LastName=TAG+' CNPJ B mascara', Company=TAG, State='RS', CompanyDocument__c='99.000.000/0002-00', Status='Aberto - Não contatado'));
  ls.add(new Lead(LastName=TAG+' CNPJ B digitos (conta B com mascara)', Company=TAG, State='RS', CompanyDocument__c='99000000000200', Status='Aberto - Não contatado'));
  ls.add(new Lead(LastName=TAG+' CNPJ duplicado', Company=TAG, State='MG', CompanyDocument__c='99000000000003', Status='Aberto - Não contatado'));
  Database.DMLOptions o = new Database.DMLOptions();
  o.assignmentRuleHeader.useDefaultRule = true; // equivale a caixa marcada na tela
  Database.insert(ls, o);
  System.debug('LEADS_OK '+ls.size());
} else if (acao == 'limpar') {
  delete [SELECT Id FROM Lead WHERE Company = :TAG];
  TriggerUtility.bypassTrigger = true;
  delete [SELECT Id FROM Account WHERE Name LIKE 'TESTE EPLAST-35%'];
  System.debug('LIMPAR_OK');
} else if (acao == 'limparfilas') {
  delete [SELECT Id FROM GroupMember WHERE Group.Type='Queue' AND Group.DeveloperName IN ('Leads_MG','Leads_SP','Leads_RJ_ES','Leads_Sul','Leads_CO') AND UserOrGroupId IN (:teste, :outro, :terceiro, :inativo)];
  System.debug('LIMPARFILAS_OK');
}
