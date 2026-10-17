public with sharing class ProtheusInsertOrderModel {
    public Pedido[] Pedido;

    public class Pedido {
        public String Filial;
        public String FilDespacho;
        public String NumERP;
        public String NumPedCRM;
        public String CliVen;
        public String LojaVen;
        public String NomeCliVen;
        public String CliEnt;
        public String LojaEnt;
        public String NomeCliEnt;
        public String UFVenda;
        public String CidadeVenda;
        public String CondPagto;
        public String FormaPagto;
        public String FormaPagto2;
        public String Vend1;
        public String Vend2;
        public String DtEmissao;
        public String DtPrevVenda;
        public String DtEntrega;
        public String Volume;
        public String Especie;
        public String MensNota;
        public String Observacao;
        public Decimal Parcela1;
        public Decimal Parcela2;
        public Decimal Parcela3;
        public Decimal Parcela4;
        public Decimal Parcela5;
        public Decimal Parcela6;
        public Decimal Parcela7;
        public Decimal Parcela8;
        public Decimal Parcela9;
        public Decimal Parcela10;
        public Decimal Parcela11;
        public Decimal Parcela12;
        public String Vencimento1;
        public String Vencimento2;
        public String Vencimento3;
        public String Vencimento4;
        public String Vencimento5;
        public String Vencimento6;
        public String Vencimento7;
        public String Vencimento8;
        public String Vencimento9;
        public String Vencimento10;
        public String IDEXTERNO;
        public String Vencimento11;
        public String Vencimento12;
        public Decimal ValorPedido;
        public String Transport;
        public String OperPed;
        public String TipoOper;
        public String TipoFrete;
        public String MotCancel;
        public Decimal DESCONTO;
        public Item[] itens;
    }

    public class Item {
        public String Filial;
        public String NumERP;
        public String NumPedCRM;
        public String Item;
        public String Produto;
        public String Unidade;
        public Decimal Quant1UM;
        public Decimal VlUnit;
        public Decimal VlTotal;
        public Decimal Quant2UM;
    }
}