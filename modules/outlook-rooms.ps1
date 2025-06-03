# Création de la RoomList

<#
    Script : Create-RoomList_AllRooms.ps1
    Objet  : Crée (ou met à jour) la Room List et y ajoute
             toutes les salles (Room Mailboxes) du tenant Office 365.
    
    POURQUOI CE SCRIPT :
    - Les Room Lists permettent de regrouper les salles de réunion dans Outlook
    - Elles facilitent la recherche et la réservation de salles pour les utilisateurs
    - Sans Room List, les utilisateurs doivent connaître les noms exacts des salles
    - Ce script automatise la création et la maintenance de cette liste
#>

# ─── Variables à modifier si besoin ─────────────────────────────────────────────
# POURQUOI ces variables : centraliser la configuration pour faciliter la réutilisation
$AdminUPN      = "admin@company.onmicrosoft.com"   # Compte avec droits Exchange Admin requis
$RoomListName  = "Company - rooms"                 # Nom visible dans l'interface Outlook
$RoomListSMTP  = "company-rooms@company.com"       # Adresse email unique pour identifier la liste
# ───────────────────────────────────────────────────────────────────────────────

# POURQUOI importer ce module : 
# - Il contient toutes les commandes pour gérer Exchange Online
# - ErrorAction Stop = arrête le script si le module n'est pas disponible (évite des erreurs cryptiques plus tard)
Import-Module ExchangeOnlineManagement -ErrorAction Stop

Write-Host "[+] Connexion à Exchange Online…" -ForegroundColor Cyan
# POURQUOI cette connexion :
# - Obligatoire pour exécuter des commandes Exchange Online
# - UserPrincipalName spécifie le compte admin à utiliser
# - ShowBanner:$false évite l'affichage de messages de bienvenue parasites
Connect-ExchangeOnline -UserPrincipalName $AdminUPN -ShowBanner:$false

# POURQUOI un bloc try-finally :
# - Garantit que la déconnexion Exchange aura lieu même en cas d'erreur
# - Évite de laisser des sessions ouvertes qui consomment des ressources
try {
    # ═══════════════════════════════════════════════════════════════════════════════
    # ÉTAPE 1 : CRÉER LA ROOM LIST SI ELLE N'EXISTE PAS
    # ═══════════════════════════════════════════════════════════════════════════════
    
    # POURQUOI vérifier l'existence avant création :
    # - Évite une erreur si la Room List existe déjà
    # - Permet de faire du "idempotent scripting" (réexécutable sans problème)
    $dg = Get-DistributionGroup -Identity $RoomListSMTP -ErrorAction SilentlyContinue
    
    if (-not $dg) {
        Write-Host "[+] Création de la Room List '$RoomListName'…" -ForegroundColor Cyan
        # POURQUOI New-DistributionGroup avec -RoomList :
        # - Les Room Lists sont techniquement des groupes de distribution spéciaux
        # - Le paramètre -RoomList les marque comme listes de salles (comportement spécifique dans Outlook)
        # - PrimarySmtpAddress définit l'adresse email principale pour l'identification
        $dg = New-DistributionGroup -Name $RoomListName `
                                    -PrimarySmtpAddress $RoomListSMTP `
                                    -RoomList
    } else {
        Write-Host "[=] La Room List '$RoomListName' existe déjà." -ForegroundColor Yellow
    }

    # ═══════════════════════════════════════════════════════════════════════════════
    # ÉTAPE 2 : RÉCUPÉRER TOUTES LES SALLES DU TENANT
    # ═══════════════════════════════════════════════════════════════════════════════
    
    Write-Host "[~] Recherche de toutes les salles…" -ForegroundColor Cyan
    # POURQUOI RecipientTypeDetails RoomMailbox :
    # - Filtre uniquement les boîtes aux lettres de type "salle de réunion"
    # - Exclut les utilisateurs normaux, équipements, boîtes partagées, etc.
    # - Plus efficace que récupérer toutes les mailboxes puis filtrer
    $rooms = Get-Mailbox -RecipientTypeDetails RoomMailbox

    # POURQUOI cette vérification :
    # - Évite de continuer le traitement s'il n'y a aucune salle
    # - Informe l'administrateur qu'il n'y a rien à faire
    if (-not $rooms) {
        Write-Warning "Aucune salle trouvée dans le tenant !"
        return
    }

    # ═══════════════════════════════════════════════════════════════════════════════
    # ÉTAPE 3 : AJOUTER CHAQUE SALLE À LA ROOM LIST
    # ═══════════════════════════════════════════════════════════════════════════════
    
    # POURQUOI une boucle foreach :
    # - Traite chaque salle individuellement pour un meilleur contrôle d'erreur
    # - Permet d'afficher le progrès en temps réel
    foreach ($room in $rooms) {
        # POURQUOI un bloc try-catch par salle :
        # - Une erreur sur une salle ne doit pas arrêter le traitement des autres
        # - Permet de gérer spécifiquement le cas "déjà membre"
        try {
            # POURQUOI Add-DistributionGroupMember :
            # - Commande standard pour ajouter des membres aux groupes de distribution
            # - Identity = la Room List cible
            # - Member = la salle à ajouter (on utilise Alias car plus stable que DisplayName)
            Add-DistributionGroupMember -Identity $RoomListSMTP `
                                        -Member   $room.Alias `
                                        -ErrorAction Stop
            Write-Host "   → Ajouté : $($room.DisplayName)" -ForegroundColor Green
        } catch {
            # POURQUOI traiter spécifiquement "is already a member" :
            # - C'est un cas normal lors de re-exécutions du script
            # - Ne doit pas être traité comme une vraie erreur
            if ($_.Exception -match "is already a member") {
                Write-Host "   → Déjà présent : $($room.DisplayName)" -ForegroundColor DarkGray
            } else {
                # POURQUOI Write-Warning pour les autres erreurs :
                # - Signale un problème sans arrêter le script
                # - Permet de continuer avec les autres salles
                Write-Warning "   → ERREUR sur $($room.DisplayName) : $_"
            }
        }
    }

    # ═══════════════════════════════════════════════════════════════════════════════
    # ÉTAPE 4 : AFFICHER UN RÉCAPITULATIF
    # ═══════════════════════════════════════════════════════════════════════════════
    
    Write-Host "`nMembres actuels de la Room List :" -ForegroundColor Cyan
    # POURQUOI ce récapitulatif :
    # - Permet de vérifier visuellement le résultat
    # - Utile pour les audits et la documentation
    # - Sort-Object pour un affichage ordonné et lisible
    Get-DistributionGroupMember -Identity $RoomListSMTP |
        Sort-Object Name |
        Format-Table Name, PrimarySmtpAddress, Office -AutoSize
}
finally {
    # POURQUOI dans finally :
    # - S'exécute TOUJOURS, même en cas d'erreur ou d'interruption
    # - Évite de laisser des sessions Exchange ouvertes
    # - Confirm:$false évite une demande de confirmation interactive
    Disconnect-ExchangeOnline -Confirm:$false
    Write-Host "[✓] Terminé." -ForegroundColor Cyan
}

# ═══════════════════════════════════════════════════════════════════════════════════
# SECTION 2 : CONFIGURATION DE L'EMPLACEMENT DES SALLES
# ═══════════════════════════════════════════════════════════════════════════════════

# POURQUOI cette section séparée :
# - La configuration des emplacements est optionnelle mais recommandée
# - Améliore l'expérience utilisateur dans New Outlook et Teams
# - Permet le filtrage géographique des salles

# POURQUOI réimporter et reconnecter :
# - Ce script peut être exécuté indépendamment de la première partie
# - Garantit que les modules et connexions sont disponibles
Import-Module ExchangeOnlineManagement -ErrorAction Stop
Connect-ExchangeOnline -UserPrincipalName admin@company.onmicrosoft.com -ShowBanner:$false

# POURQUOI ces variables d'emplacement :
# - Standardise l'information géographique de toutes les salles
# - Facilite la maintenance (changement centralisé)
$City      = "CityName"      # Utilisé pour le filtrage géographique
$Building  = "BuildingName"  # Aide à localiser précisément les salles

# POURQUOI re-récupérer les salles :
# - Ce bloc peut être exécuté indépendamment
# - Assure qu'on a la liste la plus récente
$rooms = Get-Mailbox -RecipientTypeDetails RoomMailbox

foreach ($r in $rooms) {
    # POURQUOI un hashtable pour les propriétés :
    # - Syntaxe propre et extensible
    # - Permet d'ajouter facilement d'autres propriétés (Country, Floor, etc.)
    $props = @{
        City      = $City
        Building  = $Building
    }
    
    # POURQUOI Set-Place :
    # - Commande spécialisée pour les propriétés d'emplacement des salles
    # - Synchronise avec le service de lieux Microsoft (Places)
    # - Améliore l'intégration avec Teams et New Outlook
    Set-Place -Identity $r.Alias @props
    Write-Host "✔ Propriétés mises à jour pour $($r.DisplayName)"
}

# POURQUOI se déconnecter à nouveau :
# - Libère les ressources de session
# - Bonne pratique de sécurité (limite l'exposition des sessions admin)
Disconnect-ExchangeOnline -Confirm:$false
