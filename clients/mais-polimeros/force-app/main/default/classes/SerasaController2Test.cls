@IsTest
global with sharing class SerasaController2Test {

    @TestSetup
    static void makeData() {

        String CLIENTE_RECORD_TYPE = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Conta MP').getRecordTypeId();

        Contact contato = new COntact(
            FirstName = 'Teste 1',
            LastName = 'Teste 1',
            Email = 'teste1@email.com'
        );
        insert contato;

        Account acc = new Account (
            Name = 'Soares & Marinho',
            NomeFantasia__c = 'teste',
            RecordTypeId = CLIENTE_RECORD_TYPE,
            beeCnpj__CNPJ__c = '06074426000176',
            BillingState = 'SP',
            BillingCountry = 'BR'
             
        );
        insert acc;

    }

    global class MockHttpResponse200Generator implements HttpCalloutMock {
        global  HTTPResponse respond(HTTPRequest req) {

            String body = ''+
            'INI0138IP20RTOKS2        00423692022N            03N  000000000000000                                                                    '+
            'BLC2277'+
            '#L01000002                                                                               004236920 IPHXC08.01.2020                                    2N2  2SITUACAO DO CNPJ EM 13/07/2013: ATIVA                                                      '+
            '#L010101VICTOR MOURA                                                2020111911:38:04  CNPJ: 04.236.920/0001-6420130718 0000046485620130528'+
            '#L010102COEMA PAISAGISMO URBANIZACAO & SERVICOS LTDA                          004236920                                                            14200062737SOCIEDADE EMPRESARIA LIMITADA                               LUCRO PRESUMIDO               0206'+
            '#L010103R PACARAIMA 304 ED SUMARE - SAO VICENTE                               SAO VICENTE                   R PACARAIMA 304 ED SUMARE                                                       '+
            '#L010104BOA VISTA                     RR0693033600000000000000000000000                                                                                                                                                '+
            '#L0101052000110120010116SERVICOS DE JARDINAGEM                                S06040000000000000000000000431340020130726'+
            '#L010106BELO HORIZONTE                BHE #L010106BARUERI                       BRE #L010106BRASILIA                      BSA '+
            '#L01010820180614000041752512100004175251210000000000000ESTRANGEIRO PRIVADO     FECHADO      F'+
            '#L010109J010555483000044EXUWK RKYKFUSE SLHMKO M/C                                        ESTRANGEIRO 100000000000N100002S1600  C'+
            '#L01011020180614'+ 
            '#L010111F471633211000004HAWBKUSLW IIWCF OZURNRII                                  DIR         BRASIL      DIVORCIAD2012020000000000N0020720120208C#L010111F503999266000015IKVOX RLZXKKPFY FYYWE CF ZMNESRY                          DIRETOR     BRASIL               2015010000000000N0220720150102C#L010111F943997517000020XPZA NCLYIQ RQNRH SZGRACXWG                               DIRETOR     BRASIL      SOLTEIRO 2013070000000000N0220720130701C#L010111F862075981000072WWHYIK ROCAWO ZK YAKGWRAC CICEXY                          DIRETOR     BRASIL      CASADO   2015010000000000N0220720150102C'+
            '#L01011220230602 '+
            '#L01011303150964622WPUDRIU WDDLSKARKUWUVXM H OFLGWKWOHNANM G/Z                        N0000J02'+
            '#L010114RIVIX WKH ZLNESO E/Z                                               AC                                           10000N030621687000043J02'+
            '#L01011303151118008URFPKQ HAOIHSLZWDNUEYM F XCIPZFSACFXWE M/C                         N0000J02'+
            '#L010114RIVIX WKH ZLNESO E/Z                                               AC                                           10000N030621687000043J02'+
            '#L010116FJKE RORDLYCGWKH OJFH                                                 020160401         #L010116F E R G AKKLOWAZITYZVRNC W QVIUSIHAJAE AESZ                           020061013         '+
            '#L01011747163321100000420180614HAWBKUSLW IIWCF OZURNRII                                    0000001296819720530A                                00000000000000000                                                                                                                          0000000000000C'+
            '#L010118ADVOGADO    0000000000000000000000                        00000000000                                                            0000000000000000000000#L040199=== NADA CONSTA PARA O CPF CONSULTADO ===                                      #L040299=== NADA CONSTA PARA O CPF CONSULTADO ===                                       #L041099=== NADA CONSTA PARA O CPF CONSULTADO ===                                      '+
            '#L0101190105554830001442008123020180614EXUWK RKYKFUSE SLHMKO M/C                                                                           SC'+
            '#L010120EKUVRKKI                                                                                                                  00000000000000000000000000HOLDING                                                    '+
            '#L011399NAO CONSTA INFORMACAO DE PARTICIPACOES.                                        '+
            '#L0301012011NOV023000A               '+
            '#L0301012010OUT031000A               '+
            '#L0301012009SET007000A               '+
            '#L0301012008AGO017000A               '+
            '#L0301012007JUL026000A               '+
            '#L0301012006JUN024000A               '+
            '#L0301012005MAI032000A               '+
            '#L0301012004ABR037000A               '+
            '#L0301012003MAR017000A               '+
            '#L0301012002FEV023000A               '+
            '#L0301012001JAN033000A               '+
            '#L0301011912DEZ015000A               '+
            '#L0301011911NOV011000A               '+
            '#L0301011910OUT003000A               '+
            '#L03010220201117ATEND MT DISTRIB CARTOES TELEFONICO0001006207421 S'+
            '#L03010220201117ARCELORMITTAL BRASIL S/A           0025017469701 S'+
            '#L03010220201117SKUFX GISKQC E/H                   0001060889128 S'+
            '#L03010220201117FIBRASCA QUMICA TEXTIL LTDA        0001080662315 S'+
            '#L03010220201116FXUCWCFLZWFI WAVHTWJVKCVCY CCP KTII0001003795072 S'+
            '#L030103frase de alerta aqui frase alerta aqui frase de alerta aqui frase alerta aqui frase de alerta aqui frase alerta aqui fim :)22101998areareservadaparaq ?'+        
            '#L030303                             2023060107228128000156MAIS POLIMEROS DO BRASIL LTDA                                         00000005          #L030303                             2023053107228128000156MAIS POLIMEROS DO BRASIL LTDA                                         00000032          #L030303                             2023053007228128000156MAIS POLIMEROS DO BRASIL LTDA                                         00000003          '+
            '#L010198A EMPRESA INCORPOROU EM 03/2020 UCK CWGHUEUUVWTKXVX ZYXWKYKFLZT OPWK - CNPJ 11.20211030                                A'+
            '#L010999 PELAS CARACTERISTICAS SOCIETARIAS A INFORMACAO NAO SE APLICA '+
            '#L04010100000000400000000420211023SEGURO GARANN0000000000872CTR-PEFIN-105009TESTE CREDOR SEM HASMGB SG IPZ4V0074008002000000028                                                                                                                    0000000008983'+
            '#L04010200000000200000000220230125CRED.CARTAO N0000000000364MP38856600002982SANTANDER PAA CT IPZ4I0608652986062955505                                                                                                                   0000000000649B'+
            '#L040199=== NADA CONSTA PARA O CNPJ CONSULTADO ===                                   '+
            '#L040299=== NADA CONSTA PARA O CPF CONSULTADO ===                                  '+
            '#L04040100000005220230320EXECUCAO R$ 0000000000000010041RIO DE JANEIRO RJ EX IPZ4C0034284721062955505AAAAAAAAAAAAAAAAAAAAAAAAAAAABBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBVVVVVVVVVVVVVVVVVVVVVVVVVVCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCDDDDDDDDDDDDDDDDDDDDDDDEEEEEEEEEEEEE'+
            '#L04060100000000720211015RECUPERAC JUDIC REQ VARA0001SAO PAULO SPRR IPZ4E0000840449014310577                                                                                                                                      aaaaaaaaaaaaaaa'+
            '#L04070100000000220180820DEV R$ 0000000000642000000185100732SEFAZ TUCBD IPZ450489472973000000003                                                                                                                                                A'+
            '#L041099=== NADA CONSTA PARA O CNPJ CONSULTADO === '+
            '#L040201MARIA RAIMUNDA MATOS FRAZAO TESTANDO TESTANDO NOME TESTESTANDO TESTE TESTE'+
            '#L04090100000004720221227CCF-BB00001SANTANDER 1653 IPZ4O0134777583062955505 TESTES TESQUE TESTANDO O TESTE DE TESTES TESTANDO'+
            '#L040202000000002DIVIDA VENCIDA AGO0818AGO0818R$ 000000000064200000000015930700000000000000000000000000000000000000000000000000000000000000000000000'+
            '#L04030100000000220221201R$ 000000050000001SAO PAULO SP Z1 IPZ4A0006533017000000028 TESTE TESTANDO TESTE EU VOU TESTAR TODOAS AS CLASSES COM ESTE TESTE TESTANDO > TESTE < TESTE ... TESTANDO TESTESTANDO MAIS TESTE TESTE .. TESTES TESTANDO TESTE'+
            '#L04050112342342622101998AQUIFICAUMTIPODALGO11313993AQUI FICA o nome de alguma empresa provavelmenteTESTANDO TESTE TESTCDGAREA RESERCADA PARA ALGO IMPORTANTE'+
            '#L041000000000009000000006'+
            '#L041101NOME DO PARTICIPANTE VAI AQUI - ISSO DEVE TER 65 CARACTERES NODWA MAXIMO.11313993905J'+    
            '#L0701060206202311:09:40PROBABILIDADE DE INADIMPLENCIA:  1,17%                                         '+
            '#L0701090206202311:09:400520001170000C                 '+
            '#L0701120904202321:40:420001000000000         '+
            '#L0701130904202321:40:42SITUACAO DO CNPJ: INAPTO                  '+
            '#L0701990904202321:44:10SCORE NAO CALCULADO - INSUFICIENCIA INFORMACOES BASE DE DADOS SERASA EXPERIAN 23008360000                           '+
            '#L070401F1156957480000630000SUKVTRNNI RNLTHV SN YHRGC 000788C 14,8009/04/2321:42:300000990000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000'+
            '#L07049909/04/2321:40:4200005PORTE DA EMPRESA NAO E ALVO DE CALCULO                                      '+
            '#L0711990206202311:09:40SCORE NAO CALCULADO - INSUFICIENCIA INFORMACOES BASE DE DADOS SERASA EXPERIAN   008360000                                               '+            
            '#L1001010206202311:09:40000000542204100                                                       '+
            '#L1001020904202321:40:42SITUACAO DO CNPJ: INAPTO                                                         '+
            '#L1001990904202321:44:10GASTO NAO CALCULADO - INSUFICIENCIA INFORMACOES BASE DE DADOS SERASA EXPERIAN                                             '+
            '#L1201011131390512322101998'+
            '#L1201992023060211:09:42NAO FOI POSSIVEL IDENTIFICAR O MOSAIC BUSINESS REFERENTE A ESSA EMPRESA  '+
            '#L1202990206202311:09:42A EMPRESA NAO POSSUI NEGATIVOS DE ORDEM PUBLICA                                                     '+
            '#L1301010206202311:09:420091000DADOS AVALIADOS COM CADASTRO POSITIVO FINANCEIRO E COMERCIAL                    '+
            '#L1301990904202321:44:119990836SCORE NAO CALCULADO - INSUFICIENCIA INFORMACOES BASE DE DADOS SERASA EXPERIAN '+
            '#L27010120230405000063960000109PYH MPLHODNLWHZTG CA ZICGFU UGRF.                                     2ATIVA                         20051103N4711301HIPERMERCADOS                                                        '+
            '#L2701024647801COMERCIO ATACADISTA DE ARTIGOS DE ESCRITORIO E DE PAPELARIA           #L2701027490104ATIVIDADES DE INTERMEDIACAO E AGENCIAMENTO DE SERVICOS E NEGOCIOS EM G#L2701025611201RESTAURANTES E SIMILARES                                             '+
            '#L270103EMPRESA NAO CADASTRADA NA BASE SERASA EXPERIAN '+
            '#L270104199911300002062286721190004ATIVO                                                                                                                                                                                                   '+
            '#L27010520151115WAL MART BRASIL LTDA                                                                                20151115          '+
            '#L270106COMERCIO VAREJISTA DE MERCADORIAS EM GERAL, COM PREDOMINANCIA DE PRODUTOS ALIMENTICIOS - HIPERMERCADOS                                                '+
            '#L270107Observações do Sintegra/SEFAZ'+
            '#L270199ESSA EMPRESA POSSUI MAIS DE TRES CNAES SECUNDARIOS E/OU INSCRICOES ESTADUAIS, PARA VERIFICA-LOS ACESSE O CONFIE NO MENU DE PRODUTOS. CONSULTE A TABELA DE PRECO DESTE PRODUTO.                          '+
            '#L2801990206202311:09:41NAO HA ENDERECOS ADICIONAIS DESTA EMPRESA OU DE SEUS SOCIOS/ADMINISTRADORES                         '+
            '#L29010122101998004733270550XXXXXXXXX'+
            '#L2901992210199869240420ALGUMA MENSAGEM ALEATORIA AQUI, TALVEZ  ALGO RELACIONADO A ALGO IMPORTANTE QUE EU NÃO TENHO COMO VEESPACO RESERVADO SRRSA'+
            '#L300201020230103000000003000125FKJH NCLFSFSS LQMNJW IXWHOPF HK IITKKE NIXT DCEOSEPHUA 202304092140420000000000000000000000000000000000000000'+
            '#L300202020230409+000000000000000000000000000000000'+
            '#L300203020230409O FATURAMENTO ESTIMADO COM POSITIVO LEVOU EM CONSIDERACAO O MOTIVO: SITUACAO DO 0000000000000000000000000000000000o'+
            '#L300203020230409CNPJ: INAPTO 0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000'+
            '#L0701090904202321:40:420001000000000 '+
            '#L300299020230409SCORE NAO CALCULADO - INSUFICIENCIA INFORMACOES BASE DE DADOS SERASA EXPERIAN '+
            '#L03039909.04.2023 0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000'+
            '#L030303CDGOaqui esta a descricao :)2210199833270550123477NOME DE ALGUMA PESSOA FAMOSA COMO WILL SMITH 000415476000024FE09112021XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX12345678G'+
            '#L300901020201216062967294000182EPYNIYFLCCCI LYBI NVFK SH OICZH NLHUFN AESZ 007228128 20230409215928000000000000000000000000000000000000000000000'+
            '#L3009020202010311BRGAAP 2BALANCETE 101MILHARES 1REAL 000000000000000000000000000000000000000000000000000000000000000'+
            '#L30090300134027CLIENTES +000000249N0000000000000000000000'+
            '#L30090400127276FORNECEDORES +000001005N00000000000000000000'+
            '#L30090500109316RESULTADO BRUTO +000004870N0000000000000000000000'+
            '#L30130112345678Alguma mensagem Aleatoria            '+
            '#L3101012210199812345432423413213123141231223423423412312312654621231234234234234154364542342313123423421231212312354353413134523422342123123123123323423'+
            '#L3101022210199812345432423413213123141231223423423412312312654621231234234234234154364542342313123423421231212312354353413134523422342123123123123323423'+
            '#L310199 00880QUANTIDADE DE EMPRESAS INSUFICIENTE PARA CALCULO 000000000000000000000000000000000000000000'+
            '#L320101131722697712391203123123843291            '+
            '#L30090600 001ENDIVIDAMENTO TOTAL +0000000086000+0000000121000P0500888888888888888888888888888888888888888888888888888888888'+
            '#L30139923NAO FOI POSSIVEL CALCULO888888888888888888888888888888888888888888888888888888888888888888888'+
            '#L32010212312312353452342341231345345234                                        '+
            '#L320103131777                                  '+
            '#L32010442124121421443242342342123423413213124234235231231231242345235123424234346345243234561231232143242344123235235234123123123122432423423423423123423423423454363463241231231242342344123241231243252411235251231232423423412              '+
            '#L320199INFORMACOES INSUFICIENTES NA BASE PARA COMPOSICAO DOS DADOS POSITIVOS DO CNPJ CONSULTADO                                                                                                                                              '+            
            '#L32020143264334264523421431231231231231233                                     '+
            '#L32020212342342342342123123123423423423                                 '+
            '#L320203345326734                           '+
            '#32020423453412354312312312312312432421                            '+
            '#L32020523452356321275623412312312334523534521                               '+
            '#L32020631242163442353153453452341346363452                            '+
            '#L320297ALGUMA MENSAGEM RELATIvA A PONTUALIDADE DE PAGAMETO DEVE TER ATÉ 100 CARACTERE                         '+
            '#L320298ALGUMA MENSAGEM RELATIvA   DWADHAHAHAHAHA HAHAHAHAHAA HAAAAAAAAAAAAAAAAAAAAAF                         '+
            '#L320299ALGUMA MENSAGEM RELATIvA   ALGO   XXXXXXXXXXX HAHAHAHAHAA HAAAAAAAAAAAAAAAAAAAAAF                         '+
            '#L530101083500063960000109PYH MPLHODNLWHZTG CA ZICGFU UGRF                                               3A EMPRESA POSSUI MODERADA PROPENSAO A RECUPERACAO DE CREDITO                                                                                                                                                                             '+                                                                               
            '#530199332705501234773124alguma mensagem qualquer alguma mensagem qualquer alguma mensagem qualquerddddddawdwadddddxxxx                                                                                                                                                                                                   '+
            '#L571001000206228672119                               '+
            '#L580101NNN                                                                                                                        '+
            '#L580199342XXXXXXXXXXXXXwadawdawdawdwwwwwwwwwwcwadawcdwadvaddddaaxxxxxxxxxxxxxXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX            '+
            '#L600199010NAO FORAM IDENTIFICADAS ALTERACOES NOS ULTIMOS 12(DOZE) MESES                  '+
            '#L600101231243542342345221019982311199905062023                   '+
            '#600102234NOME VELHO DE ALGUEM IMPORTANTE TIPO O WILL SMITH OU ALGO DO TIPO    NOME novo DE ALGUEM IMPORTANTE TIPO O WILL SMITH OU ALGO DO TIPO     22101998'+
            '#L60020131423423423221019983327055023111999                '+
            '#L6002022341234521descricao para o cna atual. esta descricao deve ser ago importante pois        3123412descricao para o cna anterior. esta descricao deve ser ago importante pois        22101998       '+
            '#L600299020NAO FORAM IDENTIFICADAS ALTERACOES NOS ULTIMOS 12(DOZE) MESES                  '+
            '#L60030123412312345221019983327055023111999                '+
            '#L600302231alguma rua de algum lugar    completo bairro atual aqui  89056300SC4215123454353454rua antiga velha wdadawdcompletovbairro velho velho89056300MG432356421231235664564564            '+
            '#L600399030NAO FORAM IDENTIFICADAS ALTERACOES NOS ULTIMOS 12(DOZE) MESES (MUDANCA DE CEP) '+
            '#L600401123221019982311199933270550            '+
            '#L6004022311tipo societario fica aqui e tem 44 caracterextipo societario ante aqui e tem 44 caractere          22101998'+
            '#L600499040NAO FOI IDENTIFICADA ALTERACAO DO TIPO JURIDICO DA EMPRESA                     '+
            '#L600699060ESTA EMPRESA NAO POSSUI REGISTROS NA CNEP-CADASTRO NACIONAL DE EMPRESAS PUNIDAS'+
            '#L600701123345234753221019983327055023111999            '+
            '#L6007024561ESTA É A FRASE DE ALERTA DA INCONSISTENCIAS COMERCIAIS ESTA É A FRASE DE ALERTA DA INCONSISTENCIAS COMERCIAISxxxxxxxxxxxXXX22101998       XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'+        
            '#L600799073ESSA EMPRESA NAO E ALVO DE ANALISE                                             '+
            '#L610099025EMPRESA NAO E ALVO DE ALERTA CADASTRAL SOCIOS/ADMINISTRADORES                                       '+
            '#L610101092000000003090420230904202309042022                     '+
            '#L610102094RUBENS MENIN TEIXEIRA DE SOUZA 315836606000015FE18102021XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'+
            '#L610199090NAO FORAM IDENTIFICADAS ALTERACOES NOS ULTIMOS 12(DOZE) MESES                    '+
            '#L610201106000000007090420230904202309042022                              '+
            '#L610202104EDUARDO FISCHER TEIXEIRA DE SOUZA 000415476000024FE09112021XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'+
            '#L610299100NAO FORAM IDENTIFICADAS ALTERACOES NOS ULTIMOS 12(DOZE) MESES                               '+
            '#L610301111000000001090420230904202309042022                                    '+
            '#L610302117 ACOES EM TESOURARIA 008343492000120J(ESSA EMPRESA NAO E ALVO DE ANALISE) 09042023XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'+
            '#L610399115EMPRESA NAO E ALVO DE ALERTA CADASTRAL - INCONSISTENCIA SOCIETARIA PJ                           '+
            '#L610499125EMPRESA NAO E ALVO DE ALERTA CADASTRAL - INCONSISTENCIA ADMINISTRATIVA PJ                          '+
            '#L610599130NAO CONSTA INFORMACAO DE OBITO DOS SOCIOS NA BASE DE DADOS SERASA EXPERIAN                             '+
            '#L610699140NAO CONSTA OBITO DOS ADMINISTRADORES NA BASE DE DADOS SERASA EXPERIAN                          '+
            '#L700099001CONSULTA INDISPONIVEL                                                           '+
            '#L901099=== NADA CONSTA PARA O CNPJ CONSULTADO ===                                      '+
            '#L907099=== NADA CONSTA PARA O CNPJ CONSULTADO ===                                      '+
            '#L9010010603202023122019CB-1912-179171089 000000000006525NAWVIXLCGUU XKBUIIXDZJKOC SXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'+ 
            '#L907001230320230846 CDL - SAO PAULO/SP 0002                                                                                                                        '+
            '#L901002BARUERI SP ASSOCIACAO COMERCIAL - TESTE S                                                                   '+
            '#L901003000000000000004000000000000261                                          '+
            '#L9250010001J0306216870001430000SRIVIX WKH ZLNESO E/Z                                                  00000000000000000000000000000000000C'+
            '#L9250990001=== NADA CONSTA PARA O CNPJ CONSULTADO ===                                      '+
            '#L9250023124231242122342341123523423412312342353456343321C324234123123234412Blumenau SC OktobercityXXXXXXXXXXXXXSCNome de alguem importanteXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXorigem desta anotaçãoXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'+
            '#L9260010001J0306216870001430000SRIVIX WKH ZLNESO E/Z                                                  000000C'+
            '#L9260990001=== NADA CONSTA PARA O CNPJ CONSULTADO ===                                      '+
            '#L9250010002J0974226200001500000SSXOIIWHI NFZZH EVIWLUWIHCNIQ UVZH                                     00000000000000000000000000000000000C'+
            '#L9250990002=== NADA CONSTA PARA O CNPJ CONSULTADO ===                                      '+
            '#L9260010002J0974226200001500000SSXOIIWHI NFZZH EVIWLUWIHCNIQ UVZH                                     000000C'+
            '#L9260990002=== NADA CONSTA PARA O CNPJ CONSULTADO ===                                      '+
            '#L9250010003F0336525680000060000AOPKJ KOPDXRI ZFGMZX                                                   00000000000000000000000000000000000C'+
            '#L9250990003=== NADA CONSTA PARA O CPF CONSULTADO  ===                                      '+
            '#L9260010003F0336525680000060000AOPKJ KOPDXRI ZFGMZX                                                   000000C'+
            '#L9260990003=== NADA CONSTA PARA O CPF CONSULTADO  ===                                      '+
            '#L9250990001=== NADA CONSTA PARA O CNPJ CONSULTADO ===                                      '+
            '#L9260010001J0306216870001430000SRIVIX WKH ZLNESO E/Z                                                  000000C'+
            '#L9260990001=== NADA CONSTA PARA O CNPJ CONSULTADO ===                                      '+
            '#L9250010002J0974226200001500000SSXOIIWHI NFZZH EVIWLUWIHCNIQ UVZH                                     00000000000000000000000000000000000C'+
            '#L9250990002=== NADA CONSTA PARA O CNPJ CONSULTADO ===                                      '+
            '#L9260010002J0974226200001500000SSXOIIWHI NFZZH EVIWLUWIHCNIQ UVZH                                     000000C'+
            '#L9260990002=== NADA CONSTA PARA O CNPJ CONSULTADO ===                                      '+
            '#L9250010003F0336525680000060000AOPKJ KOPDXRI ZFGMZX                                                   00000000000000000000000000000000000C'+
            '#L9070022304ABR000#L9070022303MAR067#L9070022302FEV099                                         '+
            'L040199=== NADA CONSTA PARA O CNPJ CONSULTADO ===                                     '+
            'L040299=== NADA CONSTA PARA O CNPJ CONSULTADO ===                                     '+
            'L041099=== NADA CONSTA PARA O CNPJ CONSULTADO ===                                     '+
            'FIM9999';

            System.assertEquals('POST', req.getMethod());

            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'text/plain; charset=UTF-8');
            res.setBody(body);
            res.setStatusCode(200);
            return res;
        }
    }
    
    @IsTest
    static void TEST_consultarSerasa() {

        Account acc = [ SELECT Id, beeCnpj__CNPJ__c FROM Account LIMIT 1];

        Test.setMock(HttpCalloutMock.class, new MockHttpResponse200Generator());

        Test.startTest();

        List<String> parametros = new List<String>();
        SerasaController2.consultarSerasa(acc.Id,parametros);
        
        Test.stopTest();

    }

    @IsTest
    static void testEnviarAlertaDeErroPorEmail() {
        
        String mensagem = 'Exemplo de mensagem de erro';
        Integer initialEmailCount = Limits.getEmailInvocations();
        
        SerasaController2.enviarAlertaDeErroPorEmail(mensagem);
        Integer finalEmailCount = Limits.getEmailInvocations();
        Integer emailSentCount = finalEmailCount - initialEmailCount;

        System.assertEquals(1, emailSentCount, 'Deve ter sido enviado um e-mail de erro');
    }

    /*
    @IsTest
    static void testGetParametrosUltimaConsulta() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        List<String> parametros = new List<String>{'param1', 'param2', 'param3'};
        SerasaController2.setParametrosUltimaConsulta(acc.Id, parametros, acc);

        String parametrosRetornados = SerasaController2.getParametrosUltimaConsulta(acc.Id);

        System.assertEquals('param1,param2,param3', parametrosRetornados, 'Os parâmetros retornados não estão corretos');

        acc = [SELECT SerasaParametrosSelecionados__c FROM Account WHERE Id = :acc.Id];
        System.assertEquals('param1,param2,param3', acc.SerasaParametrosSelecionados__c, 'Os parâmetros não foram salvos corretamente no registro');
    }
    */

}