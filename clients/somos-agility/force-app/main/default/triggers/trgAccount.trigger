trigger trgAccount on Account (after insert, after update) {
    Desabilita_trigger__c settings = Desabilita_trigger__c.getInstance();

if(settings.Ativo__c==false){
    for (Account objConta: Trigger.new){
                //Sempre que houver um insert ou uma atualização será sincronizado com o new age
                //SincronizaNewAge sinc = new SincronizaNewAge();
                
                String WS_SN_CLIENTE= 'N'; 
                String WS_SN_FORN= 'N'; 
                String WS_PESS= 'N'; 
                String WS_P_SERVICOS = 'N';
                String Ativo='S';
                Integer Codigo_pais=Integer.valueof(objConta.Pais__r.Codigo__c);
                Integer Codigo_Ramo_Atividade=Integer.valueof(objConta.Ramo_de_Atividade__r.Codigo__c);
                Integer Categoria_Cliente=Integer.valueof(objConta.Categoria_de_cliente__r.Codigo__c);
                
                Categoria_Cliente = (Categoria_Cliente==null || Categoria_Cliente==0 ?999:Categoria_Cliente);
                Codigo_pais = (Codigo_pais==null?0:Codigo_pais);
                Codigo_Ramo_Atividade = (Codigo_Ramo_Atividade==null  || Codigo_Ramo_Atividade==0 ?999:Codigo_Ramo_Atividade);
                String strContr_IPI=(objConta.Contribuicao_de_IPI__c==false || objConta.Contribuicao_de_IPI__c==null?'N':'S');
                String Strcnpj=objConta.cnpj__c;
                /*Strcnpj = Strcnpj.replace('.','');
                Strcnpj = Strcnpj.replace('/','');
                Strcnpj = Strcnpj.replace('-','');*/
                String[] picklistlines =new String[]{};
                String selectedMulPickKeyTech;
                String Telefone=objConta.Phone;
                String ddd='';
                if(Telefone!=null && Telefone!=''){
                    ddd=Telefone.substring(1,2);
                    Telefone=Telefone.substring(3,Telefone.length()-2);
                }
                WS_SN_CLIENTE=(objConta.Cliente__c==false ? 'N' : 'S');
                WS_SN_FORN=(objConta.Fornecedor__c==true || objConta.Parceiro_de_Negocio__c==true || objConta.Distribuidor__c==true  ? 'S' : 'N');
                WS_P_SERVICOS=(objConta.Prestador_de_Servicos__c==false ? 'N' : 'S');
                //selectedMulPickKeyTech = objConta.Atributos__c;
                //picklistlines = selectedMulPickKeyTech.split(';');
                /*for(String str : picklistlines) {
                    if(str=='Cliente'){
                        WS_SN_CLIENTE='S';
                    }
                    if(str.indexof('Fornecedor')>0){
                        WS_SN_FORN='S';
                    }
                    if(str=='Prestador de Serviço'){
                        WS_P_SERVICOS='S';
                    }
                }*/
                String MSG='';
                String sBreak = ' ; ';
                if(objConta.BillingStreet=='' || objConta.BillingStreet==null){
                	MSG+='Informe a Rua' + sBreak;
                }
                
                if(objConta.BillingPostalCode=='' || objConta.BillingPostalCode==null){
                	MSG+='Informe o CEP' + sBreak;
                }
                
                if(objConta.BillingState=='' || objConta.BillingState==null){
                	MSG+='Informe o Estado' + sBreak;
                }
                
                if(objConta.BillingCity=='' || objConta.BillingCity==null){
                	MSG+='Informe a Cidade' + sBreak;
                }
                
                
                if(objConta.Status_da_Conta__c=='Inativo'){
                    Ativo='N';
                }
                if(MSG==''){
	                SincronizaNewAge.sincronizarContato (Strcnpj,  WS_SN_CLIENTE,  WS_SN_FORN,  WS_PESS, 
	                                             WS_P_SERVICOS, Ativo, objConta.Name,  objConta.Raz_o_Social__c, 
	                                            '', objConta.BillingStreet,objConta.Numero_de_cobranca__c, objConta.Complemento__c,
	                                            objConta.BillingPostalCode, objConta.Bairro_Cobranca__c,objConta.BillingCity, 
	                                            objConta.BillingState, Codigo_pais, objConta.Email__c,
	                                            Codigo_Ramo_Atividade, Categoria_Cliente, 
	                                            objConta.Inscricao_estadual__c,ddd,Telefone,objConta.Tipo_Logradouro__c,
	                                            objConta.Inscricao_Municipal__c,strContr_IPI);
                }
                else{
                	objConta.adderror(msg);
                }
                
            
            }
}

}