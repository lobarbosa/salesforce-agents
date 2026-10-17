public  with sharing class EstoqueFilialCallout {

    private ApexPages.StandardSetController standardSetController;
 
    public EstoqueFilialCallout(ApexPages.StandardSetController standardSetController)
    {
        this.standardSetController = standardSetController;
    }

    public static PageReference botaoAtualizar(){
        IntegrProtheusEstoqueController.buscaEstoque();
        return null;
    }
}