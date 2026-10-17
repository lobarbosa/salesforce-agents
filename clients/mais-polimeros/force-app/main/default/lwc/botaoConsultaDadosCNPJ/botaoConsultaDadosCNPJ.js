import { LightningElement, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import consultarDadosReceitaWS from '@salesforce/apex/IntegracaoReceitaWS.consultarDadosReceitaWS';
import atualizarObjeto from '@salesforce/apex/IntegracaoReceitaWS.atualizarObjeto';
import consultarDadosObjeto from '@salesforce/apex/IntegracaoReceitaWS.consultarDadosObjeto';

export default class BotaoConsultaDadosCNPJ extends LightningElement {

  @api recordId;
  @api objectApiName;

  isLead;
  isAccount;
  isRendered = false;

  dadosReceita;
  dadosAtividadeSec;
  dadosAtividadePri;

  CNPJ;
  razaoSocial;
  naturezaJuridica;
  tipo;
  telefone;
  dataAbertura;
  situacaoCadastral;
  motivoSituacaoCadastral;
  dataSituacao;
  cepCobranca;
  ruaCobranca;
  bairroCobranca;
  cidadeCobranca;
  estadoCobranca;
  paisCobranca;
  atvEconomicaPrincipal;
  atvEconomicaSecundaria;

  renderedCallback() {

    if(!this.isRendered) {
      setTimeout(() => {
        this.buscarContas();
      }, 300); 
    }
    this.isRendered = true;

  }

  buscarContas() {

    this.isAccount = (this.objectApiName == 'Account');
    this.isLead = (this.objectApiName == 'Lead');

    console.log(this.isAccount);
    console.log(this.isLead);

    consultarDadosObjeto({

      idObjeto : this.recordId, 
      nomeApi: this.objectApiName

    })
    .then((result)=>{

      console.log('result' , result);

      let dados = result;

      this.CNPJ = dados.beeCnpj__CNPJ__c;
      this.razaoSocial = dados.beeCnpj__RazaoSocial__c;
      this.naturezaJuridica = dados.beeCnpj__NaturezaJuridica__c;
      this.tipo = dados.beeCnpj__Tipo__c;
      this.telefone = dados.Phone;
      this.dataAbertura =  dados.beeCnpj__DataAbertura__c;
      this.situacaoCadastral = dados.beeCnpj__SituacaoCadastral__c;
      this.motivoSituacaoCadastral = dados.beeCnpj__MotivoSituacaoCadastral__c;
      this.dataSituacao = dados.beeCnpj__DataSituacao__c;
      this.atvEconomicaPrincipal = dados.beeCnpj__AtividadeEconomicaPrincipal__c;
      this.atvEconomicaSecundaria = dados.beeCnpj__AtividadeEconomicaSecundaria__c;

      if(this.isAccount) {

        this.cepCobranca = dados.BillingPostalCode;
        this.ruaCobranca = dados.BillingStreet;
        this.bairroCobranca = dados.BairroCobranca__c;
        this.cidadeCobranca = dados.BillingCity;
        this.estadoCobranca = dados.BillingState;
        this.paisCobranca = dados.BillingCountry;

      } else {

        this.cepCobranca = dados.PostalCode;
        this.ruaCobranca = dados.Street;
        this.bairroCobranca = dados.Bairro__c;
        this.cidadeCobranca = dados.City;
        this.estadoCobranca = dados.State;
        this.paisCobranca = dados.Country;

      }
    })
    .catch((error)=>{
      console.log(error);

    })
  }
 
 
  handleClickBuscaDados() {

    consultarDadosReceitaWS({CNPJ : this.CNPJ})
    .then((result) => {
      console.log(result);
       
      this.dadosReceita       = result.dadosGeral;
     
      this.dadosAtividadeSec  = result.dadosAtividadeSec;

      this.dadosAtividadePri  = result.dadosAtividadePrim;

      this.CNPJ               = this.dadosReceita.cnpj ? this.dadosReceita.cnpj : ' ' ;
    
      this.razaoSocial        = this.dadosReceita.nome ? this.dadosReceita.nome : ' ' ;
      
      this.naturezaJuridica   = this.dadosReceita.natureza_juridica ? this.dadosReceita.natureza_juridica : ' ' ;
      
      this.tipo               = this.dadosReceita.tipo ? this.dadosReceita.tipo : ' ';
     
      this.telefone           = this.dadosReceita.telefone ? this.dadosReceita.telefone : ' ';
    
      this.dataAbertura       = this.dadosReceita.abertura ? this.dadosReceita.abertura : ' ';
    
      this.situacaoCadastral  = this.dadosReceita.situacao ? this.dadosReceita.situacao : ' ';
    
      this.motivoSituacaoCadastral  = this.dadosReceita.motivo_situacao ? this.dadosReceita.motivo_situacao : ' ';
   
      this.dataSituacao             = this.dadosReceita.data_situacao ? this.dadosReceita.data_situacao : ' ';
   
      this.cepCobranca              = this.dadosReceita.cep ? this.dadosReceita.cep : ' '; 

      this.ruaCobranca              = result.enderecoFormatado ? result.enderecoFormatado : '';

      this.bairroCobranca           = this.dadosReceita.bairro ? this.dadosReceita.bairro : ' ';
      
      this.cidadeCobranca           = this.dadosReceita.municipio ? this.dadosReceita.municipio : ' ';
     
      this.estadoCobranca           = this.dadosReceita.uf ? this.dadosReceita.uf : ' ';
    
      this.paisCobranca             =  'BR';

      this.atvEconomicaPrincipal    = this.dadosAtividadePri ? this.dadosAtividadePri : ' ';
     
      this.atvEconomicaSecundaria   = this.dadosAtividadeSec ? this.dadosAtividadeSec : ' ';
      
    })
    .catch((error) => {
      console.log(error);
      this.dispatchEvent(
        new ShowToastEvent({
            title: 'Erro',
            message: error.message,
            variant: 'error'
        })
      );
       
    });

  }

  handleClickSave() {
     
    atualizarObjeto({
  
      recordId2:                this.recordId,
      objectName2:              this.objectApiName,
      CNPJ2:                    this.CNPJ,
      razaoSocial2:             this.razaoSocial,
      naturezaJuridica2:        this.naturezaJuridica ,
      tipo2:                    this.tipo,
      telefone2:                this.telefone ,
      dataAbertura2:            this.dataAbertura,
      situacaoCadastral2:       this.situacaoCadastral,
      motivoSituacaoCadastral2: this.motivoSituacaoCadastral,
      dataSituacao2:            this.dataSituacao,
      cepCobranca2:             this.cepCobranca,
      ruaCobranca2:             this.ruaCobranca,
      bairroCobranca2:          this.bairroCobranca,
      cidadeCobranca2:          this.cidadeCobranca,
      estadoCobranca2:          this.estadoCobranca,
      paisCobranca2:            this.paisCobranca,
      atvEconomicaPrincipal2:   this.atvEconomicaPrincipal ,
      atvEconomicaSecundaria2:  this.atvEconomicaSecundaria

    })
    .then((result)=>{
      //console.log(result);
      window.location.reload();
      
    })
    .catch((error)=>{

      console.log(error);
      this.dispatchEvent(
        new ShowToastEvent({
            title: 'Erro',
            message: error.message,
            variant: 'error'
        })
      );

    });

    this.dispatchEvent(new CloseActionScreenEvent());
         
    this.dispatchEvent(
      new ShowToastEvent({
          title: 'Success',
          message: 'Record updated!',
          variant: 'success'
      })
    );

  }

  handleClickClose() {
    this.dispatchEvent(new CloseActionScreenEvent());

  }

  handleChangeCNPJ(event) {
    this.CNPJ = event.target.value;

  }

  handleChangeRazaoSocial(event) {
    this.razaoSocial = event.target.value;  

  }

  handleChangeNaturezaJuridica(event) {
    this.naturezaJuridica = event.target.value;
    
  }

  handleChangeTipo(event) {
    this.tipo = event.target.value;
    
  }

  handleChangeTelefone(event) {
    this.telefone = event.target.value;
    
  }

  handleChangeDataAbertura(event) {
    this.dataAbertura = event.target.value;
    
  }

  handleChangeSituacaoCadastral(event) {
    this.situacaoCadastral = event.target.value;
    
  }

  handleChangeMotivoSituacaoCadastral(event) {
    this.motivoSituacaoCadastral = event.target.value;
    
  }

  handleChangeDataSituacao(event) {
    this.dataSituacao = event.target.value;
    
  }

  handleChangeCepCobranca(event) {
    this.cepCobranca = event.target.value;
    
  }

  handleChangeRuaCobranca(event) {
    this.ruaCobranca = event.target.value;
    
  }

  handleChangeCidadeCobranca(event) {
    this.cidadeCobranca = event.target.value;
    
  }

  handleChangeEstadoCobranca(event) {
    this.estadoCobranca = event.target.value;
    
  }

  handleChangePaisCobranca(event) {
    this.paisCobranca = event.target.value;
    
  }

  handleChangeAtvEconomicaPrincipal(event) {
    this.atvEconomicaPrincipal = event.target.value;
    
  }

  handleChangeAtvEconomicaSecundaria(event) {
    this.atvEconomicaSecundaria = event.target.value;
    
  }

}