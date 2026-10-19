CreatorConfig = {}

---------------------------------------------------------------------
-- IDENTITÉ
---------------------------------------------------------------------
CreatorConfig.MinAge = 18
CreatorConfig.MaxAge = 90
CreatorConfig.MinHeight = 150
CreatorConfig.MaxHeight = 210
CreatorConfig.NameMin = 2
CreatorConfig.NameMax = 19

---------------------------------------------------------------------
-- CRÉATEUR DE PERSONNAGE
---------------------------------------------------------------------
-- Pendant la création, le joueur est seul dans sa "dimension" (les autres ne le voient pas)
CreatorConfig.PrivateBucket = true
-- Touches pour tourner le personnage (contrôles GTA : 44 = A/Q, 38 = E)
CreatorConfig.RotateLeft = 44
CreatorConfig.RotateRight = 38

---------------------------------------------------------------------
-- MAGASINS DE VÊTEMENTS (menu RageUI)
---------------------------------------------------------------------
CreatorConfig.Shop = {
    Blip = { sprite = 73, color = 0, scale = 0.75, label = 'Magasin de vêtements' },
    Key = 38,               -- E
    Distance = 2.2,
    -- prix par catégorie modifiée (payé en liquide, sinon en banque)
    Prices = {
        [11] = 120, -- haut
        [8]  = 60,  -- t-shirt
        [3]  = 20,  -- bras / torse
        [4]  = 90,  -- pantalon
        [6]  = 80,  -- chaussures
        [1]  = 70,  -- masque
        [5]  = 60,  -- sac
        [7]  = 40,  -- accessoire
        p0 = 50,    -- chapeau
        p1 = 45,    -- lunettes
        p2 = 35,    -- boucles d'oreilles
        p6 = 90,    -- montre
        p7 = 40,    -- bracelet
    },
    Locations = {
        vector4(1693.2, 4828.11, 42.07, 188.66),
        vector4(-705.5, -149.22, 37.42, 122.0),
        vector4(-1192.61, -768.4, 17.32, 216.6),
        vector4(425.91, -801.03, 29.49, 177.79),
        vector4(-168.73, -301.41, 39.73, 238.67),
        vector4(75.39, -1398.28, 29.38, 6.73),
        vector4(-827.39, -1075.93, 11.33, 294.31),
        vector4(-1445.86, -240.78, 49.82, 36.17),
        vector4(9.22, 6515.74, 31.88, 131.27),
        vector4(615.35, 2762.72, 42.09, 170.51),
        vector4(1191.61, 2710.91, 38.22, 269.96),
        vector4(-3171.32, 1043.56, 20.86, 334.3),
        vector4(-1105.52, 2707.79, 19.11, 317.19),
        vector4(-1119.24, -1440.6, 5.23, 300.5),
        vector4(124.82, -224.36, 54.56, 335.41),
    },
}

-- Catégories de vêtements (composants et accessoires GTA)
CreatorConfig.Clothes = {
    { key = 11, label = 'Haut / veste',      icon = '🧥', cam = 'body' },
    { key = 8,  label = 'T-shirt',            icon = '👕', cam = 'body' },
    { key = 3,  label = 'Bras / torse',       icon = '💪', cam = 'body' },
    { key = 4,  label = 'Pantalon',           icon = '👖', cam = 'legs' },
    { key = 6,  label = 'Chaussures',         icon = '👟', cam = 'feet' },
    { key = 7,  label = 'Chaîne / cravate',   icon = '📿', cam = 'body' },
    { key = 5,  label = 'Sac',                icon = '🎒', cam = 'body' },
    { key = 1,  label = 'Masque',             icon = '🎭', cam = 'face' },
    { key = 'p0', label = 'Chapeau / casque', icon = '🧢', cam = 'face' },
    { key = 'p1', label = 'Lunettes',         icon = '🕶️', cam = 'face' },
    { key = 'p2', label = 'Boucles d\'oreilles', icon = '💎', cam = 'face' },
    { key = 'p6', label = 'Montre',           icon = '⌚', cam = 'body' },
    { key = 'p7', label = 'Bracelet',         icon = '📿', cam = 'body' },
}

---------------------------------------------------------------------
-- BARBIER (point « Barbier », touche E)
---------------------------------------------------------------------
CreatorConfig.Barber = {
    Blip = { sprite = 71, color = 0, scale = 0.75, label = 'Barbier' },
    Key = 38,          -- E
    Distance = 2.2,
    -- prix par partie modifiée (payé en liquide, sinon en banque)
    Prices = {
        hair = 60,       -- coupe / couleur des cheveux
        eyebrows = 25,   -- sourcils
        beard = 40,      -- barbe
        eyes = 30,       -- couleur des yeux
        makeUp = 35,     -- maquillage
        blush = 20,      -- blush
        lipstick = 20,   -- rouge à lèvres
    },
    Locations = {
        vector4(-814.22, -183.7, 37.57, 116.91),
        vector4(136.78, -1708.4, 29.29, 144.19),
        vector4(-1282.57, -1116.84, 6.99, 89.25),
        vector4(1931.41, 3729.73, 32.84, 212.08),
        vector4(1212.8, -472.9, 65.2, 60.94),
        vector4(-32.9, -152.3, 56.1, 335.22),
        vector4(-278.1, 6228.5, 30.7, 49.32),
    },
}

-- Points modifiables en jeu : Admin > Configuration serveur > Lieux et blips
-- Les magasins de vêtements sont gérés par nova_clothing (CreatorConfig.Shop ne sert plus qu'aux prix de l'éditeur)
Nova.PlaceSet('barber', CreatorConfig.Barber.Locations, { label = 'Barbiers', fields = { { k = '@', label = 'Point', h = true } } })
