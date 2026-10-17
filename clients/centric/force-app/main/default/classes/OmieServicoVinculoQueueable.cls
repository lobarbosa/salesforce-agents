/**
 * Preenche o Id_Codigo_de_Servico__c (nCodServ do Omie) nos Product2 de serviço,
 * uma fatia de páginas por transação.
 *
 * Por que não resolve numa execução só: percorrer o cadastro de serviços do Omie
 * passa dos 100 callouts por transação do Salesforce, porque cada página é um
 * callout. Cada execução aqui lê PAGINAS_POR_TRANSACAO páginas, grava o que
 * casou e se reenfileira na página seguinte.
 *
 * Por que Queueable e não Batch Apex: o Batch exige o escopo inteiro no start(),
 * e só descobrimos quantas páginas existem perguntando à API. Encadear Queueable
 * deixa a paginação ser o que ela é — um número que passa de uma execução para a
 * próxima.
 *
 * Uso:
 *   System.enqueueJob(new OmieServicoVinculoQueueable());        // cadastro inteiro
 *   OmieServicoVinculoQueueable.vincular(productId);             // um serviço só
 *   OmieServicoVinculoQueueable.vincularComFiltro(
 *       'Family = \'Serviço\'');                                 // recorte seu
 */
public with sharing class OmieServicoVinculoQueueable implements Queueable, Database.AllowsCallouts {

    /** Uma página = um callout. O teto da transação é 100: 20 deixa folga larga. */
    private static final Integer PAGINAS_POR_TRANSACAO = 20;

    private Integer pagina;
    private Resultado total;

    /** Product2 alvo no modo de um só; null significa cadastro inteiro. */
    private Id alvo;

    /** Condição SOQL extra do modo completo; null ou vazio = sem recorte. */
    private String filtro;

    public OmieServicoVinculoQueueable() {
        this(1, new Resultado(), null, null);
    }

    /**
     * Vincula só este Product2, varrendo o cadastro do Omie até encontrá-lo.
     *
     * Para na primeira página que resolver o match, em vez de seguir até o fim do
     * cadastro: é a única diferença de comportamento em relação ao modo completo.
     * Continua paginando entre transações, porque o serviço procurado pode estar
     * na página 300 e aí uma transação não bastaria.
     */
    public OmieServicoVinculoQueueable(Id productId) {
        this(1, new Resultado(), productId, null);
    }

    private OmieServicoVinculoQueueable(Integer pagina, Resultado total, Id alvo, String filtro) {
        this.pagina = pagina;
        this.total  = total;
        this.alvo   = alvo;
        this.filtro = filtro;
    }

    /** Atalho para o modo de um só. O placar sai no log da última execução. */
    public static Id vincular(Id productId) {
        return System.enqueueJob(new OmieServicoVinculoQueueable(productId));
    }

    /**
     * Cadastro inteiro, restringindo os Product2 candidatos ao seu recorte.
     *
     * O filtro ENTRA ALÉM da condição de sempre, nunca no lugar dela: continua
     * valendo que o produto precisa ter sido mencionado pela fatia lida do Omie.
     * Serve para dizer "destes, só os que me interessam agora".
     *
     *   vincularComFiltro('Family = \'Serviço\'');
     *   vincularComFiltro('Id_Codigo_de_Servico__c = null AND CreatedDate = THIS_YEAR');
     *
     * É método estático e não construtor porque um construtor que aceitasse String
     * ficaria ambíguo com o que aceita Id — um literal serviria aos dois, e o modo
     * escolhido dependeria de como o Apex resolvesse a sobrecarga.
     */
    public static Id vincularComFiltro(String filtroSoql) {
        return System.enqueueJob(
            new OmieServicoVinculoQueueable(1, new Resultado(), null, filtroSoql));
    }

    // -----------------------------------------------------------------
    public void execute(QueueableContext ctx) {
        if (alvo == null) {
            executarCadastroInteiro();
        } else {
            procurarUmSo();
        }
    }

    // -----------------------------------------------------------------
    /** Uma fatia de páginas por transação; grava tudo o que casou no caminho. */
    private void executarCadastroInteiro() {

        // 1) Callouts primeiro: o Apex proíbe callout depois de gravação.
        OmieServicoService.Codigos omie =
            OmieServicoService.codigosAtivos(pagina, PAGINAS_POR_TRANSACAO);
        total.lidosDoOmie += omie.lidos;

        // 2) Do Salesforce, só os serviços que ESTA fatia mencionou. É o que
        //    mantém a query e o heap pequenos, em vez de carregar o objeto todo.
        List<Product2> servicos = candidatos(omie);

        // 3) Casa e grava.
        aplicar(servicos, omie);

        // 4) Continuação: proximaPagina null significa que o cadastro acabou.
        if (omie.proximaPagina == null) {
            System.debug(LoggingLevel.INFO, 'Vínculo de serviços concluído — ' + total);
            return;
        }
        if (!Test.isRunningTest()) {
            // O filtro viaja junto: a próxima fatia tem de usar o mesmo recorte.
            System.enqueueJob(
                new OmieServicoVinculoQueueable(omie.proximaPagina, total, null, filtro));
        }
    }

    /**
     * Os Product2 candidatos da fatia: a condição de sempre como base, mais o
     * filtro opcional.
     *
     * Dinâmica só pelo filtro — a base continua fixa no código. As duas coleções
     * viram variável local porque bind de SOQL dinâmico não aceita caminho:
     * ":omie.porCodigo.keySet()" não resolve, ":codigos" resolve.
     *
     * O filtro vai CRU para a query, e não há como escapá-lo: escapar quebraria
     * justamente o filtro legítimo. É entrada de Apex, de quem dispara o job —
     * nunca passe aqui texto vindo de tela, Flow ou integração sem tratar antes.
     */
    private List<Product2> candidatos(OmieServicoService.Codigos omie) {
        Set<String> codigos = omie.porCodigo.keySet();
        Set<Id>     ids     = omie.idsSalesforce();

        String soql = 'SELECT Id, ProductCode, Id_Codigo_de_Servico__c FROM Product2'
                    + ' WHERE (ProductCode IN :codigos OR Id IN :ids)';

        if (String.isNotBlank(filtro)) {
            // Entre parênteses: um filtro com OR dentro não pode vazar e afrouxar
            // a condição de base.
            soql += ' AND (' + filtro + ')';
        }
        return Database.query(soql);
    }

    /**
     * Varre o cadastro do Omie UMA PÁGINA POR VEZ até achar o alvo.
     *
     * Página por página, e não a fatia de 20 de uma vez, porque é isso que deixa
     * parar no encontro: ler 20 páginas para depois descobrir que a resposta
     * estava na primeira seriam 19 callouts jogados fora.
     *
     * Não há filtro de Family na busca do Product2 de propósito — você nomeou o
     * registro, e o pedido explícito vale mais que a classificação dele.
     */
    private void procurarUmSo() {
        List<Product2> achados = [
            SELECT Id, ProductCode, Id_Codigo_de_Servico__c
            FROM Product2
            WHERE Id = :alvo
        ];
        if (achados.isEmpty()) {
            System.debug(LoggingLevel.WARN, 'Product2 não encontrado: ' + alvo);
            return;                              // sem alvo, nem vale chamar a API
        }
        Product2 p = achados[0];

        OmieServicoService.Codigos onde = null;
        Integer proxima = pagina;

        for (Integer i = 0; i < PAGINAS_POR_TRANSACAO && proxima != null; i++) {
            OmieServicoService.Codigos omie = OmieServicoService.codigosAtivos(proxima, 1);
            total.lidosDoOmie += omie.lidos;
            proxima = omie.proximaPagina;

            if (omie.buscar(String.valueOf(p.Id), p.ProductCode) != null) {
                onde = omie;
                break;
            }
        }

        if (onde != null) {
            aplicar(new List<Product2>{ p }, onde);      // reaproveita a gravação
        } else if (proxima != null && !Test.isRunningTest()) {
            // Acabou a cota de páginas desta transação, mas o cadastro continua.
            System.enqueueJob(new OmieServicoVinculoQueueable(proxima, total, alvo, null));
            return;
        }
        System.debug(LoggingLevel.INFO, 'Vínculo de um serviço — ' + total);
    }

    // -----------------------------------------------------------------
    private void aplicar(List<Product2> servicos, OmieServicoService.Codigos omie) {
        Set<String> repetidos = codigosRepetidos(servicos);
        List<Product2> paraAtualizar = new List<Product2>();

        for (Product2 p : servicos) {
            // Código ambíguo vira null: aí só a chave de integração salva o match.
            String codigo = repetidos.contains(p.ProductCode) ? null : p.ProductCode;

            Long codigoOmie = omie.buscar(String.valueOf(p.Id), codigo);
            if (codigoOmie == null) {
                total.ambiguos++;
                continue;
            }

            String novo = String.valueOf(codigoOmie);
            if (novo == p.Id_Codigo_de_Servico__c) {
                total.jaVinculados++;
                continue;
            }
            paraAtualizar.add(new Product2(Id = p.Id, Id_Codigo_de_Servico__c = novo));
        }

        if (paraAtualizar.isEmpty()) return;

        // allOrNone = false: um registro que falhe (validação, trigger) não pode
        // desfazer o vínculo de todos os outros.
        for (Database.SaveResult sr : Database.update(paraAtualizar, false)) {
            if (sr.isSuccess()) total.vinculados++; else total.erros++;
        }
    }

    /**
     * ProductCode repetido não serve para casar: dois serviços do Salesforce
     * apontando para o mesmo cadastro do Omie brigariam na sincronização.
     * Set.add devolve false quando o valor já estava lá.
     */
    private Set<String> codigosRepetidos(List<Product2> servicos) {
        Set<String> vistos    = new Set<String>();
        Set<String> repetidos = new Set<String>();
        for (Product2 p : servicos) {
            if (String.isNotBlank(p.ProductCode) && !vistos.add(p.ProductCode)) {
                repetidos.add(p.ProductCode);
            }
        }
        return repetidos;
    }

    // -----------------------------------------------------------------
    /**
     * Acumula o placar entre as execuções — a instância é serializada junto com
     * o Queueable, então o total atravessa as transações.
     */
    public class Resultado {
        public Integer lidosDoOmie  = 0;   // serviços ativos lidos até aqui
        public Integer vinculados   = 0;   // Product2 atualizados
        public Integer jaVinculados = 0;   // já tinham o mesmo código gravado
        public Integer ambiguos     = 0;   // ProductCode repetido: não deu para casar
        public Integer erros        = 0;   // falharam no update

        public override String toString() {
            return 'Omie: ' + lidosDoOmie +
                   ' | vinculados: '    + vinculados +
                   ' | ja vinculados: ' + jaVinculados +
                   ' | ambiguos: '      + ambiguos +
                   ' | erros: '         + erros;
        }
    }
}