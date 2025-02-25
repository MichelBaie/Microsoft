<#
.SYNOPSIS
    Script permettant de désactiver l'extinction automatique de l'écran et la mise en veille pour le compte utilisateur "ITLocal".

.DESCRIPTION
    Ce script vérifie si l'utilisateur actuel est "ITLocal". Si c'est le cas, il modifie les paramètres d'alimentation pour empêcher l'écran de s'éteindre et le PC de passer en veille lorsqu'il est connecté au secteur.

.AUTHOR
    Tristan BRINGUIER

.DATE
    Février 2025

.VERSION
    1.0

.NOTES
    Ce script doit être exécuté avec des privilèges administratifs pour modifier les paramètres d'alimentation.
    Il ne s'exécute que pour le compte utilisateur "ITLocal".

.EXAMPLE
    .\donotsleep.ps1

.PARAMETER None
    Ce script ne prend pas de paramètres en entrée.

.OUTPUTS
    Le script affiche des messages dans la console indiquant si les paramètres ont été modifiés ou non.

.INPUTS
    Aucune entrée utilisateur n'est requise pour l'exécution du script.
#>


# Vérifier si le nom d'utilisateur correspond à "ITLocal"
if ($env:USERNAME -eq "ITLocal") {
    Write-Output "Compte ITLocal détecté. Modification des paramètres d'alimentation..."

    # Désactiver l'extinction automatique de l'écran et la mise en veille en mode secteur (AC)
    powercfg -change -monitor-timeout-ac 0
    powercfg -change -standby-timeout-ac 0

    Read-Host "Les paramètres ont été modifiés : l'écran reste allumé et le PC ne passe pas en veille."
}
else {
    Write-Output "Ce script s'exécute uniquement pour les comptes ITLocal. Aucun changement appliqué."
}
