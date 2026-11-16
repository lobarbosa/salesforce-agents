# Pré-checagem — EPLAST-46

Etapa que vai rodar: `qa` · org: `sbx-eplast-qa`. Gerado pela esteira antes da sessão; leia antes de agir e trate cada aviso no seu artefato.

## Bloqueios
- nenhum

## Outras demandas mexendo nos mesmos componentes
- EPLAST-27 (aguardando_gate_build) também mexe em: agente SFAgent2.
- EPLAST-29 (build) também mexe em: agente SFAgent2.
- EPLAST-34 (aguardando_homologacao) também mexe em: agente SFAgent2.
- EPLAST-36 (aguardando_homologacao) também mexe em: reports/MARKETINGCLOUD.
- EPLAST-37 (aguardando_homologacao) também mexe em: reports/MARKETINGCLOUD.
- EPLAST-42 (aguardando_homologacao) também mexe em: reports/MARKETINGCLOUD.
- EPLAST-43 (aguardando_homologacao) também mexe em: reports/MARKETINGCLOUD.
- EPLAST-44 (aguardando_homologacao) também mexe em: reports/MARKETINGCLOUD.
- EPLAST-45 (aguardando_homologacao) também mexe em: reports/MARKETINGCLOUD.

## Estado na org
- Agente `SFAgent2`: versões v1, v2, v3, v4, v6, v7, v8, v9; ativa: v7. Versão ativa não aceita deploy: o build cria a seguinte, inativa (skill salesforce-doutrina).
- Flow `Account_Agente_SugestaoCampanha`: tem versão ativa nesta org — mudança entra como versão nova.
