/**
 * MeetingSummaryService (EPLAST-34)
 *
 * Acao invocavel do SFAgent2 (topico insights_comerciais) que monta o resumo para as
 * reunioes Comercial, GDD, S&OP e Board. Os numeros saem de SOQL agregado (COUNT, SUM,
 * GROUP BY) em USER_MODE; o texto e montado aqui, nunca pelo modelo (PA-03).
 *
 * Somente leitura: nao faz DML, callout, @future, Queueable nem envio de e-mail.
 * Le Opportunity e Order (campos padrao). Nao le Contact, Lead, e-mail, telefone ou documento.
 *
 * with sharing: o resumo respeita a visibilidade de quem pergunta (design secao 6, PA-07).
 *
 * Premissas (03-design.md secao 10): PD-01 equipe = vendedor (OwnerId); PD-02 top 20 contas;
 * PD-03 BRL sem conversao; PD-04 aberta = IsClosed false com CloseDate no periodo;
 * PD-05 todos os status de pedido com EffectiveDate no periodo; PD-06 teto de linhas;
 * PD-10 periodo maximo. Cada uma e constante abaixo, facil de mudar.
 */
public with sharing class MeetingSummaryService {

    // PD-02
    @TestVisible private static final Integer TOP_CONTAS = 20;
    // PD-10
    @TestVisible private static final Integer PERIODO_MAXIMO_DIAS = 366;
    // PD-06 (80% do limite de 50.000 linhas)
    @TestVisible private static Integer tetoLinhas = 40000;
    // Somente teste: forca o caminho de erro inesperado.
    @TestVisible private static Boolean forcarErro = false;

    public static final String TIPO_COMERCIAL = 'COMERCIAL';
    public static final String TIPO_GDD = 'GDD';
    public static final String TIPO_SOP = 'SOP';
    public static final String TIPO_BOARD = 'BOARD';

    public static final String ST_OK = 'OK';
    public static final String ST_VAZIO = 'VAZIO';
    public static final String ST_SEM_ACESSO = 'SEM_ACESSO';
    public static final String ST_VOLUME = 'VOLUME_EXCEDIDO';
    public static final String ST_PARCIAL = 'PARCIAL';
    public static final String ST_ERRO = 'ERRO';

    public class MeetingSummaryRequest {
        @InvocableVariable(label='Tipo de reuniao' description='COMERCIAL, GDD, SOP ou BOARD' required=true)
        public String tipo;
        @InvocableVariable(label='Data inicial' description='Opcional. Sem data, usa o mes corrente.')
        public Date dataInicio;
        @InvocableVariable(label='Data final' description='Opcional. Sem data, usa o mes corrente.')
        public Date dataFim;
    }

    public class MeetingSummaryResult {
        @InvocableVariable(label='Status' description='OK, PARCIAL, SEM_ACESSO ou ERRO')
        public String status;
        @InvocableVariable(label='Texto do resumo' description='Mostrar como veio, sem recalcular nem reescrever numeros.')
        public String textoResumo;
        @InvocableVariable(label='Data e hora de corte')
        public Datetime dataHoraCorte;
    }

    @TestVisible
    private class Secao {
        String titulo;
        String status = ST_OK;
        String mensagem;
        List<String> linhas = new List<String>();
        Secao(String titulo) { this.titulo = titulo; }
    }

    private class Contexto {
        Date inicio;
        Date fim;
        Integer linhasUsadas = 0;
    }

    @InvocableMethod(
        label='Resumo de reuniao'
        description='Resumo de numeros para reuniao Comercial, GDD, S&OP ou Board, calculado por consulta agregada.'
    )
    public static List<MeetingSummaryResult> resumir(List<MeetingSummaryRequest> requests) {
        List<MeetingSummaryResult> resultados = new List<MeetingSummaryResult>();
        if (requests == null) {
            return resultados;
        }
        for (MeetingSummaryRequest req : requests) {
            if (Limits.getQueries() + 15 > Limits.getLimitQueries()) {
                resultados.add(erro('Limite de consultas da transacao atingido. Peca um resumo por vez.'));
                continue;
            }
            try {
                resultados.add(gerar(req));
            } catch (Exception e) {
                resultados.add(erro('Nao foi possivel gerar o resumo: ' + e.getMessage()));
            }
        }
        return resultados;
    }

    private static MeetingSummaryResult gerar(MeetingSummaryRequest req) {
        if (forcarErro) {
            throw new IllegalArgumentException('erro forcado em teste');
        }
        String tipo = normalizarTipo(req == null ? null : req.tipo);
        if (tipo == null) {
            return erro('Tipo de reuniao invalido. Use COMERCIAL, GDD, SOP ou BOARD.');
        }
        Contexto ctx = new Contexto();
        String erroPeriodo = definirPeriodo(ctx, req.dataInicio, req.dataFim);
        if (erroPeriodo != null) {
            return erro(erroPeriodo);
        }
        Datetime corte = Datetime.now();

        List<Secao> secoes = new List<Secao>();
        if (tipo == TIPO_COMERCIAL) {
            secoes.add(oppPorEtapa(ctx));
            secoes.add(oppPorVendedor(ctx, '2) Oportunidades abertas por vendedor'));
        } else if (tipo == TIPO_GDD) {
            secoes.add(oppPorConta(ctx));
            secoes.add(pedidosPorConta(ctx));
        } else if (tipo == TIPO_SOP) {
            Secao porStatus = pedidosPorStatus(ctx);
            secoes.add(porStatus);
            secoes.add(pedidosTotal(ctx));
        } else {
            secoes.add(oppPorVendedor(ctx, '1) Pipeline aberto por vendedor'));
            secoes.add(pedidosPorVendedor(ctx));
            secoes.add(totalGeral(ctx));
        }
        return montar(tipo, ctx, secoes, corte);
    }

    // ---------- Normalizacao e periodo ----------

    @TestVisible
    private static String normalizarTipo(String bruto) {
        if (String.isBlank(bruto)) {
            return null;
        }
        String t = bruto.trim().toUpperCase().replace('&', '').replace('/', '').replace(' ', '');
        if (t == TIPO_COMERCIAL || t == TIPO_GDD || t == TIPO_SOP || t == TIPO_BOARD) {
            return t;
        }
        return null;
    }

    private static String definirPeriodo(Contexto ctx, Date ini, Date fim) {
        if (ini == null && fim == null) {
            ini = Date.today().toStartOfMonth();
            fim = ini.addMonths(1).addDays(-1);
        } else if (fim == null) {
            fim = ini.toStartOfMonth().addMonths(1).addDays(-1);
        } else if (ini == null) {
            ini = fim.toStartOfMonth();
        }
        if (ini > fim) {
            return 'A data inicial e posterior a data final.';
        }
        if (ini.daysBetween(fim) + 1 > PERIODO_MAXIMO_DIAS) {
            return 'Periodo maior que ' + PERIODO_MAXIMO_DIAS + ' dias. Informe um periodo menor.';
        }
        ctx.inicio = ini;
        ctx.fim = fim;
        return null;
    }

    // ---------- Secoes ----------

    private static Secao oppPorEtapa(Contexto ctx) {
        Secao s = new Secao('1) Oportunidades abertas por etapa (Opportunity.StageName, Opportunity.Amount)');
        if (!Schema.sObjectType.Opportunity.isAccessible()) { return semAcesso(s, 'Opportunity'); }
        try {
            if (excedeVolume(s, ctx, contarOpp(ctx.inicio, ctx.fim))) { return s; }
            List<AggregateResult> rs = [
                SELECT StageName etapa, COUNT(Id) qtd, SUM(Amount) valor
                FROM Opportunity
                WHERE IsClosed = false AND CloseDate >= :ctx.inicio AND CloseDate <= :ctx.fim
                WITH USER_MODE
                GROUP BY StageName
                ORDER BY StageName
            ];
            for (AggregateResult r : rs) {
                s.linhas.add(String.valueOf(r.get('etapa')) + ': ' + r.get('qtd') + ' oportunidade(s), ' + moeda((Decimal) r.get('valor')));
            }
            return fechar(s);
        } catch (QueryException e) {
            return semAcesso(s, 'Opportunity');
        }
    }

    private static Secao oppPorVendedor(Contexto ctx, String titulo) {
        Secao s = new Secao(titulo + ' (Opportunity.OwnerId, Opportunity.Amount)');
        if (!Schema.sObjectType.Opportunity.isAccessible()) { return semAcesso(s, 'Opportunity'); }
        try {
            if (excedeVolume(s, ctx, contarOpp(ctx.inicio, ctx.fim))) { return s; }
            List<AggregateResult> rs = [
                SELECT OwnerId dono, Owner.Name nome, COUNT(Id) qtd, SUM(Amount) valor
                FROM Opportunity
                WHERE IsClosed = false AND CloseDate >= :ctx.inicio AND CloseDate <= :ctx.fim
                WITH USER_MODE
                GROUP BY OwnerId, Owner.Name
                ORDER BY SUM(Amount) DESC NULLS LAST
            ];
            for (AggregateResult r : rs) {
                s.linhas.add(String.valueOf(r.get('nome')) + ': ' + r.get('qtd') + ' oportunidade(s), ' + moeda((Decimal) r.get('valor')));
            }
            return fechar(s);
        } catch (QueryException e) {
            return semAcesso(s, 'Opportunity');
        }
    }

    private static Secao oppPorConta(Contexto ctx) {
        Secao s = new Secao('1) Oportunidades abertas por conta (Opportunity.AccountId, Opportunity.Amount)');
        if (!Schema.sObjectType.Opportunity.isAccessible()) { return semAcesso(s, 'Opportunity'); }
        try {
            if (excedeVolume(s, ctx, contarOpp(ctx.inicio, ctx.fim))) { return s; }
            List<AggregateResult> rs = [
                SELECT AccountId conta, Account.Name nome, COUNT(Id) qtd, SUM(Amount) valor
                FROM Opportunity
                WHERE IsClosed = false AND CloseDate >= :ctx.inicio AND CloseDate <= :ctx.fim
                WITH USER_MODE
                GROUP BY AccountId, Account.Name
                ORDER BY SUM(Amount) DESC NULLS LAST
                LIMIT :TOP_CONTAS
            ];
            AggregateResult total = [
                SELECT COUNT(Id) qtd, SUM(Amount) valor
                FROM Opportunity
                WHERE IsClosed = false AND CloseDate >= :ctx.inicio AND CloseDate <= :ctx.fim
                WITH USER_MODE
            ];
            return listarTopContas(s, rs, total);
        } catch (QueryException e) {
            return semAcesso(s, 'Opportunity');
        }
    }

    private static Secao pedidosPorConta(Contexto ctx) {
        Secao s = new Secao('2) Pedidos no periodo por conta (Order.AccountId, Order.TotalAmount)');
        if (!Schema.sObjectType.Order.isAccessible()) { return semAcesso(s, 'Order'); }
        try {
            if (excedeVolume(s, ctx, contarOrder(ctx.inicio, ctx.fim))) { return s; }
            List<AggregateResult> rs = [
                SELECT AccountId conta, Account.Name nome, COUNT(Id) qtd, SUM(TotalAmount) valor
                FROM Order
                WHERE EffectiveDate >= :ctx.inicio AND EffectiveDate <= :ctx.fim
                WITH USER_MODE
                GROUP BY AccountId, Account.Name
                ORDER BY SUM(TotalAmount) DESC NULLS LAST
                LIMIT :TOP_CONTAS
            ];
            AggregateResult total = [
                SELECT COUNT(Id) qtd, SUM(TotalAmount) valor
                FROM Order
                WHERE EffectiveDate >= :ctx.inicio AND EffectiveDate <= :ctx.fim
                WITH USER_MODE
            ];
            return listarTopContas(s, rs, total);
        } catch (QueryException e) {
            return semAcesso(s, 'Order');
        }
    }

    private static Secao pedidosPorStatus(Contexto ctx) {
        Secao s = new Secao('1) Pedidos no periodo por status (Order.Status, Order.TotalAmount)');
        if (!Schema.sObjectType.Order.isAccessible()) { return semAcesso(s, 'Order'); }
        try {
            if (excedeVolume(s, ctx, contarOrder(ctx.inicio, ctx.fim))) { return s; }
            List<AggregateResult> rs = [
                SELECT Status status, COUNT(Id) qtd, SUM(TotalAmount) valor
                FROM Order
                WHERE EffectiveDate >= :ctx.inicio AND EffectiveDate <= :ctx.fim
                WITH USER_MODE
                GROUP BY Status
                ORDER BY Status
            ];
            for (AggregateResult r : rs) {
                s.linhas.add(String.valueOf(r.get('status')) + ': ' + r.get('qtd') + ' pedido(s), ' + moeda((Decimal) r.get('valor')));
            }
            return fechar(s);
        } catch (QueryException e) {
            return semAcesso(s, 'Order');
        }
    }

    private static Secao pedidosTotal(Contexto ctx) {
        Secao s = new Secao('2) Total do periodo (Order.TotalAmount)');
        if (!Schema.sObjectType.Order.isAccessible()) { return semAcesso(s, 'Order'); }
        try {
            if (excedeVolume(s, ctx, contarOrder(ctx.inicio, ctx.fim))) { return s; }
            AggregateResult r = [
                SELECT COUNT(Id) qtd, SUM(TotalAmount) valor
                FROM Order
                WHERE EffectiveDate >= :ctx.inicio AND EffectiveDate <= :ctx.fim
                WITH USER_MODE
            ];
            if ((Integer) r.get('qtd') > 0) {
                s.linhas.add('Total: ' + r.get('qtd') + ' pedido(s), ' + moeda((Decimal) r.get('valor')));
            }
            return fechar(s);
        } catch (QueryException e) {
            return semAcesso(s, 'Order');
        }
    }

    private static Secao pedidosPorVendedor(Contexto ctx) {
        Secao s = new Secao('2) Pedidos no periodo por vendedor (Order.OwnerId, Order.TotalAmount)');
        if (!Schema.sObjectType.Order.isAccessible()) { return semAcesso(s, 'Order'); }
        try {
            if (excedeVolume(s, ctx, contarOrder(ctx.inicio, ctx.fim))) { return s; }
            List<AggregateResult> rs = [
                SELECT OwnerId dono, Owner.Name nome, COUNT(Id) qtd, SUM(TotalAmount) valor
                FROM Order
                WHERE EffectiveDate >= :ctx.inicio AND EffectiveDate <= :ctx.fim
                WITH USER_MODE
                GROUP BY OwnerId, Owner.Name
                ORDER BY SUM(TotalAmount) DESC NULLS LAST
            ];
            for (AggregateResult r : rs) {
                s.linhas.add(String.valueOf(r.get('nome')) + ': ' + r.get('qtd') + ' pedido(s), ' + moeda((Decimal) r.get('valor')));
            }
            return fechar(s);
        } catch (QueryException e) {
            return semAcesso(s, 'Order');
        }
    }

    private static Secao totalGeral(Contexto ctx) {
        Secao s = new Secao('3) Total geral (Opportunity.Amount aberta e Order.TotalAmount)');
        Boolean oppOk = Schema.sObjectType.Opportunity.isAccessible();
        Boolean ordOk = Schema.sObjectType.Order.isAccessible();
        if (!oppOk || !ordOk) {
            return semAcesso(s, !oppOk ? 'Opportunity' : 'Order');
        }
        try {
            Integer qtdOpp = contarOpp(ctx.inicio, ctx.fim);
            Integer qtdOrd = contarOrder(ctx.inicio, ctx.fim);
            if (excedeVolume(s, ctx, qtdOpp + qtdOrd)) { return s; }
            AggregateResult o = [
                SELECT COUNT(Id) qtd, SUM(Amount) valor
                FROM Opportunity
                WHERE IsClosed = false AND CloseDate >= :ctx.inicio AND CloseDate <= :ctx.fim
                WITH USER_MODE
            ];
            AggregateResult p = [
                SELECT COUNT(Id) qtd, SUM(TotalAmount) valor
                FROM Order
                WHERE EffectiveDate >= :ctx.inicio AND EffectiveDate <= :ctx.fim
                WITH USER_MODE
            ];
            if (qtdOpp + qtdOrd > 0) {
                s.linhas.add('Pipeline aberto: ' + o.get('qtd') + ' oportunidade(s), ' + moeda((Decimal) o.get('valor')));
                s.linhas.add('Pedidos: ' + p.get('qtd') + ' pedido(s), ' + moeda((Decimal) p.get('valor')));
            }
            return fechar(s);
        } catch (QueryException e) {
            return semAcesso(s, 'Opportunity/Order');
        }
    }

    // ---------- Auxiliares de consulta ----------

    private static Integer contarOpp(Date ini, Date fim) {
        return [
            SELECT COUNT() FROM Opportunity
            WHERE IsClosed = false AND CloseDate >= :ini AND CloseDate <= :fim
            WITH USER_MODE
        ];
    }

    private static Integer contarOrder(Date ini, Date fim) {
        return [
            SELECT COUNT() FROM Order
            WHERE EffectiveDate >= :ini AND EffectiveDate <= :fim
            WITH USER_MODE
        ];
    }

    private static Boolean excedeVolume(Secao s, Contexto ctx, Integer qtd) {
        if (ctx.linhasUsadas + qtd > tetoLinhas) {
            s.status = ST_VOLUME;
            s.mensagem = 'Volume acima do limite seguro de leitura. Reduza o periodo e peca de novo.';
            return true;
        }
        ctx.linhasUsadas += qtd;
        return false;
    }

    private static Secao listarTopContas(Secao s, List<AggregateResult> rs, AggregateResult total) {
        Decimal somaTop = 0;
        Integer qtdTop = 0;
        for (AggregateResult r : rs) {
            Decimal v = (Decimal) r.get('valor');
            somaTop += (v == null ? 0 : v);
            qtdTop += (Integer) r.get('qtd');
            s.linhas.add(String.valueOf(r.get('nome')) + ': ' + r.get('qtd') + ' registro(s), ' + moeda(v));
        }
        Integer qtdTotal = (Integer) total.get('qtd');
        Decimal valorTotal = (Decimal) total.get('valor');
        if (qtdTotal > qtdTop) {
            s.linhas.add('Demais contas: ' + (qtdTotal - qtdTop) + ' registro(s), '
                + moeda((valorTotal == null ? 0 : valorTotal) - somaTop));
        }
        return fechar(s);
    }

    private static Secao fechar(Secao s) {
        if (s.linhas.isEmpty()) {
            s.status = ST_VAZIO;
            s.mensagem = 'Nenhum registro no periodo.';
        }
        return s;
    }

    private static Secao semAcesso(Secao s, String objeto) {
        s.status = ST_SEM_ACESSO;
        s.mensagem = 'Voce nao tem acesso de leitura a ' + objeto + '. Esta secao nao foi calculada.';
        s.linhas.clear();
        return s;
    }

    // ---------- Montagem do texto ----------

    private static MeetingSummaryResult montar(String tipo, Contexto ctx, List<Secao> secoes, Datetime corte) {
        Integer ok = 0;
        Integer semAcesso = 0;
        List<String> txt = new List<String>();
        txt.add('Resumo para reuniao ' + nomeTipo(tipo) + ' - periodo ' + data(ctx.inicio) + ' a ' + data(ctx.fim));
        for (Secao s : secoes) {
            txt.add('');
            txt.add(s.titulo + ' [' + s.status + ']');
            if (s.mensagem != null) {
                txt.add(s.mensagem);
            }
            txt.addAll(s.linhas);
            if (s.status == ST_OK || s.status == ST_VAZIO) { ok++; }
            if (s.status == ST_SEM_ACESSO) { semAcesso++; }
        }
        txt.add('');
        txt.add('Valores em BRL. Dados ate ' + corte.format('dd/MM/yyyy HH:mm') + '.');

        MeetingSummaryResult r = new MeetingSummaryResult();
        r.status = ok == secoes.size() ? ST_OK : (semAcesso == secoes.size() ? ST_SEM_ACESSO : ST_PARCIAL);
        r.textoResumo = String.join(txt, '\n');
        r.dataHoraCorte = corte;
        return r;
    }

    private static String nomeTipo(String tipo) {
        return tipo == TIPO_SOP ? 'S&OP' : (tipo == TIPO_GDD ? 'GDD' : (tipo == TIPO_BOARD ? 'Board' : 'Comercial'));
    }

    private static String data(Date d) {
        return Datetime.newInstance(d, Time.newInstance(0, 0, 0, 0)).format('dd/MM/yyyy');
    }

    @TestVisible
    private static String moeda(Decimal v) {
        Decimal x = (v == null ? 0 : v).setScale(2, RoundingMode.HALF_UP);
        Boolean neg = x < 0;
        String s = String.valueOf(x.abs());
        List<String> partes = s.split('\\.');
        String inteiro = partes[0];
        String cent = partes.size() > 1 ? partes[1] : '00';
        String out = '';
        Integer cont = 0;
        for (Integer i = inteiro.length() - 1; i >= 0; i--) {
            if (cont > 0 && Math.mod(cont, 3) == 0) { out = '.' + out; }
            out = inteiro.substring(i, i + 1) + out;
            cont++;
        }
        return (neg ? '-' : '') + 'R$ ' + out + ',' + cent;
    }

    private static MeetingSummaryResult erro(String msg) {
        MeetingSummaryResult r = new MeetingSummaryResult();
        r.status = ST_ERRO;
        r.textoResumo = msg;
        r.dataHoraCorte = Datetime.now();
        return r;
    }
}
