global with sharing class IntegracaoReceitaWS {

  @AuraEnabled 
  public static Wrapper consultarDadosReceitaWS(String CNPJ) {

    CNPJ = CNPJ.replace( '/' , '' );
    CNPJ = CNPJ.replace( '-' , '' );
    CNPJ = CNPJ.replace( '.' , '' );

    String endpoint ='https://receitaws.com.br/v1/cnpj/' + CNPJ;

    Http http = new Http();
    HttpRequest request = new HttpRequest();

    request.setEndpoint(endpoint); 
    request.setMethod('GET');

    HttpResponse response = http.send(request);

    Wrapper wrapper = new Wrapper();
    if(response.getStatusCode() == 200) {

      System.debug(response.getBody());
      DadosReceitaWS dados = (DadosReceitaWS)JSON.deserialize(response.getBody(), DadosReceitaWS.class);

      wrapper.dadosGeral = dados;

      String atividadePrim='';
      for(Atividade_principal atvPrim : dados.atividade_principal) {
          atividadePrim +=  atvPrim.code + '   ' + atvPrim.text + '\n';
          
      }
      wrapper.dadosAtividadePrim = atividadePrim;

      String atividadesSecund='';
      for(Atividades_secundarias atvSec : dados.atividades_secundarias) {
          atividadesSecund +=  atvSec.code + '   ' + atvSec.text + '\n';
          
      }
      wrapper.dadosAtividadeSec = atividadesSecund;

      String enderecoForm='';
      if(String.isNotBlank(dados.logradouro)) {
        enderecoForm += dados.logradouro ;

      }
      if(String.isNotBlank(dados.numero)) {
        enderecoForm +=  ', ' + dados.numero ;

      }
      if(String.isNotBlank(dados.complemento)) {
        enderecoForm += ' , ' + dados.complemento;

      }
      if(String.isNotBlank(dados.bairro)) {
        enderecoForm += ' - '+ dados.bairro ;

      }
      wrapper.enderecoFormatado = enderecoForm;
              
      return wrapper;

    }else {

      return null;

    }       
  }

  @AuraEnabled
  public static void atualizarObjeto( String  recordId2,              String  objectName2,
                                      String  CNPJ2,                  String  razaoSocial2,
                                      String  naturezaJuridica2,      String  tipo2,
                                      String  telefone2,              String  dataAbertura2,
                                      String  situacaoCadastral2,     String  motivoSituacaoCadastral2,
                                      String  dataSituacao2,          String  cepCobranca2,
                                      String  ruaCobranca2,           String  cidadeCobranca2,
                                      String  estadoCobranca2,        String  paisCobranca2, 
                                      String  atvEconomicaPrincipal2, String  atvEconomicaSecundaria2,
                                      String  bairroCobranca2 ) {

    CNPJ2 = CNPJ2.replace( '/' , '' );
    CNPJ2 = CNPJ2.replace( '-' , '' );
    CNPJ2 = CNPJ2.replace( '.' , '' );

    //System.debug(dataSituacao2);
    Date situacaoData;
    if(String.isNotBlank(dataSituacao2)) {

      if(dataSituacao2.contains('-')) {
        situacaoData  =  Date.valueOf(dataSituacao2);
      } else {
        situacaoData  = Date.parse(dataSituacao2);
      }

    }

    //System.debug(dataAbertura2);
    Date aberturaData;
    if(String.isNotBlank(dataAbertura2)) {

      if(dataAbertura2.contains('-')) {
        aberturaData  =  Date.valueOf(dataAbertura2);
      } else {
        aberturaData  = date.parse(dataAbertura2);
      }

    }


    if(objectName2 == 'Account') {

      Account acc = [ SELECT Id FROM Account WHERE Id = :recordId2  ];

      acc.name                          = razaoSocial2;
      acc.beeCnpj__CNPJ__c              = CNPJ2;
      acc.beeCnpj__RazaoSocial__c       = razaoSocial2;
      acc.beeCnpj__NaturezaJuridica__c  = naturezaJuridica2;
      acc.beeCnpj__Tipo__c              = tipo2;
      acc.Phone                         = telefone2;
      acc.beeCnpj__DataAbertura__c      = aberturaData;
      acc.beeCnpj__SituacaoCadastral__c = situacaoCadastral2;
      acc.beeCnpj__MotivoSituacaoCadastral__c       = motivoSituacaoCadastral2;
      acc.beeCnpj__DataSituacao__c                  = situacaoData;
      acc.beeCnpj__AtividadeEconomicaPrincipal__c   = atvEconomicaPrincipal2;	
      acc.beeCnpj__AtividadeEconomicaSecundaria__c  = atvEconomicaSecundaria2;

      acc.BairroCobranca__c   = bairroCobranca2;
      acc.BillingStreet       = ruaCobranca2;
      acc.BillingCity         = cidadeCobranca2;
      acc.BillingPostalCode   = cepCobranca2;
      acc.BillingState        = estadoCobranca2;
      acc.BillingCountry      = 'BR ';

      update acc;

    } else if (objectName2 == 'Lead') {

      Lead ld = [ SELECT Id FROM Lead WHERE Id = :recordId2 ];

      ld.beeCnpj__CNPJ__c              = CNPJ2;
      ld.Company                       = razaoSocial2;
      ld.Phone                         = telefone2;
      ld.beeCnpj__RazaoSocial__c       = razaoSocial2;
      ld.beeCnpj__DataAbertura__c      = aberturaData;
      ld.beeCnpj__NaturezaJuridica__c  = naturezaJuridica2;
      ld.beeCnpj__SituacaoCadastral__c = situacaoCadastral2;
      ld.beeCnpj__Tipo__c                     = tipo2;
      ld.beeCnpj__MotivoSituacaoCadastral__c  = motivoSituacaoCadastral2;
      ld.beeCnpj__DataSituacao__c             = situacaoData;
      ld.PostalCode                           = cepCobranca2;
      ld.Street                               = ruaCobranca2;
      ld.City                                 = cidadeCobranca2;
      ld.State                                = estadoCobranca2;
      ld.Country                              = 'BR';
      ld.beeCnpj__AtividadeEconomicaPrincipal__c  = atvEconomicaPrincipal2;
      ld.beeCnpj__AtividadeEconomicaSecundaria__c = atvEconomicaSecundaria2;

      update ld;

      //System.debug( 'IS LEAD');
    }

  }

  @AuraEnabled(cacheable=true)
  public static SObject consultarDadosObjeto(String idObjeto, String nomeApi) {

    SObject objeto;
    if(String.isNotBlank(idObjeto) && nomeApi == 'Account') {

      System.debug('IS ACCOUNT');
      Account  acc = [  SELECT    beeCnpj__CNPJ__c,
                                  beeCnpj__RazaoSocial__c,
                                  beeCnpj__NaturezaJuridica__c,
                                  beeCnpj__Tipo__c,
                                  Phone,
                                  beeCnpj__DataAbertura__c,
                                  beeCnpj__SituacaoCadastral__c,
                                  beeCnpj__MotivoSituacaoCadastral__c,
                                  beeCnpj__DataSituacao__c,
                                  beeCnpj__AtividadeEconomicaPrincipal__c,
                                  beeCnpj__AtividadeEconomicaSecundaria__c,
                                  BillingStreet,
                                  BillingCity,
                                  BillingPostalCode,
                                  BillingState,
                                  BillingCountry
                        FROM      Account 
                        WHERE     Id =: idObjeto  ];

      objeto = acc; 

    } else if(String.isNotBlank(idObjeto) && nomeApi == 'Lead') { 
      //System.debug('IS LEAD');

      Lead ld = [ SELECT    beeCnpj__CNPJ__c,
                            Company,
                            Phone,
                            beeCnpj__RazaoSocial__c,
                            beeCnpj__DataAbertura__c,
                            beeCnpj__NaturezaJuridica__c,
                            beeCnpj__SituacaoCadastral__c,
                            beeCnpj__Tipo__c,
                            beeCnpj__MotivoSituacaoCadastral__c,
                            beeCnpj__DataSituacao__c,
                            PostalCode,
                            Street,  
                            City,  
                            State,  
                            Country,
                            beeCnpj__AtividadeEconomicaPrincipal__c,
                            beeCnpj__AtividadeEconomicaSecundaria__c
                  FROM      Lead 
                  WHERE     Id =: idObjeto  ];

      objeto = ld;   
    }

    return objeto;

  }


  public class Wrapper {

    @AuraEnabled public DadosReceitaWS  dadosGeral;
    @AuraEnabled public String dadosAtividadePrim;
    @AuraEnabled public String dadosAtividadeSec;
    @AuraEnabled public String enderecoFormatado;

  }

  public class DadosReceitaWS {

  //Os campos comentados abaixo não são usados, e o fato de não serem usados prejudica a cobertura da classe de teste.
  //Por isso se precisar usar campos a mais, descomente.
  //public String status {get;set;} Não é usado 
    
  //@AuraEnabled  public String ultima_atualizacao {get;set;} Não é usado
    @AuraEnabled  public String cnpj {get;set;}       
    @AuraEnabled  public String tipo {get;set;}       
    @AuraEnabled  public String porte {get;set;} 
    @AuraEnabled  public String nome {get;set;}   // Razão social
 // @AuraEnabled  public String fantasia {get;set;} Não é usado  
    @AuraEnabled  public String abertura {get;set;}   
    @AuraEnabled  public List<Atividade_principal> atividade_principal {get;set;}         
    @AuraEnabled  public List<Atividades_secundarias> atividades_secundarias {get;set;}  
    @AuraEnabled  public String natureza_juridica {get;set;} 
    @AuraEnabled  public String logradouro {get;set;}       
    @AuraEnabled  public String numero {get;set;}           
    @AuraEnabled  public String complemento {get;set;}      
    @AuraEnabled  public String cep {get;set;}              
    @AuraEnabled  public String bairro {get;set;}           
    @AuraEnabled  public String municipio {get;set;}        
    @AuraEnabled  public String uf {get;set;}               
 // @AuraEnabled  public String email {get;set;} Não é usado
    @AuraEnabled  public String telefone {get;set;}         
 // @AuraEnabled  public String efr {get;set;}  Não é usado
    @AuraEnabled  public String situacao {get;set;}         
    @AuraEnabled  public String data_situacao {get;set;}    
    @AuraEnabled  public String motivo_situacao {get;set;}   
 // @AuraEnabled  public String situacao_especial {get;set;} 
 // @AuraEnabled  public String data_situacao_especial {get;set;} 
 // @AuraEnabled  public String capital_social {get;set;} 
 // @AuraEnabled  public List<Qsa> qsa {get;set;}

  }

  public class Atividade_principal {

    @AuraEnabled  public String code {get;set;} 
    @AuraEnabled  public String text {get;set;} 

  }

  public class Atividades_secundarias {

    @AuraEnabled  public String code {get;set;} 
    @AuraEnabled  public String text {get;set;} 

  }

  // public class Qsa {
  // @AuraEnabled  public String nome {get;set;} 
  // @AuraEnabled  public String qual {get;set;} 
  // @AuraEnabled  public String pais_origem {get;set;} 
  // @AuraEnabled  public String nome_rep_legal {get;set;} 
  // @AuraEnabled  public String qual_rep_legal {get;set;} 
  // }

}