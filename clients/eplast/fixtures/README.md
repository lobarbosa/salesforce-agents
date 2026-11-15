# Fixtures do cliente Eplast

Scripts de dado de teste (regra 6 da conta). Todo registro criado e sintetico, com prefixo identificavel, sem dado pessoal. Rodar so em `sbx-eplast-dev` ou `sbx-eplast-qa`.

## lead_roteamento_regional.apex (EPLAST-38)

Cria Leads de teste para o roteamento regional (regra `Distribuicao_Regional_Leads`) e limpa depois.

- Prefixo: `LastName` comeca por `EPLAST38-TESTE-`. A limpeza (`MODO = 'LIMPAR'`) apaga so esses registros.
- Modos: `REGRA` (cabecalho de regra, um Lead por UF + 'sp' + vazio + 'Sao Paulo'), `SIMPLES` (sem cabecalho, caminho C assincrono, exige o permission set `PS_Integracao_DistribuicaoLead` no usuario de execucao), `MASSA_REGRA` e `MASSA_SIMPLES` (200 Leads, CA-06), `MANTER_DONO` (CA-04), `LIMPAR`.
- Edite a variavel `MODO` no topo e rode: `sf apex run --file fixtures/lead_roteamento_regional.apex --target-org sbx-eplast-dev`.
- Telefone: `Phone` e `MobilePhone` ficam vazios. As validation rules `Celular` e `Telefone` (ativas) nao barram Lead sem telefone. Funcionou na dev em 2026-11-15 (30 de 30 inseridos, modo REGRA).
- Valores de picklist usados (lidos da org): `Status = 'Aberto - Não contatado'`, `LeadSource = 'Evento'`, `Sector__c = 'Alimentos'`. Pontuacao esperada: 60 (setor + origem); 100 exige `Status = 'Contatado'`.
- Resultado esperado em modo `REGRA` (conferido na dev): SP e 'sp' em Leads SP; RJ, MG, ES nas filas proprias; PR/SC/RS em Leads Sul; GO/DF/MT/MS/TO em Leads Centro-Oeste; 15 UFs de Norte e Nordeste em Leads Norte e Nordeste; vazio e 'Sao Paulo' em Leads Triagem.
- Caminho C: depois do insert, esperar o processamento assincrono antes de consultar `OwnerId`.
- Na QAS (Partial Copy), consultar so pelos Ids criados pelo script; nunca ler ou alterar registro real.
