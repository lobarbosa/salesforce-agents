import { LightningElement } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import getFilterMetadata from "@salesforce/apex/CentralComercialV1Controller.getFilterMetadata";
import getDirectory from "@salesforce/apex/CentralComercialV1Controller.getDirectory";
import getRelatedRecords from "@salesforce/apex/CentralComercialV1Controller.getRelatedRecords";
import getSegmentRelatedRecords from "@salesforce/apex/CentralComercialV1Controller.getSegmentRelatedRecords";
import TicketMedioModal from "c/centralComercialTicketMedio";

const NUMBER = new Intl.NumberFormat("pt-BR");
const MONEY = new Intl.NumberFormat("pt-BR", {
  minimumFractionDigits: 2,
  maximumFractionDigits: 2
});
const MONTH = new Intl.DateTimeFormat("pt-BR", {
  month: "long",
  year: "numeric",
  timeZone: "UTC"
});
const RELATED = {
  Opportunity: {
    title: "Oportunidades",
    dateLabel: "Fechamento previsto",
    owner: true,
    status: true,
    amount: true,
    score: true
  },
  Task: {
    title: "Tarefas",
    dateLabel: "Vencimento",
    owner: true,
    status: true
  },
  Order: {
    title: "Pedidos",
    dateLabel: "Data previsão de vendas",
    status: true
  },
  Contact: { title: "Contatos" }
};
function valueLabel(value, state, empty = "Sem valor") {
  if (state === "no_access") return "Sem acesso";
  if (state === "missing") return "Indisponível";
  return value == null || value === "" ? empty : value;
}
function formatRow(row, object, states = {}) {
  return {
    ...row,
    object,
    label: row.label || (object === "Task" ? "Tarefa sem assunto" : "Sem nome"),
    recordUrl: `/lightning/r/${object}/${row.id}/view`,
    ownerLabel: valueLabel(row.ownerName, states.ownerName),
    sectorLabel: valueLabel(row.sector, states.sector),
    stateLabel: valueLabel(row.billingState, states.billingState),
    companyLabel: valueLabel(row.company, states.company),
    scoreLabel: valueLabel(
      row.score == null ? null : NUMBER.format(row.score),
      states.score,
      "Sem score"
    ),
    bandLabel: valueLabel(row.band, states.band),
    statusLabel: row.status || "Sem valor",
    dateLabel: row.relevantDate
      ? row.relevantDate.split("-").reverse().join("/")
      : object === "Task"
        ? "Sem vencimento"
        : "Sem data",
    amountLabel: valueLabel(
      row.amount == null
        ? null
        : [row.currencyCode, MONEY.format(row.amount)]
            .filter(Boolean)
            .join(" "),
      states.amount
    )
  };
}
function errorMessage(error, fallback) {
  return error?.body?.message || fallback;
}
function coverage(data, history) {
  if (data?.block?.total == null) return "";
  const size = data.block.rows?.length || 0;
  const first = size ? (history.length - 1) * 20 + 1 : 0;
  return `${NUMBER.format(first)}–${NUMBER.format(first + Math.max(size - 1, 0))} de ${NUMBER.format(data.block.total)} registros`;
}

export default class CentralComercial extends NavigationMixin(
  LightningElement
) {
  metadata;
  dashboardUrl = "/lightning/r/Dashboard/01ZbJ000000OFifUAG/view";
  analysisOpening = false;
  priorityExplanation =
    "Score indica a prioridade de atendimento: quanto maior, maior a prioridade.";
  leadScoreHelp =
    "Pontuação calculada pelo Engajamento (Marketing Cloud): Alto, Médio ou Baixo. Os pontos são definidos na configuração de prioridades da organização. Sem engajamento preenchido, o Score é 0.";
  leadBandHelp =
    "Usa as faixas AA, A, B, C e D, conforme os limites definidos na configuração de prioridades. Sem engajamento preenchido, a Faixa é Não classificado.";
  opportunityScoreHelp =
    "Considera Discovery Completed, Budget Confirmed, fase comercial avançada, Última atividade recente e Próxima etapa preenchida. Os pesos e o prazo de atividade recente vêm da configuração de prioridades. Oportunidades encerradas recebem Score 0.";
  opportunityBandHelp =
    "Usa as faixas AA, A, B, C e D, conforme os limites definidos na configuração de prioridades. Oportunidades encerradas recebem a Faixa Não classificado.";
  metadataError;
  metadataLoading = false;
  entityType = "Account";
  mine = true;
  nameSearch = "";
  billingState = "";
  accountSector = "";
  leadStatus = "__ACTIVE__";
  ownerId = null;
  directory;
  directoryLoading = false;
  directoryError;
  directoryDirty = false;
  directoryHistory = [null];
  appliedDirectory;
  directoryRequest = 0;
  draftRevision = 0;
  selectedEntity;
  relatedType = "Opportunity";
  datePreset = "all";
  monthKey;
  recordScope = "open";
  related;
  relatedLoading = false;
  relatedError;
  relatedDirty = false;
  relatedHistory = [null];
  appliedRelated;
  relatedRequest = 0;
  relatedRevision = 0;
  activeUserFilter = {
    criteria: [{ fieldPath: "IsActive", operator: "eq", value: true }]
  };

  connectedCallback() {
    this.loadMetadata();
    this.prepareDashboardLink();
  }
  async prepareDashboardLink() {
    try {
      const url = await this[NavigationMixin.GenerateUrl]({
        type: "standard__recordPage",
        attributes: {
          recordId: "01ZbJ000000OFifUAG",
          objectApiName: "Dashboard",
          actionName: "view"
        }
      });
      if (url) this.dashboardUrl = url;
    } catch {
      // The same-org record link remains usable if URL generation is unavailable.
    }
  }
  async openTicketMedio() {
    if (this.analysisOpening) return;
    this.analysisOpening = true;
    try {
      await TicketMedioModal.open({
        size: "large",
        description:
          "Análise de Ticket Médio de oportunidades ganhas por fechamento",
        referenceDate: this.metadata?.today
      });
    } finally {
      this.analysisOpening = false;
    }
  }
  async loadMetadata() {
    this.metadataLoading = true;
    this.metadataError = undefined;
    try {
      this.metadata = JSON.parse(await getFilterMetadata());
      this.monthKey = this.monthKey || this.metadata.today.slice(0, 7);
    } catch (error) {
      this.metadataError = errorMessage(
        error,
        "Não foi possível carregar as opções dos filtros."
      );
    } finally {
      this.metadataLoading = false;
    }
  }
  get isAccount() {
    return this.entityType === "Account";
  }
  get isLead() {
    return this.entityType === "Lead";
  }
  get entityOptions() {
    return [
      { label: "Clientes", value: "Account" },
      { label: "Leads", value: "Lead" }
    ];
  }
  get directoryTitle() {
    return this.isAccount ? "Clientes encontrados" : "Leads encontrados";
  }
  get ownerLabel() {
    return this.isAccount ? "Vendedor da conta" : "Responsável pelo lead";
  }
  get scopeValue() {
    return this.mine ? "mine" : "all";
  }
  get scopeOptions() {
    return this.isAccount
      ? [
          { label: "Minhas contas", value: "mine" },
          { label: "Todas as contas acessíveis", value: "all" }
        ]
      : [
          { label: "Meus leads", value: "mine" },
          { label: "Todos os leads acessíveis", value: "all" }
        ];
  }
  get sectorOptions() {
    return [
      { label: "Todos os setores", value: "" },
      ...(this.metadata?.accountSectors || [])
    ];
  }
  get sectorDisabled() {
    return this.metadata?.accountSectorState !== "available";
  }
  get sectorNote() {
    return this.metadata?.accountSectorState === "no_access"
      ? "Sem acesso ao setor da conta."
      : "";
  }
  get leadStatusOptions() {
    return [
      { label: "Em atendimento", value: "__ACTIVE__" },
      { label: "Todos os não convertidos", value: "" },
      ...(this.metadata?.leadStatuses || [])
    ];
  }
  get searchDisabled() {
    return !this.metadata || this.metadataLoading || this.directoryLoading;
  }
  get hasDirectory() {
    return Boolean(this.directory);
  }
  get directoryBlockError() {
    return this.directory?.block?.error;
  }
  get directoryRows() {
    return (this.directory?.block?.rows || []).map((row) => ({
      ...formatRow(row, this.entityType, this.directory?.block?.fieldStates),
      className: row.id === this.selectedEntity?.id ? "selected-row" : ""
    }));
  }
  get hasDirectoryRows() {
    return this.directoryRows.length > 0;
  }
  get directoryCoverage() {
    return coverage(this.directory, this.directoryHistory);
  }
  get directorySortNote() {
    if (this.isAccount)
      return "Contas ordenadas por nome. Selecione uma para explorar os relacionados.";
    return this.directory?.block?.fieldStates?.score === "available"
      ? "Score em ordem decrescente; faixa oficial da organização. Leads convertidos ficam fora desta lista."
      : "Score indisponível para este acesso; ordenação por nome. Leads convertidos ficam fora desta lista.";
  }
  get previousDirectoryDisabled() {
    return (
      this.directoryLoading ||
      this.directoryDirty ||
      this.directoryHistory.length <= 1
    );
  }
  get nextDirectoryDisabled() {
    return (
      this.directoryLoading ||
      this.directoryDirty ||
      !this.directory?.nextCursor
    );
  }
  get hasSelection() {
    return Boolean(this.selectedEntity);
  }
  get isSegment() {
    return this.selectedEntity?.segment === true;
  }
  get segmentDisabled() {
    return (
      this.directoryLoading || this.directoryDirty || !this.hasDirectoryRows
    );
  }
  get segmentHelp() {
    return this.isAccount
      ? "Recorte é o conjunto de contas retornado pelos filtros da última busca. Esta ação permite consultar oportunidades, tarefas, pedidos e contatos de todas essas contas, inclusive as de outras páginas."
      : "Recorte é o conjunto de leads retornado pelos filtros da última busca. Esta ação permite consultar as tarefas de todos esses leads, inclusive os de outras páginas.";
  }
  get segmentHint() {
    return this.isAccount
      ? "Consulte os relacionados de todas as contas da última busca, inclusive as de outras páginas."
      : "Consulte as tarefas de todos os leads da última busca, inclusive os de outras páginas.";
  }
  get parentColumnLabel() {
    return this.selectedEntity?.object === "Lead" ? "Lead" : "Cliente";
  }
  get selectedUrl() {
    return this.selectedEntity
      ? `/lightning/r/${this.selectedEntity.object}/${this.selectedEntity.id}/view`
      : "";
  }
  get relatedOptions() {
    return this.selectedEntity?.object === "Lead"
      ? [{ label: "Tarefas", value: "Task" }]
      : Object.entries(RELATED).map(([value, item]) => ({
          value,
          label: item.title
        }));
  }
  get relatedConfig() {
    return RELATED[this.relatedType];
  }
  get hasDateFilter() {
    return this.relatedType !== "Contact";
  }
  get hasStatusFilter() {
    return this.relatedType !== "Contact";
  }
  get dateOptions() {
    const options = [
      { label: "Sem filtro de período", value: "all" },
      { label: "No mês selecionado", value: "month" }
    ];
    if (this.relatedType === "Task")
      options.push(
        { label: "Vencimento anterior a hoje", value: "overdue" },
        { label: "Vencimento hoje", value: "today" },
        { label: "Vencimento nos próximos 7 dias", value: "next7" }
      );
    if (this.relatedType === "Opportunity")
      options.push({
        label: "Fechamento previsto anterior a hoje",
        value: "overdue"
      });
    return options;
  }
  get showMonth() {
    return this.hasDateFilter && this.datePreset === "month";
  }
  get monthOptions() {
    if (!this.metadata?.today) return [];
    const [year, month] = this.metadata.today.split("-").map(Number);
    return Array.from({ length: 25 }, (_, index) => {
      const date = new Date(Date.UTC(year, month - 1 + 12 - index, 1));
      return {
        label: MONTH.format(date),
        value: date.toISOString().slice(0, 7)
      };
    });
  }
  get relatedScopeOptions() {
    if (this.relatedType === "Order")
      return [
        { label: "Todos os status", value: "" },
        ...(this.metadata?.orderStatuses || [])
      ];
    return this.relatedType === "Task"
      ? [
          { label: "Abertas", value: "open" },
          { label: "Concluídas", value: "closed" },
          { label: "Todas", value: "all" }
        ]
      : [
          { label: "Em aberto", value: "open" },
          { label: "Encerradas", value: "closed" },
          { label: "Todas", value: "all" }
        ];
  }
  get relatedRows() {
    return (this.related?.block?.rows || []).map((row) =>
      formatRow(
        row,
        this.appliedRelated?.relatedType || this.relatedType,
        this.related?.block?.fieldStates
      )
    );
  }
  get hasRelated() {
    return Boolean(this.related);
  }
  get hasRelatedRows() {
    return this.relatedRows.length > 0;
  }
  get relatedBlockError() {
    return this.related?.block?.error;
  }
  get relatedCriterion() {
    return this.related?.block?.criterion;
  }
  get relatedCoverage() {
    return coverage(this.related, this.relatedHistory);
  }
  get previousRelatedDisabled() {
    return (
      this.relatedLoading ||
      this.relatedDirty ||
      this.relatedHistory.length <= 1
    );
  }
  get nextRelatedDisabled() {
    return (
      this.relatedLoading || this.relatedDirty || !this.related?.nextCursor
    );
  }

  markDirectoryDirty() {
    this.draftRevision++;
    this.directoryDirty = Boolean(this.directory);
  }
  handleEntityType(event) {
    this.entityType = event.detail.value;
    this.directoryRequest++;
    this.directoryLoading = false;
    this.directory = undefined;
    this.directoryError = undefined;
    this.directoryDirty = false;
    this.directoryHistory = [null];
    this.markDirectoryDirty();
    this.clearSelection();
  }
  handleScope(event) {
    this.mine = event.detail.value === "mine";
    if (this.mine) this.ownerId = null;
    this.markDirectoryDirty();
  }
  handleName(event) {
    this.nameSearch = event.target.value;
    this.markDirectoryDirty();
  }
  handleState(event) {
    this.billingState = event.target.value;
    this.markDirectoryDirty();
  }
  handleSector(event) {
    this.accountSector = event.detail.value;
    this.markDirectoryDirty();
  }
  handleOwner(event) {
    this.ownerId = event.detail.recordId || null;
    if (this.ownerId) this.mine = false;
    this.markDirectoryDirty();
  }
  handleLeadStatus(event) {
    this.leadStatus = event.detail.value;
    this.markDirectoryDirty();
  }
  searchDirectory() {
    const filters = {
      entityType: this.entityType,
      mine: this.mine,
      nameSearch: this.nameSearch || null,
      billingState: this.isAccount ? this.billingState || null : null,
      accountSector: this.isAccount ? this.accountSector || null : null,
      leadStatus: this.isAccount ? null : this.leadStatus,
      ownerId: this.ownerId
    };
    return this.loadDirectory(filters, [null]);
  }
  async loadDirectory(filters, history) {
    const request = ++this.directoryRequest;
    const revision = this.draftRevision;
    this.directoryLoading = true;
    this.directoryError = undefined;
    try {
      const data = JSON.parse(
        await getDirectory({
          ...filters,
          cursorToken: history[history.length - 1]
        })
      );
      if (request !== this.directoryRequest) return;
      this.directory = data;
      this.appliedDirectory = { ...filters };
      this.directoryHistory = history;
      this.directoryDirty = revision !== this.draftRevision;
      this.clearSelection();
    } catch (error) {
      if (request === this.directoryRequest)
        this.directoryError = errorMessage(
          error,
          "Não foi possível buscar os registros. Confira os filtros e seu acesso."
        );
    } finally {
      if (request === this.directoryRequest) this.directoryLoading = false;
    }
  }
  nextDirectory() {
    return this.loadDirectory(this.appliedDirectory, [
      ...this.directoryHistory,
      this.directory.nextCursor
    ]);
  }
  previousDirectory() {
    return this.loadDirectory(
      this.appliedDirectory,
      this.directoryHistory.slice(0, -1)
    );
  }
  selectEntity(event) {
    const row = this.directoryRows.find(
      (item) => item.id === event.currentTarget.dataset.id
    );
    if (!row) return undefined;
    const sameType = this.selectedEntity?.object === this.entityType;
    this.selectedEntity = {
      id: row.id,
      label: row.label,
      object: this.entityType
    };
    if (!sameType) {
      this.relatedType = this.isAccount ? "Opportunity" : "Task";
      this.datePreset = "all";
      this.recordScope = "open";
    }
    this.related = undefined;
    return this.searchRelated();
  }
  selectSegment() {
    this.selectedEntity = {
      id: null,
      label: `${NUMBER.format(this.directory.block.total)} ${this.isAccount ? "contas" : "leads"} do recorte consultado`,
      object: this.entityType,
      segment: true
    };
    this.relatedType = this.isAccount ? "Opportunity" : "Task";
    this.datePreset = "all";
    this.recordScope = "open";
    this.related = undefined;
    return this.searchRelated();
  }
  selectRelatedParent(event) {
    const row = this.relatedRows.find(
      (item) => item.parentId === event.currentTarget.dataset.id
    );
    if (!row) return undefined;
    this.selectedEntity = {
      id: row.parentId,
      label: row.parentName,
      object: this.selectedEntity.object
    };
    return this.searchRelated();
  }
  clearSelection() {
    this.relatedRequest++;
    this.selectedEntity = undefined;
    this.related = undefined;
    this.relatedError = undefined;
    this.relatedLoading = false;
    this.relatedDirty = false;
    this.relatedHistory = [null];
  }
  handleRelatedType(event) {
    this.relatedType = event.detail.value;
    this.recordScope = this.relatedType === "Order" ? "" : "open";
    if (!this.dateOptions.some((option) => option.value === this.datePreset))
      this.datePreset = "all";
    if (this.relatedType === "Contact") this.datePreset = "all";
    this.related = undefined;
    return this.searchRelated();
  }
  markRelatedDirty() {
    this.relatedRevision++;
    this.relatedDirty = Boolean(this.related);
  }
  handleDatePreset(event) {
    this.datePreset = event.detail.value;
    this.markRelatedDirty();
  }
  handleMonth(event) {
    this.monthKey = event.detail.value;
    this.markRelatedDirty();
  }
  handleRecordScope(event) {
    this.recordScope = event.detail.value;
    this.markRelatedDirty();
  }
  searchRelated() {
    if (!this.selectedEntity) return undefined;
    return this.loadRelated(
      {
        parentId: this.selectedEntity.id,
        directoryFilters: this.isSegment
          ? JSON.stringify(this.appliedDirectory)
          : null,
        relatedType: this.relatedType,
        datePreset: this.datePreset,
        monthKey: this.datePreset === "month" ? this.monthKey : null,
        recordScope: this.relatedType === "Contact" ? null : this.recordScope
      },
      [null]
    );
  }
  async loadRelated(filters, history) {
    const request = ++this.relatedRequest;
    const revision = this.relatedRevision;
    this.relatedLoading = true;
    this.relatedError = undefined;
    try {
      const { directoryFilters, parentId, ...selection } = filters;
      const paging = { ...selection, cursorToken: history[history.length - 1] };
      const data = JSON.parse(
        await (directoryFilters
          ? getSegmentRelatedRecords({ ...paging, directoryFilters })
          : getRelatedRecords({ ...paging, parentId }))
      );
      if (request !== this.relatedRequest) return;
      this.related = data;
      this.appliedRelated = { ...filters };
      this.relatedHistory = history;
      this.relatedDirty = revision !== this.relatedRevision;
    } catch (error) {
      if (request === this.relatedRequest)
        this.relatedError = errorMessage(
          error,
          "Não foi possível consultar os relacionados deste registro."
        );
    } finally {
      if (request === this.relatedRequest) this.relatedLoading = false;
    }
  }
  nextRelated() {
    return this.loadRelated(this.appliedRelated, [
      ...this.relatedHistory,
      this.related.nextCursor
    ]);
  }
  previousRelated() {
    return this.loadRelated(
      this.appliedRelated,
      this.relatedHistory.slice(0, -1)
    );
  }
  openRecord(event) {
    if (event.ctrlKey || event.metaKey || event.shiftKey || event.altKey)
      return;
    event.preventDefault();
    const { id, object } = event.currentTarget.dataset;
    this[NavigationMixin.Navigate]({
      type: "standard__recordPage",
      attributes: { recordId: id, objectApiName: object, actionName: "view" }
    });
  }
}