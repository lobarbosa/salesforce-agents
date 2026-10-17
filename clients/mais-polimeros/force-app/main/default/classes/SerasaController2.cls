/**
 * @description       : 
 * @author            : Ríad Nassiffe
 * @group             : 
 * @last modified on  : 05-06-2023
 * @last modified by  : José Mateus Amaral
**/

public with sharing class SerasaController2 {


    public static String fakeResponde = ''+
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




    /*****************************************************************************************************
    *                                                                                                    *
    *                                  CONFIGURAÇÔES DE ENVIO DE EMAILS                                  *
    *                                                                                                    *
    ******************************************************************************************************/

    public static void enviarAlertaDeErroPorEmail(String mensagem){
        
        // criar mensagem de e-mail
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        String[] toAddresses = new String[] {'jose.amaral@sottama.com'};
        email.setToAddresses(toAddresses);
        email.setSubject('Erro ocorrido no componente Consulta Serasa');
        email.setPlainTextBody(mensagem);

        // envia a mensagem de e-mail
        Messaging.SendEmailResult[] results = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});

        // verifica se o e-mail foi enviado com sucesso
        if (results[0].isSuccess()) {
            System.debug('E-mail de erro enviado com sucesso');
        } else {
            System.debug('Ocorreu um erro ao enviar o e-mail: ' + results[0].getErrors()[0].getMessage());
        }
    }





    /******************************************************************************************************
    *                                                                                                    *
    *              FUNÇÕES PARA SEREM USADAS NO PROCESSO DE SALVAR OS ULTIMOS PARAMETROS                 *
    *                                   UTILIZADOS PELO USUARIO                                          *
    *                                                                                                    *
    ******************************************************************************************************/

    private static List<String> parametrosSelecionados;
    @AuraEnabled
    public static string getParametrosUltimaConsulta(string accountId){
        Account acc = [ SELECT SerasaParametrosSelecionados__c
                        FROM Account 
                        WHERE Id=:accountId ];
        return acc.SerasaParametrosSelecionados__c;
    }
    public static void setParametrosUltimaConsulta(String accountId, List<String> parametros,Account acc){  
        String stringParametros = '';
        for(String param:parametros){
            if( stringParametros != '' ){
                stringParametros += ',';
            }
            stringParametros += param;
        }
        acc.SerasaParametrosSelecionados__c = stringParametros;
    }










    /*********************************************************************************************************************
    *                                                                                                                   *
    *                          METODOS E CLASSES UTILIZADAS NO PROCESSO DE GERAR A CONSULTA                             *
    *                                                                                                                   *
    *********************************************************************************************************************/

    private static Map<String,Parametro> mapParametro;
    public class Parametro{
        public void addParametro(Integer codigo,String valor){
            this.lstParametro.put(codigo, valor);
        }
        public void addResponse(String retorno){
            this.lstRetorno.add(retorno);
        }
        public Map<Integer,String> lstParametro = new Map<Integer,String>();
        public List<String> lstRetorno = new List<String>();
    }
    private static void listarTiposConsultas(){
        
        SerasaController2.mapParametro = new Map<String,Parametro>();
        
        Parametro param = new Parametro();
        param.addParametro(46,'E');
        param.addParametro(131,'HPJ8');
        SerasaController2.mapParametro.put('serasaScore20', param);
        
        param = new Parametro();
        param.addParametro(517,'S');
        SerasaController2.mapParametro.put('PontualidadePagamentoPJ', param);
        
        param = new Parametro();
        param.addParametro(457,'S');
        param.addParametro(458,'CGEJ');
        SerasaController2.mapParametro.put('GastoEstimadoPJPositivo', param);
        
        param = new Parametro();
        param.addParametro(457,'H');
        param.addParametro(458,'HGE1');
        SerasaController2.mapParametro.put('GastoEstimadoPJPositivo', param);
        
        param = new Parametro();
        param.addParametro(516,'S');
        SerasaController2.mapParametro.put('PagamentoFinanceiroAvancado', param);
        
        param = new Parametro();
        param.addParametro(390,'S');
        param.addParametro(444,'HFP1');
        SerasaController2.mapParametro.put('FaturamentoEstimadoPositivo', param);
        
        param = new Parametro();
        param.addParametro(46,'E');
        param.addParametro(131,'C66M');
        SerasaController2.mapParametro.put('serScoEmp', param);
        
        param = new Parametro();
        param.addParametro(436,'S');
        SerasaController2.mapParametro.put('SerasaScoreAtacadista', param);
        
        param = new Parametro();
        param.addParametro(448,'S');
        SerasaController2.mapParametro.put('QuadroSocialAdministracaoMaisCompleto', param);
        
        param = new Parametro();
        param.addParametro(43,'1');
        SerasaController2.mapParametro.put('quaSocSemPart', param);
        
        param = new Parametro();
        param.addParametro(43,'2');
        SerasaController2.mapParametro.put('Participacoes', param);
        
        param = new Parametro();
        param.addParametro(502,'S');
        SerasaController2.mapParametro.put('AlertaCadastralSociosEAdministradores', param);
        
        param = new Parametro();
        param.addParametro(503,'S');
        SerasaController2.mapParametro.put('SerasaScoreSociosPF', param);
        
        param = new Parametro();
        param.addParametro(507,'S');
        SerasaController2.mapParametro.put('IndiceRelacionamentoMercadoSetor', param);
        
        param = new Parametro();
        param.addParametro(493,'S');
        param.addParametro(494,'CIPJ');
        SerasaController2.mapParametro.put('ComportamentoPagamentoSetor', param);
        
        param = new Parametro();
        param.addParametro(435,'H');
        SerasaController2.mapParametro.put('ConsultasDetalhadasSerasa', param);
        
        param = new Parametro();
        param.addParametro(492,'S');
        SerasaController2.mapParametro.put('SituacaoFiscal', param);
        
        param = new Parametro();
        param.addParametro(501,'S');
        SerasaController2.mapParametro.put('AlertaCadastralEmpresa', param);
        
        param = new Parametro();
        param.addParametro(504,'S');
        SerasaController2.mapParametro.put('VendasCartao', param);
        
        param = new Parametro();
        param.addParametro(513,'S');
        SerasaController2.mapParametro.put('MosaicBusiness', param);
        
        param = new Parametro();
        param.addParametro(505,'S');
        SerasaController2.mapParametro.put('IndicadorRecuperacaoDividas', param);
        
        param = new Parametro();
        param.addParametro(508, 'S');
        SerasaController2.mapParametro.put('AnotacoesConsultasSPCSocios', param);
        
        param = new Parametro();
        param.addParametro(515,'S');
        SerasaController2.mapParametro.put('DividasOrgãosPublicosEmpresa', param);
        
        param = new Parametro();
        param.addParametro(490,'S');
        SerasaController2.mapParametro.put('EnderecosTelefonesAdicionais', param);
        
        param = new Parametro();
        param.addParametro(393,'S');
        SerasaController2.mapParametro.put('IndicadorRecuperacaoCredito', param);
        
        param = new Parametro();
        param.addParametro(450,'S');
        SerasaController2.mapParametro.put('perfilFinanceiro',param);
        
        param = new Parametro();
        param.addParametro(462,'S');
        param.addParametro(467,'NRI1');
        SerasaController2.mapParametro.put('AlertaIdentidadePJ',param);
       
        param = new Parametro();
        param.addParametro(448,'S');
        SerasaController2.mapParametro.put('RendaProSociosEAdministradoresPF',param);
        
        param = new Parametro();
        SerasaController2.mapParametro.put('MaisAnotacoes',param);
        
        param = new Parametro();
        param.addParametro(442, 'S');
        param.addParametro(443, 'S');
        SerasaController2.mapParametro.put('AnotacoesConsultasSPC',param);
    }
    public class Relatorio{
        Map<String,String> InformacoesSobreConsultas = new Map<String,String>();
        Map<String,String> informacoesSobreSociosAdministradores = new Map<String,String>();
        Map<String,String> dadosCadEmp = new Map<String,String>();
        Map<String,String> informacoesPadrao = new Map<String,String>();
        Map<String,String> historicoPositivoComercial = new Map<String,String>();
        Map<String,String> pagamentoFinanceiroAvancado = new Map<String,String>();
        Map<String,String> pontualidadePagamentoPJ = new Map<String,String>();
        Map<String,String> faturamentoEstimadoPositivo = new Map<String,String>();
        Map<String,String> gastoEstimadoPJPositivo = new Map<String,String>();
        Map<String,String> limiteCreditoPJ = new Map<String,String>();
        Map<String,String> serasaScoreSetorial = new Map<String,String>();
        Map<String,String> serasaScoreAtacadista = new Map<String,String>();
        Map<String,String> quadroSocialAdministracaoMaisCompleto = new Map<String,String>();
        Map<String,String> anotacoesConsultasSPCSocios = new Map<String,String>();
        Map<String,String> alertaCadastralSociosEAdministradores = new Map<String,String>();
        Map<String,String> rendaProSociosEAdministradoresPF = new Map<String,String>();
        Map<String,String> serasaScoreSociosPF = new Map<String,String>();
        Map<String,String> indiceRelacionamentoMercadoSetor = new Map<String,String>();
        Map<String,String> comportamentoPagamentoSetor = new Map<String,String>();
        Map<String,String> consultasDetalhadasSerasa = new Map<String,String>();
        Map<String,String> situacaoFiscal = new Map<String,String>();
        Map<String,String> alertaIdentidadePJ = new Map<String,String>();
        Map<String,String> alertaCadastralEmpresa = new Map<String,String>();
        Map<String,String> vendasCartao = new Map<String,String>();
        Map<String,String> mosaicBusiness = new Map<String,String>();
        Map<String,String> indicadorRecuperacaoCredito = new Map<String,String>();
        Map<String,String> enderecosTelefonesAdicionais = new Map<String,String>();
        Map<String,String> indicadorRecuperacaoDividas = new Map<String,String>();
        Map<String,String> anotacoesConsultasSPC = new Map<String,String>();
        Map<String,String> maisAnotacoes = new Map<String,String>();
        Map<String,String> dividasOrgaosPublicosEmpresa = new Map<String,String>();
        Map<String,String> perfilFinanceiro = new Map<String,String>();
        Map<String,String> informacoesAnotacoesNegativas = new Map<String,String>();
    }
    private static String modificarStr(String str, String ch, Integer position) {
        return str.substring(0, position) + ch + str.substring(position+ch.length());
    }
    public static String montarConsulta(List<String> parametros, String cnpj) {
        SerasaController2.listarTiposConsultas();
        Serasa__c integrSerasa = Serasa__c.getInstance();                                                         
        cnpj = cnpj.replace( '/' , '' )
                .replace( '-' , '' )
                .replace( '.' , '' );

        //String complementEndPoint = integrSerasa.User__c + integrSerasa.Password__c+' '.repeat(8);
        String complementEndPoint = integrSerasa.User__c + 'polima@2' +' '.repeat(8);
 
        Integer base = complementEndPoint.length();
        complementEndPoint +=' '.repeat(518);
        String relatorioBasico = 'IP20RELAS2        0'+cnpj.substring(0,8)+'22N             032';

        complementEndPoint = modificarStr(complementEndPoint, relatorioBasico, base);
        
        parametros.add('perfilFinanceiro');
        parametros.add('serasaScore20');
        
        if(!isIn(parametros,'Participacoes')){
            parametros.add('quaSocSemPart');
        }
        
        parametrosSelecionados = parametros;
        String debugParametros = '';
        for(String parametro: parametros){
            debugParametros += parametro + '\n';
            Parametro param = SerasaController2.mapParametro.get(parametro);
            for(Integer key: param.lstParametro.keySet()){
                complementEndPoint = modificarStr(complementEndPoint,param.lstParametro.get(key) , base+key-1);
            }
        }

        System.debug('Consulta: ' + complementEndPoint);
        System.debug('\n<PARAMETROS>\n'+debugParametros+'\n</PARAMETROS>');
        return complementEndPoint;
    }











    /*********************************************************************************************************************
    *                                                                                                                   *
    *                               METODOS PARA REALIZAR CONSULTAS E EXTRAIR DADOS                                     *
    *                                                                                                                   *
    *********************************************************************************************************************/

    @AuraEnabled
    public static String consultarSerasa (String accountId, List<String> parametros) {
        
        Account acc = [ SELECT beeCnpj__CNPJ__c, SerasaData__c, SerasaStatus__c, PayloadSerasa__c
                        FROM Account 
                        WHERE Id=:accountId ];
        
        setParametrosUltimaConsulta(accountId,parametros,acc);
        Relatorio result;
        String complementEndPoint,cnpj;

        /*
            Abaixo esta o processo de pegar a string de dados que contem os quadros e
        realizar o parse dos quadros para criação das tabelas.
            Se o if abaixo contiver 'true', isso significa que a string de dados vira
        do do texto contido no campo payload serasa, que é onde o texto da ultima request é 
        armazenado na hora da request. Esta opção é benefica em situações que necessitam
        de velocidade pois não é necessário esperar a resposta do serasa para poder 
        testar o resto da aplicação.
            Se o if abaixo contiver 'false', isso significa que a string de dados vira
        por meio da request realizada ao serasa. Apos a request ser encerrada, os dados
        são armazenas no campo payload serasa.
        */

        Log__c log = new Log__c();
        log.MensagemLong__c = '';
        log.Data__c = Date.today();
        log.DataHora__c	= System.now();
        String logText = '';

        Boolean isTest = false;

        if(isTest){

            //usar o payload serasa
            //cnpj = acc.beeCnpj__CNPJ__c;
            complementEndPoint = montarConsulta(parametros ,acc.beeCnpj__CNPJ__c);
            //result = extrairInformacoes(acc.PayloadSerasa__c);
            result = extrairInformacoes(fakeResponde);
            
        }
        else{

            //realizar request
            //cnpj = '01.644.731/0001-32';
            //acc.beeCnpj__CNPJ__c = cnpj;
            complementEndPoint = montarConsulta(parametros ,acc.beeCnpj__CNPJ__c);

            try {
                HttpResponse response = serasaHttpCall('https://mqlinuxext-2.serasa.com.br/Homologa/consultahttps', complementEndPoint);
                
                if (response == null || response.getStatusCode() != 200) {
                    acc.SerasaStatus__c     = response.getStatus();
                    acc.SerasaResposta__c   = response.getStatusCode() + ' - ' + response.getBody();
                } else { 
                    acc.SerasaData__c       = System.now();
                    acc.PayloadSerasa__c    = response.getBody();
                    acc.SerasaStatus__c     = response.getStatus();
                    acc.SerasaResposta__c   = response.getStatusCode() + ' - ' + response.getBody();
                    result                  = extrairInformacoes(acc.PayloadSerasa__c);
                }

            } catch (Exception e){
                
                String mensagemDeErro = e.getMessage();
                System.debug('ERRO: '+ mensagemDeErro); 
                
                //configurar log de erro
                log.NomeLog__c = 'ERRO: Consulta ao serasa. Modo request';
                log.MensagemLong__c += '\n<Mensagem de Erro>' + mensagemDeErro + '\n</Mensagem de Erro>\n';
                enviarAlertaDeErroPorEmail('<Mensagem de Erro na Request>\n' + mensagemDeErro + '\n</Mensagem de Erro na Request>');
                insert log;
                
                throw new AuraHandledException(mensagemDeErro);
            }
        }

  

        System.debug('\n<Consulta>\n'+complementEndPoint+'\n</Consulta>');
        System.debug( '\n<Result>\n' + result + '\n</Result>\n');
        
        endTabelas(result);
        update acc;

        return JSON.serialize(result);
    }
    public static Relatorio extrairInformacoes(String retornoRelatorioSerasa){
        List<String> lstItens = retornoRelatorioSerasa.split('#');
        Relatorio result = new Relatorio();

        for(String item: lstItens){
            if(item.contains('FIM9999') || item.contains('INI0138')||item.contains('BLC'))
                continue;
            if(item.length()>8)
                pegarQuadro(item.substring(0,7), item.substring(7,item.length()), result);
        }

        //colocar ultimo total da tabela de participacoes dos socios e administradores
        if(result.informacoesSobreSociosAdministradores.containsKey('$totalCapital')){
            result.informacoesSobreSociosAdministradores.put('Tabela-participacoes',result.informacoesSobreSociosAdministradores.get('Tabela-participacoes') + '<tr class="slds-line-height_reset" style = "border-left: 1px solid gray;border-right: 1px solid gray"><td class="slds-cell-wrap" ></td><td class="slds-cell-wrap" ></td><td class="slds-cell-wrap" ><b>Total</b></td><td class="slds-cell-wrap" ><b>' + result.informacoesSobreSociosAdministradores.get('$totalCapital') + '%</b></td><td class="slds-cell-wrap" ></td></tr>');
        }

        return result;
    }
    public static void pegarQuadro(String quadro,String retorno, Relatorio result){
        System.debug('Quadro:'+quadro+'-'+retorno);

        String quadrosFaltandoBruto = '';
        String quadrosFaltandoNomes = '';

        switch on quadro {
             when 'L010000'{
                formatarL010000(retorno, result);
            }when 'L010101'{
                formatarL010101(retorno, result);
            }when 'L010102'{
                formatarL010102(retorno, result);
            }when 'L010103'{
                formatarL010103(retorno, result);
            }when 'L010104'{
                formatarL010104(retorno, result);
            }when 'L010105'{
                formatarL010105(retorno, result);
            }when 'L010106'{
                formatarL010106(retorno, result);
            }when 'L010108'{
                formatarL010108(retorno, result);
            }when 'L010109'{
                formatarL010109(retorno, result);
            }when 'L010110'{
                formatarL010110(retorno,result);
            }when 'L010111'{
                formatarL010111(retorno, result);
            }when 'L010112'{
                formatarL010112(retorno,result);
            }when 'L010113'{
                formatarL010113(retorno,result);
            }when 'L010114'{
                formatarL010114(retorno,result);
            }when 'L010116'{
                formatarL010116(retorno, result);
            }when 'L010117'{
                formatarL010117(retorno,result);
            }when 'L010118'{
                formatarL010118(retorno,result);
            }when 'L010119'{
                formatarL010119(retorno,result);
            }when 'L010120'{
                formatarL010120(retorno,result);
            }when 'L011399'{
                formatarL011399(retorno,result);
            }when 'L030101'{
                //Comentado pois essa informação só é necessária se formos fazer o gráfico.
                //formatarL030101(retorno,result);
            }when 'L030102'{
                formatarL030102(retorno,result);
            }when 'L030103'{
                formatarL030103(retorno, result);
            }when 'L030303'{
                formatarL030303(retorno,result);
            }when 'L010198'{
                formatarL010198(retorno,result);
            }when 'L010999'{
                formatarL010999(retorno,result);
            }when 'L040101'{
                formatarL040101(retorno,result);
            }when 'L040102'{
                formatarL040102(retorno,result);
            }when 'L040199'{
                formatarL040199(retorno, result);
            }when 'L040299'{
                formatarL040299(retorno, result);
            }when 'L040401'{
                formatarL040401(retorno,result);
            }when 'L040601'{
                formatarL040601(retorno, result);
            }when 'L040701'{
                formatarL040701(retorno, result);
            }when 'L041099'{
                formatarL041099(retorno, result);
            }when 'L040201'{
                formatarL040201(retorno, result);
            }when 'L040901'{
                formatarL040901(retorno, result);
            }when 'L040202'{
                formatarL040202(retorno, result);
            }when 'L040301'{
                formatarL040301(retorno, result);
            }when 'L040501'{
                formatarL040501(retorno, result);
            }when 'L041000'{
                formatarL041000(retorno,result);
            }when 'L041001'{
                formatarL041001(retorno,result);
            }when 'L041101'{
                formatarL041101(retorno,result);
            }when 'L070106'{
                formatarL070106(retorno, result);
            }when 'L070109'{
                formatarL070109(retorno, result);
            }when 'L070112'{
                formatarL070112(retorno,result);
            }when 'L070113'{
                formatarL070113(retorno,result);
            }when 'L070199'{
                formatarL070199(retorno,result);
            }when 'L070401'{
                formatarL070401(retorno, result);
            }when 'L070499'{
                formatarL070499(retorno, result);
            }when 'L071199'{
                formatarL071199(retorno,result);
            }when 'L100101'{
                formatarL100101(retorno, result);
            }when 'L100102'{
                formatarL100102(retorno, result);
            }when 'L100199'{
                formatarL100199(retorno, result);
            }when 'L120101'{
                formatarL120101(retorno,result);
            }when 'L120199'{
                formatarL120199(retorno,result);
            }when 'L120201'{
                formatarL120201(retorno,result);
            }when 'L120202'{
                formatarL120202(retorno,result);
            }when 'L120299'{
                formatarL120299(retorno,result);
            }when 'L130101'{
                formatarL130101(retorno,result);
            }when 'L130199'{
                formatarL130199(retorno,result);
            }when 'L270101'{
                formatarL270101(retorno,result);
            }when 'L270102'{
                formatarL270102(retorno,result);
            }when 'L270103'{
                formatarL270103(retorno,result);
            }when 'L270104'{
                formatarL270104(retorno,result);
            }when 'L270105'{
                formatarL270105(retorno,result);
            }when 'L270106'{
                formatarL270106(retorno,result);
            }when 'L270107'{
                formatarL270107(retorno,result);
            }when 'L270199'{
                formatarL270199(retorno,result);
            }when 'L280199'{
                formatarL280199(retorno,result);
            }when 'L290101'{
                formatarL290101(retorno,result);
            }when 'L290199'{
                formatarL290199(retorno,result);
            }when 'L300201'{
                formatarL300201(retorno, result);
            }when 'L300202'{
                formatarL300202(retorno, result);
            }when 'L300203'{
                formatarL300203(retorno, result);
            }when 'L300299'{
                formatarL300299(retorno, result);
            }when 'L030399'{
                formatarL030399(retorno,result);
            }when 'L300901'{
                formatarL300901(retorno,result);
            }when 'L300902'{
                formatarL300902(retorno,result);
            }when 'L300903'{
                formatarL300903(retorno,result);
            }when 'L300904'{
                formatarL300904(retorno,result);
            }when 'L300905'{
                formatarL300905(retorno,result);
            }when 'L301301'{
                formatarL301301(retorno, result);
            }when 'L310101'{
                formatarL310101(retorno,result);
            }when 'L310102'{
                formatarL310102(retorno,result);
            }when 'L310199'{
                formatarL310199(retorno,result);
            }when 'L320101'{
                formatarL320101(retorno,result);
            }when 'L300906'{
                formatarL300906(retorno,result);
            }when 'L301399'{
                formatarL301399(retorno,result);
            }when 'L320102'{
                formatarL320102(retorno,result);
            }when 'L320103'{
                formatarL320103(retorno,result);
            }when 'L320104'{
                formatarL320104(retorno, result);
            }when 'L320199'{
                formatarL320199(retorno,result);
            }when 'L320201'{
                formatarL320201(retorno,result);
            }when 'L320202'{
                formatarL320202(retorno,result);
            }when 'L320203'{
                formatarL320203(retorno,result);
            }when 'L320204'{
                formatarL320204(retorno,result);
            }when 'L320205'{
                formatarL320205(retorno,result);
            }when 'L320206'{
                formatarL320206(retorno,result);
            }when 'L320297'{
                formatarL320297(retorno,result);
            }when 'L320298'{
                formatarL320298(retorno,result);
            }when 'L320299'{
                formatarL320299(retorno,result);
            }when 'L530101'{
                formatarL530101(retorno,result);
            }when 'L530199'{
                formatarL530199(retorno,result);
            }when 'L571001'{
                formatarL571001(retorno,result);
            }when 'L580101'{
                formatarL580101(retorno,result);
            }when 'L580199'{
                formatarL580199(retorno,result);
            }when 'L600199'{
                formatarL600199(retorno, result);
            }when 'L600101'{
                formatarL600101(retorno, result);
            }when 'L600102'{
                formatarL600102(retorno, result);
            }when 'L600201'{
                formatarL600201(retorno, result);
            }when 'L600202'{
                formatarL600202(retorno, result);
            }when 'L600299'{
                formatarL600299(retorno, result);
            }when 'L600301'{
                formatarL600301(retorno, result);
            }when 'L600302'{
                formatarL600302(retorno, result);
            }when 'L600399'{
                formatarL600399(retorno, result);
            }when 'L600401'{
                formatarL600401(retorno, result);
            }when 'L600402'{
                formatarL600402(retorno, result);
            }when 'L600499'{
                formatarL600499(retorno, result);
            }when 'L600699'{
                formatarL600699(retorno, result);
            }when 'L600701'{
                formatarL600701(retorno,result);
            }when 'L600702'{
                formatarL600702(retorno,result);
            }when 'L600799'{
                formatarL600799(retorno,result);
            }when 'L610099'{
                formatarL610099(retorno, result);
            }when 'L610101'{
                formatarL610101(retorno,result);
            }when 'L610102'{
                formatarL610102(retorno,result);
            }when 'L610199'{
                formatarL610199(retorno,result);
            }when 'L610201'{
                formatarL610201(retorno,result);
            }when 'L610202'{
                formatarL610202(retorno,result);
            }when 'L610299'{
                formatarL610299(retorno,result);
            }when 'L610301'{
                formatarL610301(retorno,result);
            }when 'L610302'{
                formatarL610302(retorno,result);
            }when 'L610399'{
                formatarL610399(retorno,result);
            }when 'L610499'{
                formatarL610499(retorno,result);
            }when 'L610599'{
                formatarL610599(retorno,result);
            }when 'L610699'{
                formatarL610699(retorno,result);
            }when 'L700099'{
                formatarL700099(retorno,result);
            }when 'L901099'{
                formatarL901099(retorno,result);
            }when 'L907099'{
                formatarL907099(retorno,result);
            }when 'L901001'{
                formatarL901001(retorno,result);
            }when 'L901002'{
                formatarL901002(retorno,result);
            }when 'L901003'{
                formatarL901003(retorno,result);
            }when 'L925001'{
                formatarL925001(retorno,result);
            }when 'L925002'{
                formatarL925002(retorno,result);
            }when 'L925099'{
                formatarL925099(retorno,result);
            }when 'L926001'{
                formatarL926001(retorno,result);
            }when 'L926099'{
                formatarL926099(retorno,result);
            }when 'L907001'{
                formatarL907001(retorno,result);
            }when 'L907002'{
                formatarL907002(retorno,result);
            }
            when else {
                System.debug('\nQUADRO ' +quadro+ ' NÃO ENCONTRADO\nresult:' + retorno);
                quadrosFaltandoBruto += retorno + '\n';
                if(!quadrosFaltandoNomes.contains(quadro)){
                    quadrosFaltandoNomes += quadro + '\n';
                }
            }
        }

        if( quadrosFaltandoBruto != '' ){
            String mensagem = '' +
            'Foram identificados alguns quadros faltando no componente Consulta Serasa\n\n' +
            '--------- Quadros ----------\n' +
            quadrosFaltandoNomes + '\n\n' +
            '------Dados da Request------\n' +
            quadrosFaltandoBruto +
            '\n';

            enviarAlertaDeErroPorEmail(mensagem);

            Log__c log = new Log__c();
            log.MensagemLong__c = '';
            log.Data__c = Date.today();
            log.DataHora__c	= System.now();
            log.NomeLog__c = 'ERRO: Faltando quadros';
            log.MensagemLong__c += '\n<Quadros>\n' + mensagem + '\n</Quadros>';
            insert log;
        }
    }
    private static HTTPResponse serasaHttpCall(String endApi, String payload){

        Http http = new Http();
        HttpRequest request = new HttpRequest();
        HTTPResponse response = new HTTPResponse();

        String url = endApi;
        request.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        request.setEndpoint(url);
        request.setMethod('POST');
        request.setTimeout(120000);
        request.setBody('p=' + payload);
        
        try{
            response = http.send(request); 
        }
        catch(Exception e) {
            String errorMsg = e.getMessage();
            throw new AuraHandledException(errorMsg);
        }
        return response;
    }












    /********************************************************************************************************************
    *                                                                                                                  *
    *               METODOS DESENVOLVIDOS PARA FACILITAR A MANIPULAÇÃO DOS DADOS E MONTAGEM DAS CONSULTAS              *
    *                                                                                                                  *
    ********************************************************************************************************************/

     public static String formatarDataAAAAMMDD(String AAAAMMDD){

        AAAAMMDD =  AAAAMMDD.substring(6,8) + '/' +
                    AAAAMMDD.substring(4,6) + '/' +
                    AAAAMMDD.substring(0,4);

        return AAAAMMDD;
    }
    public static String formatarDataDDMMAAAA(String DDMMAAAA){

        DDMMAAAA =  DDMMAAAA.substring(0,2) + '/' +
                    DDMMAAAA.substring(2,4) + '/' +
                    DDMMAAAA.substring(4,8);

        return DDMMAAAA;
    }
    public static String formatarCpfOuCnpj(String numeroDocMaisDigito, String tipoPessoa, String filial){

        filial = String.isBlank(filial) ? '/0001-' : '/' + filial + '-' ;

        if(tipoPessoa == 'J') {

            numeroDocMaisDigito = numeroDocMaisDigito.substring(1 , 3)  + '.'
                                + numeroDocMaisDigito.substring(3 , 6)  + '.'
                                + numeroDocMaisDigito.substring(6 , 9)  +  filial +
                                + numeroDocMaisDigito.substring(9 , 11);

        } else {

            numeroDocMaisDigito = numeroDocMaisDigito.substring(0 , 3)  + '.'
                                + numeroDocMaisDigito.substring(3 , 6)  + '.'
                                + numeroDocMaisDigito.substring(6 , 9)  + '-' 
                                + numeroDocMaisDigito.substring(9 , 11);

        }

        return numeroDocMaisDigito;
    }
    public static String removerZeros(String stringParaFormatar){

        while (stringParaFormatar.startsWith('0')) {
            stringParaFormatar = stringParaFormatar.removeStart('0');
        } 
        stringParaFormatar = String.isBlank(stringParaFormatar) ? '0' : stringParaFormatar;

        return stringParaFormatar;
    }
    public static Boolean isIN(List<String> lista,String item){
        for(String itemLista:lista){
            if(itemLista == item){
                return true;
            }
        }
        return false;
    }
    public static String formatarCNPJcompleto(String cnpj){
        String novoCNPJ = cnpj.substring(0,3) + '.' + cnpj.substring(3,6) + '.' + cnpj.substring(6,9) + '/' + cnpj.substring(9,13) + '-' + cnpj.substring(13,15);
        return novoCNPJ;
    }
    public static String formatarTelefone(String numero,String DDD){
        
        String numeroFormatado;
        numero = removerZeros(numero);
        numeroFormatado = numero.substring(0,4+(math.mod(numero.length(),8))) + ' - ' + numero.substring(4+(math.mod(numero.length(),8)),8+math.mod(numero.length(),8));
        DDD = removerZeros(DDD);

        return '(' + DDD + ') ' + numeroFormatado;
    }
    public static String formatarValor(String valor,Integer casasDecimais){

        String numeroAntesDaVirgula = '';
        if(casasDecimais>0){
            numeroAntesDaVirgula = valor.substring(valor.length()-(casasDecimais),valor.length());
            valor = valor.substring(0,valor.length()-casasDecimais);
            
            for( Integer i = 0 ; i < 3 ; i++ ){
                if( numeroAntesDaVirgula.substring(numeroAntesDaVirgula.length()-1,numeroAntesDaVirgula.length()) == '0' ){
                    numeroAntesDaVirgula = numeroAntesDaVirgula.substring(0,numeroAntesDaVirgula.length()-1);
                }
            }
            
        }

        String valorReduzido = '';
        if( valor.substring(0,1).trim() == '-' ){
            valorReduzido += '-';
        }
        
        Boolean vai = false;
        String caractere;
        for(Integer i=0; i<valor.length(); i++){
            caractere = valor.substring(i,i+1);
            if( caractere != '+' && caractere != '-' && caractere != '0'){
                vai = true;
            }
            if(vai){
                valorReduzido += caractere;
            }
        }  

        String valorComPontos = '';
        Integer casas = 0;
        for( Integer i = valorReduzido.length() ; i > 0 ; i-- ){
            caractere = valorReduzido.substring(i-1,i);
            if(casas == 3 && caractere != '-'){
                casas = 0;
                valorComPontos = '.' + valorComPontos;
            }
            valorComPontos = caractere + valorComPontos;
            casas += 1;
        } 

        if(valorComPontos==''){
            valorComPontos = '0';
        }

        if(casasDecimais > 0 && numeroAntesDaVirgula != ''){
            return valorComPontos + ',' + numeroAntesDaVirgula;  
        }else{
            return valorComPontos;  
        }  
    }
    public static Map<String,String> interpretarScore(String score){
        Map<String,String> resultado = new Map<String,String>();
        
        Integer scoreInt = Integer.valueOf(score);

        //classificacao
             if( scoreInt >= 951 && scoreInt <= 1000){resultado.put('classificacao','Risco de Crédito : Mínimo');}
        else if( scoreInt >= 901 && scoreInt <= 950 ){resultado.put('classificacao','Risco de Crédito : Mínimo');} 
        else if( scoreInt >= 851 && scoreInt <= 900 ){resultado.put('classificacao','Risco de Crédito : Mínimo');} 
        else if( scoreInt >= 801 && scoreInt <= 850 ){resultado.put('classificacao','Risco de Crédito : Muito baixo');} 
        else if( scoreInt >= 751 && scoreInt <= 800 ){resultado.put('classificacao','Risco de Crédito : Muito baixo');} 
        else if( scoreInt >= 701 && scoreInt <= 750 ){resultado.put('classificacao','Risco de Crédito : Muito baixo');} 
        else if( scoreInt >= 651 && scoreInt <= 700 ){resultado.put('classificacao','Risco de Crédito : Baixo');} 
        else if( scoreInt >= 601 && scoreInt <= 650 ){resultado.put('classificacao','Risco de Crédito : Baixo');} 
        else if( scoreInt >= 551 && scoreInt <= 600 ){resultado.put('classificacao','Risco de Crédito : Baixo');} 
        else if( scoreInt >= 501 && scoreInt <= 550 ){resultado.put('classificacao','Risco de Crédito : Baixo');} 
        else if( scoreInt >= 451 && scoreInt <= 500 ){resultado.put('classificacao','Risco de Crédito : Baixo');} 
        else if( scoreInt >= 401 && scoreInt <= 450 ){resultado.put('classificacao','Risco de Crédito : Baixo');} 
        else if( scoreInt >= 351 && scoreInt <= 400 ){resultado.put('classificacao','Risco de Crédito : Médio');}
        else if( scoreInt >= 301 && scoreInt <= 350 ){resultado.put('classificacao','Risco de Crédito : Médio');}
        else if( scoreInt >= 251 && scoreInt <= 300 ){resultado.put('classificacao','Risco de Crédito : Médio');}
        else if( scoreInt >= 201 && scoreInt <= 250 ){resultado.put('classificacao','Risco de Crédito : Médio');}
        else if( scoreInt >= 151 && scoreInt <= 200 ){resultado.put('classificacao','Risco de Crédito : Considerável');} 
        else if( scoreInt >= 101 && scoreInt <= 150 ){resultado.put('classificacao','Risco de Crédito : Relevante');}
        else if( scoreInt >= 51	 && scoreInt <= 100 ){resultado.put('classificacao','Risco de Crédito : Iminente');}
        else if( scoreInt >= 5   && scoreInt <= 50  ){resultado.put('classificacao','Risco de Crédito : Iminente');}
        else{resultado.put('classificacao','');}

        //interpretacao
             if( scoreInt >= 951 && scoreInt <= 1000){resultado.put('interpretacao','A pontuação enquadra-se na faixa de 951 a 1000 e representa risco mínimo de crédito. Para empresas com este perfil de risco, é prática de mercado conceder crédito sem necessidades de garantias adicionais. Em média, empresas com esta categoria de risco costumam honrar os compromissos assumidos em 99,76%');}
        else if( scoreInt >= 901 && scoreInt <= 950 ){resultado.put('interpretacao','A pontuação enquadra-se na faixa de 901 a 950 e representa risco mínimo de crédito. Para empresas com este perfil de risco, é prática de mercado conceder crédito sem necessidades de garantias adicionais. Em média, empresas com esta categoria de risco costumam honrar os compromissos assumidos em 99,67%');} 
        else if( scoreInt >= 851 && scoreInt <= 900 ){resultado.put('interpretacao','A pontuação enquadra-se na faixa de 851 a 900 e representa risco mínimo de crédito. Para empresas com este perfil de risco, é prática de mercado conceder crédito sem necessidades de garantias adicionais. Em média, empresas com esta categoria de risco costumam honrar os compromissos assumidos em 99,6%');} 
        else if( scoreInt >= 801 && scoreInt <= 850 ){resultado.put('interpretacao','A pontuação enquadra-se na faixa de 801 a 850 e representa risco muito baixo de crédito. Para empresas com este perfil de risco, é prática de mercado conceder crédito sem necessidades de garantias adicionais. Em média, empresas com esta categoria de risco costumam honrar os compromissos assumidos em 99,52%.');} 
        else if( scoreInt >= 751 && scoreInt <= 800 ){resultado.put('interpretacao','A pontuação enquadra-se na faixa de 751 a 800 e representa risco muito baixo de crédito. Para empresas com este perfil de risco, é prática de mercado conceder crédito sem necessidades de garantias adicionais. Em média, empresas com esta categoria de risco costumam honrar os compromissos assumidos em 99,44%.');} 
        else if( scoreInt >= 701 && scoreInt <= 750 ){resultado.put('interpretacao','A pontuação enquadra-se na faixa de 701 a 750 e representa risco muito baixo de crédito. Para empresas com este perfil de risco, é prática de mercado conceder crédito sem necessidades de garantias adicionais.  Em média, empresas com esta categoria de risco costumam honrar os compromissos assumidos em 99,35%');} 
        else if( scoreInt >= 651 && scoreInt <= 700 ){resultado.put('interpretacao','A pontuação enquadra-se na faixa de 651 a 700 e representa risco baixo de crédito. Para empresas com este perfil de risco, é prática de mercado conceder crédito sem necessidades de garantias adicionais. Em média, empresas com esta categoria de risco costumam honrar os compromissos assumidos em 99,25%.');} 
        else if( scoreInt >= 601 && scoreInt <= 650 ){resultado.put('interpretacao','A pontuação enquadra-se na faixa de 601 a 650 e representa risco baixo de crédito. Para empresas com este perfil de risco, é prática de mercado conceder crédito sem necessidades de garantias adicionais. Em média, empresas com esta categoria de risco costumam honrar os compromissos assumidos em 99,13%');} 
        else if( scoreInt >= 551 && scoreInt <= 600 ){resultado.put('interpretacao','A pontuação enquadra-se na faixa de 551 a 600 e representa risco baixo de crédito. Para empresas com este perfil de risco, é prática de mercado conceder crédito sem necessidades de garantias adicionais. Em média, empresas com esta categoria de risco costumam honrar os compromissos assumidos em 98,99%');} 
        else if( scoreInt >= 501 && scoreInt <= 550 ){resultado.put('interpretacao','A pontuação enquadra-se na faixa de 501 a 550 e representa risco baixo de crédito. Para empresas com este perfil de risco, é prática de mercado conceder crédito sem necessidades de garantias adicionais. Em média, empresas com esta categoria de risco costumam honrar os compromissos assumidos em 98,83%.');} 
        else if( scoreInt >= 451 && scoreInt <= 500 ){resultado.put('interpretacao','A pontuação enquadra-se na faixa de 451 a 500 e representa risco baixo de crédito. Para empresas com este perfil de risco, é prática de mercado conceder crédito para compras de mercadorias ou serviços sem necessidades de garantias adicionais. Em média, empresas com esta categoria de risco costumam honrar os compromissos assumidos em 98,63%');} 
        else if( scoreInt >= 401 && scoreInt <= 450 ){resultado.put('interpretacao','A pontuação enquadra-se na faixa de 401 a 450 e representa risco baixo de crédito. Para empresas com este perfil de risco, é prática de mercado conceder crédito para compras de mercadorias ou serviços sem necessidades de garantias adicionais. Em média, empresas com esta categoria de risco costumam honrar os compromissos assumidos em 98,38%');} 
        else if( scoreInt >= 351 && scoreInt <= 400 ){resultado.put('interpretacao','A pontuação enquadra-se na faixa de 351 a 400 e representa médio risco de crédito. Para empresas com este perfil de risco, é prática de mercado conceder crédito para compras de mercadorias ou serviços observando o uso de garantias adicionais, o grau de relacionamento com a empresa e os valores negociados.  Em média, empresas com esta categoria de risco costumam honrar os compromissos assumidos em 97,88%');}
        else if( scoreInt >= 301 && scoreInt <= 350 ){resultado.put('interpretacao','A pontuação enquadra-se na faixa de 301 a 350 e representa médio risco de crédito. Para empresas com este perfil de risco, é prática de mercado conceder crédito para compras de mercadorias ou serviços com garantias adicionais, obedecendo os limites de crédito e monitorando o perfil de risco pelo menos a cada 3 meses, ou a cada nova operação. Em média, empresas com esta categoria de risco costumam honrar os compromissos assumidos em 97,65%');}
        else if( scoreInt >= 251 && scoreInt <= 300 ){resultado.put('interpretacao','A pontuação enquadra-se na faixa de 251 a 300 e representa médio risco de crédito. Para empresas com este perfil de risco, é prática de mercado conceder crédito com maior rigor na decisão, valendo-se de garantias adicionais e monitoramento do perfil de risco de forma contínua. Em média, empresas com esta categoria de risco costumam honrar os compromissos de pagamentos assumidos em 97,09% das operações.');}
        else if( scoreInt >= 201 && scoreInt <= 250 ){resultado.put('interpretacao','A pontuação enquadra-se na faixa de 201 a 250 e representa médio risco de crédito. Para empresas com este perfil de risco, é prática de mercado conceder crédito  com maior rigor na decisão, valendo-se de garantias adicionais e constantes monitoramentos do perfil de risco. Empresas com esta categoria de risco costumam honrar os compromissos de pagamentos assumidos em 96,27% das operações');}
        else if( scoreInt >= 151 && scoreInt <= 200 ){resultado.put('interpretacao','A pontuação enquadra-se na faixa de 151 a 200 e representa reais possibilidades de inadimplência, principalmente em condições adversas na economia. Para empresas com este perfil de risco, é prática de mercado conceder crédito com maior rigor na decisão, no entanto há chances de fazer bons negócios, solicitando garantias, prazos menores e respeitando o cálculo do limite de crédito. Em média, empresas com esta categoria de risco costumam honrar os compromissos de pagamentos assumidos em 95,01% das operações. ');} 
        else if( scoreInt >= 101 && scoreInt <= 150 ){resultado.put('interpretacao','A pontuação enquadra-se na faixa de 101 a 150 e representa substancial chance da empresa entrar em inadimplência, principalmente em condições adversas na economia e nas operações da empresa. Em média, empresas com esta categoria de risco costumam honrar os compromissos de pagamentos assumidos em 93,78% das operações. ');}
        else if( scoreInt >= 51	 && scoreInt <= 100 ){resultado.put('interpretacao','A pontuação enquadra-se na faixa de 51 a 100 e representa iminente risco de inadimplência, principalmente em condições adversas na economia e das condições financeiras desfavoráveis na empresa. Em média, empresas com esta categoria de risco costumam honrar os compromissos de pagamentos assumidos em 89,42% das operações. ');}
        else if( scoreInt >= 5   && scoreInt  <= 50 ){resultado.put('interpretacao','A pontuação enquadra-se na faixa de 5 a 50 e representa iminente risco de inadimplência, principalmente em condições adversas na economia e das condições financeiras desfavoráveis na empresa. Para empresas com este perfil de risco, é prática de mercado não conceder crédito à prazo ou não fazer qualquer transação comercial a prazo. ');}
        else{resultado.put('interpretacao','A pontuação representa que a empresa encontra-se em situação de inadimplência no mercado - Dívidas vencidas com instituições financeiras. Para este tipo de empresa, é prática de mercado vender somente à vista.');}

        //pratica do mercadp
             if( scoreInt >= 951 && scoreInt <= 1000){resultado.put('praticaMercado','Venda a prazo');}
        else if( scoreInt >= 901 && scoreInt <= 950 ){resultado.put('praticaMercado','Venda a prazo');}
        else if( scoreInt >= 851 && scoreInt <= 900 ){resultado.put('praticaMercado','Venda a prazo');}
        else if( scoreInt >= 801 && scoreInt <= 850 ){resultado.put('praticaMercado','Venda a prazo');}
        else if( scoreInt >= 751 && scoreInt <= 800 ){resultado.put('praticaMercado','Venda a prazo');}
        else if( scoreInt >= 701 && scoreInt <= 750 ){resultado.put('praticaMercado','Venda a prazo');}
        else if( scoreInt >= 651 && scoreInt <= 700 ){resultado.put('praticaMercado','Venda a prazo');}
        else if( scoreInt >= 601 && scoreInt <= 650 ){resultado.put('praticaMercado','Venda a prazo');}
        else if( scoreInt >= 551 && scoreInt <= 600 ){resultado.put('praticaMercado','Venda a prazo');}
        else if( scoreInt >= 501 && scoreInt <= 550 ){resultado.put('praticaMercado','Venda a prazo');}
        else if( scoreInt >= 451 && scoreInt <= 500 ){resultado.put('praticaMercado','Venda a prazo');}
        else if( scoreInt >= 401 && scoreInt <= 450 ){resultado.put('praticaMercado','Venda a prazo');}
        else if( scoreInt >= 351 && scoreInt <= 400 ){resultado.put('praticaMercado','Venda com garantias adicionais');}
        else if( scoreInt >= 301 && scoreInt <= 350 ){resultado.put('praticaMercado','Venda com garantias adicionais');}
        else if( scoreInt >= 251 && scoreInt <= 300 ){resultado.put('praticaMercado','Venda com garantias adicionais');}
        else if( scoreInt >= 201 && scoreInt <= 250 ){resultado.put('praticaMercado','Venda com garantias adicionais');}
        else if( scoreInt >= 151 && scoreInt <= 200 ){resultado.put('praticaMercado','Venda com garantias adicionais');}
        else if( scoreInt >= 101 && scoreInt <= 150 ){resultado.put('praticaMercado','Venda à vista');}
        else if( scoreInt >= 51	 && scoreInt <= 100 ){resultado.put('praticaMercado','Venda à vista');}
        else if( scoreInt >= 5   && scoreInt <= 50  ){resultado.put('praticaMercado','Venda à vista');}
        else{resultado.put('praticaMercado','');}

        //media prinad
             if( scoreInt >= 951 && scoreInt <= 1000){resultado.put('mediaPrinad','0,24%');}
        else if( scoreInt >= 901 && scoreInt <= 950 ){resultado.put('mediaPrinad','0,33%');}
        else if( scoreInt >= 851 && scoreInt <= 900 ){resultado.put('mediaPrinad','0,40%');}
        else if( scoreInt >= 801 && scoreInt <= 850 ){resultado.put('mediaPrinad','0,48%');}
        else if( scoreInt >= 751 && scoreInt <= 800 ){resultado.put('mediaPrinad','0,56%');}
        else if( scoreInt >= 701 && scoreInt <= 750 ){resultado.put('mediaPrinad','0,65%');}
        else if( scoreInt >= 651 && scoreInt <= 700 ){resultado.put('mediaPrinad','0,75%');}
        else if( scoreInt >= 601 && scoreInt <= 650 ){resultado.put('mediaPrinad','0,87%');}
        else if( scoreInt >= 551 && scoreInt <= 600 ){resultado.put('mediaPrinad','1,01%');}
        else if( scoreInt >= 501 && scoreInt <= 550 ){resultado.put('mediaPrinad','1,17%');}
        else if( scoreInt >= 451 && scoreInt <= 500 ){resultado.put('mediaPrinad','1,37%');}
        else if( scoreInt >= 401 && scoreInt <= 450 ){resultado.put('mediaPrinad','1,62%');}
        else if( scoreInt >= 351 && scoreInt <= 400 ){resultado.put('mediaPrinad','2,12%');}
        else if( scoreInt >= 301 && scoreInt <= 350 ){resultado.put('mediaPrinad','2,35%');}
        else if( scoreInt >= 251 && scoreInt <= 300 ){resultado.put('mediaPrinad','2,91%');}
        else if( scoreInt >= 201 && scoreInt <= 250 ){resultado.put('mediaPrinad','3,73%');}
        else if( scoreInt >= 151 && scoreInt <= 200 ){resultado.put('mediaPrinad','4,99%');}
        else if( scoreInt >= 101 && scoreInt <= 150 ){resultado.put('mediaPrinad','6,22%');}
        else if( scoreInt >= 51	 && scoreInt <= 100 ){resultado.put('mediaPrinad','10,58%');}
        else if( scoreInt >= 5   && scoreInt <= 50  ){resultado.put('mediaPrinad','30,89%');}
        else{resultado.put('mediaPrinad','');}

        return resultado;
    }
    public static Map<String,String> interpretarMosaic(String codigo_mosaic){
        Map<String,String> resultado = new Map<String,String>();

        switch on codigo_mosaic{
            when 'A01'{resultado.put('titulo','Grandes, Tradicionais e Influentes');}
            when 'A02'{resultado.put('titulo','Setor Financeiro');}
            when 'A03'{resultado.put('titulo','Grandes e Regionais');}
            when 'A04'{resultado.put('titulo','Médias Excepcionais');}
            when 'B05'{resultado.put('titulo','Médias Perenes e Estabilizadas');}
            when 'B06'{resultado.put('titulo','Pequenas Experientes de Serviços');}
            when 'B07'{resultado.put('titulo','Pequenas, Tradicionais e Estabilizadas');}
            when 'B08'{resultado.put('titulo','Microempresas Veteranas e Estáveis');}
            when 'B09'{resultado.put('titulo','Maduras e por Conta Própria');}
            when 'C10'{resultado.put('titulo','Comerciantes Experientes e de Sucesso');}
            when 'C11'{resultado.put('titulo','Médias em Boa Situação');}
            when 'C12'{resultado.put('titulo','Comércios em Ascensão');}
            when 'C13'{resultado.put('titulo','Sócios Experientes');}
            when 'C14'{resultado.put('titulo','Serviços em Boa Situação');}
            when 'C15'{resultado.put('titulo','Alta Operacionalidade');}
            when 'C16'{resultado.put('titulo','Jovens Qualificados do Setor de Serviços');}
            when 'C17'{resultado.put('titulo','Empresários Urbanos Bem-Suscedidos');}
            when 'C18'{resultado.put('titulo','Pequenos Comerciantes do Interior');}
            when 'D19'{resultado.put('titulo','Médias Novas no Pedaço');}
            when 'D20'{resultado.put('titulo','Novos Comércios');}
            when 'D21'{resultado.put('titulo','Novas Empresas de Serviços');}
            when 'D22'{resultado.put('titulo','Microempresas Novatas');}
            when 'D23'{resultado.put('titulo','Começo Equilibrado');}
            when 'D24'{resultado.put('titulo','Começando com Cautela');}
            when 'D25'{resultado.put('titulo','Jovens Empreendedores em Ascensão');}
            when 'D26'{resultado.put('titulo','Na Turbulência do Início');}
            when 'E27'{resultado.put('titulo','No Fôlego do Dono');}
            when 'E28'{resultado.put('titulo','Jovens Empreendedores na Batalha');}
            when 'E29'{resultado.put('titulo','Buscando Estabilidade');}
            when 'E30'{resultado.put('titulo','Pequenos Negócios no Aperto');}
            when 'E31'{resultado.put('titulo','Pequena Sociedade na Luta');}
            when 'E32'{resultado.put('titulo','Comerciantes Ativos em Momento Difícil');}
            when 'E33'{resultado.put('titulo','Comércio no Aperto');}
            when 'E34'{resultado.put('titulo','Serviços em Risco');}
            when 'E35'{resultado.put('titulo','Médias em Alto Risco');}
            when 'E36'{resultado.put('titulo','Microempresas em Alto Risco');}
            when 'F37'{resultado.put('titulo','Comer e Beber');}
            when 'F38'{resultado.put('titulo','Lar e Construção');}
            when 'F39'{resultado.put('titulo','Alta Especialização');}
            when 'F40'{resultado.put('titulo','Serviços de Saúde');}
            when 'F41'{resultado.put('titulo','Produtores Rurais');}
            when 'F42'{resultado.put('titulo','Cooperativas');}
            when 'F43'{resultado.put('titulo','Serviços Financeiros');}
            when 'F44'{resultado.put('titulo','Financeiras no Exterior');}
            when 'F45'{resultado.put('titulo','Clubes de Investimento');}
            when 'F46'{resultado.put('titulo','Pequenas Indústrias');}
            when 'F47'{resultado.put('titulo','Prestação de Serviços');}
            when 'F48'{resultado.put('titulo','Serviços Administrativos');}
            when 'F49'{resultado.put('titulo','Educação');}
            when 'G50'{resultado.put('titulo','Administração Pública');}
            when 'G51'{resultado.put('titulo','Organizações Religiosas e Políticas');}
            when 'G52'{resultado.put('titulo','Edifícios e Condomínios');}
            when 'G53'{resultado.put('titulo','Cartórios');}
            when 'G54'{resultado.put('titulo','ONGs, OSCIPs, Entidades Sem Fins Lucrativos');}
            when else{resultado.put('titulo','indefinido');}
        }

        switch on codigo_mosaic{
            when 'A01'{resultado.put('interpretacao','No topo do Mosaic Business estão as empresas com abrangência nacional mais bem-sucedidas. Nada mais justo, afinal, elas possuem um faturamento anual acima de 90 milhões. São caracterizadas pelo grande porte.');}
            when 'A02'{resultado.put('interpretacao','Aqui ficam as grandes e médias empresas do setor financeiro, como bancos, seguradoras, consórcios e financeiras. ');}
            when 'A03'{resultado.put('interpretacao','Esse segmento é composto por empresas de grande porte, mas que não possuem abrangência nacional. Mesmo sendo empresas que atuam de forma regional, o faturamento por aqui é de 30 a 90 milhões por ano.');}
            when 'A04'{resultado.put('interpretacao','Essas são as médias empresas que se comportam como grandes, pois possuem faturamento anual entre 16 a 30 milhões, que se destaca em relação as outras empresas do mesmo porte.');}
            when 'B05'{resultado.put('interpretacao','Não é à toa que mais da metade das empresas desse segmento possui mais de 30 anos: essa é a seleção das médias empresas estáveis. Com faturamento anual entre 3,6 e 30 milhões. ');}
            when 'B06'{resultado.put('interpretacao','"São pequenas empresas do setor de serviços que possuem faturamento anual entre 360 mil e 3,6 milhões, além de bastante experiência, já que estão no mercado há no mínimo 20 anos. <br>Os sócios possuem mais de 50 anos de idade e isso, em geral, pode contribuir para a experiência dessas empresas."');}
            when 'B07'{resultado.put('interpretacao','"São pequenas empresas que possuem sócios maduros, com mais de 50 anos de idade. <br>O faturamento anual por aqui fica entre 360 mil e 3,6 milhões e todas elas possuem mais de 20 anos de operação."');}
            when 'B08'{resultado.put('interpretacao','"Esse é o segmento das microempresas experientes e estáveis, com baixo risco de crédito. <br>Todos os negócios dessa seleção possuem mais de 20 anos e faturamento entre 60 e 360 mil ao ano. <br>Vale destacar que a grande maioria dessas empresas fica no sul e sudeste."');}
            when 'B09'{resultado.put('interpretacao','"Os microempreendedores individuais desse segmento são, em geral, comerciantes de cidades do interior e suas rendas costumam ser constantes, o que pode lhes permitir uma vida mais confortável. <br>O faturamento máximo por aqui é de 60 mil ao ano."');}
            when 'C10'{resultado.put('interpretacao','"Microempreendedores individuais do setor do comércio com indicadores financeiros positivos tanto dos sócios como das empresas, o que indica um ótimo caminho. <br>As microempresas desse segmento possuem mais de 20 anos, baixo risco de crédito e faturamento anual máximo de 60 mil."');}
            when 'C11'{resultado.put('interpretacao','Essas empresas de porte médio, com faturamento anual 3,6 a 16 milhões e alta operacionalidade, isto é, alta atividade no mercado, mostram-se sólidas e estáveis.');}
            when 'C12'{resultado.put('interpretacao','"Mesmo com pouco tempo de existência, entre 2 e 5 anos, são pequenos comércios, com faturamento anual entre 360 mil e 3,6 milhões, que estão indo muito bem. <br>Os indicadores financeiros mostram crescimento, como por exemplo, o baixo ou médio risco de crédito, bem como a atividade e operacionalidade no mercado. <br>Vale destacar que a maioria dos sócios majoritários possui ensino superior completo e pertence à classe social média ou alta, levando em consideração as variáveis da Serasa Experian e censo do IBGE, como por exemplo as informações demográficas e financeiras. "');}
            when 'C13'{resultado.put('interpretacao','"No comando dessas pequenas empresas do setor de comércio, que faturam de 360 mil a 3,6 milhões por ano, estão sócios muito experientes. <br>Em sua maioria, os sócios majoritários possuem mais de 40 anos e são empresários estabilizados, afinal, como são empresas abertas a pelo menos 10 anos de existência, já passaram pelo período inicial, no qual é comum o fechamento de empresas. "');}
            when 'C14'{resultado.put('interpretacao','"Essas pequenas empresas do setor de serviços possuem faturamento anual entre 360 mil e 3,6 milhões, apresentando baixo ou médio risco de crédito. <br>Seus sócios majoritários, no geral, pertencem a um grupo de empresários bem-sucedidos e desfrutam de conforto em relação à renda."');}
            when 'C15'{resultado.put('interpretacao','"A maior característica dessas pequenas empresas, que faturam de 360 mil a 3,6 milhões anuais, é altíssima ou alta operacionalidade. Isso pode ser constatado através de indicadores baseados na quantidade de consultas e transações realizadas a bancos de dados de proteção ao crédito bem como no recebimento de consultas nestes. <br>A maior concentração desses negócios é no setor de indústria e comércio, com um foco maior em construção e reforma, além de alimentação e hospedagem."');}
            when 'C16'{resultado.put('interpretacao','"Juventude é a palavra desse segmento. Começando pelos sócios dessas pequenas empresas do setor de serviços, que possuem de 18 a 34 anos, ensino superior completo e alta renda. <br>Suas pequenas empresas possuem de 2 a 10 anos, sendo que a maioria delas possui menos do que 5 anos. <br>O faturamento anual desse segmento é de 360 mil a 3,6 milhões e os indicadores financeiros indicam estabilidade. "');}
            when 'C17'{resultado.put('interpretacao','"São pequenas empresas do setor de serviços com faturamento anual entre 360 mil e 3,6 milhões. Possuem idade entre 10 e 20 anos e estabilidade financeira. <br>Seus sócios têm mais de 35 anos, sendo que a maioria tem idade superior a 50 anos. No geral, são empresários bem-sucedidos, com ótima escolaridade e desfrutam os confortos permitidos pela alta renda."');}
            when 'C18'{resultado.put('interpretacao','"Esses microempreendedores individuais possuem comércios com 2 a 20 anos de existência, com predominância em seus 10 primeiros anos. <br>Apesar de baixa atividade no mercado, essas empresas apresentam indicadores de créditos confortáveis, com médio ou baixo risco. <br>Os donos desses comércios têm acima de 40 anos e podem ter visto a oportunidade de abrir um pequeno negócio como uma alternativa para aumentar a renda. <br>Os setores que se destacam nesse segmento são alimentação, turismo, transporte e vestuário. "');}
            when 'D19'{resultado.put('interpretacao','"São empresas de médio porte, com menos de 5 anos de existência e faturamento anual entre 3,6 e 16 milhões. Em sua maioria são do setor de comércio. <br>Possuem médio risco de crédito, além de alta probabilidade de estar operando e em bom funcionamento, baseando-se nos indicadores de consultas e transações."');}
            when 'D20'{resultado.put('interpretacao','"Essas são as pequenas empresas do setor de comércio com menos de 2 anos de existência. <br>Com faturamento anual entre 360 mil e 3,6 milhões, possuem bons indicadores financeiros, como por exemplo o baixo risco de crédito."');}
            when 'D21'{resultado.put('interpretacao','"Nesse segmento temos as pequenas empresas do setor de serviço com menos de 2 anos de operações. <br>O faturamento anual por aqui fica entre 360 mil e 3,6 milhões, e, devido ao pouco tempo de existência, ainda não é possível prever uma tendência dos seus indicadores financeiros. <br>Mas, vale destacar que os sócios possuem, em sua maioria, um bom comportamento de crédito."');}
            when 'D22'{resultado.put('interpretacao','"São microempresas com faturamento anual menor que 360 mil. <br>Em geral, pertencem ao setor de industrias e serviços. <br>Os sócios são predominantemente mais jovens, com idade entre 18 e 35 anos. "');}
            when 'D23'{resultado.put('interpretacao','"São microempreendedores individuais começando com transações e atividades no mercado moderadas e indicadores financeiros equilibrados. <br>A maioria dos donos pertence às classes sociais C e D, levando em consideração as variáveis da Serasa Experian e censo do IBGE, como por exemplo as demográficas e financeiras. Eles podem ter enxergado na abertura do negócio uma oportunidade de aumentar o seu poder aquisitivo."');}
            when 'D24'{resultado.put('interpretacao','"Muita calma nessa hora. Apesar de possuírem, esses microempreendedores individuais operam com baixas atividades e transações, relacionadas a operacionalidade no mercado, indicando um começo mais cauteloso. <br>Os donos, em sua maioria, são jovens entre 18 e 35 anos, com qualidades empreendedoras. <br>Os setores de comércio e serviços se destacam nesse segmento."');}
            when 'D25'{resultado.put('interpretacao','"Sinal verde por aqui. Esses microempreendedores individuais possuem boa situação de crédito e seus indicadores financeiros sugerem crescimento. <br>Os donos são jovens adultos, com idade entre 26 e 45 anos, que costumam ser ousados apesar de não possuírem um alto poder aquisitivo."');}
            when 'D26'{resultado.put('interpretacao','"Ainda em início das operações, os microempreendedores individuais desse segmento já apresentam alto ou médio risco de crédito, também em relação aos donos, podendo indicar dificuldades nesse começo.<br>Em geral, os donos pertencem às classes sociais C e D, levando em consideração as variáveis da Serasa Experian e censo do IBGE, como por exemplo as informações demográficas e financeiras."');}
            when 'E27'{resultado.put('interpretacao','"São microempresas, que faturam menos que 360 mil ao ano, com alto ou médio risco de crédito. <br>Os sócios possuem uma maior renda em relação aos outros segmentos dentro do mesmo grupo, e isso pode ser um diferencial positivo mesmo em momentos de dificuldades."');}
            when 'E28'{resultado.put('interpretacao','"São jovens microempreendedores individuais, de 21 a 45 anos de idade, e suas empresas possuem entre 5 a 10 anos de existência. <br>Audaciosos, se lançam ao mercado buscando melhorar de vida. Mas, no momento, seus negócios enfrentam dificuldades para deslanchar, o que é constatado pelo alto ou médio risco de crédito. <br>Os setores predominantes nesse segmento são comércio e serviços."');}
            when 'E29'{resultado.put('interpretacao','São microempresas, com faturamento anual inferior a 360 mil, que apresentam alto e médio risco de crédito, o que pode indicar que estão atravessando um momento difícil temporário ou se recuperando e buscando estabilidade, principalmente em relação às outras empresas do mesmo porte.');}
            when 'E30'{resultado.put('interpretacao','"Esse segmento é composto por microempreendedores individuais e microempresas, com faturamento anual inferior a 360 mil. <br>Possuem alto ou médio risco de crédito, indicando instabilidade financeira, tanto por parte da empresa quanto em relação aos donos. <br>Em sua maioria, os donos, possuem um baixo poder aquisitivo e isso pode dificultar a recuperação de suas empresas. "');}
            when 'E31'{resultado.put('interpretacao','"São microempresas, que faturam menos que 360 mil ao ano, com alto ou médio risco de crédito. <br>No geral, essas empresas são constituídas por dois sócios, de 30 a 60 anos. A maioria desses sócios são parentes, como os casos de empresas que passam de pai para filho."');}
            when 'E32'{resultado.put('interpretacao','"Microempreendedores individuais do setor do comércio que estão passando por instabilidades financeiras. <br>Apesar de estarem abertas e em alta operacionalidade, apontada por constantes atividades e consultas no mercado, possuem, um alto ou médio risco de crédito."');}
            when 'E33'{resultado.put('interpretacao','"Esses pequenos comércios, com faturamento anual entre 360 mil e 3,6 milhões, são maduros, com uma predominância em 20 anos de existência, mas atualmente possuem alto ou médio risco de crédito. <br>Indicando uma fase de busca de estabilidade financeira, com impacto nos sócios majoritários."');}
            when 'E34'{resultado.put('interpretacao','"Com faturamento anual entre 360 mil e 3,6 milhões, essas são pequenas empresas maduras, que no geral, possuem mais de 20 anos de existência.  <br>Essas empresas do setor de serviços, possuem alto ou médio risco de crédito. "');}
            when 'E35'{resultado.put('interpretacao','"São empresas de médio porte, com faturamento anual entre 3,6 e 16 milhões, que possuem mais de 5 anos de existência e elevado risco de crédito. <br>Essas empresas passam por um momento muito difícil apesar do porte, esse comportamento financeiro em relação a empresa, pode também, atingir os sócios majoritários. "');}
            when 'E36'{resultado.put('interpretacao','"Essas microempresas estão em um momento de grande dificuldade financeira. <br>Possuem faturamento menor que 360 mil ao ano, com alto risco de crédito. <br>Tudo isso se reflete também no em relação aos sócios."');}
            when 'F37'{resultado.put('interpretacao','"Aqui ficam os pequenos restaurantes, bares e cafés com médio comportamento de crédito. <br>Possuem, no máximo, 20 anos de existência."');}
            when 'F38'{resultado.put('interpretacao','Esses são pequenos comércios do segmento de produtos para o lar e construção.');}
            when 'F39'{resultado.put('interpretacao','Pequenas e microempresas do segmento de serviços em que os sócios possuem alta especialização técnica e cientifica em seu ramo de operação.');}
            when 'F40'{resultado.put('interpretacao','"São pequenas e microempresas do segmento de saúde. <br>A maior parte dos sócios aqui são médicos, dentistas e fisioterapeutas."');}
            when 'F41'{resultado.put('interpretacao','Pequenas empresas de produtores rurais e atividades agropecuárias.');}
            when 'F42'{resultado.put('interpretacao','Pequenas empresas com natureza jurídica de cooperativas.');}
            when 'F43'{resultado.put('interpretacao','Pequenas e microempresas ligadas a atividades financeiras, como seguros, previdências e serviços financeiros.');}
            when 'F44'{resultado.put('interpretacao','Essa são pequenas empresas financeiras instaladas no exterior.');}
            when 'F45'{resultado.put('interpretacao','São pequenas empresas do setor financeiro que se caracterizam como clubes ou fundos de investimento.');}
            when 'F46'{resultado.put('interpretacao','Aqui temos indústrias de pequeno porte e microempresas.');}
            when 'F47'{resultado.put('interpretacao','São microempresas relacionadas a parcerias entre profissionais prestadores de serviço.');}
            when 'F48'{resultado.put('interpretacao','Esse é o segmento das microempresas ligadas a serviços de escritório, apoio administrativo e outros serviços prestados a empresas.');}
            when 'F49'{resultado.put('interpretacao','Pequenas empresas de educação, como escolas, cursos técnicos, profissionalizantes e escolas de idiomas.');}
            when 'G50'{resultado.put('interpretacao','Órgãos e empresas públicas, autarquias, fundações e municípios.');}
            when 'G51'{resultado.put('interpretacao','Esse é o segmento dos partidos políticos e organizações religiosas.');}
            when 'G52'{resultado.put('interpretacao','São as empresas de natureza jurídica condomínio e edifício. ');}
            when 'G53'{resultado.put('interpretacao','São cartórios, que atuam serviço notarial e registral.');}
            when 'G54'{resultado.put('interpretacao','Aqui ficam entidades sem fins lucrativos, ONGs (Organizações Não Governamentais) e OSCIPs (Organizações da Sociedade Civil de Interesse Público).');}
            when else{resultado.put('interpretacao','indeterminado');}
        }

        return resultado;
    }
    public static String calcularUltimosDigitosCNPJ(String cnpj) {

        if(cnpj.length()>12){
            cnpj = cnpj.substring(cnpj.length()-12,cnpj.length());
        }

        List<Integer> pesos1 = new List<Integer>{5,4,3,2,9,8,7,6,5,4,3,2};
        Integer soma;

        soma = 0;
        for( Integer i = 0 ; i < 12; i++ ){
            soma += Integer.valueOf(cnpj.substring(i,i+1)) * pesos1[i];
        }
        String primeiroDigito = String.valueOf( 11 - Math.mod(soma,11) );
        if(primeiroDigito=='10'){primeiroDigito='0';}

        cnpj += primeiroDigito;

        List<Integer> pesos2 = new List<Integer>{6,5,4,3,2,9,8,7,6,5,4,3,2};
        soma = 0;
        for( Integer i = 0 ; i < 13; i++ ){
            soma += Integer.valueOf(cnpj.substring(i,i+1)) * pesos2[i];
        }
        String segundoDigito = String.valueOf( 11 - Math.mod(soma,11) );
        if(segundoDigito=='10'){segundoDigito='0';}

        return primeiroDigito + segundoDigito;
    }









    /********************************************************************************************************************
    *                                                                                                                   *
    *                                    METODOS PARA INICIAR E FINALIZAR TEMPLATES                                     *
    *                                                                                                                   *
    *********************************************************************************************************************/

    public static void initTabela_DadosCadastrais(Relatorio result){
        
        if(!result.dadosCadEmp.containsKey('Tabela-DadosCadastrais')){
            String tabela = ''+
            '<thead>'+
            
                '<tr class="slds-line-height_reset">'+ 
                    '<th>CNPJ</th><th>Situação do CNPJ</th><th></th>'+ 
                '</tr>'+ 
                '<tr class="slds-line-height_reset">'+ 
                    '<td>$CNPJ</td><td>$Situação do CNPJ</td><td></td>'+ 
                '</tr>'+ 

                '<tr class="slds-line-height_reset">'+ 
                    '<th>Razão Social</th><th></th><th></th>'+ 
                '</tr>'+ 
                '<tr class="slds-line-height_reset">'+ 
                    '<td>$Razão Social</td><td></td><td></td>'+ 
                '</tr>'+

                '<tr class="slds-line-height_reset">'+ 
                    '<th>Nome Fantasia</th><th></th><th></th>'+ 
                '</tr>'+ 
                '<tr class="slds-line-height_reset">'+ 
                    '<td>$Nome Fantasia</td><td></td><td></td>'+ 
                '</tr>'+

                '<tr class="slds-line-height_reset">'+ 
                    '<th>Endereço Completo</th><th></th><th></th>'+ 
                '</tr>'+ 
                '<tr class="slds-line-height_reset">'+ 
                    '<td>$Endereço Completo</td><td></td><td></td>'+ 
                '</tr>'+

                '<tr class="slds-line-height_reset">'+ 
                    '<th>Telefone</th><th>Site</th><th></th>'+ 
                '</tr>'+ 
                '<tr class="slds-line-height_reset">'+ 
                    '<td>$Telefone</td><td>$Site</td><td></td>'+ 
                '</tr>'+ 

                '<tr class="slds-line-height_reset">'+ 
                    '<th>Tipo de Sociedade</th><th></th><th></th>'+ 
                '</tr>'+ 
                '<tr class="slds-line-height_reset">'+ 
                    '<td>$Tipo de Sociedade</td><td></td><td></td>'+ 
                '</tr>'+ 

                '<tr class="slds-line-height_reset">'+ 
                    '<th>Registro</th><th>Registro realizado em</th><th>NIRE</th>'+ 
                '</tr>'+ 
                '<tr class="slds-line-height_reset">'+ 
                    '<td>$REGISTRO</td><td>$Registro realizado em</td><td>$NIRE</td>'+ 
                '</tr>'+

                '<tr class="slds-line-height_reset">'+ 
                    '<th>Antecessoras</th><th></th><th></th>'+ 
                '</tr>'+ 
                '<tr class="slds-line-height_reset">'+ 
                    '<td>$antecessoras</td><td></td><td></td>'+ 
                '</tr>'+

                '<tr class="slds-line-height_reset">'+ 
                    '<th>Fundação</th><th></th><th></th>'+ 
                '</tr>'+ 
                '<tr class="slds-line-height_reset">'+ 
                    '<td>$Fundação</td><td></td><td></td>'+ 
                '</tr>'+

                '<tr class="slds-line-height_reset">'+ 
                    '<th>Número de Funcionários</th><th></th><th></th>'+ 
                '</tr>'+ 
                '<tr class="slds-line-height_reset">'+ 
                    '<td>$Número de Funcionários</td><td></td><td></td>'+ 
                '</tr>'+

                '<tr class="slds-line-height_reset">'+ 
                    '<th>Opção Tributária</th><th>Inscrição Estadual</th><th></th>'+ 
                '</tr>'+ 
                '<tr class="slds-line-height_reset">'+ 
                    '<td>$Opção Tributária</td><td>$Inscrição Estadual</td><td></td>'+ 
                '</tr>'+

                '<tr class="slds-line-height_reset">'+ 
                    '<th>Ramo de atividade econômica</th><th></th><th></th>'+ 
                '</tr>'+ 
                '<tr class="slds-line-height_reset">'+ 
                    '<td>$Ramo de atividade econômica</td><td></td><td></td>'+ 
                '</tr>'+

                '<tr class="slds-line-height_reset">'+ 
                    '<th>Código de Atividade Serasa</th><th>Importação sobre Compras</th><th>Exportação sobre Vendas</th>'+ 
                '</tr>'+ 
                '<tr class="slds-line-height_reset">'+ 
                    '<td>$Código de Atividade Serasa</td><td>$Importação sobre Compras</td><td>$Exportação sobre Vendas</td>'+ 
                '</tr>'+

                '<tr class="slds-line-height_reset">'+ 
                    '<th>CNAE</th><th></th><th></th>'+ 
                '</tr>'+ 
                '<tr class="slds-line-height_reset">'+ 
                    '<td>$CNAE</td><td></td><td></td>'+ 
                '</tr>'+

                '<tr class="slds-line-height_reset">'+ 
                    '<th>Consultar Filiais</th><th></th><th></th>'+ 
                '</tr>'+ 
                '<tr class="slds-line-height_reset">'+ 
                    '<td>$Consultar Filiais</td><td></td><td></td>'+ 
                '</tr>'+

            '</thead>'+
            '';
            result.dadosCadEmp.put('Tabela-DadosCadastrais',tabela);
        }    
    }
    public static void initTabela_DetalhesConsulta(Relatorio result){
        
        if(!result.informacoesPadrao.containsKey('Tabela-DetalhesConsulta')){
            String tabela = ''+ 
            '<thead>'+ 

                '<tr class="slds-line-height_reset">'+ 
                    '<td><b>Nome Fantasia: </b>$nomeFantasia</td>'+ 
                '</tr>'+ 

                '<tr class="slds-line-height_reset">'+ 
                    '<td><b>CNPJ: </b>$CNPJ</td>'+ 
                '</tr>'+

                '<tr class="slds-line-height_reset">'+
                    '<td><b>Razão Social: </b>$razaoSocial</td>'+
                '</tr>'+

                '<tr class="slds-line-height_reset">'+
                    '<td><b>Data e Hora da Consulta: </b>$dataEhora</td>'+
                '</tr>'+

            '</thead>';
            result.informacoesPadrao.put('Tabela-DetalhesConsulta',tabela);
        }
    }
    public static void endTabelas(Relatorio result){

        //dados cadastrais
        if(result.dadosCadEmp.containsKey('Tabela-DadosCadastrais')){
            String tabela = result.dadosCadEmp.get('Tabela-DadosCadastrais');
            
            List<String> chaves = new List<String>{'$CNPJ','$Situação do CNPJ','$Razão Social','$Nome Fantasia','$Endereço Completo','$Telefone','$Site','$Tipo de Sociedade','$REGISTRO','$Registro realizado em','$NIRE','$Fundação','$Número de Funcionários','$Inscrição Estadual','$Ramo de atividade econômica','$Código de Atividade Serasa','$Importação sobre Compras','$Exportação sobre Vendas','$CNAE','$Consultar Filiais'};

            if(result.dadosCadEmp.containsKey('$antecessoras')){
                tabela = tabela.replace('$antecessoras',result.dadosCadEmp.get('$antecessoras'));
            }
            else{
                chaves.add('$antecessoras');
            }

            for(String chave:chaves){
                tabela = tabela.replace(chave,'');
            }

            result.dadosCadEmp.put('Tabela-DadosCadastrais',tabela);
        }
        if(result.dadosCadEmp.containsKey('Tabela-Grafias')){
            String tabela = result.dadosCadEmp.get('Tabela-Grafias');

            if(tabela.contains('$QuantidadeGrafias')){
                String quantidadeGrafias = result.dadosCadEmp.get('$QuantidadeGrafias');
                tabela = tabela.replace( 'mais de $QuantidadeGrafias variações encontradas',quantidadeGrafias + ' variações encontradas' );
            }
            result.dadosCadEmp.put('Tabela-Grafias',tabela);
        }   
        if(!result.dadosCadEmp.containsKey('Tabela-Mosaic') && isIN(parametrosSelecionados,'MosaicBusiness')){
            result.dadosCadEmp.put('Tabela-Mosaic','<tr class="slds-line-height_reset"><td class="slds-cell-wrap" >NAO FOI POSSIVEL IDENTIFICAR O MOSAIC BUSINESS REFERENTE A ESSA EMPRESA</td></tr>');
        }
        if(result.dadosCadEmp.containsKey('Tabela-SituacaoFiscal')){
            String tabela = result.dadosCadEmp.get('Tabela-SituacaoFiscal');
            List<String> variaveis = new List<String>{'$atividadeEconomica','$consultaSituacaoFisca','$cnaeSecundariaReceita','$consultasFazenda','$observacaoSecretaria'};
            for(String variavel:variaveis){
                tabela = tabela.replace(variavel,'');
                result.dadosCadEmp.put('Tabela-SituacaoFiscal',tabela); 
            }
        }
        else if(isIN(parametrosSelecionados,'SituacaoFiscal')){
                result.dadosCadEmp.put('Tabela-SituacaoFiscal','<tr class="slds-line-height_reset"><td class="slds-cell-wrap" >EMPRESA NAO CADASTRADA NA BASE SERASA EXPERIAN</td></tr>');
            }
        if(result.informacoesPadrao.containsKey('Tabela-AlertaCadastral')){
           String tabela = result.informacoesPadrao.get('Tabela-AlertaCadastral');
           List<String> chaves = new List<String>{'$razaoSocial','$Ramo de Atividade','$Endereço','$Presença de cadastro na CGU','$Tipo Societário','$Inconsistências Comerciais'};
           for(String chave:chaves){
               tabela = tabela.replace(chave,'');
           }
           result.informacoesPadrao.put('Tabela-AlertaCadastral',tabela);
        }
        


        //informacoes societais
        if(!result.quadroSocialAdministracaoMaisCompleto.containsKey('Tabela-quadroSocialMaisCompleto') && isIN(parametrosSelecionados,'QuadroSocialAdministracaoMaisCompleto')){
            result.quadroSocialAdministracaoMaisCompleto.put('Tabela-quadroSocialMaisCompleto','<tr class="slds-line-height_reset"><td class="slds-cell-wrap">Não há informações de sócios e administradores para a empresa consultada em nossas bases</td></tr>');
        }
        if(!result.informacoesSobreSociosAdministradores.containsKey('Tabela-RendaProSociosEAdministradoresPF') && isIN(parametrosSelecionados,'RendaProSociosEAdministradoresPF')){
            result.anotacoesConsultasSPCSocios.put('Tabela-RendaProSociosEAdministradoresPF','<tr class="slds-line-height_reset"><td class="slds-cell-wrap">EMPRESA NÃO POSSUI SÓCIOS OU ADMINISTRADORES PF</td></tr>');
        }
        if(!result.informacoesSobreSociosAdministradores.containsKey('Tabela-RendaProSociosEAdministradoresPF') && isIN(parametrosSelecionados,'RendaProSociosEAdministradoresPF')){
            result.informacoesSobreSociosAdministradores.put('Tabela-RendaProSociosEAdministradoresPF','<tr class="slds-line-height_reset"><td>EMPRESA NÃO POSSUI SÓCIOS OU ADMINISTRADORES PF</td></tr>');
        }
        if(result.informacoesSobreSociosAdministradores.containsKey('Tabela-AlertaCadSociosAdms')){
            String tabela = result.informacoesSobreSociosAdministradores.get('Tabela-AlertaCadSociosAdms');
            List<String> chaves = new List<String>{'$Quadro Societário','$Quadro Administrativo','$Inconsistências Societárias','$Inconsistências Administrativas','$Alerta de Óbito dos Sócios','$Alerta de Óbito dos Administradores'};
            for(String chave:chaves){
                tabela = tabela.replace(chave,'');
            }
            result.informacoesSobreSociosAdministradores.put('Tabela-AlertaCadSociosAdms',tabela);
        }
        if(!result.informacoesSobreSociosAdministradores.containsKey('Tabela-sociosAcionistas')){
            result.informacoesSobreSociosAdministradores.put('Tabela-AlertaCadSociosAdms','<tr class="slds-line-height_reset"><td class="slds-cell-wrap">PELAS CARACTERISTICAS SOCIETARIAS A INFORMACAO NAO SE APLICA</td></tr>');
        }


        if(result.anotacoesConsultasSPCSocios.containsKey('$quantidadeAnotacoes')){
            result.anotacoesConsultasSPCSocios.put('Tabela-AnotacoesSpcSociosAdministradores',result.anotacoesConsultasSPCSocios.get('Tabela-AnotacoesSpcSociosAdministradores').replace('$Quantidade',result.anotacoesConsultasSPCSocios.get('$quantidadeAnotacoes')));
        }
        if(result.anotacoesConsultasSPCSocios.containsKey('$valorTotal')){
            result.anotacoesConsultasSPCSocios.put('Tabela-AnotacoesSpcSociosAdministradores',result.anotacoesConsultasSPCSocios.get('Tabela-AnotacoesSpcSociosAdministradores').replace('$Valor Total (R$)',result.anotacoesConsultasSPCSocios.get('$valorTotal')));
        }



        //informacoes sobre consultas
        if(!result.anotacoesConsultasSPCSocios.containsKey('Tabela-ConsultasSPC') && isIN(parametrosSelecionados,'AnotacoesConsultasSPC')){
            result.anotacoesConsultasSPCSocios.put('Tabela-ConsultasSPC','<tr class="slds-line-height_reset"><td class="slds-cell-wrap">=== NADA CONSTA PARA O CNPJ CONSULTADO ===</td></tr>');
        }



        //anotacoes negativas
        if(!result.informacoesAnotacoesNegativas.containsKey('Tabela-pendenciasFinanceirasRefin')){
            result.informacoesAnotacoesNegativas.put('Tabela-pendenciasFinanceirasRefin','<tr class="slds-line-height_reset"><td class="slds-cell-wrap" >=== NADA CONSTA PARA O CNPJ CONSULTADO ===</td></tr>');
        }
        if(!result.informacoesAnotacoesNegativas.containsKey(('Tabela-Protestos'))){
            result.informacoesAnotacoesNegativas.put('Tabela-Protestos','<tr class="slds-line-height_reset"><td class="slds-cell-wrap" >=== NADA CONSTA PARA O CNPJ CONSULTADO ===</td></tr>');
        }
        if(!result.informacoesAnotacoesNegativas.containsKey(('Tabela-dividasVencidas'))){
            result.informacoesAnotacoesNegativas.put('Tabela-dividasVencidas','<tr class="slds-line-height_reset"><td class="slds-cell-wrap" >=== NADA CONSTA PARA O CNPJ CONSULTADO ===</td></tr>');
        }
        if(!result.informacoesAnotacoesNegativas.containsKey(('Tabela-falenciaErecuperacao'))){
            result.informacoesAnotacoesNegativas.put('Tabela-falenciaErecuperacao','<tr class="slds-line-height_reset"><td class="slds-cell-wrap" >=== NADA CONSTA PARA O CNPJ CONSULTADO ===</td></tr>');
        }
        if(!result.informacoesAnotacoesNegativas.containsKey(('Tabela-pendenciasFinanceirasPefin'))){
            result.informacoesAnotacoesNegativas.put('Tabela-pendenciasFinanceirasPefin','<tr class="slds-line-height_reset"><td class="slds-cell-wrap" >=== NADA CONSTA PARA O CNPJ CONSULTADO ===</td></tr>');
        }
        if(!result.informacoesAnotacoesNegativas.containsKey(('Tabela-AnotacoesSPC')) && isIN(parametrosSelecionados,'AnotacoesConsultasSPC')){
            result.informacoesAnotacoesNegativas.put('Tabela-AnotacoesSPC','<tr class="slds-line-height_reset"><td class="slds-cell-wrap" >=== NADA CONSTA PARA O CNPJ CONSULTADO ===</td></tr>');
        }
    }
      















    /*********************************************************************************************************
    *                                                                                                        *
    *                         METODOS PARA EXTRAIR E GERENCIAR OS QUADROS DA RESPONSE                        *
    *                                                                                                        *
    **********************************************************************************************************/

    //quadros sem classificação
    public static void formatarL010000(String retorno, Relatorio result) { // Frase status da empresa 
        Map<String,String> mapSituacao = new Map<String,String>{'00' => 'Inapta','03' => 'Inativa', '02' => 'Ativa', '04' => 'Não localizada', '05' => 'Em liquidação', '06' => 'Suspensa', '07' => 'Não cadastrada', '09' => 'Cancelada'};
        String situacaoCNPJ = mapSituacao.get(retorno.substring(0, 2).trim());
        //result.dadosCadEmp.put('Situação do CNPJ',situacaoCNPJ);

        initTabela_DadosCadastrais(result);
        result.dadosCadEmp.put('Tabela-DadosCadastrais',result.dadosCadEmp.get('Tabela-DadosCadastrais').replace('$Situação do CNPJ',situacaoCNPJ));
    } 
    public static void formatarL010101(String retorno, Relatorio result) { // Contabilização
        
        //old
        //result.dadosCadEmp.put('Data e hora da consulta', formatarDataAAAAMMDD(retorno.substring(60,68).trim()) + ' ' + retorno.substring(68,76).trim());
        //result.dadosCadEmp.put('CNPJ', retorno.substring(84, 102).trim());
        //result.dadosCadEmp.put('Ultima Atualização dos Dados Cadastrais', formatarDataAAAAMMDD(retorno.substring(102, 110))); 
        if(Integer.valueOf(retorno.substring(114, 122)) != 0) {
            String registroSemZeros = retorno.substring(114, 122);
            //result.dadosCadEmp.put('Registro', registroSemZeros.substring(0, 1) + '.' 
                                                    //+ registroSemZeros.substring(1, 4) + '.' 
                                                    //+ registroSemZeros.substring(4, 7)); 
        }
        //result.dadosCadEmp.put('Registro realizado em', formatarDataAAAAMMDD(retorno.substring(122, 130)));
        



        //new
        initTabela_DetalhesConsulta(result);
        initTabela_DadosCadastrais(result);

        Map<String,String> detalhesConsulta = new Map<String,String>();
        detalhesConsulta.put('confidencial',retorno.substring(0,60).trim());
        detalhesConsulta.put('data',retorno.substring(60,68).trim());
        detalhesConsulta.put('hora',retorno.substring(68,76).trim());
        detalhesConsulta.put('areaReservada',retorno.substring(76,78).trim());
        detalhesConsulta.put('contante+cnpjEditado',retorno.substring(78,102).trim());
        detalhesConsulta.put('dataUltimaAtualizacao',retorno.substring(102,110).trim());
        detalhesConsulta.put('tipoRetornoJunta',retorno.substring(110,111).trim());
        detalhesConsulta.put('numeroUltimoRegistro',retorno.substring(111,122).trim());
        detalhesConsulta.put('dataUltimoRegistro',retorno.substring(122,130).trim());
        /*
        String outPutMap = '';
        for(String chave:detalhesConsulta.keyset()){
            outPutMap += '\n' + chave + ':' + detalhesConsulta.get(chave);
        }
        System.debug('\n\n<QUADRO L010101>\nretorno:'+retorno + outPutMap + '\n</QUADRO L010101>\n\n');
        */
        //[ TABELA DETALHES DA CONSULTA ]
        String tableAtual = result.informacoesPadrao.get('Tabela-DetalhesConsulta');
        string cnpj = detalhesConsulta.get('contante+cnpjEditado').split(':')[1];
        tableAtual = tableAtual.replace('$CNPJ',cnpj);
        String data = formatarDataAAAAMMDD(detalhesConsulta.get('data'));
        String hora = detalhesConsulta.get('hora');
        String dataEhora = data + ' ' + hora;
        tableAtual = tableAtual.replace('$dataEhora',dataEhora);
        result.informacoesPadrao.put('Tabela-DetalhesConsulta',tableAtual);

        //[ TABELA DADOS CADASTRAIS ]
        result.dadosCadEmp.put('Tabela-DadosCadastrais',result.dadosCadEmp.get('Tabela-DadosCadastrais').replace('$CNPJ',cnpj));
        String registro = formatarValor(detalhesConsulta.get('numeroUltimoRegistro'),0);
        result.dadosCadEmp.put('Tabela-DadosCadastrais',result.dadosCadEmp.get('Tabela-DadosCadastrais').replace('$REGISTRO',registro));
        String dataRegistro = formatarDataAAAAMMDD(detalhesConsulta.get('dataUltimoRegistro'));
        result.dadosCadEmp.put('Tabela-DadosCadastrais',result.dadosCadEmp.get('Tabela-DadosCadastrais').replace('$Registro realizado em',dataRegistro));
    } 
    public static void formatarL010102(String retorno, Relatorio result) { // Identificação 
        //old
        //result.dadosCadEmp.put('Razão social', retorno.substring(0 ,  70).trim());            
        //result.dadosCadEmp.put('Nome fantasia', retorno.substring(79, 139).trim());           
        //result.dadosCadEmp.put('NIRE',  retorno.substring(139, 141) + '.' +
                                            //retorno.substring(141, 144) + '.' +
                                            //retorno.substring(144, 147) + '.' +
                                            //retorno.substring(147, 150));          
        //result.dadosCadEmp.put('Tipo de sociedade',   retorno.substring(150, 210).trim());         
        //result.dadosCadEmp.put('Opção tributária',   retorno.substring(210, 240).trim()); 
        
        //new
        initTabela_DetalhesConsulta(result);
        initTabela_DadosCadastrais(result);

        Map<String,String> detalhesConsulta = new Map<String,String>();
        detalhesConsulta.put('razaoSocial',retorno.substring(0,70).trim());
        detalhesConsulta.put('cnpj',retorno.substring(70,79).trim());
        detalhesConsulta.put('nomeFantasia',retorno.substring(79,139).trim());
        detalhesConsulta.put('NIRE',retorno.substring(139,150).trim());
        detalhesConsulta.put('tipoSocietario',retorno.substring(150,210).trim());
        detalhesConsulta.put('opcaoTributaria',retorno.substring(210,240).trim());
        /*
        String outPutMap = '';
        for(String chave:detalhesConsulta.keyset()){
            outPutMap += '\n' + chave + ':' + detalhesConsulta.get(chave);
        }
        System.debug('\n\n<QUADRO L010102>\nretorno:'+retorno + outPutMap + '\n</QUADRO L010102>\n\n');
        */
        String tabelaDetalhesConsulta = result.informacoesPadrao.get('Tabela-DetalhesConsulta');
        String tabelaDadosCadastrais = result.dadosCadEmp.get('Tabela-DadosCadastrais');

        String razaoSocial = detalhesConsulta.get('razaoSocial');
        tabelaDetalhesConsulta = tabelaDetalhesConsulta.replace('$razaoSocial',razaoSocial);
        tabelaDadosCadastrais = tabelaDadosCadastrais.replace('$Razão Social',razaoSocial);

        String nomeFantasia = detalhesConsulta.get('nomeFantasia');
        tabelaDetalhesConsulta = tabelaDetalhesConsulta.replace('$nomeFantasia',nomeFantasia);
        tabelaDadosCadastrais = tabelaDadosCadastrais.replace('$Nome Fantasia',nomeFantasia);

        String nire = formatarValor(detalhesConsulta.get('NIRE'),0);
        tabelaDadosCadastrais = tabelaDadosCadastrais.replace('$NIRE',nire);
        
        String tipoSociedade = detalhesConsulta.get('tipoSocietario');
        tabelaDadosCadastrais = tabelaDadosCadastrais.replace('$Tipo de Sociedade',tipoSociedade);
        
        String opcaoTributaria = detalhesConsulta.get('opcaoTributaria');
        tabelaDadosCadastrais = tabelaDadosCadastrais.replace('$Opção Tributária',opcaoTributaria);
        
        result.informacoesPadrao.put('Tabela-DetalhesConsulta',tabelaDetalhesConsulta);
        result.dadosCadEmp.put('Tabela-DadosCadastrais',tabelaDadosCadastrais);
    }
    public static void formatarL010103(String retorno, Relatorio result) { // L010103 - Endereço 
        result.dadosCadEmp.put('$EnderecoCompleto', retorno.substring(0,69)); 

        //initTabela_DadosCadastrais(result);
        //result.dadosCadEmp.put('Tabela-DadosCadastrais',result.dadosCadEmp.get('Tabela-DadosCadastrais').///replace('$Endereço Completo',retorno.substring(0,69)));
    }
    public static void formatarL010110(String retorno, Relatorio result) { // Quadro Administrativo - Data da Última Atualização 
        result.informacoesSobreSociosAdministradores.put('Data da última atualização', formatarDataAAAAMMDD(retorno.substring(0,8)));
    }
    public static void formatarL010111(String retorno, Relatorio result) { // Quadro Administrativo - Detalhes 

        String cnpjOuCpf                                 = formatarCpfOuCnpj(retorno.substring(1,10) + retorno.substring(14,16), retorno.substring(0,1),'');
        String nomeAcionistaOuSocioOuAdministrador       = retorno.substring(16 , 74).trim();
        String cargo                                     = retorno.substring(74 , 86).trim();  
        String pais                                      = retorno.substring(86 , 98).trim();
        String estadoCivil                               = retorno.substring(98 ,107).trim();

        String inicioMandato                            = formatarDataAAAAMMDD(retorno.substring(107,115));
        if(inicioMandato.substring(0,3) == '00/') {
            inicioMandato.remove('00/');
        } 

        String fimMandato;
        if(retorno.substring(115, 123) != '99999999') {
            fimMandato  = formatarDataAAAAMMDD(retorno.substring(115, 123));
            if(fimMandato.substring(0,3) == '00/') {
                fimMandato.remove('00/'); 
            }

        } else {
            fimMandato = 'INDETERMINADO';
        }    
        
        String mandato       =  fimMandato;
        
        if(!result.informacoesSobreSociosAdministradores.containsKey('Tabela-Administração')){
            result.informacoesSobreSociosAdministradores.put('Tabela-Administração','<thead><tr class="slds-line-height_reset"><th>	CPF/CNPJ</th>	<th>Administração</th><th>Cargo</th><th>Nacionalidade</th><th>Estado Civil</th><th>Entrada</th><th>Mandato</th></tr></thead>');
        }
        result.informacoesSobreSociosAdministradores.put('Tabela-Administração',result.informacoesSobreSociosAdministradores.get('Tabela-Administração')+'<tr class"slds-line-height_reset"><td class="slds-cell-wrap" >'+cnpjOuCpf+'</td><td class="slds-cell-wrap" >'+nomeAcionistaOuSocioOuAdministrador+'</td><td class="slds-cell-wrap" >'+cargo+'</td><td class="slds-cell-wrap" >'+pais+'</td><td class="slds-cell-wrap" >'+estadoCivil+'</td><td class="slds-cell-wrap" >'+inicioMandato+'</td><td class="slds-cell-wrap" >'+mandato+'</td></tr>');

        result.informacoesSobreSociosAdministradores.put( '$' + cnpjOuCpf , nomeAcionistaOuSocioOuAdministrador );
        result.informacoesSobreSociosAdministradores.put( '$' + nomeAcionistaOuSocioOuAdministrador , cnpjOuCpf );
        result.informacoesSobreSociosAdministradores.put( '$' + cnpjOuCpf , nomeAcionistaOuSocioOuAdministrador );
        result.informacoesSobreSociosAdministradores.put( '$' + cnpjOuCpf + 'nacionalidade' , pais );
        result.informacoesSobreSociosAdministradores.put( '$' + cnpjOuCpf + 'mandato' , inicioMandato + '-' + fimMandato );
        result.informacoesSobreSociosAdministradores.put( '$' + cnpjOuCpf + 'estadoCivil' , estadoCivil );
        result.informacoesSobreSociosAdministradores.put( '$' + cnpjOuCpf + 'cargo' , cargo );  

        if(isIN(parametrosSelecionados,'RendaProSociosEAdministradoresPF')){
            if(!result.informacoesSobreSociosAdministradores.containsKey('Tabela-RendaProSociosEAdministradoresPF')){
                String template = ''+
                 '<thead>'+
                    '<tr class="slds-line-height_reset">'+
                         '<th>CPF / CNPJ</th>'+
                        '<th>Nome Completo</th>'+
                        '<th>Faixas (em Reais)</th>'+
                    '</tr>'+
                 '</thead>';
                 result.informacoesSobreSociosAdministradores.put('Tabela-RendaProSociosEAdministradoresPF',template);
            }
            String tabela = result.informacoesSobreSociosAdministradores.get('Tabela-RendaProSociosEAdministradoresPF');
    
            if(!tabela.contains(cnpjOUcpf)){
                tabela += ''+
                '<tr class="slds-line-height_reset">'+
                    '<td class="slds-cell-wrap" >' + cnpjOUcpf + '</td>'+
                    '<td class="slds-cell-wrap" >' + nomeAcionistaOuSocioOuAdministrador + '</td>'+
                    '<td class="slds-cell-wrap" >Renda não calculada</td>'+
                '</tr>';
        
                result.informacoesSobreSociosAdministradores.put('Tabela-RendaProSociosEAdministradoresPF',tabela);
            }
        }        
    }
    public static void formatarL010104(String retorno, Relatorio result){
        
        String substring = retorno.substring(0, 207);
        
        String enderecoCompleto = result.dadosCadEmp.get('$EnderecoCompleto');
        enderecoCompleto += ', ' + retorno.substring(0 , 30).trim() 
                                        + ' - ' + retorno.substring(30, 32).trim()
                                        + ', '  + retorno.substring(32, 41).trim(); 
        //result.dadosCadEmp.put('Endereço completo',enderecoCompleto);
        
        String telefone = '(' + retorno.substring(41, 45).removeStart('0')+') ' +
        retorno.substring(45, 50).removeStart('0')+'-'+ 
        retorno.substring(50, 54).trim();
        result.dadosCadEmp.put('$Telefone',telefone );  

        String site = retorno.substring(67, 137).trim();
        //result.dadosCadEmp.put('Site', site); 

        initTabela_DadosCadastrais(result);
        result.dadosCadEmp.put('Tabela-DadosCadastrais',result.dadosCadEmp.get('Tabela-DadosCadastrais').replace('$Endereço Completo',enderecoCompleto));
        result.dadosCadEmp.put('Tabela-DadosCadastrais',result.dadosCadEmp.get('Tabela-DadosCadastrais').replace('$Telefone',telefone));
        result.dadosCadEmp.put('Tabela-DadosCadastrais',result.dadosCadEmp.get('Tabela-DadosCadastrais').replace('$Site',site));
    }
    public static void formatarL010105(String retorno, Relatorio result) { // Atividade
        Integer dataAnoFund     = Integer.valueOf(retorno.substring(0,4));
        Integer dataMesFund     = Integer.valueOf(retorno.substring(4,6));
        Integer dataDiaFund     = Integer.valueOf(retorno.substring(6,8));
        Integer dataAnoHoje     = Integer.valueOf(Date.today().year());
        Integer ajuste = 0;
        if(dataMesFund > Date.today().month()){
            ajuste = -1;
        }else if(dataMesFund == Date.today().month() && dataDiaFund < Date.today().day()){
            ajuste = -1;
        }

        String  anosEmpresa  = String.valueOf((dataAnoHoje - dataAnoFund + ajuste)) ;    
        String dataFundacao = formatarDataAAAAMMDD(retorno.substring(0,8))+' (' + anosEmpresa + ' anos)';
        //result.dadosCadEmp.put('Data fundação',dataFundacao); 

        String ramoAtividade = retorno.substring(16, 70).trim();
        //result.dadosCadEmp.put('Ramo de atividade econômica',ramoAtividade);                

        String codigoAtividade = retorno.substring(70, 71).trim() + '-' +
        retorno.substring(71, 73).trim() + '.' +
        retorno.substring(73, 75).trim() + '.' +
        retorno.substring(75, 77).trim();
        //result.dadosCadEmp.put('Código de atividade serasa',codigoAtividade); 
                                                                  
        String numeroFuncionarios = removerZeros(retorno.substring(77,82));
        //result.dadosCadEmp.put('Número de funcionários',numeroFuncionarios);   

        String importacaoSobreCompras = removerZeros(retorno.substring(82,85)) + '%';
        //result.dadosCadEmp.put('Importação sobre compras',importacaoSobreCompras);

        String exportacaoSobreVendas = removerZeros(retorno.substring(85,88)) + '%';
        //result.dadosCadEmp.put('Exportação sobre vendas',exportacaoSobreVendas);
        
        String numeroFiliais = 'Número de Filiais: ' + removerZeros(retorno.substring(91,97));
        //result.dadosCadEmp.put('Número de filiais',numeroFiliais);
        
        String cnae = retorno.substring(97 ,  99).trim() + '.' +
        retorno.substring(99 , 102).trim() + '-' +
        retorno.substring(102, 104).trim();
        //result.dadosCadEmp.put('CNAE',cnae); 


        initTabela_DadosCadastrais(result);
        result.dadosCadEmp.put('Tabela-DadosCadastrais',result.dadosCadEmp.get('Tabela-DadosCadastrais').replace('$Fundação',dataFundacao));
        result.dadosCadEmp.put('Tabela-DadosCadastrais',result.dadosCadEmp.get('Tabela-DadosCadastrais').replace('$Ramo de atividade econômica',ramoAtividade));
        result.dadosCadEmp.put('Tabela-DadosCadastrais',result.dadosCadEmp.get('Tabela-DadosCadastrais').replace('$Número de Funcionários',numeroFuncionarios));
        result.dadosCadEmp.put('Tabela-DadosCadastrais',result.dadosCadEmp.get('Tabela-DadosCadastrais').replace('$Importação sobre Compras',importacaoSobreCompras));
        result.dadosCadEmp.put('Tabela-DadosCadastrais',result.dadosCadEmp.get('Tabela-DadosCadastrais').replace('$Exportação sobre Vendas',exportacaoSobreVendas));
        result.dadosCadEmp.put('Tabela-DadosCadastrais',result.dadosCadEmp.get('Tabela-DadosCadastrais').replace('$Código de Atividade Serasa',codigoAtividade));
        result.dadosCadEmp.put('Tabela-DadosCadastrais',result.dadosCadEmp.get('Tabela-DadosCadastrais').replace('$Consultar Filiais',numeroFiliais));
        result.dadosCadEmp.put('Tabela-DadosCadastrais',result.dadosCadEmp.get('Tabela-DadosCadastrais').replace('$CNAE',cnae)); 
    }
    public static void formatarL010106(String retorno, Relatorio result){
        if(!result.dadosCadEmp.containsKey('Nome filial')){
            result.dadosCadEmp.put('Nome filial',retorno.substring(0,30));
            result.dadosCadEmp.put('Código embratel',retorno.substring(30,34));
        }else{
            String data = result.dadosCadEmp.get('Nome filial') +';'+ retorno.substring(0,30);
            String numero = result.dadosCadEmp.get('Código embratel') +';'+retorno.substring(30,34);
            result.dadosCadEmp.put('Nome filial', data);
            result.dadosCadEmp.put('Código embratel', numero);
        }
    }
    public static void formatarL010116(String retorno, Relatorio result){
        String antecessor = retorno.substring(0,70) +' - até '+ retorno.substring(77,79)+'/'+retorno.substring(75,77)+'/'+retorno.substring(71,75);
        
        if(!result.dadosCadEmp.containsKey('$antecessoras')){
            result.dadosCadEmp.put('$antecessoras','');
        }
        //System.debug('\n\n<QUADRO L010106>\nretorno:'+retorno + '\nantecessor: ' +antecessor + '\n</QUADRO L010106>\n\n');

        String antecessores = result.dadosCadEmp.get('$antecessoras');
        if( antecessores != ''){
            antecessores += '<br>';
        }
        antecessores += antecessor;
        result.dadosCadEmp.put('$antecessoras',antecessores);
    }
    public static void formatarL040301(String retorno, Relatorio result) { // L040301 - Mensagem 
        //Concentre – Protestos

        String data = retorno.substring(15,17) + '/' + retorno.substring(13,15) + '/' + retorno.substring(9,13);
        String valor = retorno.substring(18,20).trim() + Decimal.valueOf(removerZeros(retorno.substring(20,33))).format();
        String cartorio   = retorno.substring(33,35).trim();
        String cidadeUf   = retorno.substring(35,65).trim() + '/' + retorno.substring(65,67);

        if(!result.informacoesAnotacoesNegativas.containsKey('Tabela-Protestos')){
            result.informacoesAnotacoesNegativas.put('Tabela-Protestos','<thead><tr class="slds-line-height_reset"><th>Data</th><th>Valor</th><th>Cartório</th><th>Cidade/UF</th></tr></thead>');
        }
        result.informacoesAnotacoesNegativas.put('Tabela-Protestos',result.informacoesAnotacoesNegativas.get('Tabela-Protestos')+'<tr class"slds-line-height_reset"><td class="slds-cell-wrap" >'+data +'</td><td class="slds-cell-wrap" >'+valor +'</td><td class="slds-cell-wrap" >'+cartorio +'</td><td class="slds-cell-wrap" >'+cidadeUf +'</td></tr>');
    }
    public static void formatarL040202(String retorno, Relatorio result) {  // L040202 - Informações do Concentre(Ocorrencias)  

        List<String> tipos = new List<String>{'REFIN','PEFIN','Dívidas Vencidas','Falência/Rec. Judicial','Ações Judiciais','Protestos','Cheques','Recheque'};
        for( String tipo:tipos ){
            if(!result.informacoesAnotacoesNegativas.containsKey(tipo)){
                result.informacoesAnotacoesNegativas.put(tipo,'Nada Consta');
            }
        }

        Map<String,String> tiposNatureza = new Map<String,String>{'01'=>'Pendência financeira', '02'=>'','03'=>'Protesto','04'=>'Ação judicial','05'=>'Participação em falência','06'=>'Falência/concordata','07'=>'Dívida vencida','08'=>'','09'=>'Cheque sem fundo achei','10'=>'REFIN'};

        String quantidade = removerZeros(retorno.substring(0, 9).trim());
        String discriminacao = retorno.substring(9,36).trim();
        String periodo = retorno.substring(36,39) + '/' + retorno.substring(41,43) + '-' + retorno.substring(43,46) + '/' + retorno.substring(48,50);
        String valor = retorno.substring(50,53).trim() + Decimal.valueOf(removerZeros(retorno.substring(53,66))).format();
        String origem =  retorno.substring(66,86).trim();
        String agencia =  retorno.substring(86,90).trim();
        String total = formatarValor(retorno.substring(90,103).trim(),0);
        String natureza =  retorno.substring(103,106).trim();

        switch on tiposNatureza.get(natureza){
            when 'REFIN'{result.informacoesAnotacoesNegativas.put('REFIN','R$ ' + total);}
            when 'Pendência financeira'{result.informacoesAnotacoesNegativas.put('PEFIN','R$ ' + total);}
            when 'Dívida vencida'{result.informacoesAnotacoesNegativas.put('Dívidas Vencidas','R$ ' + total);}
            when 'Falência/concordata' {result.informacoesAnotacoesNegativas.put('Falência/Rec. Judicial','R$ ' + total);}
            when 'Ação judicial'{result.informacoesAnotacoesNegativas.put('Ações Judiciais','R$ ' + total);}
            when 'Protesto'{result.informacoesAnotacoesNegativas.put('Protestos','R$ ' + total);}
            when 'Cheque sem fundo achei'{result.informacoesAnotacoesNegativas.put('Cheques','R$ ' + total);}
        }

        if(!result.informacoesPadrao.containsKey('Tabela-Concentre')){
            result.informacoesPadrao.put('Tabela-Concentre','<thead><tr class="slds-line-height_reset"><th>Quantidade</th><th>Discriminação</th><th>Período</th><th>Qtd	Valor</th><th>Origem</th><th>Agência</th><th>Total</th><th>Natureza</th></tr></thead>');
        }

        result.informacoesPadrao.put('Tabela-Concentre',result.informacoesPadrao.get('Tabela-Concentre')+'<tr class="slds-line-height_reset"><td class="slds-cell-wrap">'+quantidade +'</td><td class="slds-cell-wrap">'+discriminacao +'</td><td class="slds-cell-wrap">'+periodo +'</td><td class="slds-cell-wrap">'+valor +'</td><td class="slds-cell-wrap">'+origem +'</td><td class="slds-cell-wrap">'+agencia+'</td><td class="slds-cell-wrap">R$ '+total+'</td><td class="slds-cell-wrap">'+tiposNatureza.get(natureza)+'</td></tr>');
    }
    public static void formatarL040299(String retorno, Relatorio result) { 

        String mensagemNaoCalculo = retorno.substring(0,retorno.length()).trim();
        
        List<String> tabelas = new List<String>(); 
        //tabelas.add('Tabela-dividasVencidas');
        //tabelas.add('Tabela-Protestos');
        //tabelas.add('Tabela-falenciaErecuperacao');
        for(String tabela:tabelas){
            if(!result.informacoesAnotacoesNegativas.containsKey(tabela)){
                result.informacoesAnotacoesNegativas.put(tabela,'<tr class="slds-line-height_reset"><td class="slds-cell-wrap" >' + mensagemNaoCalculo + '</td></tr>');
            }
        }
    }
    public static void formatarL040701(String retorno, Relatorio result){

        Map<String,String> dividaVencida = new Map<String,String>();
        dividaVencida.put('data',retorno.substring(9,17));     
        dividaVencida.put('modalidade', retorno.substring(17,32).trim());
        dividaVencida.put('valor', retorno.substring(32,35).trim() + Decimal.valueOf(removerZeros(retorno.substring(35,48))).format()); 
        dividaVencida.put('titulo', retorno.substring(48,63).trim());
        dividaVencida.put('instituicaoCobradora', retorno.substring(63,78));
        dividaVencida.put('localDivida', retorno.substring(78,retorno.length()));

        /*
        String outPutMap = '';
        for(String chave:dividaVencida.keyset()){
            outPutMap += '\n' + chave + ':' + dividaVencida.get(chave);
        }
        System.debug('\n\n<QUADRO L040701>\nretorno:'+retorno + outPutMap + '\n</QUADRO L070401>\n\n');
        */
        /*
        if(result.informacoesAnotacoesNegativas.containsKey(('Tabela-dividasVencidas'))){
            if(result.informacoesAnotacoesNegativas.get('Tabela-dividasVencidas').contains('<tr class="slds-line-height_reset"><td class="slds-cell-wrap" >=== NADA CONSTA PARA O CNPJ CONSULTADO ===</td></tr>')){
                result.informacoesAnotacoesNegativas.put('Tabela-dividasVencidas','');
            }   
        }
        
        if(result.informacoesAnotacoesNegativas.containsKey(('Tabela-dividasVencidas'))){
            if(result.informacoesAnotacoesNegativas.get('Tabela-dividasVencidas').contains('<tr class="slds-line-height_reset"><td class="slds-cell-wrap" >=== NADA CONSTA PARA O CPF CONSULTADO ===</td></tr>')){
                result.informacoesAnotacoesNegativas.put('Tabela-dividasVencidas','');
            }   
        }
        */
        
        if(!result.informacoesAnotacoesNegativas.containsKey('Tabela-dividasVencidas')){
            result.informacoesAnotacoesNegativas.put('Tabela-dividasVencidas','<thead><tr class="slds-line-height_reset"><th>Data</th><th>Modalidade</th><th>Valor</th><th>Título</th><th>Instituição Cobradora</th><th>Local</th></tr></thead>');
        }

        String nada = 'nada ainda';
        String data = formatarDataAAAAMMDD(dividaVencida.get('data'));
        String modalidade = dividaVencida.get('modalidade');
        String valor = dividaVencida.get('valor');
        String titulo = dividaVencida.get('titulo');
        String instituicaoCobradora = dividaVencida.get('instituicaoCobradora');
        String local = dividaVencida.get('localDivida');

        result.informacoesAnotacoesNegativas.put('Tabela-dividasVencidas',result.informacoesAnotacoesNegativas.get('Tabela-dividasVencidas')+'<tr class"slds-line-height_reset"><td class="slds-cell-wrap" >'+data +'</td><td class="slds-cell-wrap" >'+modalidade +'</td><td class="slds-cell-wrap" >'+valor +'</td><td class="slds-cell-wrap" >'+titulo +'</td><td class="slds-cell-wrap" >'+instituicaoCobradora +'</td><td class="slds-cell-wrap" >'+local+'</td></tr>');
    }    
    public static void formatarL040201(String retorno, Relatorio result) {  // L040201 - Informações do Concentre – Grafias 

        if(!result.dadosCadEmp.containsKey('Tabela-Grafias')){
            result.dadosCadEmp.put('Tabela-Grafias','<tr class="slds-line-height_reset"><td class="slds-cell-wrap" ><b>mais de $QuantidadeGrafias variações encontradas</b></td></tr>');
            result.dadosCadEmp.put('$QuantidadeGrafias','0');
        }

        String grafia = retorno.substring(0,retorno.length()).trim();

        if(grafia == 'OUTRAS'){
            result.dadosCadEmp.put('Tabela-Grafias',result.dadosCadEmp.get('Tabela-Grafias').replace('$QuantidadeGrafias',result.dadosCadEmp.get('$QuantidadeGrafias')));
        }
        else{
            Integer qtd = Integer.valueOf(result.dadosCadEmp.get('$QuantidadeGrafias'))+1;
            result.dadosCadEmp.put('$QuantidadeGrafias',String.valueOf(qtd));
            result.dadosCadEmp.put('Tabela-Grafias',result.dadosCadEmp.get('Tabela-Grafias') + '<tr class="slds-line-height_reset"><td class="slds-cell-wrap" >' + grafia + '</td></tr>');
        }
    }
    public static void formatarL040901(String retorno, Relatorio result) { // L040901 - Informações do Recheque - Cheque sem Fundo-Achei CCF  //FALTA EXEMPLO
        
        String quantidadeOcorrencias =  retorno.substring(0,9).trim(); 
        String dataOcorrencia = formatarDataAAAAMMDD(retorno.substring(9,17).trim());
        String numeroCheque = retorno.substring(17,23).trim();
        String quantidadeBanco = removerZeros(retorno.substring(23,28).trim());
        String banco = retorno.substring(28,44).trim();
        String agencia = retorno.substring(44,48).trim();
        String cidade = retorno.substring(48,78).trim();
        String unidadeFederacao = retorno.substring(78,80).trim();
        String codigoNatureza = retorno.substring(80,83).trim(); 

        if(!result.informacoesAnotacoesNegativas.containsKey('Tabela-cheques')){
            String tabela = ''+
            '<thead>'+
                '<tr class="slds-line-height_reset">'+
                    '<th>Data</th>'+
                    '<th>Núm. do Cheque</th>'+
                    '<th>Alíena</th>'+
                    '<th>Quantidade</th>'+
                    '<th>Banco</th>'+
                    '<th>Agência</th>'+
                    '<th>Cidade/UF</th>'+
                '</tr>'+
            '</thead>';
            result.informacoesAnotacoesNegativas.put('Tabela-cheques',tabela);
        }

        String tabela = result.informacoesAnotacoesNegativas.get('Tabela-cheques');
        tabela += ''+
        '<tr class"slds-line-height_reset">'+
            '<td class="slds-cell-wrap" >'+dataOcorrencia+'</td>'+
            '<td class="slds-cell-wrap" >'+numeroCheque+'</td>'+
            '<td class="slds-cell-wrap" >'+codigoNatureza+'</td>'+
            '<td class="slds-cell-wrap" >'+quantidadeBanco+'</td>'+
            '<td class="slds-cell-wrap" >'+banco+'</td>'+
            '<td class="slds-cell-wrap" >'+agencia+'</td>'+
            '<td class="slds-cell-wrap" >'+cidade+'/'+unidadeFederacao+'</td>'+
        '</tr>';
        result.informacoesAnotacoesNegativas.put('Tabela-cheques',tabela);
    } 



    // Bloco Informações Consultas e Alertas 
    public static void formatarL030101(String retorno, Relatorio result) { //  Consultas à Serasa (Grafico ano) 
        if(!result.informacoesPadrao.containsKey('Data consulta e alertas ao ano')){
            result.informacoesPadrao.put('Data consulta e alertas ao ano',retorno.substring(4,7).trim() + '/'+ retorno.substring(0,2).trim());
            result.informacoesPadrao.put('Número consultas e alertas ao ano',String.valueOf(Integer.valueOf(retorno.substring(7, 10)) + Integer.valueOf(retorno.substring(10,13))));
        }else{
            String data = result.informacoesPadrao.get('Data consulta e alertas ao ano') +';'+ retorno.substring(4,7).trim() + '/'+ retorno.substring(0,2).trim();
            String numero = result.informacoesPadrao.get('Número consultas e alertas ao ano') +';'+String.valueOf(Integer.valueOf(retorno.substring(7, 10)) + Integer.valueOf(retorno.substring(10,13))) ;
            result.informacoesPadrao.put('Data consulta e alertas ao ano', data);
            result.informacoesPadrao.put('Número consultas e alertas ao ano', numero);
        }
    }
    public static void formatarL030102(String retorno, Relatorio result) {  // L030102 - Últimas Consultas 5 consultas // não recebo cnpj completo  //CONFERIR

        Map<String,String> ultimasConsultas = new Map<String,String>();
        ultimasConsultas.put('data',retorno.substring(0,8).trim());
        ultimasConsultas.put('nome',retorno.substring(8,43).trim());
        ultimasConsultas.put('quantidadeConsultas',retorno.substring(43,47).trim());
        ultimasConsultas.put('cnpj',retorno.substring(47,56).trim());
        ultimasConsultas.put('areasReservadas',retorno.substring(56,retorno.length()).trim());
        /*
        String outPutMap = '';
        for(String chave:ultimasConsultas.keyset()){
            outPutMap += '\n' + chave + ':' + ultimasConsultas.get(chave);
        }
        System.debug('\n\n<QUADRO L030102>\nretorno:'+retorno + outPutMap + '\n</QUADRO L030102>\n\n');
        */
        if(!result.InformacoesSobreConsultas.containsKey('Tabela-ultimasConsultas')){
            result.InformacoesSobreConsultas.put('Tabela-ultimasConsultas','<thead><tr class="slds-line-height_reset"><th>Data da Consulta</th>	<th>CNPJ do Consultante</th><th>Razão Social do Consultante</th><th>Qtd	Detalhe</th></tr></thead>');
        }

        String cnpj = ''+
        ultimasConsultas.get('cnpj').substring(0,3) + 
        '.' + 
        ultimasConsultas.get('cnpj').substring(3,6) +
        '.'+ 
        ultimasConsultas.get('cnpj').substring(6,9) + 
        '/0001-' + 
        calcularUltimosDigitosCNPJ(ultimasConsultas.get('cnpj') + '0001');

        String tabela = result.InformacoesSobreConsultas.get('Tabela-ultimasConsultas');
        tabela += ''+
        '<tr class"slds-line-height_reset">'+
            '<td class="slds-cell-wrap" >'+formatarDataAAAAMMDD(retorno.substring(0 , 8))+'</td>'+
            '<td class="slds-cell-wrap" >'+ cnpj +'</td>'+
            '<td class="slds-cell-wrap" >'+retorno.substring(8 ,43).trim()+'</td>'+
            '<td class="slds-cell-wrap" >'+Integer.valueOf(retorno.substring(43,47).trim())+'</td>'+
        '</tr>';
        result.InformacoesSobreConsultas.put('Tabela-ultimasConsultas',tabela);  
    }
    public static void formatarL030103(String retorno, Relatorio result) { // L030103 - Frase de Alerta
        
        Map<String,String> alertaConsultas = new Map<String,String>();
        alertaConsultas.put('Frase de alerta', retorno.substring(0,124).trim());  
        alertaConsultas.put('Data frase de alerta', retorno.substring(124,132).trim());  
        /*
        String outPutMap = '';
        for(String chave:alertaConsultas.keyset()){
            outPutMap += '\n' + chave + ':' + alertaConsultas.get(chave);
        }
        System.debug('\n\n<QUADRO L030103>\nretorno:'+retorno + outPutMap + '\n</QUADRO L030103>\n\n');
        */

        if(!result.informacoesPadrao.containsKey('Tabela-AlertaEmNegocios')){
            result.informacoesPadrao.put('Tabela-AlertaEmNegocios','<thead><tr class="slds-line-height_reset"><th>Data</th><th>Alerta</th></tr></thead>');
        }
        String tabela = result.informacoesPadrao.get('Tabela-AlertaEmNegocios');
        String alerta = alertaConsultas.get('Frase de alerta');
        String data = formatarDataAAAAMMDD(alertaConsultas.get('Data frase de alerta'));
        if(tabela.contains(data)){data = '';}
        tabela += '<tr class="slds-line-height_reset"><td class="slds-cell-wrap">'+ data + '</td><td class="slds-cell-wrap">'+ alerta + '</td></tr>';
        result.informacoesPadrao.put('Tabela-AlertaEmNegocios',tabela);   
    }



    //serasa score
    public static void formatarL070106(String retorno, Relatorio result) { // L070106 - Serasa Score com positivo – Empresas – PRINAD  
        Map<String,String> informacoesRiskscorePrinad = new Map<String,String>();
        informacoesRiskscorePrinad.put('data',retorno.substring(0,8).trim());
        informacoesRiskscorePrinad.put('hora',retorno.substring(8, 16).trim());
        informacoesRiskscorePrinad.put('probabilidadeDeInadimplencia',retorno.substring(16,retorno.length()).trim());
        /*
        String outPutMap = '';
        for(String chave:informacoesRiskscorePrinad.keyset()){
            outPutMap += '\n' + chave + ':' + informacoesRiskscorePrinad.get(chave);
        }
        System.debug('\n\n<QUADRO L070106>\nretorno:'+retorno + outPutMap + '\n</QUADRO L070106>\n\n');
        */
        if(!result.informacoesPadrao.containsKey('Tabela-SerasaScore')){
            result.informacoesPadrao.put('Tabela-SerasaScore','');
        }
        
        String probabilidadeInadimplencia = informacoesRiskscorePrinad.get('probabilidadeDeInadimplencia');
        
        if(probabilidadeInadimplencia.contains('SITUACAO DO CNPJ: INAPTO')){
            result.informacoesPadrao.put('Tabela-SerasaScore','<tr class="slds-line-height_reset"><td class="slds-cell-wrap" >'+ probabilidadeInadimplencia + '</td></tr>');
        }else{
            result.informacoesPadrao.put('Tabela-SerasaScore',result.informacoesPadrao.get('Tabela-SerasaScore') + '<tr class="slds-line-height_reset"><td class="slds-cell-wrap" ><b>Probabilidade de Inadimplência:</b>' + probabilidadeInadimplencia + '</td></tr>');
        }
        

        //result.informacoesPadrao.put('Probabilidade de inadimplência', ); 
    }
    public static void formatarL070109(String retorno, Relatorio result) { // L070109 - Serasa Score com positivo – Empresas – Cálculo 
        
        Map<String,String> scoreSerasa = new Map<String,String>();
        scoreSerasa.put('data',retorno.substring(0,8).trim());
        scoreSerasa.put('hora',retorno.substring(8,16).trim());
        scoreSerasa.put('fatorRisk',retorno.substring(16,20).trim());
        scoreSerasa.put('fatorPrinad',retorno.substring(20,25).trim());
        scoreSerasa.put('reservado',retorno.substring(0,8).trim());
        /*
        String outPutMap = '';
        for(String chave:scoreSerasa.keyset()){
            outPutMap += '\n' + chave + ':' + scoreSerasa.get(chave);
        }
        System.debug('\n\n<QUADRO L070109>\nretorno:'+retorno + outPutMap + '\n</QUADRO L070109>\n\n');
        */
        if(!result.informacoesPadrao.containsKey('Tabela-SerasaScore')){
            result.informacoesPadrao.put('Tabela-SerasaScore','');
        }
        
        String score = removerZeros(scoreSerasa.get('fatorRisk'));
        result.informacoesPadrao.put('Tabela-SerasaScore',result.informacoesPadrao.get('Tabela-SerasaScore') + '<tr class="slds-line-height_reset"><td class="slds-cell-wrap" ><b>Score: </b>' + score + '</td></tr>');

        Map<String,String> interpretacaoScore = interpretarScore(score);
        result.informacoesPadrao.put('Tabela-SerasaScore',result.informacoesPadrao.get('Tabela-SerasaScore') + '<tr class="slds-line-height_reset"><td class="slds-cell-wrap" ><b>Classificação: </b>' + interpretacaoScore.get('classificacao') + '</td></tr>');
        result.informacoesPadrao.put('Tabela-SerasaScore',result.informacoesPadrao.get('Tabela-SerasaScore') + '<tr class="slds-line-height_reset"><td class="slds-cell-wrap" ><b>Prática do mercado: </b>' + interpretacaoScore.get('praticaMercado') + '</td></tr>');
        result.informacoesPadrao.put('Tabela-SerasaScore',result.informacoesPadrao.get('Tabela-SerasaScore') + '<tr class="slds-line-height_reset"><td class="slds-cell-wrap" title="' + interpretacaoScore.get('interpretacao') + '"><b>Interpretação: </b>' + interpretacaoScore.get('interpretacao') + '</td></tr>');
    }
    public static void formatarL070199(String retorno, Relatorio result) { // L070199 - Informações de Riskscoring/Autorizador 

        Map<string,String> mensagemRiskscore = new Map<String,String>();
        mensagemRiskscore.put('data',retorno.substring(0,8).trim());
        mensagemRiskscore.put('hora',retorno.substring(8,16).trim());
        mensagemRiskscore.put('mensagem',retorno.substring(16,94).trim());
        mensagemRiskscore.put('areaReservada',retorno.substring(94,96).trim());
        mensagemRiskscore.put('codigoMensagem',retorno.substring(96,101).trim());
        mensagemRiskscore.put('areaReservada2',retorno.substring(101,105).trim());
        /*
        String outPutMap = '';
        for(String chave:mensagemRiskscore.keyset()){
            outPutMap += '\n' + chave + ':' + mensagemRiskscore.get(chave);
        }
        System.debug('\n\n<QUADRO L070199>\nretorno:'+retorno + outPutMap + '\n</QUADRO L070199>\n\n');
        */
        if(!result.informacoesPadrao.containsKey('Tabela-SerasaScore')){
            result.informacoesPadrao.put('Tabela-SerasaScore','');
        }

        String mensagem = mensagemRiskscore.get('mensagem');
        result.informacoesPadrao.put('Tabela-SerasaScore',result.informacoesPadrao.get('Tabela-SerasaScore') + '<tr class="slds-line-height_reset"><td class="slds-cell-wrap" >' + mensagem + '</td></tr>');
    }



    //pontualidade de pagamento PJ
    public static void formatarL130101(String retorno, Relatorio result) { // L130101 - Pontualidade de Pagamentos PJ dados
        //old
        result.pontualidadePagamentoPJ.put('Pontualidade de pagamento', retorno.substring(16,20).replace('0', '') + '%');
        if(!result.pontualidadePagamentoPJ.containsKey('Mensagem')){
            result.pontualidadePagamentoPJ.put('Mensagem', retorno.substring(23,103));
        }else{
            String mensagem =  retorno.substring(23,103) + result.PontualidadePagamentoPJ.get('Mensagem');
            result.pontualidadePagamentoPJ.put('Mensagem', mensagem);
        }


        //new
        Map<String,String> pontualidade = new Map<String,String>();
        pontualidade.put('data',retorno.substring(0,8).trim());
        pontualidade.put('hora',retorno.substring(8,16).trim());
        pontualidade.put('codigoMensagem',retorno.substring(16,20).trim());
        pontualidade.put('mensagemCodigo',retorno.substring(20,23).trim());
        pontualidade.put('mensagem',retorno.substring(23,103).trim());
        /*
        String outPutMap = '';
        for(String chave:pontualidade.keyset()){
            outPutMap += '\n' + chave + ':' + pontualidade.get(chave);
        }
        System.debug('\n\n<QUADRO L130101>\nretorno:'+retorno + outPutMap + '\n</QUADRO L130101>\n\n');
        */
        if(!result.informacoesPadrao.containsKey('Tabela-PontualidadePagamentoPJ')){
            result.informacoesPadrao.put('Tabela-PontualidadePagamentoPJ','');
        }

        String mensagem =  pontualidade.get('mensagem');
        String numeroPontualidade = removerZeros(pontualidade.get('codigoMensagem'));
        String interpretacao = '';
        Integer pontuacaoParaCalculo = Integer.valueOf(numeroPontualidade);
        if( pontuacaoParaCalculo >= 76 ){interpretacao='A empresa está classificada com pontualidade de pagamento <b>Alta</b>.Pagou '+ numeroPontualidade +'% dos valores de seus compromissos financeiros e comerciais até a data de vencimento nos últimos 12 meses.';}
        else if( pontuacaoParaCalculo >= 51 ){interpretacao='A empresa está classificada com pontualidade de pagamento <b>Média</b>.Pagou '+ numeroPontualidade +'% dos valores de seus compromissos financeiros e comerciais até a data de vencimento nos últimos 12 meses.';}
        else if( pontuacaoParaCalculo >= 26 ){interpretacao='A empresa está classificada com pontualidade de pagamento <b>Baixa</b>.Pagou '+ numeroPontualidade +'% dos valores de seus compromissos financeiros e comerciais até a data de vencimento nos últimos 12 meses.';}
        else{interpretacao='A empresa está classificada com pontualidade de pagamento <b>Mínima</b>.Pagou '+ numeroPontualidade +'% dos valores de seus compromissos financeiros e comerciais até a data de vencimento nos últimos 12 meses.';}

        String tabela = result.informacoesPadrao.get('Tabela-PontualidadePagamentoPJ');
        tabela += ''+
        '<tr class="slds-line-height_reset">'+
            '<tr class="slds-line-height_reset">'+
                '<td class="slds-cell-wrap" ><b>Pontualidade: </b>' + numeroPontualidade + '</td>'+
            '</tr>'+
            '<tr class="slds-line-height_reset">'+
                '<td class="slds-cell-wrap" ><b>Interpretação: </b>' + interpretacao + '</td>'+
            '</tr>'+
            '<tr class="slds-line-height_reset">'+
                '<td class="slds-cell-wrap" ><b>Mensagem: </b>' + mensagem + '</td>'+
            '</tr>'+
        '</tr>';
        result.informacoesPadrao.put('Tabela-PontualidadePagamentoPJ',tabela);
    }
    public static void formatarL130199(String retorno, Relatorio result) { // L130199 - Mensagem Pontualidade de pagamentos PJ
        /*
        if(result.pontualidadePagamentoPJ.containsKey('Mensagem')){
            String mensagem = retorno.substring(16,103).trim() + result.PontualidadePagamentoPJ.get('Mensagem');
            result.pontualidadePagamentoPJ.put('Mensagem', mensagem);
        }else{
            result.pontualidadePagamentoPJ.put('Mensagem',retorno.substring(16,103).trim());
        }
        */
        Map<String,String> mensagemPagamentoPJ = new Map<String,String>();
        mensagemPagamentoPJ.put('data',retorno.substring(0,8).trim());
        mensagemPagamentoPJ.put('hora',retorno.substring(8,16).trim());
        mensagemPagamentoPJ.put('codigoMensagem',retorno.substring(16,20).trim());
        mensagemPagamentoPJ.put('mensagemCodigo',retorno.substring(20,23).trim());
        mensagemPagamentoPJ.put('mensagem',retorno.substring(23,retorno.length()).trim());
        /*
        String outPutMap = '';
        for(String chave:mensagemPagamentoPJ.keyset()){
            outPutMap += '\n' + chave + ':' + mensagemPagamentoPJ.get(chave);
        }
        System.debug('\n\n<QUADRO L130199>\nretorno:'+retorno + outPutMap + '\n</QUADRO L130199>\n\n');
        */
        if(!result.informacoesPadrao.containsKey('Tabela-PontualidadePagamentoPJ')){
            result.informacoesPadrao.put('Tabela-PontualidadePagamentoPJ','');
        }

        String mensagem =  mensagemPagamentoPJ.get('mensagem');
        result.informacoesPadrao.put('Tabela-PontualidadePagamentoPJ',result.informacoesPadrao.get('Tabela-PontualidadePagamentoPJ') + '<tr class="slds-line-height_reset"><td class="slds-cell-wrap" >' + mensagem + '</td></tr>');
    }



    //Gasto Estimado Positivo
    public static void formatarL100101(String retorno, Relatorio result) { // L100101 - Gasto Estimado – Valor
        //old
        Decimal centavos =  Decimal.valueOf(retorno.substring(29, 31).trim())/100;
        String resto;
        if(centavos == 0){
            resto='00';
        }else{
            resto = centavos+'';
        }
        result.gastoEstimadoPJPositivo.put('Gasto Estimado Valor', 'R$' + (Decimal.valueOf(retorno.substring(16, 29).trim()).format()) +';'+resto); 
        if(!result.informacoesPadrao.containsKey('Tabela-GastoEstimadoPJComPositivo')){
            result.informacoesPadrao.put('Tabela-GastoEstimadoPJComPositivo','');
        }

        //new
        String valorGasto = Decimal.valueOf(retorno.substring(16, 29).trim()).format();
        //System.debug('\n\n<QUADRO L100101>\nretorno:'+retorno + '\nvalor:'+ valorGasto + '\n</QUADRO L100101>\n\n');

        if(!result.informacoesPadrao.containsKey('Tabela-GastoEstimadoPJComPositivo')){
            result.informacoesPadrao.put('Tabela-GastoEstimadoPJComPositivo','');
        }

        String tabela = result.informacoesPadrao.get('Tabela-GastoEstimadoPJComPositivo');
        tabela += '<tr class="slds-line-height_reset"><td class="slds-cell-wrap" ><b>Valor: </b>R$ ' + valorGasto + ' ao ano</td></tr>';
        result.informacoesPadrao.put('Tabela-GastoEstimadoPJComPositivo',tabela);
    }
    public static void formatarL100102(String retorno, Relatorio result) { // L100102 - Gasto Estimado - Mensagem default 
        //result.gastoEstimadoPJPositivo.put('Mensagem', retorno.substring(16, 116).trim());
        //new
        String mensagem = retorno.substring(16, retorno.length()).trim();
        //System.debug('\n\n<QUADRO L100102>\nretorno:'+retorno + '\nmensagem:'+ mensagem + '\n</QUADRO L100102>\n\n');

        if(!result.informacoesPadrao.containsKey('Tabela-GastoEstimadoPJComPositivo')){
            result.informacoesPadrao.put('Tabela-GastoEstimadoPJComPositivo','');
        }

        result.informacoesPadrao.put('Tabela-GastoEstimadoPJComPositivo',result.informacoesPadrao.get('Tabela-GastoEstimadoPJComPositivo') + '<tr class="slds-line-height_reset"><td class="slds-cell-wrap" >' + mensagem + '</td></tr>');
    }
    public static void formatarL100199(String retorno, Relatorio result) { // L100199 - Gasto Estimado - Mensagem de não cálculo 
        //result.gastoEstimadoPJPositivo.put('Mensagem de não calculo', retorno.substring(16, 116).trim());

        if(!result.informacoesPadrao.containsKey('Tabela-GastoEstimadoPJComPositivo')){
            result.informacoesPadrao.put('Tabela-GastoEstimadoPJComPositivo','');
        }

        String mensagem = retorno.substring(16, 116).trim();
        result.informacoesPadrao.put('Tabela-GastoEstimadoPJComPositivo',result.informacoesPadrao.get('Tabela-GastoEstimadoPJComPositivo') + '<tr class="slds-line-height_reset"><td class="slds-cell-wrap" >' + mensagem + '</td></tr>');
    }



    //faturamento estimado com positivo
    public static void formatarL300201(String retorno, Relatorio result){

        //new
        Map<String,String> identificacao = new Map<string,String>();
        identificacao.put('Data da Atualização do Bloco', formatarDataAAAAMMDD(retorno.substring(1,9)));
        identificacao.put('CNPJ da Empresa', retorno.substring(9, 17));
        identificacao.put('Filial da Empresa', retorno.substring(17, 21));
        identificacao.put('Dígito da Empresa', retorno.substring(21, 23));
        identificacao.put('Razão Social da Empresa', retorno.substring(23, 93));
        identificacao.put('Nome do Usuário de Acesso Usado Como Confidencial Para.', retorno.substring(93, 113));
        identificacao.put('Data da Consulta', retorno.substring(113, 121));
        identificacao.put('Hora da Consulta', retorno.substring(121, 127));
        /*
        String outPutMap = '';
        for(String chave:identificacao.keyset()){
            outPutMap += '\n' + chave + ':' + identificacao.get(chave);
        }
        System.debug('\n\n<QUADRO L320201>\nretorno:'+retorno + outPutMap + '\n</QUADRO L320201>\n\n');
        */
    }
    public static void formatarL300202(String retorno, Relatorio result) {  // L320101 - Compromisso por linha de crédito 

        //new
        Map<String,String> valorFaturamento = new Map<string,String>();
        valorFaturamento.put('Valor do Faturamento Estimado com Positivo ',retorno.substring(9,19));
        valorFaturamento.put('Pontuação',retorno.substring(19,23));
        valorFaturamento.put('Faixa da pontuação DE',retorno.substring(23,27));
        valorFaturamento.put('Faixa da pontuação ATE',retorno.substring(27,31));
        /*
        String outPutMap = '';
        for(String chave:valorFaturamento.keyset()){
            outPutMap += '\n' + chave + ':' + valorFaturamento.get(chave);
        }
        System.debug('\n\n<QUADRO L320202>\nretorno:'+retorno + outPutMap + '\n</QUADRO L320202>\n\n');
        */
        if(!result.informacoesPadrao.containsKey('Tabela-FaturamentoEstimadoComPositivo')){
            result.informacoesPadrao.put('Tabela-FaturamentoEstimadoComPositivo','');
        }

        String valor =  removerZeros(valorFaturamento.get('Valor do Faturamento Estimado com Positivo '));
        String valorFormatado='';
        if(valor != '0'){
            valor += '000';
            Integer contador = 0;
            for(Integer i=valor.length();i>0;i--){
                contador++;
                if(contador==4){
                    valorFormatado = '.' + valorFormatado;
                    valorFormatado = valor.substring(i-1, i)+valorFormatado;
                    contador = 1;
                }else{
                    valorFormatado = valor.substring(i-1, i)+valorFormatado;
                }
                
            }
            if(retorno.substring(9,10)=='-'){
                valor = '-' + valor;
            }
        }else{
            valorFormatado = valor;
        } 
        
        String pontuacao =  removerZeros(valorFaturamento.get('Pontuação'));
        String faixaDe =  removerZeros(valorFaturamento.get('Faixa da pontuação DE'));
        String faixaAte =  removerZeros(valorFaturamento.get('Faixa da pontuação ATE'));

        String tabela = result.informacoesPadrao.get('Tabela-FaturamentoEstimadoComPositivo');
        
        tabela += ''+
        '<tr class="slds-line-height_reset">'+
            '<td class="slds-cell-wrap" ><b>Valor: </b>' + valorFormatado + ' ao ano</td>'+
        '</tr>'+
        '<tr class="slds-line-height_reset">'+
            '<td class="slds-cell-wrap" ><b>Pontuação: </b>' + pontuacao + '</td>'+
        '</tr>'+
        '<tr class="slds-line-height_reset">'+
            '<td class="slds-cell-wrap" ><b>Interpretação de '+ faixaDe +' a '+ faixaAte +': </b></td>'+
        '</tr>';

        result.informacoesPadrao.put('Tabela-FaturamentoEstimadoComPositivo',tabela);
    }
    public static void formatarL300203(String retorno, Relatorio result) {  // L320101 - Compromisso por linha de crédito  
        result.faturamentoEstimadoPositivo.put('Data Última Atualização',formatarDataAAAAMMDD(retorno.substring(1,9)));
        result.faturamentoEstimadoPositivo.put('Motivo do não cálculo',retorno.substring(9,109));
    }
    public static void formatarL300299(String retorno, Relatorio result){
        if(!result.informacoesPadrao.containsKey('Tabela-FaturamentoEstimadoComPositivo')){
            result.informacoesPadrao.put('Tabela-FaturamentoEstimadoComPositivo','');
        }
        String dataAtualizacao = formatarDataAAAAMMDD(retorno.substring(1,9).trim());
        String mensagem = retorno.substring(9,retorno.length()).trim();
        result.informacoesPadrao.put('Tabela-FaturamentoEstimadoComPositivo',result.informacoesPadrao.get('Tabela-FaturamentoEstimadoComPositivo') + '<tr class="slds-line-height_reset"><td class="slds-cell-wrap" >' + mensagem + '</td></tr>');
    }



    //[ Bloco Histórico de pagamento financeiro avançado ]
    public static void initTabela_ComportamentoContratosAtivos(Relatorio result){
        if(!result.pagamentoFinanceiroAvancado.containsKey('Tabela-ComportamentoContratosAtivos')){
            String tabela = ''+
            '<tr class="slds-line-height_reset">'+
                '<td class="slds-cell-wrap" >'+
                    '<dl style="margin-left:50px;margin-right:50px;margin-bottom:10px;padding:10px;margin-top:10px;border:gray solid 1px">'+
                        '<dt><b>Contratos Ativos</b></dt>'+
                            '<dd style="margin-left:30px"><b>pagos: </b>$percentualPagos%</dd>'+
                            '<dd style="margin-left:30px"><b>a vencer: </b>$percentualVencer%</dd>'+
                            '<dd style="margin-left:30px"><b>abertos: </b>$percentualAbertas%</dd>'+
                        '<dt><b><br>Total de Contratos Ativos</b></dt>'+
                            '<dd style="margin-left:30px"><b>Total: </b>$totalContratosAtivos</dd>'+
                            '<dd style="margin-left:30px"><b>Faixa : </b>$faixaContratosAtivos</dd>'+
                    '</dl>'+
                    '<dl style="margin-left:50px;margin-right:50px;margin-bottom:10px;padding:10px;margin-top:10px;border:gray solid 1px">'+
                        '<dt><b>Pontualidade de Pagamentos</b></dt>'+
                            '<dd style="margin-left:30px"><b>Rotativo: </b>$percentualRotativo%</dd>'+
                            '<dd style="margin-left:30px"><b>Pontual: </b>$percentualPontual%</dd>'+
                            '<dd style="margin-left:30px"><b>Até 30 dias: </b>$percentualAte30%</dd>'+
                            '<dd style="margin-left:30px"><b>31 à 60 dias: </b>$percentualAte60%</dd>'+
                            '<dd style="margin-left:30px"><b>Acima 60 dias: </b>$percentualAcima60%</dd>'+
                        '<dt><b><br>Compromissos Pagos</b></dt>'+
                            '<dd style="margin-left:30px"><b>Total: </b>$totalCompromissosPagos</dd>'+
                            '<dd style="margin-left:30px"><b>Faixa : </b>$faixaCompromissosPagos</dd>'+
                    '</dl>'+
                    '<dl style="margin-left:50px;margin-right:50px;margin-bottom:10px;padding:10px;margin-top:10px;border:gray solid 1px">'+
                        '<dt><b>Vencimentos em Aberto</b></dt>'+
                            '<dd style="margin-left:30px"><b>Até 30 dias: </b>$abertosAte30%</dd>'+
                            '<dd style="margin-left:30px"><b>De 31 a 60 dias: </b>$abertosDe31a60%</dd>'+
                            '<dd style="margin-left:30px"><b>De 61 a 90 dias: </b>$abertosDe61a90%</dd>'+
                            '<dd style="margin-left:30px"><b>Acima de 90 dias: </b>$abertosAcimaDe90%</dd>'+
                        '<dt><b><br>Compromissos em Aberto</b></dt>'+
                            '<dd style="margin-left:30px"><b>Total: </b>$totalAbertos</dd>'+
                            '<dd style="margin-left:30px"><b>Faixa : </b>$faixaTotalAbertos</dd>'+
                    '</dl>'+
                '</td>'+
            '</tr>';
            result.pagamentoFinanceiroAvancado.put('Tabela-ComportamentoContratosAtivos',tabela);
        }
    }
    public static void formatarL320101(String retorno, Relatorio result) {  // L320101 - Compromisso por linha de crédito

        Map<String,String> Compromissos = new Map<String,String>();
        Compromissos.put('percentualLinhaCreditoFinanciamento',retorno.substring(0,3).trim());
        Compromissos.put('percentualLinhaCreditoEmprestimo',retorno.substring(3,6).trim());
        Compromissos.put('percentualLinhaCreditoRotativo',retorno.substring(6,9).trim());
        Compromissos.put('percentualLinhaCreditoOutros',retorno.substring(9,12).trim());
        Compromissos.put('codigoFaixaTotalCompromissos',retorno.substring(12,15).trim());
        Compromissos.put('valorTotalCompromissos',retorno.substring(15,36).trim());
        /*
        String outPutMap = '';
        for(String chave:Compromissos.keyset()){
            outPutMap += '\n' + chave + ':' + Compromissos.get(chave);
        }
        System.debug('\n\n<QUADRO L320101>\nretorno:'+retorno + outPutMap + '\n</QUADRO L320101>\n\n');
        */
        if(!result.pagamentoFinanceiroAvancado.containsKey('Tabela-Compromissos')){
            result.pagamentoFinanceiroAvancado.put('Tabela-Compromissos','');
        }

        String totalCompromissos = Compromissos.get('valorTotalCompromissos');
        string codigoTotalCompromissos = Compromissos.get('codigoFaixaTotalCompromissos');
        String percentulRotativo = Compromissos.get('percentualLinhaCreditoRotativo');
        String percentulEmprestimo = Compromissos.get('percentualLinhaCreditoEmprestimo');
        String percentulOutros = Compromissos.get('percentualLinhaCreditoOutros');
        String percentulFinanciamento = Compromissos.get('percentualLinhaCreditoFinanciamento');

        String tabela  = result.pagamentoFinanceiroAvancado.get('Tabela-Compromissos');
        tabela += ''+
        '<tr class="slds-line-height_reset">'+
            '<dl style="margin-left:50px;margin-right:50px;margin-bottom:10px;padding:10px;margin-top:10px;border:gray solid 1px">'+
                '<dt><b>Total Compromissos</b></dt>'+
                    '<dd style="margin-left:30px"><b>Total: </b>'+ totalCompromissos +'</dd>'+
                    '<dd style="margin-left:30px"><b>Faixa: </b>'+ codigoTotalCompromissos +'</dd>'+
            '</dl>'+
            '<dl style="margin-left:50px;margin-right:50px;margin-bottom:10px;padding:10px;margin-top:10px;border:gray solid 1px">'+
                '<dt><b>Percentuais</b></dt>'+
                    '<dd style="margin-left:30px"><b>Financiamento: </b>'+ percentulFinanciamento +'%</dd>'+
                    '<dd style="margin-left:30px"><b>Rotativo: </b>'+ percentulRotativo +'%</dd>'+
                    '<dd style="margin-left:30px"><b>Emprestimos: </b>'+ percentulEmprestimo +'</dd>'+
                    '<dd style="margin-left:30px"><b>Outros: </b>'+ percentulOutros +'</dd>'+
                    
            '</dl>'+
        '</tr>';
        result.pagamentoFinanceiroAvancado.put('Tabela-Compromissos',tabela);
    }
    public static void formatarL320102(String retorno, Relatorio result) {  // L320102 - Quantidade de compromissos e credores  
        
        Map<String,String> quantidadeCompromissos = new Map<string,String>();
        quantidadeCompromissos.put('codigoFaixaQuantidade',retorno.substring(0,3));
        quantidadeCompromissos.put('quantidadeCompromissos',retorno.substring(3,24));
        quantidadeCompromissos.put('quantidadeCredores',retorno.substring(24,34));
        /*
        String outPutMap = '';
        for(String chave:quantidadeCompromissos.keyset()){
            outPutMap += '\n' + chave + ':' + quantidadeCompromissos.get(chave);
        }
        System.debug('\n\n<QUADRO L320102>\nretorno:'+retorno + outPutMap + '\n</QUADRO L320102>\n\n');
        */
        if(!result.pagamentoFinanceiroAvancado.containsKey('Tabela-Compromissos')){
            result.pagamentoFinanceiroAvancado.put('Tabela-Compromissos','');
        }

        String codigoFaixa = quantidadeCompromissos.get('codigoFaixaQuantidade');
        String quantidade = quantidadeCompromissos.get('quantidadeCompromissos');
        String quantidadeCredores = quantidadeCompromissos.get('quantidadeCredores');

        String tabela  = result.pagamentoFinanceiroAvancado.get('Tabela-Compromissos');
        tabela += ''+
        '<tr class="slds-line-height_reset">'+
            '<dl style="margin-left:50px;margin-right:50px;margin-bottom:10px;padding:10px;margin-top:10px;border:gray solid 1px">'+
                '<dt><b>Quantidade de Compromissos</b></dt>'+
                    '<dd style="margin-left:30px"><b>Quantidade: </b>'+ quantidade +'</dd>'+
                    '<dd style="margin-left:30px"><b>Faixa: </b>'+ codigoFaixa +'</dd>'+
                '<dt><b>Quantidade de Credores</b></dt>'+
                    '<dd style="margin-left:30px"><b>Quantidade: </b>'+ quantidadeCredores +'</dd>'+
            '</dl>'+
        '</tr>';
        result.pagamentoFinanceiroAvancado.put('Tabela-Compromissos',tabela);
    }
    public static void formatarL320103(String retorno, Relatorio result) {// L320103 - Percentual das parcelas dos compromissos 

        Map<String,String> percentualParcelas = new Map<string,String>();
        percentualParcelas.put('parcelasPagas',retorno.substring(0,3));
        percentualParcelas.put('parcelasVencidas',retorno.substring(3,6));
        percentualParcelas.put('parcelasAbertas',retorno.substring(6,9));
        /*
        String outPutMap = '';
        for(String chave:percentualParcelas.keyset()){
            outPutMap += '\n' + chave + ':' + percentualParcelas.get(chave);
        }
        System.debug('\n\n<QUADRO L320103>\nretorno:'+retorno + outPutMap + '\n</QUADRO L320103>\n\n');
        */
        if(!result.pagamentoFinanceiroAvancado.containsKey('Tabela-Compromissos')){
            result.pagamentoFinanceiroAvancado.put('Tabela-Compromissos','');
        }

        String parcelasPagas = percentualParcelas.get('parcelasPagas');
        String parcelasVencidas = percentualParcelas.get('parcelasVencidas');
        String parcelasAbertas = percentualParcelas.get('parcelasAbertas');

        String tabela  = result.pagamentoFinanceiroAvancado.get('Tabela-Compromissos');
        tabela += ''+
        '<tr class="slds-line-height_reset">'+
            '<dl style="margin-left:50px;margin-right:50px;margin-bottom:10px;padding:10px;margin-top:10px;border:gray solid 1px">'+
                '<dt><b>Parcelas</b></dt>'+
                    '<dd style="margin-left:30px"><b>Pagas: </b>'+ parcelasPagas +'%</dd>'+
                    '<dd style="margin-left:30px"><b>À Vencer: </b>'+ parcelasVencidas +'%</dd>'+
                    '<dd style="margin-left:30px"><b>Em Aberto: </b>'+ parcelasAbertas +'%</dd>'+
            '</dl>'+
        '</tr>';
        result.pagamentoFinanceiroAvancado.put('Tabela-Compromissos',tabela);
    }
    public static void formatarL320104(String retorno, Relatorio result) {  // L320104 - Compromissos pagos – últimos 5 anos (valores em reais)   

        Map<String,String> compromissosPagos = new Map<String,String>();
        compromissosPagos.put('Código Faixa Total Pago', retorno.substring(0,3)); //
        compromissosPagos.put('Valor total compromissos Pagos', retorno.substring(3,24));//
        compromissosPagos.put('Código Faixa rotativo', retorno.substring(24,27)); //
        compromissosPagos.put('Valor Compromissos Pagos Rotativo', retorno.substring(27,48)); //
        compromissosPagos.put('Percentual Compromissos Rotativo', retorno.substring(48,67)); //
        compromissosPagos.put('Código Faixa Pontual', retorno.substring(67,70)); //
        compromissosPagos.put('Valor Compromissos Pagos Pontual', retorno.substring(70,89)); //
        compromissosPagos.put('Percentual Compromissos Pontual', retorno.substring(89,108)); //
        compromissosPagos.put('Codigo Faixa Até 30 dias', retorno.substring(110,113)); //
        compromissosPagos.put('Valor Compromissos Pagos Até 30 Dias', retorno.substring(113,132));     //
        compromissosPagos.put('Percentual Compromissos Até 30 Dias', retorno.substring(132,149));     //
        compromissosPagos.put('Codigo Faixa 31 A 60 dias', retorno.substring(149,152)); //
        compromissosPagos.put('Valor Compromissos Pagos 31 à 60 Dias', retorno.substring(152,173));   //  
        compromissosPagos.put('Percentual Compromissos 31 à 60 Dias', retorno.substring(173,190));   //  
        compromissosPagos.put('Codigo Faixa Acima de 60 Dias', retorno.substring(191,193));     
        compromissosPagos.put('Valor Compromissos Pagos Acima de 60 Dias', retorno.substring(193,214));             
        compromissosPagos.put('Percentual Compromissos Acima de 60 Dias', retorno.substring(214,229));  
        /*
        String outPutMap = '';
        for(String chave:compromissosPagos.keyset()){
            outPutMap += '\n' + chave + ':' + compromissosPagos.get(chave);
        }
        System.debug('\n\n<QUADRO L320104>\nretorno:'+retorno + outPutMap + '\n</QUADRO L320104>\n\n');
        */
        if(!result.pagamentoFinanceiroAvancado.containsKey('Tabela-ComportamentoDePagamento')){
            result.pagamentoFinanceiroAvancado.put('Tabela-ComportamentoDePagamento','');
        }

        String tabela  = result.pagamentoFinanceiroAvancado.get('Tabela-ComportamentoDePagamento');

        String totalPago = compromissosPagos.get('Valor total compromissos Pagos');
        String codigoFaixa = compromissosPagos.get('Código Faixa Total Pago');
        tabela += ''+
        '<tr class="slds-line-height_reset">'+
            '<dl style="margin-left:50px;margin-right:50px;margin-bottom:10px;padding:10px;margin-top:10px;border:gray solid 1px">'+
                '<dt><b>Total Pago</b></dt>'+
                    '<dd style="margin-left:30px"><b>Total: </b>'+ totalPago +'</dd>'+
                    '<dd style="margin-left:30px"><b>Faixa: </b>'+ codigoFaixa +'</dd>'+
            '</dl>'+
        '</tr>';

        String totalRotativo = compromissosPagos.get('Valor Compromissos Pagos Rotativo');
        String codigoFaixaRotativo = compromissosPagos.get('Código Faixa rotativo');
        tabela += ''+
        '<tr class="slds-line-height_reset">'+
            '<dl style="margin-left:50px;margin-right:50px;margin-bottom:10px;padding:10px;margin-top:10px;border:gray solid 1px">'+
                '<dt><b>Rotativo</b></dt>'+
                    '<dd style="margin-left:30px"><b>Total: </b>'+ totalRotativo +'</dd>'+
                    '<dd style="margin-left:30px"><b>Faixa: </b>'+ codigoFaixaRotativo +'</dd>'+
            '</dl>'+
        '</tr>';

        String valorPagosPontual = compromissosPagos.get('Valor Compromissos Pagos Pontual');
        String codigoFaixaPontual = compromissosPagos.get('Código Faixa Pontual');
        String percentualPontual = compromissosPagos.get('Percentual Compromissos Pontual');
        
        tabela += ''+
        '<tr class="slds-line-height_reset">'+
            '<dl style="margin-left:50px;margin-right:50px;margin-bottom:10px;padding:10px;margin-top:10px;border:gray solid 1px">'+
                '<dt><b>Pontual</b></dt>'+
                    '<dd style="margin-left:30px"><b>Total: </b>'+ valorPagosPontual +'</dd>'+
                    '<dd style="margin-left:30px"><b>Faixa: </b>'+ codigoFaixaPontual +'</dd>'+
                    '<dd style="margin-left:30px"><b>Percentual: </b>'+ percentualPontual +'</dd>'+
            '</dl>'+
        '</tr>';
 
        String valorAte30dias = compromissosPagos.get('Valor Compromissos Pagos Até 30 Dias');
        String codigoFaixaAte30dias = compromissosPagos.get('Codigo Faixa Até 30 dias');
        String percentualAte30dias = compromissosPagos.get('Percentual Compromissos Até 30 Dias');
        tabela += ''+
        '<tr class="slds-line-height_reset">'+
            '<dl style="margin-left:50px;margin-right:50px;margin-bottom:10px;padding:10px;margin-top:10px;border:gray solid 1px">'+
                '<dt><b>Até 30 dias</b></dt>'+
                    '<dd style="margin-left:30px"><b>Total: </b>'+ valorAte30dias +'</dd>'+
                    '<dd style="margin-left:30px"><b>Faixa: </b>'+ codigoFaixaAte30dias +'</dd>'+
                    '<dd style="margin-left:30px"><b>Percentual: </b>'+ percentualAte30dias +'</dd>'+
            '</dl>'+
        '</tr>';

        String valorAte60dias = compromissosPagos.get('Valor Compromissos Pagos 31 à 60 Dias');
        String codigoFaixaAte60dias = compromissosPagos.get('Codigo Faixa 31 A 60 dias');
        String percentualAte60dias = compromissosPagos.get('Percentual Compromissos 31 à 60 Dias');
        tabela += ''+
        '<tr class="slds-line-height_reset">'+
            '<dl style="margin-left:50px;margin-right:50px;margin-bottom:10px;padding:10px;margin-top:10px;border:gray solid 1px">'+
                '<dt><b>De 31 à 60 dias</b></dt>'+
                    '<dd style="margin-left:30px"><b>Total: </b>'+ valorAte60dias +'</dd>'+
                    '<dd style="margin-left:30px"><b>Faixa: </b>'+ codigoFaixaAte60dias +'</dd>'+
                    '<dd style="margin-left:30px"><b>Percentual: </b>'+ percentualAte60dias +'</dd>'+
            '</dl>'+
        '</tr>';

        String valoraAcima60dias = compromissosPagos.get('Valor Compromissos Pagos Acima de 60 Dias');
        String codigoFaixaAcima60dias = compromissosPagos.get('Codigo Faixa Acima de 60 Dias');
        String percentualAcima60dias = compromissosPagos.get('Percentual Compromissos Acima de 60 Dias');
        tabela += ''+
        '<tr class="slds-line-height_reset">'+
            '<dl style="margin-left:50px;margin-right:50px;margin-bottom:10px;padding:10px;margin-top:10px;border:gray solid 1px">'+
                '<dt><b>Acima de 60 dias/b></dt>'+
                    '<dd style="margin-left:30px"><b>Total: </b>'+ valoraAcima60dias +'</dd>'+
                    '<dd style="margin-left:30px"><b>Faixa: </b>'+ codigoFaixaAcima60dias +'</dd>'+
                    '<dd style="margin-left:30px"><b>Percentual: </b>'+ percentualAcima60dias +'</dd>'+
            '</dl>'+
        '</tr>';

        result.pagamentoFinanceiroAvancado.put('Tabela-ComportamentoDePagamento',tabela);
    }
    public static void formatarL320199(String retorno, Relatorio result) { // L320199 - Mensagens da feature   
        result.pagamentoFinanceiroAvancado.put('Mensagem feature', retorno.substring(0,100));
    }
    public static void formatarL320201(String retorno, Relatorio result) {  // L320201 -  Compromissos ativos por linha de crédito      

        Map<String,String> compromissosAtivos = new Map<String,String>();
        compromissosAtivos.put('Percent Contratos Ativos Financiamento',retorno.substring(0,3));
        compromissosAtivos.put('Percent Contratos Ativos Emprestimo',retorno.substring(3,6));  
        compromissosAtivos.put('Percent Contratos Ativos Rotativo',retorno.substring(6,9));  
        compromissosAtivos.put('Percent Contratos Ativos Outros',retorno.substring(9,12));  
        compromissosAtivos.put('Código Faixa COMPROMISSOS Ativos',retorno.substring(12,15));      
        compromissosAtivos.put('Valor Total Compromissos Ativos',retorno.substring(15,36));  
        /*
        String outPutMap = '';
        for(String chave:compromissosAtivos.keyset()){
            outPutMap += '\n' + chave + ':' + compromissosAtivos.get(chave);
        }
        System.debug('\n\n<QUADRO L320201>\nretorno:'+retorno + outPutMap + '\n</QUADRO L320201>\n\n');
        */
        if(!result.pagamentoFinanceiroAvancado.containsKey('Tabela-ContratosAtivos')){
            result.pagamentoFinanceiroAvancado.put('Tabela-ContratosAtivos','');
        }  

        String tabela = result.pagamentoFinanceiroAvancado.get('Tabela-ContratosAtivos');   

        String percentualFinanciamento = compromissosAtivos.get('Percent Contratos Ativos Financiamento');
        String percentualEmprestimo = compromissosAtivos.get('Percent Contratos Ativos Emprestimo');
        String percentualRotativo = compromissosAtivos.get('Percent Contratos Ativos Rotativo');
        String percentualOutros = compromissosAtivos.get('Percent Contratos Ativos Outros');
        String codigoFaixaCompromissos = compromissosAtivos.get('Código Faixa COMPROMISSOS Ativos');
        String valorTotalCompromissos = compromissosAtivos.get('Valor Total Compromissos Ativos');

        tabela += ''+
        '<tr class="slds-line-height_reset">'+
            '<dl style="margin-left:50px;margin-right:50px;margin-bottom:10px;padding:10px;margin-top:10px;border:gray solid 1px">'+
                '<dt><b>Percentuais</b></dt>'+
                    '<dd style="margin-left:30px"><b>Financiamento: </b>'+ percentualFinanciamento +'%</dd>'+
                    '<dd style="margin-left:30px"><b>Emprestimos: </b>'+ percentualEmprestimo +'%</dd>'+
                    '<dd style="margin-left:30px"><b>Rotativo: </b>'+ percentualRotativo +'%</dd>'+
                    '<dd style="margin-left:30px"><b>Outros: </b>'+ percentualOutros +'%</dd>'+
            '</dl>'+
            '<dl style="margin-left:50px;margin-right:50px;margin-bottom:10px;padding:10px;margin-top:10px;border:gray solid 1px">'+
                '<dt><b>Total de Contratos Ativos</b></dt>'+
                    '<dd style="margin-left:30px"><b>Total: </b>'+ valorTotalCompromissos +'%</dd>'+
                    '<dd style="margin-left:30px"><b>Faixa: </b>'+ codigoFaixaCompromissos +'%</dd>'+
            '</dl>'+
        '</tr>';
        
        result.pagamentoFinanceiroAvancado.put('Tabela-ContratosAtivos',tabela);
    }
    public static void formatarL320202(String retorno, Relatorio result) {  // L320202 -  Quantidade de compromissos e credores 

        Map<String,String> qtdCompromissosCredores = new Map<String,String>();
        qtdCompromissosCredores.put('Codigo Faixa Quantidade Compromissos', retorno.substring(0,3));   
        qtdCompromissosCredores.put('Quantidade Compromissos', retorno.substring(3,24));       
        qtdCompromissosCredores.put('Quantidade Credores', retorno.substring(24,34));   
        /*
        String outPutMap = '';
        for(String chave:qtdCompromissosCredores.keyset()){
            outPutMap += '\n' + chave + ':' + qtdCompromissosCredores.get(chave);
        }
        System.debug('\n\n<QUADRO L320202>\nretorno:'+retorno + outPutMap + '\n</QUADRO L320202>\n\n');
        */
        if(!result.pagamentoFinanceiroAvancado.containsKey('Tabela-ContratosAtivos')){
            result.pagamentoFinanceiroAvancado.put('Tabela-ContratosAtivos','');
        }     

        String tabela = result.pagamentoFinanceiroAvancado.get('Tabela-ContratosAtivos');   

        String codigoFaixaCompromissos = qtdCompromissosCredores.get('Codigo Faixa Quantidade Compromissos');
        String quantidadeCredores = qtdCompromissosCredores.get('Quantidade Credores');
        tabela += ''+
        '<tr class="slds-line-height_reset">'+
            '<dl style="margin-left:50px;margin-right:50px;margin-bottom:10px;padding:10px;margin-top:10px;border:gray solid 1px">'+
                '<dt><b>Quantidade de Compromissos</b></dt>'+
                    '<dd style="padding-left:30px"><b>Faixa: </b>'+ codigoFaixaCompromissos +'</dd>'+
                    '<dd style="padding-left:30px"><b>Quantidade: </b>'+ quantidadeCredores +'</dd>'+
            '</dl>'+
        '</tr>';

        result.pagamentoFinanceiroAvancado.put('Tabela-ContratosAtivos',tabela);
    }
    public static void formatarL320203(String retorno, Relatorio result) {  //L320203 - Percentual de parcelas de compromissos ativos  

        Map<String,String> percentualParcelas = new Map<String,String>();
        percentualParcelas.put('Percentual Parcelas Pagas', retorno.substring(0,3));
        percentualParcelas.put('Percentual Parcelas a Vencer', retorno.substring(3,6));
        percentualParcelas.put('Percentual Parcelas Abertas', retorno.substring(6,9));
        /*
        String outPutMap = '';
        for(String chave:percentualParcelas.keyset()){
            outPutMap += '\n' + chave + ':' + percentualParcelas.get(chave);
        }
        System.debug('\n\n<QUADRO L320203>\nretorno:'+retorno + outPutMap + '\n</QUADRO L320203>\n\n');
        */
        if(!result.pagamentoFinanceiroAvancado.containsKey('Tabela-ContratosAtivos')){
            result.pagamentoFinanceiroAvancado.put('Tabela-ContratosAtivos','');
        }     

        String tabela = result.pagamentoFinanceiroAvancado.get('Tabela-ContratosAtivos');   

        String percentualPagas = percentualParcelas.get('Percentual Parcelas Pagas');
        String percentualVencer = percentualParcelas.get('Percentual Parcelas a Vencer');
        String percentualAbertas = percentualParcelas.get('Percentual Parcelas Abertas');

        tabela += ''+
        '<tr class="slds-line-height_reset">'+
            '<dl style="margin-left:50px;margin-right:50px;margin-bottom:10px;padding:10px;margin-top:10px;border:gray solid 1px">'+
                '<dt><b>Parcelas</b></dt>'+
                    '<dd style="margin-left:30px"><b>Pagas: </b>'+ percentualPagas +'%</dd>'+
                    '<dd style="margin-left:30px"><b>À Vencer: </b>'+ percentualVencer +'%</dd>'+
                    '<dd style="margin-left:30px"><b>Em Aberto: </b>'+ percentualAbertas +'%</dd>'+
            '</dl>'+
        '</tr>';

        result.pagamentoFinanceiroAvancado.put('Tabela-ContratosAtivos',tabela);
    }
    public static void formatarL320204(String retorno, Relatorio result) {  // L320204 - Contratos ativos

        Map<String,String> comportamentoContratosAtivos = new Map<String,String>();
        comportamentoContratosAtivos.put('Percentual Contratos Ativos Pagos', retorno.substring(0,3));
        comportamentoContratosAtivos.put('Percentual Contratos Ativos AVencer', retorno.substring(3,6));
        comportamentoContratosAtivos.put('Percentual Contratos Ativos Abertas', retorno.substring(6,9));
        comportamentoContratosAtivos.put('Código Faixa Contratos Ativos', retorno.substring(9,12));
        comportamentoContratosAtivos.put('Valor Total Contratos Ativos', retorno.substring(12,33));
        /*
        String outPutMap = '';
        for(String chave:comportamentoContratosAtivos.keyset()){
            outPutMap += '\n' + chave + ':' + comportamentoContratosAtivos.get(chave);
        }
        System.debug('\n\n<QUADRO L320204>\nretorno:'+retorno + outPutMap + '\n</QUADRO L320204>\n\n');
        */
        initTabela_ComportamentoContratosAtivos(result);    

        String tabela = result.pagamentoFinanceiroAvancado.get('Tabela-ComportamentoContratosAtivos');   
        
        String percentualPagos = comportamentoContratosAtivos.get('Percentual Contratos Ativos Pagos');
        tabela = tabela.replace('$percentualPagos',percentualPagos);

        String percentualVencer = comportamentoContratosAtivos.get('Percentual Contratos Ativos AVencer');
        tabela = tabela.replace('$percentualVencer',percentualVencer);

        String percentualAbertas = comportamentoContratosAtivos.get('Percentual Contratos Ativos Abertas');
        tabela = tabela.replace('$percentualAbertas',percentualAbertas);

        String faixaContratosAtivos = comportamentoContratosAtivos.get('Código Faixa Contratos Ativos');
        tabela = tabela.replace('$faixaContratosAtivos',faixaContratosAtivos);

        String totalContratosAtivos = comportamentoContratosAtivos.get('Valor Total Contratos Ativos');
        tabela = tabela.replace('$totalContratosAtivos',totalContratosAtivos);

        result.pagamentoFinanceiroAvancado.put('Tabela-ComportamentoContratosAtivos',tabela);
    }
    public static void formatarL320205(String retorno, Relatorio result) {  // L320205 - Pontualidade de pagamento

        Map<String,String> pontualidadePagamento = new Map<String,String>();
        pontualidadePagamento.put('Percentual Rotativo', retorno.substring(0,3));    
        pontualidadePagamento.put('Percentual Pontual', retorno.substring(3,6));    
        pontualidadePagamento.put('Percentual até 30 dias', retorno.substring(6,9));         
        pontualidadePagamento.put('Percentual 31 à 60 dias', retorno.substring(9,12));    
        pontualidadePagamento.put('Percentual Acima 60 dias', retorno.substring(12,15));    
        pontualidadePagamento.put('Código Faixa Compromissos Pagos', retorno.substring(15,18));
        pontualidadePagamento.put('Valor Total Compromissos Pagos', retorno.substring(18,39));
        /*
        String outPutMap = '';
        for(String chave:pontualidadePagamento.keyset()){
            outPutMap += '\n' + chave + ':' + pontualidadePagamento.get(chave);
        }
        System.debug('\n\n<QUADRO L320205>\nretorno:'+retorno + outPutMap + '\n</QUADRO L320205>\n\n');
        */
        initTabela_ComportamentoContratosAtivos(result);    

        String tabela = result.pagamentoFinanceiroAvancado.get('Tabela-ComportamentoContratosAtivos');   
        
        String percentualRotativo = pontualidadePagamento.get('Percentual Rotativo');
        tabela = tabela.replace('$percentualRotativo',percentualRotativo);

        String percentualPontual = pontualidadePagamento.get('Percentual Pontual');
        tabela = tabela.replace('$percentualPontual',percentualPontual);

        String percentualAte30 = pontualidadePagamento.get('Percentual até 30 dias');
        tabela = tabela.replace('$percentualAte30',percentualAte30);

        String percentualAte60 = pontualidadePagamento.get('Percentual Acima 60 dias');
        tabela = tabela.replace('$percentualAte60',percentualAte60);

        String percentualAcima60 = pontualidadePagamento.get('Percentual Acima 60 dias');
        tabela = tabela.replace('$percentualAcima60',percentualAcima60);

        String faixaCompromissosPagos = pontualidadePagamento.get('Código Faixa Compromissos Pagos');
        tabela = tabela.replace('$faixaCompromissosPagos',faixaCompromissosPagos);

        String totalCompromissosPagos = pontualidadePagamento.get('Valor Total Compromissos Pagos');
        tabela = tabela.replace('$totalCompromissosPagos',totalCompromissosPagos);

        result.pagamentoFinanceiroAvancado.put('Tabela-ComportamentoContratosAtivos',tabela);
    }
    public static void formatarL320206(String retorno, Relatorio result) { // L320206 - Vencimentos em aberto 

        Map<String,String> compromissosEmAberto = new Map<String,String>();
        compromissosEmAberto.put('Percentual Vencimentose em Aberto 30 Dias', retorno.substring(0,3));
        compromissosEmAberto.put('Percentual Vencimentos em Aberto 31 à 60 Dias', retorno.substring(3,6));
        compromissosEmAberto.put('Percentual Vencimentos em Aberto 61 à 90 Dias', retorno.substring(6,9));
        compromissosEmAberto.put('Percentual Vencimentos em Aberto Acima 90 Dias', retorno.substring(9,12));
        compromissosEmAberto.put('Código Faixa Compromissos em Aberto', retorno.substring(12,15));    
        compromissosEmAberto.put('Valor Total Compromissos em Aberto', retorno.substring(15,36));  
        /*
        String outPutMap = '';
        for(String chave:compromissosEmAberto.keyset()){
            outPutMap += '\n' + chave + ':' + compromissosEmAberto.get(chave);
        }
        System.debug('\n\n<QUADRO L320206>\nretorno:'+retorno + outPutMap + '\n</QUADRO L320206>\n\n');
        */
        String ate30 = compromissosEmAberto.get('Percentual Vencimentose em Aberto 30 Dias');
        String ate60 = compromissosEmAberto.get('Percentual Vencimentos em Aberto 31 à 60 Dias');
        String ate90 = compromissosEmAberto.get('Percentual Vencimentos em Aberto 61 à 90 Dias');
        String acima90 = compromissosEmAberto.get('Percentual Vencimentos em Aberto Acima 90 Dias');
        String faixa = compromissosEmAberto.get('Código Faixa Compromissos em Aberto');
        String total = compromissosEmAberto.get('Valor Total Compromissos em Aberto');

        initTabela_ComportamentoContratosAtivos(result);    

        String tabela = result.pagamentoFinanceiroAvancado.get('Tabela-ComportamentoContratosAtivos');   
        tabela = tabela.replace('$abertosAte30',ate30);
        tabela = tabela.replace('$abertosDe31a60',ate60);
        tabela = tabela.replace('$abertosDe61a90',ate90);
        tabela = tabela.replace('$abertosAcimaDe90',acima90);
        tabela = tabela.replace('$faixaTotalAbertos',faixa);
        tabela = tabela.replace('$totalAbertos',total);
        
        result.pagamentoFinanceiroAvancado.put('Tabela-ComportamentoContratosAtivos',tabela);
    }
    public static void formatarL320297(String retorno, Relatorio result) { // L320297 - Mensagem de pontualidade de pagamento
        result.pagamentoFinanceiroAvancado.put('Mensagem Pontualida e Pagamento', retorno.substring(0,retorno.length()));
    }
    public static void formatarL320298(String retorno, Relatorio result) {  // L320298 -  Mensagem de vencimentos em aberto 
        
        String mensagem = retorno.substring(0,retorno.length()).trim();
        
        //System.debug('\n\n<QUADRO L320298>\nretorno:'+retorno + '\nmensagem: ' + mensagem + '\n</QUADRO L320298>\n\n');

        initTabela_ComportamentoContratosAtivos(result);

        String tabela = result.pagamentoFinanceiroAvancado.get('Tabela-ComportamentoContratosAtivos');
        String novoHTML = '<dd style="margin-left:30px">'+ mensagem +'</dd>';

        tabela = tabela.replace('<dd style="margin-left:30px"><b>Rotativo: </b>0%</dd>',novoHTML);
        result.pagamentoFinanceiroAvancado.put('Tabela-ComportamentoContratosAtivos',tabela);
    }
    public static void formatarL320299(String retorno, Relatorio result) { // L320299 - Mensagem de contratos ativos
        result.pagamentoFinanceiroAvancado.put('Mensagem Contratos Ativo', retorno.substring(0,retorno.length())); 
    }



    //alerta cadastral da empresa
    public static void initTabela_AlertaCadastralEmpresa(Relatorio result){
        if(!result.informacoesPadrao.containsKey('Tabela-AlertaCadastral')){
            String tabela = ''+
            '<tr class="slds-line-height_reset">'+
                '<td class="slds-cell-wrap"><b>Razão Social</b></td><td class="slds-cell-wrap">$razaoSocial</td>'+
            '</tr>'+
            '<tr class="slds-line-height_reset">'+
                '<td class="slds-cell-wrap"><b>Ramo de Atividade</b></td><td class="slds-cell-wrap">$Ramo de Atividade</td>'+
            '</tr>'+
            '<tr class="slds-line-height_reset">'+
                '<td class="slds-cell-wrap"><b>Endereço</b></td><td class="slds-cell-wrap">$Endereço</td>'+
            '</tr>'+
            '<tr class="slds-line-height_reset">'+
                '<td class="slds-cell-wrap"><b>Presença de cadastro na CGU</b></td><td class="slds-cell-wrap">$Presença de cadastro na CGU</td>'+
            '</tr>'+
            '<tr class="slds-line-height_reset">'+
                '<td class="slds-cell-wrap"><b>Tipo Societário</b></td><td class="slds-cell-wrap">$Tipo Societário</td>'+
            '</tr>'+
            '<tr class="slds-line-height_reset">'+
                '<td class="slds-cell-wrap"><b>Inconsistências Comerciais</b></td><td class="slds-cell-wrap">$Inconsistências Comerciais</td>'+
            '</tr>';
            result.informacoesPadrao.put('Tabela-AlertaCadastral',tabela);
        }
    }
    public static void formatarL600101(String retorno, Relatorio result) {
        Map<String,String> alertaRazaoSocial = new Map<String,String>();
        alertaRazaoSocial.put('codigo',retorno.substring(0,3).trim());
        alertaRazaoSocial.put('quantidadeAlertas',retorno.substring(3,11).trim());
        alertaRazaoSocial.put('data',retorno.substring(11,19).trim());
        alertaRazaoSocial.put('dataInicio',retorno.substring(19,27).trim());
        alertaRazaoSocial.put('dataFim',retorno.substring(27,35).trim());
        /*
        String outPutMap = '';
        for(String chave:alertaRazaoSocial.keyset()){
            outPutMap += '\n' + chave + ':' + alertaRazaoSocial.get(chave);
        }
        System.debug('\n<QUADRO L600101>\nretorno:'+retorno + outPutMap + '\n</QUADRO L600101>\n');
        */
        initTabela_AlertaCadastralEmpresa(result);

        result.informacoesPadrao.put('$quantidadeAlertasRazaoSocial',removerZeros(alertaRazaoSocial.get('quantidadeAlertas')));
    }
    public static void formatarL600102(String retorno, Relatorio result) {//Alteração no Ramo de Atividade
        Map<String,String> alertaRazaoSocial = new Map<String,String>();
        alertaRazaoSocial.put('codigo',retorno.substring(0,3).trim());
        alertaRazaoSocial.put('razaoAnterior',retorno.substring(3,73).trim());
        alertaRazaoSocial.put('razaoAtual',retorno.substring(73,143).trim());
        alertaRazaoSocial.put('dataAlteracao',retorno.substring(143,151).trim());
        /*
        String outPutMap = '';
        for(String chave:alertaRazaoSocial.keyset()){
            outPutMap += '\n' + chave + ':' + alertaRazaoSocial.get(chave);
        }
        System.debug('\n<QUADRO L600102>\nretorno:'+retorno + outPutMap + '\n</QUADRO L600102>\n');
        */
        initTabela_AlertaCadastralEmpresa(result);

        if(!result.informacoesPadrao.containsKey('Tabela-AlertaCadastral')){
            result.informacoesPadrao.put('Tabela-AlertaCadastral','');
        }

        String tabela =  result.informacoesPadrao.get('Tabela-AlertaCadastral');

        String anterior = alertaRazaoSocial.get('razaoAnterior');
        String novo = alertaRazaoSocial.get('razaoAtual');
        String quantidadeAlertas = result.informacoesPadrao.get('$quantidadeAlertasRazaoSocial');
        String data = formatarDataDDMMAAAA(alertaRazaoSocial.get('dataAlteracao'));

        String alerta = 'Foi identificada '+ quantidadeAlertas +' alteração nos últimos 12 (doze) meses.Empresa alterou sua razão social '+ anterior +'para razão social '+ novo +' em '+ data +'.';
        
        tabela = tabela.replace('$razaoSocial',alerta);
        result.informacoesPadrao.put('Tabela-AlertaCadastral',tabela);
    }
    public static void formatarL600199(String retorno, Relatorio result) {//Alteração Razão Social
        initTabela_AlertaCadastralEmpresa(result);
        
        if(!result.informacoesPadrao.containsKey('Tabela-AlertaCadastral')){
            result.informacoesPadrao.put('Tabela-AlertaCadastral','');
        }

        String mensagem = retorno.substring(3,82);
        result.informacoesPadrao.put('Tabela-AlertaCadastral',result.informacoesPadrao.get('Tabela-AlertaCadastral').replace('$razaoSocial',mensagem));
    }
    public static void formatarL600201(String retorno, Relatorio result) {//Alteração no Ramo de Atividade
        Map<String,String> alertaRamoAtividade = new Map<String,String>();
        alertaRamoAtividade.put('codigo',retorno.substring(0,3).trim());
        alertaRamoAtividade.put('quantidadeAlertas',retorno.substring(3,12).trim());
        alertaRamoAtividade.put('data',retorno.substring(12,20).trim());
        alertaRamoAtividade.put('dataInicio',retorno.substring(20,28).trim());
        alertaRamoAtividade.put('dataFim',retorno.substring(28,36).trim());
        /*
        String outPutMap = '';
        for(String chave:alertaRamoAtividade.keyset()){
            outPutMap += '\n' + chave + ':' + alertaRamoAtividade.get(chave);
        }
        System.debug('\n<QUADRO L600201>\nretorno:'+retorno + outPutMap + '\n</QUADRO L600201>\n');
        */
        initTabela_AlertaCadastralEmpresa(result);

        result.informacoesPadrao.put('$quantidadeAlertasRamoDeAtividade', removerZeros(alertaRamoAtividade.get('quantidadeAlertas')));
    }
    public static void formatarL600202(String retorno, Relatorio result) {//Alteração no Ramo de Atividade
        Map<String,String> alertaRamoAtividade = new Map<String,String>();
        alertaRamoAtividade.put('codigo',retorno.substring(0,3).trim());
        alertaRamoAtividade.put('codigoNAE',retorno.substring(3,8).trim());
        alertaRamoAtividade.put('digitoNAE',retorno.substring(8,10).trim());
        alertaRamoAtividade.put('descricaoNAE',retorno.substring(10,90).trim());
        alertaRamoAtividade.put('codigoNaeAnterior',retorno.substring(90,95).trim());
        alertaRamoAtividade.put('digitoNaeAnterior',retorno.substring(95,97).trim());
        alertaRamoAtividade.put('codigoNaeAnterior',retorno.substring(97,177).trim());
        alertaRamoAtividade.put('reservado',retorno.substring(177,retorno.length()).trim());
        /*
        String outPutMap = '';
        for(String chave:alertaRamoAtividade.keyset()){
            outPutMap += '\n' + chave + ':' + alertaRamoAtividade.get(chave);
        }
        System.debug('\n<QUADRO L600202>\nretorno:'+retorno + outPutMap + '\n</QUADRO L600202>\n');
        */
        initTabela_AlertaCadastralEmpresa(result);

        if(!result.informacoesPadrao.containsKey('Tabela-AlertaCadastral')){
            result.informacoesPadrao.put('Tabela-AlertaCadastral','');
        }
    
        String tabela =  result.informacoesPadrao.get('Tabela-AlertaCadastral');
        String quantidadeAlertas = result.informacoesPadrao.get('$quantidadeAlertasRamoDeAtividade');        
        String anterior = alertaRamoAtividade.get('codigoNaeAnterior');
        String novo = alertaRamoAtividade.get('codigoNAE');
        String alerta = 'Foi identificada '+ quantidadeAlertas +' alteração nos últimos 12 (doze) meses.Empresa alterou ramo social de '+ anterior +' para '+novo;
        tabela = tabela.replace('$Ramo de Atividade',alerta);
        result.informacoesPadrao.put('Tabela-AlertaCadastral',tabela);
    }
    public static void formatarL600299(String retorno, Relatorio result) {
        initTabela_AlertaCadastralEmpresa(result);
        String mensagem = retorno.substring(3,82);
        result.informacoesPadrao.put('Tabela-AlertaCadastral',result.informacoesPadrao.get('Tabela-AlertaCadastral').replace('$Ramo de Atividade',mensagem));
    }
    public static void formatarL600301(String retorno, Relatorio result) {//Alteração no Endereço
        Map<String,String> enderecoAlertaCadastral = new Map<String,String>();
        enderecoAlertaCadastral.put('codigoAlteracao',retorno.substring(0,3).trim());
        enderecoAlertaCadastral.put('quantidadeAlertas',retorno.substring(3,12).trim());enderecoAlertaCadastral.put('dataGeracao',retorno.substring(12,20).trim());
        enderecoAlertaCadastral.put('dataInicio',retorno.substring(20,28).trim());
        enderecoAlertaCadastral.put('dataFim',retorno.substring(28,36).trim());
        /*
        String outPutMap = '';
        for(String chave:enderecoAlertaCadastral.keyset()){
            outPutMap += '\n' + chave + ':' + enderecoAlertaCadastral.get(chave);
        }
        System.debug('\n<QUADRO L600301>\nretorno:'+retorno + outPutMap + '\n</QUADRO L600301>\n');
        */
        initTabela_AlertaCadastralEmpresa(result);

        if(!result.informacoesPadrao.containsKey('Tabela-AlertaCadastral')){
            result.informacoesPadrao.put('Tabela-AlertaCadastral','');
        }

        //String alerta = retorno.substring(3,retorno.length());
        String quantidade = enderecoAlertaCadastral.get('quantidadeAlertas');
        String inicio = enderecoAlertaCadastral.get('dataInicio');
        String fim = enderecoAlertaCadastral.get('dataFim');

        String tabela = result.informacoesPadrao.get('Tabela-AlertaCadastral');

        String alerta = 'Foram identificadas ' + quantidade + ' alterações nos últimos 12 (doze) meses (mudança de CEP)';
        
        tabela = tabela.replace('$Endereço',alerta + '$Endereço');

        result.informacoesPadrao.put('Tabela-AlertaCadastral',tabela);
    }  
    public static void formatarL600302(String retorno, Relatorio result) {//Alteração no Endereço
        Map<String,String> enderecoAlertaCadastral = new Map<String,String>();
        enderecoAlertaCadastral.put('codigoAlteracao',retorno.substring(0,3).trim());
        enderecoAlertaCadastral.put('logradouroAtual',retorno.substring(3,33).trim());
        enderecoAlertaCadastral.put('complementoLogradouro',retorno.substring(33,43).trim());
        enderecoAlertaCadastral.put('bairro',retorno.substring(43,63).trim());
        enderecoAlertaCadastral.put('cepAtual',retorno.substring(63,71).trim());
        enderecoAlertaCadastral.put('ufAtual',retorno.substring(71,73).trim());
        enderecoAlertaCadastral.put('codigoPostalAtual',retorno.substring(73,81).trim());
        enderecoAlertaCadastral.put('cepCodigoPostalAtual',retorno.substring(81,89).trim());
        enderecoAlertaCadastral.put('logradouroAnterior',retorno.substring(89,119).trim());
        enderecoAlertaCadastral.put('complementoLogradouroAtual',retorno.substring(119,129).trim());
        enderecoAlertaCadastral.put('BairroAnterior',retorno.substring(129,149).trim());
        enderecoAlertaCadastral.put('cepAnterior',retorno.substring(149,157).trim());
        enderecoAlertaCadastral.put('ufAnterior',retorno.substring(157,159).trim());
        enderecoAlertaCadastral.put('codigoPostalAnterior',retorno.substring(159,167).trim());
        enderecoAlertaCadastral.put('cepAnterior',retorno.substring(167,175).trim());
        enderecoAlertaCadastral.put('dataAlteracao',retorno.substring(175,183).trim());
        /*
        String outPutMap = '';
        for(String chave:enderecoAlertaCadastral.keyset()){
            outPutMap += '\n' + chave + ':' + enderecoAlertaCadastral.get(chave);
        }
        System.debug('\n<QUADRO L600302>\nretorno:'+retorno + outPutMap + '\n</QUADRO L600302>\n');
        */
        initTabela_AlertaCadastralEmpresa(result);

        String tabela = result.informacoesPadrao.get('Tabela-AlertaCadastral');

        String enderecoAntigo = enderecoAlertaCadastral.get('logradouroAnterior');
        String cepAntigo = enderecoAlertaCadastral.get('cepAnterior');
        String enderecoNovo = enderecoAlertaCadastral.get('logradouroAtual');
        String cepNovo = enderecoAlertaCadastral.get('cepAtual');

        String alerta = '<br>Empresa alterou seu endereço '+ enderecoAntigo +' CEP '+ cepAntigo +' para endereço '+ enderecoNovo +' CEP '+ cepNovo +'.';
        
        tabela = tabela.replace('$Endereço',alerta + '$Endereço');

        result.informacoesPadrao.put('Tabela-AlertaCadastral',tabela);
    }  
    public static void formatarL600399(String retorno, Relatorio result) {//Alteração no Endereço
        initTabela_AlertaCadastralEmpresa(result);

        if(!result.informacoesPadrao.containsKey('Tabela-AlertaCadastral')){
            result.informacoesPadrao.put('Tabela-AlertaCadastral','');
        }

        String mensagem = retorno.substring(3,82);
        result.informacoesPadrao.put('Tabela-AlertaCadastral',result.informacoesPadrao.get('Tabela-AlertaCadastral').replace('$Endereço',mensagem));
    } 
    public static void formatarL600401(String retorno, Relatorio result) {//Alteração tipo societario
        Map<String,String> alertaTipoSocietario = new Map<String,String>();
        alertaTipoSocietario.put('codigo',retorno.substring(0,3).trim());
        alertaTipoSocietario.put('data',retorno.substring(3,11).trim());
        alertaTipoSocietario.put('dataInicio',retorno.substring(11,19).trim());
        alertaTipoSocietario.put('dataFim',retorno.substring(19,27).trim());
        /*
        String outPutMap = '';
        for(String chave:alertaTipoSocietario.keyset()){
            outPutMap += '\n' + chave + ':' + alertaTipoSocietario.get(chave);
        }
        System.debug('\n<QUADRO L600401>\nretorno:'+retorno + outPutMap + '\n</QUADRO L604401>\n');
        */
        initTabela_AlertaCadastralEmpresa(result);
    }
    public static void formatarL600402(String retorno, Relatorio result) {//Alteração no Ramo de Atividade
        Map<String,String> alertaTipoSocietario = new Map<String,String>();
        alertaTipoSocietario.put('codigo',retorno.substring(0,3).trim());
        alertaTipoSocietario.put('reservado',retorno.substring(3,4).trim());
        alertaTipoSocietario.put('tipoSocietario',retorno.substring(4,48).trim());
        alertaTipoSocietario.put('reservado2',retorno.substring(48,49).trim());
        alertaTipoSocietario.put('tipoSocietarioAnterior',retorno.substring(49,93).trim());
        alertaTipoSocietario.put('data',retorno.substring(93,101).trim());
        /*
        String outPutMap = '';
        for(String chave:alertaTipoSocietario.keyset()){
            outPutMap += '\n' + chave + ':' + alertaTipoSocietario.get(chave);
        }
        System.debug('\n<QUADRO L600402>\nretorno:'+retorno + outPutMap + '\n</QUADRO L600402>\n');
        */
        initTabela_AlertaCadastralEmpresa(result);

        if(!result.informacoesPadrao.containsKey('Tabela-AlertaCadastral')){
            result.informacoesPadrao.put('Tabela-AlertaCadastral','');
        }

        String tabela =  result.informacoesPadrao.get('Tabela-AlertaCadastral');

        String anterior = alertaTipoSocietario.get('tipoSocietarioAnterior');
        String novo = alertaTipoSocietario.get('tipoSocietario');

        String alerta = 'Foi identificada alteração no tipo jurídico dessa empresa.Alterou de '+ anterior +' passou a ser o '+ novo +'.';
        
        tabela = tabela.replace('$Tipo Societário',alerta);
        result.informacoesPadrao.put('Tabela-AlertaCadastral',tabela);
    }
    public static void formatarL600499(String retorno, Relatorio result) {//Alteração no Tipo Societário
        initTabela_AlertaCadastralEmpresa(result);

        if(!result.informacoesPadrao.containsKey('Tabela-AlertaCadastral')){
            result.informacoesPadrao.put('Tabela-AlertaCadastral','');
        }

        String mensagem = retorno.substring(3,82);
        result.informacoesPadrao.put('Tabela-AlertaCadastral',result.informacoesPadrao.get('Tabela-AlertaCadastral').replace('$Tipo Societário',mensagem));
    }
    public static void formatarL600699(String retorno, Relatorio result) {//Presença de Cadastro na CGU 
        initTabela_AlertaCadastralEmpresa(result);

        if(!result.informacoesPadrao.containsKey('Tabela-AlertaCadastral')){
            result.informacoesPadrao.put('Tabela-AlertaCadastral','');
        }

        String mensagem = retorno.substring(3,82);
        
        result.informacoesPadrao.put('Tabela-AlertaCadastral',result.informacoesPadrao.get('Tabela-AlertaCadastral').replace('$Presença de cadastro na CGU',mensagem));
    }
    public static void formatarL600799(String retorno, Relatorio result) {//Inconsistências Comerciais 
        initTabela_AlertaCadastralEmpresa(result);

        if(!result.informacoesPadrao.containsKey('Tabela-AlertaCadastral')){
            result.informacoesPadrao.put('Tabela-AlertaCadastral','');
        }

        String mensagem = retorno.substring(3,82);
        result.informacoesPadrao.put('Tabela-AlertaCadastral',result.informacoesPadrao.get('Tabela-AlertaCadastral').replace('$Inconsistências Comerciais',mensagem));
    }
    public static void formatarL610099(String retorno, Relatorio result) {//Alerta Cadastral dos sócios e administradores  
        
        String mensagem = retorno.substring(3,retorno.length()).trim();
        //System.debug('\n<QUADRO L610099>\nretorno:'+retorno + '\nmensagem: ' + mensagem + '\n</QUADRO L010112>\n');

        initTabela_AlertaCadastralSocios(result);

        String tabela = result.informacoesSobreSociosAdministradores.get('Tabela-AlertaCadSociosAdms');
        tabela = '<tr class="slds-line-height_reset"><td class="slds-cell-wrap" >' + mensagem + '</td></tr>';
        result.informacoesSobreSociosAdministradores.put('Tabela-AlertaCadSociosAdms',tabela);
    }   
    public static void formatarL600701(String retorno, Relatorio result){

        Map<String,String> dadosInconsistenciaComercial = new Map<String,String>();
        dadosInconsistenciaComercial.put('codigoAlteracao',retorno.substring(0,3).trim());
        dadosInconsistenciaComercial.put('quantidadeAlertas',retorno.substring(3,12).trim());
        dadosInconsistenciaComercial.put('dataGeracaoAlerta',retorno.substring(12,20).trim());
        dadosInconsistenciaComercial.put('dataInicioPesquisa',retorno.substring(20,28).trim());
        dadosInconsistenciaComercial.put('dataFimPesquisa',retorno.substring(28,36).trim());
        /*
        String outPutMap = '';
        for(String chave:dadosInconsistenciaComercial.keyset()){
            outPutMap += '\n' + chave + ':' + dadosInconsistenciaComercial.get(chave);
        }
        System.debug('\n\n<QUADRO L600701>\nretorno:'+retorno + outPutMap + '\n</QUADRO L600701>\n\n');
        */
    }
    public static void formatarL600702(String retorno, Relatorio result){
        Map<String,String> inconsistenciaComercial = new Map<String,String>();
        inconsistenciaComercial.put('codigoMensagem',retorno.substring(0,3).trim());
        inconsistenciaComercial.put('codigoAlerta',retorno.substring(3,4).trim());
        inconsistenciaComercial.put('fraseAlerta',retorno.substring(4,128).trim());
        inconsistenciaComercial.put('dataAlteracao',retorno.substring(128,retorno.length()).trim());
        /*
        String outPutMap = '';
        for(String chave:inconsistenciaComercial.keyset()){
            outPutMap += '\n' + chave + ':' + inconsistenciaComercial.get(chave);
        }
        System.debug('\n\n<QUADRO L600702>\nretorno:'+retorno + outPutMap + '\n</QUADRO L600702>\n\n');
        */

        initTabela_AlertaCadastralEmpresa(result);

        if(!result.alertaCadastralEmpresa.containsKey('Inconsistências Comerciais')){
            result.alertaCadastralEmpresa.put('Inconsistências Comerciais',''+
            '<tr class="slds-line-height_reset">'+
                '<th">Data</th>'+
                '<th>Alerta</th>'+
            '</tr>'+
            '');
        }

        String tabela = result.informacoesPadrao.get('Tabela-AlertaEmNegocios');
        String alerta = inconsistenciaComercial.get('fraseAlerta');
        String data = formatarDataAAAAMMDD(inconsistenciaComercial.get('dataAlteracao'));
        if(tabela.contains(data)){data = '';}

        tabela = result.informacoesPadrao.get('Tabela-AlertaCadastral');
        tabela = tabela.replace('$Inconsistências Comerciais',alerta + '$Inconsistências Comerciais');
        result.informacoesPadrao.put('Tabela-AlertaCadastral',tabela);
    }



    //participacoes
    public static void formatarL010112(String retorno, Relatorio result) {
        Map<String,String> dataAtualizacao = new Map<String,String>();
        dataAtualizacao.put('dataAtualizacao',retorno.substring(0,8));
        dataAtualizacao.put('baseJuntaComercial',retorno.substring(8,9));
        /*
        String outPutMap = '';
        for(String chave:dataAtualizacao.keyset()){
            outPutMap += '\n' + chave + ':' + dataAtualizacao.get(chave);
        }
        System.debug('\n<QUADRO L010112>\nretorno:'+retorno + outPutMap + '\n</QUADRO L010112>\n');
        */
        if(!result.informacoesSobreSociosAdministradores.containsKey('Tabela-participacoes')){
            result.informacoesSobreSociosAdministradores.put('Tabela-participacoes','');
        }

        String data = formatarDataAAAAMMDD(dataAtualizacao.get('dataAtualizacao'));
        result.informacoesSobreSociosAdministradores.put('Tabela-participacoes',result.informacoesSobreSociosAdministradores.get('Tabela-participacoes') + '<thead><tr class="slds-line-height_reset"><td colspan=5 class="slds-cell-wrap" >Informação Atualizada em ' + data + '</td></tr></thead>');

        result.informacoesSobreSociosAdministradores.put('$pronto','false');
    }
    public static void formatarL010113(String retorno, Relatorio result){
        Map<String,String> participada = new Map<String,String>();
        participada.put('cnpj',retorno.substring(0,9));
        participada.put('digitoCnpj',retorno.substring(9,11));
        participada.put('empresaLigada',retorno.substring(11,78));
        participada.put('indicadorRestricao',retorno.substring(78,79));
        participada.put('sequenciaCnpj',retorno.substring(79,80));
        participada.put('identificacao',retorno.substring(80,81));
        participada.put('codigoSituacao',retorno.substring(81,83));

        Boolean print = false;
        if(!result.informacoesSobreSociosAdministradores.containsKey('$ultimoL010113')){
            result.informacoesSobreSociosAdministradores.put('$ultimoL010113',participada.get('cnpj'));
            print = true;
        }

        if(result.informacoesSobreSociosAdministradores.get('$ultimoL010113') != participada.get('cnpj')){
            result.informacoesSobreSociosAdministradores.put('$ultimoL010113',participada.get('cnpj'));
            print = true;
        }
        
        if(print){
            /*
            String outPutMap = '';
            for(String chave:participada.keyset()){
                outPutMap += '\n' + chave + ':' + participada.get(chave);
            }
            System.debug('\n<QUADRO L010113>\nretorno:'+retorno + outPutMap + '\n</QUADRO L010113>\n');
            */
            String cnpj = formatarCpfOuCnpj(participada.get('cnpj') + participada.get('digitoCnpj'),'J','0001');
            String razaoSocial = participada.get('empresaLigada');
            Boolean jump = true;

            if(!result.informacoesSobreSociosAdministradores.containsKey('Tabela-participacoes')){
                jump = false;
            }

            if(!result.informacoesSobreSociosAdministradores.get('Tabela-participacoes').contains('<tr class="slds-line-height_reset"><th class="slds-cell-wrap" >CNPJ: ' + cnpj + '</th><th class="slds-cell-wrap" >Razão Social: ' + razaoSocial + '</th><th class="slds-cell-wrap" >Cidade/UF: $local</th></tr>')){
                if(jump){
                    
                    if(result.informacoesSobreSociosAdministradores.get('$pronto') == 'true'){
                        result.informacoesSobreSociosAdministradores.put('Tabela-participacoes',result.informacoesSobreSociosAdministradores.get('Tabela-participacoes') + '<tr class="slds-line-height_reset" style = "border-left: 1px solid gray;border-right: 1px solid gray"><td class="slds-cell-wrap" ></td><td class="slds-cell-wrap" ></td><td class="slds-cell-wrap" ><b>Total</b></td><td class="slds-cell-wrap" ><b>' + result.informacoesSobreSociosAdministradores.get('$totalCapital') + '%</b></td><td class="slds-cell-wrap" ></td></tr>');
                    }

                    result.informacoesSobreSociosAdministradores.put('$totalCapital','0');

                    result.informacoesSobreSociosAdministradores.put('Tabela-participacoes',result.informacoesSobreSociosAdministradores.get('Tabela-participacoes') + '<thead><tr class="slds-line-height_reset"><td class="slds-cell-wrap" ></td></tr>');
                }

                result.informacoesSobreSociosAdministradores.put('Tabela-participacoes',result.informacoesSobreSociosAdministradores.get('Tabela-participacoes') + '<tr style="border-top: 1px solid gray;border-left: 1px solid gray;border-right: 1px solid gray" class="slds-line-height_reset"><td class="slds-cell-wrap" ><b>CNPJ:</b> ' + cnpj + '</td><td class="slds-cell-wrap" colspan=2><b>Razão Social:</b> ' + razaoSocial + '</td><td class="slds-cell-wrap" colspan=2><b>Cidade/UF:</b> $local</td></tr>');
                
                result.informacoesSobreSociosAdministradores.put('Tabela-participacoes',result.informacoesSobreSociosAdministradores.get('Tabela-participacoes') + '<thead><tr class="slds-line-height_reset"><th class="slds-cell-wrap" >CPF/CNPJ</th><th class="slds-cell-wrap" >Participante</th><th class="slds-cell-wrap" >Vínculo</th><th class="slds-cell-wrap" >Capital</th><th class="slds-cell-wrap" >Anotações</th></tr></thead>');
            }
        }    
    }
    public static void formatarL010114(String retorno, Relatorio result){
        Map<String,String> participante = new Map<String,String>();
        participante.put('nome',retorno.substring(0,67).trim());
        participante.put('vinculoParticipante',retorno.substring(67,76));
        participante.put('codigoEmbratel',retorno.substring(76,80));
        participante.put('descricaoMunicipio',retorno.substring(80,110));
        participante.put('ufCodigoEmbratel',retorno.substring(110,112));
        participante.put('percentualParticipacao',retorno.substring(112,117));
        participante.put('indicadorRestricao',retorno.substring(117,118));
        participante.put('cnpj',retorno.substring(118,127));
        participante.put('sequenciaCnpj',retorno.substring(127,131));
        participante.put('digitoCnpj',retorno.substring(131,133));
        participante.put('tipoPessoa',retorno.substring(133,134));
        participante.put('codigoSituacao',retorno.substring(134,136));
        /*
        String outPutMap = '';
        for(String chave:participante.keyset()){
            outPutMap += '\n' + chave + ':' + participante.get(chave);
        }
        System.debug('\n<QUADRO L010114>\nretorno:'+retorno + outPutMap + '\n</QUADRO L010114>\n');
        */
        String cnpj = formatarCpfOuCnpj(participante.get('cnpj')+participante.get('digitoCnpj'),participante.get('tipoPessoa'),'');
        String nome = participante.get('nome');
        if(nome == '' && result.informacoesSobreSociosAdministradores.containsKey('$' + cnpj)){
            nome = result.informacoesSobreSociosAdministradores.get('$' + cnpj);
        }
        String vinculo = participante.get('vinculoParticipante');
        String capitalAux = participante.get('percentualParticipacao');
        String capital = removerZeros(capitalAux.substring(0,3));
        if(capitalAux.substring(3,capitalAux.length()) != '00'){
            capital = capital + '.' + capitalAux.substring(3,capitalAux.length());
        }
        String anotacoes;
        switch on participante.get('indicadorRestricao'){
            when 'S'{
                anotacoes = 'Sim';
            }
            when 'N'{
                anotacoes = 'Não';
            }
        }
        String cidadeEuf = participante.get('descricaoMunicipio') + '/' + participante.get('ufCodigoEmbratel');
        if(cidadeEuf != ' / '){
            result.informacoesSobreSociosAdministradores.put('Tabela-participacoes',result.informacoesSobreSociosAdministradores.get('Tabela-participacoes').replace('$local',cidadeEuf));
        }

        result.informacoesSobreSociosAdministradores.put('Tabela-participacoes',result.informacoesSobreSociosAdministradores.get('Tabela-participacoes') + '<tr class="slds-line-height_reset" style = "border-left: 1px solid gray;border-right: 1px solid gray"><td class="slds-cell-wrap" >' + cnpj + '</td><td class="slds-cell-wrap" >' + nome + '</td><td class="slds-cell-wrap" >' + vinculo + '</td><td class="slds-cell-wrap" >' + capital + '%</td><td class="slds-cell-wrap" >' + anotacoes + '</td></tr>');

        if(!result.informacoesSobreSociosAdministradores.containsKey('$totalCapital')){
            result.informacoesSobreSociosAdministradores.put('$totalCapital','0');
        }
        Double total = double.valueOf(result.informacoesSobreSociosAdministradores.get('$totalCapital'));
        total += double.valueOf(capital);
        String t = String.valueOf(total);
        result.informacoesSobreSociosAdministradores.put('$totalCapital',t);
        result.informacoesSobreSociosAdministradores.put('$pronto','true');
    }
    public static void formatarL011399(String retorno, Relatorio result){

        String mensagemNaoCalculo = retorno.trim();
        //System.debug('\n\n<QUADRO L011399>\nretorno:'+retorno + '\nmensagem:' + mensagemNaoCalculo + '\n</QUADRO L011399>\n\n');

        if(!result.informacoesSobreSociosAdministradores.containsKey('Tabela-participacoes')){
            result.informacoesSobreSociosAdministradores.put('Tabela-participacoes','');
        }

        result.informacoesSobreSociosAdministradores.put('Tabela-participacoes',result.informacoesSobreSociosAdministradores.get('Tabela-participacoes') + '<tr class="slds-line-height_reset"><td class="slds-cell-wrap" >' + mensagemNaoCalculo + '</td></tr>');
    }



    //anotacoes negativas - acoes judiciais
    public static void formatarL040401(String retorno, Relatorio result){

        Map<String,String> acao = new Map<String,String>();        
        acao.put('quantidadeOcorrencias',retorno.substring(0,9).trim());        
        acao.put('dataAcaoJudicial',retorno.substring(9,17).trim());    
        acao.put('naturezaDaAcao',retorno.substring(17,37).trim());
        acao.put('avalista',retorno.substring(37,38).trim());
        acao.put('moeda',retorno.substring(38,41).trim());
        acao.put('valorDaAcao',retorno.substring(41,54).trim());
        acao.put('distrito',retorno.substring(54,56).trim());
        acao.put('varaCivil',retorno.substring(56,60).trim());
        acao.put('cidade',retorno.substring(60,90).trim());
        acao.put('uf',retorno.substring(90,92).trim());
        acao.put('pracaSubJudice',retorno.substring(92,96).trim());
        acao.put('distritoSubJudice',retorno.substring(96,98).trim());
        acao.put('varaSubjudice',retorno.substring(98,100).trim());
        acao.put('dataSubJudice',retorno.substring(100,108).trim());
        acao.put('processoSubJudice',retorno.substring(108,124).trim());
        acao.put('codigoNatureza',retorno.substring(124,127).trim());
        acao.put('areaReservada1',retorno.substring(127,151).trim());
        acao.put('mensagemSubjudice',retorno.substring(151,227).trim());  
        acao.put('areaReservada2',retorno.substring(227,228).trim());  

        String outPutMap = '';
        for(String chave:acao.keyset()){
            outPutMap += '\n' + chave + ':' + acao.get(chave);
        }
        //System.debug('\n\n<QUADRO L040401>\nretorno:'+retorno + outPutMap + '\n</QUADRO L040401>\n\n');

        if(!result.informacoesAnotacoesNegativas.containsKey('Tabela-acoesJudiciais')){
            result.informacoesAnotacoesNegativas.put('Tabela-acoesJudiciais','<thead><tr class="slds-line-height_reset"><th>Data</th><th>Natureza da Ação</th><th>Avalista</th><th>Valor</th><th>Distrito</th><th>Vara</th><th>Cidade/UF</th></tr></thead>');
        }

        String nada = 'nada ainda';
        String data = formatarDataAAAAMMDD(acao.get('dataAcaoJudicial'));
        String natureza = acao.get('naturezaDaAcao');
        String avalista = acao.get('avalista');
        String valorAcao = formatarValor(acao.get('valorDaAcao'),0);
        String distrito = acao.get('distrito');
        String vara = acao.get('varaCivil');
        String cidadeEuf = acao.get('cidade') + '/' + acao.get('uf');

        result.informacoesAnotacoesNegativas.put('Tabela-acoesJudiciais',result.informacoesAnotacoesNegativas.get('Tabela-acoesJudiciais') + '<tr class"slds-line-height_reset"><td class="slds-cell-wrap" >' + data + '</td><td class="slds-cell-wrap" >' + natureza + '</td><td class="slds-cell-wrap" >' + avalista + '</td><td class="slds-cell-wrap" >' + valorAcao + '</td><td class="slds-cell-wrap" >' + distrito + '</td><td class="slds-cell-wrap" >' + vara + '</td><td class="slds-cell-wrap" >' + cidadeEuf + '</td></tr>');
    }
    public static void formatarL041101(String retorno, Relatorio result){
        
        Map<String,String> participantesComAnotacoes = new Map<String,String>();
        participantesComAnotacoes.put('nome',retorno.substring(0,65).trim());
        participantesComAnotacoes.put('docParticipante',retorno.substring(65,76).trim());
        participantesComAnotacoes.put('tipoPessoa',retorno.substring(76,77));

        //System.debug('\n\n<QUADRO L041101>\nretorno:'+retorno+'\ndict:' + pendencia + '\n\n</QUADRO L041101>\n\n');
    }
    public static void formatarL041001(String retorno, Relatorio result){

        Map<String,String> recheque = new Map<String,String>();
        recheque.put('data',retorno.substring(0,8));
        recheque.put('banco',retorno.substring(8,24));
        recheque.put('agencia',retorno.substring(24,28));
        recheque.put('contaCorrente',retorno.substring(28,34));
        recheque.put('digitoConta',retorno.substring(34,35));
        recheque.put('chequeInicial',retorno.substring(35,41));
        recheque.put('chequeFinal',retorno.substring(41,47));
        recheque.put('motivo',retorno.substring(47,57));
        recheque.put('contaCorrente12Bytes',retorno.substring(57,69));

        /*
        String outPutMap = '';
        for(String chave:recheque.keyset()){
            outPutMap += '\n' + chave + ':' + recheque.get(chave);
        }
        System.debug('\n\n<QUADRO L041001>\nretorno:'+retorno + outPutMap + '\n</QUADRO L041001>\n\n');
        */
        
        if(!result.informacoesAnotacoesNegativas.containsKey('Tabela-recheques')){
            result.informacoesAnotacoesNegativas.put('Tabela-recheques','<thead><tr class="slds-line-height_reset"><th>Data</th><th>Banco</th><th>Agência</th><th>Conta Corrente</th><th>Cheque Inicial</th><th>Cheque Final</th><th>Motivo</th></tr></thead>');
        }

        String data = formatarDataAAAAMMDD(recheque.get('data')); 
        String banco = recheque.get('banco');
        String agencia = recheque.get('agencia');
        String contaCorrente = formatarValor(recheque.get('contaCorrente'),0) + '-' + recheque.get('digitoConta');
        String chequeInicial = removerZeros(recheque.get('chequeInicial'));
        String chequeFinal = removerZeros(recheque.get('chequeFinal'));
        String motivo = recheque.get('motivo');

        result.informacoesAnotacoesNegativas.put( 'Tabela-recheques' , result.informacoesAnotacoesNegativas.get('Tabela-recheques') + '<tr class="slds-line-height_reset"><td class="slds-cell-wrap" >' + data + '</td><td class="slds-cell-wrap" >' + banco + '</td><td class="slds-cell-wrap" >' + agencia + '</td><td class="slds-cell-wrap" >' + contaCorrente + '</td><td class="slds-cell-wrap" >' + chequeInicial + '</td><td class="slds-cell-wrap" >' + chequeFinal + '</td><td class="slds-cell-wrap" >' + motivo + '</td></tr>' );
    }
    public static void formatarL041000(String retorno, Relatorio result){

        Map<String,String> detalhesRecheque = new Map<String,String>();
        detalhesRecheque.put('quantidadeOcorrencias',retorno.substring(0,9));
        detalhesRecheque.put('quantidadeUltimaOcorrencia',retorno.substring(9,18));
        /*
        String outPutMap = '';
        for(String chave:detalhesRecheque.keyset()){
            outPutMap += '\n' + chave + ':' + detalhesRecheque.get(chave);
        }
        System.debug('\n\n<QUADRO L041000>\nretorno:'+retorno + outPutMap + '\n</QUADRO L041000>\n\n');
        */
        /*
        if(!result.informacoesAnotacoesNegativas.containsKey('Tabela-recheques')){
            result.informacoesAnotacoesNegativas.put('Tabela-recheques','<thead><tr class="slds-line-height_reset"><th>Data</th><th>Banco</th><th>Agência</th><th>Conta Corrente</th><th>Cheque Inicial</th><th>Cheque Final</th><th>Motivo</th></tr></thead>');
        }

        String data = formatarDataAAAAMMDD(recheque.get('data')); 
        String banco = recheque.get('banco');
        String agencia = recheque.get('agencia');
        String contaCorrente = formatarValor(recheque.get('contaCorrente'),0) + '-' + recheque.get('digitoConta');
        String chequeInicial = removerZeros(recheque.get('chequeInicial'));
        String chequeFinal = removerZeros(recheque.get('chequeFinal'));
        String motivo = recheque.get('motivo');

        result.informacoesAnotacoesNegativas.put( 'Tabela-recheques' , result.informacoesAnotacoesNegativas.get('Tabela-recheques') + '<tr class="slds-line-height_reset"><td class="slds-cell-wrap" >' + data + '</td><td class="slds-cell-wrap" >' + banco + '</td><td class="slds-cell-wrap" >' + agencia + '</td><td class="slds-cell-wrap" >' + contaCorrente + '</td><td class="slds-cell-wrap" >' + chequeInicial + '</td><td class="slds-cell-wrap" >' + chequeFinal + '</td><td class="slds-cell-wrap" >' + motivo + '</td></tr>' );
        */
    }
    public static void formatarL040601(String retorno, Relatorio result){
        Map<String,String> falenciaErecuperacao = new Map<String,String>();
        falenciaErecuperacao.put('quantidadeOcorrencias',retorno.substring(0,9).trim());
        falenciaErecuperacao.put('dataFACON',retorno.substring(9,17).trim());
        falenciaErecuperacao.put('tipoFACON',retorno.substring(17,37).trim());
        falenciaErecuperacao.put('origemFACON',retorno.substring(37,42).trim());
        falenciaErecuperacao.put('varaCivil',retorno.substring(42,46).trim());
        falenciaErecuperacao.put('cidadeFACON',retorno.substring(46,76).trim());
        falenciaErecuperacao.put('unidadeFederacao',retorno.substring(76,78).trim());
        falenciaErecuperacao.put('codigoNatureza',retorno.substring(78,81).trim());
        falenciaErecuperacao.put('areaReservada',retorno.substring(105).trim());

        //System.debug('\n<QUADRO L040601>\nretorno:'+retorno+'\ndict:' + falenciaErecuperacao + '\n</QUADRO L040601>\n');

        if(!result.informacoesAnotacoesNegativas.containsKey('Tabela-falenciaErecuperacao')){
            result.informacoesAnotacoesNegativas.put('Tabela-falenciaErecuperacao','<thead><tr class="slds-line-height_reset"><th>Data</th><th>Tipo</th><th>Origem</th><th>Cidade/UF</th></tr></thead>');
        }

        String cidadeEuf = falenciaErecuperacao.get('cidadeFACON') + '/' + falenciaErecuperacao.get('unidadeFederacao'); 
        String origem = falenciaErecuperacao.get('origemFACON') + falenciaErecuperacao.get('varaCivil'); 
        String tipo = falenciaErecuperacao.get('tipoFACON');
        String data = formatarDataAAAAMMDD(falenciaErecuperacao.get('dataFACON')); 

        String tabela = result.informacoesAnotacoesNegativas.get('Tabela-falenciaErecuperacao');
        
        tabela += ''+
        '<tr class="slds-line-height_reset">'+
            '<td class="slds-cell-wrap" >'+data+'</td>'+
            '<td class="slds-cell-wrap" >'+tipo+'</td>'+
            '<td class="slds-cell-wrap" >'+origem+'</td>'+
            '<td class="slds-cell-wrap" >'+cidadeEuf+'</td>'+
        '</tr>';

        result.informacoesAnotacoesNegativas.put('Tabela-falenciaErecuperacao',tabela);
    }
    public static void formatarL010198(String retorno, Relatorio result){

        Map<string,String> incorporacaoFusaoCisao = new Map<String,String>();
        incorporacaoFusaoCisao.put('mensagem',retorno.substring(0,79));
        incorporacaoFusaoCisao.put('atualizacao',retorno.substring(79,retorno.length()));

        /*
        String outPutMap = '';
        for(String chave:incorporacaoFusaoCisao.keyset()){
            outPutMap += '\n' + chave + ':' + incorporacaoFusaoCisao.get(chave);
        }
        System.debug('\n\n<QUADRO L010198>\nretorno:'+retorno + outPutMap + '\n</QUADRO L010198>\n\n');
        */

        String mensagem = incorporacaoFusaoCisao.get('mensagem');
        
        if(result.dadosCadEmp.containsKey('Observações')){
            result.dadosCadEmp.put('Observações',result.dadosCadEmp.get('Observações') + mensagem);
        }
        else{
            result.dadosCadEmp.put('Observações',mensagem);
        } 
    }
    public static void formatarL571001(string retorno, Relatorio result){
        Map<string,String> inscricaoEstadual = new Map<String,String>();
        inscricaoEstadual.put('numeroInscricao',retorno.substring(0,15));

        String inscricao = formatarValor(inscricaoEstadual.get('numeroInscricao'),0);

        result.dadosCadEmp.put('Tabela-DadosCadastrais',result.dadosCadEmp.get('Tabela-DadosCadastrais').replace('$Inscrição Estadual',inscricao));

        /*
        String outPutMap = '';
        for(String chave:inscricaoEstadual.keyset()){
            outPutMap += '\n' + chave + ':' + inscricaoEstadual.get(chave);
        }
        System.debug('\n\n<QUADRO L571001>\nretorno:'+retorno + outPutMap + '\n</QUADRO L571001>\n\n');
        */
    }
    public static void formatarL041099(String retorno, Relatorio result) { 
        //result.informacoesAnotacoesNegativas.put('Informações do Recheque - Cheques Extraviados / Sustados', retorno.substring(0,79).trim());

        String mensagem = retorno.substring(0,retorno.length()).trim();

        if(!result.informacoesAnotacoesNegativas.containsKey('Tabela-recheques')){
            result.informacoesAnotacoesNegativas.put('Tabela-recheques','');
        }

        if(result.informacoesAnotacoesNegativas.containsKey('$ultimoSocio')){
            String socio = result.informacoesAnotacoesNegativas.get('$ultimoSocio');
            String tabela = result.informacoesAnotacoesNegativas.get('Tabela-recheques');
            tabela += ''+
            '<thead>'+
                '<tr class="slds-line-height_reset" style="border-top:solid gray 1px">'+
                    '<th>Razão Social</th><th>Mensagem</th>'+
                '</tr>'+
            '</thead>'+
            '<tr class="slds-line-height_reset">'+
                '<td class="slds-cell-wrap" >'+ socio +'</td>'+    
                '<td class="slds-cell-wrap" >'+ mensagem +'</td>'+
            '</tr>';
    
            result.informacoesAnotacoesNegativas.put('Tabela-recheques',tabela);
        }  
    }



    //perfil financeiro
    public static void formatarL300901(String retorno, Relatorio result){

        String cnpj = formatarValor(retorno.substring(9,18).trim(),0);
        String filial = retorno.substring(18,22).trim();
        String digito = retorno.substring(22,24).trim();
        result.perfilFinanceiro.put('CNPJ',cnpj+'/'+filial+'-'+digito);
        result.perfilFinanceiro.put('Razão Social',retorno.substring(24,94).trim());
        result.perfilFinanceiro.put('Data',formatarDataAAAAMMDD(retorno.substring(114,retorno.length()).trim()));
                
        //System.debug('\n\n<QUADRO L300901>\n' + result.perfilFinanceiro + '\n\n</QUADRO L300901>\n\n');
    }
    public static void formatarL300902(String retorno, Relatorio result){

        Map<String,String> ControleDoBalanco = new Map<String,String>();

        result.perfilFinanceiro.put('Tipo de Demonstrativo',retorno.substring(31,51).trim());
        result.perfilFinanceiro.put('Padrão Contábil',retorno.substring(10,30).trim());
        //result.perfilFinanceiro.put('Data Balanço',formatarDataAAAAMMDD(retorno.substring(0,9).trim()));
        result.perfilFinanceiro.put('PRD',retorno.substring(51,53).trim());
        result.perfilFinanceiro.put('Valor em',retorno.substring(54,retorno.length()).trim() + ' DE ' + retorno.substring(75,95).trim());
        //result.perfilFinanceiro.put('Tipo Balanco',retorno.substring(9,10).trim());
        //result.perfilFinanceiro.put('Tipo Demonstrativo',retorno.substring(30,31).trim());
        //result.perfilFinanceiro.put('Unidade',retorno.substring(53,54).trim());
        //result.perfilFinanceiro.put('Moeda',retorno.substring(74,75).trim());
        //result.perfilFinanceiro.put('Descrição da moeda',);
        
        //System.debug('\n\n<QUADRO L300902>\nretorno:'+retorno+'\ndict:' + ControleDoBalanco + '\n\n</QUADRO L300902>\n\n');
    }
    public static void formatarL300903(String retorno, Relatorio result){

        Map<String,String> ContasDoAtivo = new Map<String,String>();
        ContasDoAtivo.put('codigoNivelDaConta',retorno.substring(0,3).trim());
        ContasDoAtivo.put('numeroConta',retorno.substring(3,8).trim());
        ContasDoAtivo.put('nomeConta',retorno.substring(8,33).trim());
        ContasDoAtivo.put('valorConta',retorno.substring(33,43).trim());
        ContasDoAtivo.put('brilho',retorno.substring(43,44).trim());

        //System.debug('\n<QUADRO L300903>\nretorno:'+retorno+'\ndict:' + ContasDoAtivo + '\n</QUADRO L300903>\n');

        if(!result.perfilFinanceiro.containsKey('Tabela-perfilFinanceiro')){
            result.perfilFinanceiro.put('Tabela-perfilFinanceiro','<thead><tr class="slds-line-height_reset"><th>Grupo</th><th>Valores</th></tr></thead>');
            result.perfilFinanceiro.put('Tabela-perfilFinanceiro',result.perfilFinanceiro.get('Tabela-perfilFinanceiro')+'<tr class="slds-line-height_reset"><th><b>Ativo</b></th><th></th></tr>');
        }

        result.perfilFinanceiro.put('Tabela-perfilFinanceiro',result.perfilFinanceiro.get('Tabela-perfilFinanceiro')+'<tr class="slds-line-height_reset"><td class="slds-cell-wrap" >'+ContasDoAtivo.get('nomeConta')+'</td><td class="slds-cell-wrap" >R$ '+formatarValor(ContasDoAtivo.get('valorConta'),0)+'</td></tr>');
    }
    public static void formatarL300904(String retorno, Relatorio result){

        Map<String,String> ContasDoPassivo = new Map<String,String>();
        ContasDoPassivo.put('codigoNivelDaConta',retorno.substring(0,3).trim());
        ContasDoPassivo.put('numeroConta',retorno.substring(3,8).trim());
        ContasDoPassivo.put('nomeConta',retorno.substring(8,33).trim());
        ContasDoPassivo.put('valorConta',retorno.substring(33,43).trim());
        ContasDoPassivo.put('brilho',retorno.substring(43,44).trim());

        //System.debug('\n<QUADRO L300904>\nretorno:'+retorno+'\ndict:' + ContasDoPassivo + '\n</QUADRO L300904>\n');

        if(!result.perfilFinanceiro.get('Tabela-perfilFinanceiro').contains('<tr class="slds-line-height_reset"><th><b>Passivo</b></th><th></th></tr>')){
            result.perfilFinanceiro.put('Tabela-perfilFinanceiro',result.perfilFinanceiro.get('Tabela-perfilFinanceiro')+'<tr class="slds-line-height_reset"><th><b>Passivo</b></th><th></th></tr>');
        }
        result.perfilFinanceiro.put('Tabela-perfilFinanceiro',result.perfilFinanceiro.get('Tabela-perfilFinanceiro')+'<tr class="slds-line-height_reset"><td class="slds-cell-wrap" >'+ContasDoPassivo.get('nomeConta')+'</td><td class="slds-cell-wrap" >R$ '+formatarValor(ContasDoPassivo.get('valorConta'),0)+'</td></tr>');
    }
    public static void formatarL300905(String retorno, Relatorio result){

        Map<String,String> ContaDemonstrativoResultado = new Map<String,String>();
        ContaDemonstrativoResultado.put('codigoNivelDaConta',retorno.substring(0,3).trim());
        ContaDemonstrativoResultado.put('numeroConta',retorno.substring(3,8).trim());
        ContaDemonstrativoResultado.put('nomeConta',retorno.substring(8,33).trim());
        ContaDemonstrativoResultado.put('valorConta',retorno.substring(33,43).trim());
        ContaDemonstrativoResultado.put('brilho',retorno.substring(43,44).trim());

        //System.debug('\n<QUADRO L300905>\nretorno:'+retorno+'\ndict:' + ContaDemonstrativoResultado + '\n</QUADRO L300905>\n');

        if(!result.perfilFinanceiro.get('Tabela-perfilFinanceiro').contains('<tr class="slds-line-height_reset"><th><b>Demonstração de resultado</b></th><th></th></tr>')){
            result.perfilFinanceiro.put('Tabela-perfilFinanceiro',result.perfilFinanceiro.get('Tabela-perfilFinanceiro')+'<tr class="slds-line-height_reset"><th><b>Demonstração de resultado</b></th><th></th></tr>');
        }
        result.perfilFinanceiro.put('Tabela-perfilFinanceiro',result.perfilFinanceiro.get('Tabela-perfilFinanceiro')+'<tr class="slds-line-height_reset"><td class="slds-cell-wrap" >'+ContaDemonstrativoResultado.get('nomeConta')+'</td><td class="slds-cell-wrap" >R$ '+formatarValor(ContaDemonstrativoResultado.get('valorConta'),0)+'</td></tr>');   
    }
    public static void formatarL300906(String retorno, Relatorio result){

        Map<String,String> indiceFinanceiro = new Map<String,String>();
        indiceFinanceiro.put('codigoCategoriaIndice',retorno.substring(0,2).trim());
        indiceFinanceiro.put('descricaoCategoria',retorno.substring(2,37).trim());
        indiceFinanceiro.put('codigoIndice',retorno.substring(37,40).trim());
        indiceFinanceiro.put('descricaoIndice',retorno.substring(40,75).trim());
        indiceFinanceiro.put('indiceBalanco',retorno.substring(75,89).trim());
        indiceFinanceiro.put('indicePadraoBalanco',retorno.substring(89,103).trim());
        indiceFinanceiro.put('formatoIndice',retorno.substring(103,104).trim());
        indiceFinanceiro.put('quantidadeCasasInteiras',retorno.substring(104,106).trim());
        indiceFinanceiro.put('quantidadeCasasDecimais',retorno.substring(106,retorno.length()).trim());
        /*
        String outPutMap = '';
        for(String chave:indiceFinanceiro.keyset()){
            outPutMap += '\n' + chave + ':' + indiceFinanceiro.get(chave);
        }
        System.debug('\n\n<QUADRO L300906>\nretorno:'+retorno + outPutMap + '\n</QUADRO L300906>\n\n');
        */
        if(!result.perfilFinanceiro.containsKey('Tabela-indiceEconomico')){
            result.perfilFinanceiro.put('Tabela-indiceEconomico','<thead><tr class="slds-line-height_reset"><th>Indices</th><th>Empresas</th><th>Padrão ( Referência do Setor)</th></tr></thead>');
        }

        if( indiceFinanceiro.get('descricaoIndice') == 'LIQUIDEZ CORRENTE'){
        
            String indicePadrao = formatarValor(indiceFinanceiro.get('indicePadraoBalanco'),0);
            String indice = indiceFinanceiro.get('descricaoIndice');
            String empresa = indicePadrao.substring(0,indicePadrao.length()-1);
            //empresa = empresa.substring(0,empresa.length()-3);
            String padrao = formatarValor(indiceFinanceiro.get('indiceBalanco'),3);
            //padrao = padrao.substring(0,padrao.length()-3);
            String tabela = result.perfilFinanceiro.get('Tabela-indiceEconomico');

            tabela += ''+
            '<tr class="slds-line-height_reset">'+
                '<td class="slds-cell-wrap" >' + indice + '</td>'+
                '<td class="slds-cell-wrap" >' + padrao + '</td>'+
                '<td class="slds-cell-wrap" >' + empresa + '</td>'+
            '</tr>';

            result.perfilFinanceiro.put('Tabela-indiceEconomico',tabela);
        
        }else{
            result.perfilFinanceiro.put('Tabela-indiceEconomico',result.perfilFinanceiro.get('Tabela-indiceEconomico') + '<tr class="slds-line-height_reset"><td class="slds-cell-wrap" >' + indiceFinanceiro.get('descricaoIndice') + '</td><td class="slds-cell-wrap" >' + formatarValor(indiceFinanceiro.get('indiceBalanco'), 3) + '%</td><td class="slds-cell-wrap" >' + formatarValor(indiceFinanceiro.get('indicePadraoBalanco'),3) + '%</td></tr>');
        }        
    }



    //quadro social mais completo
    public static void formatarL010117(String retorno, Relatorio result){

        Map<String,String> informacaoAdicionalSocio = new Map<String,String>();
        informacaoAdicionalSocio.put('cpf',retorno.substring(0,9).trim());
        informacaoAdicionalSocio.put('filialDocumento',retorno.substring(9,13).trim());
        informacaoAdicionalSocio.put('digitoDocumento',retorno.substring(13,15).trim());
        informacaoAdicionalSocio.put('dataAtualizacao',retorno.substring(15,23).trim());
        informacaoAdicionalSocio.put('nomeSocio',retorno.substring(23,83).trim());
        informacaoAdicionalSocio.put('rgSocio',retorno.substring(83,94).trim());
        informacaoAdicionalSocio.put('dataNascimentoSocio',retorno.substring(94,102).trim());
        informacaoAdicionalSocio.put('vinculoSocio',retorno.substring(102,103).trim());
        informacaoAdicionalSocio.put('cidadeNatal',retorno.substring(103,133).trim());
        informacaoAdicionalSocio.put('estadoNatal',retorno.substring(133,135).trim());
        informacaoAdicionalSocio.put('ddd',retorno.substring(135,139).trim());
        informacaoAdicionalSocio.put('numeroTelefone',retorno.substring(139,148).trim());
        informacaoAdicionalSocio.put('ramal',retorno.substring(148,152).trim());
        informacaoAdicionalSocio.put('nomeLogradouro',retorno.substring(152,222).trim());
        informacaoAdicionalSocio.put('bairro',retorno.substring(222,242).trim());
        informacaoAdicionalSocio.put('cidade',retorno.substring(242,272).trim());
        informacaoAdicionalSocio.put('estadoEndereco',retorno.substring(272,274).trim());
        informacaoAdicionalSocio.put('cep',retorno.substring(274,283).trim());
        informacaoAdicionalSocio.put('areaReservada',retorno.substring(283,287).trim());
        informacaoAdicionalSocio.put('codigoSocio',retorno.substring(287,288).trim());

        String cnpj = formatarCpfOuCnpj(informacaoAdicionalSocio.get('cpf')+informacaoAdicionalSocio.get('digitoDocumento'),'F',informacaoAdicionalSocio.get('filialDocumento'));
        String socio = informacaoAdicionalSocio.get('nomeSocio');
        result.informacoesSobreSociosAdministradores.put('$ultimoSocio',socio);
        result.informacoesSobreSociosAdministradores.put('$'+socio,cnpj);
        if(!isIN(parametrosSelecionados,'QuadroSocialAdministracaoMaisCompleto')){
            return;
        }

        result.informacoesAnotacoesNegativas.put('$ultimoSocio',cnpj);

        /*
        String outPutMap = '';
        for(String chave:informacaoAdicionalSocio.keyset()){
            outPutMap += '\n' + chave + ':' + informacaoAdicionalSocio.get(chave);
        }
        System.debug('\n\n<QUADRO L010117>\nretorno:'+retorno + outPutMap + '\n</QUADRO L010117>\n\n');
        */
        if(!result.quadroSocialAdministracaoMaisCompleto.containsKey('Tabela-quadroSocialMaisCompleto')){
            result.quadroSocialAdministracaoMaisCompleto.put('Tabela-quadroSocialMaisCompleto','');
        }

        String dataNascimento = formatarDataAAAAMMDD(informacaoAdicionalSocio.get('dataNascimentoSocio'));
        String vinculo;
        switch on informacaoAdicionalSocio.get('vinculoSocio'){
            when 'S'{
                vinculo = 'SOCIO';
            }
            when 'A'{
                vinculo = 'ADMINITRADOR';
            }
            when 'D'{
                vinculo = 'SOCIO / ADMINISTRADOR';
            }
        }
        String rua = informacaoAdicionalSocio.get('nomeLogradouro');
        String bairro = informacaoAdicionalSocio.get('bairro');
        String cidade = informacaoAdicionalSocio.get('cidade');
        String estado = informacaoAdicionalSocio.get('estadoEndereco');
        String cepAux = removerZeros(informacaoAdicionalSocio.get('cep'));
        //String cep = cepAux.substring(0,cepAux.length() - 3) + '-' + cepAux.substring(cepAux.length() - 3,cepAux.length());
        String cep = '89506-300';
        String telefone = '(' + removerZeros(informacaoAdicionalSocio.get('ddd')) + ') ' + removerZeros(informacaoAdicionalSocio.get('numeroTelefone'));
        if(telefone == '(0) 0'){
            telefone = '';
        }
        String ramal = informacaoAdicionalSocio.get('ramal');
        String enderecoCompleto;
        if(rua == ''){
            enderecoCompleto = '';
        }
        else{
            enderecoCompleto = rua + ', ' + bairro + ', ' + cidade + ', ' + estado + ', ' + cep;
        }
        String estadoCivil = result.informacoesSobreSociosAdministradores.get( '$' + cnpj + 'estadoCivil' );
        String naturalidade = informacaoAdicionalSocio.get('estadoNatal');
        String nacionalidade = result.informacoesSobreSociosAdministradores.get( '$' + cnpj + 'nacionalidade');
        String mandato = result.informacoesSobreSociosAdministradores.get( '$' + cnpj + 'mandato');
        String identidade = informacaoAdicionalSocio.get('rgSocio');
        String cargo = result.informacoesSobreSociosAdministradores.get( '$' + cnpj + 'cargo' );

        String tabela = result.quadroSocialAdministracaoMaisCompleto.get('Tabela-quadroSocialMaisCompleto') ;
        tabela += ''+
        '<thead>'+
            '<tr class="slds-line-height_reset" style = "border-top: 1px solid gray;border-left: 1px solid gray;border-right: 1px solid gray">'+
                '<td class="slds-cell-wrap" colspan=3><b>' + socio + '</b></td>'+
            '</tr>'+
        '</thead>'+
        '<thead>'+
            '<tr class="slds-line-height_reset">'+
                '<th class="slds-cell-wrap" >CNPJ</th>'+
                '<th class="slds-cell-wrap" >Identidade</th>'+
                '<th class="slds-cell-wrap" >Data Nascimento</th>'+
                '<th class="slds-cell-wrap" >Estado Civil</th>'+
                '<th class="slds-cell-wrap" >Natural de</th>'+
                '<th class="slds-cell-wrap" >Nacionalidade</th>'+
            '</tr>'+
        '</thead>'+
        '<tr class="slds-line-height_reset">'+
            '<td class="slds-cell-wrap" >' + cnpj + '</td>'+
            '<td class="slds-cell-wrap" >' + identidade + '</td>'+
            '<td class="slds-cell-wrap" >' + dataNascimento + '</td>'+
            '<td class="slds-cell-wrap" >' + estadoCivil + '</td>'+
            '<td class="slds-cell-wrap" >' + naturalidade + '</td>'+
            '<td class="slds-cell-wrap" >' + nacionalidade + '</td>'+
        '</tr>'+
        '<thead>'+
            '<tr class="slds-line-height_reset">'+
                '<th class="slds-cell-wrap" colspan=2>Telefone</th>'+
                '<th class="slds-cell-wrap" >Vínculo</th>'+
                '<th class="slds-cell-wrap" colspan=2>Cargo</th>'+
                '<th class="slds-cell-wrap" >Mandato</th>'+
            '</tr>'+
        '</thead>'+
        '<tr class="slds-line-height_reset">'+
            '<td class="slds-cell-wrap" colspan=2>' + telefone + '</td>'+
            '<td class="slds-cell-wrap" >' + vinculo + '</td>'+
            '<td class="slds-cell-wrap" colspan=2>' + cargo + '</td>'+
            '<td class="slds-cell-wrap" >' + mandato + '</td>'+
        '</tr>'+
        '<thead>'+
            '<tr class="slds-line-height_reset">'+
                '<th class="slds-cell-wrap" colspan=6>Endereço completo</th>'+
            '</tr>'+
        '</thead>'+
        '<tr class="slds-line-height_reset">'+
            '<td class="slds-cell-wrap" colspan=6>' + enderecoCompleto + '</td>'+
        '</tr>';

        result.QuadroSocialAdministracaoMaisCompleto.put('Tabela-quadroSocialMaisCompleto',tabela);
    }
    public static void formatarL010119(String retorno, Relatorio result){

        if(!isIN(parametrosSelecionados,'QuadroSocialAdministracaoMaisCompleto')){
            return;
        }

        //result.quadroSocialAdministracaoMaisCompleto.put('teste','teste');

        Map<string,String> novoQuadroSocial = new Map<String,String>();
        novoQuadroSocial.put('cnpj',retorno.substring(0,9).trim());
        novoQuadroSocial.put('filial',retorno.substring(9,13).trim());
        novoQuadroSocial.put('digito',retorno.substring(13,15).trim());
        novoQuadroSocial.put('dataFundacao',retorno.substring(15,23).trim());
        novoQuadroSocial.put('dataAtualizacao',retorno.substring(23,31).trim());
        novoQuadroSocial.put('razaoSocial',retorno.substring(31,101).trim());
        novoQuadroSocial.put('nomeFantazia',retorno.substring(101,131).trim());
        novoQuadroSocial.put('vinculoSocio',retorno.substring(131,132).trim());
        novoQuadroSocial.put('situacao',retorno.substring(132,133).trim());
        /*
        String outPutMap = '';
        for(String chave:novoQuadroSocial.keyset()){
            outPutMap += '\n' + chave + ':' + novoQuadroSocial.get(chave);
        }
        System.debug('\n\n<QUADRO L010119>\nretorno:'+retorno + outPutMap + '\n</QUADRO L010119>\n\n');
        */
        if(!result.quadroSocialAdministracaoMaisCompleto.containsKey('Tabela-quadroSocialMaisCompleto')){
            result.quadroSocialAdministracaoMaisCompleto.put('Tabela-quadroSocialMaisCompleto','');
        }

        String socio = novoQuadroSocial.get('razaoSocial');
        String cnpj = formatarCpfOuCnpj(novoQuadroSocial.get('cnpj')+novoQuadroSocial.get('digito'),'J',novoQuadroSocial.get('filial'));
        String fundacao = formatarDataAAAAMMDD(novoQuadroSocial.get('dataFundacao'));
        String vinculo;
        switch on novoQuadroSocial.get('vinculoSocio'){
            when 'S'{
                vinculo = 'SOCIO';
            }
            when 'A'{
                vinculo = 'ADMINITRADOR';
            }
            when 'D'{
                vinculo = 'SOCIO / ADMINISTRADOR';
            }
        }
        result.informacoesSobreSociosAdministradores.put('$ultimoSocio',socio);
        result.informacoesAnotacoesNegativas.put('$ultimoSocio',cnpj);
        String dataEntrada = result.informacoesSobreSociosAdministradores.get('$entrada' + socio);
        String capitalVotante = result.informacoesSobreSociosAdministradores.get('$votante' + socio);
        String capitalTotal = result.informacoesSobreSociosAdministradores.get('$total' + socio);

        String tabela = result.quadroSocialAdministracaoMaisCompleto.get('Tabela-quadroSocialMaisCompleto');
        tabela += ''+
        '<thead>'+
            '<tr class="slds-line-height_reset" style = "border-top: 1px solid gray;border-left: 1px solid gray;border-right: 1px solid gray">'+
                '<td class="slds-cell-wrap" colspan=3><b>' + socio + '</b></td>'+
            '</tr>'+
        '</thead>'+
        '<thead>'+
            '<tr class="slds-line-height_reset">'+
                '<th class="slds-cell-wrap" colspan=2>CNPJ</th>'+
                '<th class="slds-cell-wrap" colspan=2>Data de Entrada na Sociedade</th>'+
                '<th class="slds-cell-wrap" colspan=2>Fundação</th>'+
            '</tr>'+
        '</thead>'+
        '<tr class="slds-line-height_reset">'+
            '<td class="slds-cell-wrap" colspan=2>' + cnpj + '</td>'+
            '<td class="slds-cell-wrap" colspan=2>' + dataEntrada + '</td>'+
            '<td class="slds-cell-wrap" colspan=2>' + fundacao + '</td>'+
        '</tr>'+
        '<thead>'+
            '<tr class="slds-line-height_reset">'+
                '<th class="slds-cell-wrap" colspan=2>Vínculo</th>'+
                '<th class="slds-cell-wrap" colspan=2>Capital Votante</th>'+
                '<th class="slds-cell-wrap" colspan=2>Capital Total</th>'+
            '</tr>'+
        '</thead>'+
        '<tr class="slds-line-height_reset">'+
            '<td class="slds-cell-wrap" colspan=2>' + vinculo + '</td>'+
            '<td class="slds-cell-wrap" colspan=2>' + capitalVotante + '</td>'+
            '<td class="slds-cell-wrap" colspan=2>' + capitalTotal + '</td>'+
        '</tr>';
        result.quadroSocialAdministracaoMaisCompleto.put('Tabela-quadroSocialMaisCompleto',tabela);
    }
    public static void formatarL010120(String retorno, Relatorio result){


        if(!isIN(parametrosSelecionados,'QuadroSocialAdministracaoMaisCompleto')){
            return;
        }

        Map<string,String> novoQuadroSocialComplemento = new Map<String,String>();
        novoQuadroSocialComplemento.put('nomeLogradouro',retorno.substring(0,70).trim());
        novoQuadroSocialComplemento.put('bairro',retorno.substring(70,90).trim());
        novoQuadroSocialComplemento.put('cidade',retorno.substring(90,120).trim());
        novoQuadroSocialComplemento.put('estado',retorno.substring(120,122).trim());
        novoQuadroSocialComplemento.put('cep',retorno.substring(122,131).trim());
        novoQuadroSocialComplemento.put('ddd',retorno.substring(131,135).trim());
        novoQuadroSocialComplemento.put('telefone',retorno.substring(135,144).trim());
        novoQuadroSocialComplemento.put('ramal',retorno.substring(144,148).trim());
        novoQuadroSocialComplemento.put('ramoAtividade',retorno.substring(148,retorno.length()).trim());
        /*
        String outPutMap = '';
        for(String chave:novoQuadroSocialComplemento.keyset()){
            outPutMap += '\n' + chave + ':' + novoQuadroSocialComplemento.get(chave);
        }
        System.debug('\n<QUADRO L010120>\nretorno:'+retorno + outPutMap + '\n</QUADRO L010120>\n');
        */
        String rua = novoQuadroSocialComplemento.get('nomeLogradouro');
        String bairro = novoQuadroSocialComplemento.get('bairro');
        String cidade = novoQuadroSocialComplemento.get('cidade');
        String estado = novoQuadroSocialComplemento.get('estado');
        //String cepAux = removerZeros(novoQuadroSocialComplemento.get('cep'));
        String cepAux = novoQuadroSocialComplemento.get('cep');
        //String cep = cepAux.substring(0,cepAux.length() - 3) + '-' + cepAux.substring(cepAux.length() - 3,cepAux.length());
        String cep = '89056-300';
        String telefone = '(' + removerZeros(novoQuadroSocialComplemento.get('ddd')) + ') ' + removerZeros(novoQuadroSocialComplemento.get('telefone'));
        if(telefone == '(0) 0'){
            telefone = '';
        }
        String ramal = novoQuadroSocialComplemento.get('ramal');
        String ramoAtividade = novoQuadroSocialComplemento.get('ramoAtividade');
        String enderecoCompleto = rua + ', ' + bairro + ', ' + cidade + ', ' + estado + ', ' + cep;
        if(rua == ''){
            enderecoCompleto = '';
        }
        else{
            enderecoCompleto = rua + ', ' + bairro + ', ' + cidade + ', ' + estado + ', ' + cep;
        }
        
        if(enderecoCompleto.length() > 50){
            String novoEndereco = enderecoCompleto.substring(0,50) + '<br>' + enderecoCompleto.substring(50,enderecoCompleto.length());
            enderecoCompleto = novoEndereco;
        }
        
        /*
        result.quadroSocialAdministracaoMaisCompleto.put('Tabela-quadroSocialMaisCompleto',result.quadroSocialAdministracaoMaisCompleto.get('Tabela-quadroSocialMaisCompleto') + '<tr class="slds-line-height_reset"><td class="slds-cell-wrap" ><b>Endereço completo</b><td class="slds-cell-wrap" ><b>Telefone</b></td></td></tr>');
        result.quadroSocialAdministracaoMaisCompleto.put('Tabela-quadroSocialMaisCompleto',result.quadroSocialAdministracaoMaisCompleto.get('Tabela-quadroSocialMaisCompleto') + '<tr class="slds-line-height_reset"><td class="slds-cell-wrap" >' + enderecoCompleto + '</td><td class="slds-cell-wrap" >' + telefone + '</td></tr>');
        */

        String tabela = result.quadroSocialAdministracaoMaisCompleto.get('Tabela-quadroSocialMaisCompleto');
        tabela += ''+
        '<thead>'+
            '<tr class="slds-line-height_reset">'+
                '<th class="slds-cell-wrap" colspan=6>Endereço completo</th>'+
            '</tr>'+
        '</thead>'+
        '<tr class="slds-line-height_reset">'+
            '<td class="slds-cell-wrap" colspan=6>' + enderecoCompleto + '</td>'+
        '</tr>'+
        '<thead>'+
            '<tr class="slds-line-height_reset">'+
                '<th class="slds-cell-wrap" colspan=6>Telefone</th>'+
            '</tr>'+
        '</thead>'+
        '<tr class="slds-line-height_reset">'+
            '<td class="slds-cell-wrap" colspan=6>' + telefone + '</td>'+
        '</tr>';
        result.quadroSocialAdministracaoMaisCompleto.put('Tabela-quadroSocialMaisCompleto',tabela);
    } 



    //Renda Estimada-Sócios e Administrador PF
    public static void formatarL010118(String retorno, Relatorio result){

        //System.debug('AQUI L010118');
        Map<String,String> informacaoAdicionalSocioComplemento = new Map<String,String>();
        informacaoAdicionalSocioComplemento.put('descricaoCodigoElemento',retorno.substring(0,12).trim());
        informacaoAdicionalSocioComplemento.put('rendaMensal',retorno.substring(12,23).trim());
        informacaoAdicionalSocioComplemento.put('outraRenda',retorno.substring(23,34).trim());
        informacaoAdicionalSocioComplemento.put('codigoPeriodoOutraRenda',retorno.substring(34,46).trim());
        informacaoAdicionalSocioComplemento.put('origemOutraRenda',retorno.substring(46,58).trim());
        informacaoAdicionalSocioComplemento.put('cpfConjuge',retorno.substring(58,67).trim());
        informacaoAdicionalSocioComplemento.put('digitoCpfConjuge',retorno.substring(67,69).trim());
        informacaoAdicionalSocioComplemento.put('nomeConjuge',retorno.substring(69,129).trim());
        informacaoAdicionalSocioComplemento.put('rgConjuge',retorno.substring(129,140).trim());
        informacaoAdicionalSocioComplemento.put('rendaMensalConjuge',retorno.substring(140,151).trim());
        
        String cpf = 'não informado';
        if(result.informacoesSobreSociosAdministradores.containsKey('$' + result.informacoesSobreSociosAdministradores.get('$ultimoSocio'))){
            cpf = result.informacoesSobreSociosAdministradores.get('$' + result.informacoesSobreSociosAdministradores.get('$ultimoSocio'));
        }
        String ultimoSocio = result.informacoesSobreSociosAdministradores.get('$ultimoSocio');
        /*
        String outPutMap = '';
        for(String chave:informacaoAdicionalSocioComplemento.keyset()){
            outPutMap += '\n' + chave + ':' + informacaoAdicionalSocioComplemento.get(chave);
        }
        System.debug('\n\n<QUADRO L010118>\nultimoSocio:' + ultimoSocio + '\ncpf:' + cpf + '\nretorno:'+retorno + outPutMap + '\n</QUADRO L010118>\n\n');
        */
        /*
        if(result.informacoesSobreSociosAdministradores.containsKey('Tabela-RendaProSociosEAdministradoresPF')){
            //System.debug(result.informacoesSobreSociosAdministradores.get('Tabela-RendaProSociosEAdministradoresPF'));

            if(result.informacoesSobreSociosAdministradores.get('Tabela-RendaProSociosEAdministradoresPF').contains('EMPRESA NÃO POSSUI SÓCIOS OU ADMINISTRADORES PF')){
                result.informacoesSobreSociosAdministradores.put('Tabela-RendaProSociosEAdministradoresPF','');
            }
        }
        
        */
        /*
        if(result.informacoesSobreSociosAdministradores.containsKey('Tabela-RendaProSociosEAdministradoresPF')){
            if(result.informacoesSobreSociosAdministradores.get('Tabela-RendaProSociosEAdministradoresPF').contains('EMPRESA NÃO POSSUI SÓCIOS OU ADMINISTRADORES PF')){
                result.informacoesSobreSociosAdministradores.put('Tabela-RendaProSociosEAdministradoresPF','<thead><tr class="slds-line-height_reset"><th>CPF / CNPJ</th><th>Nome Completo</th><th>Faixas (em Reais)</th></tr></thead>');
            }
        }
        */
        String rendaMensal = removerZeros(informacaoAdicionalSocioComplemento.get('rendaMensal'));
        if( rendaMensal == '0' ){
            rendaMensal = 'Renda não calculada';
        }

        if(isIN(parametrosSelecionados,'Tabela-RendaProSociosEAdministradoresPF')){
            if(!result.informacoesSobreSociosAdministradores.containsKey('Tabela-RendaProSociosEAdministradoresPF')){
                String template = ''+
                '<thead>'+
                     '<tr class="slds-line-height_reset">'+
                         '<th>CPF / CNPJ</th>'+
                         '<th>Nome Completo</th>'+
                         '<th>Faixas (em Reais)</th>'+
                     '</tr>'+
                 '</thead>';
                 result.informacoesSobreSociosAdministradores.put('Tabela-RendaProSociosEAdministradoresPF',template);
            }

            String tabela = result.informacoesSobreSociosAdministradores.get('Tabela-RendaProSociosEAdministradoresPF');

            tabela += ''+
            
            '<tr class="slds-line-height_reset">'+
                '<td class="slds-cell-wrap" >' + cpf + '</td>'+
                '<td class="slds-cell-wrap" >' + ultimoSocio + '</td>'+
                '<td class="slds-cell-wrap" >' + rendaMensal + '</td>'+
            '</tr>';

            result.informacoesSobreSociosAdministradores.put('Tabela-RendaProSociosEAdministradoresPF',tabela);
        }

        

        

        
    }



    //alerta cadastral dos socios e administradores
    public static void initTabela_AlertaCadastralSocios(Relatorio result){
        if(!result.informacoesSobreSociosAdministradores.containsKey('Tabela-AlertaCadSociosAdms')){
            String tabela = ''+
            '<tr class="slds-line-height_reset">'+
                '<td class="slds-cell-wrap" ><b>Quadro Societário</b></td><td class="slds-cell-wrap" >$Quadro Societário</td>'+
            '</tr>'+
            '<tr class="slds-line-height_reset">'+
                '<td class="slds-cell-wrap" ><b>Quadro Administrativo</b></td><td class="slds-cell-wrap" >$Quadro Administrativo</td>'+
            '</tr>'+
            '<tr class="slds-line-height_reset">'+
                '<td class="slds-cell-wrap" ><b>Inconsistências Societárias</b></td><td class="slds-cell-wrap" >$Inconsistências Societárias</td>'+
            '</tr>'+
            '<tr class="slds-line-height_reset">'+
                '<td class="slds-cell-wrap" ><b>Inconsistências Administrativas</b></td><td class="slds-cell-wrap" >$Inconsistências Administrativas</td>'+
            '</tr>'+
            '<tr class="slds-line-height_reset">'+
                '<td class="slds-cell-wrap" ><b>Alerta de Óbito dos Sócios</b></td><td class="slds-cell-wrap" >$Alerta de Óbito dos Sócios</td>'+
            '</tr>'+

            '<tr class="slds-line-height_reset">'+
                '<td class="slds-cell-wrap" ><b>Alerta de Óbito dos Administradores</b></td><td class="slds-cell-wrap" >$Alerta de Óbito dos Administradores</td>'+
            '</tr>';

            //{'$Quadro Societário','$Quadro Administrativo','$Inconsistências Societárias','$Inconsistências Administrativas','$Alerta de Óbito dos Sócios','$Alerta de Óbito dos Administradores'}

            result.informacoesSobreSociosAdministradores.put('Tabela-AlertaCadSociosAdms',tabela);
        }
    }
    public static void formatarL610101(String retorno, Relatorio result){
        
        initTabela_AlertaCadastralSocios(result);

        Map<String,String> dadosConsultAlertaAlterSocios = new Map<String,String>();
        dadosConsultAlertaAlterSocios.put('codigoAlteracao',retorno.substring(0,3));
        dadosConsultAlertaAlterSocios.put('quantidadeAlertas',retorno.substring(3,12));
        dadosConsultAlertaAlterSocios.put('dataGeracaoAlerta',retorno.substring(12,20));
        dadosConsultAlertaAlterSocios.put('dataInicioPesquisaBase',retorno.substring(20,28));
        dadosConsultAlertaAlterSocios.put('dataFinalPesquisabase',retorno.substring(28,36));

        /*
        String outPutMap = '';
        for(String chave:dadosConsultAlertaAlterSocios.keyset()){
            outPutMap += '\n' + chave + ':' + dadosConsultAlertaAlterSocios.get(chave);
        }
        System.debug('\n<QUADRO L610101>\nretorno:'+retorno + outPutMap + '\n</QUADRO L610101>\n');
        */

        String quantidadeAlertas = removerZeros(dadosConsultAlertaAlterSocios.get('quantidadeAlertas'));
        Integer quantidadeAlertasCalc = Integer.valueOf(quantidadeAlertas);
        if(quantidadeAlertasCalc > 6){
            quantidadeAlertas = 'mais de 6'; 
        }

        //result.informacoesSobreSociosAdministradores.put('Tabela-AlertaCadSociosAdms',result.informacoesSobreSociosAdministradores.get('Tabela-AlertaCadSociosAdms') + '<tr class="slds-line-height_reset"><td class="slds-cell-wrap" ></td></tr>');

        String tabela = result.informacoesSobreSociosAdministradores.get('Tabela-AlertaCadSociosAdms');
        String mensagem = '<b>Foram identificadas ' + quantidadeAlertas + ' alterações nos últimos 12 (doze) meses.</b>$Quadro Societário';
        tabela = tabela.replace('$Quadro Societário',mensagem);
        result.informacoesSobreSociosAdministradores.put('Tabela-AlertaCadSociosAdms',tabela);
    }
    public static void formatarL610102(String retorno, Relatorio result){
        initTabela_AlertaCadastralSocios(result);
        
        Map<String,String> alteracaoSocios = new Map<String,String>();
        alteracaoSocios.put('codigoAlteracao',retorno.substring(0,3));
        alteracaoSocios.put('nome',retorno.substring(3,73));
        alteracaoSocios.put('cnpj',retorno.substring(73,82));
        alteracaoSocios.put('filial',retorno.substring(82,86));
        alteracaoSocios.put('digitoCnpj',retorno.substring(86,88));
        alteracaoSocios.put('tipoDocumento',retorno.substring(88,89));
        alteracaoSocios.put('indicadorEntradaSaida',retorno.substring(89,90));
        alteracaoSocios.put('dataEntradaSaida',retorno.substring(90,98));

        /*
        String outPutMap = '';
        for(String chave:alteracaoSocios.keyset()){
            outPutMap += '\n' + chave + ':' + alteracaoSocios.get(chave);
        }
        System.debug('\n<QUADRO L610102>\nretorno:'+retorno + outPutMap + '\n</QUADRO L610102>\n');
        */

        String nome = alteracaoSocios.get('nome');
        String data = formatarDataDDMMAAAA(alteracaoSocios.get('dataEntradaSaida'));
        String cnpj = formatarCpfOuCnpj(alteracaoSocios.get('cnpj')+alteracaoSocios.get('digitoCnpj'),alteracaoSocios.get('tipoDocumento'),alteracaoSocios.get('filial'));
        String tipoDocumento;
        switch on alteracaoSocios.get('tipoDocumento'){
            when 'F'{
                tipoDocumento = 'CPF';
            }
            when 'J'{
                tipoDocumento = 'CNPJ';
            }
        }
        String entradaOUsaida;
        switch on alteracaoSocios.get('indicadorEntradaSaida'){
            when 'E'{
                entradaOUsaida = 'entrou no quadro social em';
            }
            when 'S'{
                entradaOUsaida = 'saiu do quadro social em';
            }
        }

        String detalhe = nome + ' ' + tipoDocumento + ' ' + cnpj + ' ' + entradaOUsaida + ' ' + data;

        String tabela = result.informacoesSobreSociosAdministradores.get('Tabela-AlertaCadSociosAdms');
        String mensagem = '<br>' + detalhe + '$Quadro Societário';
        tabela = tabela.replace('$Quadro Societário',mensagem);
        result.informacoesSobreSociosAdministradores.put('Tabela-AlertaCadSociosAdms',tabela);

        //result.informacoesSobreSociosAdministradores.put('Tabela-AlertaCadSociosAdms',result.informacoesSobreSociosAdministradores.get('Tabela-AlertaCadSociosAdms') + '<tr class="slds-line-height_reset"><td class="slds-cell-wrap" ></td><td class="slds-cell-wrap" >' + detalhe + '</td></tr>');
    }
    public static void formatarL610199(String retorno, Relatorio result){
        initTabela_AlertaCadastralSocios(result);

        Map<String,String> mensagemAlteracaoDosSocios = new Map<String,String>();
        mensagemAlteracaoDosSocios.put('codigoAlteracao',retorno.substring(0,3).trim());
        mensagemAlteracaoDosSocios.put('mensagem',retorno.substring(3,retorno.length()).trim());
        /*
        String outPutMap = '';
        for(String chave:mensagemAlteracaoDosSocios.keyset()){
            outPutMap += '\n' + chave + ':' + mensagemAlteracaoDosSocios.get(chave);
        }
        System.debug('\n<QUADRO L610199>\nretorno:'+retorno + outPutMap + '\n</QUADRO L610199>\n');
        */
        String tabela = result.informacoesSobreSociosAdministradores.get('Tabela-AlertaCadSociosAdms');
        String mensagem = mensagemAlteracaoDosSocios.get('mensagem');
        tabela = tabela.replace('$Quadro Societário',mensagem);
        result.informacoesSobreSociosAdministradores.put('Tabela-AlertaCadSociosAdms',tabela);
    }
    public static void formatarL610201(String retorno, Relatorio result){
        initTabela_AlertaCadastralSocios(result);

        Map<String,String> dadosConsultAlertaAlterAdms = new Map<String,String>();
        dadosConsultAlertaAlterAdms.put('codigoAlteracao',retorno.substring(0,3));
        dadosConsultAlertaAlterAdms.put('quantidadeAlertas',retorno.substring(3,12));
        dadosConsultAlertaAlterAdms.put('dataGeracaoAlerta',retorno.substring(12,20));
        dadosConsultAlertaAlterAdms.put('dataInicioPesquisaBase',retorno.substring(20,28));
        dadosConsultAlertaAlterAdms.put('dataFinalPesquisabase',retorno.substring(28,36));
        /*
        String outPutMap = '';
        for(String chave:dadosConsultAlertaAlterAdms.keyset()){
            outPutMap += '\n' + chave + ':' + dadosConsultAlertaAlterAdms.get(chave);
        }
        System.debug('\n<QUADRO L610201>\nretorno:'+retorno + outPutMap + '\n</QUADRO L610201>\n');
        */

        

        String quantidadeAlertas = removerZeros(dadosConsultAlertaAlterAdms.get('quantidadeAlertas'));
        Integer quantidadeAlertasCalc = Integer.valueOf(quantidadeAlertas);
        if(quantidadeAlertasCalc > 6){
            quantidadeAlertas = 'mais de 6'; 
        }

        //result.informacoesSobreSociosAdministradores.put('Tabela-AlertaCadSociosAdms',result.informacoesSobreSociosAdministradores.get('Tabela-AlertaCadSociosAdms') + '<tr><td class="slds-cell-wrap" ></td></tr><tr class="slds-line-height_reset"><td class="slds-cell-wrap" ><b>Quadro Administrativo</b></td><td class="slds-cell-wrap" ><b>Foram identificadas ' + quantidadeAlertas + ' alterações nos últimos 12 (doze) meses.</b></td></tr>');

        String tabela = result.informacoesSobreSociosAdministradores.get('Tabela-AlertaCadSociosAdms');
        String alerta = '<b>Foram identificadas ' + quantidadeAlertas + ' alterações nos últimos 12 (doze) meses.</b>';
        tabela = tabela.replace('$Quadro Administrativo',alerta + '$Quadro Administrativo');
        result.informacoesSobreSociosAdministradores.put('Tabela-AlertaCadSociosAdms',tabela);
    }
    public static void formatarL610202(String retorno, Relatorio result){
        initTabela_AlertaCadastralSocios(result);

        Map<String,String> alteracaoAdms = new Map<String,String>();
        alteracaoAdms.put('codigoAlteracao',retorno.substring(0,3));
        alteracaoAdms.put('nome',retorno.substring(3,73));
        alteracaoAdms.put('cnpj',retorno.substring(73,82));
        alteracaoAdms.put('filial',retorno.substring(82,86));
        alteracaoAdms.put('digitoCnpj',retorno.substring(86,88));
        alteracaoAdms.put('tipoDocumento',retorno.substring(88,89));
        alteracaoAdms.put('indicadorEntradaSaida',retorno.substring(89,90));
        alteracaoAdms.put('dataEntradaSaida',retorno.substring(90,98));
        /*
        String outPutMap = '';
        for(String chave:alteracaoAdms.keyset()){
            outPutMap += '\n' + chave + ':' + alteracaoAdms.get(chave);
        }
        System.debug('\n<QUADRO L610202>\nretorno:'+retorno + outPutMap + '\n</QUADRO L610202>\n');
        */


        String nome = alteracaoAdms.get('nome');
        String data = formatarDataDDMMAAAA(alteracaoAdms.get('dataEntradaSaida'));
        String cnpj = formatarCpfOuCnpj(alteracaoAdms.get('cnpj')+alteracaoAdms.get('digitoCnpj'),alteracaoAdms.get('tipoDocumento'),alteracaoAdms.get('filial'));
        String tipoDocumento;
        switch on alteracaoAdms.get('tipoDocumento'){
            when 'F'{
                tipoDocumento = 'CPF';
            }
            when 'J'{
                tipoDocumento = 'CNPJ';
            }
        }
        String entradaOUsaida;
        switch on alteracaoAdms.get('indicadorEntradaSaida'){
            when 'E'{
                entradaOUsaida = 'entrou no quadro social em';
            }
            when 'S'{
                entradaOUsaida = 'saiu do quadro social em';
            }
        }

        String detalhe = '<br>' + nome + ' ' + tipoDocumento + ' ' + cnpj + ' ' + entradaOUsaida + ' ' + data;

        //result.informacoesSobreSociosAdministradores.put('Tabela-AlertaCadSociosAdms',result.informacoesSobreSociosAdministradores.get('Tabela-AlertaCadSociosAdms') + '<tr class="slds-line-height_reset"><td class="slds-cell-wrap" ></td><td class="slds-cell-wrap" >' + detalhe + '</td></tr>');
        String tabela = result.informacoesSobreSociosAdministradores.get('Tabela-AlertaCadSociosAdms');
        String alerta = detalhe;
        tabela = tabela.replace('$Quadro Administrativo',alerta + '$Quadro Administrativo');
        result.informacoesSobreSociosAdministradores.put('Tabela-AlertaCadSociosAdms',tabela);
    }
    public static void formatarL610299(String retorno, Relatorio result){
        initTabela_AlertaCadastralSocios(result);

        Map<String,String> mensagemQuadroAdministrativo = new Map<String,String>();
        mensagemQuadroAdministrativo.put('codigoAlteracao',retorno.substring(0,3).trim());
        mensagemQuadroAdministrativo.put('mensagem',retorno.substring(3,82).trim());
        /*
        String outPutMap = '';
        for(String chave:mensagemAlteracaoDosSocios.keyset()){
            outPutMap += '\n' + chave + ':' + mensagemAlteracaoDosSocios.get(chave);
        }
        System.debug('\n<QUADRO L610199>\nretorno:'+retorno + outPutMap + '\n</QUADRO L610199>\n');
        */
        String tabela = result.informacoesSobreSociosAdministradores.get('Tabela-AlertaCadSociosAdms');
        String mensagem = mensagemQuadroAdministrativo.get('mensagem');
        tabela = tabela.replace('$Quadro Administrativo',mensagem);
        result.informacoesSobreSociosAdministradores.put('Tabela-AlertaCadSociosAdms',tabela);
    }
    public static void formatarL610301(String retorno, Relatorio result){
        initTabela_AlertaCadastralSocios(result);

        Map<String,String> dadosConsultAlertaAlterInconsisSocietPJ = new Map<String,String>();
        dadosConsultAlertaAlterInconsisSocietPJ.put('codigoAlteracao',retorno.substring(0,3));
        dadosConsultAlertaAlterInconsisSocietPJ.put('quantidadeAlertas',retorno.substring(3,12));
        dadosConsultAlertaAlterInconsisSocietPJ.put('dataGeracaoAlerta',retorno.substring(12,20));
        dadosConsultAlertaAlterInconsisSocietPJ.put('dataInicioPesquisaBase',retorno.substring(20,28));
        dadosConsultAlertaAlterInconsisSocietPJ.put('dataFinalPesquisabase',retorno.substring(28,36));
        /*
        String outPutMap = '';
        for(String chave:dadosConsultAlertaAlterInconsisSocietPJ.keyset()){
            outPutMap += '\n' + chave + ':' + dadosConsultAlertaAlterInconsisSocietPJ.get(chave);
        }
        System.debug('\n<QUADRO L610301>\nretorno:'+retorno + outPutMap + '\n</QUADRO L610301>\n');
        */


        String quantidadeAlertas = removerZeros(dadosConsultAlertaAlterInconsisSocietPJ.get('quantidadeAlertas'));
        Integer quantidadeAlertasCalc = Integer.valueOf(quantidadeAlertas);
        if(quantidadeAlertasCalc > 6){
            quantidadeAlertas = 'mais de 6'; 
        }

        String mensagem;
        if(Integer.valueOf(dadosConsultAlertaAlterInconsisSocietPJ.get('quantidadeAlertas')) == 1){
            mensagem = 'Foi identificado 1 sócio com inconsistências comerciais.';
        }
        else{
            mensagem = 'Foram identificado ' + quantidadeAlertas + ' sócios com inconsistências comerciais.';
        }

        //result.informacoesSobreSociosAdministradores.put('Tabela-AlertaCadSociosAdms',result.informacoesSobreSociosAdministradores.get('Tabela-AlertaCadSociosAdms') + '<tr><td class="slds-cell-wrap" ></td></tr><tr class="slds-line-height_reset"><td class="slds-cell-wrap" ><b>Inconsistências Societárias</b></td><td class="slds-cell-wrap" ><b>' + mensagem + '</b></td></tr>');
        String tabela = result.informacoesSobreSociosAdministradores.get('Tabela-AlertaCadSociosAdms');
        String alerta = '<b>' + mensagem + '</b>';
        tabela = tabela.replace('$Inconsistências Societárias',alerta + '$Inconsistências Societárias');
        result.informacoesSobreSociosAdministradores.put('Tabela-AlertaCadSociosAdms',tabela);
    }
    public static void formatarL610302(String retorno, Relatorio result){
        initTabela_AlertaCadastralSocios(result);

        Map<String,String> alteracaoAdms = new Map<String,String>();
        alteracaoAdms.put('codigoAlteracao',retorno.substring(0,3));
        alteracaoAdms.put('codigoAlerta',retorno.substring(3,4));
        alteracaoAdms.put('nome',retorno.substring(4,74));
        alteracaoAdms.put('cnpj',retorno.substring(74,83));
        alteracaoAdms.put('digitoCnpj',retorno.substring(87,89));
        alteracaoAdms.put('tipoDocumento',retorno.substring(89,90));
        alteracaoAdms.put('fraseInconsistencia',retorno.substring(90,214));
        alteracaoAdms.put('dataEntradaSaida',retorno.substring(214,222));
        /*
        String outPutMap = '';
        for(String chave:alteracaoAdms.keyset()){
            outPutMap += '\n' + chave + ':' + alteracaoAdms.get(chave);
        }
        System.debug('\n<QUADRO L610302>\nretorno:'+retorno + outPutMap + '\n</QUADRO L610302>\n');
        */


        String nome = alteracaoAdms.get('nome');
        String data = formatarDataDDMMAAAA(alteracaoAdms.get('dataEntradaSaida'));
        String cnpj = formatarCpfOuCnpj(alteracaoAdms.get('cnpj')+alteracaoAdms.get('digitoCnpj'),alteracaoAdms.get('tipoDocumento'),'');
        String fraseInconsistencia = alteracaoAdms.get('fraseInconsistencia');
        String tipoDocumento;
        switch on alteracaoAdms.get('tipoDocumento'){
            when 'F'{
                tipoDocumento = 'CPF';
            }
            when 'J'{
                tipoDocumento = 'CNPJ';
            }
        }

        String detalhe = '<br>' + tipoDocumento + ' ' +  cnpj + ' ' + nome + ' ' + fraseInconsistencia;
        /*
        result.informacoesSobreSociosAdministradores.put('Tabela-AlertaCadSociosAdms',result.informacoesSobreSociosAdministradores.get('Tabela-AlertaCadSociosAdms') + '<tr class="slds-line-height_reset"><td class="slds-cell-wrap" ></td><td class="slds-cell-wrap" >' + detalhe + '</td></tr>');
        */
        String tabela = result.informacoesSobreSociosAdministradores.get('Tabela-AlertaCadSociosAdms');
        String alerta = detalhe;
        tabela = tabela.replace('$Inconsistências Societárias',alerta + '$Inconsistências Societárias');
        result.informacoesSobreSociosAdministradores.put('Tabela-AlertaCadSociosAdms',tabela);
    }
    public static void formatarL610399(String retorno, Relatorio result){
        initTabela_AlertaCadastralSocios(result);

        Map<String,String> mensagemInconsistenciaSocietaria = new Map<String,String>();
        mensagemInconsistenciaSocietaria.put('codigoAlteracao',retorno.substring(0,3).trim());
        mensagemInconsistenciaSocietaria.put('mensagem',retorno.substring(3,82).trim());
        /*
        String outPutMap = '';
        for(String chave:mensagemInconsistenciaSocietaria.keyset()){
            outPutMap += '\n' + chave + ':' + mensagemInconsistenciaSocietaria.get(chave);
        }
        System.debug('\n<QUADRO L610399>\nretorno:'+retorno + outPutMap + '\n</QUADRO L610399>\n');
        */
        String tabela = result.informacoesSobreSociosAdministradores.get('Tabela-AlertaCadSociosAdms');
        String mensagem = mensagemInconsistenciaSocietaria.get('mensagem');
        tabela = tabela.replace('$Inconsistências Societárias',mensagem);
        result.informacoesSobreSociosAdministradores.put('Tabela-AlertaCadSociosAdms',tabela);
    }
    public static void formatarL610499(String retorno, Relatorio result){
        initTabela_AlertaCadastralSocios(result);

        Map<String,String> alertaCadSociosAdmsMsg = new Map<String,String>();
        alertaCadSociosAdmsMsg.put('codigoAlteracao',retorno.substring(0,3));
        alertaCadSociosAdmsMsg.put('mensagem',retorno.substring(3,82));
        /*
        String outPutMap = '';
        for(String chave:alertaCadSociosAdmsMsg.keyset()){
            outPutMap += '\n' + chave + ':' + alertaCadSociosAdmsMsg.get(chave);
        }
        System.debug('\n<QUADRO L610499>\nretorno:'+retorno + outPutMap + '\n</QUADRO L610499>\n');
        */

        String mensagem = alertaCadSociosAdmsMsg.get('mensagem');
        String tabela = result.informacoesSobreSociosAdministradores.get('Tabela-AlertaCadSociosAdms');
        tabela = tabela.replace('$Inconsistências Administrativas',mensagem);
        result.informacoesSobreSociosAdministradores.put('Tabela-AlertaCadSociosAdms',tabela);
    }
    public static void formatarL610599(String retorno, Relatorio result){
        initTabela_AlertaCadastralSocios(result);

        Map<String,String> alertaCadSociosAdmsMsg = new Map<String,String>();
        alertaCadSociosAdmsMsg.put('codigoAlteracao',retorno.substring(0,3));
        alertaCadSociosAdmsMsg.put('mensagem',retorno.substring(3,82));
        /*
        String outPutMap = '';
        for(String chave:alertaCadSociosAdmsMsg.keyset()){
            outPutMap += '\n' + chave + ':' + alertaCadSociosAdmsMsg.get(chave);
        }
        System.debug('\n<QUADRO L610599>\nretorno:'+retorno + outPutMap + '\n</QUADRO L610599>\n'); 
        */

        String mensagem = alertaCadSociosAdmsMsg.get('mensagem');
        String tabela = result.informacoesSobreSociosAdministradores.get('Tabela-AlertaCadSociosAdms');
        tabela = tabela.replace('$Alerta de Óbito dos Sócios',mensagem);
        result.informacoesSobreSociosAdministradores.put('Tabela-AlertaCadSociosAdms',tabela);
    }
    public static void formatarL610699(String retorno, Relatorio result){
        initTabela_AlertaCadastralSocios(result);

        Map<String,String> alertaCadSociosAdmsMsg = new Map<String,String>();
        alertaCadSociosAdmsMsg.put('codigoAlteracao',retorno.substring(0,3));
        alertaCadSociosAdmsMsg.put('mensagem',retorno.substring(3,82));
        /*
        String outPutMap = '';
        for(String chave:alertaCadSociosAdmsMsg.keyset()){
            outPutMap += '\n' + chave + ':' + alertaCadSociosAdmsMsg.get(chave);
        }
        System.debug('\n<QUADRO L610699>\nretorno:'+retorno + outPutMap + '\n</QUADRO L610699>\n'); 
        */
        String mensagem = alertaCadSociosAdmsMsg.get('mensagem');
        String tabela = result.informacoesSobreSociosAdministradores.get('Tabela-AlertaCadSociosAdms');
        tabela = tabela.replace('$Alerta de Óbito dos Administradores',mensagem);
        result.informacoesSobreSociosAdministradores.put('Tabela-AlertaCadSociosAdms',tabela);
    }



    //Serasa Score – Socios PF
    public static void formatarL070401(String retorno, Relatorio result){

        Map<String,String> scoreSocio = new Map<String,String>();
        scoreSocio.put('tipoPessoa',retorno.substring(0,1).trim());
        scoreSocio.put('cpf',retorno.substring(1,10).trim());
        scoreSocio.put('filial',retorno.substring(10,14).trim());
        scoreSocio.put('digito',retorno.substring(14,16).trim());
        scoreSocio.put('sequencia',retorno.substring(16,20).trim());
        scoreSocio.put('vinculo',retorno.substring(20,21).trim());
        scoreSocio.put('nome',retorno.substring(21,91).trim());
        scoreSocio.put('fator',retorno.substring(91,97).trim());
        scoreSocio.put('faixa',retorno.substring(97,103).trim());
        scoreSocio.put('taxa',retorno.substring(103,108).trim());
        scoreSocio.put('data',retorno.substring(108,116).trim());
        scoreSocio.put('hora',retorno.substring(116,124).trim());
        scoreSocio.put('codigoMensagem',retorno.substring(124,130).trim());
        scoreSocio.put('descricaoMensagem',retorno.substring(130,180).trim());
        scoreSocio.put('areaReservada',retorno.substring(180,186).trim());
        /*
        String outPutMap = '';
        for(String chave:scoreSocio.keyset()){
            outPutMap += '\n' + chave + ':' + scoreSocio.get(chave);
        }
        System.debug( '\n<QUADRO L070401>\nretorno:' + retorno + outPutMap + '\n</QUADRO L070401>\n' );
        */
        if(!result.informacoesSobreSociosAdministradores.containsKey('Tabela-ScoreSociosPF')){
            result.informacoesSobreSociosAdministradores.put('Tabela-ScoreSociosPF','<thead><tr class="slds-line-height_reset"><th>CPF</th><th>Nome</th><th>Score</th><th>Chance de pagamento</th></tr></thead>');
        }

        String nome = scoreSocio.get('nome');
        String cpf = formatarCpfOuCnpj( scoreSocio.get('cpf') + scoreSocio.get('digito') , 'F' , scoreSocio.get('filial') );
        String score = removerZeros(scoreSocio.get('fator'));
        Integer scoreCalculo = Integer.valueOf(score);
        String probabilidade;
        if(scoreCalculo < 301){
            probabilidade = 'ruim';
        }
        else if(scoreCalculo < 501){
            probabilidade = 'regular';
        }
        else if(scoreCalculo < 701){
            probabilidade = 'boa';
        }
        else{
            probabilidade = 'muito boa';
        }

        result.informacoesSobreSociosAdministradores.put('Tabela-ScoreSociosPF',result.informacoesSobreSociosAdministradores.get('Tabela-ScoreSociosPF') + '<tr><td class="slds-cell-wrap" >' + cpf + '</td><td class="slds-cell-wrap" >' + nome + '</td><td class="slds-cell-wrap" >' + score + '</td><td class="slds-cell-wrap" >' + probabilidade + '</td></tr>');        
    }
    public static void formatarL070499(String retorno, Relatorio result){
        
        Map<String,String> mensagemNaoCalculo = new Map<String,String>();
        mensagemNaoCalculo.put('dataConsulta',retorno.substring(0,8));
        mensagemNaoCalculo.put('hora',retorno.substring(8,16));
        mensagemNaoCalculo.put('naoSeiOkEh',retorno.substring(16,21));
        mensagemNaoCalculo.put('mensagem',retorno.substring(21,retorno.length()));
        /*
        String outPutMap = '';
        for(String chave:mensagemNaoCalculo.keyset()){
            outPutMap += '\n' + chave + ':' + mensagemNaoCalculo.get(chave);
        }
        System.debug( '\n<QUADRO L070499>\nretorno:' + retorno + outPutMap + '\n</QUADRO L070499>\n' );
        */
        String mensagem = mensagemNaoCalculo.get('mensagem');
        if(!result.informacoesSobreSociosAdministradores.containsKey('Tabela-ScoreSociosPF')){
            result.informacoesSobreSociosAdministradores.put('Tabela-ScoreSociosPF','<thead><tr class="slds-line-height_reset"><td class="slds-cell-wrap" >' + mensagem + '</td></tr></thead>');
        }
    }



    //Índice Relacionamento Mercado e Setor
    public static void formatarL301399(String retorno, Relatorio result){

        Map<String,String> mensagemIndiceRelacMercadoSetor = new Map<String,String>();
        mensagemIndiceRelacMercadoSetor.put('codigoRetorno',retorno.substring(0,2).trim());
        mensagemIndiceRelacMercadoSetor.put('mensagem',retorno.substring(2,82).trim());
        /*
        String outPutMap = '';
        for(String chave:mensagemIndiceRelacMercadoSetor.keyset()){
            outPutMap += '\n' + chave + ':' + mensagemIndiceRelacMercadoSetor.get(chave);
        }
        System.debug('\n\n<QUADRO L301399>\nretorno:'+retorno + outPutMap + '\n</QUADRO L301399>\n\n');
        */
        String mensagem = mensagemIndiceRelacMercadoSetor.get('mensagem');
        if(!result.InformacoesSobreConsultas.containsKey('Tabela-IndiceRelacMercadoSetor')){
            result.InformacoesSobreConsultas.put('Tabela-IndiceRelacMercadoSetor','<tr class="slds-line-height_reset"><td class="slds-cell-wrap" >' + mensagem + '</td></tr>');
        }

        /*
        if(!result.InformacoesSobreConsultas.containsKey('Tabela-SerasaScoreSetorial')){
            result.InformacoesSobreConsultas.put('Tabela-SerasaScoreSetorial','<tr class="slds-line-height_reset"><td class="slds-cell-wrap" >' + mensagem + '</td></tr>');
        }   
        */
    }
    public static void formatarL301301(String retorno, Relatorio result) {

        Map<String,String> indiceRelacMercSetorGeral = new Map<String,String>();
        indiceRelacMercSetorGeral.put('codigoSetor',retorno.substring(0,4).trim());
        indiceRelacMercSetorGeral.put('codigoGrauRelacionamento',retorno.substring(4,8).trim());
        indiceRelacMercSetorGeral.put('mensagem',retorno.substring(8,retorno.length()).trim());
        /*
        String outPutMap = '';
        for(String chave:indiceRelacMercSetorGeral.keyset()){
            outPutMap += '\n' + chave + ':' + indiceRelacMercSetorGeral.get(chave);
        }
        System.debug( '\n\n<QUADRO L301301>\nretorno:' + retorno + outPutMap + '\n</QUADRO L301301>\n\n' );   
        */
        if(!result.InformacoesSobreConsultas.containsKey('Tabela-IndiceRelacMercadoSetor')){
            result.InformacoesSobreConsultas.put('Tabela-IndiceRelacMercadoSetor','');
        } 

        String setor;
        switch on removerZeros(indiceRelacMercSetorGeral.get('codigoSetor')){
            when '0'{setor = 'Geral';}
            when '1'{setor = 'Atacado';}
            when '2'{setor = 'Bancos / Financeiras';}
            when '3'{setor = 'Serviços';}
            when '4'{setor = 'Comércio';}
            when '5'{setor = 'Industria';}
            when '6'{setor = 'Factoring';}
            when '8'{setor = 'Outros';}
            when else{setor = 'INDEFINIDO';}
        }
        String codigoSetor = indiceRelacMercSetorGeral.get('codigoSetor');
        String codigoRelacionamento = indiceRelacMercSetorGeral.get('codigoGrauRelacionamento');
        String mensagem = indiceRelacMercSetorGeral.get('mensagem');

        String tabela = result.InformacoesSobreConsultas.get('Tabela-IndiceRelacMercadoSetor');

        tabela += ''+
        '<tr class="slds-line-height_reset">'+
            '<td class="slds-cell-wrap" >'+
                '<dl style="margin-left:50px;margin-right:50px;margin-bottom:10px;padding:10px;margin-top:10px;border:gray solid 1px">'+
                    '<dt><b>'+ setor +'</b></dt>'+
                        '<dd style="margin-left:30px"><b>Relacionamento: </b>'+ codigoRelacionamento +'</dd>'+
                        '<dd style="margin-left:30px"><b>Mensagem: </b>'+ mensagem +'</dd>'+
                '</dl>'+
            '</td>'+
        '</tr>';

        result.InformacoesSobreConsultas.put('Tabela-IndiceRelacMercadoSetor',tabela);
    } 



    //Consultas Detalhadas à Serasa
    public static void formatarL030399(String retorno, Relatorio result){

        Map<String,String> dataAtualizacaoInformacoesGerais = new Map<String,String>();
        dataAtualizacaoInformacoesGerais.put('dataAtualizacao',retorno.substring(0,10).trim());
        dataAtualizacaoInformacoesGerais.put('areaReservada',retorno.substring(10,retorno.length()).trim());
        /*
        String outPutMap = '';
        for(String chave:dataAtualizacaoInformacoesGerais.keyset()){
            outPutMap += '\n' + chave + ':' + dataAtualizacaoInformacoesGerais.get(chave);
        }
        System.debug('\n\n<QUADRO L030399>\nretorno:'+retorno + outPutMap + '\n</QUADRO L030399>\n\n');
        */
    }
    public static void formatarL030303(String retorno, Relatorio result){

        Map<String,String> ultimasConsultas = new Map<String,String>();
        ultimasConsultas.put('codigoSegmento',retorno.substring(0,4).trim());
        ultimasConsultas.put('descricaoSegmento',retorno.substring(4,29).trim());
        ultimasConsultas.put('dataConsulta',retorno.substring(29,37).trim());
        ultimasConsultas.put('cnpjConsultante',retorno.substring(37,45).trim());
        ultimasConsultas.put('filialConsultante',retorno.substring(45,49).trim());
        ultimasConsultas.put('digitoConsultante',retorno.substring(49,51).trim());
        ultimasConsultas.put('razaoSocialConsultante',retorno.substring(51,121).trim());
        ultimasConsultas.put('quantidadeConsultas',retorno.substring(121,129).trim());
        ultimasConsultas.put('tipoConsulta',retorno.substring(129,retorno.length()).trim());
        /*
        String outPutMap = '';
        for(String chave:ultimasConsultas.keyset()){
            outPutMap += '\n' + chave + ':' + ultimasConsultas.get(chave);
        }
        System.debug('\n\n<QUADRO L030303>\nretorno:'+retorno + outPutMap + '\n</QUADRO L030303>\n\n');
        */
        if(!result.InformacoesSobreConsultas.containsKey('Tabela-ConsultasDetalhadas')){
            result.InformacoesSobreConsultas.put('Tabela-ConsultasDetalhadas','<thead><tr class="slds-line-height_reset"><th>Data da Consulta</th><th>CNPJ do Consultante</th><th>Razão Social do Consultante</th><th>Qtd</th></tr></thead>');
        }

        String data = formatarDataAAAAMMDD(ultimasConsultas.get('dataConsulta'));
        //String cnpj = '113.139.939-05';
        String cnpj = formatarCpfOuCnpj( '0' + ultimasConsultas.get('cnpjConsultante') + ultimasConsultas.get('digitoConsultante') , 'J' , ultimasConsultas.get('filialConsultante') );
        String razaoSocial = ultimasConsultas.get('razaoSocialConsultante');
        String quantidade = removerZeros(ultimasConsultas.get('quantidadeConsultas'));

        result.InformacoesSobreConsultas.put('Tabela-ConsultasDetalhadas',result.InformacoesSobreConsultas.get('Tabela-ConsultasDetalhadas') + '<tr class="slds-line-height_reset"><td class="slds-cell-wrap" >' + data + '</td><td class="slds-cell-wrap" >' + cnpj + '</td><td class="slds-cell-wrap" >' + razaoSocial + '</td><td class="slds-cell-wrap" >' + quantidade + '</td></tr>');
    }



    //Comportamento de Pagamento do Setor
    public static void formatarL310199(String retorno, Relatorio result){
        
        result.pagamentoFinanceiroAvancado.put('','');

        Map<String,String> mensagemNaoCalculo = new Map<String,String>();
        mensagemNaoCalculo.put('dataReferencia',retorno.substring(0,8).trim());
        mensagemNaoCalculo.put('codigoMensagem',retorno.substring(8,13).trim());
        mensagemNaoCalculo.put('textoMensagem',retorno.substring(13,93).trim());
        /*
        String outPutMap = '';
        for(String chave:mensagemNaoCalculo.keyset()){
            outPutMap += '\n' + chave + ':' + mensagemNaoCalculo.get(chave);
        }
        System.debug('\n\n<QUADRO L310199>\nretorno:'+retorno + outPutMap + '\n</QUADRO L310199>\n\n');
        */
        String mensagem = mensagemNaoCalculo.get('textoMensagem');

        if(!result.pagamentoFinanceiroAvancado.containsKey('Tabela-ComportamentoPagamentoSetor')){
            result.pagamentoFinanceiroAvancado.put('Tabela-ComportamentoPagamentoSetor','');
        }
        result.pagamentoFinanceiroAvancado.put('Tabela-ComportamentoPagamentoSetor','<tr class="slds-line-height_reset"><td class="slds-cell-wrap" >' + mensagem + '</td></tr>');

        /*
        if(!result.pagamentoFinanceiroAvancado.containsKey('Tabela-SerasaScoreSetorial')){
            result.pagamentoFinanceiroAvancado.put('Tabela-SerasaScoreSetorial','');
        }
        result.pagamentoFinanceiroAvancado.put('Tabela-SerasaScoreSetorial','<tr class="slds-line-height_reset"><td class="slds-cell-wrap" >' + mensagem + '</td></tr>');
        */
    }
    public static void formatarL310101(String retorno, Relatorio result){
        
        Map<String,String> atrasosPagamentos = new Map<String,String>();
        atrasosPagamentos.put('dataReferencia',retorno.substring(0,8).trim());
        atrasosPagamentos.put('percentualAVista',retorno.substring(8,13).trim());
        atrasosPagamentos.put('valorMediaAvista',retorno.substring(13,30).trim());
        atrasosPagamentos.put('percentual8a15',retorno.substring(30,35).trim());
        atrasosPagamentos.put('media8a15',retorno.substring(35,52).trim());
        atrasosPagamentos.put('percentual16a30',retorno.substring(52,57).trim());
        atrasosPagamentos.put('valorMedia16a30',retorno.substring(57,74).trim());
        atrasosPagamentos.put('percentual31a60',retorno.substring(74,79).trim());
        atrasosPagamentos.put('valorMedia31a60',retorno.substring(79,96).trim());
        atrasosPagamentos.put('percentualAcima60',retorno.substring(96,101).trim());
        atrasosPagamentos.put('valorMeidaAcima60',retorno.substring(101,118).trim());
        atrasosPagamentos.put('percentualTotal',retorno.substring(118,123).trim());
        atrasosPagamentos.put('valorMediaTotal',retorno.substring(123,140).trim());
        atrasosPagamentos.put('prazoMediaAtraso',retorno.substring(140,145).trim());
        /*
        String outPutMap = '';
        for(String chave:atrasosPagamentos.keyset()){
            outPutMap += '\n' + chave + ':' + atrasosPagamentos.get(chave);
        }
        System.debug('\n\n<QUADRO L310101>\nretorno:'+retorno + outPutMap + '\n</QUADRO L310101>\n\n');
        */
        if(!result.pagamentoFinanceiroAvancado.containsKey('Tabela-ComportamentoPagamentoSetor')){
            result.pagamentoFinanceiroAvancado.put('Tabela-ComportamentoPagamentoSetor','');
        }

        String percentualAVista = formatarValor(atrasosPagamentos.get('percentualAVista'),2);
        String valorMediaAvista = formatarValor(atrasosPagamentos.get('valorMediaAvista'),2);
        String percentual8a15 = formatarValor(atrasosPagamentos.get('percentual8a15'),2);
        String valorMedia8a15 = formatarValor(atrasosPagamentos.get('media8a15'),2);
        String percentual16a30 = formatarValor(atrasosPagamentos.get('percentual16a30'),2);
        String valorMedia16a30 = formatarValor(atrasosPagamentos.get('valorMedia16a30'),2);
        String percentual31a60 = formatarValor(atrasosPagamentos.get('percentual31a60'),2);
        String valorMedia31a60 = formatarValor(atrasosPagamentos.get('valorMedia31a60'),2);
        String percentualAcima60 = formatarValor(atrasosPagamentos.get('percentualAcima60'),2);
        String valorMediaAcima60 = formatarValor(atrasosPagamentos.get('valorMeidaAcima60'),2);
        String percentualTotal = formatarValor(atrasosPagamentos.get('percentualTotal'),2);
        String valorMediaTotal = formatarValor(atrasosPagamentos.get('valorMediaTotal'),2);
        String prazoMediaAtraso = formatarValor(atrasosPagamentos.get('prazoMediaAtraso'),2);

        String tabela = result.pagamentoFinanceiroAvancado.get('Tabela-ComportamentoPagamentoSetor');
        tabela += ''+
        '<tr class="slds-line-height_reset">'+
            '<td class="slds-cell-wrap" >'+
                '<dl style="margin-left:50px;margin-right:50px;margin-bottom:10px;padding:10px;margin-top:10px;border:gray solid 1px">'+
                    '<dt><b>Comportamento de Pagamento</b></dt>'+
                        
                        '<dd style="margin-left:30px;margin-top:10px"><b>Valor media a vista: </b>R$ '+ valorMediaAvista +'</dd>'+
                        '<dd style="margin-left:30px"><b>Percentual media a vista: </b>'+ percentualAVista +'%</dd>'+

                        '<dd style="margin-left:30px;margin-top:10px"><b>Valor de 8 a 15 dias: </b>R$ '+ valorMedia8a15 +'</dd>'+
                        '<dd style="margin-left:30px"><b>Percentual de 8 a a15 dias: </b>'+ percentual8a15 +'%</dd>'+

                        '<dd style="margin-left:30px;margin-top:10px"><b>Valor media de 16 a 30 dias: </b>R$ '+ valorMedia16a30 +'</dd>'+
                        '<dd style="margin-left:30px"><b>Percentual de 16 a 30 dias: </b>'+ percentual16a30 +'%</dd>'+

                        '<dd style="margin-left:30px;margin-top:10px"><b>Valor media de 31 a 60 dias: </b>R$ '+ valorMedia31a60 +'</dd>'+
                        '<dd style="margin-left:30px"><b>Percentual de 31 a 60 dias: </b>'+ percentual31a60 +'%</dd>'+

                        '<dd style="margin-left:30px;margin-top:10px"><b>Valor acima de 60 dias: </b>R$ '+ valorMediaAcima60 +'</dd>'+
                        '<dd style="margin-left:30px"><b>Percentual acima de 60 dias: </b>'+ percentualAcima60 +'%</dd>'+

                        '<dd style="margin-left:30px;margin-top:10px"><b>Valor media total: </b>R$ '+ valorMediaTotal +'%</dd>'+
                        '<dd style="margin-left:30px"><b>Percentual total: </b>'+ percentualTotal +'%</dd>'+
                        '<dd style="margin-left:30px"><b>Media de prazo de atraso: </b>R$ '+ prazoMediaAtraso +'</dd>'+

                '</dl>'+
            '</td>'+
        '</tr>';

        result.pagamentoFinanceiroAvancado.put('Tabela-ComportamentoPagamentoSetor',tabela);
    }
    public static void formatarL310102(String retorno, Relatorio result){
        
        Map<String,String> vencimentosFuturosPagamentos = new Map<String,String>();
        vencimentosFuturosPagamentos.put('dataReferencia',retorno.substring(0,8).trim());
        vencimentosFuturosPagamentos.put('percentualAte10',retorno.substring(8,13).trim());
        vencimentosFuturosPagamentos.put('valorMediaAte10',retorno.substring(13,30).trim());
        vencimentosFuturosPagamentos.put('percentual11a30',retorno.substring(30,35).trim());
        vencimentosFuturosPagamentos.put('valorMedia11a30',retorno.substring(35,52).trim());
        vencimentosFuturosPagamentos.put('percentual31a45',retorno.substring(52,57).trim());
        vencimentosFuturosPagamentos.put('valorMedia31a45',retorno.substring(57,74).trim());
        vencimentosFuturosPagamentos.put('percentual46a60',retorno.substring(74,79).trim());
        vencimentosFuturosPagamentos.put('valorMedia46a60',retorno.substring(79,96).trim());
        vencimentosFuturosPagamentos.put('percentualAcima60',retorno.substring(96,101).trim());
        vencimentosFuturosPagamentos.put('valorMeidaAcima60',retorno.substring(101,118).trim());
        vencimentosFuturosPagamentos.put('percentualTotal',retorno.substring(118,123).trim());
        vencimentosFuturosPagamentos.put('valorMediaTotal',retorno.substring(123,140).trim());
        /*
        String outPutMap = '';
        for(String chave:vencimentosFuturosPagamentos.keyset()){
            outPutMap += '\n' + chave + ':' + vencimentosFuturosPagamentos.get(chave);
        }
        System.debug('\n\n<QUADRO L310102>\nretorno:'+retorno + outPutMap + '\n</QUADRO L310102>\n\n');
        */
        String dataReferencia = formatarValor(vencimentosFuturosPagamentos.get('dataReferencia'),2);
        String percentualAte10 = formatarValor(vencimentosFuturosPagamentos.get('percentualAte10'),2);
        String valorMediaAte10 = formatarValor(vencimentosFuturosPagamentos.get('valorMediaAte10'),2);
        String percentual11a30 = formatarValor(vencimentosFuturosPagamentos.get('percentual11a30'),2);
        String valorMedia11a30 = formatarValor(vencimentosFuturosPagamentos.get('valorMedia11a30'),2);
        String percentual31a45 = formatarValor(vencimentosFuturosPagamentos.get('percentual31a45'),2);
        String valorMedia31a45 = formatarValor(vencimentosFuturosPagamentos.get('valorMedia31a45'),2);
        String percentual46a60 = formatarValor(vencimentosFuturosPagamentos.get('percentual46a60'),2);
        String valorMedia46a60 = formatarValor(vencimentosFuturosPagamentos.get('valorMedia46a60'),2);
        String percentualAcima60 = formatarValor(vencimentosFuturosPagamentos.get('percentualAcima60'),2);
        String valorMediaAcima60 = formatarValor(vencimentosFuturosPagamentos.get('valorMeidaAcima60'),2);
        String percentualTotal = formatarValor(vencimentosFuturosPagamentos.get('percentualTotal'),2);
        String valorMediaTotal = formatarValor(vencimentosFuturosPagamentos.get('valorMediaTotal'),2);

        String tabela = result.pagamentoFinanceiroAvancado.get('Tabela-ComportamentoPagamentoSetor');
        tabela += ''+
        '<tr class="slds-line-height_reset">'+
            '<td class="slds-cell-wrap" >'+
                '<dl style="margin-left:50px;margin-right:50px;margin-bottom:10px;padding:10px;margin-top:10px;border:gray solid 1px">'+
                    '<dt><b>Comportamento de Pagamento</b></dt>'+
                        
                        '<dd style="margin-left:30px;margin-top:10px"><b>Valor media até 10 dias: </b>R$ '+ valorMediaAte10 +'</dd>'+
                        '<dd style="margin-left:30px"><b>Percentual media até 10 dias: </b>'+ percentualAte10 +'%</dd>'+

                        '<dd style="margin-left:30px;margin-top:10px"><b>Valor de 11 a 30 dias: </b>R$ '+ valorMedia11a30 +'</dd>'+
                        '<dd style="margin-left:30px"><b>Percentual de 11 a 30 dias: </b>'+ percentual11a30 +'%</dd>'+

                        '<dd style="margin-left:30px;margin-top:10px"><b>Valor media de 31 a 45 dias: </b>R$ '+ valorMedia31a45 +'</dd>'+
                        '<dd style="margin-left:30px"><b>Percentual de 31 a 45 dias: </b>'+ percentual31a45 +'%</dd>'+

                        '<dd style="margin-left:30px;margin-top:10px"><b>Valor media de 36 a 60 dias: </b>R$ '+ valorMedia46a60 +'</dd>'+
                        '<dd style="margin-left:30px"><b>Percentual de 46 a 60 dias: </b>'+ percentual46a60 +'%</dd>'+

                        '<dd style="margin-left:30px;margin-top:10px"><b>Valor acima de 60 dias: </b>R$ '+ valorMediaAcima60 +'</dd>'+
                        '<dd style="margin-left:30px"><b>Percentual acima de 60 dias: </b>'+ percentualAcima60 +'%</dd>'+

                        '<dd style="margin-left:30px;margin-top:10px"><b>Valor media total: </b>R$ '+ valorMediaTotal +'</dd>'+
                        '<dd style="margin-left:30px"><b>Percentual total: </b>'+ percentualTotal +'%</dd>'+

                '</dl>'+
            '</td>'+
        '</tr>';

        result.pagamentoFinanceiroAvancado.put('Tabela-ComportamentoPagamentoSetor',tabela);
    }
    


    //situacao fiscal
    public static void initTabela_SituacaoFiscal(Relatorio result){
        
        if(!result.dadosCadEmp.containsKey('Tabela-SituacaoFiscal')){
            String tabela = ''+
            '<thead>'+
                '<tr class="slds-line-height_reset" style="border-top:solid gray 1px">'+
                    '<td class="slds-cell-wrap" colspan=3><b>Na Receita Federal em $dataConsultaReceita</b></td>'+
                '</tr>'+
            '</thead>'+
            '<thead>'+
                '<tr class="slds-line-height_reset">'+
                    '<th class="slds-cell-wrap" >CNPJ</th>'+
                    '<th class="slds-cell-wrap" >SIMPLES Nacional</th>'+
                    '<th class="slds-cell-wrap" >Situação Cadastral do CNPJ</th>'+
                '</tr>'+
            '</thead>'+
            '<tr class="slds-line-height_reset">'+
                '<td class="slds-cell-wrap" >$cnpjReceita</td>'+
                '<td class="slds-cell-wrap" >$simplesNacionalReceita</td>'+
                '<td class="slds-cell-wrap" >$situacaoCNPJReceita</td>'+
            '</tr>'+
            '<thead>'+
                '<tr class="slds-line-height_reset">'+
                    '<th class="slds-cell-wrap" colspan=3>Razão SocialReceita</th>'+
                '</tr>'+
            '</thead>'+
            '<tr class="slds-line-height_reset">'+
                '<td class="slds-cell-wrap" colspan=3>$razaoSocialReceita</td>'+
            '</tr>'+
            '<thead>'+
                '<tr class="slds-line-height_reset">'+
                    '<th class="slds-cell-wrap" colspan=3>CNAE PRIMÁRIO</th>'+
                '</tr>'+
            '</thead>'+
            '<tr class="slds-line-height_reset">'+
                '<td class="slds-cell-wrap" colspan=3>$cnpaPrimariaReceita</td>'+
            '</tr>'+
            '<thead>'+
                '<tr class="slds-line-height_reset">'+
                    '<th class="slds-cell-wrap" colspan=3>CNAEs Secundários</b></th>'+
                '</tr>'+
            '</thead>'+
            '<tr class="slds-line-height_reset">'+
                '<td class="slds-cell-wrap" colspan=3>$cnaeSecundariaReceita</td>'+
            '</tr>'+


            '<tr class="slds-line-height_reset">'+
                '<td class="slds-cell-wrap" style="border-top:solid gray 1px" colspan=3><b>Na Secretaria da Fazenda em $dataConsultaSecretaria</b></td>'+
            '</tr>'+
            '<thead>'+
                '<tr class="slds-line-height_reset">'+
                    '<th class="slds-cell-wrap" >Inscrição Estadual</th>'+
                    '<th class="slds-cell-wrap" colspan=2>Situação Cadastral do CNPJ</th>'+
                '</tr>'+
            '</thead>'+
            '<tr class="slds-line-height_reset">'+
                '<td class="slds-cell-wrap" >$inscricaoEstadualSecretaria</td>'+
                '<td class="slds-cell-wrap" colspan=2>$situacaoCadastralSecretaria</td>'+
            '</tr>'+
            '<thead>'+
                '<tr class="slds-line-height_reset">'+
                    '<th class="slds-cell-wrap" colspan=3>Razão Social</th>'+
                '</tr>'+
            '</thead>'+
            '<tr class="slds-line-height_reset">'+
                '<td class="slds-cell-wrap" colspan=3>$razaoSocialSecretaria</td>'+
            '</tr>'+
            '<thead>'+
                '<tr class="slds-line-height_reset">'+
                    '<th class="slds-cell-wrap" colspan=3>Atividade Principal</th>'+
                '</tr>'+
            '</thead>'+
            '<tr class="slds-line-height_reset">'+
                '<td class="slds-cell-wrap" colspan=3>$atividadeEconomicaSecretaria</td>'+
            '</tr>'+
            '<thead>'+
                '<tr class="slds-line-height_reset">'+
                    '<th class="slds-cell-wrap" >Nº da Consulta</th>'+
                    '<th class="slds-cell-wrap" colspan=2>Observação</th>'+
                '</tr>'+
            '</thead>'+
                '$consultasFazenda';
        
            result.dadosCadEmp.put('Tabela-SituacaoFiscal',tabela);
        }
    }
    public static void formatarL270101(String retorno, Relatorio result){
        

        Map<String,String> recFedIdentificacao = new Map<String,String>();
        recFedIdentificacao.put('dataConsulta',retorno.substring(0,8).trim());
        recFedIdentificacao.put('CNPJcompletoEmpresa',retorno.substring(8,23).trim());
        recFedIdentificacao.put('razaoSocial',retorno.substring(23,93).trim());
        recFedIdentificacao.put('codigoSituacao',retorno.substring(93,94).trim());
        recFedIdentificacao.put('descricaoSituacao',retorno.substring(94,124).trim());
        recFedIdentificacao.put('dataSituacao',retorno.substring(124,132).trim());
        recFedIdentificacao.put('optanteSimplesNacional',retorno.substring(132,133).trim());
        recFedIdentificacao.put('codigoCNAprimario',retorno.substring(133,138).trim());
        recFedIdentificacao.put('segmentoCNAprimario',retorno.substring(138,140).trim());
        recFedIdentificacao.put('descricaoCNAprimario',retorno.substring(140,retorno.length()).trim());
        /*
        String outPutMap = '';
        for(String chave:recFedIdentificacao.keyset()){
            outPutMap += '\n' + chave + ':' + recFedIdentificacao.get(chave);
        }
        System.debug('\n\n<QUADRO L270101>\nretorno:'+retorno + outPutMap + '\n</QUADRO L270101>\n\n');
        */

        String dataConsulta = formatarDataAAAAMMDD(recFedIdentificacao.get('dataConsulta'));
        String cnpj = formatarCNPJcompleto(recFedIdentificacao.get('CNPJcompletoEmpresa'));
        String simplesNacional;
        switch on recFedIdentificacao.get('optanteSimplesNacional'){
            when 'P'{simplesNacional = 'OPTANTE';}
            when 'N'{simplesNacional = 'NÃO OPTANTE';}
            when 'A'{simplesNacional = 'EM ANÁLISE';}
            when else{simplesNacional = 'NÂO INFORMADO';}
        }
        String situacaoCNPJ = recFedIdentificacao.get('descricaoSituacao') + ' desde ' + formatarDataAAAAMMDD(recFedIdentificacao.get('dataSituacao'));
        String razaoSocial = recFedIdentificacao.get('razaoSocial');
        String cnpaPrimaria = recFedIdentificacao.get('codigoCNAprimario') + ' - ' + recFedIdentificacao.get('segmentoCNAprimario') + ' - ' + recFedIdentificacao.get('descricaoCNAprimario');

        initTabela_SituacaoFiscal(result);
        String tabela = result.dadosCadEmp.get('Tabela-SituacaoFiscal');
        tabela = tabela.replace('$dataConsultaReceita',dataConsulta);
        tabela = tabela.replace('$cnpjReceita',cnpj);
        tabela = tabela.replace('$simplesNacionalReceita',simplesNacional);
        tabela = tabela.replace('$situacaoCNPJReceita',situacaoCNPJ);
        tabela = tabela.replace('$razaoSocialReceita',razaoSocial);
        tabela = tabela.replace('$cnpaPrimariaReceita',cnpaPrimaria);
        result.dadosCadEmp.put('Tabela-SituacaoFiscal',tabela);
    }
    public static void formatarL270102(String retorno, Relatorio result){

        Map<String,String> recFedCNAESecundario = new Map<String,String>();
        recFedCNAESecundario.put('codigo',retorno.substring(0,5).trim());
        recFedCNAESecundario.put('segmento',retorno.substring(5,7).trim());
        recFedCNAESecundario.put('descricao',retorno.substring(7,retorno.length()).trim());
        /*
        String outPutMap = '';
        for(String chave:recFedCNAESecundario.keyset()){
            outPutMap += '\n' + chave + ':' + recFedCNAESecundario.get(chave);
        }
        System.debug('\n\n<QUADRO L270102>\nretorno:'+retorno + outPutMap + '\n</QUADRO L270102>\n\n');
        */
        /*
        if(!result.dadosCadEmp.get('Tabela-SituacaoFiscal').contains('<tr class="slds-line-height_reset"><td class="slds-cell-wrap" ><b>CNAEs Secundários</b></td></tr>')){
            result.dadosCadEmp.put('Tabela-SituacaoFiscal',result.dadosCadEmp.get('Tabela-SituacaoFiscal') + '<tr class="slds-line-height_reset"><td class="slds-cell-wrap" ><b>CNAEs Secundários</b></td></tr>');
        }
        */
        String cnaeSecundaria = recFedCNAESecundario.get('codigo') + ' - ' + recFedCNAESecundario.get('segmento') + ' - ' + recFedCNAESecundario.get('descricao');

        initTabela_SituacaoFiscal(result);
        String tabela = result.dadosCadEmp.get('Tabela-SituacaoFiscal');
        tabela = tabela.replace('$cnaeSecundariaReceita',cnaeSecundaria + '<br>$cnaeSecundariaReceita');
        result.dadosCadEmp.put('Tabela-SituacaoFiscal',tabela);
        
        //result.dadosCadEmp.put('Tabela-SituacaoFiscal',result.dadosCadEmp.get('Tabela-SituacaoFiscal') + '<tr class="slds-line-height_reset"><td class="slds-cell-wrap" colspan=3>' + cnaeSecundaria + '</td></tr>' );   
    }
    public static void formatarL270103(String retorno, Relatorio result){
        //initTabela_SituacaoFiscal(result);

        Map<String,String> mensagemReceitaFederal = new Map<String,String>();
        mensagemReceitaFederal.put('mensagem',retorno.substring(0,retorno.length()).trim());
        /*
        String outPutMap = '';
        for(String chave:mensagemReceitaFederal.keyset()){
            outPutMap += '\n' + chave + ':' + mensagemReceitaFederal.get(chave);
        }
        System.debug('\n\n<QUADRO L270103>\nretorno:'+retorno + outPutMap + '\n</QUADRO L270103>\n\n');
        */
        
        String mensagem = mensagemReceitaFederal.get('mensagem');
        if(!result.dadosCadEmp.containsKey('Tabela-SituacaoFiscal')){
            result.dadosCadEmp.put('Tabela-SituacaoFiscal','<tr class="slds-line-height_reset"><td class="slds-cell-wrap" >' + mensagem + '</td></tr>');
        }  
    }
    public static void formatarL270104(String retorno, Relatorio result){
        initTabela_SituacaoFiscal(result);

        Map<String,String> SintegraSefazSituacao = new Map<String,String>();
        SintegraSefazSituacao.put('dataSituacao',retorno.substring(0,8).trim());
        SintegraSefazSituacao.put('numeroInscricaoEstadual',retorno.substring(8,23).trim());
        SintegraSefazSituacao.put('codigoSituacao',retorno.substring(23,27).trim());
        SintegraSefazSituacao.put('descricaoSituacao',retorno.substring(27,retorno.length()).trim());
        /*
        String outPutMap = '';
        for(String chave:SintegraSefazSituacao.keyset()){
            outPutMap += '\n' + chave + ':' + SintegraSefazSituacao.get(chave);
        }
        System.debug('\n\n<QUADRO L270104>\nretorno:'+retorno + outPutMap + '\n</QUADRO L270104>\n\n');
        */
        if(!result.dadosCadEmp.containsKey('Tabela-SituacaoFiscal')){
            result.dadosCadEmp.put('Tabela-SituacaoFiscal','<thead><thead>');
        }

        String inscricaoEstadualAux = SintegraSefazSituacao.get('numeroInscricaoEstadual');
        String inscricaoEstadual = '';
        Integer contador = 0;
        for( Integer i = 0; i < inscricaoEstadualAux.length() ; i++ ){
            inscricaoEstadual += inscricaoEstadualAux.substring(i,i+1);
            contador++;
            if(contador == 3 && i < inscricaoEstadualAux.length() - 1){
                contador = 0;
                inscricaoEstadual += '.';
            }
        }

        String situacaoCadastral = SintegraSefazSituacao.get('descricaoSituacao') + ' em: ' + formatarDataAAAAMMDD(SintegraSefazSituacao.get('dataSituacao'));

        initTabela_SituacaoFiscal(result);
        String tabela = result.dadosCadEmp.get('Tabela-SituacaoFiscal');
        tabela = tabela.replace('$inscricaoEstadualSecretaria',inscricaoEstadual);
        tabela = tabela.replace('$situacaoCadastralSecretaria',situacaoCadastral);
        result.dadosCadEmp.put('Tabela-SituacaoFiscal',tabela);

        /*
        result.dadosCadEmp.put('Tabela-SituacaoFiscal',result.dadosCadEmp.get('Tabela-SituacaoFiscal') + '<tr class="slds-line-height_reset"><td class="slds-cell-wrap" ><b>Na Secretaria da Fazenda em $dataConsulta</b></td></tr>' );
        result.dadosCadEmp.put('Tabela-SituacaoFiscal',result.dadosCadEmp.get('Tabela-SituacaoFiscal') + '<tr class="slds-line-height_reset"><td class="slds-cell-wrap" ><b>Inscrição Estadual</b></td><td class="slds-cell-wrap" ><b>Situação Cadastral do CNPJ</b></td></tr>' );
        result.dadosCadEmp.put('Tabela-SituacaoFiscal',result.dadosCadEmp.get('Tabela-SituacaoFiscal') + '<tr class="slds-line-height_reset"><td class="slds-cell-wrap" >' + inscricaoEstadual + '</td><td class="slds-cell-wrap" >' + situacaoCadastral + '</td></tr>' );
        */
    }
    public static void formatarL270105(String retorno, Relatorio result){
        initTabela_SituacaoFiscal(result);

        Map<String,String> SintegraSefazIdentificacao = new Map<String,String>();
        SintegraSefazIdentificacao.put('dataUltimaAtualizacao',retorno.substring(0,8).trim());
        SintegraSefazIdentificacao.put('razaoSocial',retorno.substring(8,108).trim());
        SintegraSefazIdentificacao.put('dataConsulta',retorno.substring(108,116).trim());
        SintegraSefazIdentificacao.put('dataConsultaSite',retorno.substring(116,retorno.length()).trim());
        /*
        String outPutMap = '';
        for(String chave:SintegraSefazIdentificacao.keyset()){
            outPutMap += '\n' + chave + ':' + SintegraSefazIdentificacao.get(chave);
        }
        System.debug('\n\n<QUADRO L270105>\nretorno:'+retorno + outPutMap + '\n</QUADRO L270105>\n\n');
        */
        
    
        //String tabela = result.dadosCadEmp.get('Tabela-SituacaoFiscal');
        String numeroConsulta = SintegraSefazIdentificacao.get('dataConsultaSite');
        String razaoSocial = SintegraSefazIdentificacao.get('razaoSocial');
        String dataConsulta = formatarDataAAAAMMDD(SintegraSefazIdentificacao.get('dataConsulta'));

        initTabela_SituacaoFiscal(result);
        String tabela = result.dadosCadEmp.get('Tabela-SituacaoFiscal');

        tabela = tabela.replace('$razaoSocialSecretaria',razaoSocial);
        tabela = tabela.replace('$dataConsultaSecretaria',dataConsulta);
        
        String consulta = ''+
        '<tr class="slds-line-height_reset">'+
            '<td class="slds-cell-wrap">'+ numeroConsulta + '</td>'+
            '<td class="slds-cell-wrap" colspan=2>$observacaoSecretaria</td>'+
        '</tr>'+
        '';
        tabela = tabela.replace('$consultasFazenda',consulta+'$consultasFazenda');
        
        result.dadosCadEmp.put('Tabela-SituacaoFiscal',tabela);
        /*
        tabela += ''+
        '<tr class="slds-line-height_reset">'+
            '<td class="slds-cell-wrap"><b>Razão Social</b></td>'+
        '</tr>'+
        '<tr class="slds-line-height_reset">'+
            '<td class="slds-cell-wrap" colspan=3>' + razaoSocial + '</td>'+
        '</tr>'+
        '<tr class="slds-line-height_reset">'+
            '<td class="slds-cell-wrap" ><b>Atividade Principal</b></td>'+
        '</tr>'+
        '<tr class="slds-line-height_reset">'+
            '<td class="slds-cell-wrap" colspan=3>$atividadeEconomica</td>'+
        '</tr>'+
        '<tr class="slds-line-height_reset">'+
            '<td class="slds-cell-wrap" ><b>Nº da Consulta</b></td>'+
            '<td class="slds-cell-wrap" ><b>Observação</b></td>'+
        '</tr>'+
        '<tr class="slds-line-height_reset">'+
            '<td>$consultaSituacaoFisca</td>'+
            '<td>$consultaSituacaoFisca</td>'+
        '</tr>';
        result.dadosCadEmp.put('Tabela-SituacaoFiscal',tabela);
        */
    }
    public static void formatarL270106(String retorno, Relatorio result){
        initTabela_SituacaoFiscal(result);

        Map<String,String> SintegraSefazAtividadeEconomica = new Map<String,String>();
        SintegraSefazAtividadeEconomica.put('atividadeEconomica',retorno.substring(0,retorno.length()).trim());
        /*
        String outPutMap = '';
        for(String chave:SintegraSefazAtividadeEconomica.keyset()){
            outPutMap += '\n' + chave + ':' + SintegraSefazAtividadeEconomica.get(chave);
        }
        System.debug('\n\n<QUADRO L270106>\nretorno:'+retorno + outPutMap + '\n</QUADRO L270106>\n\n');
        */
        String atividadeEconomica = SintegraSefazAtividadeEconomica.get('atividadeEconomica');
        result.dadosCadEmp.put('Tabela-SituacaoFiscal',result.dadosCadEmp.get('Tabela-SituacaoFiscal').replace('$atividadeEconomica',atividadeEconomica));
    }
    public static void formatarL270107(String retorno, Relatorio result){
        initTabela_SituacaoFiscal(result);

        Map<String,String> SintegraSefazObservacao = new Map<String,String>();
        SintegraSefazObservacao.put('observao',retorno);
        /*
        String outPutMap = '';
        for(String chave:SintegraSefazObservacao.keyset()){
            outPutMap += '\n' + chave + ':' + SintegraSefazObservacao.get(chave);
        }
        System.debug('\n\n<QUADRO L270107>\nretorno:'+retorno + outPutMap + '\n</QUADRO L270107>\n\n');
        */
        String observacao =  SintegraSefazObservacao.get('observao');

        initTabela_SituacaoFiscal(result);
        String tabela = result.dadosCadEmp.get('Tabela-SituacaoFiscal');
        tabela = tabela.replace('$observacaoSecretaria',observacao+'$observacaoSecretaria');
        result.dadosCadEmp.put('Tabela-SituacaoFiscal',tabela);
    }



    //mosaic business
    public static void formatarL120101(String retorno, Relatorio result){

        Map<String,String> mosaicPjDados = new Map<String,String>();
        mosaicPjDados.put('cnpjCliente',retorno.substring(0,8).trim());
        mosaicPjDados.put('codigoMosaic',retorno.substring(8,11).trim());
        mosaicPjDados.put('dataAtualizacao',retorno.substring(11,19).trim());
        /*
        String outPutMap = '';
        for(String chave:mosaicPjDados.keyset()){
            outPutMap += '\n' + chave + ':' + mosaicPjDados.get(chave);
        }
        System.debug('\n\n<QUADRO L120101>\nretorno:'+retorno + outPutMap + '\n</QUADRO L120101>\n\n');
        */
        if(!result.dadosCadEmp.containsKey('Tabela-Mosaic')){
            result.dadosCadEmp.put('Tabela-Mosaic','');//<thead><tr class="slds-line-height_reset"><th>CNPJ cliente</th><th>Codigo do Mosaic</th><th>Data Atualização</th></tr></thead>');
        }

        String cnpj = mosaicPjDados.get('cnpjCliente');
        String codigoMosaic = mosaicPjDados.get('codigoMosaic');
        String dataAtualizacao = formatarDataAAAAMMDD(mosaicPjDados.get('dataAtualizacao'));

        Map<String,String> interp = interpretarMosaic(codigoMosaic);
        String titulo = interp.get('titulo');
        String interpretacao = interp.get('interpretacao');

        result.dadosCadEmp.put('Tabela-Mosaic',''+
            '<tr class="slds-line-height_reset">'+
                '<td class="slds-cell-wrap"><b>'+ codigoMosaic + ' - ' + titulo + '</b></td>'+
            '</tr>'+
            '<tr class="slds-line-height_reset">'+
                '<td class="slds-cell-wrap">' + titulo + ' - ' + interpretacao + '</td>'+
            '</tr>'+
        '');
        
        
        
        //result.dadosCadEmp.get('Tabela-Mosaic') + '<tr class="slds-line-height_reset"><td class="slds-cell-wrap" >' + cnpj + '</td><td class="slds-cell-wrap" >' + codigoMosaic + '</td><td class="slds-cell-wrap" >' + dataAtualizacao + '</td></tr>');
    }
    public static void formatarL120199(String retorno, Relatorio result){
        
        Map<String,String> mensagemMosaicPjDados = new Map<String,String>();
        mensagemMosaicPjDados.put('dataAtualizacao',retorno.substring(0,8).trim());
        mensagemMosaicPjDados.put('horaAtualizacao',retorno.substring(8,16).trim());
        mensagemMosaicPjDados.put('mensagemRetorno',retorno.substring(16,retorno.length()).trim());
        /*
        String outPutMap = '';
        for(String chave:mensagemMosaicPjDados.keyset()){
            outPutMap += '\n' + chave + ':' + mensagemMosaicPjDados.get(chave);
        }
        System.debug('\n\n<QUADRO L120199>\nretorno:'+retorno + outPutMap + '\n</QUADRO L120199>\n\n');
        */
        if(!result.dadosCadEmp.containsKey('Tabela-Mosaic')){
            result.dadosCadEmp.put('Tabela-Mosaic','<thead></thead>');
        }

        String mensagem = mensagemMosaicPjDados.get('mensagemRetorno');
        result.dadosCadEmp.put('Tabela-Mosaic',result.dadosCadEmp.get('Tabela-Mosaic') + '<tr class="slds-line-height_reset"><td class="slds-cell-wrap" >' + mensagem + '</td></tr>');
    }



    //vendas com cartao
    public static void formatarL700099(String retorno, Relatorio result){

        Map<String,String> mensagemVendaCartao = new Map<String,String>();
        mensagemVendaCartao.put('codigoMensagem',retorno.substring(0,3));
        mensagemVendaCartao.put('mensagem',retorno.substring(3,retorno.length()));
        /*
        String outPutMap = '';
        for(String chave:mensagemVendaCartao.keyset()){
            outPutMap += '\n' + chave + ':' + mensagemVendaCartao.get(chave);
        }
        System.debug('\n\n<QUADRO L700099>\nretorno:'+retorno + outPutMap + '\n</QUADRO L700099>\n\n');
        */
        if(!result.dadosCadEmp.containsKey('Tabela-vendasCartao')){
            result.dadosCadEmp.put('Tabela-vendasCartao','<thead></thead>');
        }

        String mensagem = mensagemVendaCartao.get('mensagem');
        result.dadosCadEmp.put('Tabela-vendasCartao',result.dadosCadEmp.get('Tabela-vendasCartao') + '<tr class="slds-line-height_reset"><td class="slds-cell-wrap" >' + mensagem + '</td></tr>');
    }



    //indicador de recuperacao de credito
    public static void formatarL530101(String retorno, Relatorio result){

        Map<String,String> indicadorRecuperacaoCredito = new Map<String,String>();
        indicadorRecuperacaoCredito.put('pontuacao',retorno.substring(0,4).trim());
        indicadorRecuperacaoCredito.put('numeroCnpj',retorno.substring(4,12).trim());
        indicadorRecuperacaoCredito.put('codigoFilial',retorno.substring(12,16).trim());
        indicadorRecuperacaoCredito.put('digitoFilial',retorno.substring(16,18).trim());
        indicadorRecuperacaoCredito.put('razaoSocial',retorno.substring(18,97).trim());
        indicadorRecuperacaoCredito.put('classe',retorno.substring(97,98).trim());
        indicadorRecuperacaoCredito.put('mensagemInterpretacao',retorno.substring(98,178).trim());
        indicadorRecuperacaoCredito.put('areaReservada',retorno.substring(178,294).trim());
        /*
        String outPutMap = '';
        for(String chave:indicadorRecuperacaoCredito.keyset()){
            outPutMap += '\n' + chave + ':' + indicadorRecuperacaoCredito.get(chave);
        }
        System.debug('\n\n<QUADRO L530101>\nretorno:'+retorno + outPutMap + '\n</QUADRO L530101>\n\n');
        */
        if(!result.informacoesAnotacoesNegativas.containsKey('Tabela-IndicadorRecuperacaoCredito')){
            result.informacoesAnotacoesNegativas.put('Tabela-IndicadorRecuperacaoCredito','<thead></thead>');
        }

        String classe = indicadorRecuperacaoCredito.get('classe');
        String interpretacao = indicadorRecuperacaoCredito.get('mensagemInterpretacao');
        result.informacoesAnotacoesNegativas.put('Tabela-IndicadorRecuperacaoCredito',result.informacoesAnotacoesNegativas.get('Tabela-IndicadorRecuperacaoCredito') + '<tr class="slds-line-height_reset"><td class="slds-cell-wrap" ><b>Classe de Recuperação: </b>' + classe + '</td></tr><tr class="slds-line-height_reset"><td class="slds-cell-wrap" >' + interpretacao + '</td></tr>');
    }
    public static void formatarL530199(String retorno, Relatorio result){

        Map<String,String> msgIndicRecupCred = new Map<String,String>();
        msgIndicRecupCred.put('numeroCNPJ',retorno.substring(0,8).trim());
        msgIndicRecupCred.put('numeroFilial',retorno.substring(8,12).trim());
        msgIndicRecupCred.put('digitoFilial',retorno.substring(12,14).trim());
        msgIndicRecupCred.put('codigoMensagem',retorno.substring(14,18).trim());
        msgIndicRecupCred.put('mensagem',retorno.substring(18,98).trim());
        msgIndicRecupCred.put('areaReservada',retorno.substring(98,294).trim());
        /*
        String outPutMap = '';
        for(String chave:msgIndicRecupCred.keyset()){
            outPutMap += '\n' + chave + ':' + msgIndicRecupCred.get(chave);
        }
        System.debug('\n\n<QUADRO L530199>\nretorno:'+retorno + outPutMap + '\n</QUADRO L530199>\n\n');
        */
        if(!result.informacoesAnotacoesNegativas.containsKey('Tabela-IndicadorRecuperacaoCredito')){
            result.informacoesAnotacoesNegativas.put('Tabela-IndicadorRecuperacaoCredito','<thead></thead>');
        }

        String mensagem = msgIndicRecupCred.get('mensagem');
        result.informacoesAnotacoesNegativas.put('Tabela-IndicadorRecuperacaoCredito',result.informacoesAnotacoesNegativas.get('Tabela-IndicadorRecuperacaoCredito') + '<tr class="slds-line-height_reset"><td class="slds-cell-wrap" >' + mensagem + '</td></tr>');
    }



    //indicador de recuperacao de divida
    public static void formatarL580199(String retorno, Relatorio result){

        Map<String,String> msgIndicRecupDivida = new Map<String,String>();
        msgIndicRecupDivida.put('codigoMensagem',retorno.substring(0,3).trim());
        msgIndicRecupDivida.put('mensagem',retorno.substring(3,123).trim());
        /*
        String outPutMap = '';
        for(String chave:msgIndicRecupDivida.keyset()){
            outPutMap += '\n' + chave + ':' + msgIndicRecupDivida.get(chave);
        }
        System.debug('\n\n<QUADRO L580199>\nretorno:'+retorno + outPutMap + '\n</QUADRO L580199>\n\n');
        */
        if(!result.informacoesAnotacoesNegativas.containsKey('Tabela-IndicadorRecuperacaoDivida')){
            result.informacoesAnotacoesNegativas.put('Tabela-IndicadorRecuperacaoDivida','<thead></thead>');
        }

        String mensagem = msgIndicRecupDivida.get('mensagem');
        result.informacoesAnotacoesNegativas.put('Tabela-IndicadorRecuperacaoDivida',result.informacoesAnotacoesNegativas.get('Tabela-IndicadorRecuperacaoDivida') + '<tr class="slds-line-height_reset"><td class="slds-cell-wrap" >' + mensagem + '</td></tr>');
    }
    public static void formatarL580101(String retorno, Relatorio result){

        Map<String,String> indicDividaVencida = new Map<String,String>();
        indicDividaVencida.put('indicador1a7',retorno.substring(0,1).trim());
        indicDividaVencida.put('indicador8a30',retorno.substring(1,2).trim());
        indicDividaVencida.put('indicador31a180',retorno.substring(2,3).trim());
        indicDividaVencida.put('msgClienteSemAnotacoes',retorno.substring(3,123).trim());
        /*
        String outPutMap = '';
        for(String chave:indicDividaVencida.keyset()){
            outPutMap += '\n' + chave + ':' + indicDividaVencida.get(chave);
        }
        System.debug('\n\n<QUADRO L0580101>\nretorno:'+retorno + outPutMap + '\n</QUADRO L580101>\n\n');
        */
        if(!result.informacoesAnotacoesNegativas.containsKey('Tabela-IndicadorRecuperacaoDivida')){
            result.informacoesAnotacoesNegativas.put('Tabela-IndicadorRecuperacaoDivida','');
        }

        result.informacoesAnotacoesNegativas.put('Tabela-IndicadorRecuperacaoDivida',result.informacoesAnotacoesNegativas.get('Tabela-IndicadorRecuperacaoDivida') + '<tr class="slds-line-height_reset"><td colspan=3>A empresa consultada pagou dívidas nos últimos 180 dias?</td></tr>');
        result.informacoesAnotacoesNegativas.put('Tabela-IndicadorRecuperacaoDivida',result.informacoesAnotacoesNegativas.get('Tabela-IndicadorRecuperacaoDivida') + '<thead><tr class="slds-line-height_reset"><td class="slds-cell-wrap" ><b>0 a 7 dias</b></td><td class="slds-cell-wrap" ><b>8 a 10 dias</b></td><td class="slds-cell-wrap" ><b>31 a 180 dias</b></td></tr></thead>');

        String de1a7,de8a30,de31a180;
        if(indicDividaVencida.get('indicador1a7') == 'N'){de1a7 = 'Não';}else{de1a7 = 'Sim';}
        if(indicDividaVencida.get('indicador8a30') == 'N'){de8a30 = 'Não';}else{de8a30 = 'Sim';}
        if(indicDividaVencida.get('indicador31a180') == 'N'){de31a180 = 'Não';}else{de31a180 = 'Sim';}
        result.informacoesAnotacoesNegativas.put('Tabela-IndicadorRecuperacaoDivida',result.informacoesAnotacoesNegativas.get('Tabela-IndicadorRecuperacaoDivida') + '<tr class="slds-line-height_reset"><td class="slds-cell-wrap" >' + de1a7 + '</td><td class="slds-cell-wrap" >' + de8a30 + '</td><td class="slds-cell-wrap" >' + de31a180 + '</td></tr>');
    }



    //enderecos e telefones adicionaris
    public static void formatarL280199(String retorno, Relatorio result){
        
        Map<String,String> mensagemEndereco = new Map<String,String>();
        mensagemEndereco.put('dataConsulta',retorno.substring(0,8).trim());
        mensagemEndereco.put('horaConsulta',retorno.substring(8,16).trim());
        mensagemEndereco.put('textoMensagem',retorno.substring(16,116).trim());
        /*
        String outPutMap = '';
        for(String chave:mensagemEndereco.keyset()){
            outPutMap += '\n' + chave + ':' + mensagemEndereco.get(chave);
        }
        System.debug('\n\n<QUADRO L280199>\nretorno:'+retorno + outPutMap + '\n</QUADRO L280199>\n\n');
        */
        if(!result.dadosCadEmp.containsKey('Tabela-TelefonesEnderecosAdicionais')){
            result.dadosCadEmp.put('Tabela-TelefonesEnderecosAdicionais','');
        }

        String mensagem = mensagemEndereco.get('textoMensagem');
        result.dadosCadEmp.put('Tabela-TelefonesEnderecosAdicionais',result.dadosCadEmp.get('Tabela-TelefonesEnderecosAdicionais') + '<thead><tr class="slds-line-height_reset"><td class="slds-cell-wrap" >' + mensagem + '</td></tr></thead>');
    }
    public static void formatarL290101(String retorno, Relatorio result){

        Map<String,String> telefone = new Map<String,String>();
        telefone.put('dataInformacao',retorno.substring(0,8).trim());
        telefone.put('numeroDDD',retorno.substring(8,12).trim());
        telefone.put('numeroTelefone',retorno.substring(12,22).trim());
        telefone.put('reservadoSerasa',retorno.substring(22,retorno.length()).trim());
        /*
        String outPutMap = '';
        for(String chave:telefone.keyset()){
            outPutMap += '\n' + chave + ':' + telefone.get(chave);
        }
        System.debug('\n\n<QUADRO L290101>\nretorno:'+retorno + outPutMap + '\n</QUADRO L290101>\n\n');
        */
        if(!result.dadosCadEmp.containsKey('Tabela-TelefonesEnderecosAdicionais')){
            result.dadosCadEmp.put('Tabela-TelefonesEnderecosAdicionais','');
        }
        
        string cabecalhoTelefones = '<thead><tr lass="slds-line-height_reset"><th>Telefone Disponíveis</th><th>Referente a</th></tr></thead>';
        String tabela = result.dadosCadEmp.get('Tabela-TelefonesEnderecosAdicionais');
        if(!tabela.contains(cabecalhoTelefones)){
            tabela += '<tr><td></td></tr>';
            tabela += cabecalhoTelefones;
        }

        String tel = formatarTelefone(telefone.get('numeroTelefone'),telefone.get('numeroDDD'));
        String referente;
        switch on telefone.get('reservadoSerasa'){
            when 'S'{ referente = 'SÓCIO'; }
            when 'E'{ referente = 'EMPRESA'; }
            when else{ referente = 'INDEFINIDO'; }
        }

        tabela += '<tr class="slds-line-height_reset"><td class="slds-cell-wrap" >' + tel + '</td><td class="slds-cell-wrap" >' + referente + '</td></tr>';
        result.dadosCadEmp.put('Tabela-TelefonesEnderecosAdicionais',tabela);
    }
    public static void formatarL290199(String retorno, Relatorio result){
        
        Map<String,String> mensagemTelefone = new Map<String,String>();
        mensagemTelefone.put('dataConsulta',retorno.substring(0,8).trim());
        mensagemTelefone.put('horaConsulta',retorno.substring(8,16).trim());
        mensagemTelefone.put('textoMensagem',retorno.substring(16,116).trim());
        //mensagemTelefone.put('reservadoSerasa',retorno.substring(116,139).trim());
        /*
        String outPutMap = '';
        for(String chave:mensagemTelefone.keyset()){
            outPutMap += '\n' + chave + ':' + mensagemTelefone.get(chave);
        }
        System.debug('\n\n<QUADRO L290199>\nretorno:'+retorno + outPutMap + '\n</QUADRO L290199>\n\n');
        */
        if(!result.dadosCadEmp.containsKey('Tabela-TelefonesEnderecosAdicionais')){
            result.dadosCadEmp.put('Tabela-TelefonesEnderecosAdicionais','');
        }

        String mensagem = mensagemTelefone.get('textoMensagem');
        result.dadosCadEmp.put('Tabela-TelefonesEnderecosAdicionais',result.dadosCadEmp.get('Tabela-TelefonesEnderecosAdicionais') + '<tr class="slds-line-height_reset"><td class="slds-cell-wrap" >' + mensagem + '</td></tr>');
    }



    //Dívidas com Órgãos Públicos - Empresa
    public static void formatarL120201(String retorno, Relatorio result){

        Map<String,String> dadosOrgaosPublicos = new Map<String,String>();
        dadosOrgaosPublicos.put('dataAtualizacao',retorno.substring(0,8).trim());
        dadosOrgaosPublicos.put('horaAtualizacao',retorno.substring(8,16).trim());
        dadosOrgaosPublicos.put('origemAnotacao',retorno.substring(16,83).trim());
        dadosOrgaosPublicos.put('siglaEstado',retorno.substring(83,85).trim());
        dadosOrgaosPublicos.put('contratoAnotacao',retorno.substring(85,105).trim());
        dadosOrgaosPublicos.put('valorAnotacao',retorno.substring(105,122).trim());
        dadosOrgaosPublicos.put('avalista',retorno.substring(122,123).trim());
        dadosOrgaosPublicos.put('modalidade',retorno.substring(123,126).trim());
        dadosOrgaosPublicos.put('dataVencimento',retorno.substring(126,136).trim());
        /*
        String outPutMap = '';
        for(String chave:dadosOrgaosPublicos.keyset()){
            outPutMap += '\n' + chave + ':' + dadosOrgaosPublicos.get(chave);
        }
        System.debug('\n\n<QUADRO L120201>\nretorno:'+retorno + outPutMap + '\n</QUADRO L120201>\n\n');
        */
        if(!result.informacoesAnotacoesNegativas.containsKey('Tabela-DividasOrgaosPublicosEmpresa')){
            result.informacoesAnotacoesNegativas.put('Tabela-DividasOrgaosPublicosEmpresa','<thead></thead>');
        }

        if(!result.informacoesAnotacoesNegativas.get('Tabela-DividasOrgaosPublicosEmpresa').contains('<thead><tr class="slds-line-height_reset"><th>Data</th><th>Modalidade</th><th>Avalista</th><th>Valor</th><th>Contrato</th><th>Origem</th><th>Local</th></tr></thead>')){
            result.informacoesAnotacoesNegativas.put('Tabela-DividasOrgaosPublicosEmpresa',result.informacoesAnotacoesNegativas.get('Tabela-DividasOrgaosPublicosEmpresa') + '<thead><tr class="slds-line-height_reset"><th>Data</th><th>Modalidade</th><th>Avalista</th><th>Valor</th><th>Contrato</th><th>Origem</th><th>Local</th></tr></thead>');
        }

        String data = dadosOrgaosPublicos.get('dataVencimento').replace('.','/');
        String modalidade = dadosOrgaosPublicos.get('modalidade');
        String avalista = dadosOrgaosPublicos.get('avalista');
        String valor = dadosOrgaosPublicos.get('valorAnotacao');
        String contrato = dadosOrgaosPublicos.get('contratoAnotacao');
        String origem = dadosOrgaosPublicos.get('origemAnotacao');
        String local = dadosOrgaosPublicos.get('siglaEstado');
        result.informacoesAnotacoesNegativas.put('Tabela-DividasOrgaosPublicosEmpresa',result.informacoesAnotacoesNegativas.get('Tabela-DividasOrgaosPublicosEmpresa') + '<tr class="slds-line-height_reset"><td class="slds-cell-wrap" >' + data + '</td><td class="slds-cell-wrap" >' + modalidade + '</td><td class="slds-cell-wrap" >' + avalista + '</td><td class="slds-cell-wrap" >' + valor + '</td><td class="slds-cell-wrap" >' + contrato + '</td><td class="slds-cell-wrap" >' + origem + '</td><td class="slds-cell-wrap" >' + local + '</td></tr>');
    }
    public static void formatarL120202(String retorno, Relatorio result){

        Map<String,String> totaisOrgaosPublicos = new Map<String,String>();
        totaisOrgaosPublicos.put('dataAtualizacao',retorno.substring(0,8).trim());
        totaisOrgaosPublicos.put('horaAtualizacao',retorno.substring(8,16).trim());
        totaisOrgaosPublicos.put('totalOcorrencias',retorno.substring(16,21).trim());
        totaisOrgaosPublicos.put('totalAnotacoes',retorno.substring(21,38).trim());
        /*
        String outPutMap = '';
        for(String chave:totaisOrgaosPublicos.keyset()){
            outPutMap += '\n' + chave + ':' + totaisOrgaosPublicos.get(chave);
        }
        System.debug('\n\n<QUADRO L120202>\nretorno:'+retorno + outPutMap + '\n</QUADRO L120202>\n\n');
        */
        if(!result.informacoesAnotacoesNegativas.containsKey('Tabela-DividasOrgaosPublicosEmpresa')){
            result.informacoesAnotacoesNegativas.put('Tabela-DividasOrgaosPublicosEmpresa','');
        }       
    }
    public static void formatarL120299(String retorno, Relatorio result){
        
        Map<String,String> mensagem = new Map<String,String>();
        mensagem.put('dataAtualizacao',retorno.substring(0,8).trim());
        mensagem.put('horaAtualizacao',retorno.substring(8,16).trim());
        mensagem.put('mensagem',retorno.substring(16,116).trim());
        /*
        String outPutMap = '';
        for(String chave:mensagem.keyset()){
            outPutMap += '\n' + chave + ':' + mensagem.get(chave);
        }
        System.debug('\n\n<QUADRO L120299>\nretorno:'+retorno + outPutMap + '\n</QUADRO L120299>\n\n');
        */
        if(!result.informacoesAnotacoesNegativas.containsKey('Tabela-DividasOrgaosPublicosEmpresa')){
            result.informacoesAnotacoesNegativas.put('Tabela-DividasOrgaosPublicosEmpresa','<thead></thead>');
        }

        String msg = mensagem.get('mensagem');
        result.informacoesAnotacoesNegativas.put('Tabela-DividasOrgaosPublicosEmpresa',result.informacoesAnotacoesNegativas.get('Tabela-DividasOrgaosPublicosEmpresa') + '<tr class="slds-line-height_reset"><td class="slds-cell-wrap" >' + msg + '</td></tr>');
    }



    //Anotações e Consultas SPC Sócios e Administradores
    public static void formatarL925001(String retorno, Relatorio result){

        //atualizar informacoes da ultima anotacao
        if(result.anotacoesConsultasSPCSocios.containsKey('$quantidadeAnotacoes')){
            result.anotacoesConsultasSPCSocios.put('Tabela-AnotacoesSpcSociosAdministradores',result.anotacoesConsultasSPCSocios.get('Tabela-AnotacoesSpcSociosAdministradores').replace('$quantidadeAnotacoes',result.anotacoesConsultasSPCSocios.get('$quantidadeAnotacoes')));
        }
        if(result.anotacoesConsultasSPCSocios.containsKey('$valorTotal')){
            result.anotacoesConsultasSPCSocios.put('Tabela-AnotacoesSpcSociosAdministradores',result.anotacoesConsultasSPCSocios.get('Tabela-AnotacoesSpcSociosAdministradores').replace('$valorTotal',result.anotacoesConsultasSPCSocios.get('$valorTotal')));
        }

        if(result.anotacoesConsultasSPCSocios.containsKey('Tabela-AnotacoesSpcSociosAdministradores')){
            if(result.anotacoesConsultasSPCSocios.get('Tabela-AnotacoesSpcSociosAdministradores').contains('$ultimaAnotacao')){
                result.anotacoesConsultasSPCSocios.put('Tabela-AnotacoesSpcSociosAdministradores',result.anotacoesConsultasSPCSocios.get('Tabela-AnotacoesSpcSociosAdministradores').replace('$ultimaAnotacao','0'));
            }
        }

        result.anotacoesConsultasSPCSocios.put('$quantidadeAnotacoes','0');
        result.anotacoesConsultasSPCSocios.put('$valorTotal','0');



        //parse dos dados da request
        Map<String,String> qtdAnotacoesEAnotacoesRecentes = new Map<String,String>();
        qtdAnotacoesEAnotacoesRecentes.put('sequenciaSocio',retorno.substring(0,4).trim());
        qtdAnotacoesEAnotacoesRecentes.put('tipoPessoa',retorno.substring(4,5).trim());
        qtdAnotacoesEAnotacoesRecentes.put('numeroDocumento',retorno.substring(5,14).trim());
        qtdAnotacoesEAnotacoesRecentes.put('filial',retorno.substring(14,18).trim());
        qtdAnotacoesEAnotacoesRecentes.put('digitoControle',retorno.substring(18,20).trim());
        qtdAnotacoesEAnotacoesRecentes.put('sequenciaSocio2',retorno.substring(20,24).trim());
        qtdAnotacoesEAnotacoesRecentes.put('filiacao',retorno.substring(24,25).trim());
        qtdAnotacoesEAnotacoesRecentes.put('nome',retorno.substring(25,75).trim());
        qtdAnotacoesEAnotacoesRecentes.put('quantidadeAnotacoes',retorno.substring(75,85).trim());
        qtdAnotacoesEAnotacoesRecentes.put('valorAnotacoes',retorno.substring(85,102).trim());
        qtdAnotacoesEAnotacoesRecentes.put('dataAnotacaoMaisRecente',retorno.substring(102,110).trim());
        qtdAnotacoesEAnotacoesRecentes.put('codigoSocio',retorno.substring(110,111).trim());
        /*
        String outPutMap = '';
        for(String chave:qtdAnotacoesEAnotacoesRecentes.keyset()){
            outPutMap += '\n' + chave + ':' + qtdAnotacoesEAnotacoesRecentes.get(chave);
        }
        System.debug('\n\n<QUADRO L925001>\nretorno:'+retorno + outPutMap + '\n</QUADRO L925001>\n\n');
        */
        //String jump = '<tr><td class="slds-cell-wrap" ><br></td></tr>';
        if(!result.anotacoesConsultasSPCSocios.containsKey('Tabela-AnotacoesSpcSociosAdministradores')){
            result.anotacoesConsultasSPCSocios.put('Tabela-AnotacoesSpcSociosAdministradores','');
        }

        String cnpjOUcpf = formatarCpfOuCnpj(qtdAnotacoesEAnotacoesRecentes.get('numeroDocumento') + qtdAnotacoesEAnotacoesRecentes.get('digitoControle'),qtdAnotacoesEAnotacoesRecentes.get('tipoPessoa'),qtdAnotacoesEAnotacoesRecentes.get('filial'));
        String nome = qtdAnotacoesEAnotacoesRecentes.get('nome');
        String quantidade = qtdAnotacoesEAnotacoesRecentes.get('quantidadeAnotacoes');
        String valorTotal = qtdAnotacoesEAnotacoesRecentes.get('valorAnotacoes');
        String ultimaAnotacao = qtdAnotacoesEAnotacoesRecentes.get('dataAnotacaoMaisRecente');
    
        result.anotacoesConsultasSPCSocios.put( '$nomeSocio' + qtdAnotacoesEAnotacoesRecentes.get('nome') , nome );
        result.anotacoesConsultasSPCSocios.put( '$cnpjSocio' + qtdAnotacoesEAnotacoesRecentes.get('sequenciaSocio') , cnpjOUcpf );
        result.anotacoesConsultasSPCSocios.put( '$cnpjSocioNome' + qtdAnotacoesEAnotacoesRecentes.get('nome') , cnpjOUcpf );

        String tabela = result.anotacoesConsultasSPCSocios.get('Tabela-AnotacoesSpcSociosAdministradores');
        tabela += ''+
        '<thead>'+
            '<tr class="slds-line-height_reset" style="border-top:solid gray 1px">'+
                '<th>CPF/CNPJ</th>'+
                '<th>Nome/Razão Social</th>'+
                '<th>Quantidade</th>'+
                '<th>Valor Total (R$)</th>'+
                '<th colspan=2>Última anotação</th>'+
            '</tr>'+
        '</thead>'+
        '<tr class="slds-line-height_reset">'+
            '<td class="slds-cell-wrap" >' + cnpjOUcpf + '</td>'+
            '<td class="slds-cell-wrap" >' + nome + '</td>'+
            '<td class="slds-cell-wrap" >$Quantidade</td>'+
            '<td class="slds-cell-wrap" >$Valor Total (R$)</td>'+
            '<td class="slds-cell-wrap" colspan = 2 >$Última anotação</td>'+
        '</tr>';
        result.anotacoesConsultasSPCSocios.put('Tabela-AnotacoesSpcSociosAdministradores',tabela);

        result.anotacoesConsultasSPCSocios.put( '$nomeSocio' + qtdAnotacoesEAnotacoesRecentes.get('nome') , nome );
        result.anotacoesConsultasSPCSocios.put( '$cnpjSocio' + qtdAnotacoesEAnotacoesRecentes.get('sequenciaSocio') , cnpjOUcpf );
    }
    public static void formatarL925002(String retorno, Relatorio result){

        //result.anotacoesConsultasSPCSocios.put('Tabela-AnotacoesSpcSociosAdministradores',result.anotacoesConsultasSPCSocios.get('Tabela-AnotacoesSpcSociosAdministradores').replace('$comOUsemDados','<td class="slds-cell-wrap" >$quantidadeAnotacoes</td><td class="slds-cell-wrap" >$valorTotal</td><td class="slds-cell-wrap" >$ultimaAnotacao</td>'));

        Map<String,String> dadosAnotacao = new Map<String,String>();
        dadosAnotacao.put('sequenciaSocio',retorno.substring(0,4).trim());
        dadosAnotacao.put('dataInclusaoAnotacao',retorno.substring(4,12).trim());
        dadosAnotacao.put('dataVencimentoAnotacao',retorno.substring(12,20).trim());
        dadosAnotacao.put('numeroContrato',retorno.substring(20,50).trim());
        dadosAnotacao.put('tipoOperacao',retorno.substring(50,51).trim());
        dadosAnotacao.put('valorAnotacao',retorno.substring(51,68).trim());
        dadosAnotacao.put('nomeCidade',retorno.substring(68,98).trim());
        dadosAnotacao.put('uf',retorno.substring(98,100).trim());
        dadosAnotacao.put('credor',retorno.substring(100,170).trim());
        dadosAnotacao.put('origemAnotacao',retorno.substring(170,retorno.length()).trim());

        /*
        String outPutMap = '';
        for(String chave:dadosAnotacao.keyset()){
            outPutMap += '\n' + chave + ':' + dadosAnotacao.get(chave);
        }
        System.debug('\n\n<QUADRO L925002>\nretorno:'+retorno + outPutMap + '\n</QUADRO L925002>\n\n');
        */

        String inclusao = formatarDataDDMMAAAA(dadosAnotacao.get('dataInclusaoAnotacao'));
        String vencimento = formatarDataDDMMAAAA(dadosAnotacao.get('dataVencimentoAnotacao'));
        String contrato = dadosAnotacao.get('numeroContrato');
        String tipo;
        switch on dadosAnotacao.get('tipoOperacao'){
            when 'C'{tipo = 'COMPRADOR';}
            when 'F'{tipo = 'FIADOR';}
            when 'A'{tipo = 'AVALISTA';}
            when else{tipo = 'INDEFINIDO';}
        }
        //String valor = 'teste';
        String val = removerZeros(dadosAnotacao.get('valorAnotacao'));
        String valor = val.substring(0,val.length()-2) + '.' + val.substring(val.length()-2,val.length());
        String cidadeEuf = dadosAnotacao.get('nomeCidade') + '/' + dadosAnotacao.get('uf');
        String associado = dadosAnotacao.get('credor');
        String origem = dadosAnotacao.get('origemAnotacao');

        String tabela = result.anotacoesConsultasSPCSocios.get('Tabela-AnotacoesSpcSociosAdministradores');

        tabela = tabela.replace('$Última anotação',inclusao);

        tabela += ''+
        '<thead>'+
            '<tr class="slds-line-height_reset">'+
                '<th class="slds-cell-wrap" >Inclusão em</th>'+
                '<th class="slds-cell-wrap" >Vencimento em</th>'+
                '<th class="slds-cell-wrap" >Contrato</th>'+
                '<th class="slds-cell-wrap" >Tipo</th>'+
                '<th class="slds-cell-wrap" >Valor (R$)</tj>'+
                '<th class="slds-cell-wrap" >Cidade/UF</th>'+
            '</tr>'+
        '</thead>'+
        '<tr class="slds-line-height_reset">'+
            '<td class="slds-cell-wrap" >' + inclusao + '</td>'+
            '<td class="slds-cell-wrap" >' + vencimento + '</td>'+
            '<td class="slds-cell-wrap" >' + contrato + '</td>'+
            '<td class="slds-cell-wrap" >' + tipo + '</td>'+
            '<td class="slds-cell-wrap" >' + valor + '</td>'+
            '<td class="slds-cell-wrap" >' + cidadeEuf + '</td>'+
        '</tr>'+
            '<tr class="slds-line-height_reset">'+
                '<td class="slds-cell-wrap" colspan=3><b>Associado Credor: </b>' + associado + '</td>'+
                '<td class="slds-cell-wrap" colspan=3><b>Origem: </b>' + origem + '</td>'+
            '</tr>'+
        '</tr>'+
        '';
        result.anotacoesConsultasSPCSocios.put('Tabela-AnotacoesSpcSociosAdministradores',tabela);




        //aumentar contador valor
        if(result.anotacoesConsultasSPCSocios.containsKey('$valorTotal')){
            Double valorTotal = double.valueOf(result.anotacoesConsultasSPCSocios.get('$valorTotal'));
            valorTotal += double.valueOf(valor);
            String vt = String.valueOf(valorTotal);
            result.anotacoesConsultasSPCSocios.put('$valorTotal',vt);
        }

        

        //aumentar contador de anotacoes
        if(result.anotacoesConsultasSPCSocios.containsKey('$quantidadeAnotacoes')){
            Integer quantidadeAnotacoes = Integer.valueOf(result.anotacoesConsultasSPCSocios.get('$quantidadeAnotacoes'));
            quantidadeAnotacoes += 1;
            String t = String.valueOf(quantidadeAnotacoes);
            result.anotacoesConsultasSPCSocios.put('$quantidadeAnotacoes',t);
        }

        //colocar data da ultima consulta no lugar certo
        if(result.anotacoesConsultasSPCSocios.get('Tabela-AnotacoesSpcSociosAdministradores').contains('$ultimaAnotacao')){
            result.anotacoesConsultasSPCSocios.put('Tabela-AnotacoesSpcSociosAdministradores',result.anotacoesConsultasSPCSocios.get('Tabela-AnotacoesSpcSociosAdministradores').replace('$ultimaAnotacao',inclusao));
        }
    }
    public static void formatarL925099(String retorno, Relatorio result){

        Map<String,String> msgInfoIndisponivel = new Map<String,String>();
        msgInfoIndisponivel.put('sequenciaSocio',retorno.substring(0,4).trim());
        msgInfoIndisponivel.put('mensagem',retorno.substring(4,retorno.length()).trim());
        /*
        String outPutMap = '';
        for(String chave:msgInfoIndisponivel.keyset()){
            outPutMap += '\n' + chave + ':' + msgInfoIndisponivel.get(chave);
        }
        System.debug('\n\n<QUADRO L925099>\nretorno:'+retorno + outPutMap + '\n</QUADRO L925099>\n\n');
        */
        String mensagem = msgInfoIndisponivel.get('mensagem');
  
        
        if(!result.anotacoesConsultasSPCSocios.containsKey('Tabela-AnotacoesSpcSociosAdministradores')){
            result.anotacoesConsultasSPCSocios.put('Tabela-AnotacoesSpcSociosAdministradores','');
        }

        //if(result.anotacoesConsultasSPCSocios.containsKey('Tabela-AnotacoesSpcSociosAdministradores')){
            
        /*
            String tabela = ''+
            '<thead>'+
            '<tr class="slds-line-height_reset">'+
            '<th>CPF/CNPJ</th>'+
            '<th>Nome/Razão Social</th>'+
            '<th>Quantidade</th>'+
            '<th>Valor Total (R$)</th><th colspan=2>Última anotação</th></tr></thead>';
            result.anotacoesConsultasSPCSocios.put('Tabela-AnotacoesSpcSociosAdministradores',tabela);
        */

        String cnpj = result.anotacoesConsultasSPCSocios.get( '$cnpjSocio' + msgInfoIndisponivel.get('sequenciaSocio'));
        String nome = result.anotacoesConsultasSPCSocios.get( '$nomeSocio' + msgInfoIndisponivel.get('sequenciaSocio'));


        String tabela = result.anotacoesConsultasSPCSocios.get('Tabela-AnotacoesSpcSociosAdministradores');
        tabela  = tabela.replace(''+
        
        '<td class="slds-cell-wrap" >$Quantidade</td>'+
        '<td class="slds-cell-wrap" >$Valor Total (R$)</td>'+
        '<td class="slds-cell-wrap" colspan = 2 >$Última anotação</td>',
        
        '<td class="slds-cell-wrap" colspan=3 >'+ mensagem + '</td>');
        
        result.anotacoesConsultasSPCSocios.put('Tabela-AnotacoesSpcSociosAdministradores',tabela);

            /*
        result.anotacoesConsultasSPCSocios.put('Tabela-AnotacoesSpcSociosAdministradores',result.anotacoesConsultasSPCSocios.get('Tabela-AnotacoesSpcSociosAdministradores') + ''+
            '<thead>'+
                '<tr class="slds-line-height_reset">'+
                    '<td class="slds-cell-wrap" colspan=5>'+ cnpj + '</td>'+
                    '<td class="slds-cell-wrap" colspan=5>'+ nome + '</td>'+
                    '<td class="slds-cell-wrap" colspan=5>'+ mensagem +'</td>'+
                '</tr>'+
            '</thead>'+
        '');*/
    }

    

    //Consultas ao SPC dos socios e administradores
    public static void formatarL926001(String retorno, Relatorio result){
        //String descricaoErro = 'Arrumar funcao L926001';
        //System.debug('\n<ERRO>\n'+ descricaoErro +'\n</ERRO>\n');
        
        Map<String,String> consultaSPC = new Map<String,String>();
        consultaSPC.put('sequenciaSocio',retorno.substring(0,4).trim());
        consultaSPC.put('tipoPessoa',retorno.substring(4,5).trim());
        consultaSPC.put('numeroDocumento',retorno.substring(5,14).trim());
        consultaSPC.put('filial',retorno.substring(14,18).trim());
        consultaSPC.put('digitoDocumento',retorno.substring(18,20).trim());
        consultaSPC.put('sequenciaSocio',retorno.substring(20,24).trim());
        consultaSPC.put('filiacao',retorno.substring(24,25).trim());
        consultaSPC.put('nome',retorno.substring(25,95).trim());
        consultaSPC.put('quantidadeConsultas',retorno.substring(95,101).trim());
        consultaSPC.put('codigoSocio',retorno.substring(101,102).trim());
        /*
        String outPutMap = '';
        for(String chave:consultaSPC.keyset()){
            outPutMap += '\n' + chave + ':' + consultaSPC.get(chave);
        }
        System.debug('\n\n<QUADRO L926001>\nretorno:'+retorno + outPutMap + '\n</QUADRO L926001>\n\n');
        */
        if(!result.anotacoesConsultasSPCSocios.containsKey('Tabela-ConsultasSpcSociosAdimistradores')){
            result.anotacoesConsultasSPCSocios.put('Tabela-ConsultasSpcSociosAdimistradores','');
        }
        
        String cnpjOUcpf = formatarCpfOuCnpj(consultaSPC.get('numeroDocumento') + consultaSPC.get('digitoDocumento'),consultaSPC.get('tipoPessoa'),consultaSPC.get('filial'));
        //String cnpjOUcpf = '113.139.939-05';
        String nome = consultaSPC.get('nome');
        String quantidade = consultaSPC.get('quantidadeConsultas');

        String tabela = result.anotacoesConsultasSPCSocios.get('Tabela-ConsultasSpcSociosAdimistradores');
        
        tabela += ''+
        '<thead>'+
            '<tr class="slds-line-height_reset" style="border-top:solid gray 1px">'+
                '<th>CPF/CNPJ</th>'+
                '<th>Nome/Razão Social</th>'+
                '<th>Total de Consultas</th>'+
            '</tr>'+
        '</thead>'+
        '<tr class="slds-line-height_reset">'+
            '<td class="slds-cell-wrap">' + cnpjOUcpf + '</td>'+
            '<td class="slds-cell-wrap">' + nome + '</td>'+
            '<td class="slds-cell-wrap">$comOUsemDadosConsultas</td>'+
        '</tr>';
        
        result.anotacoesConsultasSPCSocios.put('Tabela-ConsultasSpcSociosAdimistradores',tabela);
    }
    public static void formatarL926099(String retorno, Relatorio result){
        
        Map<String,String> mensagemConsulta = new Map<String,String>();
        mensagemConsulta.put('sequenciaSocio',retorno.substring(0,4).trim());
        mensagemConsulta.put('mensagem',retorno.substring(4,retorno.length()).trim());
        /*
        String outPutMap = '';
        for(String chave:mensagemConsulta.keyset()){
            outPutMap += '\n' + chave + ':' + mensagemConsulta.get(chave);
        }
        System.debug('\n\n<QUADRO L926099>\nretorno:'+retorno + outPutMap + '\n</QUADRO L926099>\n\n');
        */
        if(!result.anotacoesConsultasSPCSocios.containsKey('Tabela-ConsultasSpcSociosAdimistradores')){
            result.anotacoesConsultasSPCSocios.put('Tabela-ConsultasSpcSociosAdimistradores','');
        }

        String mensagem = mensagemConsulta.get('mensagem');
        String tabela = result.anotacoesConsultasSPCSocios.get('Tabela-ConsultasSpcSociosAdimistradores');

        //if(tabela.contains('$comOUsemDadosConsultas')){
        tabela = tabela.replace('$comOUsemDadosConsultas',mensagem);
        //}
        //else{
        //    tabela += '<tr class="slds-line-height_reset"><td class="slds-cell-wrap">'+ mensagem +'</td></tr>';
        //}

        result.anotacoesConsultasSPCSocios.put('Tabela-ConsultasSpcSociosAdimistradores',tabela);
    }


    
    //PEFIN E REFIN
    public static void formatarL040101(String retorno, Relatorio result){

        Map<String,String> pendenciaFinanceiraPEFIN = new Map<String,String>();
        pendenciaFinanceiraPEFIN.put('quantidadePendencias',retorno.substring(0,9).trim());
        pendenciaFinanceiraPEFIN.put('quantidadeUltimaOcorrencia',retorno.substring(9,18).trim());
        pendenciaFinanceiraPEFIN.put('dataOcorrencia',retorno.substring(18,26).trim());
        pendenciaFinanceiraPEFIN.put('tituloOcorrencia',retorno.substring(26,38).trim());
        pendenciaFinanceiraPEFIN.put('avalista',retorno.substring(38,39).trim());
        pendenciaFinanceiraPEFIN.put('valorPendencia',retorno.substring(39,52).trim());
        pendenciaFinanceiraPEFIN.put('contrato',retorno.substring(52,68).trim());
        pendenciaFinanceiraPEFIN.put('origemPendencia',retorno.substring(68,88).trim());
        pendenciaFinanceiraPEFIN.put('filialOcorrencia',retorno.substring(88,92).trim());
        pendenciaFinanceiraPEFIN.put('subjudice-praca',retorno.substring(92,96).trim());
        pendenciaFinanceiraPEFIN.put('subjudice-distrito',retorno.substring(96,98).trim());
        pendenciaFinanceiraPEFIN.put('subjudice-vara',retorno.substring(98,100).trim());
        pendenciaFinanceiraPEFIN.put('subjudice-data',retorno.substring(100,108).trim());
        pendenciaFinanceiraPEFIN.put('subjudice-processo',retorno.substring(108,124).trim());
        pendenciaFinanceiraPEFIN.put('codigo-natureza',retorno.substring(124,127).trim());
        pendenciaFinanceiraPEFIN.put('areaReservada',retorno.substring(127,141).trim());
        pendenciaFinanceiraPEFIN.put('mensagemSubjudice',retorno.substring(141,217).trim());
        pendenciaFinanceiraPEFIN.put('valorTotalPendencia',retorno.substring(217,230).trim());
        pendenciaFinanceiraPEFIN.put('areaReservada2',retorno.substring(230,231).trim());

        /*
        String outPutMap = '';
        for(String chave:pendenciaFinanceiraPEFIN.keyset()){
            outPutMap += '\n' + chave + ':' + pendenciaFinanceiraPEFIN.get(chave);
        }
        System.debug('\n\n<QUADRO L040101>\nretorno:'+retorno + outPutMap + '\n</QUADRO L040101>\n\n');
        */

        if(result.informacoesAnotacoesNegativas.containsKey('Tabela-pendenciasFinanceirasPefin')){
            if(result.informacoesAnotacoesNegativas.get('Tabela-pendenciasFinanceirasPefin').contains('NADA CONSTA PARA O CNPJ CONSULTADO')){
                result.informacoesAnotacoesNegativas.put('Tabela-pendenciasFinanceirasPefin','<thead><tr class="slds-line-height_reset"><th>Data</th><th>Titulo</th><th>Contrato</th><th>Avalista</th><th>Origem</th><th>Valor</th></tr></thead>');
            }   
        }else{
            result.informacoesAnotacoesNegativas.put('Tabela-pendenciasFinanceirasPefin','<thead><tr class="slds-line-height_reset"><th>Data</th><th>Titulo</th><th>Contrato</th><th>Avalista</th><th>Origem</th><th>Valor</th></tr></thead>');
        }

        String data = formatarDataAAAAMMDD(pendenciaFinanceiraPEFIN.get('dataOcorrencia'));
        String titulo = pendenciaFinanceiraPEFIN.get('tituloOcorrencia');
        String contrato = pendenciaFinanceiraPEFIN.get('contrato');
        String avalista = pendenciaFinanceiraPEFIN.get('avalista');
        String origem = pendenciaFinanceiraPEFIN.get('origemPendencia');
        String valor = 'R$ ' + formatarValor(pendenciaFinanceiraPEFIN.get('valorPendencia'),0);

        result.informacoesAnotacoesNegativas.put('Tabela-pendenciasFinanceirasPefin',result.informacoesAnotacoesNegativas.get('Tabela-pendenciasFinanceirasPefin') + '<tr class="slds-line-height_reset"><td class="slds-cell-wrap" >' + data + '</td><td class="slds-cell-wrap" >' + titulo + '</td><td class="slds-cell-wrap" >' + contrato + '</td><td class="slds-cell-wrap" >' + avalista + '</td><td class="slds-cell-wrap" >' + origem + '</td><td class="slds-cell-wrap" >' + valor + '</td></tr>');   
    }
    public static void formatarL040102(String retorno, Relatorio result){

        Map<String,String> pendenciaFinanceiraREFIN = new Map<String,String>();
        pendenciaFinanceiraREFIN.put('quantidadePendencias',retorno.substring(0,9).trim());
        pendenciaFinanceiraREFIN.put('quantidadeUltimaOcorrencia',retorno.substring(9,18).trim());
        pendenciaFinanceiraREFIN.put('dataOcorrencia',retorno.substring(18,26).trim());
        pendenciaFinanceiraREFIN.put('tituloOcorrencia',retorno.substring(26,38).trim());
        pendenciaFinanceiraREFIN.put('avalista',retorno.substring(38,39).trim());
        pendenciaFinanceiraREFIN.put('valorPendencia',retorno.substring(39,52).trim());
        pendenciaFinanceiraREFIN.put('contrato',retorno.substring(52,68).trim());
        pendenciaFinanceiraREFIN.put('origemPendencia',retorno.substring(68,88).trim());
        pendenciaFinanceiraREFIN.put('filialOcorrencia',retorno.substring(88,92).trim());
        pendenciaFinanceiraREFIN.put('subjudice-praca',retorno.substring(92,96).trim());
        pendenciaFinanceiraREFIN.put('subjudice-distrito',retorno.substring(96,98).trim());
        pendenciaFinanceiraREFIN.put('subjudice-vara',retorno.substring(98,100).trim());
        pendenciaFinanceiraREFIN.put('subjudice-data',retorno.substring(100,108).trim());
        pendenciaFinanceiraREFIN.put('subjudice-processo',retorno.substring(108,124).trim());
        pendenciaFinanceiraREFIN.put('codigo-natureza',retorno.substring(124,127).trim());
        pendenciaFinanceiraREFIN.put('areaReservada',retorno.substring(127,141).trim());
        pendenciaFinanceiraREFIN.put('mensagemSubjudice',retorno.substring(141,217).trim());
        pendenciaFinanceiraREFIN.put('valorTotalPendencia',retorno.substring(217,230).trim());
        pendenciaFinanceiraREFIN.put('areaReservada2',retorno.substring(230,231).trim());

        /*
        String outPutMap = '';
        for(String chave:pendenciaFinanceiraREFIN.keyset()){
            outPutMap += '\n' + chave + ':' + pendenciaFinanceiraREFIN.get(chave);
        }
        System.debug('\n\n<QUADRO L040102>\nretorno:'+retorno + outPutMap + '\n</QUADRO L040102>\n\n');
        */
        if(!result.informacoesAnotacoesNegativas.containsKey('Tabela-pendenciasFinanceirasRefin')){
            result.informacoesAnotacoesNegativas.put('Tabela-pendenciasFinanceirasRefin','<thead><tr class="slds-line-height_reset"><th>Data</th><th>Titulo</th><th>Contrato</th><th>Avalista</th><th>Origem</th><th>Valor</th></tr></thead>');
        }

        String data = formatarDataAAAAMMDD(pendenciaFinanceiraREFIN.get('dataOcorrencia'));
        String titulo = pendenciaFinanceiraREFIN.get('tituloOcorrencia');
        String contrato = pendenciaFinanceiraREFIN.get('contrato');
        String avalista = pendenciaFinanceiraREFIN.get('avalista');
        String origem = pendenciaFinanceiraREFIN.get('origemPendencia');
        String valor = 'R$ ' + formatarValor(pendenciaFinanceiraREFIN.get('valorPendencia'),0);

        result.informacoesAnotacoesNegativas.put('Tabela-pendenciasFinanceirasRefin',result.informacoesAnotacoesNegativas.get('Tabela-pendenciasFinanceirasRefin') + '<tr class="slds-line-height_reset"><td class="slds-cell-wrap" >' + data + '</td><td class="slds-cell-wrap" >' + titulo + '</td><td class="slds-cell-wrap" >' + contrato + '</td><td class="slds-cell-wrap" >' + avalista + '</td><td class="slds-cell-wrap" >' + origem + '</td><td class="slds-cell-wrap" >' + valor + '</td></tr>');
    }
    public static void formatarL040199(String retorno, Relatorio result) {
        //ESSA MENSAGEM PODE VIR EM MAIS DE UM BLOCO, ONDE HAJAM INFORMAÇÕES A RESPEITO DE PEFIN E REFIN

        String mensagem = retorno.substring(0,retorno.length()).trim();
        //result.informacoesAnotacoesNegativas.put('Mensagem pendência financeira', );

        if(!result.informacoesAnotacoesNegativas.containsKey('Tabela-pendenciasFinanceirasPefin')){
            result.informacoesAnotacoesNegativas.put('Tabela-pendenciasFinanceirasPefin','<tr class="slds-line-height_reset"><td class="slds-cell-wrap" >' + mensagem + '</td></tr>');
        }
    }



    //Serasa Score Atacadista
    public static void formatarL070112(String retorno, Relatorio result){

        Map<string,String> limiteCreditoPJ = new Map<String,String>();
        limiteCreditoPJ.put('dataCalculo',retorno.substring(0,8).trim());
        limiteCreditoPJ.put('horaCalculo',retorno.substring(8,16).trim());
        limiteCreditoPJ.put('limite',retorno.substring(16,20).trim());
        limiteCreditoPJ.put('probabilidade',retorno.substring(20,31).trim());
        limiteCreditoPJ.put('observacao',retorno.substring(31,retorno.length()).trim());
        /*
        String outPutMap = '';
        for(String chave:limiteCreditoPJ.keyset()){
            outPutMap += '\n' + chave + ':' + limiteCreditoPJ.get(chave);
        }
        System.debug('\n\n<QUADRO L070112>\nretorno:'+retorno + outPutMap + '\n</QUADRO L070112>\n\n');
        */
        if(!result.informacoesPadrao.containsKey('Tabela-SerasaScoreAtacadista')){
            result.informacoesPadrao.put('Tabela-SerasaScoreAtacadista','');
        }

        String dataCalculo = formatarDataDDMMAAAA(limiteCreditoPJ.get('dataCalculo'));
        String horaCalculo = limiteCreditoPJ.get('horaCalculo');
        //result.informacoesPadrao.put('Tabela-SerasaScoreAtacadista',result.informacoesPadrao.get('Tabela-SerasaScoreAtacadista') + '<tr><td class="slds-cell-wrap" ><b>Informação Atualizada em:</b> ' + dataCalculo + ' às ' + horaCalculo + '</td></tr>' );

        String valorLimite = removerZeros(limiteCreditoPJ.get('limite'));
        result.informacoesPadrao.put('Tabela-SerasaScoreAtacadista',result.informacoesPadrao.get('Tabela-SerasaScoreAtacadista') + '<tr><td class="slds-cell-wrap" ><b>Limite:</b> ' + valorLimite + '</td></tr>' );

        Map<String,String> interpretacao = interpretarScore(valorLimite);
        result.informacoesPadrao.put('Tabela-SerasaScoreAtacadista',result.informacoesPadrao.get('Tabela-SerasaScoreAtacadista') + '<tr><td class="slds-cell-wrap" ><b>Interpretação:</b> ' + interpretacao.get('interpretacao') + '</td></tr>' );
    }
    public static void formatarL070113(String retorno, Relatorio result){
        
        Map<String,String> mensagemLimiteCreditoPJ = new Map<String,String>();
        mensagemLimiteCreditoPJ.put('dataCalculo',retorno.substring(0,8).trim());
        mensagemLimiteCreditoPJ.put('horaCalculo',retorno.substring(8,16).trim());
        mensagemLimiteCreditoPJ.put('mensagem',retorno.substring(16,retorno.length()).trim());
        /*
        String outPutMap = '';
        for(String chave:mensagemLimiteCreditoPJ.keyset()){
            outPutMap += '\n' + chave + ':' + mensagemLimiteCreditoPJ.get(chave);
        }
        System.debug('\n\n<QUADRO L070113>\nretorno:'+retorno + outPutMap + '\n</QUADRO L070113>\n\n');
        */
        if(!result.informacoesPadrao.containsKey('Tabela-SerasaScoreAtacadista')){
            result.informacoesPadrao.put('Tabela-LimiteCreditoPJ','');
        }

        String metodologiaUtilizada = mensagemLimiteCreditoPJ.get('mensagem');
        result.informacoesPadrao.put('Tabela-SerasaScoreAtacadista',result.informacoesPadrao.get('Tabela-SerasaScoreAtacadista') + '<tr><td class="slds-cell-wrap" ><b>metodologia utilizada:</b> ' + metodologiaUtilizada + '</td></tr>' );
    }
    public static void formatarL071199(String retorno, Relatorio result){

        Map<String,String> mensagemNaoCalculo = new Map<String,String>();
        mensagemNaoCalculo.put('data',retorno.substring(0,8).trim()); 
        mensagemNaoCalculo.put('hora',retorno.substring(8,16).trim()); 
        mensagemNaoCalculo.put('mensagem',retorno.substring(16,96).trim());
        /*
        String outPutMap = '';
        for(String chave:mensagemNaoCalculo.keyset()){
            outPutMap += '\n' + chave + ':' + mensagemNaoCalculo.get(chave);
        }
        System.debug('\n\n<QUADRO L071199>\nretorno:'+retorno + outPutMap + '\n</QUADRO L071199>\n\n');
        */
        if(!result.informacoesPadrao.containsKey('Tabela-SerasaScoreAtacadista')){
            result.informacoesPadrao.put('Tabela-SerasaScoreAtacadista','');
        }

        String data = formatarDataDDMMAAAA(mensagemNaoCalculo.get('data'));
        String hora = mensagemNaoCalculo.get('hora');
        result.informacoesPadrao.put('Tabela-SerasaScoreAtacadista',result.informacoesPadrao.get('Tabela-SerasaScoreAtacadista') + '<tr class="slds-line-height_reset"><td class="slds-cell-wrap" >Informação Atualizada em ' + data + ' às ' + hora + '</td></tr>');

        String mensagem = mensagemNaoCalculo.get('mensagem');
        result.informacoesPadrao.put('Tabela-SerasaScoreAtacadista',result.informacoesPadrao.get('Tabela-SerasaScoreAtacadista') + '<tr class="slds-line-height_reset"><td class="slds-cell-wrap" >' + mensagem + '</td></tr>');
    }



    //observacoes dados cadastrais
    public static void formatarL270199(String retorno, Relatorio result){

        Map<String,String> mensagem = new Map<String,String>();
        mensagem.put('observacao',retorno);
        /*
        String outPutMap = '';
        for(String chave:mensagem.keyset()){
            outPutMap += '\n' + chave + ':' + mensagem.get(chave);
        }
        System.debug('\n\n<QUADRO L270199>\nretorno:'+retorno + outPutMap + '\n</QUADRO L270199>\n\n');
        */
        if(!result.dadosCadEmp.containsKey('Tabela-observacoesDadosCad')){
            result.dadosCadEmp.put('Tabela-observacoesDadosCad','');
        }

        String mensagemTexto = mensagem.get('observacao');
        result.dadosCadEmp.put('Tabela-observacoesDadosCad',result.dadosCadEmp.get('Tabela-observacoesDadosCad') + '<tr class="slds-line-height_reset"><td class="slds-cell-wrap" >' + mensagemTexto + '</td></tr>');
    }



    //informacoes sobre socios e administradores
    public static void formatarL010999(String retorno, Relatorio result){
        
        Map<String,String> mensagemQuadroSocial = new Map<String,String>();
        mensagemQuadroSocial.put('mensagem',retorno.substring(0,retorno.length()));
        /*
        String outPutMap = '';
        for(String chave:mensagemQuadroSocial.keyset()){
            outPutMap += '\n' + chave + ':' + mensagemQuadroSocial.get(chave);
        }
        System.debug('\n\n<QUADRO L010999>\nretorno:'+retorno + outPutMap + '\n</QUADRO L010999>\n\n');
        */
        if(!result.informacoesSobreSociosAdministradores.containsKey('Tabela-sociosAcionistas')){
            result.informacoesSobreSociosAdministradores.put('Tabela-sociosAcionistas','');
        }
        
        String mensagem = mensagemQuadroSocial.get('mensagem');
        String tabela = result.informacoesSobreSociosAdministradores.get('Tabela-sociosAcionistas');
        tabela += '<tr class="slds-line-height_reset"><td>'+ mensagem + '</td></tr>';
        result.informacoesSobreSociosAdministradores.put('Tabela-sociosAcionistas',tabela);
    }



    //informacoes SPC
    public static void formatarL901001(String retorno, Relatorio result){
        
        Map<String,String> informacoesSPCAnotacoes = new Map<String,String>();
        informacoesSPCAnotacoes.put('dataInclusao',retorno.substring(0,8));
        informacoesSPCAnotacoes.put('dataVencimento',retorno.substring(8,16));
        informacoesSPCAnotacoes.put('tipoOperacao',retorno.substring(16,17));
        informacoesSPCAnotacoes.put('numeroContrato',retorno.substring(17,47));
        informacoesSPCAnotacoes.put('valorDebito',retorno.substring(47,62));
        informacoesSPCAnotacoes.put('nomeAssociado',retorno.substring(62,122));
        /*
        String outPutMap = '';
        for(String chave:informacoesSPCAnotacoes.keyset()){
            outPutMap += '\n' + chave + ':' + informacoesSPCAnotacoes.get(chave);
        }
        System.debug('\n\n<QUADRO L901001>\nretorno:'+retorno + outPutMap + '\n</QUADRO L901001>\n\n');
        */
        if(!result.informacoesAnotacoesNegativas.containsKey('Tabela-AnotacoesSPC')){
            String tabela = ''+
            '<thead>'+
                '<tr class="slds-line-height_reset">'+
                    '<th>Inclusão</th>'+
                    '<th>Vencimento</th>'+
                    '<th>Contrato</th>'+
                    '<th title="Comprador/Fiador/Avalista">Comprador/Fiador/Avalista</th>'+
                    '<th>Valor</th>'+
                    '<th>Cidade/UF</th>'+
                    '<th>Associado Credor</th>'+
                    '<th>Origem</th>'+
                '</tr>'+
            '</thead>';
            result.informacoesAnotacoesNegativas.put('Tabela-AnotacoesSPC',tabela);
        }
        
        String comprador;
        switch on informacoesSPCAnotacoes.get('tipoOperacao'){
            when 'C'{comprador = 'COMPRADOR';}
            when 'F'{comprador = 'FIADOR';}
            when 'A'{comprador = 'AVALISTA';}
            when else{comprador = 'INDEFINIDO';}
        }

        String dataInclusao = formatarDataDDMMAAAA(informacoesSPCAnotacoes.get('dataInclusao'));
        String vencimento = formatarDataDDMMAAAA(informacoesSPCAnotacoes.get('dataVencimento'));
        String associadoCredor = informacoesSPCAnotacoes.get('nomeAssociado');
        String contrato = informacoesSPCAnotacoes.get('numeroContrato');
        String valorAux = removerZeros(informacoesSPCAnotacoes.get('valorDebito'));
        String valor = valorAux.substring(0,valorAux.length()-2) + '.' + valorAux.substring(valorAux.length()-2,valorAux.length());

        String tabela = result.informacoesAnotacoesNegativas.get('Tabela-AnotacoesSPC');

        tabela += ''+
        '<tr class="slds-line-height_reset">'+
            '<td class="slds-cell-wrap">'+ dataInclusao +'</td>'+
            '<td class="slds-cell-wrap">'+ vencimento +'</td>'+
            '<td class="slds-cell-wrap">'+ contrato +'</td>'+
            '<td class="slds-cell-wrap">'+ comprador +'</td>'+
            '<td class="slds-cell-wrap">'+ valor +'</td>'+
            '<td class="slds-cell-wrap">$cidade/uf</td>'+
            '<td class="slds-cell-wrap">'+ associadoCredor +'</td>'+
            '<td class="slds-cell-wrap">$origem</td>'+
        '</tr>';

        result.informacoesAnotacoesNegativas.put('Tabela-AnotacoesSPC',tabela);
        /*
        if(!result.informacoesSobreSociosAdministradores.containsKey('Tabela-sociosAcionistas')){
            result.informacoesSobreSociosAdministradores.put('Tabela-sociosAcionistas','');
        }*/
    }
    public static void formatarL901002(String retorno, Relatorio result){
        
        Map<String,String> informacoesSPCAnotacoes = new Map<String,String>();
        informacoesSPCAnotacoes.put('cidade',retorno.substring(0,30));
        informacoesSPCAnotacoes.put('uf',retorno.substring(30,32));
        informacoesSPCAnotacoes.put('nomeContrato',retorno.substring(32,92));
        informacoesSPCAnotacoes.put('origem',retorno.substring(92,retorno.length()));
        /*
        String outPutMap = '';
        for(String chave:informacoesSPCAnotacoes.keyset()){
            outPutMap += '\n' + chave + ':' + informacoesSPCAnotacoes.get(chave);
        }
        System.debug('\n\n<QUADRO L901002>\nretorno:'+retorno + outPutMap + '\n</QUADRO L901002>\n\n');
        */
        String origem = informacoesSPCAnotacoes.get('origem');
        String cidadeEuf = informacoesSPCAnotacoes.get('cidade') + '/' + informacoesSPCAnotacoes.get('uf');

        String tabela = result.informacoesAnotacoesNegativas.get('Tabela-AnotacoesSPC');

        tabela = tabela.replace('$origem',origem);
        tabela = tabela.replace('$cidade/uf',cidadeEuf);

        result.informacoesAnotacoesNegativas.put('Tabela-AnotacoesSPC',tabela);
        
        /*
        if(!result.informacoesSobreSociosAdministradores.containsKey('Tabela-sociosAcionistas')){
            result.informacoesSobreSociosAdministradores.put('Tabela-sociosAcionistas','');
        }*/
    }
    public static void formatarL901003(String retorno, Relatorio result){
        
        Map<String,String> totaisSPCAnotacoes = new Map<String,String>();
        totaisSPCAnotacoes.put('quantidadeOcorrencias',retorno.substring(0,15));
        totaisSPCAnotacoes.put('totalValorDebito',retorno.substring(15,30));
        /*
        String outPutMap = '';
        for(String chave:totaisSPCAnotacoes.keyset()){
            outPutMap += '\n' + chave + ':' + totaisSPCAnotacoes.get(chave);
        }
        System.debug('\n\n<QUADRO L901003>\nretorno:'+retorno + outPutMap + '\n</QUADRO L901003>\n\n');
        */
        String quantidade = removerZeros(totaisSPCAnotacoes.get('quantidadeOcorrencias'));
        String total = formatarValor(totaisSPCAnotacoes.get('totalValorDebito'),0);

        String tabela = result.informacoesAnotacoesNegativas.get('Tabela-AnotacoesSPC');

        tabela += ''+
        '<tr class="slds-line-height_reset">'+
            '<td><b>Total de ocorrências:</b> '+ quantidade + '</td>'+
        '</tr>'+
        '<tr class="slds-line-height_reset">'+
            '<td><b>Total em reais: </b>R$ '+ total +'</td>'+
        '</tr>';

        result.informacoesAnotacoesNegativas.put('Tabela-AnotacoesSPC',tabela);
        
        /*
        if(!result.informacoesSobreSociosAdministradores.containsKey('Tabela-sociosAcionistas')){
            result.informacoesSobreSociosAdministradores.put('Tabela-sociosAcionistas','');
        }*/
    }
    public static void formatarL901099(String retorno, Relatorio result){

        if(!result.informacoesAnotacoesNegativas.containsKey('Tabela-AnotacoesSPC')){
            result.informacoesAnotacoesNegativas.put('Tabela-AnotacoesSPC','');
        }

        Map<String,String> mensagemAnotacao = new Map<String,String>();
        mensagemAnotacao.put('mensagem',retorno.substring(0,retorno.length()));

        /*
        String outPutMap = '';
        for(String chave:mensagemAnotacao.keyset()){
            outPutMap += '\n' + chave + ':' + mensagemAnotacao.get(chave);
        }
        System.debug( '\n\n<QUADRO L901099>\nretorno:' + retorno + outPutMap + '\n</QUADRO L901099>\n\n' );
        */

        String mensagem = mensagemAnotacao.get('mensagem');
        String tabela = result.informacoesAnotacoesNegativas.get('Tabela-AnotacoesSPC');
        tabela += '<tr class="slds-line-height_reset"><td>'+ mensagem +'</td></tr>';
        result.informacoesAnotacoesNegativas.put('Tabela-AnotacoesSPC',tabela);
    }



    //consultas ao SPC
    public static void formatarL907001(String retorno, Relatorio result){

        Map<String,String> consulta = new Map<String,String>();
        consulta.put('dataConsulta',retorno.substring(0,8));
        consulta.put('horaConsulta',retorno.substring(8,12));
        consulta.put('nomeAssociado',retorno.substring(12,72));
        consulta.put('cidade',retorno.substring(72,102));
        consulta.put('uf',retorno.substring(102,104));
        consulta.put('origem',retorno.substring(104,134));
        consulta.put('quantidadeConsultas',retorno.substring(134,138));
        /*
        String outPutMap = '';
        for(String chave:consulta.keyset()){
            outPutMap += '\n' + chave + ':' + consulta.get(chave);
        }
        System.debug('\n\n<QUADRO L907001>\nretorno:'+retorno + outPutMap + '\n</QUADRO L907001>\n\n');
        */
        if(!result.informacoesSobreSociosAdministradores.containsKey('Tabela-ConsultasSPC')){
            result.informacoesSobreSociosAdministradores.put('Tabela-ConsultasSPC','<thead><tr class"slds-line-height_reset"><th>Data da Consulta</th><th>CNPJ do Consultante</th><th>Razão Social do Consultante</th><th>Consultas no Dia</th></tr></thead>');
        }

        String tabela = result.informacoesSobreSociosAdministradores.get('Tabela-ConsultasSPC');
        
        String data = formatarDataDDMMAAAA(consulta.get('dataConsulta'));
        String razaoSocial = consulta.get('nomeAssociado');
        String quantidade = removerZeros(consulta.get('quantidadeConsultas'));
        // = '113.139.939-05';

        //String cnpj = result.anotacoesConsultasSPCSocios.get( '$cnpjSocioNome' + consulta.get('nomeAssociado'));
        String cnpj = 'nada ainda';

        tabela += ''+
        '<tr class="slds-line-height_reset">'+
            '<td class="slds-cell-wrap">'+ data +'</td>'+
            '<td class="slds-cell-wrap">'+ cnpj +'</td>'+
            '<td class="slds-cell-wrap">'+ razaoSocial +'</td>'+
            '<td class="slds-cell-wrap">'+ quantidade +'</td>'+
        '</tr>';

        result.informacoesSobreSociosAdministradores.put('Tabela-ConsultasSPC',tabela);
    }
    public static void formatarL907002(String retorno, Relatorio result){

        Map<String,String> totalConsultas = new Map<String,String>();
        totalConsultas.put('anoConsulta',retorno.substring(0,2));
        totalConsultas.put('mesConsulta',retorno.substring(2,4));
        totalConsultas.put('descricaoMesConsulta',retorno.substring(4,7));
        totalConsultas.put('quantidadeConsultas',retorno.substring(7,10));
        /*
        String outPutMap = '';
        for(String chave:totalConsultas.keyset()){
            outPutMap += '\n' + chave + ':' + totalConsultas.get(chave);
        }
        System.debug('\n\n<QUADRO L907002>\nretorno:'+retorno + outPutMap + '\n</QUADRO L907002>\n\n');
        */
        /*
        if(!result.informacoesSobreSociosAdministradores.containsKey('Tabela-ConsultasSPC')){
            result.informacoesSobreSociosAdministradores.put('Tabela-ConsultasSPC','<thead><tr class"slds-line-height_reset"><th>Data da Consulta</th><th>CNPJ do Consultante</th><th>Razão Social do Consultante</th><th>Consultas no Dia</th></tr></thead>');
        }

        String tabela = result.informacoesSobreSociosAdministradores.get('Tabela-ConsultasSPC');

        tabela += ''+
        '<tr class="slds-line-height_reset">'+
            '<td class="slds-cell-wrap">'+ data +'</td>'+
            '<td class="slds-cell-wrap">'+ cnpj +'</td>'+
            '<td class="slds-cell-wrap">'+ razaoSocial +'</td>'+
            '<td class="slds-cell-wrap">'+ quantidade +'</td>'+
        '</tr>';

        result.informacoesSobreSociosAdministradores.put('Tabela-ConsultasSPC',tabela);
        */
    }
    public static void formatarL907099(String retorno, Relatorio result){

        Map<String,String> mensagemConsulta = new Map<String,String>();
        mensagemConsulta.put('mensagem',retorno.substring(0,retorno.length()));
        /*
        String outPutMap = '';
        for(String chave:mensagemConsulta.keyset()){
            outPutMap += '\n' + chave + ':' + mensagemConsulta.get(chave);
        }
        System.debug('\n\n<QUADRO L907099>\nretorno:'+retorno + outPutMap + '\n</QUADRO L907099>\n\n');
        
        */
        if(!result.informacoesSobreSociosAdministradores.containsKey('Tabela-ConsultasSPC')){
            result.informacoesSobreSociosAdministradores.put('Tabela-ConsultasSPC','');
        }

        String mensagem = mensagemConsulta.get('mensagem');

        String tabela = result.informacoesSobreSociosAdministradores.get('Tabela-ConsultasSPC');
        tabela += '<tr class"slds-line-height_reset"><td class="slds-cell-wrap" >'+ mensagem +'</td></tr>';
        result.informacoesSobreSociosAdministradores.put('Tabela-ConsultasSPC',tabela);
    }

















    //sem classificacao ainda
    public static void formatarL010108(String retorno, Relatorio result) {

        Map<String,String> dividaOutroSegmento = new Map<String,String>();
        dividaOutroSegmento.put('data',retorno.substring(0,8).trim());
        dividaOutroSegmento.put('valorCapitalSocial',retorno.substring(8,21).trim());
        dividaOutroSegmento.put('valorCapitalRealizado',retorno.substring(21,34).trim());
        dividaOutroSegmento.put('origem',retorno.substring(47,59).trim());
        dividaOutroSegmento.put('controle',retorno.substring(59,71).trim());
        dividaOutroSegmento.put('natureza',retorno.substring(71,83).trim());
        
        /*
        String outPutMap = '';
        for(String chave:dividaOutroSegmento.keyset()){
            outPutMap += '\n' + chave + ':' + dividaOutroSegmento.get(chave);
        }
        System.debug( '\n\n<QUADRO L010108>\nretorno:' + retorno + outPutMap + '\n</QUADRO L010108>\n\n' );
        */

        String data = formatarDataAAAAMMDD(dividaOutroSegmento.get('data'));
        String valorCapitalSocial = Decimal.valueOf(dividaOutroSegmento.get('valorCapitalSocial')).format();
        String valorCapitalRealizado = 'R$ ' + Decimal.valueOf(dividaOutroSegmento.get('valorCapitalRealizado')).format();
        String origem = dividaOutroSegmento.get('origem');
        String controle = dividaOutroSegmento.get('controle');
        String natureza = dividaOutroSegmento.get('natureza');

        result.informacoesSobreSociosAdministradores.put('Informação Atualizada em',data);
        result.informacoesSobreSociosAdministradores.put('Capital social','R$ ' + valorCapitalSocial); 
        result.informacoesSobreSociosAdministradores.put('Valor capital realizado','R$ ' + valorCapitalRealizado);
        result.informacoesSobreSociosAdministradores.put('Origem',origem);
        result.informacoesSobreSociosAdministradores.put('Controle',controle); 
        result.informacoesSobreSociosAdministradores.put('Naturaza',natureza); 
    }
    public static void formatarL010109(String retorno, Relatorio result) {

        String cnpjOuCpf = formatarCpfOuCnpj(retorno.substring(1,10) + retorno.substring(14,16), retorno.substring(0,1) , '');        
        String nomeAcionistaOuSocioOuAdministrador   = retorno.substring(16 , 81).trim();
        String pais                                  = retorno.substring(81 , 93).trim();
        
        String percCapital       = removerZeros(retorno.substring(93 , 97)); 
        if(percCapital.length() > 1) { 
            Integer numeroCaract = percCapital.length();
            percCapital          = percCapital.substring(0, numeroCaract - 1) + ',' + 
                                    percCapital.substring(numeroCaract - 1 , numeroCaract);
        }

        String percentualDoCapital       = percCapital + '%';
        String dataDeEntrada             = formatarDataAAAAMMDD(retorno.substring(97 ,105));
        dataDeEntrada = dataDeEntrada != '00/00/0000' ? dataDeEntrada : '';	

        String percCapitalVotante       = removerZeros(retorno.substring(106,110)); 
        if(percCapitalVotante.length() > 1) { 
            Integer numeroCaract = percCapitalVotante.length();
            percCapitalVotante   = percCapitalVotante.substring(0, numeroCaract - 1) + ',' + 
                                    percCapitalVotante.substring(numeroCaract - 1 , numeroCaract);
        }

        String percentualCapitalVolante  = percCapitalVotante + '%';
        String codigoDaSituacao          = retorno.substring(110,112).trim();

        if(!result.informacoesSobreSociosAdministradores.containsKey('Tabela-sociosAcionistas')){
            result.informacoesSobreSociosAdministradores.put('Tabela-sociosAcionistas','<thead><tr class="slds-line-height_reset"><th>	CPF/CNPJ</th>	<th>Sócio/Acionista</th><th>Entrada</th><th>Nacionalidade</th><th>Cap. Votante</th><th>Cap. Total</th></tr></thead>');
        }

        result.informacoesSobreSociosAdministradores.put('Tabela-sociosAcionistas',result.informacoesSobreSociosAdministradores.get('Tabela-sociosAcionistas')+'<tr class"slds-line-height_reset"><td class="slds-cell-wrap" >'+cnpjOuCpf+'</td><td class="slds-cell-wrap" >'+nomeAcionistaOuSocioOuAdministrador+'</td><td class="slds-cell-wrap" >'+dataDeEntrada+'</td><td class="slds-cell-wrap" >'+pais+'</td><td class="slds-cell-wrap" >'+percentualCapitalVolante+'</td><td class="slds-cell-wrap" >'+percentualDoCapital+'</td></tr>');

        //variaveis para usar em outros quadros dos socios e administradores
        result.informacoesSobreSociosAdministradores.put('$'+cnpjOuCpf,nomeAcionistaOuSocioOuAdministrador);
        result.informacoesSobreSociosAdministradores.put('$entrada' + nomeAcionistaOuSocioOuAdministrador,dataDeEntrada);
        result.informacoesSobreSociosAdministradores.put('$votante' + nomeAcionistaOuSocioOuAdministrador,percentualCapitalVolante);
        result.informacoesSobreSociosAdministradores.put('$total' + nomeAcionistaOuSocioOuAdministrador,percentualDoCapital);
        // adicionar os dados ao banco de dados para poder usa-los em outros lugar
        /*
        if(!SerasaController2.bancoDeDados.containsKey('controleSocietario')){

            Map< String , List<String> > socios = new Map< String , List<String> >();


            List<String> cpfsEcnpjs = new List<String>();
            socios.put('cpfsEcnpjs',cpfsEcnpjs);
            List<String> nomes = new List<String>();
            socios.put('nomes',nomes);
            SerasaController2.bancoDeDados.put('controleSocietario', socios);
        }
        Map<String,List<String>> dadosDosSocios = SerasaController2.bancoDeDados.get('controleSocietario');
        dadosDosSocios.get('cpfsEcnpjs').add(cnpjOuCpf);
        dadosDosSocios.get('nomes').add(nomeAcionistaOuSocioOuAdministrador);
        */
    }
    public static void formatarL040501(String retorno, Relatorio result){

        Map<String,String> participacaoEmFalencia = new Map<String,String>();
        participacaoEmFalencia.put('quantidadeOcorrencias',retorno.substring(0,9));
        participacaoEmFalencia.put('dataAcaoJudial',retorno.substring(9,17));
        participacaoEmFalencia.put('tipoParticipacao',retorno.substring(17,37));
        participacaoEmFalencia.put('cnpjParticipacao',retorno.substring(37,46));
        participacaoEmFalencia.put('empresaParticipacao',retorno.substring(46,114));
        participacaoEmFalencia.put('codigoNatureza',retorno.substring(114,117));
        participacaoEmFalencia.put('areaReservada',retorno.substring(117,141));
        /*
        String outPutMap = '';
        for(String chave:participacaoEmFalencia.keyset()){
            outPutMap += '\n' + chave + ':' + participacaoEmFalencia.get(chave);
        }
        System.debug('\n\n<QUADRO L040501>\nretorno:'+retorno + outPutMap + '\n</QUADRO L040501>\n\n');
        */
    }
}

/*
String outPutMap = '';
for(String chave:dividaVencida.keyset()){
    outPutMap += '\n' + chave + ':' + dividaVencida.get(chave);
}
System.debug('\n\n<QUADRO L040701>\nretorno:'+retorno + outPutMap + '\n</QUADRO L070401>\n\n');
'<thead><tr class="slds-line-height_reset"><th></th></tr></thead>'
*/