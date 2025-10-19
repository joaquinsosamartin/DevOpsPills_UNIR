# ================================================================
# SCRIPT COMPLEMENTARIO - GESTION DE PORT-FORWARDS
# ================================================================

param(
    [ValidateSet("start", "stop", "status", "restart")]
    [string]$Action = "status"
)

$colors = @{
    Success = "Green" 
    Warning = "Yellow"
    Error   = "Red"
    Info    = "White"
    Title   = "Cyan"
}

function Write-ColorOutput {
    param([string]$Message, [string]$Color = "White")
    
    $colorValue = $colors[$Color]
    if (-not $colorValue) {
        $colorValue = "White"
    }
    Write-Host $Message -ForegroundColor $colorValue
}

function Test-ServiceStatus {
    param([string]$Url, [string]$Name)
    
    try {
        $response = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 3 -ErrorAction Stop
        Write-ColorOutput "OK $Name -> $Url" "Success"
        return $true
    }
    catch {
        Write-ColorOutput "ERROR $Name -> $Url (No disponible)" "Error"
        return $false
    }
}

function Start-AllPortForwards {
    Write-ColorOutput "Iniciando todos los port-forwards..." "Title"
    
    # Verificar que los servicios existen
    $services = @(
        @{Name = "monitoring-kube-prometheus-prometheus"; Namespace = "monitoring" },
        @{Name = "monitoring-grafana"; Namespace = "monitoring" },
        @{Name = "aspnetcore-metrics-service"; Namespace = "default" },
        @{Name = "monitoring-kube-prometheus-alertmanager"; Namespace = "monitoring" }
    )
    
    foreach ($svc in $services) {
        $check = kubectl get svc $svc.Name -n $svc.Namespace --ignore-not-found=true 2>$null
        if (-not $check) {
            Write-ColorOutput "ATENCION: Servicio $($svc.Name) no encontrado en namespace $($svc.Namespace)" "Warning"
        }
    }
    
    # Iniciar port-forwards
    $jobs = @()
    
    # Prometheus
    $prometheusJob = Start-Job -ScriptBlock {
        while ($true) {
            try { kubectl port-forward -n monitoring svc/monitoring-kube-prometheus-prometheus 9090:9090 2>$null }
            catch { Start-Sleep -Seconds 3 }
        }
    }
    $jobs += @{Name = "Prometheus"; Job = $prometheusJob; Url = "http://localhost:9090" }
    
    # Grafana
    $grafanaJob = Start-Job -ScriptBlock {
        while ($true) {
            try { kubectl port-forward -n monitoring svc/monitoring-grafana 3000:80 2>$null }
            catch { Start-Sleep -Seconds 3 }
        }
    }
    $jobs += @{Name = "Grafana"; Job = $grafanaJob; Url = "http://localhost:3000" }
    
    # ASP.NET Core
    $appJob = Start-Job -ScriptBlock {
        while ($true) {
            try { kubectl port-forward svc/aspnetcore-metrics-service 8080:8080 2>$null }
            catch { Start-Sleep -Seconds 3 }
        }
    }
    $jobs += @{Name = "ASP.NET Core"; Job = $appJob; Url = "http://localhost:8080" }
    
    # Alertmanager
    $alertJob = Start-Job -ScriptBlock {
        while ($true) {
            try { kubectl port-forward -n monitoring svc/monitoring-kube-prometheus-alertmanager 9093:9093 2>$null }
            catch { Start-Sleep -Seconds 3 }
        }
    }
    $jobs += @{Name = "Alertmanager"; Job = $alertJob; Url = "http://localhost:9093" }
    
    # Esperar y verificar
    Start-Sleep -Seconds 8
    
    Write-ColorOutput "" "Info"
    Write-ColorOutput "Estado de los servicios:" "Title"
    foreach ($job in $jobs) {
        Test-ServiceStatus -Url $job.Url -Name $job.Name
    }
    
    # Guardar informacion de jobs
    $jobInfo = @{}
    foreach ($job in $jobs) {
        $jobInfo[$job.Name] = $job.Job.Id
    }
    $jobInfo | ConvertTo-Json | Out-File "port-forward-jobs.json" -Encoding UTF8
    
    Write-ColorOutput "" "Info"
    Write-ColorOutput "Port-forwards iniciados en background" "Success"
    Write-ColorOutput "IDs de jobs guardados en: port-forward-jobs.json" "Info"
}

function Stop-AllPortForwards {
    Write-ColorOutput "Deteniendo todos los port-forwards..." "Warning"
    
    # Detener por nombre de proceso
    Get-Process | Where-Object { $_.ProcessName -eq "kubectl" -and $_.CommandLine -like "*port-forward*" } | Stop-Process -Force -ErrorAction SilentlyContinue
    
    # Detener jobs de PowerShell
    Get-Job | Where-Object { $_.State -eq "Running" } | Stop-Job
    Get-Job | Remove-Job -Force -ErrorAction SilentlyContinue
    
    # Limpiar archivo de jobs
    if (Test-Path "port-forward-jobs.json") {
        Remove-Item "port-forward-jobs.json" -Force
    }
    
    Write-ColorOutput "Todos los port-forwards han sido detenidos" "Success"
}

function Show-Status {
    Write-ColorOutput "Estado actual de los servicios:" "Title"
    Write-ColorOutput "======================================" "Title"
    
    $services = @(
        @{Name = "Prometheus"; Url = "http://localhost:9090" },
        @{Name = "Grafana"; Url = "http://localhost:3000" },
        @{Name = "ASP.NET Core"; Url = "http://localhost:8080/health" },
        @{Name = "Alertmanager"; Url = "http://localhost:9093" }
    )
    
    $activeCount = 0
    foreach ($service in $services) {
        if (Test-ServiceStatus -Url $service.Url -Name $service.Name) {
            $activeCount++
        }
    }
    
    Write-ColorOutput "" "Info"
    Write-ColorOutput "Resumen: $activeCount/4 servicios activos" "Info"
    
    # Mostrar jobs activos
    $jobs = Get-Job | Where-Object { $_.State -eq "Running" }
    if ($jobs) {
        Write-ColorOutput "" "Info"
        Write-ColorOutput "Jobs de PowerShell activos:" "Info"
        $jobs | Format-Table Id, Name, State -AutoSize
    }
    else {
        Write-ColorOutput "" "Info"
        Write-ColorOutput "No hay jobs de PowerShell activos" "Warning"
    }
    
    # Mostrar procesos kubectl
    $kubectlProcesses = Get-Process | Where-Object { $_.ProcessName -eq "kubectl" } | Measure-Object
    Write-ColorOutput "Procesos kubectl activos: $($kubectlProcesses.Count)" "Info"
}

function Restart-AllPortForwards {
    Write-ColorOutput "Reiniciando todos los port-forwards..." "Warning"
    Stop-AllPortForwards
    Start-Sleep -Seconds 3
    Start-AllPortForwards
}

# ================================================================
# EJECUCION PRINCIPAL
# ================================================================

Clear-Host
Write-ColorOutput "================================================================" "Title"
Write-ColorOutput "     GESTION DE PORT-FORWARDS - DEMO MONITORIZACION" "Title"
Write-ColorOutput "================================================================" "Title"

switch ($Action) {
    "start" {
        Start-AllPortForwards
    }
    "stop" {
        Stop-AllPortForwards
    }
    "status" {
        Show-Status
    }
    "restart" {
        Restart-AllPortForwards
    }
    default {
        Write-ColorOutput "ERROR: Accion no valida: $Action" "Error"
        Write-ColorOutput "Uso: .\gestionar-portforwards.ps1 -Action [start|stop|status|restart]" "Info"
        exit 1
    }
}

Write-ColorOutput "" "Info"
Write-ColorOutput "================================================================" "Title"