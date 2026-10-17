public without sharing class B2BUtil {
    public static WebStore getStore() {
        WebStore store;
        if (!Test.isRunningTest()){
            System.debug(Network.getNetworkId());
            Network storeNetWork = [SELECT Name FROM Network WHERE Id =: Network.getNetworkId()];
            store = [SELECT Id, Type FROM WebStore WHERE Name =: storeNetWork.Name];
        } else {
            store = [SELECT Id, Type FROM WebStore LIMIT 1];
        }
        return store;
    }

    public static String getTES(String cartId){
        // 0a6880000000fRNAAY

        Map<String,String> mapUfOrigem = new Map<String,String>();
        mapUfOrigem.put('01', 'SP');
        mapUfOrigem.put('02', 'PR');
        mapUfOrigem.put('04', 'GO');
        mapUfOrigem.put('06', 'RS');
        mapUfOrigem.put('07', 'SC');
        mapUfOrigem.put('08', 'RS');

        CartDeliveryGroup cdg = [   SELECT  Id
                                            , DeliverToState
                                            , Cart.Filial__c
                                            , Cart.TipoVenda__c
                                    FROM    CartDeliveryGroup
                                    WHERE   CartId = :cartId    ];

        List<AggregateResult> lstAgg = new List<AggregateResult>();
        lstAgg = [    SELECT  Product2.Fabricante__c fabricante
                        FROM    CartItem
                        WHERE   CartId = :cartId
                        AND     Type = 'Product'
                        GROUP BY Product2.Fabricante__c ];

        String fabricante = '';
        if(lstAgg.size() > 1){
            // Erro
        } else {
            fabricante = (String)lstAgg[0].get('fabricante') + '%';
        }

        String filial = String.isBlank(cdg.Cart.Filial__c) ? '01' : cdg.Cart.Filial__c;
        String ufOrigem = mapUfOrigem.get(filial);
        String ufDestino = String.isBlank(cdg.DeliverToState) ? 'SP' : cdg.DeliverToState;
        Boolean foraEstado = (ufOrigem != ufDestino);
        Boolean regimeEspecial = false;

        String tipoVenda = cdg.Cart.TipoVenda__c;
        Boolean operacaoTriangular = false;
        Boolean consumidorFinal = false;
        Boolean suframa = false;
        Boolean vendaDireta = false;

        if(String.isBlank(tipoVenda)){
            vendaDireta = true;
        } else {
            operacaoTriangular = (tipoVenda.containsIgnoreCase('triangular'));
            consumidorFinal = (tipoVenda.containsIgnoreCase('consumidor'));
            suframa = (tipoVenda.containsIgnoreCase('suframa'));
            vendaDireta = (tipoVenda.containsIgnoreCase('direta')) || (!operacaoTriangular && !consumidorFinal && !suframa);
        }

        String tes = [  SELECT  TES__c
                        FROM    TES__mdt
                        WHERE   Filial__c = :filial
                        AND     Fabricante__c LIKE :fabricante
                        AND     ForaEstado__c = :foraEstado
                        AND     VendaDireta__c = :vendaDireta
                        AND     VendaTriangular__c = :operacaoTriangular
                        AND     ConsumidorFinal__c = :consumidorFinal
                        AND     SUFRAMA__c = :suframa ]?.TES__c;

        if(String.isBlank(tes)){
            tes = '521';
        }

        System.debug('filial: ' + filial);
        System.debug('ufOrigem: ' + ufOrigem);
        System.debug('ufDestino: ' + ufDestino);
        System.debug('foraEstado: ' + foraEstado);
        System.debug('regimeEspecial: ' + regimeEspecial);
        System.debug('fabricante: ' + fabricante);
        System.debug('tipoVenda: ' + tipoVenda);
        System.debug('operacaoTriangular: ' + operacaoTriangular);
        System.debug('consumidorFinal: ' + consumidorFinal);
        System.debug('suframa: ' + suframa);
        System.debug('vendaDireta: ' + vendaDireta);
        System.debug('tes: ' + tes);
        return tes;
    }
}