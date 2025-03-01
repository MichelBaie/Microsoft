# Liste des packages à installer via Chocolatey
$packages = @(
    "googlechrome",
    "sumatrapdf.install",
    "firefoxesr",
    "7zip",
    "notepadplusplus",
    "vlc",
    "dellcommandupdate",
    "hpsupportassistant",
    "everything",
    "libreoffice-fresh"
)

<#
.SYNOPSIS
Installe Chocolatey et suppression des installations existantes
#>
function Install-Chocolatey {
    Write-Host "Début de l'installation de Chocolatey."
    
    # Bloc d'installation avec réessai automatique
    Invoke-WithRetry -ScriptBlock {
        # Nettoyage des installations précédentes
        if (Test-Path "$env:ProgramData\chocolatey") {
            Remove-Item "$env:ProgramData\chocolatey" -Recurse -Force
            Write-Host "Ancienne installation de Chocolatey supprimée."
        }

        # Configuration de l'environnement pour l'installation
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        
        # Téléchargement et exécution du script d'installation
        iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    }
    
    Write-Host "Installation de Chocolatey terminée."
}

<#
.SYNOPSIS
Installe la liste des packages définie dans $packages
#>
function Install-Packages {
    Write-Host "Début de l'installation des packages."
    
    # Installation de chaque package avec 3 tentatives
    foreach ($pkg in $packages) {
        $maxRetries = 3    # Nombre maximum de tentatives
        $attempt = 0       # Compteur de tentatives
        $success = $false  # État de réussite

        # Boucle de réessai
        while ($attempt -lt $maxRetries -and -not $success) {
            Write-Host "Tentative d'installation de $pkg (essai $($attempt + 1) sur $maxRetries)..."
            
            # Commande d'installation Chocolatey
            choco install $pkg -y --ignore-checksums
            
            # Vérification du résultat
            if ($LASTEXITCODE -eq 0) {
                Write-Host "$pkg installé avec succès."
                $success = $true
            } else {
                Write-Host "L'installation de $pkg a échoué (code $LASTEXITCODE)." "ERROR"
                $attempt++
                
                # Pause avant réessai si ce n'était pas la dernière tentative
                if ($attempt -lt $maxRetries) {
                    Write-Host "Nouvelle tentative dans 5 secondes..."
                    Start-Sleep -Seconds 5
                }
            }
        }

        # Gestion des échecs définitifs
        if (-not $success) {
            Write-Host "L'installation de $pkg a échoué après $maxRetries tentatives. Passage au package suivant." "ERROR"
        }
    }
    
    Write-Host "Installation des packages terminée."
}
