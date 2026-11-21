@IsTest
private class CentralComercialV1ControllerTest {
  private static String ticketWonStage;
  @TestSetup
  static void setupData() {
    // Same trigger bypass used by FlowOpportunityControllerTest; no org metadata is changed.
    TriggerUtility.bypassTrigger = true;
    update new User(Id = UserInfo.getUserId(), ProtheusSellerId__c = 'CCV001');
    Id commercialProfile = [
      SELECT Id
      FROM Profile
      WHERE Name = 'Comercial - Analista'
      LIMIT 1
    ]
    .Id;
    Id minimumProfile = [
      SELECT Id
      FROM Profile
      WHERE Name = 'Minimum Access - Salesforce'
      LIMIT 1
    ]
    .Id;
    List<User> sellers = new List<User>{
      makeUser('ccscore', commercialProfile),
      makeUser('ccplain', minimumProfile)
    };
    insert sellers;
    Id scorePermission = [
      SELECT Id
      FROM PermissionSet
      WHERE Name = 'PS_Comercial_ScorePrioridade'
      LIMIT 1
    ]
    .Id;
    List<PermissionSetAssignment> assignments = new List<PermissionSetAssignment>{
      new PermissionSetAssignment(
        AssigneeId = sellers[0].Id,
        PermissionSetId = scorePermission
      )
    };
    if (
      [
        SELECT COUNT()
        FROM PermissionSetAssignment
        WHERE
          AssigneeId = :UserInfo.getUserId()
          AND PermissionSetId = :scorePermission
      ] == 0
    ) {
      assignments.add(
        new PermissionSetAssignment(
          AssigneeId = UserInfo.getUserId(),
          PermissionSetId = scorePermission
        )
      );
    }
    insert assignments;
    // runAs isolates mixed setup/business DML. Everything rolls back with the test.
    System.runAs(new User(Id = UserInfo.getUserId())) {
      insert new List<Account>{
        account('CC Alfa', UserInfo.getUserId()),
        account('CC Beta', sellers[0].Id)
      };
    }
  }

  @IsTest
  static void agendaSeparatesThreeWindowsAndCountsBeyondTheRowLimit() {
    Account chosen = [SELECT Id FROM Account WHERE Name = 'CC Alfa' LIMIT 1];
    Account other = [SELECT Id FROM Account WHERE Name = 'CC Beta' LIMIT 1];
    String openStatus = [
      SELECT ApiName
      FROM TaskStatus
      WHERE IsClosed = FALSE
      ORDER BY SortOrder
      LIMIT 1
    ]
    .ApiName;
    String closedStatus = [
      SELECT ApiName
      FROM TaskStatus
      WHERE IsClosed = TRUE
      ORDER BY SortOrder
      LIMIT 1
    ]
    .ApiName;
    Date today = Date.today();
    // Account automation creates a real welcome task due today; retain it in the fixture.
    Integer initialToday = [
      SELECT COUNT()
      FROM Task
      WHERE
        AccountId = :chosen.Id
        AND IsClosed = FALSE
        AND ActivityDate = :today
    ];
    List<Task> tasks = new List<Task>();
    for (Integer i = 0; i < 21; i++) {
      tasks.add(
        new Task(
          WhatId = chosen.Id,
          Subject = 'Vencida ' + i,
          Status = openStatus,
          ActivityDate = today.addDays(-1)
        )
      );
    }
    tasks.add(
      new Task(
        WhatId = chosen.Id,
        Subject = 'Hoje',
        Status = openStatus,
        ActivityDate = today
      )
    );
    tasks.add(
      new Task(
        WhatId = chosen.Id,
        Subject = 'Dia sete',
        Status = openStatus,
        ActivityDate = today.addDays(7)
      )
    );
    tasks.add(
      new Task(
        WhatId = chosen.Id,
        Subject = 'Dia oito',
        Status = openStatus,
        ActivityDate = today.addDays(8)
      )
    );
    tasks.add(
      new Task(
        WhatId = chosen.Id,
        Subject = 'Concluída',
        Status = closedStatus,
        ActivityDate = today
      )
    );
    tasks.add(
      new Task(WhatId = chosen.Id, Subject = 'Sem prazo', Status = openStatus)
    );
    tasks.add(
      new Task(
        WhatId = other.Id,
        Subject = 'Outra conta',
        Status = openStatus,
        ActivityDate = today
      )
    );
    insert tasks;
    Test.startTest();
    Map<String, Object> overview = overview('2025-01', true, null, chosen.Id);
    Test.stopTest();
    Map<String, Object> overdue = block(overview, 'agenda');
    Assert.isNull(overdue.get('error'));
    Assert.areEqual(21, overdue.get('total'));
    Assert.areEqual(20, rows(overdue).size());
    Assert.areEqual(
      initialToday + 1,
      block(overview, 'todayTasks').get('total')
    );
    Set<String> todayLabels = new Set<String>();
    for (Object value : rows(block(overview, 'todayTasks')))
      todayLabels.add((String) ((Map<String, Object>) value).get('label'));
    Assert.isTrue(todayLabels.contains('Hoje'));
    Assert.areEqual(1, block(overview, 'upcoming').get('total'));
    Assert.areEqual(
      'Dia sete',
      row(block(overview, 'upcoming'), 0).get('label')
    );
  }

  @IsTest
  static void pipelineUsesMonthBoundariesAndDetailKeepsAccountScope() {
    TriggerUtility.bypassTrigger = true;
    Account chosen = [SELECT Id FROM Account WHERE Name = 'CC Alfa' LIMIT 1];
    Account other = [SELECT Id FROM Account WHERE Name = 'CC Beta' LIMIT 1];
    insert new List<Opportunity>{
      opportunity('Início', chosen.Id, Date.newInstance(2025, 1, 1)),
      opportunity('Fim', chosen.Id, Date.newInstance(2025, 1, 31)),
      opportunity('Próximo mês', chosen.Id, Date.newInstance(2025, 2, 1)),
      opportunity('Outra carteira', other.Id, Date.newInstance(2025, 1, 1))
    };
    insert new List<Contact>{
      new Contact(LastName = 'Contato Alfa', AccountId = chosen.Id),
      new Contact(LastName = 'Contato Beta', AccountId = other.Id)
    };
    Test.startTest();
    Map<String, Object> january = overview('2025-01', false, null, chosen.Id);
    Map<String, Object> february = overview('2025-02', false, null, chosen.Id);
    Map<String, Object> detail = parsed(
      CentralComercialV1Controller.getAccountDetail(chosen.Id)
    );
    Test.stopTest();
    Assert.isNull(block(january, 'pipeline').get('error'));
    Assert.areEqual(2, block(january, 'pipeline').get('total'));
    Assert.areEqual(1, block(february, 'pipeline').get('total'));
    Assert.areEqual('2025-01-31', january.get('monthEnd'));
    Assert.areEqual(
      block(january, 'overdue').get('total'),
      block(february, 'overdue').get('total')
    );
    Assert.areEqual(3, rows(block(detail, 'opportunities')).size());
    Assert.areEqual(1, rows(block(detail, 'contacts')).size());
    Assert.areEqual(
      'Contato Alfa',
      row(block(detail, 'contacts'), 0).get('label')
    );
  }

  @IsTest
  static void leadsUseRealScoreAndExcludeClosedAndConvertedWithoutAccountFilters() {
    TriggerUtility.bypassTrigger = true;
    Account chosen = [SELECT Id FROM Account WHERE Name = 'CC Alfa' LIMIT 1];
    String sector = firstActive(Lead.Sector__c);
    String source = firstActive(Lead.LeadSource);
    List<Lead> leads = new List<Lead>{
      new Lead(
        LastName = 'CC Alta',
        Company = 'Teste',
        MKT_MC_Engajamento__c = 'Alto',
        Status = 'Contatado',
        Sector__c = sector,
        LeadSource = source
      ),
      new Lead(
        LastName = 'CC Baixa',
        Company = 'Teste',
        MKT_MC_Engajamento__c = 'Baixo',
        Status = 'Aberto - Não contatado',
        Sector__c = sector
      ),
      new Lead(
        LastName = 'CC Encerrado',
        Company = 'Teste',
        Status = 'Fechado - Não convertido',
        Sector__c = sector,
        LeadSource = source
      )
    };
    for (Integer i = 0; i < 21; i++)
      leads.add(
        new Lead(
          LastName = 'CC Zero ' + i,
          Company = 'Teste',
          Status = 'Aberto - Não contatado'
        )
      );
    Lead converted = new Lead(
      LastName = 'CC Convertido',
      Company = 'Teste',
      Status = 'Contatado'
    );
    leads.add(converted);
    insert leads;
    Database.LeadConvert conversion = new Database.LeadConvert();
    conversion.setLeadId(converted.Id);
    conversion.setConvertedStatus(
      [SELECT ApiName FROM LeadStatus WHERE IsConverted = TRUE LIMIT 1].ApiName
    );
    conversion.setAccountId(chosen.Id);
    conversion.setDoNotCreateOpportunity(true);
    Assert.isTrue(Database.convertLead(conversion).isSuccess());
    Test.startTest();
    Map<String, Object> result = overview(
      '2025-01',
      false,
      'UF sem conta',
      chosen.Id
    );
    Test.stopTest();
    Map<String, Object> leadBlock = block(result, 'leads');
    Assert.isNull(leadBlock.get('error'));
    Assert.areEqual(
      23,
      leadBlock.get('total'),
      'Excluir convertidos e fechados não convertidos, sem aplicar UF ou conta a leads.'
    );
    Assert.areEqual(20, rows(leadBlock).size());
    Lead high = [
      SELECT PriorityScore__c, PriorityBand__c
      FROM Lead
      WHERE Id = :leads[0].Id
    ];
    Lead low = [SELECT PriorityScore__c FROM Lead WHERE Id = :leads[1].Id];
    Assert.areEqual(high.PriorityScore__c, row(leadBlock, 0).get('score'));
    Assert.areEqual(high.PriorityBand__c, row(leadBlock, 0).get('band'));
    Assert.areEqual(low.PriorityScore__c, row(leadBlock, 1).get('score'));
    Assert.areEqual(
      0,
      row(leadBlock, 2).get('score'),
      'A fórmula atual retorna zero quando o engajamento não está preenchido.'
    );
    Assert.areEqual('Não classificado', row(leadBlock, 2).get('band'));
  }

  @IsTest
  static void ordersUseCommercialDateInsteadOfEffectiveDate() {
    Account chosen = [SELECT Id FROM Account WHERE Name = 'CC Alfa' LIMIT 1];
    insert new List<Order>{
      new Order(
        AccountId = chosen.Id,
        Status = 'Revisao de Pedido',
        EffectiveDate = Date.newInstance(2025, 2, 1),
        ExpectedSaleDate__c = Date.newInstance(2025, 1, 31)
      ),
      new Order(
        AccountId = chosen.Id,
        Status = 'Revisao de Pedido',
        EffectiveDate = Date.newInstance(2025, 1, 1),
        ExpectedSaleDate__c = Date.newInstance(2025, 2, 1)
      ),
      new Order(
        AccountId = chosen.Id,
        Status = 'Revisao de Pedido',
        EffectiveDate = Date.newInstance(2025, 1, 1)
      )
    };
    Test.startTest();
    Map<String, Object> january = overview('2025-01', true, null, chosen.Id);
    Map<String, Object> february = overview('2025-02', true, null, chosen.Id);
    Test.stopTest();
    Assert.isNull(block(january, 'orders').get('error'));
    Assert.areEqual(1, block(january, 'orders').get('total'));
    Assert.areEqual(
      '2025-01-31',
      row(block(january, 'orders'), 0).get('relevantDate')
    );
    Assert.areEqual(
      'Revisao de Pedido',
      row(block(january, 'orders'), 0).get('status')
    );
    Assert.areEqual(1, block(february, 'orders').get('total'));
    Assert.areEqual('Order.ExpectedSaleDate__c', january.get('orderDateApi'));
  }

  @IsTest
  static void sellerScopeUsesAccountOwnerAndLeadFiltersAreIndependent() {
    TriggerUtility.bypassTrigger = true;
    User seller = [SELECT Id FROM User WHERE Alias = 'ccscore' LIMIT 1];
    Account chosen = [SELECT Id FROM Account WHERE Name = 'CC Beta' LIMIT 1];
    Opportunity opp = opportunity(
      'Dono da oportunidade diferente',
      chosen.Id,
      Date.newInstance(2025, 1, 15)
    );
    opp.OwnerId = UserInfo.getUserId();
    insert opp;
    insert new Lead(
      LastName = 'Lead do vendedor',
      Company = 'Teste',
      MKT_MC_Engajamento__c = 'Alto',
      OwnerId = seller.Id,
      Status = 'Contatado',
      Sector__c = firstActive(Lead.Sector__c),
      LeadSource = firstActive(Lead.LeadSource)
    );
    Map<String, Object> result;
    System.runAs(seller) {
      Test.startTest();
      result = parsed(
        CentralComercialV1Controller.getOverview(
          '2025-01',
          true,
          null,
          null,
          null,
          true,
          seller.Id,
          'Contatado',
          null
        )
      );
      Test.stopTest();
    }
    Assert.isNull(block(result, 'pipeline').get('error'));
    Assert.areEqual(
      1,
      block(result, 'pipeline').get('total'),
      'A carteira usa o dono da conta, não o dono da oportunidade.'
    );
    Assert.areEqual(1, block(result, 'leads').get('total'));
    Assert.areEqual(
      [
        SELECT PriorityScore__c
        FROM Lead
        WHERE LastName = 'Lead do vendedor'
        LIMIT 1
      ]
      .PriorityScore__c,
      row(block(result, 'leads'), 0).get('score')
    );
    Assert.areEqual(
      'available',
      ((Map<String, Object>) block(result, 'leads').get('fieldStates'))
        .get('score')
    );
  }

  @IsTest
  static void inaccessibleObjectIsNeverReportedAsEmptyOrZero() {
    User seller = [SELECT Id FROM User WHERE Alias = 'ccplain' LIMIT 1];
    Map<String, Object> result;
    System.runAs(seller) {
      Assert.isFalse(
        Lead.SObjectType.getDescribe().isAccessible(),
        'Usuário de teste com perfil de acesso mínimo.'
      );
      Test.startTest();
      result = parsed(
        CentralComercialV1Controller.getOverview(
          null,
          false,
          null,
          null,
          null,
          true,
          null,
          null,
          null
        )
      );
      Test.stopTest();
    }
    Map<String, Object> leadBlock = block(result, 'leads');
    Assert.isNotNull(leadBlock.get('error'));
    Assert.isNull(leadBlock.get('total'));
    Assert.areEqual('no_access', leadBlock.get('errorCode'));
    Assert.areEqual(0, rows(leadBlock).size());
    Map<String, Object> sectorFilter = (Map<String, Object>) result.get(
      'accountSectorFilter'
    );
    Assert.areEqual('no_access', sectorFilter.get('state'));
    Assert.areEqual(0, ((List<Object>) sectorFilter.get('options')).size());
  }

  @IsTest
  static void invalidInputsAreRejectedAndEmptySelectionIsZero() {
    Account chosen = [SELECT Id FROM Account WHERE Name = 'CC Alfa' LIMIT 1];
    Test.startTest();
    for (
      String month : new List<String>{
        '2025-13',
        '1999-12',
        '2025-01 OR Name != null'
      }
    ) {
      try {
        overview(month, false, null, null);
        Assert.fail('Mês inválido deve falhar.');
      } catch (AuraHandledException expected) {
      }
    }
    try {
      overview(null, false, null, UserInfo.getUserId());
      Assert.fail('ID de conta inválido deve falhar.');
    } catch (AuraHandledException expected) {
    }
    try {
      CentralComercialV1Controller.getAccountDetail(null);
      Assert.fail('Conta obrigatória.');
    } catch (AuraHandledException expected) {
    }
    try {
      CentralComercialV1Controller.getOverview(
        null,
        false,
        null,
        null,
        chosen.Id,
        false,
        null,
        null,
        null
      );
      Assert.fail('ID do vendedor inválido.');
    } catch (AuraHandledException expected) {
    }
    try {
      CentralComercialV1Controller.getOverview(
        null,
        false,
        null,
        null,
        null,
        false,
        null,
        'Fechado - Não convertido',
        null
      );
      Assert.fail('Status inelegível.');
    } catch (AuraHandledException expected) {
    }
    try {
      CentralComercialV1Controller.getOverview(
        null,
        false,
        null,
        null,
        null,
        false,
        null,
        null,
        'Setor inexistente'
      );
      Assert.fail('Setor fora dos metadados deve ser rejeitado.');
    } catch (AuraHandledException expected) {
    }
    Map<String, Object> empty = overview(
      '2025-01',
      false,
      'UF inexistente',
      chosen.Id
    );
    Test.stopTest();
    Assert.areEqual(0, block(empty, 'pipeline').get('total'));
    Assert.isNull(block(empty, 'pipeline').get('error'));
  }

  @IsTest
  static void accountSectorFiltersAllAccountBlocksButNeverLeads() {
    TriggerUtility.bypassTrigger = true;
    Account chosen = [
      SELECT Id, Sector__c
      FROM Account
      WHERE Name = 'CC Alfa'
      LIMIT 1
    ];
    Account other = [
      SELECT Id, Sector__c
      FROM Account
      WHERE Name = 'CC Beta'
      LIMIT 1
    ];
    List<String> sectors = new List<String>();
    for (
      Schema.PicklistEntry entry : Account.Sector__c.getDescribe()
        .getPicklistValues()
    ) {
      if (entry.isActive())
        sectors.add(entry.getValue());
    }
    Assert.isTrue(
      sectors.size() >= 2,
      'Metadados confirmados têm vários setores ativos.'
    );
    chosen.Sector__c = sectors[0];
    other.Sector__c = sectors[1];
    update new List<Account>{ chosen, other };
    insert account('CC Sem setor', UserInfo.getUserId());
    Date commercialDate = Date.newInstance(Date.today().year() - 1, 1, 15);
    String monthKey = String.valueOf(commercialDate).substring(0, 7);
    insert new List<Opportunity>{
      opportunity('Setor A', chosen.Id, commercialDate),
      opportunity('Setor B', other.Id, commercialDate)
    };
    String openStatus = [
      SELECT ApiName
      FROM TaskStatus
      WHERE IsClosed = FALSE
      ORDER BY SortOrder
      LIMIT 1
    ]
    .ApiName;
    List<Task> tasks = new List<Task>();
    for (Id relatedAccount : new List<Id>{ chosen.Id, other.Id }) {
      for (Integer offset : new List<Integer>{ -1, 0, 7 })
        tasks.add(
          new Task(
            WhatId = relatedAccount,
            Subject = 'Agenda por setor',
            Status = openStatus,
            ActivityDate = Date.today().addDays(offset)
          )
        );
    }
    insert tasks;
    insert new List<Order>{
      new Order(
        AccountId = chosen.Id,
        Status = 'Revisao de Pedido',
        EffectiveDate = Date.today(),
        ExpectedSaleDate__c = commercialDate
      ),
      new Order(
        AccountId = other.Id,
        Status = 'Revisao de Pedido',
        EffectiveDate = Date.today(),
        ExpectedSaleDate__c = commercialDate
      )
    };
    insert new Lead(
      LastName = 'Lead independente do setor da conta',
      Company = 'Teste',
      Status = 'Contatado'
    );
    Test.startTest();
    Map<String, Object> allSectors = overview(monthKey, false, null, null);
    Map<String, Object> selectedSector = parsed(
      CentralComercialV1Controller.getOverview(
        monthKey,
        false,
        null,
        null,
        null,
        false,
        null,
        null,
        sectors[0]
      )
    );
    Map<String, Object> clearedSector = overview(monthKey, false, null, null);
    Test.stopTest();
    Assert.areEqual(2, block(allSectors, 'pipeline').get('total'));
    for (
      String key : new List<String>{
        'agenda',
        'upcoming',
        'pipeline',
        'overdue',
        'orders'
      }
    ) {
      Assert.isNull(block(selectedSector, key).get('error'), key);
      Assert.areEqual(1, block(selectedSector, key).get('total'), key);
    }
    for (
      String key : new List<String>{
        'agenda',
        'todayTasks',
        'upcoming',
        'pipeline',
        'overdue',
        'orders'
      }
    ) {
      Assert.isNull(block(selectedSector, key).get('error'), key);
      for (Object value : rows(block(selectedSector, key)))
        Assert.areEqual(
          String.valueOf(chosen.Id),
          ((Map<String, Object>) value).get('accountId'),
          key
        );
    }
    Assert.areEqual(1, block(selectedSector, 'leads').get('total'));
    Assert.areEqual(
      block(allSectors, 'leads').get('total'),
      block(selectedSector, 'leads').get('total')
    );
    Assert.areEqual(2, block(clearedSector, 'pipeline').get('total'));
    Map<String, Object> filter = (Map<String, Object>) selectedSector.get(
      'accountSectorFilter'
    );
    Assert.areEqual('available', filter.get('state'));
    Set<String> returnedValues = new Set<String>();
    for (Object value : (List<Object>) filter.get('options'))
      returnedValues.add((String) ((Map<String, Object>) value).get('value'));
    Assert.areEqual(
      new Set<String>(sectors),
      returnedValues,
      'As opções vêm dos metadados ativos, sem valores inventados.'
    );
  }

  @IsTest
  static void directoryPaginationKeepsFullCountWithDuplicateNames() {
    TriggerUtility.bypassTrigger = true;
    String sector = firstActive(Account.Sector__c);
    List<Account> accounts = new List<Account>();
    for (Integer i = 0; i < 23; i++) {
      Account item = account('CC Página', UserInfo.getUserId());
      if (Math.mod(i, 2) == 0)
        item.Sector__c = sector;
      accounts.add(item);
    }
    insert accounts;
    insert new List<Opportunity>{
      opportunity('Recorte primeira conta', accounts[0].Id, Date.today()),
      opportunity('Recorte última conta', accounts[22].Id, Date.today())
    };
    Test.startTest();
    Map<String, Object> first = parsed(
      CentralComercialV1Controller.getDirectory(
        'Account',
        false,
        'CC Página',
        null,
        null,
        null,
        null,
        null
      )
    );
    Map<String, Object> second = parsed(
      CentralComercialV1Controller.getDirectory(
        'Account',
        false,
        'CC Página',
        null,
        null,
        null,
        null,
        (String) first.get('nextCursor')
      )
    );
    Map<String, Object> filtered = parsed(
      CentralComercialV1Controller.getDirectory(
        'Account',
        false,
        'CC Página',
        'SP',
        sector,
        null,
        null,
        null
      )
    );
    Test.stopTest();
    Assert.areEqual(23, block(first, 'block').get('total'));
    Assert.areEqual(20, rows(block(first, 'block')).size());
    Assert.areEqual(
      23,
      block(second, 'block').get('total'),
      'Total continua sendo do recorte completo na segunda página.'
    );
    Assert.areEqual(3, rows(block(second, 'block')).size());
    Assert.isNull(second.get('nextCursor'));
    Set<String> ids = new Set<String>();
    for (Object value : rows(block(first, 'block')))
      ids.add((String) ((Map<String, Object>) value).get('id'));
    for (Object value : rows(block(second, 'block')))
      Assert.isTrue(
        ids.add((String) ((Map<String, Object>) value).get('id')),
        'Sem duplicação com nomes iguais.'
      );
    Assert.areEqual(23, ids.size());
    Assert.areEqual(12, block(filtered, 'block').get('total'));
    Map<String, Object> segment = parsed(
      CentralComercialV1Controller.getSegmentRelatedRecords(
        JSON.serialize(
          new Map<String, Object>{
            'entityType' => 'Account',
            'mine' => false,
            'nameSearch' => 'CC Página'
          }
        ),
        'Opportunity',
        'all',
        null,
        'open',
        null
      )
    );
    Assert.isNull(block(segment, 'block').get('error'));
    Assert.areEqual(
      2,
      block(segment, 'block').get('total'),
      'Relacionados de todas as contas do recorte, inclusive além da primeira página.'
    );
    Set<String> relatedParents = new Set<String>();
    for (Object value : rows(block(segment, 'block')))
      relatedParents.add(
        (String) ((Map<String, Object>) value).get('parentId')
      );
    Assert.isTrue(relatedParents.contains(String.valueOf(accounts[22].Id)));
  }

  @IsTest
  static void leadDirectoryPaginatesScoreZeroAndIgnoresAccountDimensions() {
    List<Lead> leads = new List<Lead>();
    for (Integer i = 0; i < 22; i++)
      leads.add(
        new Lead(
          LastName = 'CC Lista Zero ' + i,
          Company = 'Teste',
          Status = 'Aberto - Não contatado'
        )
      );
    leads.add(
      new Lead(
        LastName = 'CC Lista Alta',
        Company = 'Teste',
        MKT_MC_Engajamento__c = 'Alto',
        Status = 'Contatado',
        Sector__c = firstActive(Lead.Sector__c),
        LeadSource = firstActive(Lead.LeadSource)
      )
    );
    leads.add(
      new Lead(
        LastName = 'CC Lista Encerrado',
        Company = 'Teste',
        Status = 'Fechado - Não convertido'
      )
    );
    insert leads;
    Test.startTest();
    String taskStatus = [
      SELECT ApiName
      FROM TaskStatus
      WHERE IsClosed = FALSE
      LIMIT 1
    ]
    .ApiName;
    insert new List<Task>{
      new Task(
        WhoId = leads[0].Id,
        Subject = 'Primeiro lead',
        Status = taskStatus
      ),
      new Task(
        WhoId = leads[21].Id,
        Subject = 'Lead além da primeira página',
        Status = taskStatus
      )
    };
    Map<String, Object> first = parsed(
      CentralComercialV1Controller.getDirectory(
        'Lead',
        false,
        'CC Lista',
        'UF inexistente',
        'Setor de conta ignorado',
        '__ACTIVE__',
        null,
        null
      )
    );
    Map<String, Object> second = parsed(
      CentralComercialV1Controller.getDirectory(
        'Lead',
        false,
        'CC Lista',
        null,
        null,
        '__ACTIVE__',
        null,
        (String) first.get('nextCursor')
      )
    );
    Map<String, Object> allUnconverted = parsed(
      CentralComercialV1Controller.getDirectory(
        'Lead',
        false,
        'CC Lista',
        null,
        null,
        null,
        null,
        null
      )
    );
    Test.stopTest();
    Assert.areEqual(23, block(first, 'block').get('total'));
    Assert.areEqual(
      [
        SELECT PriorityScore__c
        FROM Lead
        WHERE LastName = 'CC Lista Alta'
        LIMIT 1
      ]
      .PriorityScore__c,
      row(block(first, 'block'), 0).get('score')
    );
    Assert.areEqual(23, block(second, 'block').get('total'));
    Assert.areEqual(3, rows(block(second, 'block')).size());
    for (Object value : rows(block(second, 'block')))
      Assert.areEqual(0, ((Map<String, Object>) value).get('score'));
    Assert.areEqual(
      24,
      block(allUnconverted, 'block').get('total'),
      'Todos os não convertidos inclui fechado não convertido.'
    );
    Map<String, Object> segment = parsed(
      CentralComercialV1Controller.getSegmentRelatedRecords(
        JSON.serialize(
          new Map<String, Object>{
            'entityType' => 'Lead',
            'mine' => false,
            'nameSearch' => 'CC Lista',
            'leadStatus' => '__ACTIVE__'
          }
        ),
        'Task',
        'all',
        null,
        'open',
        null
      )
    );
    Assert.isNull(block(segment, 'block').get('error'));
    Assert.areEqual(2, block(segment, 'block').get('total'));
    Assert.isNotNull(
      row(block(segment, 'block'), 0).get('parentName'),
      'Nome do lead identifica a origem da tarefa no recorte.'
    );
  }

  @IsTest
  static void relatedRecordsUseParentAndOptionalBusinessDates() {
    TriggerUtility.bypassTrigger = true;
    Account chosen = [SELECT Id FROM Account WHERE Name = 'CC Alfa' LIMIT 1];
    Account other = [SELECT Id FROM Account WHERE Name = 'CC Beta' LIMIT 1];
    Date january = Date.newInstance(Date.today().year() - 1, 1, 15);
    Date february = january.addMonths(1);
    insert new List<Opportunity>{
      opportunity('Jan', chosen.Id, january),
      opportunity('Fev', chosen.Id, february),
      opportunity('Outra conta', other.Id, january)
    };
    insert new List<Order>{
      new Order(
        AccountId = chosen.Id,
        Status = 'Revisao de Pedido',
        EffectiveDate = february,
        ExpectedSaleDate__c = january
      ),
      new Order(
        AccountId = chosen.Id,
        Status = 'Revisao de Pedido',
        EffectiveDate = january,
        ExpectedSaleDate__c = february
      )
    };
    Contact person = new Contact(
      LastName = 'CC Contato',
      AccountId = chosen.Id
    );
    insert person;
    Lead lead = new Lead(
      LastName = 'CC Lead Tarefas',
      Company = 'Teste',
      Status = 'Contatado'
    );
    Lead otherLead = new Lead(
      LastName = 'CC Outro Lead',
      Company = 'Teste',
      Status = 'Contatado'
    );
    insert new List<Lead>{ lead, otherLead };
    String openStatus = [
      SELECT ApiName
      FROM TaskStatus
      WHERE IsClosed = FALSE
      LIMIT 1
    ]
    .ApiName;
    insert new List<Task>{
      new Task(
        WhoId = lead.Id,
        Subject = 'Lead passado',
        Status = openStatus,
        ActivityDate = january
      ),
      new Task(
        WhoId = lead.Id,
        Subject = 'Lead futuro',
        Status = openStatus,
        ActivityDate = Date.today().addDays(7)
      ),
      new Task(
        WhoId = otherLead.Id,
        Subject = 'Outro lead',
        Status = openStatus,
        ActivityDate = january
      )
    };
    String monthKey = String.valueOf(january).substring(0, 7);
    Test.startTest();
    Map<String, Object> opportunities = parsed(
      CentralComercialV1Controller.getRelatedRecords(
        chosen.Id,
        'Opportunity',
        'all',
        null,
        'open',
        null
      )
    );
    Map<String, Object> monthly = parsed(
      CentralComercialV1Controller.getRelatedRecords(
        chosen.Id,
        'Opportunity',
        'month',
        monthKey,
        'all',
        null
      )
    );
    Map<String, Object> orders = parsed(
      CentralComercialV1Controller.getRelatedRecords(
        chosen.Id,
        'Order',
        'month',
        monthKey,
        'Revisao de Pedido',
        null
      )
    );
    Map<String, Object> contacts = parsed(
      CentralComercialV1Controller.getRelatedRecords(
        chosen.Id,
        'Contact',
        null,
        null,
        null,
        null
      )
    );
    Map<String, Object> tasks = parsed(
      CentralComercialV1Controller.getRelatedRecords(
        lead.Id,
        'Task',
        'all',
        null,
        'open',
        null
      )
    );
    Map<String, Object> next7 = parsed(
      CentralComercialV1Controller.getRelatedRecords(
        lead.Id,
        'Task',
        'next7',
        null,
        'open',
        null
      )
    );
    Map<String, Object> closed = parsed(
      CentralComercialV1Controller.getRelatedRecords(
        lead.Id,
        'Task',
        'all',
        null,
        'closed',
        null
      )
    );
    Test.stopTest();
    Assert.areEqual(2, block(opportunities, 'block').get('total'));
    Map<String, Object> expired = parsed(
      CentralComercialV1Controller.getRelatedRecords(
        chosen.Id,
        'Opportunity',
        'overdue',
        null,
        'open',
        null
      )
    );
    Assert.areEqual(
      2,
      block(expired, 'block').get('total'),
      'Fechamento vencido continua separado da inatividade comercial.'
    );
    Assert.areEqual(1, block(monthly, 'block').get('total'));
    Assert.areEqual(1, block(orders, 'block').get('total'));
    Assert.areEqual(
      String.valueOf(january),
      row(block(orders, 'block'), 0).get('relevantDate')
    );
    Assert.areEqual(1, block(contacts, 'block').get('total'));
    Assert.areEqual(
      2,
      block(tasks, 'block').get('total'),
      'Tarefas do Lead sem AccountId são encontradas por WhoId.'
    );
    Assert.areEqual(1, block(next7, 'block').get('total'));
    Assert.areEqual('Lead futuro', row(block(next7, 'block'), 0).get('label'));
    Assert.areEqual(0, block(closed, 'block').get('total'));
  }

  @IsTest
  static void relatedTaskPaginationIncludesUndatedTasks() {
    Lead lead = new Lead(
      LastName = 'CC Sem prazo',
      Company = 'Teste',
      Status = 'Contatado'
    );
    insert lead;
    String openStatus = [
      SELECT ApiName
      FROM TaskStatus
      WHERE IsClosed = FALSE
      LIMIT 1
    ]
    .ApiName;
    List<Task> tasks = new List<Task>();
    for (Integer i = 0; i < 25; i++)
      tasks.add(
        new Task(
          WhoId = lead.Id,
          Subject = 'Sem vencimento ' + i,
          Status = openStatus
        )
      );
    tasks.add(
      new Task(
        WhoId = lead.Id,
        Subject = 'Com vencimento',
        Status = openStatus,
        ActivityDate = Date.today()
      )
    );
    insert tasks;
    Test.startTest();
    Map<String, Object> first = parsed(
      CentralComercialV1Controller.getRelatedRecords(
        lead.Id,
        'Task',
        'all',
        null,
        'all',
        null
      )
    );
    Map<String, Object> second = parsed(
      CentralComercialV1Controller.getRelatedRecords(
        lead.Id,
        'Task',
        'all',
        null,
        'all',
        (String) first.get('nextCursor')
      )
    );
    Map<String, Object> overdue = parsed(
      CentralComercialV1Controller.getRelatedRecords(
        lead.Id,
        'Task',
        'overdue',
        null,
        'open',
        null
      )
    );
    Map<String, Object> today = parsed(
      CentralComercialV1Controller.getRelatedRecords(
        lead.Id,
        'Task',
        'today',
        null,
        'open',
        null
      )
    );
    Test.stopTest();
    Assert.areEqual(26, block(first, 'block').get('total'));
    Assert.areEqual(26, block(second, 'block').get('total'));
    Assert.areEqual(6, rows(block(second, 'block')).size());
    Assert.isNull(second.get('nextCursor'));
    Assert.isNull(row(block(second, 'block'), 0).get('relevantDate'));
    Assert.areEqual(0, block(overdue, 'block').get('total'));
    Assert.areEqual(1, block(today, 'block').get('total'));
  }

  @IsTest
  static void explorerEnforcesSellerPermissionsAndRejectsInvalidRequests() {
    User seller = [SELECT Id FROM User WHERE Alias = 'ccscore' LIMIT 1];
    User minimum = [SELECT Id FROM User WHERE Alias = 'ccplain' LIMIT 1];
    Account chosen = [SELECT Id FROM Account WHERE Name = 'CC Alfa' LIMIT 1];
    Lead lead = new Lead(
      LastName = 'CC Tipos',
      Company = 'Teste',
      Status = 'Contatado'
    );
    insert lead;
    Map<String, Object> metadata = parsed(
      CentralComercialV1Controller.getFilterMetadata()
    );
    Assert.isNotNull(metadata.get('today'));
    Assert.isTrue(((List<Object>) metadata.get('accountSectors')).size() > 0);
    Test.startTest();
    System.runAs(seller) {
      Map<String, Object> directory = parsed(
        CentralComercialV1Controller.getDirectory(
          'Account',
          true,
          null,
          null,
          null,
          null,
          null,
          null
        )
      );
      Assert.areEqual(1, block(directory, 'block').get('total'));
      Assert.areEqual(
        'CC Beta',
        row(block(directory, 'block'), 0).get('label')
      );
    }
    System.runAs(minimum) {
      Map<String, Object> denied = parsed(
        CentralComercialV1Controller.getDirectory(
          'Account',
          false,
          null,
          null,
          null,
          null,
          null,
          null
        )
      );
      Assert.areEqual('no_access', block(denied, 'block').get('errorCode'));
      Assert.isNull(block(denied, 'block').get('total'));
      Map<String, Object> options = parsed(
        CentralComercialV1Controller.getFilterMetadata()
      );
      Assert.areEqual(0, ((List<Object>) options.get('accountSectors')).size());
    }
    try {
      CentralComercialV1Controller.getDirectory(
        'Task',
        false,
        null,
        null,
        null,
        null,
        null,
        null
      );
      Assert.fail('Tipo inválido.');
    } catch (AuraHandledException expected) {
    }
    try {
      CentralComercialV1Controller.getDirectory(
        'Account',
        false,
        null,
        null,
        null,
        null,
        null,
        'inválido'
      );
      Assert.fail('Cursor inválido.');
    } catch (AuraHandledException expected) {
    }
    try {
      CentralComercialV1Controller.getRelatedRecords(
        lead.Id,
        'Opportunity',
        'all',
        null,
        'all',
        null
      );
      Assert.fail('Lead só tem tarefas neste fluxo.');
    } catch (AuraHandledException expected) {
    }
    try {
      CentralComercialV1Controller.getRelatedRecords(
        chosen.Id,
        'Order',
        'today',
        null,
        null,
        null
      );
      Assert.fail('Período inválido para pedidos.');
    } catch (AuraHandledException expected) {
    }
    try {
      CentralComercialV1Controller.getRelatedRecords(
        chosen.Id,
        'Task',
        'all',
        null,
        'inválido',
        null
      );
      Assert.fail('Situação inválida.');
    } catch (AuraHandledException expected) {
    }
    Test.stopTest();
  }

  @IsTest
  static void ticketUsesWonCloseDatesAllRowsAndWeightedAverage() {
    TriggerUtility.bypassTrigger = true;
    Account chosen = [SELECT Id FROM Account WHERE Name = 'CC Alfa' LIMIT 1];
    List<Opportunity> opportunities = new List<Opportunity>();
    for (Integer i = 0; i < 23; i++) {
      Opportunity won = wonOpportunity(
        'Ticket janeiro ' + i,
        chosen.Id,
        Date.newInstance(2025, 1, 1),
        i == 0 ? 0 : 100
      );
      opportunities.add(won);
    }
    opportunities.add(
      wonOpportunity(
        'Ticket fevereiro',
        chosen.Id,
        Date.newInstance(2025, 2, 28),
        1000
      )
    );
    opportunities.add(
      wonOpportunity(
        'Ticket sem valor',
        chosen.Id,
        Date.newInstance(2025, 2, 1),
        null
      )
    );
    opportunities.add(
      wonOpportunity(
        'Ticket fora do período',
        chosen.Id,
        Date.newInstance(2025, 3, 1),
        50000
      )
    );
    Opportunity open = opportunity(
      'Aberta não participa',
      chosen.Id,
      Date.newInstance(2025, 1, 15)
    );
    open.Amount = 90000;
    opportunities.add(open);
    insert opportunities;
    Test.startTest();
    Map<String, Object> analysis = parsed(
      CentralComercialV1Controller.getTicketMedio(
        Date.newInstance(2025, 1, 1),
        Date.newInstance(2025, 2, 28)
      )
    );
    Test.stopTest();
    Assert.isNull(
      analysis.get('error'),
      'A consulta do Ticket Médio deve estar disponível.'
    );
    Assert.areEqual(25, analysis.get('wonCount'));
    Assert.areEqual(
      24,
      analysis.get('includedCount'),
      'Conta todos os registros, inclusive além da página de 20 e o valor zero.'
    );
    Assert.areEqual(1, analysis.get('withoutAmountCount'));
    Assert.areEqual(3200, analysis.get('totalAmount'));
    Assert.areEqual(
      133.33,
      analysis.get('averageAmount'),
      'A média do período é ponderada pelos registros.'
    );
    List<Object> months = (List<Object>) analysis.get('months');
    Assert.areEqual(2, months.size());
    Assert.areEqual(
      '2025-01',
      ((Map<String, Object>) months[0]).get('monthKey')
    );
    Assert.areEqual(23, ((Map<String, Object>) months[0]).get('includedCount'));
    Assert.areEqual(
      95.65,
      ((Map<String, Object>) months[0]).get('averageAmount')
    );
    Assert.areEqual(
      1000,
      ((Map<String, Object>) months[1]).get('averageAmount')
    );
    Assert.areEqual('BRL', analysis.get('currencyCode'));
  }

  @IsTest
  static void ticketDistinguishesZeroMissingAndNoRecords() {
    TriggerUtility.bypassTrigger = true;
    Account chosen = [SELECT Id FROM Account WHERE Name = 'CC Alfa' LIMIT 1];
    insert new List<Opportunity>{
      wonOpportunity(
        'Ticket zero',
        chosen.Id,
        Date.newInstance(2025, 6, 15),
        0
      ),
      wonOpportunity(
        'Ticket não informado',
        chosen.Id,
        Date.newInstance(2025, 7, 15),
        null
      )
    };
    Test.startTest();
    Map<String, Object> zero = parsed(
      CentralComercialV1Controller.getTicketMedio(
        Date.newInstance(2025, 6, 1),
        Date.newInstance(2025, 6, 30)
      )
    );
    Map<String, Object> missing = parsed(
      CentralComercialV1Controller.getTicketMedio(
        Date.newInstance(2025, 7, 1),
        Date.newInstance(2025, 7, 31)
      )
    );
    Map<String, Object> empty = parsed(
      CentralComercialV1Controller.getTicketMedio(
        Date.newInstance(2025, 8, 1),
        Date.newInstance(2025, 8, 31)
      )
    );
    Test.stopTest();
    Assert.areEqual(1, zero.get('includedCount'));
    Assert.areEqual(0, zero.get('averageAmount'));
    Assert.areEqual(0, zero.get('withoutAmountCount'));
    Assert.areEqual(1, missing.get('wonCount'));
    Assert.areEqual(0, missing.get('includedCount'));
    Assert.isNull(missing.get('averageAmount'));
    Assert.areEqual(1, missing.get('withoutAmountCount'));
    Assert.areEqual(0, empty.get('wonCount'));
    Assert.isNull(empty.get('averageAmount'));
    Assert.isNull(empty.get('error'));
  }

  @IsTest
  static void ticketRespectsSellerAccessAndDistinguishesNoAccess() {
    TriggerUtility.bypassTrigger = true;
    User seller = [SELECT Id FROM User WHERE Alias = 'ccscore' LIMIT 1];
    User minimum = [SELECT Id FROM User WHERE Alias = 'ccplain' LIMIT 1];
    Account chosen = [SELECT Id FROM Account WHERE Name = 'CC Beta' LIMIT 1];
    Opportunity sellerOwned = wonOpportunity(
      'Ticket vendedor',
      chosen.Id,
      Date.newInstance(2025, 1, 10),
      20
    );
    sellerOwned.OwnerId = seller.Id;
    insert new List<Opportunity>{
      sellerOwned,
      wonOpportunity(
        'Ticket acessível de outro dono',
        chosen.Id,
        Date.newInstance(2025, 1, 20),
        80
      )
    };
    Test.startTest();
    System.runAs(seller) {
      Map<String, Object> analysis = parsed(
        CentralComercialV1Controller.getTicketMedio(
          Date.newInstance(2025, 1, 1),
          Date.newInstance(2025, 1, 31)
        )
      );
      Assert.isNull(
        analysis.get('error'),
        'O vendedor deve acessar o Ticket Médio.'
      );
      Assert.areEqual(
        2,
        analysis.get('includedCount'),
        'A análise usa todos os registros acessíveis, sem filtrar silenciosamente pelo proprietário.'
      );
      Assert.areEqual(50, analysis.get('averageAmount'));
    }
    System.runAs(minimum) {
      Map<String, Object> denied = parsed(
        CentralComercialV1Controller.getTicketMedio(
          Date.newInstance(2025, 1, 1),
          Date.newInstance(2025, 1, 31)
        )
      );
      Assert.areEqual('no_access', denied.get('errorCode'));
      Assert.isNull(denied.get('averageAmount'));
      Assert.isNull(denied.get('wonCount'));
    }
    Test.stopTest();
  }

  @IsTest
  static void ticketRejectsInvalidAndExcessivePeriods() {
    Date start = Date.newInstance(2025, 1, 1);
    for (
      List<Date> period : new List<List<Date>>{
        new List<Date>{ null, start },
        new List<Date>{ start, null },
        new List<Date>{ start, start.addDays(-1) },
        new List<Date>{ start, start.addMonths(24) }
      }
    ) {
      try {
        CentralComercialV1Controller.getTicketMedio(period[0], period[1]);
        Assert.fail('O período inválido deve ser rejeitado.');
      } catch (AuraHandledException expected) {
      }
    }
  }

  private static Opportunity wonOpportunity(
    String name,
    Id accountId,
    Date closeDate,
    Decimal amount
  ) {
    Opportunity won = opportunity(name, accountId, closeDate);
    if (ticketWonStage == null) {
      ticketWonStage = [
        SELECT ApiName
        FROM OpportunityStage
        WHERE IsWon = TRUE
        ORDER BY SortOrder
        LIMIT 1
      ]
      .ApiName;
    }
    won.StageName = ticketWonStage;
    won.Amount = amount;
    return won;
  }

  private static Account account(String name, Id ownerId) {
    return new Account(
      Name = name,
      CompanyName__c = name,
      OwnerId = ownerId,
      BillingCity = 'São Paulo',
      BillingState = 'SP',
      BillingStreet = 'Rua Teste',
      BillingPostalCode = '01000000',
      BillingNeighborhood__c = 'Centro',
      CNAE__c = '123456',
      Email__c = 'central@example.invalid',
      Phone = '(11)12341234',
      Store__c = '01',
      ProtheusId__c = 'CC0001'
    );
  }
  private static Opportunity opportunity(
    String name,
    Id accountId,
    Date closeDate
  ) {
    return new Opportunity(
      Name = name,
      AccountId = accountId,
      CloseDate = closeDate,
      StageName = 'Qualificação',
      RecordTypeId = Opportunity.SObjectType.getDescribe()
        .getRecordTypeInfosByDeveloperName()
        .get('Industria')
        .getRecordTypeId()
    );
  }
  private static User makeUser(String alias, Id profileId) {
    return new User(
      Username = alias +
        '.' +
        UserInfo.getOrganizationId() +
        '.' +
        DateTime.now().getTime() +
        '@example.invalid',
      LastName = alias,
      Email = alias + '@example.invalid',
      Alias = alias,
      TimeZoneSidKey = 'America/Sao_Paulo',
      LocaleSidKey = 'pt_BR',
      EmailEncodingKey = 'UTF-8',
      LanguageLocaleKey = 'pt_BR',
      ProfileId = profileId,
      ProtheusSellerId__c = 'CC0002'
    );
  }
  private static String firstActive(Schema.SObjectField field) {
    for (Schema.PicklistEntry entry : field.getDescribe().getPicklistValues())
      if (entry.isActive())
        return entry.getValue();
    Assert.fail('Lista de opções precisa ter valor ativo.');
    return null;
  }
  private static Map<String, Object> overview(
    String monthKey,
    Boolean mine,
    String state,
    Id accountId
  ) {
    return parsed(
      CentralComercialV1Controller.getOverview(
        monthKey,
        mine,
        state,
        accountId,
        null,
        false,
        null,
        null,
        null
      )
    );
  }
  private static Map<String, Object> parsed(String value) {
    return (Map<String, Object>) JSON.deserializeUntyped(value);
  }
  private static Map<String, Object> block(
    Map<String, Object> data,
    String key
  ) {
    return (Map<String, Object>) data.get(key);
  }
  private static List<Object> rows(Map<String, Object> section) {
    return (List<Object>) section.get('rows');
  }
  private static Map<String, Object> row(
    Map<String, Object> section,
    Integer index
  ) {
    return (Map<String, Object>) rows(section)[index];
  }
}