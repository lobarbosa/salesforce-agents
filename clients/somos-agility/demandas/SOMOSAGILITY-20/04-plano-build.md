**Resultado do build:** bloqueado

# Plano de build SOMOSAGILITY-20

**Org confirmada (`sf org list`):** `sbx-somos-agility-dev` (conectada). Nada foi tocado nela.

## Por que está bloqueado

O design (`03-design.md`, seções 3 e 7 / riscos R3 e R4) declara 6.1 e 6.3 como bloqueio para o build.
Conferido em `comentarios-do-card.md`: o cliente **não respondeu**. O único retorno é de 2026-11-23 20:14:
"Agendar reunião com area responsavel (Renovações - vanessa) para entender os gatilhos". Ou seja, a
resposta ainda vai ser colhida em reunião, e não há resposta registrada para as perguntas de 12/11.
Aprovar o gate de design não responde a pergunta de negócio. As premissas 6.2, 6.4, 6.5 e 6.6 também
não têm confirmação do cliente no card (seguem como premissas do design).

## Perguntas que faltam

1. **6.1 Gatilho / objeto de origem.** A oportunidade de renovação nasce de (a) `Hist_rico_de_Venda_e_Renova_o__c.Pr_ximo_Vencimento__c`, (b) `Asset.Vencimento_Subscri_o__c` (exige campo novo de vínculo e volta ao arquiteto, R4) ou (c) `Contract`? Muda o objeto do Flow e o nome dele. Quem responde: Renovações (Vanessa Ranieri), na reunião pedida no card.
2. **6.3 Elegibilidade.** Quais registros entram: `Classe_de_renovacao__c` (excluir quais?), `Tipo_do_Evento__c`, só o mais recente (`E_o_mais_recente__c`)? Quem responde: Renovações.
3. Recomendado confirmar na mesma reunião: 6.2 (90 dias), 6.4 (dono = usuário de Renovações), 6.5 (padrão do Name), 6.6 (1 oportunidade por HVR).

## O que NÃO foi feito

Nenhum metadata escrito, nenhum deploy, nenhum Flow ou Custom Label criado. Não escolhi o objeto de origem.

## Próximo passo

Registrar as respostas de 6.1 e 6.3 no card e devolver a demanda ao gate de design para ajustar o
`03-design.md`; só então o build pode arrancar.
