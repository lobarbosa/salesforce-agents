public with sharing class CentralComercialV1Controller {
  private static final Integer ROW_LIMIT = 20;
  private static final String ORDER_DATE = 'ExpectedSaleDate__c';
  private static final String SCORE = 'PriorityScore__c';
  private static final String BAND = 'PriorityBand__c';
  // API values confirmed in LeadStatus, layouts and the org's list views.
  private static final Set<String> ELIGIBLE_LEAD_STATUSES = new Set<String>{
    'Aberto - Não contatado',
    'Contatado'
  };
  private static final Map<String, Schema.SObjectType> OBJECTS = Schema.getGlobalDescribe();

  private class Row {
    public Id id;
    public String label;
    public Id accountId;
    public String accountName;
    public String ownerName;
    public String company;
    public String sector;
    public String billingState;
    public Id parentId;
    public String parentName;
    public String status;
    public Date relevantDate;
    public Decimal amount;
    public String currencyCode;
    public Decimal score;
    public String band;
  }

  private class Block {
    public Integer total;
    public String error;
    public String errorCode;
    public String note;
    public String criterion;
    public Map<String, String> fieldStates = new Map<String, String>();
    public List<Row> rows = new List<Row>();
  }

  private class QuerySpec {
    public String objectApi;
    public String nameField;
    public String statusField;
    public String dateField;
    public String criterion;
    public String countCriterion;
    public String orderByClause;
    public String explanation;
    public Boolean includeAccount;
    public Boolean includeLead = false;
    public Integer rowLimit;
    public Set<String> required = new Set<String>();

    public QuerySpec(
      String objectApi,
      String nameField,
      String statusField,
      String dateField,
      String criterion,
      String orderByClause,
      String explanation,
      Boolean includeAccount,
      Integer rowLimit
    ) {
      this.objectApi = objectApi;
      this.nameField = nameField;
      this.statusField = statusField;
      this.dateField = dateField;
      this.criterion = criterion;
      this.orderByClause = orderByClause;
      this.explanation = explanation;
      this.includeAccount = includeAccount;
      this.rowLimit = rowLimit;
      required.add('Id');
      required.add(nameField);
      if (statusField != null)
        required.add(statusField);
      if (dateField != null)
        required.add(dateField);
      if (includeAccount)
        required.addAll(new Set<String>{ 'AccountId', 'Account.Name' });
    }
  }

  private class TicketMonth {
    public String monthKey;
    public Integer wonCount = 0;
    public Integer includedCount = 0;
    public Decimal totalAmount;
    public Decimal averageAmount;
  }

  private class TicketAnalysis {
    public Date startDate;
    public Date endDate;
    public String currencyCode;
    public Integer wonCount;
    public Integer includedCount;
    public Integer withoutAmountCount;
    public Decimal totalAmount;
    public Decimal averageAmount;
    public String error;
    public String errorCode;
    public List<TicketMonth> months = new List<TicketMonth>();
  }

  @AuraEnabled
  public static String getTicketMedio(Date startDate, Date endDate) {
    if (startDate == null || endDate == null || endDate < startDate) {
      throw new AuraHandledException(
        'Informe um período de fechamento válido.'
      );
    }
    Date firstMonth = Date.newInstance(startDate.year(), startDate.month(), 1);
    // Presentation/query limit, not a commercial classification rule.
    if (endDate >= firstMonth.addMonths(24)) {
      throw new AuraHandledException('Consulte até 24 meses por vez.');
    }
    TicketAnalysis result = new TicketAnalysis();
    result.startDate = startDate;
    result.endDate = endDate;
    for (
      String field : new List<String>{ 'Id', 'IsWon', 'CloseDate', 'Amount' }
    ) {
      if (fieldState('Opportunity', field) != 'available') {
        result.errorCode = 'no_access';
        result.error = 'Sem acesso a Oportunidades ou aos campos necessários ao Ticket Médio.';
        return JSON.serialize(result);
      }
    }
    Map<String, Object> binds = new Map<String, Object>{
      'startDate' => startDate,
      'endDate' => endDate
    };
    String criterion = ' FROM Opportunity WHERE IsWon = true AND CloseDate >= :startDate AND CloseDate <= :endDate';
    try {
      // SUM aggregates count source rows toward Apex's 50,000-row governor limit.
      if (
        Database.countQueryWithBinds(
          'SELECT COUNT()' + criterion,
          binds,
          AccessLevel.USER_MODE
        ) > 49000
      ) {
        result.errorCode = 'too_many_records';
        result.error = 'O período contém registros demais para esta consulta. Selecione um período menor.';
        return JSON.serialize(result);
      }
      result.currencyCode = UserInfo.getDefaultCurrency();
      if (UserInfo.isMultiCurrencyOrganization()) {
        // SOQL currency aggregates use the corporate currency, not the viewer's currency.
        List<SObject> currencies = Database.queryWithBinds(
          'SELECT IsoCode FROM CurrencyType WHERE IsCorporate = true LIMIT 1',
          new Map<String, Object>(),
          AccessLevel.USER_MODE
        );
        if (currencies.isEmpty()) {
          throw new AuraHandledException(
            'Não foi possível identificar a moeda corporativa.'
          );
        }
        result.currencyCode = (String) currencies[0].get('IsoCode');
      }
      List<SObject> aggregates = Database.queryWithBinds(
        'SELECT CALENDAR_YEAR(CloseDate) closeYear, CALENDAR_MONTH(CloseDate) closeMonth, COUNT(Id) wonCount, COUNT(Amount) includedCount, SUM(Amount) totalAmount' +
          criterion +
          ' GROUP BY CALENDAR_YEAR(CloseDate), CALENDAR_MONTH(CloseDate)',
        binds,
        AccessLevel.USER_MODE
      );
      Map<String, TicketMonth> byMonth = new Map<String, TicketMonth>();
      result.wonCount = 0;
      result.includedCount = 0;
      Decimal sumAmount = 0;
      for (SObject aggregate : aggregates) {
        TicketMonth month = new TicketMonth();
        month.monthKey = String.valueOf(
            Date.newInstance(
              (Integer) aggregate.get('closeYear'),
              (Integer) aggregate.get('closeMonth'),
              1
            )
          )
          .substring(0, 7);
        month.wonCount = (Integer) aggregate.get('wonCount');
        month.includedCount = (Integer) aggregate.get('includedCount');
        month.totalAmount = (Decimal) aggregate.get('totalAmount');
        if (month.includedCount > 0) {
          month.averageAmount = (month.totalAmount / month.includedCount)
            .setScale(2);
          sumAmount += month.totalAmount;
        }
        result.wonCount += month.wonCount;
        result.includedCount += month.includedCount;
        byMonth.put(month.monthKey, month);
      }
      result.withoutAmountCount = result.wonCount - result.includedCount;
      if (result.includedCount > 0) {
        result.totalAmount = sumAmount;
        // Global average is weighted by records, never an average of monthly averages.
        result.averageAmount = (sumAmount / result.includedCount).setScale(2);
      }
      for (
        Date monthStart = firstMonth;
        monthStart <= endDate;
        monthStart = monthStart.addMonths(1)
      ) {
        String key = String.valueOf(monthStart).substring(0, 7);
        TicketMonth month = byMonth.get(key);
        if (month == null) {
          month = new TicketMonth();
          month.monthKey = key;
        }
        result.months.add(month);
      }
    } catch (QueryException e) {
      result = new TicketAnalysis();
      result.errorCode = 'query_failed';
      result.error = 'Não foi possível consultar o Ticket Médio com as permissões atuais. Tente novamente ou contate o administrador.';
    }
    return JSON.serialize(result);
  }

  @AuraEnabled
  public static String getOverview(
    String monthKey,
    Boolean mine,
    String billingState,
    Id accountId,
    Id sellerId,
    Boolean leadsMine,
    Id leadOwnerId,
    String leadStatus,
    String accountSector
  ) {
    Date today = Date.today();
    Date startDate = monthStart(monthKey, today);
    validateId(
      accountId,
      new Set<Schema.SObjectType>{ Account.SObjectType },
      'Selecione uma conta válida.'
    );
    validateId(
      sellerId,
      new Set<Schema.SObjectType>{ User.SObjectType },
      'Selecione um vendedor válido.'
    );
    validateId(
      leadOwnerId,
      new Set<Schema.SObjectType>{ User.SObjectType, Group.SObjectType },
      'Selecione um responsável pelo lead válido.'
    );
    if (
      String.isNotBlank(leadStatus) &&
      !ELIGIBLE_LEAD_STATUSES.contains(leadStatus)
    ) {
      throw new AuraHandledException(
        'Selecione um status de lead em atendimento.'
      );
    }
    String sectorState = fieldState('Account', 'Sector__c');
    List<Map<String, String>> sectorOptions = new List<Map<String, String>>();
    Set<String> validSectors = new Set<String>();
    if (sectorState == 'available') {
      for (
        Schema.PicklistEntry entry : Account.Sector__c.getDescribe()
          .getPicklistValues()
      ) {
        if (entry.isActive()) {
          sectorOptions.add(
            new Map<String, String>{
              'label' => entry.getLabel(),
              'value' => entry.getValue()
            }
          );
          validSectors.add(entry.getValue());
        }
      }
      if (
        String.isNotBlank(accountSector) &&
        !validSectors.contains(accountSector)
      ) {
        throw new AuraHandledException('Selecione um setor de conta válido.');
      }
    }
    Map<String, Object> binds = new Map<String, Object>{
      'startDate' => startDate,
      'endDate' => startDate.addMonths(1),
      'today' => today,
      'weekEnd' => today.addDays(7),
      'viewerId' => UserInfo.getUserId(),
      'eligibleStatuses' => ELIGIBLE_LEAD_STATUSES
    };
    String accountScope = ' AND AccountId != null';
    Set<String> scopeFields = new Set<String>();
    if (mine != false) {
      accountScope += ' AND Account.OwnerId = :viewerId';
      scopeFields.add('Account.OwnerId');
    }
    if (sellerId != null) {
      accountScope += ' AND Account.OwnerId = :sellerId';
      binds.put('sellerId', sellerId);
      scopeFields.add('Account.OwnerId');
    }
    if (String.isNotBlank(billingState)) {
      if (billingState.trim().length() > 80) {
        throw new AuraHandledException(
          'A UF de cobrança informada é longa demais.'
        );
      }
      accountScope += ' AND Account.BillingState = :state';
      binds.put('state', billingState.trim());
      scopeFields.add('Account.BillingState');
    }
    if (accountId != null) {
      accountScope += ' AND AccountId = :accountId';
      binds.put('accountId', accountId);
    }
    if (String.isNotBlank(accountSector)) {
      accountScope += ' AND Account.Sector__c = :accountSector';
      binds.put('accountSector', accountSector);
      scopeFields.add('Account.Sector__c');
    }
    List<QuerySpec> specs = new List<QuerySpec>{
      new QuerySpec(
        'Task',
        'Subject',
        'Status',
        'ActivityDate',
        'IsClosed = false AND ActivityDate != null AND ActivityDate < :today' +
        accountScope,
        'ActivityDate ASC, Id ASC',
        'Tarefas abertas com vencimento anterior a hoje; independente do mês.',
        true,
        ROW_LIMIT
      ),
      new QuerySpec(
        'Task',
        'Subject',
        'Status',
        'ActivityDate',
        'IsClosed = false AND ActivityDate = :today' + accountScope,
        'ActivityDate ASC, Id ASC',
        'Tarefas abertas com vencimento hoje; independente do mês.',
        true,
        ROW_LIMIT
      ),
      new QuerySpec(
        'Task',
        'Subject',
        'Status',
        'ActivityDate',
        'IsClosed = false AND ActivityDate > :today AND ActivityDate <= :weekEnd' +
        accountScope,
        'ActivityDate ASC, Id ASC',
        'Tarefas abertas de amanhã até sete dias após hoje; independente do mês.',
        true,
        ROW_LIMIT
      ),
      new QuerySpec(
        'Opportunity',
        'Name',
        'StageName',
        'CloseDate',
        'IsClosed = false AND CloseDate >= :startDate AND CloseDate < :endDate' +
        accountScope,
        'CloseDate ASC, Id ASC',
        'Oportunidades abertas pela previsão de fechamento no mês selecionado.',
        true,
        ROW_LIMIT
      ),
      new QuerySpec(
        'Opportunity',
        'Name',
        'StageName',
        'CloseDate',
        'IsClosed = false AND CloseDate < :today' + accountScope,
        'CloseDate ASC, Id ASC',
        'Oportunidades abertas com previsão de fechamento anterior a hoje; independente do mês.',
        true,
        ROW_LIMIT
      ),
      new QuerySpec(
        'Order',
        'OrderNumber',
        'Status',
        ORDER_DATE,
        ORDER_DATE +
          ' >= :startDate AND ' +
          ORDER_DATE +
          ' < :endDate' +
          accountScope,
        ORDER_DATE + ' DESC, Id DESC',
        'Data previsão de vendas no mês selecionado. Todos os status, inclusive cancelados; não mede faturamento.',
        true,
        ROW_LIMIT
      )
    };
    Map<String, Object> overview = new Map<String, Object>{
      'accountSectorFilter' => new Map<String, Object>{
        'state' => sectorState,
        'options' => sectorOptions
      },
      'today' => today,
      'weekEnd' => today.addDays(7),
      'monthStart' => startDate,
      'monthEnd' => startDate.addMonths(1).addDays(-1),
      'orderDateLabel' => 'Data previsão de vendas',
      'orderDateApi' => 'Order.' + ORDER_DATE
    };
    List<String> keys = new List<String>{
      'agenda',
      'todayTasks',
      'upcoming',
      'pipeline',
      'overdue',
      'orders'
    };
    for (Integer i = 0; i < specs.size(); i++) {
      specs[i].required.addAll(scopeFields);
      if (specs[i].objectApi != 'Order')
        specs[i].required.add('IsClosed');
      overview.put(keys[i], readBlock(specs[i], binds));
    }
    // Leads have no confirmed Account/region dimension. Never apply the account scope here.
    String leadCriterion = 'IsConverted = false AND Status IN :eligibleStatuses';
    Set<String> leadFields = new Set<String>{ 'IsConverted' };
    if (leadsMine != false) {
      leadCriterion += ' AND OwnerId = :viewerId';
      leadFields.add('OwnerId');
    }
    if (leadOwnerId != null) {
      leadCriterion += ' AND OwnerId = :leadOwnerId';
      binds.put('leadOwnerId', leadOwnerId);
      leadFields.add('OwnerId');
    }
    if (String.isNotBlank(leadStatus)) {
      leadCriterion += ' AND Status = :leadStatus';
      binds.put('leadStatus', leadStatus);
    }
    Boolean scoreReadable = fieldState('Lead', SCORE) == 'available';
    QuerySpec leadSpec = new QuerySpec(
      'Lead',
      'Name',
      'Status',
      null,
      leadCriterion,
      scoreReadable ? SCORE + ' DESC NULLS LAST, Id ASC' : 'Name ASC, Id ASC',
      'Não convertidos em Aberto - Não contatado ou Contatado. Filtros próprios de responsável e status; sem mês, conta, UF ou setor da conta.',
      false,
      ROW_LIMIT
    );
    leadSpec.required.addAll(leadFields);
    Block leads = readBlock(leadSpec, binds);
    leads.note = scoreReadable
      ? 'Score em ordem decrescente; faixa calculada pela organização.'
      : (fieldState('Lead', SCORE) == 'no_access'
          ? 'Sem acesso ao score. Lista ordenada por nome.'
          : 'Score indisponível. Lista ordenada por nome.');
    overview.put('leads', leads);
    return JSON.serialize(overview);
  }

  @AuraEnabled
  public static String getAccountDetail(Id accountId) {
    if (accountId == null)
      throw new AuraHandledException('Selecione uma conta válida.');
    validateId(
      accountId,
      new Set<Schema.SObjectType>{ Account.SObjectType },
      'Selecione uma conta válida.'
    );
    List<Account> found;
    try {
      found = [
        SELECT Id, Name
        FROM Account
        WHERE Id = :accountId
        WITH USER_MODE
        LIMIT 1
      ];
    } catch (QueryException e) {
      throw new AuraHandledException(
        'Sem acesso à conta ou aos campos necessários ao resumo.'
      );
    }
    if (found.isEmpty())
      throw new AuraHandledException('Conta indisponível para consulta.');
    Map<String, Object> binds = new Map<String, Object>{
      'accountId' => accountId
    };
    String scope = 'AccountId = :accountId';
    QuerySpec contacts = new QuerySpec(
      'Contact',
      'Name',
      null,
      null,
      scope,
      'Name ASC, Id ASC',
      'Contatos desta conta; sem filtro do mês.',
      false,
      5
    );
    QuerySpec opportunities = new QuerySpec(
      'Opportunity',
      'Name',
      'StageName',
      'CloseDate',
      scope + ' AND IsClosed = false',
      'CloseDate ASC, Id ASC',
      'Oportunidades abertas; sem filtro do mês.',
      false,
      5
    );
    QuerySpec orders = new QuerySpec(
      'Order',
      'OrderNumber',
      'Status',
      'EffectiveDate',
      scope,
      'EffectiveDate DESC, Id DESC',
      'Pedidos recentes pela data de início; todos os status e sem filtro do mês.',
      false,
      5
    );
    QuerySpec tasks = new QuerySpec(
      'Task',
      'Subject',
      'Status',
      'ActivityDate',
      scope + ' AND IsClosed = false AND ActivityDate != null',
      'ActivityDate ASC, Id ASC',
      'Tarefas abertas com prazo; sem filtro do mês.',
      false,
      5
    );
    for (
      QuerySpec spec : new List<QuerySpec>{
        contacts,
        opportunities,
        orders,
        tasks
      }
    ) {
      spec.required.add('AccountId');
      if (spec.objectApi == 'Task' || spec.objectApi == 'Opportunity')
        spec.required.add('IsClosed');
    }
    return JSON.serialize(
      new Map<String, Object>{
        'id' => found[0].Id,
        'name' => found[0].Name,
        'contacts' => readBlock(contacts, binds),
        'opportunities' => readBlock(opportunities, binds),
        'orders' => readBlock(orders, binds),
        'tasks' => readBlock(tasks, binds)
      }
    );
  }

  @AuraEnabled(cacheable=true)
  public static String getFilterMetadata() {
    // Only schema and status configuration; no customer, lead or activity records.
    List<Map<String, String>> leadStatuses = new List<Map<String, String>>();
    try {
      if (fieldState('Lead', 'Status') == 'available') {
        for (LeadStatus statusInfo : [
          SELECT ApiName, MasterLabel
          FROM LeadStatus
          WHERE IsConverted = FALSE
          WITH USER_MODE
          ORDER BY SortOrder
        ]) {
          if (!picklistContains('Lead', 'Status', statusInfo.ApiName))
            continue;
          leadStatuses.add(
            new Map<String, String>{
              'label' => statusInfo.MasterLabel,
              'value' => statusInfo.ApiName
            }
          );
        }
      }
    } catch (QueryException e) {
      // The confirmed 'in service' and 'all unconverted' modes remain available.
    }
    return JSON.serialize(
      new Map<String, Object>{
        'today' => Date.today(),
        'accountSectorState' => fieldState('Account', 'Sector__c'),
        'accountSectors' => picklistOptions('Account', 'Sector__c'),
        'leadStatuses' => leadStatuses,
        'orderStatuses' => picklistOptions('Order', 'Status')
      }
    );
  }

  @AuraEnabled
  public static String getDirectory(
    String entityType,
    Boolean mine,
    String nameSearch,
    String billingState,
    String accountSector,
    String leadStatus,
    Id ownerId,
    String cursorToken
  ) {
    DirectoryScope scope = directoryScope(
      entityType,
      mine,
      nameSearch,
      billingState,
      accountSector,
      leadStatus,
      ownerId
    );
    String criterion = scope.criterion;
    Map<String, Object> binds = scope.binds;
    Set<String> required = scope.required;
    Boolean byScore =
      entityType == 'Lead' &&
      fieldState('Lead', SCORE) == 'available';
    QuerySpec spec = new QuerySpec(
      entityType,
      'Name',
      entityType == 'Lead' ? 'Status' : null,
      null,
      criterion,
      null,
      entityType == 'Account'
        ? 'Contas do recorte consultado; datas são aplicadas aos relacionados.'
        : 'Leads não convertidos; ordenação pelo score quando acessível.',
      false,
      ROW_LIMIT + 1
    );
    spec.required.addAll(required);
    return readPage(
      spec,
      binds,
      cursorToken,
      byScore ? SCORE : 'Name',
      byScore ? 'score' : 'label',
      byScore
    );
  }

  @AuraEnabled
  public static String getRelatedRecords(
    Id parentId,
    String relatedType,
    String datePreset,
    String monthKey,
    String recordScope,
    String cursorToken
  ) {
    if (parentId == null)
      throw new AuraHandledException('Selecione uma conta ou lead.');
    validateId(
      parentId,
      new Set<Schema.SObjectType>{ Account.SObjectType, Lead.SObjectType },
      'Selecione uma conta ou lead.'
    );
    Boolean isLead = parentId.getSObjectType() == Lead.SObjectType;
    Set<String> allowed = isLead
      ? new Set<String>{ 'Task' }
      : new Set<String>{ 'Opportunity', 'Task', 'Order', 'Contact' };
    if (!allowed.contains(relatedType))
      throw new AuraHandledException(
        'Relacionado inválido para o registro selecionado.'
      );
    String parentType = isLead ? 'Lead' : 'Account';
    Map<String, Object> binds = new Map<String, Object>{
      'parentId' => parentId
    };
    try {
      if (
        Database.queryWithBinds(
            'SELECT Id, Name FROM ' +
              parentType +
              ' WHERE Id = :parentId LIMIT 1',
            binds,
            AccessLevel.USER_MODE
          )
          .isEmpty()
      ) {
        throw new AuraHandledException('Registro indisponível para consulta.');
      }
    } catch (QueryException e) {
      throw new AuraHandledException(
        'Registro ou campos sem acesso para consulta.'
      );
    }
    String linkField = isLead ? 'WhoId' : 'AccountId';
    String criterion = linkField + ' = :parentId';
    return relatedPage(
      isLead,
      relatedType,
      criterion,
      binds,
      datePreset,
      monthKey,
      recordScope,
      cursorToken,
      false
    );
  }

  @AuraEnabled
  public static String getSegmentRelatedRecords(
    String directoryFilters,
    String relatedType,
    String datePreset,
    String monthKey,
    String recordScope,
    String cursorToken
  ) {
    Map<String, Object> filters;
    try {
      filters = (Map<String, Object>) JSON.deserializeUntyped(directoryFilters);
    } catch (Exception e) {
      throw new AuraHandledException(
        'Refaça a busca para consultar o recorte.'
      );
    }
    if (filters == null)
      throw new AuraHandledException(
        'Refaça a busca para consultar o recorte.'
      );
    String entityType = (String) filters.get('entityType');
    DirectoryScope scope = directoryScope(
      entityType,
      (Boolean) filters.get('mine'),
      (String) filters.get('nameSearch'),
      (String) filters.get('billingState'),
      (String) filters.get('accountSector'),
      (String) filters.get('leadStatus'),
      (Id) ((String) filters.get('ownerId'))
    );
    scope.required.addAll(new Set<String>{ 'Id', 'Name' });
    for (String field : scope.required) {
      if (fieldState(entityType, field) != 'available') {
        Block denied = new Block();
        denied.errorCode = 'no_access';
        denied.error = 'Sem acesso aos campos necessários ao recorte.';
        return JSON.serialize(
          new Map<String, Object>{
            'block' => denied,
            'nextCursor' => null,
            'pageSize' => ROW_LIMIT
          }
        );
      }
    }
    Boolean isLead = entityType == 'Lead';
    String linkField = isLead ? 'WhoId' : 'AccountId';
    String criterion =
      linkField +
      ' IN (SELECT Id FROM ' +
      entityType +
      ' WHERE ' +
      scope.criterion +
      ')';
    return relatedPage(
      isLead,
      relatedType,
      criterion,
      scope.binds,
      datePreset,
      monthKey,
      recordScope,
      cursorToken,
      true
    );
  }

  private static String relatedPage(
    Boolean isLead,
    String relatedType,
    String criterion,
    Map<String, Object> binds,
    String datePreset,
    String monthKey,
    String recordScope,
    String cursorToken,
    Boolean includeParent
  ) {
    Set<String> allowed = isLead
      ? new Set<String>{ 'Task' }
      : new Set<String>{ 'Opportunity', 'Task', 'Order', 'Contact' };
    if (!allowed.contains(relatedType))
      throw new AuraHandledException('Relacionado inválido para este recorte.');
    String linkField = isLead ? 'WhoId' : 'AccountId';
    String statusField = relatedType == 'Opportunity'
      ? 'StageName'
      : (relatedType == 'Contact' ? null : 'Status');
    String dateField = relatedType == 'Opportunity'
      ? 'CloseDate'
      : (relatedType == 'Order'
          ? ORDER_DATE
          : (relatedType == 'Task' ? 'ActivityDate' : null));
    String dateLabel = relatedType == 'Opportunity'
      ? 'Previsão de fechamento'
      : (relatedType == 'Order' ? 'Data previsão de vendas' : 'Vencimento');
    Set<String> required = new Set<String>{ linkField };
    if (relatedType == 'Opportunity' || relatedType == 'Task') {
      if (String.isBlank(recordScope))
        recordScope = 'open';
      if (!new Set<String>{ 'open', 'closed', 'all' }.contains(recordScope))
        throw new AuraHandledException('Selecione uma situação válida.');
      if (recordScope != 'all') {
        criterion += ' AND IsClosed = :closed';
        binds.put('closed', recordScope == 'closed');
        required.add('IsClosed');
      }
    } else if (relatedType == 'Order' && String.isNotBlank(recordScope)) {
      if (
        fieldState('Order', 'Status') == 'available' &&
        !picklistContains('Order', 'Status', recordScope)
      )
        throw new AuraHandledException('Selecione um status de pedido válido.');
      criterion += ' AND Status = :orderStatus';
      binds.put('orderStatus', recordScope);
    }
    if (String.isBlank(datePreset))
      datePreset = 'all';
    String explanation = dateField == null
      ? 'Contatos vinculados à conta.'
      : dateLabel + ': sem filtro de período.';
    if (datePreset == 'month' && dateField != null) {
      Date startDate = monthStart(monthKey, Date.today());
      criterion +=
        ' AND ' +
        dateField +
        ' >= :startDate AND ' +
        dateField +
        ' < :endDate';
      binds.put('startDate', startDate);
      binds.put('endDate', startDate.addMonths(1));
      explanation =
        dateLabel +
        ': ' +
        String.valueOf(startDate) +
        ' a ' +
        String.valueOf(startDate.addMonths(1).addDays(-1)) +
        '.';
    } else if (relatedType == 'Opportunity' && datePreset == 'overdue') {
      binds.put('today', Date.today());
      criterion += ' AND CloseDate < :today';
      explanation = 'Previsão de fechamento anterior a hoje.';
    } else if (
      relatedType == 'Task' &&
      new Set<String>{ 'overdue', 'today', 'next7' }.contains(datePreset)
    ) {
      Date today = Date.today();
      binds.put('today', today);
      if (datePreset == 'overdue')
        criterion += ' AND ActivityDate != null AND ActivityDate < :today';
      if (datePreset == 'today')
        criterion += ' AND ActivityDate = :today';
      if (datePreset == 'next7') {
        criterion += ' AND ActivityDate > :today AND ActivityDate <= :weekEnd';
        binds.put('weekEnd', today.addDays(7));
      }
      explanation =
        'Vencimento: ' +
        (datePreset == 'overdue'
          ? 'anterior a hoje'
          : (datePreset == 'today' ? 'hoje' : 'de amanhã até hoje + 7')) +
        '.';
    } else if (datePreset != 'all')
      throw new AuraHandledException(
        'Selecione um período válido para esta lista.'
      );
    if (relatedType == 'Order')
      explanation += ' Todos os status são incluídos quando não há filtro de status; não mede faturamento.';
    QuerySpec spec = new QuerySpec(
      relatedType,
      relatedType == 'Order'
        ? 'OrderNumber'
        : (relatedType == 'Task' ? 'Subject' : 'Name'),
      statusField,
      dateField,
      criterion,
      null,
      explanation,
      includeParent && !isLead,
      ROW_LIMIT + 1
    );
    spec.includeLead = includeParent && isLead;
    if (spec.includeLead)
      spec.required.add('Lead.Name');
    spec.required.addAll(required);
    return readPage(
      spec,
      binds,
      cursorToken,
      dateField == null ? 'Name' : dateField,
      dateField == null ? 'label' : 'relevantDate',
      relatedType == 'Order'
    );
  }

  private class DirectoryScope {
    public String criterion;
    public Map<String, Object> binds;
    public Set<String> required;
  }
  private static DirectoryScope directoryScope(
    String entityType,
    Boolean mine,
    String nameSearch,
    String billingState,
    String accountSector,
    String leadStatus,
    Id ownerId
  ) {
    if (entityType != 'Account' && entityType != 'Lead')
      throw new AuraHandledException('Selecione Clientes ou Leads.');
    Set<Schema.SObjectType> ownerTypes = new Set<Schema.SObjectType>{
      User.SObjectType
    };
    if (entityType == 'Lead')
      ownerTypes.add(Group.SObjectType);
    validateId(ownerId, ownerTypes, 'Selecione um responsável válido.');
    Map<String, Object> binds = new Map<String, Object>();
    String criterion = 'Id != null';
    Set<String> required = new Set<String>();
    if (mine == true) {
      criterion += ' AND OwnerId = :viewerId';
      binds.put('viewerId', UserInfo.getUserId());
      required.add('OwnerId');
    }
    if (ownerId != null) {
      criterion += ' AND OwnerId = :ownerId';
      binds.put('ownerId', ownerId);
      required.add('OwnerId');
    }
    if (String.isNotBlank(nameSearch)) {
      if (nameSearch.trim().length() > 120)
        throw new AuraHandledException(
          'Use até 120 caracteres na busca por nome.'
        );
      criterion += ' AND Name LIKE :namePattern';
      binds.put(
        'namePattern',
        '%' +
          nameSearch.trim()
            .replace('\\', '\\\\')
            .replace('%', '\\%')
            .replace('_', '\\_') +
          '%'
      );
    }
    if (entityType == 'Account') {
      if (String.isNotBlank(billingState)) {
        if (billingState.trim().length() > 80)
          throw new AuraHandledException(
            'A UF de cobrança informada é longa demais.'
          );
        criterion += ' AND BillingState = :billingState';
        binds.put('billingState', billingState.trim());
        required.add('BillingState');
      }
      if (String.isNotBlank(accountSector)) {
        if (
          fieldState('Account', 'Sector__c') == 'available' &&
          !picklistContains('Account', 'Sector__c', accountSector)
        )
          throw new AuraHandledException('Selecione um setor de conta válido.');
        criterion += ' AND Sector__c = :accountSector';
        binds.put('accountSector', accountSector);
        required.add('Sector__c');
      }
    } else {
      // No account dimensions are applied to a Lead directory.
      criterion += ' AND IsConverted = false';
      required.add('IsConverted');
      if (String.isNotBlank(leadStatus))
        required.add('Status');
      if (leadStatus == '__ACTIVE__') {
        criterion += ' AND Status IN :eligibleStatuses';
        binds.put('eligibleStatuses', ELIGIBLE_LEAD_STATUSES);
      } else if (String.isNotBlank(leadStatus)) {
        if (
          fieldState('Lead', 'Status') == 'available' &&
          !picklistContains('Lead', 'Status', leadStatus)
        )
          throw new AuraHandledException('Selecione um status válido.');
        criterion += ' AND Status = :leadStatus';
        binds.put('leadStatus', leadStatus);
      }
    }
    DirectoryScope result = new DirectoryScope();
    result.criterion = criterion;
    result.binds = binds;
    result.required = required;
    return result;
  }

  private static List<Map<String, String>> picklistOptions(
    String objectApi,
    String fieldApi
  ) {
    List<Map<String, String>> options = new List<Map<String, String>>();
    if (fieldState(objectApi, fieldApi) == 'available') {
      for (
        Schema.PicklistEntry entry : OBJECTS.get(objectApi)
          .getDescribe()
          .fields.getMap()
          .get(fieldApi)
          .getDescribe()
          .getPicklistValues()
      ) {
        if (entry.isActive())
          options.add(
            new Map<String, String>{
              'label' => entry.getLabel(),
              'value' => entry.getValue()
            }
          );
      }
    }
    return options;
  }

  private static Boolean picklistContains(
    String objectApi,
    String fieldApi,
    String value
  ) {
    for (Map<String, String> option : picklistOptions(objectApi, fieldApi))
      if (option.get('value') == value)
        return true;
    return false;
  }

  private static String readPage(
    QuerySpec spec,
    Map<String, Object> binds,
    String cursorToken,
    String orderField,
    String rowKey,
    Boolean descending
  ) {
    spec.countCriterion = spec.criterion;
    spec.orderByClause =
      orderField +
      (descending ? ' DESC' : ' ASC') +
      ' NULLS LAST, Id ASC';
    if (String.isNotBlank(cursorToken)) {
      try {
        if (cursorToken.length() > 4000)
          throw new IllegalArgumentException();
        Map<String, Object> cursor = (Map<String, Object>) JSON.deserializeUntyped(
          EncodingUtil.base64Decode(cursorToken).toString()
        );
        if (
          cursor.get('objectApi') != spec.objectApi ||
          cursor.get('orderField') != orderField
        )
          throw new IllegalArgumentException();
        Id lastId = (Id) ((String) cursor.get('id'));
        if (
          lastId == null ||
          lastId.getSObjectType() != OBJECTS.get(spec.objectApi)
        )
          throw new IllegalArgumentException();
        binds.put('cursorId', lastId);
        Object value = cursor.get('value');
        if (value == null)
          spec.criterion +=
            ' AND (' +
            orderField +
            ' = null AND Id > :cursorId)';
        else {
          if (rowKey == 'score')
            value = Decimal.valueOf(String.valueOf(value));
          if (rowKey == 'relevantDate')
            value = Date.valueOf(String.valueOf(value));
          binds.put('cursorValue', value);
          spec.criterion +=
            ' AND ((' +
            orderField +
            ' = :cursorValue AND Id > :cursorId) OR ' +
            orderField +
            (descending ? ' <' : ' >') +
            ' :cursorValue OR ' +
            orderField +
            ' = null)';
        }
      } catch (Exception e) {
        throw new AuraHandledException('Página inválida. Refaça a busca.');
      }
    }
    Block result = readBlock(spec, binds);
    String nextCursor;
    if (result.rows.size() > ROW_LIMIT) {
      result.rows.remove(ROW_LIMIT);
      Row last = result.rows[ROW_LIMIT - 1];
      Object value = rowKey == 'score'
        ? (Object) last.score
        : (rowKey == 'relevantDate'
            ? (Object) last.relevantDate
            : (Object) last.label);
      nextCursor = EncodingUtil.base64Encode(
        Blob.valueOf(
          JSON.serialize(
            new Map<String, Object>{
              'objectApi' => spec.objectApi,
              'orderField' => orderField,
              'id' => last.id,
              'value' => value
            }
          )
        )
      );
    }
    return JSON.serialize(
      new Map<String, Object>{
        'block' => result,
        'nextCursor' => nextCursor,
        'pageSize' => ROW_LIMIT
      }
    );
  }

  private static Block readBlock(QuerySpec spec, Map<String, Object> binds) {
    Block result = new Block();
    result.criterion = spec.explanation;
    for (String path : spec.required) {
      String state = fieldState(spec.objectApi, path);
      if (state != 'available') {
        result.errorCode = state;
        result.error = state == 'no_access'
          ? 'Sem acesso ao objeto ou aos campos necessários a esta lista.'
          : 'Campo necessário indisponível na organização. Consulte o mapeamento da Central.';
        return result;
      }
    }
    Set<String> columns = new Set<String>{ 'Id', spec.nameField };
    if (spec.statusField != null)
      columns.add(spec.statusField);
    if (spec.dateField != null)
      columns.add(spec.dateField);
    if (spec.includeAccount)
      columns.addAll(new Set<String>{ 'AccountId', 'Account.Name' });
    if (spec.includeLead)
      columns.addAll(new Set<String>{ 'WhoId', 'Who.Name' });
    if (
      spec.objectApi == 'Task' ||
      spec.objectApi == 'Opportunity' ||
      spec.objectApi == 'Lead' ||
      spec.objectApi == 'Account'
    ) {
      String ownerState = fieldState(spec.objectApi, 'OwnerId');
      if (ownerState == 'available')
        ownerState = fieldState('User', 'Name');
      if (
        ownerState == 'available' &&
        (spec.objectApi == 'Task' ||
        spec.objectApi == 'Lead')
      )
        ownerState = fieldState('Group', 'Name');
      result.fieldStates.put('ownerName', ownerState);
      if (ownerState == 'available')
        columns.add('Owner.Name');
    }
    if (spec.objectApi == 'Opportunity') {
      addOptional(spec.objectApi, 'Amount', 'amount', columns, result);
      addOptional(
        spec.objectApi,
        'CurrencyIsoCode',
        'currency',
        columns,
        result
      );
    }
    if (spec.objectApi == 'Lead' || spec.objectApi == 'Opportunity') {
      addOptional(spec.objectApi, SCORE, 'score', columns, result);
      addOptional(spec.objectApi, BAND, 'band', columns, result);
    }
    if (spec.objectApi == 'Lead')
      addOptional('Lead', 'Company', 'company', columns, result);
    if (spec.objectApi == 'Account') {
      addOptional('Account', 'Sector__c', 'sector', columns, result);
      addOptional('Account', 'BillingState', 'billingState', columns, result);
    }
    String fromWhere = ' FROM ' + spec.objectApi + ' WHERE ' + spec.criterion;
    try {
      // Internal identifiers and clauses only; all external filters use binds.
      List<SObject> records = Database.queryWithBinds(
        'SELECT ' +
          String.join(new List<String>(columns), ', ') +
          fromWhere +
          ' ORDER BY ' +
          spec.orderByClause +
          ' LIMIT ' +
          spec.rowLimit,
        binds,
        AccessLevel.USER_MODE
      );
      // Count the entire authorized selection, independently of the displayed rows.
      result.total = Database.countQueryWithBinds(
        'SELECT COUNT() FROM ' +
          spec.objectApi +
          ' WHERE ' +
          (spec.countCriterion == null ? spec.criterion : spec.countCriterion),
        binds,
        AccessLevel.USER_MODE
      );
      for (SObject record : records) {
        Row row = new Row();
        row.id = (Id) record.get('Id');
        row.label = (String) record.get(spec.nameField);
        if (spec.statusField != null)
          row.status = (String) record.get(spec.statusField);
        if (spec.dateField != null)
          row.relevantDate = (Date) record.get(spec.dateField);
        if (spec.includeAccount) {
          row.accountId = (Id) record.get('AccountId');
          SObject account = record.getSObject('Account');
          if (account != null)
            row.accountName = (String) account.get('Name');
          row.parentId = row.accountId;
          row.parentName = row.accountName;
        }
        if (spec.includeLead) {
          row.parentId = (Id) record.get('WhoId');
          SObject person = record.getSObject('Who');
          if (person != null)
            row.parentName = (String) person.get('Name');
        }
        if (result.fieldStates.get('ownerName') == 'available') {
          SObject owner = record.getSObject('Owner');
          if (owner != null)
            row.ownerName = (String) owner.get('Name');
        }
        if (result.fieldStates.get('company') == 'available')
          row.company = (String) record.get('Company');
        if (result.fieldStates.get('sector') == 'available')
          row.sector = (String) record.get('Sector__c');
        if (result.fieldStates.get('billingState') == 'available')
          row.billingState = (String) record.get('BillingState');
        if (result.fieldStates.get('amount') == 'available')
          row.amount = (Decimal) record.get('Amount');
        if (result.fieldStates.get('currency') == 'available')
          row.currencyCode = (String) record.get('CurrencyIsoCode');
        if (result.fieldStates.get('score') == 'available')
          row.score = (Decimal) record.get(SCORE);
        if (result.fieldStates.get('band') == 'available')
          row.band = (String) record.get(BAND);
        result.rows.add(row);
      }
    } catch (QueryException e) {
      result.rows.clear();
      result.total = null;
      result.errorCode = 'query_failed';
      result.error = 'Não foi possível consultar esta lista com as permissões atuais. Tente atualizar ou contate o administrador.';
    }
    return result;
  }

  private static void addOptional(
    String objectApi,
    String fieldApi,
    String key,
    Set<String> columns,
    Block result
  ) {
    String state = fieldState(objectApi, fieldApi);
    result.fieldStates.put(key, state);
    if (state == 'available')
      columns.add(fieldApi);
  }

  private static String fieldState(String objectApi, String path) {
    if (path.startsWith('Lead.'))
      return fieldState('Lead', path.substring(5));
    if (path.startsWith('Account.'))
      return fieldState('Account', path.substring(8));
    if (!OBJECTS.containsKey(objectApi))
      return 'missing';
    Schema.DescribeSObjectResult objectInfo = OBJECTS.get(objectApi)
      .getDescribe();
    if (!objectInfo.isAccessible())
      return 'no_access';
    Map<String, Schema.SObjectField> fields = objectInfo.fields.getMap();
    if (!fields.containsKey(path))
      return 'missing';
    return fields.get(path).getDescribe().isAccessible()
      ? 'available'
      : 'no_access';
  }

  private static void validateId(
    Id value,
    Set<Schema.SObjectType> allowed,
    String message
  ) {
    if (value != null && !allowed.contains(value.getSObjectType()))
      throw new AuraHandledException(message);
  }

  private static Date monthStart(String monthKey, Date today) {
    if (String.isBlank(monthKey))
      return Date.newInstance(today.year(), today.month(), 1);
    if (
      !Pattern.compile('[0-9]{4}-(0[1-9]|1[0-2])').matcher(monthKey).matches()
    ) {
      throw new AuraHandledException(
        'Informe o mês de referência no formato AAAA-MM.'
      );
    }
    Integer year = Integer.valueOf(monthKey.substring(0, 4));
    if (year < 2000 || year > 2099)
      throw new AuraHandledException('Informe um ano entre 2000 e 2099.');
    return Date.newInstance(year, Integer.valueOf(monthKey.substring(5, 7)), 1);
  }
}