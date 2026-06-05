# ==============================================================================
# 1. BASE: Imagen oficial y configuración de entorno inicial
# ==============================================================================
FROM kalilinux/kali-rolling:latest 

LABEL maintainer="Seguridad y Auditoría - ALL4me"
ENV DEBIAN_FRONTEND=noninteractive
ENV TERM=xterm
ENV TZ=Europe/Madrid

# ==============================================================================
# 2. SISTEMA: Actualización básica e instalación de dependencias estructurales
# ==============================================================================
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    sudo \
    ca-certificates \
    curl \
    gnupg \
    grep \
    build-essential \
    iproute2 \ 
    net-tools \    
    iputils-ping \
    xsltproc \
    python3-pip \
    python3-dev \
    git \
    nodejs \
    npm \
    openssh-server \  
    openssh-client \    
    && rm -rf /var/lib/apt/lists/*

# ==============================================================================
# 3. USUARIO: Configuración de permisos, grupos y pre-creación de rutas
# ==============================================================================
# Eliminamos el flag -G docker para que el build NO falle y no demos permisos prematuros
RUN id -u kali >/dev/null 2>&1 || \
    (useradd -m -s /bin/bash kali && \
    echo 'kali ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers)

# ==============================================================================
# 4. HERRAMIENTAS: Instalación masiva
# ==============================================================================
RUN apt-get update && apt-get install -y --no-install-recommends \
    nmap \
    dnsutils \
    netcat-traditional \
    ffuf \
    feroxbuster \
    whatweb \
    wpscan \
    sqlmap \
    nuclei \
    hydra \
    micro \
    unzip \
    fzf \
    ripgrep \
    tmux \
    seclists \
    wordlists \
    smbclient \ 
    redis-tools \ 
    default-mysql-client \
    gobuster \
    exploitdb \
    && apt-get autoremove -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN gunzip /usr/share/wordlists/rockyou.txt.gz || true

# Crear un enlace simbólico global y limpio dentro del home de kali para facilitarle la vida a la IA
RUN ln -s /usr/share/wordlists /home/kali/wordlists

# ==============================================================================
# 5. INTEGRACIÓN LEMONADE (NUEVO)
# Instalamos el binario de Lemonade para que Kali pueda hablar con el servidor
# ==============================================================================

RUN curl -Lo /tmp/lemonade.tar.gz https://github.com/pocke/lemonade/releases/download/v1.1.1/lemonade_linux_amd64.tar.gz \
    && tar -xzf /tmp/lemonade.tar.gz -C /usr/local/bin/ \
    && mv /usr/local/bin/lemonade /usr/local/bin/lemonade-clip \
    && chmod +x /usr/local/bin/lemonade-clip \
    && rm /tmp/lemonade.tar.gz

# ==============================================================================
# 6. SERVIDORES MCP Y DOCKER
# ==============================================================================
RUN npm install -g @modelcontextprotocol/server-filesystem @wonderwhy-er/desktop-commander

RUN pip3 install --no-cache-dir --break-system-packages \
    duckduckgo-search \
    openai \
    watchdog
# 2. Descarga solo el binario oficial del cliente de Docker (pesa poco y no falla)
RUN curl -fsSL https://download.docker.com/linux/static/stable/x86_64/docker-24.0.7.tgz | tar -xzf - --strip-components=1 -C /usr/bin/ docker/docker

# ==============================================================================
# 7. ENTORNO DE EJECUCIÓN
# ==============================================================================
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

WORKDIR /home/kali
USER kali

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]