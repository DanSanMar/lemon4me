# 🛡️ Guía Maestra: Ecosistema de Auditoría IA (AMD Ryzen AI + Kali)

Esta documentación unifica la configuración para el despliegue de **Lemonade Server** optimizado para hardware AMD (RDNA3 + NPU) integrado con un entorno de pentesting en **Kali Linux**.

## 1. Preparación del Host (Windows 11 + WSL2)

Antes de levantar los contenedores, el host debe estar configurado para permitir el "passthrough" de hardware.

- **Drivers:** Instalar _AMD Software: Adrenalin Edition_ (v32.0.31007.5012 o superior).
    
- **Configuración WSL (`%USERPROFILE%\.wslconfig`):**
    
    Ini, TOML
    
    ```
    [wsl2]
    nestedVirtualization=true
    ```
    
- **Modo Turbo NPU (Recomendado):** Ejecutar en PowerShell como Administrador para maximizar el rendimiento de la IA:
    
    PowerShell
    
    ```
    cd C:\Windows\System32\AMD
    .\xrt-smi.exe configure --pmode turbo
    ```
    

---

## 2. Arquitectura de Contenedores (Docker Compose)

El sistema se divide en tres servicios clave sobre la red `pentest_net`:

### A. Lemonade Server (Cerebro)

Es el motor de inferencia que gestiona la carga entre la NPU y la GPU.

- **Imagen:** `ghcr.io/lemonade-sdk/lemonade-server:latest`
    
- **Puente de Hardware:** Utiliza `/dev/dxg` para acceder a la GPU/NPU en WSL2.
    
- **Variables Críticas:**
    
    - `HSA_OVERRIDE_GFX_VERSION=11.0.0` (Forzado para compatibilidad RDNA3/Radeon 860M/780M).
        
    - `LD_LIBRARY_PATH=/usr/lib/wsl/lib` (Vincula las librerías gráficas del host).
        
    - `LEMONADE_LLAMACPP_BACKEND=rocm` (Activa la aceleración por hardware).
        

### B. Kali Workspace (Brazo Ejecutor)

Contenedor basado en `kali-rolling` con herramientas de auditoría.

- **Integración:** Incluye `lemonade-clip` y servidores MCP para que la IA ejecute comandos.
    
- **Herramientas instaladas:** `nmap`, `metasploit-framework`, `nuclei`, `seclists`, y entornos Node/Python.
    

### C. Open WebUI (Interfaz)

- **Acceso:** `http://localhost:3000`
    
- **Conexión:** Configurado para apuntar a `http://lemonade:13305/api/v1`.
    

---

## 3. Configuración del Entorno y Automatización

Para que todo funcione sin intervención manual, se han aplicado los siguientes ajustes en los archivos de construcción:

### Dockerfile (Personalización de Kali)

1. **Usuario:** Se crea el usuario `kali` con permisos sudo sin contraseña.
    
2. **Librerías:** Se instalan dependencias para MCP (`@modelcontextprotocol/server-filesystem`).
    
3. **Binarios:** Se descarga y renombra el binario de Lemonade a `lemonade-clip` para evitar conflictos de nombres y permitir interacción desde la terminal de Kali.
    

### Entrypoint.sh (Script de Inicio)

El script de entrada gestiona la salud del sistema:

- **Espera Activa:** No inicia el entorno Kali hasta que la API de Lemonade responde en el puerto `13305`.
    
- **Alias de IA:** Crea el alias `ia4me` en `.bashrc` para interactuar con la API directamente:
    
    `alias ia4me='curl -s http://lemonade:13305/api/v1'`
    
- **Directorios:** Automatiza la creación de carpetas de `/home/kali/scripts` y `/reports`.
    

---

## 4. Flujo de Trabajo Operativo

Una vez que el sistema está arriba (`docker-compose up -d`):

1. **Carga de Modelo:** Lemonade descarga automáticamente el modelo solicitado. Se recomiendan modelos **Hybrid/FLM** (como `Qwen3-0.6B-GGUF` o `Gemma 3 4B`) para aprovechar la NPU.
    
2. **Interacción:**
    
    - Tú pides una tarea en **Open WebUI**.
        
    - **Lemonade** procesa la petición usando la NPU (bajo consumo) o GPU (alto rendimiento).
        
    - La IA utiliza el protocolo **MCP** para ejecutar herramientas dentro del contenedor **Kali**.
        
3. **Verificación de Hardware:**
    
    Dentro de Kali, puedes verificar si la GPU está siendo reconocida revisando los logs de Lemonade o usando el alias:
    
    `ia4me/models | jq`
    

---

## 5. Resumen de Conectividad

| **Servicio**            | **URL Local**                  | **Puerto Interno** |
| ----------------------- | ------------------------------ | ------------------ |
| **Interfaz de Usuario** | `http://localhost:3000`        | 8080               |
| **API Lemonade**        | `http://localhost:13305`       | 13305              |
| **Modelos (Interno)**   | `http://lemonade:13305/api/v1` | -                  |