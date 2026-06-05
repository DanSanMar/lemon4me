#!/bin/bash

set -e

# --- 1. Configuración de Variables y PATH ---
# Mantenemos tu PATH original y variables de modelos
export PATH="/home/kali/.local/bin:/usr/local/bin:$PATH"

# --- 1. Forzar la resolución del Host ---
echo "[setup] Verificando conectividad de red con el backend..."

# Intentamos resolver la IP de lemonade antes de seguir
# Esto "obliga" al DNS de Docker a despertarse
TARGET_HOST="lemonade"
MAX_RETRIES=15
COUNT=0

while ! getent hosts $TARGET_HOST > /dev/null; do
  COUNT=$((COUNT+1))
  if [ $COUNT -ge $MAX_RETRIES ]; then
    echo "❌ ERROR: No se puede encontrar el host '$TARGET_HOST' en la red de Docker."
    exit 1
  fi
  echo " esperando a que '$TARGET_HOST' sea visible ($COUNT/$MAX_RETRIES)..."
  sleep 2
done

echo "✅ Host '$TARGET_HOST' detectado. Procediendo a la carga..."

# Ahora definimos la API sabiendo que el host responde

MODEL_NAME="${DEFAULT_MODEL:-Qwen3-0.6B-GGUF}"

# --- 2. Inyectar PATH en .bashrc ---
if ! grep -q ".local/bin" /home/kali/.bashrc; then
    echo 'export PATH="/home/kali/.local/bin:$PATH"' >> /home/kali/.bashrc
    chown kali:kali /home/kali/.bashrc
fi

# --- 3. Definición de URLs (Sin duplicados) ---
# Si LEMONADE_SERVER tiene "/api/v1", lo quitamos para manejarlo nosotros
CLEAN_URL=$(echo "${LEMONADE_SERVER:-http://lemonade:13305}" | sed 's|/api/v1||g' | sed 's|/$||')
API_BASE="$CLEAN_URL/api/v1"

echo "-----------------------------------------------------"
echo "[setup] Estabilizando red interna..."
echo "-----------------------------------------------------"

sleep 5

# --- Carga de Modelos Secuencial ---
echo "[setup] Empezamos con Lemonade..."
echo "-----------------------------------------------------"
echo "🚀 Comprobando o el servicio, si es necesario, se descargarán los modelos prestablecidos..."
echo "-----------------------------------------------------"

# --- 1. Sonda de Cortesía (Check de supervivencia de Lemonade) ---
echo "[setup] Verificando si Lemonade está despierto..."
CONNECTED=false
for i in {1..5}; do
    if curl -s "$API_BASE/models" > /dev/null; then
        echo "✅ Lemonade responde."
        CONNECTED=true
        break
    fi
    echo "  (Intento $i/5) Lemonade no responde, esperando 3s..."
    sleep 3
done

# --- 2. Lógica de Carga Inteligente ---
if [ "$CONNECTED" = true ]; then
    # Obtenemos la lista de modelos actuales
    MODELOS_ACTUALES=$(curl -s "$API_BASE/models")

    # Función interna para no repetir código
    enviar_carga() {
        local MODELO=$1
        local ETIQUETA=$2
        if [ -n "$MODELO" ]; then
            # SI el modelo ya aparece en la lista, no hacemos el POST
            if echo "$MODELOS_ACTUALES" | grep -q "$MODELO"; then
                echo "[check] $ETIQUETA ($MODELO) ya está cargado. Saltando..."
            else
                echo "[setup] Solicitando $ETIQUETA: $MODELO"
                curl -s -X POST "$API_BASE/load" \
                    -H "Content-Type: application/json" \
                    -d "{\"model_name\": \"$MODELO\"}"
                echo -e "\n[setup] Esperando 5s para estabilizar..."
                sleep 5
            fi
        fi
    }

    enviar_carga "$DEFAULT_MODEL" "Modelo Base"
    enviar_carga "$CODE_MODEL" "Modelo de Código"
    enviar_carga "$TEXT_MODEL" "Modelo de Texto"

    echo "✅ Gestión de modelos finalizada."

else
    echo "❌ Lemonade no respondió tras 5 intentos. Saltando pre-carga para evitar bloqueo."
    echo "⚠️ Deberás cargar los modelos manualmente desde Open WebUI."
fi

echo "[ok] Continuando con la configuración de herramientas de Kali..."

# --- 6. Finalización y Persistencia ---
echo "--------------------------------------------------------"
echo "   SISTEMA ACTIVO: Lemonade + Kali Workspace"
echo "   MODELOs CARGADOs: $MODEL_NAME, $CODE_MODEL, $TEXT_MODEL"
echo "--------------------------------------------------------"
echo "🚀 Iniciando espacio de trabajo Kali..."

# --- 5. Gestión de Repositorios ---
echo "[gitclone] Verificando repositorios..."

REPO_DIR="/home/kali/scan4me"

# Comprobamos si existe la carpeta Y si realmente tiene la estructura de git
if [ -d "$REPO_DIR" ] && [ -d "$REPO_DIR/.git" ]; then
    echo "[gitclone] El repositorio ya existe. Actualizando con git pull..."
    # Usamos || true para que 'set -e' no mate el script si el pull falla por red o conflicto
    (cd "$REPO_DIR" && git pull) || echo "[⚠️ WARNING] No se pudo hacer pull, continuando con lo que hay..."
else
    echo "[gitclone] Carpeta no existe o no es un repo Git válido. Clonando por primera vez..."
    # Borramos de forma segura si existe algo residual
    rm -rf "$REPO_DIR"
    
    # Clonamos. Si falla, aquí sí queremos saberlo
    git clone https://github.com/DanSanMar/SCAN4ME_AUTO.git "$REPO_DIR"
fi

#if [ ! -d "/home/kali/deploy4me/.git" ]; then
#    echo "[gitclone] Clonando MINIdeploy4me..."
#    git clone https://github.com/DanSanMar/Deploy4me.git /home/kali/deploy4me
#else
#    echo "[gitclone] MINIdeploy4me ya existe, omitiendo clonado."
#fi

# --- 6. Configuración de permisos y estructuras (Tu lógica intacta) ---
echo "[setup] Ajustando permisos y carpetas..."
chown -R kali:kali /home/kali 2>/dev/null || true
find /home/kali -name '*.sh' -exec chmod +x {} \; 2>/dev/null || true

DIRECTORIOS=(
    "/home/kali/evidences"
    "/home/kali/scripts"
    "/home/kali/reports" 
    "/home/kali/dockerlabs"
)

for dir in "${DIRECTORIOS[@]}"; do
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir"
        echo "[setup] Carpeta creada: $dir"
    fi
done

# --- Verificación dinámica del motor en el arranque del contenedor ---
if [ -f /proc/version ] && grep -q "microsoft" /proc/version && [ -e /dev/dxg ]; then
    echo "[setup HARDWARE] Corriendo bajo arquitectura optimizada AMD en WSL."
    echo "[setup AMD] Recuerda meter el turbo desde tu POWERSHELL con: .\xrt-smi configure --pmode turbo"
else
    echo "[setup HARDWARE] Corriendo bajo arquitectura optimizada NVIDIA / Estándar."
    echo "[setup NVIDIA] Monitorea la VRAM y consumo usando 'nvidia-smi' desde tu máquina host."
fi

# Comando para ver el consumo de VRAM real desde la perspectiva de la API
echo "[check] Memoria VRAM asignada al modelo:"
curl -s "$API_BASE/models" | jq '.data[0].res_path' 2>/dev/null || echo "Info de memoria no disponible aún."

# Crear un alias global para interactuar con el servidor de IA
# --- 6. Finalización y Alias ---
# Añadimos el alias asegurando que no se duplique
if ! grep -q "alias ia4me=" /home/kali/.bashrc; then
    echo "alias ia4me='curl -s http://lemonade:13305/api/v1'" >> /home/kali/.bashrc
    # Nota: He usado 'ia4me' porque 'lemonade' ya existe como binario en el Dockerfile
fi
# Generar claves SSH si no existen
if [ ! -f /etc/ssh/ssh_host_rsa_key ]; then
    echo "[*] Generando claves SSH..."
    ssh-keygen -A
fi

# Iniciar el servicio SSH
echo "[*] Iniciando SSH..."
service ssh start

# --- NUEVO: Arrancar el Watchdog del Agente de IA en segundo plano ---
echo "[*] Iniciando Watchdog del Agente Autónomo de IA..."
python3 -u /home/kali/scripts/agent_pentest.py > /home/kali/evidences/agent_daemon.log 2>&1 &

# --- 7. Finalización y Estabilización (EVITA EL REINICIO) ---
echo "------------------------------------------------"
echo "[ok] Kali Workspace listo. Agente preparado.Entrando como usuario kali...será la buena o no?"
echo "------------------------------------------------"
# Mantener el contenedor vivo (Tu bucle original)
echo "[+] Kali Workspace está listo y vigilando laboratorios."

while true; do
    sleep 3600
done

#echo "[info] Contenedor en segundo plano. Usa 'docker exec -it kali_workspace zsh' para entrar."
#exec "$@"
#tail -f /dev/null