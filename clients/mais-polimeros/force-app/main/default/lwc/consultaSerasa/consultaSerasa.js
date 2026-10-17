/**
 * @description       : 
 * @author            : Ríad Nassiffe
 * @group             : 
 * @last modified on  : 05-06-2023
 * @last modified by  : José Mateus Amaral
**/
import { LightningElement, track, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent'; 
import consultarSerasa from '@salesforce/apex/SerasaController2.consultarSerasa';
import getParametrosUltimaConsulta from '@salesforce/apex/SerasaController2.getParametrosUltimaConsulta';
import telaConsulta from './consultaSerasa.html';
import telaResposta from './respostaSerasa.html';

export default class ConsultaSerasa extends LightningElement {

  render() {
    if (this.confirmaConsulta) {
        return telaResposta;
    } else{
        return telaConsulta;
    }
}

  @api todosAbertos = false;

  @api   recordId;
  @track confirmaConsulta = false;
  @track isLoading = false;      //spinner
  @track consulta;               //variável que vai armazenar os valores obtidos da consulta ao apex 
  @track numeroDeGrafias;
  @track informacoesPadrao                          = [];
  @track dadosHistoricoPositivoComercial            = [];
  @track dadosPagamentoFinanceiroAvancado           = [];
  @track dadosPontualidadePagamentoPJ               = [];
  @track dadosFaturamentoEstimadoPositivo           = [];
  @track dadosGastoEstimadoPJPositivo               = [];
  @track dadosLimiteCreditoPJ                       = [];
  @track dadosSerasaScoreSetorial                   = [];
  @track dadosSerasaScoreAtacadista                 = [];
  @track dadosQuadroSocialAdministracaoMaisCompleto = [];
  @track dadosAnotacoesConsultasSPCSocios           = [];
  @track dadosParticipacoes                         = [];
  @track dadosAlertaCadastralSociosEAdministradores = [];
  @track dadosRendaProSociosEAdministradoresPF      = [];
  @track dadosSerasaScoreSociosPF                   = [];
  @track dadosIndiceRelacionamentoMercadoSetor      = [];
  @track dadosComportamentoPagamentoSetor           = [];
  @track dadosConsultasDetalhadasSerasa             = [];
  @track dadosSituacaoFiscal                        = [];
  @track dadosAlertaIdentidadePJ                    = [];
  @track dadosAlertaCadastralEmpresa                = [];
  @track dadosVendasCartao                          = [];
  @track dadosMosaicBusiness                        = [];
  @track dadosIndicadorRecuperacaoCredito           = [];
  @track dadosEnderecosTelefonesAdicionais          = [];
  @track dadosIndicadorRecuperacaoDividas           = [];
  @track dadosAnotacoesConsultasSPC                 = [];  
  @track dadosMaisAnotacoes                         = [];
  @track dadosDividasOrgaosPublicosEmpresa          = [];
  @track dadosCadEmp                                = [];
  @track informacoesAnotacoesNegativas              = [];
  @track dadosInformacoesSobreSociosAdministradores = [];
  @track dadosPerfilFinanceiro                      = [];
  @track dadosInformacoesSobreConsultas             = [];
  
  


  HistoricoPositivoComercial            = true;
  PagamentoFinanceiroAvancado           = true;
  PontualidadePagamentoPJ               = true;
  FaturamentoEstimadoPositivo           = true;
  GastoEstimadoPJPositivo               = true;
  LimiteCreditoPJ                       = true;
  SerasaScoreSetorial                   = true;
  SerasaScoreAtacadista                 = true;
  QuadroSocialAdministracaoMaisCompleto = true;
  AnotacoesConsultasSPCSocios           = true;
  Participacoes                         = true;
  AlertaCadastralSociosEAdministradores = true;
  RendaProSociosEAdministradoresPF      = true;
  SerasaScoreSociosPF                   = true;
  IndiceRelacionamentoMercadoSetor      = true;
  ComportamentoPagamentoSetor           = true;
  ConsultasDetalhadasSerasa             = true;
  SituacaoFiscal                        = true;
  AlertaIdentidadePJ                    = true;
  AlertaCadastralEmpresa                = true;
  VendasCartao                          = true;
  MosaicBusiness                        = true;
  IndicadorRecuperacaoCredito           = true;
  EnderecosTelefonesAdicionais          = true;
  IndicadorRecuperacaoDividas           = true;
  AnotacoesConsultasSPC                 = true;  
  MaisAnotacoes                         = true;
  DividasOrgaosPublicosEmpresa          = true;

  //visiblidades dos componentes de linha
  @track showDadosCadEmp = true;
  @track showInformacoesPadrao = true;
  @track showPerfilFinanceiro = true;
  @track showHistoricoPagamentoFinanceiroAvancado = true;
  @track showPontualidadePagamentoPJ = true;
  @track showGastoEstimadoPJPositivo = true;
  @track showAlertaCadastralEmpresa = true;
  @track showInformacoesAnotacoesNegativas = true;
  @track showDadosFaturamentoEstimadoPositivo = true;
  @track showHistoricoPositivo = true;
  @track showInformacoesSobreConsultas = true;
  
  //tabelas dos componente de linha e seus titulos
  @track tbQuadroSocial = '';
  @track tbQuadroSocialTITULO = '';
  @track tbAdministracao = '';
  @track tbAdministracaoTITULO = ''
  @track tbResumoConcentre = '';
  @track tbResumoConcentreTITULO = '';
  @track tbUltimasConsultas = '';
  @track tbUltimasConsultasTITULO = '';
  @track tbCheques = '';
  @track tbChequesTITULO = '';
  @track tbAnotacoesSpcSociosAdministradores = '';
  @track tbAnotacoesSpcSociosAdministradoresTITULO = '';
  @track tbConsultasSpcSociosAdministradores = '';
  @track tbConsultasSpcSociosAdministradoresTITULO = '';
  @track tbPerfilFinanceiro = '';
  @track tbPerfilFinanceiroTITULO = '';
  @track tbIndicesEconomicos = '';
  @track tbIndicesEconomicosTITULO = '';
  @track tbFalenciaErecuperacao = '';
  @track tbFalenciaErecuperacaoTITULO = '';
  @track tbProtestos = '';
  @track tbProtestosTITULO = '';
  @track tbAcoesJudiciais = '';
  @track tbAcoesJudiciaisTITULO = '';
  @track tbDividasVencidas = '';
  @track tbDividasVencidasTITULO = '';
  @track tbPendenciasFinanceirasPefin = '';
  @track tbPendenciasFinanceirasPefinTITULO = '';
  @track tbPendenciasFinanceirasRefin = '';
  @track tbPendenciasFinanceirasRefinTITULO = '';
  @track tbRecheques = '';
  @track tbRechequesTITULO = '';
  @track tbQuadroSocialMaisCompleto = '';
  @track tbQuadroSocialMaisCompletoTITULO = '';
  @track tbParticipacoes = '';
  @track tbParticipacoesTITULO = '';
  @track tbAlertaCadSociosAdms = '';
  @track tbAlertaCadSociosAdmsTITULO = '';
  @track tbRendaProSociosEAdministradoresPF = '';
  @track tbRendaProSociosEAdministradoresPFTITULO = '';
  @track tbScoreSociosPF = '';
  @track tbScoreSociosPFTITULO = '';
  @track tbIndiceRelacMercadoSetor = '';
  @track tbIndiceRelacMercadoSetorTITULO = '';
  @track tbConsultasDetalhadas = '';
  @track tbConsultasDetalhadasTITULO = '';
  @track tbComportamentoPagamentoSetor = '';
  @track tbComportamentoPagamentoSetorTITULO = '';
  @track tbSituacaoFiscal = '';
  @track tbSituacaoFiscalTITULO = '';
  @track tbAlertaCadastral = '';
  @track tbAlertaCadastralTITULO = '';
  @track tbMosaic = '';
  @track tbMosaicTITULO = '';
  @track tbVendasCartao = '';
  @track tbVendasCartaoTITULO = '';
  @track tbIndicadorRecuperacaoCredito = '';
  @track tbIndicadorRecuperacaoCreditoTITULO = '';
  @track tbIndicadorRecuperacaoDivida = '';
  @track tbIndicadorRecuperacaoDividaTITULO = '';
  @track tbTelefonesEnderecosAdicionais = '';
  @track tbTelefonesEnderecosAdicionaisTITULO = '';
  @track tbDividasOrgaosPublicosEmpresa = '';
  @track tbDividasOrgaosPublicosEmpresaTITULO = '';
  @track tbLimiteCreditoPJ = '';
  @track tbLimiteCreditoPJTITULO = '';
  @track tbSerasaScore = '';
  @track tbSerasaScoreTITULO = '';
  @track tbPontualidadePagamentoPJ = '';
  @track tbPontualidadePagamentoPJTITULO = '';
  @track tbFaturamentoEstimadoComPositivo = '';
  @track tbFaturamentoEstimadoComPositivoTITULO = '';
  @track tbGastoEstimadoPJComPositivo = '';
  @track tbGastoEstimadoPJComPositivoTITULO = '';
  @track tbSerasaScoreSetorial = '';
  @track tbSerasaScoreSetorialTITULO = '';
  @track tbAlertaIdentidadePJ = '';
  @track tbAlertaIdentidadePJTITULO = '';
  @track tbObservacoesDadosCad = '';
  @track tbObservacoesDadosCadTITULO = '';
  @track tbGrafias = '';
  @track tbGrafiasTITULO = '';
  @track tbDetalhesConsulta = '';
  @track tbDetalhesConsultaTITULO = '';
  @track tbDadosCadastrais = '';
  @track tbDadosCadastraisTITULO = '';
  @track tbCompromissos = '';
  @track tbCompromissosTITULO = '';
  @track tbComportamentoDePagamento = '';
  @track tbComportamentoDePagamentoTITULO = '';
  @track tbContratosAtivos = '';
  @track tbContratosAtivosTITULO = '';
  @track tbComportamentoContratosAtivos = '';
  @track tbComportamentoContratosAtivosTITULO = '';
  @track tbAlertaEmNegocios = '';
  @track tbAlertaEmNegociosTITULO = '';
  @track tbSerasaScoreAtacadista = '';
  @track tbSerasaScoreAtacadistaTITULO = '';
  @track tbConsultasSPC = '';
  @track tbConsultasSPCTITULO = '';
  @track tbAnotacoesSPC = '';
  @track tbAnotacoesSPCTITULO = '';

  //utilizar os mesmos parametros que foram usados na ultima consulta
  renderedCallback(){
    getParametrosUltimaConsulta({accountId:this.recordId})
    .then((result) => {
      let parametros = result.split(',');
      let componentes = this.template.querySelectorAll('lightning-input');
      for( let i = 0 ; i < componentes.length ; i++ ){
        if(parametros.includes(componentes[i].name)){
          componentes[i].checked = true;
        }
      }
    });
  }

  gerarPDF() {
    console.log('gerar pdf...');
    /*
    var html = document.body.innerHTML;
    var doc = new jsPDF();
    doc.fromHTML(html, 10, 10);
    doc.save("Test.pdf");
    */
  }

  abrirTodos() {
    if(this.todosAbertos){
      console.log('fechando todos...');
      this.todosAbertos = false;
    }
    else{
      console.log('abrir todos...');
      this.todosAbertos = true;
    }
  }
    

  handleClickConfirmar() {

    this.isLoading = true;
    this.confirmaConsulta = true;
    this.render();
    const checked = Array.from(this.template.querySelectorAll('lightning-input'))
          .filter((element) => element.checked)
          .map((element) => element.name);

    this.HistoricoPositivoComercial              = checked.includes('HistoricoPositivoComercial');            //ok
    this.PagamentoFinanceiroAvancado             = checked.includes('PagamentoFinanceiroAvancado');
    this.PontualidadePagamentoPJ                 = checked.includes('PontualidadePagamentoPJ');               //ok
    this.FaturamentoEstimadoPositivo             = checked.includes('FaturamentoEstimadoPositivo');           //ok
    this.GastoEstimadoPJPositivo                 = checked.includes('GastoEstimadoPJPositivo');               //ok
    this.LimiteCreditoPJ                         = checked.includes('LimiteCreditoPJ');                       //ok
    this.SerasaScoreSetorial                     = checked.includes('SerasaScoreSetorial');                   //ok
    this.SerasaScoreAtacadista                   = checked.includes('SerasaScoreAtacadista');                 //ok
    this.QuadroSocialAdministracaoMaisCompleto   = checked.includes('QuadroSocialAdministracaoMaisCompleto'); //ok
    this.AnotacoesConsultasSPCSocios             = checked.includes('AnotacoesConsultasSPCSocios');           //ok
    this.Participacoes                           = checked.includes('Participacoes');                         //ok
    this.AlertaCadastralSociosEAdministradores   = checked.includes('AlertaCadastralSociosEAdministradores'); //ok
    this.RendaProSociosEAdministradoresPF        = checked.includes('RendaProSociosEAdministradoresPF');      //ok
    this.SerasaScoreSociosPF                     = checked.includes('SerasaScoreSociosPF');                   //ok
    this.IndiceRelacionamentoMercadoSetor        = checked.includes('IndiceRelacionamentoMercadoSetor');      //ok
    this.ComportamentoPagamentoSetor             = checked.includes('ComportamentoPagamentoSetor');           //ok
    this.ConsultasDetalhadasSerasa               = checked.includes('ConsultasDetalhadasSerasa');
    this.SituacaoFiscal                          = checked.includes('SituacaoFiscal');                        //ok
    this.AlertaIdentidadePJ                      = checked.includes('AlertaIdentidadePJ');                    //ok
    this.AlertaCadastralEmpresa                  = checked.includes('AlertaCadastralEmpresa');                //ok
    this.VendasCartao                            = checked.includes('VendasCartao');                          //ok
    this.MosaicBusiness                          = checked.includes('MosaicBusiness');                        //ok
    this.IndicadorRecuperacaoCredito             = checked.includes('IndicadorRecuperacaoCredito');           //ok
    this.EnderecosTelefonesAdicionais            = checked.includes('EnderecosTelefonesAdicionais');          //ok
    this.IndicadorRecuperacaoDividas             = checked.includes('IndicadorRecuperacaoDividas');           //ok
    this.AnotacoesConsultasSPC                   = checked.includes('AnotacoesConsultasSPC');                 //ok  
    this.MaisAnotacoes                           = checked.includes('MaisAnotacoes');
    this.DividasOrgaosPublicosEmpresa            = checked.includes('DividasOrgaosPublicosEmpresa');          //ok

    consultarSerasa({ accountId: this.recordId, parametros: checked})
    .then((result) => {

      this.consulta = JSON.parse(result); 
      let cadEmpGuide = ['CNPJ', 'Situação do CNPJ', 'Razão social', 'Nome fantasia', 'Endereço completo', 'Telefone', 'Site', 'Tipo de sociedade', 'Registro', 'Registro realizado em', 'NIRE','Antecessora', 'Data fundação', 'Número de funcionários', 'Opção tributária', 'Inscrição estadual', 'Ramo de atividade econômica', 'Indústria', 'Código de atividade serasa','Importação sobre compras', 'Exportação sobre vendas', 'CNAE','Número de filiais','Grafias','Quantidade Grafias','Última Atualização dos Dados Cadastrais','Inscrição Estadual','Observações'];
      this.dadosCadEmp = this.copySortFields(this.consulta.dadosCadEmp,cadEmpGuide);
      this.copyData(this.consulta.dadosCadEmp,[]);
      //this.showDadosCadEmp = this.dadosCadEmp.length>0 ? true:false; 
  
      this.copyData(this.consulta.informacoesAnotacoesNegativas, this.informacoesAnotacoesNegativas);
      this.showInformacoesAnotacoesNegativas = this.informacoesAnotacoesNegativas.length > 0? true:false;
      this.showInformacoesAnotacoesNegativas = true;
      
      this.copyData(this.consulta.informacoesPadrao, this.informacoesPadrao);
      this.showInformacoesPadrao = true;

      this.copyData(this.consulta.InformacoesSobreConsultas,this.dadosInformacoesSobreConsultas);
      //this.showInformacoesSobreConsultas = this.dadosInformacoesSobreConsultas.length > 0 ? true:false;
      //this.showInformacoesSobreConsultas = true;
      
      this.copyData(this.consulta.historicoPositivoComercial, this.dadosHistoricoPositivoComercial);
      this.showHistoricoPositivo = this.dadosHistoricoPositivoComercial.length > 0 ? true:false;
      
      this.copyData(this.consulta.pagamentoFinanceiroAvancado, this.dadosPagamentoFinanceiroAvancado);
      this.showHistoricoPagamentoFinanceiroAvancado = this.dadosPagamentoFinanceiroAvancado.length > 0 ? true:false;
      //this.showHistoricoPagamentoFinanceiroAvancado = true;
      
      this.copyData(this.consulta.pontualidadePagamentoPJ, this.dadosPontualidadePagamentoPJ);
      this.showPontualidadePagamentoPJ = this.dadosPontualidadePagamentoPJ.length > 0 ? true:false;
      
      this.copyData(this.consulta.faturamentoEstimadoPositivo, this.dadosFaturamentoEstimadoPositivo);
      this.showDadosFaturamentoEstimadoPositivo = this.dadosFaturamentoEstimadoPositivo.length > 0 ? true:false;
      
      this.copyData(this.consulta.gastoEstimadoPJPositivo, this.dadosGastoEstimadoPJPositivo);
      this.showGastoEstimadoPJPositivo = this.dadosGastoEstimadoPJPositivo.length > 0 ? true:false;

      this.copyData(this.consulta.informacoesSobreSociosAdministradores,this.dadosInformacoesSobreSociosAdministradores);
      
      this.copyData(this.consulta.limiteCreditoPJ, this.dadosLimiteCreditoPJ);
      
      this.copyData(this.consulta.serasaScoreSetorial, this.dadosSerasaScoreSetorial);
      
      this.copyData(this.consulta.serasaScoreAtacadista, this.dadosSerasaScoreAtacadista);
      
      this.copyData(this.consulta.quadroSocialAdministracaoMaisCompleto, this.dadosQuadroSocialAdministracaoMaisCompleto);
      //this.showQuadroSocialMaisCompleto = this.dadosQuadroSocialAdministracaoMaisCompleto.length > 0 ? true:false;

      this.copyData(this.consulta.anotacoesConsultasSPCSocios, this.dadosAnotacoesConsultasSPCSocios);
      
      this.copyData(this.consulta.participacoes, this.dadosParticipacoes);
      
      this.copyData(this.consulta.alertaCadastralSociosEAdministradores, this.dadosAlertaCadastralSociosEAdministradores);
      
      this.copyData(this.consulta.rendaProSociosEAdministradoresPF, this.dadosRendaProSociosEAdministradoresPF);
      
      this.copyData(this.consulta.serasaScoreSociosPF, this.dadosSerasaScoreSociosPF);
      
      this.copyData(this.consulta.indiceRelacionamentoMercadoSetor, this.dadosIndiceRelacionamentoMercadoSetor);
      
      this.copyData(this.consulta.comportamentoPagamentoSetor, this.dadosComportamentoPagamentoSetor);
      
      this.copyData(this.consulta.consultasDetalhadasSerasa, this.dadosConsultasDetalhadasSerasa);
      
      this.copyData(this.consulta.situacaoFiscal, this.dadosSituacaoFiscal);
      
      this.copyData(this.consulta.alertaIdentidadePJ, this.dadosAlertaIdentidadePJ);
      
      this.copyData(this.consulta.alertaCadastralEmpresa,this.dadosAlertaCadastralEmpresa);
      this.showAlertaCadastralEmpresa = this.dadosAlertaCadastralEmpresa.length > 0 ? true:false;
      
      this.copyData(this.consulta.vendasCartao, this.dadosVendasCartao);
      
      this.copyData(this.consulta.mosaicBusiness, this.dadosMosaicBusiness);
      
      this.copyData(this.consulta.indicadorRecuperacaoCredito, this.dadosIndicadorRecuperacaoCredito);
      
      this.copyData(this.consulta.enderecosTelefonesAdicionais, this.dadosEnderecosTelefonesAdicionais);
      
      this.copyData(this.consulta.indicadorRecuperacaoDividas, this.dadosIndicadorRecuperacaoDividas);
      
      this.copyData(this.consulta.anotacoesConsultasSPC, this.dadosAnotacoesConsultasSPC);
      
      this.copyData(this.consulta.maisAnotacoes, this.dadosMaisAnotacoes);
      
      this.copyData(this.consulta.dividasOrgaosPublicosEmpresa, this.dadosDividasOrgaosPublicosEmpresa);
      
      this.copyData(this.consulta.perfilFinanceiro, this.dadosPerfilFinanceiro);
      this.showPerfilFinanceiro = this.dadosPerfilFinanceiro.length > 0 ? true:false;
      this.isLoading = false;
    })
    .catch((error) => {
      this.dispatchEvent(
        new ShowToastEvent({
          title: 'Something went wrong',
          message: error.body.message,
          variant: 'error'
        })
      );
    })
  }

  copySortFields(fields, guide){
    let orderedFields = [];
    for (const  i in guide) {
      for (const  key in fields) {
        if(key== guide[i]){
          orderedFields.push({key:key,value:fields[key] });
        }
      }
    }
    return orderedFields;
  }
  

  
  copyData(origin, target){
    for (const  key in origin) {
      //console.log(key+':'+origin[key]);


      
      //Visão Geral
      if(key == 'Tabela-DetalhesConsulta'){
        this.tbDetalhesConsulta = origin[key];
        this.tbDetalhesConsultaTITULO = '<h3 class="slds-text-title slds-m-bottom_small">Detalhes da consulta</h3>';
      }
      else if(key == 'Tabela-AlertaEmNegocios'){
        this.tbAlertaEmNegocios = origin[key];
        this.tbAlertaEmNegociosTITULO = '<h3 class="slds-text-title slds-m-bottom_small">Alerta em Negócios</h3>';
      }
      else if(key == 'Tabela-SerasaScore'){
        this.tbSerasaScore = origin[key];
        this.tbSerasaScoreTITULO = '<h3 class="slds-text-title slds-m-bottom_small">Serasa Score 2.0</h3>';
      }  
      else if(key == 'Tabela-SerasaScoreSetorial'){
        this.tbSerasaScoreSetorial = origin[key];
        this.tbSerasaScoreSetorialTITULO = '<h3 class="slds-text-title slds-m-bottom_small">Serasa Score Setorial</h3>';
      }  
      else if(key == 'Tabela-SerasaScoreAtacadista'){
        this.tbSerasaScoreAtacadista = origin[key];
        this.tbSerasaScoreAtacadistaTITULO = '<h3 class="slds-text-title slds-m-bottom_small">Serasa Score Atacadista</h3>';
      } 
      else if(key == 'Tabela-PontualidadePagamentoPJ'){
        this.tbPontualidadePagamentoPJ = origin[key];
        this.tbPontualidadePagamentoPJTITULO = '<h3 class="slds-text-title slds-m-bottom_small">Pontualidade de Pagamentos PJ</h3>';
      }  
      else if(key == 'Tabela-AlertaDeIdentidadePJ'){
        this.tbAlertaIdentidadePJ = origin[key];
        this.tbAlertaIdentidadePJTITULO = '<h3 class="slds-text-title slds-m-bottom_small">Alerta de Identidade PJ</h3>';
      }  
      else if(key == 'Tabela-FaturamentoEstimadoComPositivo'){
        this.tbFaturamentoEstimadoComPositivo = origin[key];
        this.tbFaturamentoEstimadoComPositivoTITULO = '<h3 class="slds-text-title slds-m-bottom_small">Faturamento Estimado com Positivo</h3>';
      }  
      else if(key == 'Tabela-GastoEstimadoPJComPositivo'){
        this.tbGastoEstimadoPJComPositivo = origin[key];
        this.tbGastoEstimadoPJComPositivoTITULO = '<h3 class="slds-text-title slds-m-bottom_small">Gasto Estimado PJ com Positivo</h3>';
      } 
      else if(key == 'Tabela-LimiteCreditoPJ'){
        this.tbLimiteCreditoPJ = origin[key];
        this.tbLimiteCreditoPJTITULO = '<h3  class="slds-text-title slds-m-bottom_small">Limite de Crédito PJ</h3>';
      }
      
      
      //Dados cadastrais
      else if(key == 'Tabela-AlertaCadastral'){
        this.tbAlertaCadastral = origin[key];
        this.tbAlertaCadastralTITULO = '<h3  class="slds-text-title slds-m-bottom_small">Alerta Cadastral da Empresa</h3>';
      }
      else if(key == 'Tabela-DadosCadastrais'){
        this.tbDadosCadastrais = origin[key];
        this.tbDadosCadastraisTITULO = '<h3 class="slds-text-title slds-m-bottom_small">Dados Cadastrais</h3>';
      } 
      else if(key == 'Tabela-Grafias'){
        this.tbGrafias = origin[key];
        this.tbGrafiasTITULO = '<h3 class="slds-text-title slds-m-bottom_small">Grafias Semelhantes ao CNPJ</h3>';
      } 
      else if(key == 'Tabela-vendasCartao'){
        this.tbVendasCartao = origin[key];
        this.tbVendasCartaoTITULO = '<h3  class="slds-text-title slds-m-bottom_small">Vendas Cartão</h3>';
      }
      else if(key == 'Tabela-Mosaic'){
        this.tbMosaic = origin[key];
        this.tbMosaicTITULO = '<h3  class="slds-text-title slds-m-bottom_small">Mosaic Business</h3>';
      }
      else if(key == 'Tabela-SituacaoFiscal'){
        this.tbSituacaoFiscal = origin[key];
        this.tbSituacaoFiscalTITULO = '<h3  class="slds-text-title slds-m-bottom_small">Situação Fiscal</h3>';
      }
      else if(key == 'Tabela-TelefonesEnderecosAdicionais'){
        this.tbTelefonesEnderecosAdicionais = origin[key];
        this.tbTelefonesEnderecosAdicionaisTITULO = '<h3  class="slds-text-title slds-m-bottom_small">Endereços e Telefones Adicionais</h3>';
      }
      else if(key == 'Tabela-observacoesDadosCad'){
        this.tbObservacoesDadosCad = origin[key];
        this.tbObservacoesDadosCadTITULO = '<h3 class="slds-text-title slds-m-bottom_small">Observações</h3>';
      }  


      //Informações sobre Sócios e Administradores
      else if(key == 'Tabela-AlertaCadSociosAdms'){
        this.tbAlertaCadSociosAdms = origin[key];
        this.tbAlertaCadSociosAdmsTITULO = '<h3  class="slds-text-title slds-m-bottom_small">Alerta Cadastral dos Sócios e Administradores</h3>';
      }
      else if(key == 'Tabela-sociosAcionistas'){
        this.tbQuadroSocial = origin[key];
        this.tbQuadroSocialTITULO = '<h3  class="slds-text-title slds-m-bottom_small">Quadro Social</h3>';
      }
      else if(key == 'Tabela-Administração'){
        this.tbAdministracao = origin[key];
        this.tbAdministracaoTITULO = '<h3  class="slds-text-title slds-m-bottom_small">Administração</h3>';
      }
      else if(key == 'Tabela-quadroSocialMaisCompleto'){
        this.tbQuadroSocialMaisCompleto = origin[key];
        this.tbQuadroSocialMaisCompletoTITULO = '<h3  class="slds-text-title slds-m-bottom_small">Quadro Social mais completo</h3>';
      }
      else if(key == 'Tabela-AnotacoesSpcSociosAdministradores'){
        this.tbAnotacoesSpcSociosAdministradores = origin[key];
        this.tbAnotacoesSpcSociosAdministradoresTITULO = '<h3  class="slds-text-title slds-m-bottom_small">Anotações SPC Sócios e Administradores</h3>';
      }
      else if(key == 'Tabela-ConsultasSpcSociosAdimistradores'){
        this.tbConsultasSpcSociosAdministradores = origin[key];
        this.tbConsultasSpcSociosAdministradoresTITULO = '<h3  class="slds-text-title slds-m-bottom_small">Consultas realizadas para o CPF/CNPJ dos sócios e administradores no SPC</h3>';
      }
      else if(key == 'Tabela-RendaProSociosEAdministradoresPF'){
        this.tbRendaProSociosEAdministradoresPF = origin[key];
        this.tbRendaProSociosEAdministradoresPFTITULO = '<h3  class="slds-text-title slds-m-bottom_small">Renda Estimada-Sócios e Administrador PF</h3>';
      }
      else if(key == 'Tabela-participacoes'){
        this.tbParticipacoes = origin[key];
        this.tbParticipacoesTITULO = '<h3  class="slds-text-title slds-m-bottom_small">Participações</h3>';
      }
      else if(key == 'Tabela-ScoreSociosPF'){
        this.tbScoreSociosPF = origin[key];
        this.tbScoreSociosPFTITULO = '<h3  class="slds-text-title slds-m-bottom_small">Serasa Score - Sócios PF</h3>';
      }


      //perfil financeiro
      else if(key == 'Tabela-perfilFinanceiro'){
        this.tbPerfilFinanceiro = origin[key];
        this.tbPerfilFinanceiroTITULO = '<h3 class="slds-text-title slds-m-bottom_small">Balanço</h3>';
      }
      else if(key == 'Tabela-indiceEconomico'){
        this.tbIndicesEconomicos = origin[key];
        this.tbIndicesEconomicosTITULO = '<h3 class="slds-text-title slds-m-bottom_small">Índices econômicos - Financeiros</h3>';
      }


      //Informações sobre consultas
      else if(key=='Tabela-ultimasConsultas'){
        this.tbUltimasConsultas = origin[key];
        this.tbUltimasConsultasTITULO = '<h3 class="slds-text-title slds-m-bottom_small"><b>Consultas à Serasa</b> - Últimas 5 Consultas Realizadas</h3>';
      }
      else if(key == 'Tabela-ConsultasDetalhadas'){
        this.tbConsultasDetalhadas = origin[key];
        this.tbConsultasDetalhadasTITULO = '<h3  class="slds-text-title slds-m-bottom_small">Consultas Detalhadas à Serasa</h3>';
      }
      else if(key == 'Tabela-ConsultasSPC'){
        this.tbConsultasSPC = origin[key];
        this.tbConsultasSPCTITULO = '<h3  class="slds-text-title slds-m-bottom_small">Consultas ao SPC</h3>';
      }
      else if(key == 'Tabela-IndiceRelacMercadoSetor'){
        this.tbIndiceRelacMercadoSetor = origin[key];
        this.tbIndiceRelacMercadoSetorTITULO = '<h3  class="slds-text-title slds-m-bottom_small">Índice Relacionamento Mercado e Setor</h3>';
      }


      //Historico de Pagamento Financeiro - Avançado
      else if(key == 'Tabela-Compromissos'){
        this.tbCompromissos = origin[key];
        this.tbCompromissosTITULO = '<h3  class="slds-text-title slds-m-bottom_small"><b>Compromissos</b> - Últimos 5 anos</h3>';
      }
      else if(key == 'Tabela-ComportamentoDePagamento'){
        this.tbComportamentoDePagamento = origin[key];
        this.tbComportamentoDePagamentoTITULO = '<h3  class="slds-text-title slds-m-bottom_small"><b>Comportamento de Pagamento</b> - Últimos 5 anos</h3>';
      }
      else if(key == 'Tabela-ContratosAtivos'){
        this.tbContratosAtivos = origin[key];
        this.tbContratosAtivosTITULO = '<h3  class="slds-text-title slds-m-bottom_small"><b>Contratos Ativos</h3>';
      }
      else if(key == 'Tabela-ComportamentoContratosAtivos'){
        this.tbComportamentoContratosAtivos = origin[key];
        this.tbComportamentoContratosAtivosTITULO = '<h3  class="slds-text-title slds-m-bottom_small">Comportamento - Contratos Ativos</h3>';
      }
      else if(key == 'Tabela-ComportamentoPagamentoSetor'){
        this.tbComportamentoPagamentoSetor = origin[key];
        this.tbComportamentoPagamentoSetorTITULO = '<h3  class="slds-text-title slds-m-bottom_small">Comportamento de Pagamento do Setor</h3>';
      }
      


      //Informações Anotações Negativas
      else if(key =='Tabela-Concentre'){
        this.tbResumoConcentre = origin[key];
        this.tbResumoConcentreTITULO = '<h3  class="slds-text-title slds-m-bottom_small"><b>Resumo</b></h3>';
      }
      else if(key == 'Tabela-pendenciasFinanceirasPefin'){
        this.tbPendenciasFinanceirasPefin = origin[key];
        this.tbPendenciasFinanceirasPefinTITULO = '<h3  class="slds-text-title slds-m-bottom_small"><b>Dívidas em Outros Segmentos</b><br>PEFIN - Até 5 ocorrências mais recentes</h3>';
      }
      else if(key == 'Tabela-pendenciasFinanceirasRefin'){
        this.tbPendenciasFinanceirasRefin = origin[key];
        this.tbPendenciasFinanceirasRefinTITULO = '<h3  class="slds-text-title slds-m-bottom_small"><b>Dívidas em Instituições Financeiras (REFIN)</b> - Até 5 ocorrências mais recentes ?</h3>';
      }
      else if(key == 'Tabela-dividasVencidas'){
        this.tbDividasVencidas = origin[key];
        this.tbDividasVencidasTITULO = '<h3  class="slds-text-title slds-m-bottom_small"><b>Dívidas Vencidas</b> - Até 5 ocorrências mais recentes</h3>';
      }
      else if(key == 'Tabela-acoesJudiciais'){
        this.tbAcoesJudiciais = origin[key];
        this.tbAcoesJudiciaisTITULO = '<h3  class="slds-text-title slds-m-bottom_small"><b>Ações Judiciais</b> - Até 5 ocorrências mais recentes</h3>';
      }
      else if(key == 'Tabela-Protestos'){
        this.tbProtestos = origin[key];
        this.tbProtestosTITULO = '<h3  class="slds-text-title slds-m-bottom_small"><b>Protestos</b> - Até 5 ocorrências mais recentes</h3>';   
      }
      else if(key == 'Tabela-falenciaErecuperacao'){
        this.tbFalenciaErecuperacao = origin[key];
        this.tbFalenciaErecuperacaoTITULO = '<h3  class="slds-text-title slds-m-bottom_small"><b>Falência, Recuperação Judicial / Extrajudicial e Concordata</b> - Até 5 ocorrências mais recentesinanceiros</h3>';
      }
      else if(key == 'Tabela-cheques'){
        this.tbCheques = origin[key];
        this.tbChequesTITULO = '<h3  class="slds-text-title slds-m-bottom_small"><b>Cheques</b></h3>';
      }
      else if(key == 'Tabela-recheques'){
        this.tbRecheques = origin[key];
        this.tbRechequesTITULO = '<h3  class="slds-text-title slds-m-bottom_small"><b>Informações do Recheque - Cheques Extraviados / Sustados</b></h3>';
      }
      else if(key == 'Tabela-DividasOrgaosPublicosEmpresa'){
        this.tbDividasOrgaosPublicosEmpresa = origin[key];
        this.tbDividasOrgaosPublicosEmpresaTITULO = '<h3  class="slds-text-title slds-m-bottom_small">Dívidas com Órgãos Públicos - Empresa</h3>';
      }
      else if(key == 'Tabela-AnotacoesSPC'){
        this.tbAnotacoesSPC = origin[key];
        this.tbAnotacoesSPCTITULO = '<h3  class="slds-text-title slds-m-bottom_small">Anotações SPC</h3>';
      }
      else if(key == 'Tabela-IndicadorRecuperacaoDivida'){
        this.tbIndicadorRecuperacaoDivida = origin[key];
        this.tbIndicadorRecuperacaoDividaTITULO = '<h3  class="slds-text-title slds-m-bottom_small">Indicador de Recuperação de Dívidas</h3>';
      }
      else if(key == 'Tabela-IndicadorRecuperacaoCredito'){
        this.tbIndicadorRecuperacaoCredito = origin[key];
        this.tbIndicadorRecuperacaoCreditoTITULO = '<h3  class="slds-text-title slds-m-bottom_small">Indicador de Recuperação de Crédito</h3>';
      }
      
  
      else if(key.substring(0,1) != '$' && target != null){
        target.push({key:key,value:origin[key] });
      }
    }
  }

  toogleView(){
    alert('teste...');
  }

}