@IsTest
private class TestProtheusInsertClientModel {

    @IsTest
    static void testProtheusInsertClientModel() {
        ProtheusInsertClientModel clientModel = new ProtheusInsertClientModel();
        clientModel.CodCRM = '001';
        clientModel.Loja = 'A';
        clientModel.Nome = 'Test Company';
        clientModel.Cidade = 'São Paulo';
        clientModel.UF = 'SP';
        clientModel.Bairro = 'Centro';
        clientModel.Endereco = 'Rua B, 123';
        clientModel.CEP = '02000-000';
        clientModel.DDD = '11';
        clientModel.Telefone = '98888-8888';
        clientModel.CGC = '12345678000195';
        clientModel.Vend1 = '001';
        clientModel.Vend2 = '002';
        clientModel.Risco = 'A';
        clientModel.LimCred = 50000;
        clientModel.VencLimCred = '2024-12-31';
        clientModel.Email = 'test@company.com';
        clientModel.Cnae = '654321';
        
        System.assertEquals('001', clientModel.CodCRM);
        System.assertEquals('A', clientModel.Loja);
        System.assertEquals('Test Company', clientModel.Nome);
        System.assertEquals('São Paulo', clientModel.Cidade);
        System.assertEquals('SP', clientModel.UF);
        System.assertEquals('Centro', clientModel.Bairro);
        System.assertEquals('Rua B, 123', clientModel.Endereco);
        System.assertEquals('02000-000', clientModel.CEP);
        System.assertEquals('11', clientModel.DDD);
        System.assertEquals('98888-8888', clientModel.Telefone);
        System.assertEquals('12345678000195', clientModel.CGC);
        System.assertEquals('001', clientModel.Vend1);
        System.assertEquals('002', clientModel.Vend2);
        System.assertEquals('A', clientModel.Risco);
        System.assertEquals(50000, clientModel.LimCred);
        System.assertEquals('2024-12-31', clientModel.VencLimCred);
        System.assertEquals('test@company.com', clientModel.Email);
        System.assertEquals('654321', clientModel.Cnae);
    }
}