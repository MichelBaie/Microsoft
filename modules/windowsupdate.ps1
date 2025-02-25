# Fonction pour vérifier si le script est exécuté en tant qu'administrateur
function Test-Admin {
    $currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Si le script n'est pas exécuté en tant qu'administrateur, le relancer avec des privilèges élevés
if (-not (Test-Admin)) {
    Write-Host "Relancement du script avec des privilèges administratifs..."
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# Vérifier si le Package Provider NuGet est installé, sinon l'installer pour installer par la suite PSWindowsUpdate.
if (-not (Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue)) {
    Write-Host "Installation du Package Provider NuGet..."
    Install-PackageProvider -Name NuGet -Force
} else {
    Write-Host "Le Package Provider NuGet est déjà installé."
}

# Installer le module PSWindowsUpdate s'il n'est pas déjà présent.
if (-not (Get-Module -ListAvailable -Name PSWindowsUpdate)) {
    Write-Host "Installation du module PSWindowsUpdate..."
    Install-Module -Name PSWindowsUpdate -Force
}

# Importer le module PSWindowsUpdate.
Import-Module PSWindowsUpdate

# Lancer la commande pour rechercher, télécharger depuis les serveurs de Windows Update, installer les mises à jour et redémarrer automatiquement si nécessaire.
Write-Host "Lancement de la mise à jour de Windows..."
Install-WindowsUpdate -MicrosoftUpdate -AcceptAll -AutoReboot
