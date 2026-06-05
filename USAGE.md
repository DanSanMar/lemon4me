# GUÍA DE USUARIO Y REQUERIMIENTOS: IA PENTEST LAB (LEMONADE)

Este proyecto despliega un laboratorio autónomo de ciberseguridad industrial y pruebas de penetración apoyado por modelos de lenguaje locales (LLMs). Cuenta con un sistema de orquestación dual automática que optimiza el rendimiento explotando al máximo tarjetas gráficas tanto **NVIDIA (CUDA)** como **AMD (ROCm/DirectX)**.

## 1. Requerimientos Previos (Hardware y Software)

Antes de lanzar el proyecto, la máquina Host (tu PC) debe cumplir con los siguientes requisitos mínimos:

### A. Requisitos de Software (Comunes)

- **Sistema Operativo:** Windows 10/11 de 64 bits con **WSL2** instalado (Ubuntu recomendado) o **Linux Nativo** (Ubuntu/Debian/Arch).
    
- **Docker Desktop:** Instalado en el Host, con la opción _“Use the WSL 2 based engine”_ activada (en Windows).
    
- **Python 3.x:** Instalado en el sistema Host (necesario para lanzar el script selector `init_platform.py`).
    

### B. Requisitos de Hardware y Controladores (Según tu GPU)

- **Si tu máquina actual usa NVIDIA:**
    
    - Drivers de NVIDIA oficiales actualizados en el Host.
        
    - Habilidad de ejecutar el comando `nvidia-smi` en la terminal del Host de forma exitosa.
        
    - _(Solo si usas Linux nativo)_: Haber instalado el `nvidia-container-toolkit`. En Windows/WSL2, Docker Desktop lo gestiona de forma automática.
        
- **Si tu máquina actual usa AMD:**
    
    - Drivers gráficos AMD Radeon / Ryzen actualizados.
        
    - Soporte para aceleración a través del puente de Windows/WSL (`/dev/dxg`).
        
    - _(Opcional para NPUs Ryzen AI)_: Herramienta `xrt-smi` ubicada en la ruta por defecto (`C:\Windows\System32\AMD\xrt-smi.exe`) para optimización avanzada de NPU.
        

## 2. Preparación del Entorno (Estructura de Archivos)

Asegúrate de que la carpeta del proyecto (por ejemplo, `C:\Users\tu_usuario\Documents\lemonade4me`) contenga la siguiente estructura de archivos antes de empezar:

Plaintext

```
lemonade4me/
├── docker-compose.yml          # Estructura base común
├── docker-compose.nvidia.yml   # Parámetros de aceleración CUDA
├── docker-compose.amd.yml      # Parámetros de aceleración ROCm/WSL
├── init_platform.py            # Orquestador y selector automático (Python Host)
├── agent_pentest.py            # El cerebro del Agente de IA (Kali)
├── init_dockerlabs.py          # Automatizador de despliegue de víctimas (Dockerlabs)
├── entrypoint.sh               # Script de inicialización interna de Kali
├── .env                        # Archivo oculto con tus variables de entorno privadas
├── dockerlabs/                 # 📂 Carpeta donde tirarás los laboratorios (.tar / scripts)
├── kalievi/                    # 📂 Carpeta local donde la IA guardará evidencias
├── kalirep/                    # 📂 Carpeta local donde la IA exportará los reportes finales
└── kalidep/                    # 📂 Carpeta de comunicación interna (active_lab.txt)
```

### Configuración del archivo `.env`

Crea un archivo de texto llamado `.env` en la raíz del proyecto con el siguiente contenido (ajústalo a tus necesidades):

Fragmento de código

```
WEBUI_SECRET_KEY=UnaClaveUltraSecretaParaTuLoginWebUI
HF_API_KEY=tu_token_de_hugging_face_aqui_si_quieres_usar_ia_en_nube
```

_(Nota: Si dejas `HF_API_KEY` vacío, el sistema forzará automáticamente el uso de la IA 100% Local en tu hardware)._

## 3. Arquitectura del Laboratorio

Para entender cómo interactúan los componentes cuando el sistema está encendido, observa el flujo de comunicación interna:

El contenedor de **Kali Workspace** es el auditor y cuenta con las herramientas de ataque; **Lemonade Server** actúa como el motor de razonamiento de IA; **Dockerlabs** aísla y monta los entornos objetivo (víctimas); y **Open-WebUI** te permite supervisar o interactuar directamente con la inteligencia artificial a través de una interfaz de chat amigable.

## 4. Guía de Uso Diario (Flujo de Trabajo)

### Paso 1: Encender el Laboratorio

Abre tu terminal del Host (PowerShell, CMD o Terminal de Linux), sitúate en la raíz del proyecto y ejecuta:

Bash

```
python init_platform.py
```

El script evaluará tus componentes, inyectará las dependencias adecuadas de hardware (AMD o NVIDIA) y levantará los 4 contenedores en segundo plano.

### Paso 2: Lanzar un Objetivo (Máquina Víctima)

El sistema monitoriza de forma constante la carpeta local `dockerlabs/`.

1. Descarga o mueve el archivo de la máquina que quieras auditar (por ejemplo, un archivo `.tar` o script de despliegue de DockerLabs) dentro de la carpeta `./dockerlabs/`.
    
2. El contenedor `labs_dockerd` detectará el archivo de forma automática, extraerá el laboratorio y desplegará la máquina de pruebas de forma aislada dentro de la red compartida `pentest_net`.
    

### Paso 3: Activación del Agente Autónomo de IA

Una vez desplegada la víctima, el orquestador escribirá de forma automatizada los datos del objetivo en el archivo de control (`active_lab.txt`) dentro de la carpeta compartida:

1. El script `agent_pentest.py` (Watchdog de Kali) detecta que hay una nueva IP activa en el laboratorio.
    
2. Inmediatamente invoca a `autoscan4me.sh` para mapear los puertos, servicios y vulnerabilidades de la víctima.
    
3. Al terminar el escaneo, el Agente procesa el reporte, se conecta localmente a `lemonade_server` (exprimiendo tu GPU AMD/NVIDIA) para razonar la estrategia de ataque y procede a ejecutar las pruebas de explotación autónoma.
    

### Paso 4: Revisar Resultados

- **Logs en vivo:** Si quieres ver qué está pensando el agente o qué comandos está ejecutando en este preciso momento en Kali, abre una terminal en el host y ejecuta:
    
    Bash
    
    ```
    # En Windows (PowerShell) o Linux:
    tail -f kalievi/agent_daemon.log
    ```
    
- **Reportes finales:** Una vez concluida la auditoría, dirígete a tu carpeta local `./kalirep/` en el host. Allí encontrarás los informes detallados generados por la Inteligencia Artificial.
    

## 5. Acceso a las Interfaces de Usuario

Mientras el laboratorio esté en ejecución, puedes acceder a los siguientes servicios desde el navegador web de tu máquina host:

1. **Open-WebUI (Chat con la IA):** `http://localhost:3000`
    
    - _Uso:_ Regístrate con cualquier correo la primera vez. Te servirá para hablar directamente con tus modelos locales y hacerles preguntas sobre ciberseguridad o pedirles que analicen fragmentos de código de forma manual.
        
2. **Lemonade Server (Panel del Servidor de IA):** `http://localhost:13305`
    
    - _Uso:_ Endpoint de la API compatible con OpenAI. Aquí se gestionan los modelos cargados en la VRAM de tu tarjeta gráfica.
        

## 6. Comandos Útiles de Mantenimiento

- **Apagar el laboratorio por completo:** Si estás en un equipo con gráfica **AMD**:
    
    Bash
    
    ```
    docker compose -f docker-compose.yml -f docker-compose.amd.yml down
    ```
    
    Si estás en un equipo con gráfica **NVIDIA**:
    
    Bash
    
    ```
    docker compose -f docker-compose.yml -f docker-compose.nvidia.yml down
    ```
    
    _(Nota: Esto apaga los contenedores pero NO borra tus modelos descargados ni tus evidencias, ya que están protegidos en volúmenes persistentes)._
    
- **Entrar manualmente a la consola de Kali:** Si necesitas ejecutar herramientas de forma manual desde el espacio de Kali, usa:
    
    Bash
    
    ```
    docker exec -it kali_workspace /bin/bash
    ```