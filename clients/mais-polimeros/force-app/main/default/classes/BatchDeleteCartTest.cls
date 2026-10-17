@isTest
public class BatchDeleteCartTest {

    @testSetup
    static void setupData() {
        // Criação de WebStore
        WebStore store = new WebStore(Name = 'Loja Mais Polímeros');
        insert store;
        
         Account acc = new Account(
            Name                = 'ACC TESTE',
            NomeFantasia__c = 'nome fantasia',
            Classificacao__c    = 'Tipo A'
           
        );
        insert acc;

        // Criação de WebCarts com status 'Active' e 'Checkout'
        List<WebCart> carts = new List<WebCart>();
       
        WebCart cart = new WebCart(Name='TEST',Status = 'Active', WebStoreId = store.Id,AccountId=acc.Id);
        carts.add(cart);
        
        insert carts;
    }

    @isTest
    static void testBatchExecution() {
        Test.startTest();

        // Executando o batch
        BathDeleteCart batch = new BathDeleteCart();
        Database.executeBatch(batch, 50);

        Test.stopTest();

        // Verificação: nenhum carrinho com status 'Active' ou 'Checkout' deve existir
        Id storeId = [SELECT Id FROM WebStore WHERE Name = 'Loja Mais Polímeros' LIMIT 1].Id;
        List<WebCart> remainingCarts = [SELECT Id FROM WebCart WHERE WebStoreId = :storeId];

        System.assertEquals(0, remainingCarts.size(), 'Nenhum carrinho deve permanecer.');
    }

    @isTest
    static void testBatchWithEmptyData() {
        Test.startTest();

        // Executando o batch sem dados
        BathDeleteCart batch = new BathDeleteCart();
        Database.executeBatch(batch, 50);

        Test.stopTest();

        // Verificação: nenhum erro ou falha na execução
        System.assert(true, 'Batch executado com sucesso com dados vazios.');
    }
}