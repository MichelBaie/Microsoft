# Vérifier si le script est exécuté avec des privilèges d'administrateur
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Error "Ce script doit être exécuté en tant qu'administrateur. Arrêt du script."
    exit
}

# Vérifier si le Package Provider NuGet est installé, sinon l'installer
if (-not (Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue)) {
    Write-Host "Installation du Package Provider NuGet..."
    Install-PackageProvider -Name NuGet -Force
} else {
    Write-Host "Le Package Provider NuGet est déjà installé."
}

# Installer le module PSWindowsUpdate s'il n'est pas déjà présent
if (-not (Get-Module -ListAvailable -Name PSWindowsUpdate)) {
    Write-Host "Installation du module PSWindowsUpdate..."
    Install-Module -Name PSWindowsUpdate -Force -Scope AllUsers
}

# Importer le module PSWindowsUpdate
Import-Module PSWindowsUpdate

# Lancer la commande pour rechercher, télécharger depuis les serveurs de Windows Update, installer les mises à jour et redémarrer automatiquement si nécessaire
Write-Host "Lancement de la mise à jour de Windows..."
Install-WindowsUpdate -MicrosoftUpdate -AcceptAll -AutoReboot | Out-File "C:\Automatisations\WindowsUpdate.log" -force
