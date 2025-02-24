# Paramétrage de la gestion d'erreur
$ErrorActionPreference = 'Stop'

#-------------------------------
# Préparation du dossier d'automatisation
#-------------------------------
$automationFolder = "C:\Automatisations"
if (-Not (Test-Path $automationFolder)) {
    New-Item -ItemType Directory -Path $automationFolder -Force | Out-Null
    Write-Output "Création du dossier $automationFolder."
}
else {
    Write-Output "Le dossier $automationFolder existe déjà."
}

# Définir le fichier de log
$logFile = Join-Path $automationFolder "deploy.logs"

# Démarrer la transcription pour dupliquer la sortie console dans deploy.logs
Start-Transcript -Path $logFile
# Indicateur de transcription démarrée
$script:TranscriptStarted = $true

# Enregistrer un événement qui appellera Stop-Transcript à la sortie du moteur PowerShell
Register-EngineEvent -SourceIdentifier PowerShell.Exiting -Action {
    if ($script:TranscriptStarted) {
        Stop-Transcript | Out-Null
        $script:TranscriptStarted = $false
    }
} | Out-Null

# Écrire le début d'exécution avec date et heure
$executionStart = "Début d'exécution : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Output $executionStart

# Encapsuler l'exécution principale dans un bloc try/finally pour garantir l'arrêt de la transcription
try {

    #-------------------------------
    # Fonction : Invoke-WithRetry
    #-------------------------------
    function Invoke-WithRetry {
        param(
            [ScriptBlock]$ScriptBlock,
            [int]$MaxAttempts = 3,
            [int]$DelaySeconds = 5
        )

        $attempt = 0
        while ($attempt -lt $MaxAttempts) {
            try {
                $attempt++
                Write-Output "Tentative $attempt..."
                & $ScriptBlock
                return $true
            }
            catch {
                Write-Output "Erreur lors de l'exécution de la commande. Tentative $attempt échouée. Nouvelle tentative dans $DelaySeconds secondes..."
                Start-Sleep -Seconds $DelaySeconds
            }
        }
        return $false
    }

    #-------------------------------
    # Fonction : Install-Chocolatey
    #-------------------------------
    function Install-Chocolatey {
        param(
            [string]$automationFolder
        )

        $chocoTrackingFile = Join-Path $automationFolder "ChocolateyOK.txt"
        $shouldUninstallChocolatey = $true

        if (Test-Path $chocoTrackingFile) {
            $content = Get-Content $chocoTrackingFile -ErrorAction SilentlyContinue
            if ($content.Trim() -eq "OK") {
                Write-Output "Chocolatey est déjà installé (fichier de suivi trouvé : $chocoTrackingFile)."
                $shouldUninstallChocolatey = $false
            }
            else {
                Write-Output "Le fichier $chocoTrackingFile existe mais ne contient pas OK. On procède à la désinstallation de Chocolatey."
            }
        }
        else {
            Write-Output "Le fichier $chocoTrackingFile n'existe pas. On procède à l'installation de Chocolatey si nécessaire."
        }

        if ($shouldUninstallChocolatey) {
            # Désinstallation de l'installation existante de Chocolatey si présente
            if (Test-Path "$env:ProgramData\chocolatey") {
                Write-Output "Ancienne installation de Chocolatey détectée. Suppression en cours..."
                Remove-Item "$env:ProgramData\chocolatey" -Recurse -Force
            }
            else {
                Write-Output "Aucune installation existante de Chocolatey trouvée."
            }

            # Installation de Chocolatey avec retry
            $chocoInstallCommand = {
                Set-ExecutionPolicy Bypass -Scope Process -Force
                [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
                iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
            }

            if (Invoke-WithRetry -ScriptBlock $chocoInstallCommand -MaxAttempts 3 -DelaySeconds 10) {
                Write-Output "Installation de Chocolatey réussie."
            }
            else {
                throw "L'installation de Chocolatey a échoué après plusieurs tentatives."
            }
        }

        # Création ou mise à jour du fichier de suivi pour Chocolatey
        "OK" | Out-File -FilePath $chocoTrackingFile -Encoding ASCII
        Write-Output "Mise à jour du fichier de suivi $chocoTrackingFile avec la mention OK."
    }

    #-------------------------------
    # Fonction : Install-Packages
    #-------------------------------
    function Install-Packages {
        param(
            [string]$automationFolder
        )

        $packages = @(
            "googlechrome",
            "adobereader",
            "firefoxesr",
            "7zip",
            "notepadplusplus",
            "libreoffice-fresh",
            "vlc",
            #"dellcommandupdate",
            #"hpsupportassistant",
            "whocrashed",
            "thunderbird",
            "everything"
        )

        foreach ($pkg in $packages) {
            Write-Output "Traitement du package: $pkg"
            $pkgInstalled = choco list --local-only $pkg | Select-String -Pattern "^$pkg " -SimpleMatch
            if ($pkgInstalled) {
                Write-Output "$pkg est déjà installé. Mise à jour en cours..."
                $upgradeCommand = { choco upgrade $pkg -y }
                if (Invoke-WithRetry -ScriptBlock $upgradeCommand -MaxAttempts 3 -DelaySeconds 10) {
                    Write-Output "Mise à jour de $pkg réussie."
                }
                else {
                    Write-Output "La mise à jour de $pkg a échoué après plusieurs tentatives."
                }
            }
            else {
                Write-Output "$pkg n'est pas installé. Installation en cours..."
                $installCommand = { choco install $pkg -y }
                if (Invoke-WithRetry -ScriptBlock $installCommand -MaxAttempts 3 -DelaySeconds 10) {
                    Write-Output "Installation de $pkg réussie."
                }
                else {
                    Write-Output "L'installation de $pkg a échoué après plusieurs tentatives."
                }
            }
        }

        $packagesTrackingFile = Join-Path $automationFolder "PackagesOK.txt"
        "OK" | Out-File -FilePath $packagesTrackingFile -Encoding ASCII
        Write-Output "Mise à jour du fichier de suivi $packagesTrackingFile avec la mention OK."
    }
    #-------------------------------
    # Fonction : Join-Domain
    #-------------------------------
    function Join-Domain {
        param(
            [string]$automationFolder
        )

        # Rejoindre le domaine mondomaine.local (à implémenter ultérieurement)
        # $domain   = "mondomaine.local"
        # $username = "uncompteutilisateur"
        # $password = "unmotdepasse"
        # Add-Computer -DomainName $domain -Credential (New-Object System.Management.Automation.PSCredential($username, (ConvertTo-SecureString $password -AsPlainText -Force))) -Restart
        # "OK" | Out-File -FilePath (Join-Path $automationFolder "DomainOK.txt") -Encoding ASCII

        Write-Output "La fonction Join-Domain est actuellement en attente d'implémentation."
    }

    #-------------------------------
    # Exécution séquentielle des fonctions
    #-------------------------------
    Install-Chocolatey -automationFolder $automationFolder
    Install-Packages -automationFolder $automationFolder
    Join-Domain -automationFolder $automationFolder

}
finally {
    # Arrêter la transcription si elle est encore active
    if ($script:TranscriptStarted) {
        Stop-Transcript | Out-Null
        $script:TranscriptStarted = $false
    }
}
