@isTest
public class SolicitacaoReembolsoBOTest {

    // Massa 100% sintética (guardrail #2): nenhum CPF, nome ou e-mail real. O CPF é
    // gerado com dígito verificador calculado localmente só para passar no formato
    // exigido pelo campo (não corresponde a nenhuma pessoa).
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

    // Status__c fica sempre em 'Rascunho', nunca 'Pendente': a automação nativa
    // "Atualiza_o_status_de_aprovacao_e_etapas_da_SR" (fora do escopo desta demanda)
    // reescreve Status_de_Aprovacao_e_Etapas__c sempre que Status__c = 'Pendente' é
    // salvo, o que tornaria as transições de etapa deste teste não-determinísticas.
    private static Solicitacao_de_Reembolso__c criarSolicitacao(Contact solicitante, String etapaInicial) {
        Solicitacao_de_Reembolso__c sol = new Solicitacao_de_Reembolso__c();
        sol.Solicitante__c = solicitante.Id;
        sol.PIN__c = solicitante.PIN__c;
        sol.Status__c = 'Rascunho';
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

    private static Lancamento_de_Despesas__c criarLancamentoKm(Id solicitacaoId, Id projetoId, Id contaId, Decimal km, Decimal valorPorKm) {
        Lancamento_de_Despesas__c l = new Lancamento_de_Despesas__c();
        l.Solicitacao_de_Reembolso__c = solicitacaoId;
        l.Relacionado_ao_Projeto__c = projetoId;
        l.Relacionado_a_Conta__c = contaId;
        l.Tipo_da_Despesa__c = 'Kilometragem (Analistas)';
        l.Kilometros_Percorridos_Ida__c = km;
        l.Kilometros_Percorridos_Volta__c = 0;
        l.Valor_do_KM_Rodado__c = valorPorKm;
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

    // Cenário 1 (+ cenário 4 embutido na checagem "antes"): SR sai de
    // "Pendente - Gerente de Projetos" para "Pendente - Gestor" -> total passa a
    // incluir os Lançamentos, com e sem quilometragem.
    @isTest
    static void testInclusaoAoAprovarPeloGP() {
        TriggerHandler.bypass('PPMProjectTriggerHandler');

        Account a = criarConta();
        Contact c = criarContato(a.Id);
        PPM_Project__c p = criarProjeto(a.Id);
        Solicitacao_de_Reembolso__c sol = criarSolicitacao(c, 'Pendente - Gerente de Projetos');
        criarLancamento(sol.Id, p.Id, a.Id, 150.00);
        criarLancamentoKm(sol.Id, p.Id, a.Id, 20, 1.50); // 20km x R$1,50 = R$30,00

        PPM_Project__c antes = [SELECT Id, Total_de_despesas_realizadas__c FROM PPM_Project__c WHERE Id = :p.Id];
        Assert.areEqual(0, antes.Total_de_despesas_realizadas__c,
            'Projeto com Lançamento sem etapa elegível deve ficar com total 0, nunca nulo (RN-08)');

        Test.startTest();
        sol.Status_de_Aprovacao_e_Etapas__c = 'Pendente - Gestor'; // GP aprovou
        update sol;
        Test.stopTest();

        PPM_Project__c depois = [SELECT Id, Total_de_despesas_realizadas__c, DespesasRealizadasAtividades__c FROM PPM_Project__c WHERE Id = :p.Id];
        Assert.areEqual(180.00, depois.Total_de_despesas_realizadas__c,
            'Total deve somar a despesa comum (150) e a quilometragem (20km x R$1,50 = 30)');
        Assert.areEqual(180.00, depois.DespesasRealizadasAtividades__c,
            'Campo irmão mantido por Apex (DespesasRealizadasAtividades__c) também reflete o re-save (efeito colateral aceito em D1/R3)');
    }

    // Cenário 2: SR "Pendente - Gestor" -> "Rejeitado": total volta a excluir (nos dois campos).
    @isTest
    static void testExclusaoAoRejeitar() {
        TriggerHandler.bypass('PPMProjectTriggerHandler');

        Account a = criarConta();
        Contact c = criarContato(a.Id);
        PPM_Project__c p = criarProjeto(a.Id);
        Solicitacao_de_Reembolso__c sol = criarSolicitacao(c, 'Pendente - Gestor');
        criarLancamento(sol.Id, p.Id, a.Id, 200.00);

        PPM_Project__c antes = [SELECT Id, Total_de_despesas_realizadas__c, DespesasRealizadasAtividades__c FROM PPM_Project__c WHERE Id = :p.Id];
        Assert.areEqual(200.00, antes.Total_de_despesas_realizadas__c, 'Pré-condição: SR já elegível deve contribuir com o total');
        Assert.areEqual(200.00, antes.DespesasRealizadasAtividades__c, 'Pré-condição: campo irmão também soma antes da rejeição');

        Test.startTest();
        sol.Status_de_Aprovacao_e_Etapas__c = 'Rejeitado';
        update sol;
        Test.stopTest();

        PPM_Project__c depois = [SELECT Id, Total_de_despesas_realizadas__c, DespesasRealizadasAtividades__c FROM PPM_Project__c WHERE Id = :p.Id];
        Assert.areEqual(0, depois.Total_de_despesas_realizadas__c, 'SR rejeitada não deve mais contribuir para o total (campo da demanda)');
        Assert.areEqual(0, depois.DespesasRealizadasAtividades__c, 'SR rejeitada também não deve contribuir para o campo irmão (R3)');
    }

    // Cenário 3: SR "Aprovado" -> "Recall": total exclui.
    @isTest
    static void testExclusaoAoRecolher() {
        TriggerHandler.bypass('PPMProjectTriggerHandler');

        Account a = criarConta();
        Contact c = criarContato(a.Id);
        PPM_Project__c p = criarProjeto(a.Id);
        Solicitacao_de_Reembolso__c sol = criarSolicitacao(c, 'Aprovado');
        criarLancamento(sol.Id, p.Id, a.Id, 75.50);

        PPM_Project__c antes = [SELECT Id, Total_de_despesas_realizadas__c FROM PPM_Project__c WHERE Id = :p.Id];
        Assert.areEqual(75.50, antes.Total_de_despesas_realizadas__c, 'Pré-condição: SR aprovada contribui para o total');

        Test.startTest();
        sol.Status_de_Aprovacao_e_Etapas__c = 'Recall';
        update sol;
        Test.stopTest();

        PPM_Project__c depois = [SELECT Id, Total_de_despesas_realizadas__c FROM PPM_Project__c WHERE Id = :p.Id];
        Assert.areEqual(0, depois.Total_de_despesas_realizadas__c, 'SR recolhida não deve mais contribuir para o total');
    }

    // Cenário 4 (isolado): projeto cujo único Lançamento nunca atinge etapa elegível -> total 0, nunca nulo.
    @isTest
    static void testProjetoSemLancamentoElegivelTotalZero() {
        TriggerHandler.bypass('PPMProjectTriggerHandler');

        Account a = criarConta();
        Contact c = criarContato(a.Id);
        PPM_Project__c p = criarProjeto(a.Id);
        Solicitacao_de_Reembolso__c sol = criarSolicitacao(c, 'Rascunho');

        Test.startTest();
        criarLancamento(sol.Id, p.Id, a.Id, 999.00);
        Test.stopTest();

        PPM_Project__c depois = [SELECT Id, Total_de_despesas_realizadas__c FROM PPM_Project__c WHERE Id = :p.Id];
        Assert.areEqual(0, depois.Total_de_despesas_realizadas__c, 'RN-08: projeto sem Lançamento elegível deve ter total 0, nunca nulo');
    }

    // Cenário 7 (R8): vários Lançamentos da mesma SR no MESMO projeto, inseridos juntos (bulk pequeno) -> total correto.
    @isTest
    static void testVariosLancamentosMesmoProjeto() {
        TriggerHandler.bypass('PPMProjectTriggerHandler');

        Account a = criarConta();
        Contact c = criarContato(a.Id);
        PPM_Project__c p = criarProjeto(a.Id);
        Solicitacao_de_Reembolso__c sol = criarSolicitacao(c, 'Pendente - Gestor'); // já elegível

        List<Lancamento_de_Despesas__c> lancamentos = new List<Lancamento_de_Despesas__c>();
        for (Integer i = 0; i < 5; i++) {
            Lancamento_de_Despesas__c l = new Lancamento_de_Despesas__c();
            l.Solicitacao_de_Reembolso__c = sol.Id;
            l.Relacionado_ao_Projeto__c = p.Id;
            l.Relacionado_a_Conta__c = a.Id;
            l.Tipo_da_Despesa__c = 'Alimentação';
            l.Valor_da_Despesa__c = 10.00;
            lancamentos.add(l);
        }

        Test.startTest();
        insert lancamentos; // 1 DML, várias interviews do mesmo Flow atualizando o mesmo projeto (R8)
        Test.stopTest();

        PPM_Project__c depois = [SELECT Id, Total_de_despesas_realizadas__c FROM PPM_Project__c WHERE Id = :p.Id];
        Assert.areEqual(50.00, depois.Total_de_despesas_realizadas__c, '5 Lançamentos de R$10,00 no mesmo projeto devem somar R$50,00');
    }

    // Cenário 6: 200 SR mudando de etapa numa única DML, com Lançamentos distribuídos
    // em vários projetos, sem estourar limite de governador. Mede Limits.getQueries()/
    // getDmlStatements() para o roteiro de QA comparar com N=1/50 (ver 04-plano-build.md).
    @isTest
    static void testBulk200SolicitacoesMudandoDeEtapa() {
        TriggerHandler.bypass('PPMProjectTriggerHandler');

        final Integer total = 200;
        final Integer qtdProjetos = 20; // 10 SR por projeto: menos cascata de automação nativa de PPM_Project__c por lote

        Account a = criarConta();
        List<PPM_Project__c> projetos = new List<PPM_Project__c>();
        for (Integer i = 0; i < qtdProjetos; i++) {
            projetos.add(new PPM_Project__c(Conta__c = a.Id));
        }
        insert projetos;

        List<Contact> contatos = new List<Contact>();
        for (Integer i = 0; i < total; i++) {
            Contact c = new Contact();
            c.AccountId = a.Id;
            c.LastName = 'Contato Sintetico Bulk ' + i;
            c.CPF__c = gerarCpfSintetico(1000 + i);
            c.Data_de_Nascimento__c = Date.newInstance(1990, 1, 1);
            c.Contato_Trabalha_Atualmente_na_Empresa__c = 'Sim';
            c.Phone = '1130000000';
            contatos.add(c);
        }
        insert contatos;
        Map<Id, Contact> contatosComPin = new Map<Id, Contact>([SELECT Id, PIN__c FROM Contact WHERE Id IN :contatos]);

        List<Solicitacao_de_Reembolso__c> solicitacoes = new List<Solicitacao_de_Reembolso__c>();
        for (Integer i = 0; i < total; i++) {
            Solicitacao_de_Reembolso__c sol = new Solicitacao_de_Reembolso__c();
            sol.Solicitante__c = contatos[i].Id;
            sol.PIN__c = contatosComPin.get(contatos[i].Id).PIN__c;
            sol.Status__c = 'Rascunho';
            sol.Status_de_Aprovacao_e_Etapas__c = 'Pendente - Gerente de Projetos';
            solicitacoes.add(sol);
        }
        insert solicitacoes;

        List<Lancamento_de_Despesas__c> lancamentos = new List<Lancamento_de_Despesas__c>();
        for (Integer i = 0; i < total; i++) {
            Lancamento_de_Despesas__c l = new Lancamento_de_Despesas__c();
            l.Solicitacao_de_Reembolso__c = solicitacoes[i].Id;
            l.Relacionado_ao_Projeto__c = projetos[Math.mod(i, qtdProjetos)].Id;
            l.Relacionado_a_Conta__c = a.Id;
            l.Tipo_da_Despesa__c = 'Alimentação';
            l.Valor_da_Despesa__c = 10.00;
            lancamentos.add(l);
        }
        insert lancamentos;

        for (Solicitacao_de_Reembolso__c sol : solicitacoes) {
            sol.Status_de_Aprovacao_e_Etapas__c = 'Pendente - Gestor';
        }

        Test.startTest();
        Integer queriesAntes = Limits.getQueries();
        Integer dmlAntes = Limits.getDmlStatements();
        update solicitacoes; // 1 única DML com as 200 SR mudando de etapa
        Integer queriesDepois = Limits.getQueries();
        Integer dmlDepois = Limits.getDmlStatements();
        Test.stopTest();

        System.debug(
            'SOMOSAGILITY-10 bulk(200) Limits: queries ' + (queriesDepois - queriesAntes) + '/' + Limits.getLimitQueries() +
            ', dml ' + (dmlDepois - dmlAntes) + '/' + Limits.getLimitDmlStatements()
        );

        Assert.isTrue(queriesDepois <= Limits.getLimitQueries(),
            'A atualização em massa de 200 SR não deve estourar o limite síncrono de SOQL');
        Assert.isTrue(dmlDepois <= Limits.getLimitDmlStatements(),
            'A atualização em massa de 200 SR não deve estourar o limite síncrono de DML');

        List<AggregateResult> somaPorProjeto = [
            SELECT Relacionado_ao_Projeto__c proj, SUM(Valor_da_Despesa__c) total
            FROM Lancamento_de_Despesas__c
            WHERE Relacionado_ao_Projeto__c IN :projetos
            GROUP BY Relacionado_ao_Projeto__c
        ];
        Map<Id, PPM_Project__c> projetosAtualizados = new Map<Id, PPM_Project__c>([
            SELECT Id, Total_de_despesas_realizadas__c FROM PPM_Project__c WHERE Id IN :projetos
        ]);
        Integer projetosComTotalCorreto = 0;
        for (AggregateResult r : somaPorProjeto) {
            Id projId = (Id) r.get('proj');
            Decimal esperado = (Decimal) r.get('total');
            if (esperado == projetosAtualizados.get(projId).Total_de_despesas_realizadas__c) {
                projetosComTotalCorreto++;
            }
        }
        Assert.areEqual(qtdProjetos, projetosComTotalCorreto,
            'Todos os projetos devem refletir a soma correta dos Lançamentos agora elegíveis após a mudança de etapa em lote');
    }
}
