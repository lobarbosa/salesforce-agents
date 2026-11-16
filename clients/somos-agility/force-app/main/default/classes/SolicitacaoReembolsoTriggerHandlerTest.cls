@isTest
public class SolicitacaoReembolsoTriggerHandlerTest {

    // Massa 100% sintética (guardrail #2) — mesmo padrão de geração de CPF sintético
    // usado em SolicitacaoReembolsoBOTest, duplicado aqui de propósito: cada classe de
    // teste é independente e não deve depender de helpers de outra classe de teste.
    private static Integer seq = 0;

    private static Account criarConta() {
        Account a = new Account(Name = 'Conta Sintetica SOMOSAGILITY-10 ' + (++seq));
        insert a;
        return a;
    }

    private static Contact criarContato(Id accountId) {
        Contact c = new Contact();
        c.AccountId = accountId;
        c.LastName = 'Contato Sintetico ' + (++seq);
        c.CPF__c = gerarCpfSintetico(seq);
        c.Data_de_Nascimento__c = Date.newInstance(1990, 1, 1);
        c.Contato_Trabalha_Atualmente_na_Empresa__c = 'Sim';
        c.Phone = '1130000000';
        insert c;
        return [SELECT Id, PIN__c FROM Contact WHERE Id = :c.Id];
    }

    private static PPM_Project__c criarProjeto(Id accountId) {
        PPM_Project__c p = new PPM_Project__c();
        p.Conta__c = accountId;
        insert p;
        return p;
    }

    // Status__c fixo em 'Rascunho' (nunca 'Pendente') pelo mesmo motivo documentado em
    // SolicitacaoReembolsoBOTest: evitar a automação nativa fora de escopo que reescreve
    // a etapa quando Status__c = 'Pendente'.
    private static Solicitacao_de_Reembolso__c criarSolicitacao(Contact solicitante, String etapaInicial) {
        Solicitacao_de_Reembolso__c sol = new Solicitacao_de_Reembolso__c();
        sol.Solicitante__c = solicitante.Id;
        sol.PIN__c = solicitante.PIN__c;
        sol.Status__c = 'Rascunho';
        sol.Possui_JOB_investimento_ou_treinamento__c = 'Não'; // exigido por validation rule (QA)
        sol.Status_de_Aprovacao_e_Etapas__c = etapaInicial;
        insert sol;
        return sol;
    }

    private static Lancamento_de_Despesas__c criarLancamento(Id solicitacaoId, Id projetoId, Id contaId, Decimal valorDespesa) {
        Lancamento_de_Despesas__c l = new Lancamento_de_Despesas__c();
        l.Solicitacao_de_Reembolso__c = solicitacaoId;
        l.Relacionado_ao_Projeto__c = projetoId;
        l.Relacionado_a_Conta__c = contaId;
        l.Tipo_da_Despesa__c = 'Alimentação';
        l.Valor_da_Despesa__c = valorDespesa;
        insert l;
        return l;
    }

    private static String gerarCpfSintetico(Integer indice) {
        List<Integer> digitos = new List<Integer>();
        String base = String.valueOf(900000000 + Math.mod(indice, 99999999));
        for (Integer i = 0; i < 9; i++) {
            digitos.add(Integer.valueOf(base.substring(i, i + 1)));
        }
        digitos.add(digitoVerificadorCpf(digitos, 10));
        digitos.add(digitoVerificadorCpf(digitos, 11));
        String cpf = '';
        for (Integer d : digitos) {
            cpf += String.valueOf(d);
        }
        return cpf;
    }

    private static Integer digitoVerificadorCpf(List<Integer> digitos, Integer pesoInicial) {
        Integer soma = 0;
        Integer peso = pesoInicial;
        for (Integer i = 0; i < digitos.size(); i++) {
            soma += digitos[i] * peso;
            peso--;
        }
        Integer resto = Math.mod(soma, 11);
        return (resto < 2) ? 0 : 11 - resto;
    }

    // Grava um valor-marcador no total do projeto. Se o Flow rodar de novo, ele sobrescreve
    // o marcador; se nada re-salvar o Lançamento, o marcador permanece.
    private static void marcarTotal(Id projetoId, Decimal valor) {
        update new PPM_Project__c(Id = projetoId, Total_de_despesas_realizadas__c = valor);
    }

    // Mudar de etapa -> o Lançamento é re-salvo (o Flow recalcula o total, provado por marcador, sem depender do relógio) e o total passa a incluí-lo.
    @isTest
    static void testMudarEtapaReSalvaLancamento() {
        TriggerHandler.bypass('PPMProjectTriggerHandler');

        Account a = criarConta();
        Contact c = criarContato(a.Id);
        PPM_Project__c p = criarProjeto(a.Id);
        Solicitacao_de_Reembolso__c sol = criarSolicitacao(c, 'Pendente - Gerente de Projetos');
        Lancamento_de_Despesas__c l = criarLancamento(sol.Id, p.Id, a.Id, 42.00);

        // Marcador independente do relógio: valor que só o Flow (re-disparado pelo re-save) sobrescreve.
        marcarTotal(p.Id, 999);

        Test.startTest();
        sol.Status_de_Aprovacao_e_Etapas__c = 'Pendente - Gestor';
        update sol;
        Test.stopTest();

        PPM_Project__c projeto = [SELECT Id, Total_de_despesas_realizadas__c FROM PPM_Project__c WHERE Id = :p.Id];
        Assert.areEqual(42.00, projeto.Total_de_despesas_realizadas__c, 'O re-save deve disparar o Flow e sobrescrever o marcador com o total real do projeto');
    }

    // Cenário 5: update na SR sem mudar Status_de_Aprovacao_e_Etapas__c nem Status__c -> nenhum Lançamento re-salvo.
    @isTest
    static void testUpdateSemMudarEtapaNaoReSalvaLancamento() {
        TriggerHandler.bypass('PPMProjectTriggerHandler');

        Account a = criarConta();
        Contact c = criarContato(a.Id);
        PPM_Project__c p = criarProjeto(a.Id);
        Solicitacao_de_Reembolso__c sol = criarSolicitacao(c, 'Pendente - Gestor');
        Lancamento_de_Despesas__c l = criarLancamento(sol.Id, p.Id, a.Id, 10.00);

        marcarTotal(p.Id, 999);

        Test.startTest();
        // Update que não toca Status__c nem Status_de_Aprovacao_e_Etapas__c: nenhum dos
        // dois campos monitorados pelo handler muda de valor.
        update sol;
        Test.stopTest();

        PPM_Project__c projeto = [SELECT Id, Total_de_despesas_realizadas__c FROM PPM_Project__c WHERE Id = :p.Id];
        Assert.areEqual(999, projeto.Total_de_despesas_realizadas__c,
            'Lançamento não deveria ser re-salvo quando a SR é atualizada sem mudar de etapa/status (o Flow não pode ter recalculado o total)');
    }

    // Cenário 8 (trava de recursão, camada 2 do R1): chamar o BO duas vezes para a MESMA
    // SR na MESMA etapa, na mesma transação, simula o re-disparo por field update de
    // aprovação (Trigger.old ainda com o valor anterior à DML original) — a segunda
    // chamada não deve re-salvar o Lançamento.
    @isTest
    static void testTravaDeRecursaoPorMesmaEtapaNaMesmaTransacao() {
        TriggerHandler.bypass('PPMProjectTriggerHandler');

        Account a = criarConta();
        Contact c = criarContato(a.Id);
        PPM_Project__c p = criarProjeto(a.Id);
        Solicitacao_de_Reembolso__c sol = criarSolicitacao(c, 'Pendente - Gestor');
        Lancamento_de_Despesas__c l = criarLancamento(sol.Id, p.Id, a.Id, 15.00);

        Test.startTest();
        SolicitacaoReembolsoBO.updateLancamentosDespesas(new List<Solicitacao_de_Reembolso__c>{ sol });
        PPM_Project__c aposPrimeira = [SELECT Id, Total_de_despesas_realizadas__c FROM PPM_Project__c WHERE Id = :p.Id];
        Assert.areEqual(15, aposPrimeira.Total_de_despesas_realizadas__c, 'A primeira chamada deve re-salvar e recalcular o total');
        marcarTotal(p.Id, 999);

        // Mesma SR, mesmo valor de Status_de_Aprovacao_e_Etapas__c: a trava deve bloquear.
        SolicitacaoReembolsoBO.updateLancamentosDespesas(new List<Solicitacao_de_Reembolso__c>{ sol });
        Test.stopTest();

        PPM_Project__c aposSegunda = [SELECT Id, Total_de_despesas_realizadas__c FROM PPM_Project__c WHERE Id = :p.Id];
        Assert.areEqual(999, aposSegunda.Total_de_despesas_realizadas__c,
            'A trava de recursão (SR + etapa) deve impedir reprocessar a mesma SR na mesma etapa dentro da transação');
    }

    // Cenário 8 (ponta a ponta): uma transição real de etapa deixa sincroniza_campos e
    // atualizaAprovadorReembolso gravarem de volta na SR (automação existente, fora de
    // escopo) sem causar recursão descontrolada — a transação termina dentro do limite
    // síncrono de DML, não por exceção de limite de governador.
    @isTest
    static void testTransicaoRealNaoCausaRecursaoDescontrolada() {
        TriggerHandler.bypass('PPMProjectTriggerHandler');

        Account a = criarConta();
        Contact c = criarContato(a.Id);
        PPM_Project__c p = criarProjeto(a.Id);
        Solicitacao_de_Reembolso__c sol = criarSolicitacao(c, 'Pendente - Gerente de Projetos');
        criarLancamento(sol.Id, p.Id, a.Id, 5.00);

        Test.startTest();
        Integer dmlAntes = Limits.getDmlStatements();
        sol.Status_de_Aprovacao_e_Etapas__c = 'Pendente - Gestor';
        update sol;
        Integer dmlDepois = Limits.getDmlStatements();
        Test.stopTest();

        Assert.isTrue((dmlDepois - dmlAntes) <= Limits.getLimitDmlStatements(),
            'A cascata de automação (sincroniza_campos/atualizaAprovadorReembolso + re-save) não deve estourar o limite de DML');
    }
}
