@isTest
public class ContasSemMovimentoControllerTest {
   /* @testSetup static void testSetup(){
        
        //Cria conta
        Account acc = new Account(

            Name = 'Conta teste' ,
            beeCnpj__CNPJ__c = '000100010001000000',
            Municipio__c= 'FORTALEZA',
            MunicipioEntrega__c= 'FORTALEZA'
        );
        insert acc;

        //condição de pagamento
        CondicaoPagamento__c condP = new CondicaoPagamento__c(

            Name = 'À vista',
            descricao__c = 'Descrição'
        );
        insert condP;
        //Unidade filial
        UnidadeFilial__c uniF = NEW UnidadeFilial__c(

            Name = 'Unidade Filial'
        );
        insert uniF;

        //Cria oportunidade
        Opportunity opp = new Opportunity(

            Name = 'Opp Teste',
            StageName = 'Proposal',
            RecordTypeId = 
            CloseDate = 01/03/22,
            TipoTES__c = '734',
            TesReceptor__c = '734',
            Unidade_Filial__c= uniF.Id,
            AccountId = acc.id,
            CondicaoPagamento__c = condP.Id,
            FormaDePagamento__c='DH- Dinheiro'
        );
        insert opp;

    }
    static testMethod void SkuCriaAtualizaProdutoTest(){

        List<Object> param = new List<Object>();
        Object data = '01/03/22' ;
        param.add(data);
        Object boo =  'true'; 
        param.add(boo);
        Object role = 'Representante vendas, Vendedor interno';
        param.add(role);
        ContasSemMovimentoController.invocableCarregaArquivos(param);

    }*/
}