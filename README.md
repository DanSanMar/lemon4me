# 🤖 IA Pentest Lab: Sistema Autónomo de Auditoría con LLMs Locales

Este repositorio contiene un laboratorio automatizado de ciberseguridad e ingeniería inversa respaldado por Modelos de Lenguaje Locales (LLMs). La infraestructura está diseñada en contenedores desacoplados y cuenta con un **orquestador dinámico de hardware** capaz de exprimir al máximo la aceleración por GPU tanto en entornos **NVIDIA (CUDA)** como **AMD (ROCm/DirectX en WSL2)**, garantizando que el agente de IA mantenga su velocidad máxima sin modificar una sola línea de código.

---

## 🏗️ Arquitectura del Sistema

El laboratorio se divide en cuatro componentes críticos interconectados a través de una red aislada interna de Docker (`pentest_net`):

1. **Kali Workspace (`kali_workspace`):** El entorno de auditoría. Ejecuta las herramientas tradicionales de pentesting de forma automatizada y aloja al **Agente Autónomo de IA** (`agent_pentest.py`), el cual toma decisiones en tiempo real sobre qué vulnerabilidades explotar.
2. **Lemonade Server (`lemonade_server`):** El motor de inferencia local de IA. Sirve los modelos GGUF optimizados mediante el backend nativo de tu tarjeta gráfica (`cuda` o `rocm`).
3. **Dockerlabs Orquestador (`labs_dockerd`):** El entorno de despliegue de objetivos. Vigilando un directorio local, monta automáticamente las máquinas virtuales vulnerables (víctimas) dentro de la red del laboratorio.
4. **Open-WebUI (`open_webui`):** Panel visual que te permite chatear directamente con los modelos de IA residentes en tu VRAM para realizar consultas de código, scripts o análisis manuales.

---

## 🚀 Características Clave

* **🛸 Selector Automático de Hardware:** Mediante un script en Python (`init_platform.py`), el sistema detecta de forma fiable si el equipo host tiene drivers NVIDIA o AMD y levanta la capa de Docker Compose óptima.
* **🧠 Razonamiento Híbrido Local/Nube:** Configurable para operar al 100% en local con Lemonade Server, o en la nube mediante la API oficial de Hugging Face si necesitas delegar la carga de computación.
* **🎯 Watchdog de Objetivos Activos:** El agente autónomo detecta cuando ingresa una nueva máquina objetivo a la carpeta compartida, activa los escaneos de puertos e inicia la fase de explotación sin intervención humana.

---

## 📋 Requerimientos Previos

### Requisitos de Software comunes:
* **Docker Desktop** con motor basado en **WSL2** (activado en la configuración) o Linux Nativo.
* **Python 3.x** instalado en el sistema operativo Host (para ejecutar el script de inicialización).

### Según tu Tarjeta Gráfica (GPU):
* **NVIDIA:** Drivers oficiales actualizados y capacidad de ejecutar `nvidia-smi` desde la terminal del host. *(En Linux nativo requiere `nvidia-container-toolkit`)*.
* **AMD:** Drivers AMD Adrenalin actualizados. Compatibilidad con el puente de virtualización `/dev/dxg` a través de WSL2.

---

## 🛠️ Instalación y Configuración

1. **Estructura del Proyecto:** Asegúrate de clonar o colocar los archivos respetando la siguiente jerarquía:
   
   ├── docker-compose.yml          # Configuración base común
   ├── docker-compose.nvidia.yml   # Capa de aceleración NVIDIA CUDA
   ├── docker-compose.amd.yml      # Capa de aceleración AMD ROCm
   ├── init_platform.py            # Script selector e iniciador del entorno
   ├── agent_pentest.py            # Lógica del Agente de IA
   ├── init_dockerlabs.py          # Monitor de despliegue de máquinas víctima
   ├── entrypoint.sh               # Inicializador interno de Kali
   ├── .env                        # Archivo de variables de entorno privadas
   ├── dockerlabs/                 # 📁 Directorio para colocar máquinas (.tar / scripts)
   ├── kalievi/                    # 📁 Evidencias de auditoría generadas por la IA
   └── kalirep/                    # 📁 Reportes finales generados por la IA
   
   
   2. **Configuración del Entorno (`.env`):** Crea un archivo llamado `.env` en la raíz del proyecto:
    
    Fragmento de código
    
    ```
    WEBUI_SECRET_KEY=TuClaveSecretaParaLoginWebUI
    HF_API_KEY=tu_token_hugging_face_opcional
    ```
    
    _Nota: Si dejas `HF_API_KEY` vacío, el laboratorio forzará el uso de modelos locales a través de tu GPU de manera automática._
    

## 📖 Modo de Uso Diario

### 1. Iniciar el laboratorio

En lugar de usar comandos estándar de Docker, abre tu terminal en el Host y ejecuta el script automatizado:

Bash

```
python3 init_platform.py
```

El script compilará las imágenes necesarias, combinará los archivos YAML correctos de hardware y pondrá en marcha los contenedores.

### 2. Cargar una Máquina Víctima

Descarga cualquier máquina vulnerable de entornos de práctica (como DockerLabs) y arrastra su archivo `.tar` o script dentro de la carpeta local `./dockerlabs/`. El orquestador interno la detectará, la desplegará de forma aislada e informará al agente.

### 3. Monitorear al Agente Autónomo

El agente registrará todo su árbol de pensamientos, ejecuciones de comandos de Kali y escaneos de vulnerabilidades en tiempo real. Puedes seguirlo en vivo desde tu host con:

Bash

```
tail -f kalievi/agent_daemon.log
```

### 4. Consultar Reportes Finales

Una vez completada la auditoría, la IA redactará un informe técnico exhaustivo con los hallazgos y mitigaciones. Podrás encontrarlo directamente en la carpeta local `./kalirep/`.

## 🔗 Interfaces Web Disponibles

Una vez el entorno esté corriendo, podrás acceder desde el navegador del Host a:

- **Open-WebUI (Chat con la IA):** [http://localhost:3000](https://www.google.com/search?q=http://localhost:3000) _(Regístrate con cualquier credencial en el primer acceso)._
    
- **Lemonade Server API:** [http://localhost:13305](https://www.google.com/search?q=http://localhost:13305) _(Panel de control y endpoint compatible con OpenAI)._
    

## ⚙️ Comandos Útiles de Mantenimiento

- **Detener el Laboratorio de forma limpia:**
    
    - Si estás usando **AMD**:
        
        Bash
        
        ```
        docker compose -f docker-compose.yml -f docker-compose.amd.yml down
        ```
        
    - Si estás usando **NVIDIA**:
        
        Bash
        
        ```
        docker compose -f docker-compose.yml -f docker-compose.nvidia.yml down
        ```
        
- **Acceder a la consola manual de Kali:** Si deseas realizar pruebas de penetración tradicionales de manera interactiva dentro del espacio compartido, ejecuta:
    
    Bash
    
    ```
    docker exec -it kali_workspace /bin/bash
    ```
    

⚠️ **AVISO DE USO DE SEGURIDAD:** Este laboratorio está diseñado estrictamente para fines educativos, investigación académica y pruebas de penetración autorizadas. No promueve ni se responsabiliza del uso de estas herramientas autónomas en redes o sistemas de terceros sin el consentimiento explícito de sus propietarios.


