<#
.SYNOPSIS
    Script permettant d'installer Chocolatey et une liste de packages.

.DESCRIPTION
    Ce script supprime l'installation existante de Chocolatey (si présente),
    installe Chocolatey via la commande spécifiée,
    puis procède à l'installation des packages définis.
    
.AUTHOR
    Tristan BRINGUIER

.DATE
    Février 2025

.VERSION
    1.0

.NOTES
    Ce script doit être exécuté avec des privilèges administratifs.
    Si ce n'est pas le cas, il se relancera automatiquement en tant qu'administrateur.

.EXAMPLE
    .\chocolateysofts.ps1

.PARAMETER None
    Ce script ne prend pas de paramètres en entrée.

.OUTPUTS
    Le script affiche l'état des installations et les résultats des commandes dans la console.

.INPUTS
    Le script est succeptible de demander à l'utilisateur des autorisations lors de l'installation des modules.
#>

# Définition de la liste des packages à installer via Chocolatey
$packages = @(
    "firefoxesr", # Firefox Extended Support Release
    "vlc",
    "7zip",
    "notepadplusplus",
    "googlechrome",
    "adobereader"
)

# Fonction pour vérifier si le script est exécuté avec des privilèges administratifs
function Test-Admin {
    # Récupère l'identité de l'utilisateur courant et vérifie son appartenance au groupe Administrateurs
    $currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Vérification des privilèges administratifs
if (-not (Test-Admin)) {
    Write-Host "Relancement du script avec des privilèges administratifs... (Veuillez accepter l'UAC)"
    # Relance le script en mode administrateur et quitte le processus actuel
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# Fonction pour installer Chocolatey
function Install-Chocolatey {
    Write-Output "Installation de Chocolatey..."
    try {
        # Modifie la politique d'exécution pour permettre l'exécution du script d'installation
        Set-ExecutionPolicy Bypass -Scope Process -Force
        # Active les protocoles TLS nécessaires pour la connexion sécurisée
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        # Télécharge et exécute le script d'installation de Chocolatey
        iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
        Write-Output "Chocolatey a été installé avec succès."
    } catch {
        Write-Error "Erreur lors de l'installation de Chocolatey : $_"
        exit 1
    }
}

# Fonction pour installer une liste de packages via Chocolatey
function Install-Packages {
    [CmdletBinding()]
    param(
        # Paramètre obligatoire qui contient la liste des packages à installer
        [Parameter(Mandatory = $true)]
        [string[]]$Packages
    )
    foreach ($package in $Packages) {
        Write-Output "Installation de $package..."
        try {
            # Installe le package avec Chocolatey en mode silencieux (-y pour approuver automatiquement)
            choco install $package -y
        } catch {
            Write-Error "Erreur lors de l'installation du package '$package' : $_"
        }
    }
}

# Suppression de l'installation existante de Chocolatey si le dossier existe
if (Test-Path "$env:ProgramData\chocolatey") {
    Write-Output "Ancienne installation de Chocolatey détectée. Suppression en cours..."
    # Supprime le dossier Chocolatey et tout son contenu de manière récursive et forcée
    Remove-Item "$env:ProgramData\chocolatey" -Recurse -Force
} else {
    Write-Output "Aucune installation existante de Chocolatey trouvée."
}


# Installation de Chocolatey
Install-Chocolatey

# Installation des packages via Chocolatey
Install-Packages -Packages $packages

# Message final indiquant la fin du processus d'installation
Read-Host "Installation de Chocolatey et des packages terminée."