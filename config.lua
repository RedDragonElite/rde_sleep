-- ============================================
-- 🐉 RDE SLEEPMOD - CONFIG v1.0.2
-- Proximity Loading | Statebag Sync | ox_core
-- Author: Red Dragon Elite | SerpentsByte
-- ============================================

Config = {}

-- ============================================
-- 🌍 LOCALIZATION
-- ============================================
Config.DefaultLanguage = 'en'

Config.Languages = {
    en = {
        success = 'Success', error = 'Error', warning = 'Warning',
        searching_pockets = 'Searching pockets...', carrying_player = 'Carrying player...',
        press_release = 'Press [E] to release', inventory_opened = 'Inventory opened',
        inventory_failed = 'Could not access inventory', player_carried = 'Now carrying player',
        player_released = 'Player released', already_carrying = 'Already carrying someone',
        rob_player = 'Rob Player', rob_description = 'Search their pockets',
        carry_player = 'Carry Player', carry_description = 'Pick up and carry',
        wake_player = 'Wake Player', wake_description = 'Force wake up (Admin)',
        no_permission = 'You do not have permission', admin_only = 'Admin only',
        player_woken = 'Player has been woken up', sleeping = 'Sleeping',
        offline = 'Offline', too_far = 'Too far away',
    },
    de = {
        success = 'Erfolg', error = 'Fehler', warning = 'Warnung',
        searching_pockets = 'Durchsuche Taschen...', carrying_player = 'Trage Spieler...',
        press_release = 'Drücke [E] zum Ablegen', inventory_opened = 'Inventar geöffnet',
        inventory_failed = 'Konnte nicht auf Inventar zugreifen', player_carried = 'Trage jetzt Spieler',
        player_released = 'Spieler abgelegt', already_carrying = 'Trägst bereits jemanden',
        rob_player = 'Spieler ausrauben', rob_description = 'Durchsuche Taschen',
        carry_player = 'Spieler tragen', carry_description = 'Hebe auf und trage',
        wake_player = 'Spieler aufwecken', wake_description = 'Aufwachen zwingen (Admin)',
        no_permission = 'Keine Berechtigung', admin_only = 'Nur für Admins',
        player_woken = 'Spieler wurde aufgeweckt', sleeping = 'Schlafend',
        offline = 'Offline', too_far = 'Zu weit entfernt',
    }
}

function GetLanguageString(key)
    local lang = Config.Languages[Config.DefaultLanguage]
    return lang and lang[key] or key
end

-- ============================================
-- ⚙️ PERFORMANCE & PROXIMITY
-- ============================================

Config.Debug = true -- ← Set false in production!

Config.Performance = {
    renderDistance  = 200.0,
    despawnDistance = 250.0,
    proximityTick  = 1000,
    maxVisiblePeds = 50,
    skinApplyDelay = 200,
    animApplyDelay = 100,
}

-- ============================================
-- 🎮 GAMEPLAY
-- ============================================

Config.MaxSlots = 50
Config.MaxWeight = 100000
Config.RobDuration = 3500
Config.RobDistance = 2.5
Config.CarryDistance = 2.5
Config.InvinciblePeds = true

Config.CarryOffset = {
    x = 0.27, y = 0.15, z = 0.63,
    pitch = 0.5, roll = 0.5, yaw = 0.0
}

Config.SleepingAnimation = {
    dict = 'amb@world_human_bum_slumped@male@laying_on_left_side@base',
    clip = 'base'
}

Config.RobAnimation = {
    dict = 'mini@repair',
    clip = 'fixing_a_ped'
}

Config.CarryAnimation = {
    carrier = { dict = 'missfinale_c2mcs_1', clip = 'fin_c2_mcs_1_camman' },
    carried = { dict = 'nm', clip = 'firemans_carry' }
}

-- ============================================
-- 🛡️ ADMIN
-- ============================================

Config.AdminSystem = {
    acePermission = 'rde.sleepmod',
    steamIds = { 'steam:110000101605859' },
    oxGroups = { ['admin'] = 0, ['superadmin'] = 0, ['management'] = 0, ['owner'] = 0 },
    checkOrder = {'ace', 'oxcore', 'steam'}
}

-- ============================================
-- 🎨 UI
-- ============================================

Config.TargetDistance = 2.5

Config.TargetIcons = {
    rob   = 'fas fa-magnifying-glass',
    carry = 'fas fa-people-carry-box',
    wake  = 'fas fa-bell',
}

-- ============================================
-- 📊 DATABASE
-- ============================================

Config.DatabaseTable = 'rde_sleepmod'
Config.AutoCreateTable = true

return Config
