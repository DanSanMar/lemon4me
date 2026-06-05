import os
import time
import signal
import sys
import docker
import subprocess

# Configuración de rutas internas
WATCH_DIR = "/opt/dockerlabs"
DEPLOY_DIR = "/opt/autodeploy"
NET_NAME = "pentest_net"

# Conexión al motor de Docker
client = docker.from_env()

# Variable global para controlar el apagado limpio
running = True

def cleanup_child_containers():
    """Busca y destruye todos los contenedores de laboratorios activos antes de salir."""
    print("\n[!] 🧹 Iniciando limpieza de laboratorios residuales...", flush=True)
    try:
        # Listamos todos los contenedores (activos o no)
        all_containers = client.containers.list(all=True)
        for container in all_containers:
            # Filtramos por el prefijo que tú mismo definiste en 'deploy_lab'
            if container.name.startswith("lab_"):
                print(f"[->] Deteniendo y eliminando: {container.name}...", flush=True)
                try:
                    container.stop(timeout=5)  # Tiempo de cortesía para apagarse
                    container.remove(force=True)
                    print(f"[✓] {container.name} eliminado.", flush=True)
                except Exception as ce:
                    print(f"[❌] No se pudo eliminar {container.name}: {ce}", flush=True)
    except Exception as e:
        print(f"[❌] Error durante el proceso de limpieza general: {e}", flush=True)

def handle_shutdown(signum, frame):
    global running
    print("\n[!] 🛑 Señal de apagado recibida desde Docker. Saliendo limpiamente...", flush=True)
    running = False
    # Ejecutamos la limpieza inmediatamente al recibir la señal
    cleanup_child_containers()

# Registrar las señales de parada de Docker (SIGTERM y SIGINT)
signal.signal(signal.SIGTERM, handle_shutdown)
signal.signal(signal.SIGINT, handle_shutdown)

# Conjunto en memoria para evitar reprocesar archivos si el borrado tarda
processed_files = set()

def deploy_lab(tar_path, file_name):
    try:
        lab_name = os.path.splitext(file_name)[0].lower().replace("_", "")
        container_name = f"lab_{lab_name}_{int(time.time())}"
        
        print(f"\n[+] 📦 Nuevo laboratorio detectado: {file_name}", flush=True)
        print(f"[->] Cargando imagen en Docker desde el .tar...", flush=True)
        
        with open(tar_path, 'rb') as f:
            client.images.load(f)
        
        image_tag = f"{lab_name}:latest"
        print(f"[->] Imagen [{image_tag}] lista. Desplegando contenedor...", flush=True)
        
        init_cmd = (
            "/bin/bash -c "
            "'service apache2 start 2>/dev/null || true; "
            "service nginx start 2>/dev/null || true; "
            "service mariadb start 2>/dev/null || true; "
            "service mysql start 2>/dev/null || true; "
            "while true; do sleep 60; done'"
        )

        container = client.containers.run(
            image=image_tag,
            name=container_name,
            command=init_cmd,
            detach=True,
            network=NET_NAME,
            restart_policy={"Name": "unless-stopped"}
        )
        
        container.reload()
        ip_addr = container.attrs['NetworkSettings']['Networks'][NET_NAME]['IPAddress']
        
        print(f"🚀 [¡LISTO!] Máquina objetivo operativa.")
        print(f"   📌 Nombre: {container_name}")
        print(f"   🌐 IP en Red Pentest: {ip_addr}")
        
      # Cambiamos el lanzamiento del script por la escritura del estado inicial
        print(f"[->] Notificando a Kali para iniciar autoscan4me.sh para {ip_addr}...", flush=True)
        
        active_lab_file = os.path.join(DEPLOY_DIR, "active_lab.txt")
        try:
            with open(active_lab_file, "w", encoding="utf-8") as f:
                f.write(f"TARGET_IP={ip_addr}\n")
                f.write("SCAN_READY=START_SCAN\n")
            print(f"[✓] Estado START_SCAN enviado a Kali para la IP {ip_addr}.", flush=True)
        except Exception as file_err:
            print(f"[❌] Error al escribir en active_lab.txt: {file_err}", flush=True)

    except Exception as e:
        print(f"[❌] Error crítico en el auto-despliegue de {file_name}: {e}", flush=True)
        
    finally:
        print(f"[->] Solicitando eliminación del archivo original: {file_name}", flush=True)
        # Lo añadimos al set interno para que NUNCA vuelva a intentar procesarlo en este ciclo
        processed_files.add(file_name)
        try:
            # Forzamos una micro-pausa para asegurar que el sistema de archivos liberó el .tar
            time.sleep(0.5)
            os.remove(tar_path)
            print(f"[✓] Archivo {file_name} eliminado físicamente.", flush=True)
        except Exception as e:
            print(f"[-] Nota: No se pudo borrar el archivo en disco ({e}), pero queda marcado como procesado.", flush=True)

print("[Orquestador] 🚀 Monitor de laboratorios DockerLabs activado...", flush=True)
print(f"[*] Vigilando la carpeta interna: {WATCH_DIR}", flush=True)

# Bucle controlado por la señal de apagado
while running:
    try:
        files = os.listdir(WATCH_DIR)
    except Exception as e:
        if running: # Solo alertar si no estamos en proceso de apagado
            print(f"[-] Error al leer el directorio {WATCH_DIR}: {e}", flush=True)
        time.sleep(2)
        continue

    for file in files:
        if file.endswith(".tar") and file not in processed_files:
            full_path = os.path.join(WATCH_DIR, file)
            
            # --- BUCLE DE ESPERA INTELIGENTE BLINDADO ---
            print(f"[*] Detectado {file}, verificando si terminó de copiarse...", flush=True)
            archivo_valido = True
            while True:
                try:
                    tamanio_inicial = os.path.getsize(full_path)
                    time.sleep(2) # Espera corta de 2 segundos para comprobar estabilidad
                    tamanio_final = os.path.getsize(full_path)
                    
                    if tamanio_inicial == tamanio_final:
                        # El tamaño no ha variado en 2 segundos: la copia ha terminado
                        break
                    else:
                        print(f"[->] El archivo {file} sigue creciendo... Esperando a que termine.", flush=True)
                except FileNotFoundError:
                    # Si el archivo desapareció misteriosamente durante la copia
                    print(f"[❌] El archivo {file} ya no está disponible en el directorio.", flush=True)
                    archivo_valido = False
                    break
                except Exception as e:
                    print(f"[-] Esperando liberación de descriptores para {file}: {e}", flush=True)
                    time.sleep(2)
            
            # Si el archivo dio error crítico o desapareció, saltamos al siguiente
            if not archivo_valido:
                continue

            # Una vez que el tamaño es estable, lanzamos el despliegue de forma segura
            deploy_lab(full_path, file)
            
    # Hacemos sleeps cortos en un rango para que responda rápido a la señal de apagado
    for _ in range(3):
        if not running:
            break
        time.sleep(1)


print("[Orquestador] 👋 Guardando estado y finalizando de manera ordenada.", flush=True)
sys.exit(0)