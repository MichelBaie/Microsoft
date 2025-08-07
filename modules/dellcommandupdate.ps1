# =================================================================================
# Script pour installer et mettre à jour les pilotes avec Dell Command Update (DCU)
#
# Logique :
# 1. Vérifie si l'ordinateur est de marque Dell.
# 2. Si oui, vérifie si DCU est installé.
# 3. Si DCU n'est pas installé, il l'installe via winget.
# 4. Exécute la mise à jour silencieuse des pilotes et du firmware.
# =================================================================================

# --- Configuration ---
# Chemin vers l'exécutable de la ligne de commande de Dell Command Update
$dcuCliPath = "C:\Program Files\Dell\CommandUpdate\dcu-cli.exe"
# Identifiant Winget pour Dell Command Update (Version Universelle Windows)
$wingetPackageId = "Dell.CommandUpdate.Universal"


# --- Fonction pour lancer les mises à jour DCU ---
function Start-DellUpdate {
    param(
        [string]$Path
    )
    
    Write-Host "Lancement de Dell Command Update pour la recherche et l'installation des mises à jour..."
    Write-Host "Commande: $Path /applyUpdates -silent -reboot=disable"

    $arguments = "/applyUpdates -silent -reboot=disable"

    try {
        Start-Process -FilePath $Path -ArgumentList $arguments -Wait -NoNewWindow
        
        Write-Host "La commande de mise à jour de Dell Command Update s'est terminée avec le code de sortie : $LASTEXITCODE"
    }
    catch {
        Write-Error "Une erreur critique s'est produite lors de la tentative de lancement de Dell Command Update CLI."
        Write-Error $_.Exception.Message
    }
}


# --- Script Principal ---

# 1. Vérification du fabricant de l'ordinateur
Write-Host "Vérification du fabricant de l'ordinateur..."
# Utilise Get-CimInstance, la méthode moderne pour interroger WMI
$manufacturer = (Get-CimInstance -ClassName Win32_ComputerSystem).Manufacturer

# La comparaison -like "*Dell*" est plus robuste car elle peut correspondre à "Dell Inc.", "Dell", etc.
if ($manufacturer -like "*Dell*") {
    Write-Host "Fabricant détecté : $manufacturer. Le script va continuer sur cet ordinateur Dell."

    # 2. Vérifier si Dell Command Update est déjà installé
    if (Test-Path $dcuCliPath) {
        Write-Host "Dell Command Update est déjà installé."
        # Lancer directement la mise à jour
        Start-DellUpdate -Path $dcuCliPath
    }
    else {
        Write-Host "Dell Command Update n'est pas trouvé. Tentative d'installation via winget..."

        try {
            # 3. Commande pour installer DCU via winget, en acceptant les termes pour l'automatisation
            $wingetArgs = "install -e --id $wingetPackageId --silent --accept-package-agreements --accept-source-agreements"
            Write-Host "Exécution de winget avec les arguments: $wingetArgs"
            Start-Process winget -ArgumentList $wingetArgs -Wait -NoNewWindow
            
            # Vérifier à nouveau si l'installation a réussi
            if (Test-Path $dcuCliPath) {
                Write-Host "Installation de Dell Command Update via winget réussie."
                # 4. Lancer la mise à jour après l'installation
                Start-DellUpdate -Path $dcuCliPath
            }
            else {
                Write-Error "L'installation de Dell Command Update via winget semble avoir échoué car le fichier '$dcuCliPath' est introuvable."
            }
        }
        catch {
            Write-Error "Une erreur s'est produite lors de la tentative d'installation de Dell Command Update via winget."
            Write-Error $_.Exception.Message
            Write-Error "Vérifiez que winget est installé et fonctionne sur votre système (inclus dans les versions récentes de Windows 10/11)."
        }
    }
}
else {
    # Si le fabricant n'est pas Dell, on arrête tout.
    Write-Warning "Ce script est conçu pour les ordinateurs Dell uniquement."
    Write-Warning "Fabricant détecté : '$manufacturer'. Arrêt du script."
}

Write-Host "Le script a terminé son exécution."
