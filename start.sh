#!/usr/bin/env bash
# ==============================================================================
# CarbAlium - Script de Inicialização do Servidor (Termux + Copyparty)
# ==============================================================================
# Uso:
#   chmod +x start.sh
#   ./start.sh
# ==============================================================================

# Carrega variáveis de um arquivo .env local, se existir (ideal para não expor senhas no GitHub)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/.env" ]; then
    # shellcheck disable=SC1091
    source "$SCRIPT_DIR/.env"
fi

# Configurações padrão (substitua pelas suas senhas ou crie um arquivo .env)
SERVER_NAME="${SERVER_NAME:-CarbAlium}"
ADMIN_USER="${ADMIN_USER:-admin}"
ADMIN_PASS="${ADMIN_PASS:-SUA_SENHA_ADMIN}"
COFRE_USER="${COFRE_USER:-cofre}"
COFRE_PASS="${COFRE_PASS:-SUA_SENHA_COFRE}"

# Diretórios no armazenamento do Android (atenção a maiúsculas/minúsculas)
BASE_DIR="${BASE_DIR:-/sdcard/CarbAlium}"
COFRE_DIR="${COFRE_DIR:-/sdcard/CarbAlium/cofre}"

# Encerra o loop de forma limpa ao pressionar Ctrl+C
trap 'echo -e "\n[CarbAlium] Servidor encerrado."; exit 0' INT TERM

# Ativa o wake-lock para impedir que o Android coloque a CPU em sono profundo
if command -v termux-wake-lock >/dev/null 2>&1; then
    termux-wake-lock
    echo "[CarbAlium] Wake-lock do Termux ativado."
fi

# Garante que os diretórios principais existam
mkdir -p "$BASE_DIR" "$COFRE_DIR"

echo "[CarbAlium] Iniciando '$SERVER_NAME' com autorrecuperação..."
echo "[CarbAlium] Pressione Ctrl+C (duas vezes, se necessário) para parar."

while true; do
    copyparty \
        --name "$SERVER_NAME" \
        -a "$ADMIN_USER:$ADMIN_PASS" \
        -a "$COFRE_USER:$COFRE_PASS" \
        -v "$BASE_DIR":/:rwmd,"$ADMIN_USER" \
        -v "$COFRE_DIR":/cofre:rwmd,"$ADMIN_USER","$COFRE_USER" \
        -e2ds -e2ts \
        --dav-auth

    echo "[CarbAlium] Processo interrompido. Reiniciando em 2 segundos..."
    sleep 2
done
