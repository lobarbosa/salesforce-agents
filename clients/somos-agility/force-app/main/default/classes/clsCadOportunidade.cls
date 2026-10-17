public with sharing class clsCadOportunidade {
    public String idPedido {set;get;}
    public String idOportunidade {set;get;}
    public String idProduto {set;get;}
        public clsCadOportunidade(ApexPages.StandardController controller) {
                idOportunidade=ApexPages.currentPage().getParameters().get('id');
        idPedido=ApexPages.currentPage().getParameters().get('idPedido');
        idProduto=ApexPages.currentPage().getParameters().get('idProduto');
    }
      public clsCadOportunidade() {

    }
    public PageReference SalvarOportunidade(){
         Pagereference reference;
         return reference;
    }

}