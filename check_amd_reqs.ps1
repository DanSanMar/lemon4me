<#
.SYNOPSIS
    Validador de Requisitos AMD para Lemonade + Kali Project.
#>

$reportPath = "info_check.txt"
$report = @()

function Log-Info {
    param([string]$msg)
    Write-Host "[-] $msg" -ForegroundColor Cyan
    $script:report += "[-] $msg"
}

Clear-Host
Log-Info "INICIANDO COMPROBACIÓN DE HARDWARE AMD - $(Get-Date)"
Log-Info "----------------------------------------------------"

# 1. Comprobar Procesador (Ryzen AI Check)
$cpu = Get-CimInstance Win32_Processor
Log-Info "CPU: $($cpu.Name)"
if ($cpu.Name -match "Ryzen [79]") {
    Log-Info "RESULTADO: Compatible con Ryzen AI (NPU probable)."
}

# 2. Comprobar Drivers de GPU AMD
$gpu = Get-CimInstance Win32_VideoController | Where-Object { $_.Name -match "AMD" }
if ($gpu) {
    Log-Info "GPU Detectada: $($gpu.Name)"
    Log-Info "Versión del Driver: $($gpu.DriverVersion)"
} else {
    Log-Info "CRÍTICO: No se detectó GPU AMD compatible."
}

# 3. Verificar xrt-smi (NPU Management)
$xrtPath = "C:\Windows\System32\AMD\xrt-smi.exe"
if (Test-Path $xrtPath) {
    Log-Info "NPU Tool: xrt-smi detectado en la ruta estándar."
    $npuStatus = & $xrtPath examine | Out-String
    if ($npuStatus -match "Status: Online") {
        Log-Info "NPU Status: Operativa."
    }
} else {
    Log-Info "AVISO: xrt-smi no encontrado. La aceleración NPU podría fallar."
}

# 4. Verificar Docker Desktop y WSL2
$dockerCheck = docker version --format '{{.Server.Os}}' 2>$null
if ($dockerCheck -eq "linux") {
    Log-Info "Docker: OK (WSL2 Backend detectado)."
} else {
    Log-Info "ERROR: Docker no está corriendo o no usa WSL2."
}

# 5. Resumen de Variables para .env
Log-Info "----------------------------------------------------"
Log-Info "SUGERENCIA PARA .env:"
if ($gpu.Name -match "780M|740M|Radeon 7") {
    Log-Info "HSA_OVERRIDE_GFX_VERSION=11.0.1"
} else {
    Log-Info "HSA_OVERRIDE_GFX_VERSION=11.0.0"
}

$report | Out-File -FilePath $reportPath -Encoding utf8
Write-Host "`n[!] Reporte guardado en $reportPath" -ForegroundColor Green