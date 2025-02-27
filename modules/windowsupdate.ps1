<#
.SYNOPSIS
    Script permettant de mettre à jour Windows et les pilotes automatiquement.

.DESCRIPTION
    Ce script automatise le processus de mise à jour de Windows et des pilotes.

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
    .\WindowsUpdate.ps1

.PARAMETER None
    Ce script ne prend pas de paramètres en entrée.

.OUTPUTS
    Le script affiche les résultats des mises à jour dans la console.

.INPUTS
    Le script est succeptible de demander à l'utilisateur des autorisations lors de l'installation des modules.
#>

# Fonction pour vérifier si le script est exécuté en tant qu'administrateur
function Test-Admin {
    $currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Si le script n'est pas exécuté en tant qu'administrateur, le relancer avec des privilèges élevés
if (-not (Test-Admin)) {
    Write-Host "Relancement du script avec des privilèges administratifs... (Veuillez accepter l'UAC)"
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# Vérifier si le Package Provider NuGet est installé, sinon l'installer pour installer par la suite le module PSWindowsUpdate.
if (-not (Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue)) {
    Write-Host "Installation du Package Provider NuGet..."
    Install-PackageProvider -Name NuGet -Force
}

# Installer le module PSWindowsUpdate s'il n'est pas déjà présent.
if (-not (Get-Module -ListAvailable -Name PSWindowsUpdate)) {
    Write-Host "Installation du module PSWindowsUpdate..."
    Install-Module -Name PSWindowsUpdate -Force
}

# Importer le module PSWindowsUpdate.
Import-Module PSWindowsUpdate

# Lancer la commande pour rechercher, télécharger depuis les serveurs de Windows Update, installer les mises à jour et redémarrer automatiquement si nécessaire.
Write-Host "Recherche et installation des mises à jour Windows ainsi que des pilotes de l'ordinateur via les serveurs de Windows Update..."
Get-WindowsUpdate
Install-WindowsUpdate -MicrosoftUpdate -AcceptAll -AutoReboot -Verbose
Read-Host "Installation des mises à jour terminée."
