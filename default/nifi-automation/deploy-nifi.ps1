# NiFi Deployment Script for Windows
param(
    [string]$NifiApiUrl = "https://localhost:8443/nifi-api"
)

Write-Host "=== NiFi Auto-Deployment Script ===" -ForegroundColor Magenta
Write-Host "Started at: $(Get-Date)" -ForegroundColor Gray

# SSL bypass for development
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }

# Check NiFi availability
Write-Host "Checking NiFi status..." -ForegroundColor Yellow
try {
    $status = Invoke-WebRequest -Uri "$NifiApiUrl/flow/process-groups/root" -UseBasicParsing
    Write-Host "✅ NiFi is running" -ForegroundColor Green
} catch {
    Write-Host "❌ NiFi is not accessible at $NifiApiUrl" -ForegroundColor Red
    Write-Host "Please ensure NiFi is running on your local machine" -ForegroundColor Yellow
    exit 1
}

# Deploy template
if (Test-Path "template.xml") {
    Write-Host "Deploying template..." -ForegroundColor Cyan
    
    $form = @{
        template = Get-Item "template.xml"
    }
    
    try {
        $upload = Invoke-RestMethod -Uri "$NifiApiUrl/process-groups/root/templates/upload" -Method Post -Form $form
        $templateId = $upload.template.id
        Write-Host "✅ Template uploaded: $templateId" -ForegroundColor Green
        
        # Instantiate
        $body = @{
            templateId = $templateId
            originX = 100
            originY = 100
        } | ConvertTo-Json
        
        Invoke-RestMethod -Uri "$NifiApiUrl/process-groups/root/template-instance" -Method Post -Body $body -ContentType "application/json"
        Write-Host "✅ Template instantiated successfully!" -ForegroundColor Green
        
    } catch {
        Write-Host "❌ Deployment failed: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "❌ template.xml not found in current directory" -ForegroundColor Red
    exit 1
}

Write-Host "=== Deployment completed successfully! ===" -ForegroundColor Green
Write-Host "Finished at: $(Get-Date)" -ForegroundColor Gray
Write-Host "Open NiFi: https://localhost:8443/nifi" -ForegroundColor Blue
