# Script para generar carga de CPU y activar las alertas de Prometheus
Write-Host "Iniciando generación de carga de CPU..."
Write-Host "Presiona Ctrl+C para detener"

$jobs = @()

try {
    # Crear trabajos en segundo plano para generar carga
    for ($i = 1; $i -le [Environment]::ProcessorCount; $i++) {
        $job = Start-Job -ScriptBlock {
            $startTime = Get-Date
            while ((Get-Date) -lt $startTime.AddMinutes(10)) {
                # Operación intensiva de CPU
                for ($j = 0; $j -lt 100000; $j++) {
                    [Math]::Sqrt($j * $j)
                }
            }
        }
        $jobs += $job
        Write-Host "Iniciado job $i para generar carga de CPU"
    }

    Write-Host "Generando carga de CPU durante 10 minutos..."
    Write-Host "Monitorea las alertas en Prometheus: http://localhost:9090/alerts"
    Write-Host "Y en Alertmanager si está configurado"
    
    # Esperar a que terminen los jobs
    $jobs | Wait-Job | Out-Null
    
}
finally {
    # Limpiar jobs
    $jobs | Stop-Job -ErrorAction SilentlyContinue
    $jobs | Remove-Job -ErrorAction SilentlyContinue
    Write-Host "Carga de CPU finalizada"
}