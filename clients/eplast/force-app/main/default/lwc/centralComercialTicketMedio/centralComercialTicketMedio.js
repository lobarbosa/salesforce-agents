import { api } from "lwc";
import LightningModal from "lightning/modal";
import getTicketMedio from "@salesforce/apex/CentralComercialV1Controller.getTicketMedio";

const NUMBER = new Intl.NumberFormat("pt-BR");
const MONTH = new Intl.DateTimeFormat("pt-BR", {
  month: "short",
  year: "numeric",
  timeZone: "UTC"
});

function localToday() {
  const now = new Date();
  return `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, "0")}-${String(now.getDate()).padStart(2, "0")}`;
}
function dateLabel(date) {
  return date?.split("-").reverse().join("/");
}

export default class CentralComercialTicketMedio extends LightningModal {
  @api referenceDate;
  startDate;
  endDate;
  loading = false;
  error;
  result;
  dirty = false;
  request = 0;

  connectedCallback() {
    this.endDate = this.referenceDate || localToday();
    this.startDate = `${this.endDate.slice(0, 4)}-01-01`;
  }
  disconnectedCallback() {
    this.request += 1;
  }
  handleStart(event) {
    this.startDate = event.target.value;
    this.dirty = !!this.result;
    this.error = undefined;
  }
  handleEnd(event) {
    this.endDate = event.target.value;
    this.dirty = !!this.result;
    this.error = undefined;
  }
  async consult() {
    if (this.loading) return;
    const inputs = [...this.template.querySelectorAll("lightning-input")];
    const valid = inputs.map((input) => input.reportValidity()).every(Boolean);
    if (!valid || !this.startDate || !this.endDate) return;
    if (this.endDate < this.startDate) {
      this.error = "A data final deve ser igual ou posterior à data inicial.";
      return;
    }
    const monthSpan =
      (Number(this.endDate.slice(0, 4)) - Number(this.startDate.slice(0, 4))) *
        12 +
      Number(this.endDate.slice(5, 7)) -
      Number(this.startDate.slice(5, 7));
    if (monthSpan >= 24) {
      this.error = "Consulte até 24 meses por vez.";
      return;
    }
    const request = ++this.request;
    this.loading = true;
    this.error = undefined;
    this.result = undefined;
    try {
      const result = JSON.parse(
        await getTicketMedio({
          startDate: this.startDate,
          endDate: this.endDate
        })
      );
      if (request !== this.request) return;
      if (result.error) this.error = result.error;
      else {
        this.result = result;
        this.dirty = false;
      }
    } catch (error) {
      if (request === this.request) {
        this.error =
          error?.body?.message ||
          "Não foi possível consultar o Ticket Médio. Tente novamente.";
      }
    } finally {
      if (request === this.request) this.loading = false;
    }
  }
  closeAnalysis() {
    this.close();
  }
  money(value) {
    if (value == null) return "Sem valor";
    return new Intl.NumberFormat("pt-BR", {
      style: "currency",
      currency: this.result.currencyCode
    }).format(value);
  }
  get hasResult() {
    return !!this.result;
  }
  get unqueried() {
    return !this.result && !this.loading && !this.error;
  }
  get hasIncluded() {
    return (this.result?.includedCount || 0) > 0;
  }
  get averageLabel() {
    return this.money(this.result?.averageAmount);
  }
  get totalLabel() {
    return this.money(this.result?.totalAmount);
  }
  get countLabel() {
    return NUMBER.format(this.result?.includedCount || 0);
  }
  get criterion() {
    return `Oportunidades ganhas · Fechamento de ${dateLabel(this.result?.startDate)} a ${dateLabel(this.result?.endDate)} · Todos os registros acessíveis · ${this.result?.currencyCode}`;
  }
  get missingNote() {
    const count = this.result?.withoutAmountCount || 0;
    return count > 0
      ? `${NUMBER.format(count)} oportunidade(s) ganha(s) sem valor informado foram excluídas do cálculo. Valor zero participa da média.`
      : "Valor zero participa da média. Oportunidades sem valor informado são excluídas.";
  }
  get emptyMessage() {
    return this.result?.wonCount > 0
      ? "Há oportunidades ganhas neste período, mas nenhuma tem valor informado para calcular o Ticket Médio."
      : "Nenhuma oportunidade ganha acessível com fechamento neste período.";
  }
  get bars() {
    const months = this.result?.months || [];
    const values = months.map((month) => Number(month.averageAmount || 0));
    const positive = Math.max(0, ...values);
    const negative = Math.max(0, ...values.map((value) => -value));
    const range = positive + negative || 1;
    const origin = (negative / range) * 100;
    return months.map((month) => {
      const value = Number(month.averageAmount || 0);
      const label = MONTH.format(new Date(`${month.monthKey}-01T00:00:00Z`));
      const amountLabel =
        month.averageAmount == null
          ? "Sem valor"
          : this.money(month.averageAmount);
      const countLabel = NUMBER.format(month.includedCount);
      const width = (Math.abs(value) / range) * 100;
      return {
        ...month,
        label,
        amountLabel,
        countLabel,
        hasValue: month.averageAmount != null,
        description: `${label}: ${amountLabel}; ${countLabel} oportunidades com valor informado.`,
        barStyle: `left: ${value < 0 ? origin - width : origin}%; width: ${width}%;`,
        originStyle: `left: ${origin}%;`,
        barClass: value < 0 ? "bar negative" : "bar"
      };
    });
  }
}