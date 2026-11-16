# Pré-checagem — EPLAST-27

Etapa que vai rodar: `qa` · org: `sbx-eplast-qa`. Gerado pela esteira antes da sessão; leia antes de agir e trate cada aviso no seu artefato.

## Bloqueios
- nenhum

## Outras demandas mexendo nos mesmos componentes
- EPLAST-29 (aguardando_gate_build) também mexe em: agente SFAgent2.
- EPLAST-34 (aguardando_homologacao) também mexe em: agente SFAgent2.
- EPLAST-46 (aguardando_gate_build) também mexe em: agente SFAgent2.

## Estado na org
- Agente `SFAgent2`: versões v1, v2, v3, v4, v6, v7, v8; ativa: v8. Versão ativa não aceita deploy: o build cria a seguinte, inativa (skill salesforce-doutrina).
- Flow `Account_Agente_ProximaAcao`: tem versão ativa nesta org — mudança entra como versão nova.
