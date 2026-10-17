public class SheduleInvoiceOrderSendEmail implements Schedulable {

	public void execute(SchedulableContext sc) {


		// Obtém o horário atual
		DateTime currentDateTime = DateTime.now();
		Time currentTime = currentDateTime.time();

		// Define o intervalo de tempo desejado, por exemplo, entre 07:30 e 21:00
		Time startTime = Time.newInstance(7, 30, 0, 0); // 07:30
		Time endTime = Time.newInstance(21, 0, 0, 0); // 21:00

		// Verifica se o horário atual está dentro do intervalo desejado
		if (currentTime >= startTime && currentTime <= endTime) {
			// Coloque aqui a lógica que deve ser executada apenas no horário determinado
			System.debug('Executando dentro do horário especificado.');

			sendOrderEmail();

		} else {
			System.debug('Fora do horário especificado.');
		}


	}

	public static void sendOrderEmail() {

		Set<String> Ids = new Set<String> ();
		List<PedidoEmail__c> peList = new List<PedidoEmail__c> ();
		List<PedidoEmail__c> emList = new List<PedidoEmail__c> ();
		List<PedidoEmail__c> resultList = new List<PedidoEmail__c> ();

		List<order> orderSend = new List<order> ();

       	if (Test.isRunningTest()) {
            // Durante testes, busca todos os registros sem verificar o campo Delay__c
            peList = [Select Id, Order__c, Order__r.OrderNumber, Tipo__c, ContatoPrincipal__c, NFNumero__c, Link_NFe__c, CodigoTOTVS__c from PedidoEmail__c where CreatedDate = Today and Tipo__c in('02')
		          and Executado__c = false];
        } else {
            // Em produção, aplica a verificação do campo Delay__c
            peList = [Select Id, Order__c, Order__r.OrderNumber, Tipo__c, ContatoPrincipal__c, NFNumero__c, Link_NFe__c, CodigoTOTVS__c from PedidoEmail__c where CreatedDate = Today and Tipo__c in('02')
                      and Executado__c = false and Delay__c >= 5 and ContatoPrincipal__c != null limit 10];
        }

		for (PedidoEmail__c pe : peList) { Ids.add(pe.Order__c); }


		//orderSend = [select id, Account.Name, Account.beeCnpj__CNPJ__c, Account.EnderecoEntregaCompleto__c, CodigoTOTVS__c, CondicaoPagamento__r.Name,
		//FormaPagamento__c, UnidadeFilial__r.Name, TipoFrete__c, Account.ContatoPrincipal__c from Order where Id in :ids];

		Map<id, Order> orderMap = new Map<id, Order> ([select id, Account.Name, Account.beeCnpj__CNPJ__c, Account.EnderecoEntregaCompleto__c, CodigoTOTVS__c, CondicaoPagamento__r.Name,
		                                              FormaPagamento__c, UnidadeFilial__r.Name, TipoFrete__c, Account.ContatoPrincipal__c from Order where Id in :ids]);

		List<OrderItem> orderItemList = new List<OrderItem> ([select OrderId, NP__c, Product2.Description, Quantidade__c, DataEntrega__c, NotaFiscal__c, NFNumero__c, Status__c, CodigoTOTVS__c
		                                                     from OrderItem where OrderId in :ids]);

		// Obtém os e-mails da custom label
        List<String> standardEmails = System.Label.StandartEmails.split(',');
		System.debug('List size: ' + peList.size());
        
		for (PedidoEmail__c od : peList) {

			Order occ = orderMap.get(od.Order__c);
            
            Account acc = [SELECT Id, Name, Owner.Email
                           FROM Account
                           WHERE Id =: occ.AccountId];            

			String emailBody = '';
			emailBody += '<html>';
			emailBody += '<body>';
			emailBody += '<font face="arial" size="2">';
            // Mensagem do LGPD
            emailBody += '<p style="color: red;">"Quando Sr./Sra. solicita, por abertura de Cadastro ou emissão de pedido de compra, os serviços e produtos da Mais Polímeros, o Sr./Sra. expressamente outorga o seu consentimento para que a Mais Polímeros colete seus DADOS.</p>';
            emailBody += '<p style="color: red;">Os DADOS pessoais coletados ou aqueles que de alguma forma possam identificar Sr./Sra.; ou sócios, administradores e representantes legais das empresas serão coletados neste processo, tais como denominação social, nome, telefone, CPF ou CNPJ, endereço, e-mail e dados financeiros. Apenas alguns DADOS que Sr./Sra. compartilha e que podemos te identificar são DADOS pessoais e estão protegidos pela Política de Privacidade de Dados da Mais Polímeros (PPD).</p>';
            emailBody += '<p style="color: red;">Os DADOS serão mantidos no banco de dados da Mais Polímeros enquanto mantivermos as nossas relações comerciais, com um Cadastro ativo e OC ativa e pelo prazo de 5 (cinco) anos após tal prazo."</p>';

			emailBody += '<p style="color:  #110555;"><b>Segue informações do pedido, qualquer dúvida, favor entrar em contato com o seu representante comercial.</b></p>';
			emailBody += '<br/>';

			If (occ.TipoFrete__c == 'F') {
				emailBody += '<img src="https://maispolimeros--qa.sandbox.my.salesforce.com/servlet/servlet.ImageServer?id=015be0000009X6P&oid=00Dbe0000007CCX&lastMod=1725556877000"/>';
			} else {
				emailBody += '<img src="https://maispolimeros--qa.sandbox.my.salesforce.com/servlet/servlet.ImageServer?id=015be0000009X3B&oid=00Dbe0000007CCX&lastMod=1725556816000"/>';
			}

			//emailBody += '</p>';

			emailBody += '<p style="color:  #110555;">';
			//emailBody += 'Chave da NFe: ' + od.Link_NFe__c;
			emailBody += '<br/><br/>Chave da NFe: <a href="' + od.Link_NFe__c + '">Clique aqui</a>';
			emailBody += '<br/><br/><b>Comprador: ' + occ.Account.Name + '</b>';
			emailBody += '<br/>CNPJ: ' + occ.Account.beeCnpj__CNPJ__c;
			emailBody += '<br/>Endereço: : ' + occ.Account.EnderecoEntregaCompleto__c + '</p>';

			emailBody += '<p style="color:  #110555;"><b>Pedido: ' + od.CodigoTOTVS__c + '</b>';
			emailBody += '<br/>Condição de Pagamento: ' + occ.CondicaoPagamento__r.Name;
			emailBody += '<br/>Forma de Pagamento: ' + occ.FormaPagamento__c;
			emailBody += '<br/>Filial de Embarque: ' + occ.UnidadeFilial__r.Name;
			emailBody += '<br/>Tipo de Frete: ' + occ.TipoFrete__c + '</p>';

			emailBody += '<table border="0" style="border: solid #CCCCCC; border-width: 1">';
			emailBody += '<tr style="border: solid #CCCCCC; border-width: 13">';
			emailBody += '<th style="font-size: 12px; font-face: arial; color: white; background: #110555; border-width: 1; text-align: center">Produto</th>';
			emailBody += '<th style="font-size: 12px; font-face: arial; color: white; background: #110555; border-width: 1; text-align: center">Descrição</th>';
			emailBody += '<th style="font-size: 12px; font-face: arial; color: white; background: #110555; border-width: 1; text-align: center">Quantidade</th> ';
			emailBody += '<th style="font-size: 12px; font-face: arial; color: white; background: #110555; border-width: 1; text-align: center">Data de Entrega</th>';
			emailBody += '</tr>';

			for (orderItem items : orderItemList) {
				if (od.NFNumero__c == items.NFNumero__c && items.Status__c == 'Faturado') {
					emailBody += '<tr style = "border: solid #110555; border-width: 13">';
					emailBody += '<td style = "font-size: 12px; font-face: arial; color:  #110555; text-align: center">' + items.NP__c + '</td>';
					emailBody += '<td style = "font-size: 12px; font-face: arial; color:  #110555; text-align: center">' + items.Product2.Description + '</td>';
					emailBody += '<td style = "font-size: 12px; font-face: arial; color:  #110555; text-align: center">' + items.Quantidade__c + '</td>';
					emailBody += '<td style = "font-size: 12px; font-face: arial; color:  #110555; text-align: center">' + items.DataEntrega__c.format() + '</td>';
					emailBody += '</tr>';
				}
			}

			emailBody += '</table>';
			emailBody += '<br/>';
			emailBody += '<p style="color:  #110555;">Atenciosamente,';
			emailBody += '<br/>Mais Polímeros do Brasil LTDA.';
			emailBody += '<br/>(11) 4446-4444</p>';
			emailBody += '<img src="https://maispolimeros--qa.sandbox.file.force.com/servlet/servlet.ImageServer?id=015be0000008vdp&oid=00Dbe0000007CCX&lastMod=1726149962000"/>';
			emailBody += '</font>';
			emailBody += '</body>';
			emailBody += '</html>';
            
            // Cria a lista de destinatários
            List<String> recipients = new List<String>();
            recipients.add(od.ContatoPrincipal__c);
            recipients.add(acc.Owner.Email);
            recipients.addAll(standardEmails);
            System.debug('Email send to: ' + recipients);

            // Envia o e-mail para todos os destinatários
            EmailManager emn = new EmailManager();
            emn.sendMail(recipients, 'Nota Fiscal Emitida: N° ' + od.CodigoTOTVS__c, emailBody);

			PedidoEmail__c emails = new PedidoEmail__c();
			emails.Id = od.Id;
			emails.Executado__c = true;
			resultList.add(emails);

		}

		Database.SaveResult[] srList = Database.update(resultList, false);

		// Iterate through each returned result
		for (Database.SaveResult sr : srList) {
			if (sr.isSuccess()) {
				// Operation was successful, so get the ID of the record that was processed
				System.debug('Successfully update PedidoEmail ID: ' + sr.getId());
			}
			else {
				// Operation failed, so get all errors                
				for (Database.Error err : sr.getErrors()) {
					System.debug('The following error has occurred.');
					System.debug(err.getStatusCode() + ': ' + err.getMessage());
					System.debug('Account fields that affected this error: ' + err.getFields());
				}
			}
		}
	}
}