public with sharing class ProtheusInserOrderSuccessResponseBody {
    public Ret_Pedido Ret_Pedido;

    public class Ret_Pedido{
        public String PedidoERP;
        public String PedidoCRM;
        public String STATUS;
        public String Mensagem;
    }
}