#!/usr/bin/env python3
"""Confere o pacote de Marketing Cloud (`mc/`) de uma demanda antes da revisão humana.

Versão 1 do agente de Marketing Cloud (2026-11-28, skill `marketing-cloud-doutrina`): ele
não se conecta à conta, então a única prova automática é esta leitura do pacote. Confere o
que, errado, sai caro depois: DE sem chave para Update, consulta que altera dado ou usa o que
o Automation Studio não aceita, e-mail sem descadastro, e dado pessoal fixo no pacote.

Uso: mc_validar_pacote.py <pasta mc/>
     mc_validar_pacote.py --assessment <clients/<cliente>/mc-assessment.md>
Sai 0 sem erro, 1 com erro (cada um numa linha), 2 com uso errado.
"""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

TIPOS = {"Text", "Number", "Decimal", "Date", "Boolean", "EmailAddress", "Phone", "Locale"}
_NOME = re.compile(r"^[A-Za-z][A-Za-z0-9_]{0,127}$")
_PROIBIDO_SQL = re.compile(r"\b(INSERT|UPDATE|DELETE|DROP|TRUNCATE|ALTER|CREATE|EXEC|EXECUTE|DECLARE|MERGE)\b", re.I)
_CTE = re.compile(r"^\s*WITH\s+\w+\s+AS\s*\(", re.I | re.M)
_CABECALHO = re.compile(r"^--\s*(destino|acao)\s*:\s*(.+?)\s*$", re.I | re.M)
_EMAIL = re.compile(r"[A-Za-z0-9._%+-]+@([A-Za-z0-9.-]+\.[A-Za-z]{2,})")
_IMG = re.compile(r"<img\b[^>]*>", re.I)
_ALT = re.compile(r"\balt\s*=", re.I)
_DESCADASTRO = re.compile(r"%%(unsub_center_url|profile_center_url)%%|unsub_center_url|profile_center_url", re.I)
_DOMINIOS_FICTICIOS = {"example.com", "example.org", "example.net"}


def _sem_comentario_sql(texto: str) -> str:
    texto = re.sub(r"/\*.*?\*/", " ", texto, flags=re.S)
    return re.sub(r"--[^\n]*", " ", texto)


def _sem_literais(texto: str) -> str:
    return re.sub(r"'(?:[^']|'')*'", "''", texto)


def validar_de(arquivo: Path) -> tuple[list[str], dict | None]:
    erros = []
    try:
        de = json.loads(arquivo.read_text(encoding="utf-8"))
    except json.JSONDecodeError as e:
        return [f"{arquivo.name}: JSON inválido ({e.msg}, linha {e.lineno})"], None
    nome = str(de.get("nome", ""))
    if not _NOME.match(nome):
        erros.append(f"{arquivo.name}: nome da DE ausente ou inválido ('{nome}')")
    campos = de.get("campos") or []
    if not campos:
        erros.append(f"{arquivo.name}: DE sem campos")
    nomes = set()
    for c in campos:
        cn = str(c.get("nome", ""))
        nomes.add(cn)
        if not _NOME.match(cn):
            erros.append(f"{arquivo.name}: campo com nome inválido ('{cn}')")
        tipo = c.get("tipo")
        if tipo not in TIPOS:
            erros.append(f"{arquivo.name}: campo {cn} com tipo desconhecido ('{tipo}')")
        if tipo == "Text" and not c.get("tamanho"):
            erros.append(f"{arquivo.name}: campo {cn} é Text sem tamanho")
    if de.get("enviavel"):
        envio = de.get("campo_de_envio")
        if envio not in nomes:
            erros.append(f"{arquivo.name}: DE enviável sem campo_de_envio entre os campos")
        if not any(c.get("tipo") == "EmailAddress" for c in campos):
            erros.append(f"{arquivo.name}: DE enviável sem campo EmailAddress")
        if any(c.get("nome") == envio and c.get("tipo") == "EmailAddress" for c in campos):
            erros.append(f"{arquivo.name}: campo_de_envio é o e-mail; use o Id do Contato ou do Lead (Subscriber Key)")
        if "retencao_dias" not in de and de.get("retencao") != "permanente":
            erros.append(f"{arquivo.name}: DE enviável sem retenção ('retencao_dias' ou '\"retencao\": \"permanente\"')")
    return erros, de


def validar_sql(arquivo: Path, des: dict[str, dict]) -> list[str]:
    erros = []
    texto = arquivo.read_text(encoding="utf-8")
    cab = {k.lower(): v for k, v in _CABECALHO.findall(texto)}
    destino, acao = cab.get("destino"), (cab.get("acao") or "").capitalize()
    if not destino:
        erros.append(f"{arquivo.name}: falta o cabeçalho '-- destino: <DE>'")
    if acao not in {"Overwrite", "Update", "Append"}:
        erros.append(f"{arquivo.name}: '-- acao:' deve ser Overwrite, Update ou Append")
    corpo = _sem_literais(_sem_comentario_sql(texto))
    if not re.search(r"\bSELECT\b", corpo, re.I):
        erros.append(f"{arquivo.name}: a consulta não tem SELECT")
    proibido = _PROIBIDO_SQL.search(corpo)
    if proibido:
        erros.append(f"{arquivo.name}: comando não aceito no Automation Studio ({proibido.group(1).upper()})")
    if re.search(r"\bSELECT\s+(DISTINCT\s+)?\*", corpo, re.I):
        erros.append(f"{arquivo.name}: SELECT * não entra no pacote; liste os campos do destino")
    if _CTE.search(corpo):
        erros.append(f"{arquivo.name}: CTE (WITH) não é aceita; use subconsulta")
    if acao == "Update" and destino in des:
        if not any(c.get("chave") for c in des[destino].get("campos", [])):
            erros.append(f"{arquivo.name}: Update em {destino}, que não tem chave primária no pacote")
    return erros


def validar_email(arquivo: Path) -> list[str]:
    erros = []
    texto = arquivo.read_text(encoding="utf-8")
    if not re.search(r"<!--\s*assunto\s*:", texto, re.I):
        erros.append(f"{arquivo.name}: falta o comentário '<!-- assunto: ... -->'")
    if not re.search(r"<!--\s*preheader\s*:", texto, re.I):
        erros.append(f"{arquivo.name}: falta o comentário '<!-- preheader: ... -->'")
    if not _DESCADASTRO.search(texto):
        erros.append(f"{arquivo.name}: sem link de descadastro (%%unsub_center_url%% ou %%profile_center_url%%)")
    for img in _IMG.findall(texto):
        if not _ALT.search(img):
            erros.append(f"{arquivo.name}: imagem sem alt ({img[:60]})")
    if "%%member_addr%%" not in texto.lower():
        erros.append(f"{arquivo.name}: rodapé sem o endereço do remetente (%%Member_Addr%%)")
    if texto.count("%%[") != texto.count("]%%") or texto.count("%%=") != texto.count("=%%"):
        erros.append(f"{arquivo.name}: bloco de AMPscript aberto sem fechar (%%[ ]%% ou %%= =%%)")
    if "%%[" in texto or "%%=" in texto:
        casos = arquivo.with_name(arquivo.stem + ".casos.md")
        linhas = [l for l in casos.read_text(encoding="utf-8").splitlines() if l.startswith("|")] if casos.is_file() else []
        # cabeçalho + separador + 3 casos (completo, campo ausente, pular)
        if len(linhas) < 5:
            erros.append(f"{arquivo.name}: com AMPscript e sem {casos.name} com ao menos 3 casos (dado completo, campo ausente, pular)")
    return erros


def validar_automacao(arquivo: Path, pasta: Path) -> list[str]:
    """Skill mc-automacao: inativa, com gatilho e notificação, SQL citado existe, Verificação antes do envio."""
    erros = []
    texto = arquivo.read_text(encoding="utf-8")
    estado = re.search(r"\*\*Estado:\*\*\s*(\w+)", texto)
    if not estado or estado.group(1).lower() != "inativa":
        erros.append(f"{arquivo.name}: a automação entra no pacote com '**Estado:** inativa'")
    for linha in ("Gatilho", "Notificação de erro"):
        if not re.search(rf"\*\*{linha}:\*\*\s*\S", texto):
            erros.append(f"{arquivo.name}: falta a linha '**{linha}:**'")
    for citado in sorted(set(re.findall(r"sql/([A-Za-z0-9_\-]+\.sql)", texto))):
        if not (pasta / "sql" / citado).is_file():
            erros.append(f"{arquivo.name}: cita sql/{citado}, que não está no pacote")
    linhas = [l.lower() for l in texto.splitlines() if l.startswith("|")]
    envio = next((i for i, l in enumerate(linhas) if "envio de e-mail" in l), None)
    if envio is not None and not any("verificação" in l for l in linhas[:envio]):
        erros.append(f"{arquivo.name}: automação com envio sem uma Verificação antes do envio")
    return erros


def validar_jornada(arquivo: Path, pasta: Path) -> list[str]:
    """Skill mc-jornada: inativa, decisões escritas, diagrama e e-mails citados no pacote."""
    erros = []
    texto = arquivo.read_text(encoding="utf-8")
    estado = re.search(r"\*\*Estado:\*\*\s*(\w+)", texto)
    if not estado or estado.group(1).lower() != "inativa":
        erros.append(f"{arquivo.name}: a jornada entra no pacote com '**Estado:** inativa'")
    for linha in ("Fonte de entrada", "Reentrada", "Classificação de envio", "Meta", "Critério de saída"):
        if not re.search(rf"\*\*{linha}:\*\*\s*\S", texto):
            erros.append(f"{arquivo.name}: falta a linha '**{linha}:**'")
    if "```mermaid" not in texto:
        erros.append(f"{arquivo.name}: falta o diagrama (bloco mermaid)")
    for citado in sorted(set(re.findall(r"conteudo/([A-Za-z0-9_\-]+\.html)", texto))):
        if not (pasta / "conteudo" / citado).is_file():
            erros.append(f"{arquivo.name}: cita conteudo/{citado}, que não está no pacote")
    return erros


def validar_readme(arquivo: Path) -> list[str]:
    """Skill marketing-cloud-doutrina: quem implanta acha a ordem, o teste e o rollback."""
    texto = arquivo.read_text(encoding="utf-8").lower()
    return [
        f"README.md: falta a seção '## {secao}'"
        for secao in ("Ordem de implantação", "Como testar", "Como desfazer")
        if f"## {secao.lower()}" not in texto
    ]


def validar_segmento(arquivo: Path) -> list[str]:
    """Skill mc-segmentacao: critério, consentimento, exclusões e tamanho esperado escritos."""
    texto = arquivo.read_text(encoding="utf-8")
    return [
        f"{arquivo.name}: falta a linha '**{linha}:**'"
        for linha in ("Critério", "Consentimento", "Exclusões", "Tamanho esperado")
        if not re.search(rf"\*\*{linha}:\*\*\s*\S", texto)
    ]


def dado_pessoal(arquivo: Path) -> list[str]:
    """E-mail fixo fora dos domínios reservados para exemplo (guardrail #2)."""
    texto = arquivo.read_text(encoding="utf-8", errors="ignore")
    reais = sorted({m.group(1).lower() for m in _EMAIL.finditer(texto)} - _DOMINIOS_FICTICIOS)
    return [f"{arquivo.parent.name}/{arquivo.name}: endereço de e-mail fixo fora de @example.com ({', '.join(reais)})"] if reais else []


def validar(pasta: Path) -> list[str]:
    erros = []
    if not (pasta / "README.md").is_file():
        erros.append("falta mc/README.md com a ordem de implantação, os donos e o rollback")
    else:
        erros += validar_readme(pasta / "README.md")
    des: dict[str, dict] = {}
    for arq in sorted((pasta / "data-extensions").glob("*.json")):
        e, de = validar_de(arq)
        erros += e
        if de:
            des[str(de.get("nome"))] = de
    for arq in sorted((pasta / "sql").glob("*.sql")):
        erros += validar_sql(arq, des)
    for arq in sorted((pasta / "conteudo").glob("*.html")):
        erros += validar_email(arq)
    for arq in sorted((pasta / "automacoes").glob("*.md")):
        erros += validar_automacao(arq, pasta)
    for arq in sorted((pasta / "segmentos").glob("*.md")):
        erros += validar_segmento(arq)
    for arq in sorted((pasta / "jornadas").glob("*.md")):
        erros += validar_jornada(arq, pasta)
    for arq in sorted(p for p in pasta.rglob("*") if p.is_file()):
        erros += dado_pessoal(arq)
    return erros


SEVERIDADES = {"crítica", "alta", "média", "baixa"}
_COLUNAS_ASSESSMENT = ["#", "Área", "Achado", "Severidade", "Evidência", "Correção", "Dono"]


def validar_assessment(arquivo: Path) -> list[str]:
    """Skill mc-arquitetura-da-conta: tabela de achados completa, severidade válida, sem dado pessoal."""
    erros = []
    linhas = arquivo.read_text(encoding="utf-8").splitlines()
    try:
        i = next(n for n, l in enumerate(linhas) if l.strip().lower().startswith("## achados"))
    except StopIteration:
        return [f"{arquivo.name}: falta a seção '## Achados'"]
    tabela = []
    for l in linhas[i + 1 :]:
        if l.startswith("## "):
            break
        if l.startswith("|"):
            tabela.append([c.strip() for c in l.strip().strip("|").split("|")])
    if not tabela or tabela[0] != _COLUNAS_ASSESSMENT:
        return erros + [f"{arquivo.name}: a tabela de achados tem as colunas {' | '.join(_COLUNAS_ASSESSMENT)}"]
    for linha in tabela[2:]:
        num = linha[0] if linha else "?"
        if len(linha) != len(_COLUNAS_ASSESSMENT):
            erros.append(f"{arquivo.name}: achado {num} com {len(linha)} colunas")
            continue
        if linha[3].lower() not in SEVERIDADES:
            erros.append(f"{arquivo.name}: achado {num} com severidade '{linha[3]}' (crítica, alta, média ou baixa)")
        for col, nome in ((4, "evidência"), (5, "correção"), (6, "dono")):
            if not linha[col] or linha[col] in {"-", "—"}:
                erros.append(f"{arquivo.name}: achado {num} sem {nome}")
    if not any(l.strip().lower().startswith("## não verificado") for l in linhas):
        erros.append(f"{arquivo.name}: falta a seção '## Não verificado' (pode ficar vazia, mas existe)")
    return erros + dado_pessoal(arquivo)


def main(argv: list[str]) -> int:
    if len(argv) == 2 and argv[0] == "--assessment" and Path(argv[1]).is_file():
        erros = validar_assessment(Path(argv[1]))
        for e in erros:
            print(f"ERRO {e}")
        print(f"{len(erros)} erro(s)")
        return 1 if erros else 0
    if len(argv) != 1 or not Path(argv[0]).is_dir():
        print(__doc__, file=sys.stderr)
        return 2
    erros = validar(Path(argv[0]))
    for e in erros:
        print(f"ERRO {e}")
    print(f"{len(erros)} erro(s)")
    return 1 if erros else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
