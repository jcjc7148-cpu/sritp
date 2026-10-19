PlayerConfig = {}

-- XP gagnée automatiquement en jouant
PlayerConfig.PlaytimeXP = { every = 10, amount = 25 } -- toutes les 10 minutes : +25 XP

PlayerConfig.MaxLevel = 100

-- XP nécessaire pour passer du niveau N au niveau N+1
function PlayerConfig.XPForLevel(level)
    return math.floor(100 + (level - 1) * 40)
end

-- Récompenses de niveau (argent en banque et/ou items)
PlayerConfig.LevelRewards = {
    [5]   = { bank = 5000,   label = '5 000 $' },
    [10]  = { bank = 15000,  label = '15 000 $' },
    [20]  = { bank = 30000,  label = '30 000 $' },
    [30]  = { bank = 50000,  label = '50 000 $' },
    [50]  = { bank = 100000, label = '100 000 $' },
    [75]  = { bank = 200000, label = '200 000 $' },
    [100] = { bank = 500000, label = '500 000 $' },
}

-- Nouveaux joueurs : système désactivé (pas de statut "Nouveau", pas de tag, aucune restriction)
PlayerConfig.NewbieEnabled = false
PlayerConfig.NewbieHours = 5            -- (si réactivé) statut "Nouveau" pendant 5 h de jeu
PlayerConfig.NewbieTag = false          -- (si réactivé) affiche "NOUVEAU" au-dessus de la tête
PlayerConfig.NewbieCanJoinIllegal = true

-- Kit de départ (items ox_inventory)
PlayerConfig.StarterKit = {
    { name = 'phone', count = 1 },
    { name = 'water', count = 3 },
    { name = 'bread', count = 3 },
}

PlayerConfig.WelcomeMessage = 'Bienvenue sur Vexora WL ! Appuie sur F5 pour ton menu personnel. Besoin d\'aide ? /report'
