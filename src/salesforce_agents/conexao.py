"""Gera o par de chaves JWT de uma sandbox sem a chave privada passar por um
chat de agente.

Não muda o modelo de conexão em nada: continua sendo Connected App + JWT
Bearer Flow por Environment do GitHub, exatamente como `docs/conexoes-e-setup.md`
e a skill `conectar-ambiente` descrevem. O que este módulo fecha é um passo que
era manual e, na prática, perigoso — achado real (Centric, 2026-10-03): pra
reusar o mesmo texto "da vez anterior", a chave privada foi colada direto na
conversa do agente, duas vezes. Chave em transcript de modelo não dá pra
"des-expor" depois (fica em log de sessão, em qualquer export/backup do chat),
diferente de um secret do GitHub, que dá pra rotacionar se vazar. Daqui pra
frente a chave nasce em arquivo local; a única coisa que aparece na saída do
comando é o caminho do arquivo e o checklist dos próximos passos manuais
(upload do .crt, cadastro dos 3 secrets) — nunca o conteúdo da chave.
"""

from __future__ import annotations

import subprocess
from dataclasses import dataclass
from pathlib import Path

from . import ambientes

DIAS_VALIDADE = 730


class OpensslAusenteError(Exception):
    """`openssl` não está no PATH."""


class CredencialJaExisteError(Exception):
    """Já existe um par de chaves local pra este cliente+ambiente."""


@dataclass(frozen=True)
class Credencial:
    client: str
    ambiente: str
    alias: str
    github_environment: str
    key_path: Path
    cert_path: Path


def _diretorio_credencial(client: str, ambiente: str, base_dir: Path) -> Path:
    # Fora de clients/<client>/force-app e fora de qualquer coisa que
    # ci-salesforce-validate.yml ou o scanner de PII rastreiem — é segredo
    # local, nunca conteúdo de demanda. `.gitignore` exclui este diretório.
    return base_dir / client / ".credenciais-local" / ambiente


def gerar_par_de_chaves(
    client: str,
    ambiente: str,
    *,
    base_dir: Path = Path("clients"),
    forcar: bool = False,
) -> Credencial:
    """Gera (ou recusa sobrescrever) o x509 self-signed + chave privada de uma sandbox.

    Levanta `ValueError` pra ambiente fora de dev/qa (mesma regra de
    `ambientes.py` — não repetida aqui, delegada), `CredencialJaExisteError`
    quando o par já existe e `forcar=False`, e `OpensslAusenteError` quando o
    binário não está disponível.
    """
    alias = ambientes.org_alias(client, ambiente)  # valida o ambiente
    github_environment = ambientes.github_environment(client, ambiente)

    destino = _diretorio_credencial(client, ambiente, base_dir)
    key_path = destino / "server.key"
    cert_path = destino / "server.crt"

    if not forcar and key_path.exists() and cert_path.exists():
        raise CredencialJaExisteError(
            f"Já existe um par em {destino} — gerar de novo sem `--forcar` arriscaria "
            f"criar uma chave que não bate mais com o certificado já carregado na "
            f"Connected App de {alias}, e a sandbox para de autenticar sem aviso. "
            f"Só use --forcar depois de já ter o plano de resubir o novo .crt na Connected App."
        )

    destino.mkdir(parents=True, exist_ok=True)

    try:
        subprocess.run(
            [
                "openssl", "req", "-x509", "-sha256", "-nodes",
                "-days", str(DIAS_VALIDADE),
                "-newkey", "rsa:2048",
                "-keyout", str(key_path),
                "-out", str(cert_path),
                "-subj", f"/CN={alias}/O={client}/OU=squad-os-pipeline",
            ],
            capture_output=True,
            text=True,
            timeout=30,
            check=True,
        )
    except FileNotFoundError as exc:
        raise OpensslAusenteError(
            "'openssl' não encontrado no PATH — instale-o antes de gerar a credencial."
        ) from exc
    except subprocess.CalledProcessError as exc:
        raise RuntimeError(
            f"openssl falhou (exit {exc.returncode}): {exc.stderr.strip()[:400]}"
        ) from exc

    # Chave privada em disco: nunca legível por outro usuário da máquina.
    key_path.chmod(0o600)

    return Credencial(
        client=client,
        ambiente=ambiente,
        alias=alias,
        github_environment=github_environment,
        key_path=key_path,
        cert_path=cert_path,
    )
