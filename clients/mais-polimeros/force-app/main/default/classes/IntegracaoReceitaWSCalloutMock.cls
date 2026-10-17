global class IntegracaoReceitaWSCalloutMock  implements HttpCalloutMock {
    
    global HttpResponse respond(HttpRequest req) {
         
        HttpResponse res = new HttpResponse();

        res.setHeader('Content-Type', 'application/json'); 
        res.setBody('{"atividade_principal":[{"text":"Gestão e administração da propriedade imobiliária","code":"68.22-6-00"}],"data_situacao":"13/11/2013","complemento":"SLJ 201","tipo":"MATRIZ","nome":"ADMINISTRADORA NORTH SHOPPING JOQUEI LTDA","uf":"CE","telefone":"(85) 8819-2856","atividades_secundarias":[{"text":"Estacionamento de veículos","code":"52.23-1-00"}],"qsa":[{"qual":"05-Administrador","nome":"MARCELO BAPTISTA CARVALHO"},{"qual":"22-Sócio","qual_rep_legal":"05-Administrador","nome_rep_legal":"MARCOS BAPTISTA CARVALHO","nome":"SPE FORTALEZA SHOPPING SA"},{"qual":"22-Sócio","qual_rep_legal":"05-Administrador","nome_rep_legal":"RODRIGO MORAES MARTINS","nome":"SPE ANDRIOS EMPREENDIMENTOS IMOBILIARIOS S.A."},{"qual":"05-Administrador","nome":"MARCOS BAPTISTA CARVALHO"}],"situacao":"ATIVA","bairro":"JOQUEI CLUBE","logradouro":"AV LINEU MACHADO","numero":"419","cep":"60.520-101","municipio":"FORTALEZA","porte":"DEMAIS","abertura":"13/11/2013","natureza_juridica":"206-2 - Sociedade Empresária Limitada","fantasia":"ADMINISTRADORA NORTH SHOPPING JOQUEI LTDA","cnpj":"19.248.604/0001-80","ultima_atualizacao":"2022-02-16T09:49:14.907Z","status":"OK","email":"","efr":"","motivo_situacao":"","situacao_especial":"","data_situacao_especial":"","capital_social":"1000.00","extra":{},"billing":{"free":true,"database":true}}');

        res.setStatusCode(200);

        return res;

    }
}