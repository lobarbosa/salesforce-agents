# Pré-checagem — EPLAST-29

Etapa que vai rodar: `build` · org: `sbx-eplast-dev`. Gerado pela esteira antes da sessão; leia antes de agir e trate cada aviso no seu artefato.

## Bloqueios
- nenhum

## Outras demandas mexendo nos mesmos componentes
- EPLAST-27 (aguardando_gate_design) também mexe em: agente SFAgent2.
- EPLAST-34 (aguardando_homologacao) também mexe em: agente SFAgent2.
- EPLAST-46 (aguardando_homologacao) também mexe em: agente SFAgent2.

## Estado na org
- Agente `SFAgent2`: versões v1, v2, v3, v4, v5, v6, v7, v8, v9, v10, v11, v12; ativa: v12. Versão ativa não aceita deploy: o build cria a seguinte, inativa (skill salesforce-doutrina).
- Flow `Task_Agente_CriarTarefa`: tem versão ativa nesta org — mudança entra como versão nova.
