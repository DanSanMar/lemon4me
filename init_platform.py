import os
import subprocess
import sys
import shutil

def check_nvidia():
    """Verifica si los drivers e infraestructura de NVIDIA están listos."""
    return shutil.which("nvidia-smi") is not None

def check_amd():
    """Verifica si existe hardware o herramientas de AMD (Compatible con Windows/WSL/Linux)."""
    if sys.platform == "win32":
        try:
            cmd = ["powershell", "-Command", "Get-CimInstance Win32_VideoController | Select-Object -ExpandProperty Name"]
            out = subprocess.check_output(cmd, text=True, stderr=subprocess.DEVNULL)
            return "AMD" in out or "Radeon" in out
        except:
            return os.path.exists(r"C:\Windows\System32\AMD\xrt-smi.exe")
    else:
        return os.path.exists("/dev/dxg") or os.path.exists("/dev/kfd")

def main():
    print("=" * 65)
    print("   SISTEMA DE AUDITORÍA IA - SELECTOR AUTOMÁTICO DE HARDWARE   ")
    print("=" * 65)
    
    hardware_file = None
    hw_type = ""

    print("[*] Escaneando capacidades de aceleración de hardware en el Host...")
    
    if check_nvidia():
        print("[✓] ¡GPU NVIDIA detectada de forma fiable (nvidia-smi disponible)!")
        hardware_file = "docker-compose.nvidia.yml"
        hw_type = "NVIDIA"
    elif check_amd():
        print("[✓] ¡Hardware AMD (GPU/NPU) detectado de forma fiable!")
        hardware_file = "docker-compose.amd.yml"
        hw_type = "AMD"
    else:
        print("[!] AVISO: No se detectó hardware dedicado de manera clara.")
        hardware_file = "docker-compose.nvidia.yml" 
        hw_type = "NVIDIA (Por Defecto)"
        
    print(f"[+] Capa de hardware seleccionada: [{hw_type}]")
    print("[-] Levantando contenedores combinando los archivos de configuración...")
    print("-" * 65)
    
    # Invocación limpia usando herencia y combinación de archivos YAML (-f)
    compose_cmd = ["docker", "compose", "-f", "docker-compose.yml", "-f", hardware_file, "up", "--build", "-d"]
    
    try:
        subprocess.run(compose_cmd, check=True)
        print("-" * 65)
        print(f"[✓] DESPLIEGUE COMPLETO EXITOSO [{hw_type}]")
        print("    - Kali Workspace, Dockerlabs y Open-WebUI compartiendo puente de IA.")
        print("=" * 65)
    except subprocess.CalledProcessError as e:
        print(f"\n[❌] Error crítico ejecutando Docker Compose: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()