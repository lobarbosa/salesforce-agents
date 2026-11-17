// Fixture EPLAST-35 (rodada 3). Dado SINTETICO para exercitar o Flow Lead_AfterSave_DistribuiDonoRodizio na dev (sbx-eplast-dev).
// NAO EXECUTADO pelo builder: escrito junto do build, o verificador roda e corrige o que a org recusar.
// Mude 'acao' abaixo: 'preparar' (contas, membros de fila, sem Leads), 'leads' (lote de Leads de teste), 'limpar'.
// Cria (preparar): 3 contas TESTE EPLAST-35 com CNPJ sintetico (A: 99000000000001 so digitos; B: 99.000.000/0002-00 com mascara;
//   C e D: mesmo CNPJ, donos diferentes), via TriggerUtility.bypassTrigger (sem Protheus/BrasilAPI), dono = usuario de teste do CLAUDE.md;
//   e membros diretos em Leads_MG (usuario de teste + 1o outro usuario ativo Standard).
// Exige: Leads_RJ_ES, DIST_SequenciaRodizio__c e o Flow implantados; DistribuicaoAtiva__c ligado so para a verificacao (passo de Setup).
// Telefones vazios (VRs Celular e Telefone). Proprietario de conta exige ProtheusSellerId__c? Conta nao; Oportunidade sim (nao usada aqui).
// Limpar: acao='limpar' apaga Leads/Contas 'TESTE EPLAST-35' e os GroupMember que este script criou (DurableId nao e guardado: removemos so
//   os membros de Leads_MG cujo UserOrGroupId esta no conjunto dos 2 usuarios escolhidos E que NAO existiam antes -> registre antes com a query abaixo).
// Rodar: sf apex run --target-org sbx-eplast-dev -f fixtures/lead_rodizio_dono_conta.apex
String acao = 'preparar';
String TAG = 'TESTE EPLAST-35';
Id teste = [SELECT Id FROM User WHERE Username LIKE 'projetos@konectabr.com%' AND IsActive = true LIMIT 1].Id;
Id outro = [SELECT Id FROM User WHERE IsActive = true AND UserType = 'Standard' AND Id != :teste AND Profile.Name LIKE 'Comercial%' ORDER BY Id LIMIT 1].Id;
Id filaMG = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'Leads_MG' LIMIT 1].Id;
if (acao == 'preparar') {
  TriggerUtility.bypassTrigger = true;
  List<Account> cs = new List<Account>();
  for (String[] p : new List<String[]>{
      new String[]{'A','99000000000001'}, new String[]{'B','99.000.000/0002-00'},
      new String[]{'C','99000000000003'}, new String[]{'D','99000000000003'}}) {
    cs.add(new Account(Name=TAG+' '+p[0], CompanyDocument__c=p[1], OwnerId=(p[0]=='D' ? outro : teste),
      BillingState='SP', BillingCity='Cidade Teste', BillingStreet='Rua Teste 1', BillingPostalCode='01000000',
      BillingNeighborhood__c='Bairro Teste', CNAE__c='0000000', CompanyName__c=TAG+' Ltda',
      Email__c='teste35@example.invalid', Phone='(11)30000000', Store__c='01'));
  }
  insert cs;
  insert new List<GroupMember>{ new GroupMember(GroupId=filaMG, UserOrGroupId=teste), new GroupMember(GroupId=filaMG, UserOrGroupId=outro) };
  System.debug('PREPARAR_OK contas='+cs.size()+' teste='+teste+' outro='+outro);
} else if (acao == 'leads') {
  List<Lead> ls = new List<Lead>();
  for (Integer i = 0; i < 4; i++) ls.add(new Lead(LastName=TAG+' MG '+i, Company=TAG, State='MG', Status='Aberto - Não contatado'));
  ls.add(new Lead(LastName=TAG+' CNPJ A mascara (conta A so digitos)', Company=TAG, State='RS', CompanyDocument__c='99.000.000/0001-00', Status='Aberto - Não contatado'));
  ls.add(new Lead(LastName=TAG+' CNPJ B mascara', Company=TAG, State='RS', CompanyDocument__c='99.000.000/0002-00', Status='Aberto - Não contatado'));
  ls.add(new Lead(LastName=TAG+' CNPJ duplicado', Company=TAG, State='MG', CompanyDocument__c='99000000000003', Status='Aberto - Não contatado'));
  Database.DMLOptions o = new Database.DMLOptions();
  o.assignmentRuleHeader.useDefaultRule = true; // equivale a caixa marcada na tela
  Database.insert(ls, o);
  System.debug('LEADS_OK '+ls.size());
} else if (acao == 'limpar') {
  delete [SELECT Id FROM Lead WHERE Company = :TAG];
  TriggerUtility.bypassTrigger = true;
  delete [SELECT Id FROM Account WHERE Name LIKE 'TESTE EPLAST-35%'];
  delete [SELECT Id FROM GroupMember WHERE GroupId = :filaMG AND UserOrGroupId IN (:teste, :outro)];
  System.debug('LIMPAR_OK');
}
