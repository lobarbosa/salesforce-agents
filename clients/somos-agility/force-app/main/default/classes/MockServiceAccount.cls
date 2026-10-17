@IsTest
global class MockServiceAccount implements WebServiceMock 
{
	global void doInvoke (Object stub, Object request, Map<String, Object> response, String endpoint, String soapAction, String requestName,
						  String responseNS, String responseName, String responseType) 
	{     
		wsSalesForce.CadastrarClienteResponse_element respElement = new wsSalesForce.CadastrarClienteResponse_element();       
		//wsSalesForce.IncluirPedido_element = new wsSalesForce.IncluirPedido_element();
		respElement.CadastrarClienteResult = CriaObjetos();
		response.put('response_x',respElement); 
	}
			
	public static wsSalesForce.Retorno CriaObjetos()
	{
		wsSalesForce.Retorno retVar = new wsSalesForce.Retorno();
		try
		{
			retVar.Cod_Retorno = 0;
			retVar.Mensagem = '';
		}
		catch(Exception ex)
		{
			System.debug('Erro encontrato aquiiiiiiiiii: ' + ex.getMessage());
		}
		
		return retVar;
	}
}