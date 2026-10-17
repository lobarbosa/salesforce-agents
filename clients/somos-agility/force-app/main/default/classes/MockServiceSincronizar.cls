global class MockServiceSincronizar implements WebServiceMock  {
   global void doInvoke(
           Object stub,
           Object request,
           Map<String, Object> response,
           String endpoint,
           String soapAction,
           String requestName,
           String responseNS,
           String responseName,
           String responseType) {
           	
       	wsSalesForce.IncluirPedidoResponse_element respElement = new wsSalesForce.IncluirPedidoResponse_element();
       	 	respElement.IncluirPedidoResult = CriaObjetos();
       		response.put('response_x',respElement); 
   			}
   public static wsSalesForce.ArrayOfPedidoRetorno CriaObjetos(){
    		wsSalesForce.ArrayOfPedidoRetorno sarrcont = new wsSalesForce.ArrayOfPedidoRetorno();
            wsSalesForce.PedidoRetorno[] arrcont = new wsSalesForce.PedidoRetorno[1];
            wsSalesForce.ArrayOfProduto_PedidoRetorno sarrProdRet = new wsSalesForce.ArrayOfProduto_PedidoRetorno();
            wsSalesForce.Produto_PedidoRetorno[] arrProdPedRet = new wsSalesForce.Produto_PedidoRetorno[1];
            try{
           wsSalesForce.PedidoRetorno aSarrcont = new wsSalesForce.PedidoRetorno();   
        	aSarrcont.Cotacao_Dolar=2;
        	aSarrcont.Custo_TechCenter=10;
        	aSarrcont.Custo_TechCenter_Dolar=10;
        	aSarrcont.dt_entrega=Datetime.newInstance(2010, 02, 05);
        	aSarrcont.ID_SF='NG-0000000001';
        	aSarrcont.Numero_nota_fiscal=0;
        	aSarrcont.Percentual_Rentabilidade=0;
        	aSarrcont.Percentual_Rentabilidade_liquida=0;
        	aSarrcont.Rentabilidade_Bruta=0;
        	aSarrcont.Rentabilidade_Bruta_Dolar=0;
        	aSarrcont.Serie_nota_fiscal='0';
        	aSarrcont.Status='';
        	aSarrcont.Total_Comissao_Intermediaria=0;
        	aSarrcont.Total_Comissao_Intermediaria_Dolar=0;
        	aSarrcont.Total_Custos=0;
        	aSarrcont.Total_Custos_Dolar=0;
        	aSarrcont.Total_Impostos=0;
        	aSarrcont.Total_Receitas=0;
        	aSarrcont.Total_Receitas_Dolar=0;
        	aSarrcont.valor_total_Nota_fiscal=0;
        	aSarrcont.WS_Codigo='0';
        	aSarrcont.WS_DESCRICAO='';
        	aSarrcont.WS_STATUS='';

        	wsSalesForce.Produto_PedidoRetorno pedRet = new wsSalesForce.Produto_PedidoRetorno();
			arrProdPedRet[0] = pedRet;
			sarrProdRet.Produto_PedidoRetorno = arrProdPedRet;  	
        	aSarrcont.Produto_PedidoRet = sarrProdRet; 
            arrcont[0]=aSarrcont;
           sarrcont.PedidoRetorno=arrcont;
           System.debug(sarrcont);
            }
            catch(Exception ex){
        				System.debug('Erro encontrato aquiiiiiiiiii: ' + ex.getMessage());
        			}
           return sarrcont;
   }
}