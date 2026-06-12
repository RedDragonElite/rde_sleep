# 🐉 RDE SLEEPMOD — v1.3.0

> **ox_core native · Proximity-Loaded Clones · StateBag-Synced · Free Forever**  
> Part of the [Red Dragon Elite](https://github.com/RedDragonElite) FiveM resource suite.

When a player disconnects, a sleeping clone of their character spawns at their last position — with their skin, their inventory, and a randomised sleeping pose. Other players can interact: rob them, carry them, or (admins only) forcefully wake them.

---

## ✨ Features

- **Proximity clone spawning** — clones load within `renderDistance`, despawn beyond `despawnDistance`. Zero entities when no players are nearby.
- **Persistent skin** — reads from `playerskins` table (illenium-appearance compatible). Falls back to manual component application.
- **Persistent inventory** — sleeping player's items accessible via ox_inventory stash. Stolen items are removed from their inventory on reconnect.
- **Carry system** — pick up a sleeping player and drop them anywhere. Position persists in DB and `characters` table.
- **Robbery** — progress-bar search with ox_inventory stash integration.
- **Admin wake** — triple-layer auth: ACE → ox_core groups → Steam ID whitelist.
- **Two-phase sleep animation** — lie-down intro plays once, then transitions to a proper breathing idle loop. No more idle-twitch bug.
- **ox_target integration** — context menu on every sleeping clone.
- **Statebag sync** — `GlobalState.sleepingPlayers` keeps all clients in sync without polling.
- **Auto-save** — coordinates + skin cached every 30 seconds and on resource stop.

---

## 📦 Dependencies

```
oxmysql
ox_lib
ox_core
ox_inventory
ox_target
illenium-appearance  (optional — falls back to manual skin application)
```

**server.cfg load order:**
```cfg
ensure oxmysql
ensure ox_lib
ensure ox_core
ensure ox_target
ensure ox_inventory
ensure rde_sleep
```

---

## 🗄️ Database

The resource auto-creates its table on first start (`Config.AutoCreateTable = true`):

```sql
CREATE TABLE IF NOT EXISTS rde_sleepmod (
    identifier  VARCHAR(60) PRIMARY KEY,
    charid      INT DEFAULT NULL,
    coords      TEXT NOT NULL,
    model       INT NOT NULL,
    skin        LONGTEXT,
    inventory   LONGTEXT,
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
)
```

Skin is read from your `playerskins` table. Set `Config.PlayerSkinsColumn` to match your column name (`citizenid` or `charid`).

---

## ⚙️ Configuration

Key values in `config.lua`:

| Key | Default | Description |
|---|---|---|
| `Config.DefaultLanguage` | `'en'` | `'en'` or `'de'` |
| `Config.Debug` | `false` | Verbose console output |
| `Config.Performance.renderDistance` | `200.0` | Clone spawn range (metres) |
| `Config.Performance.proximityTick` | `1000` | Proximity loop interval (ms) |
| `Config.Performance.maxVisiblePeds` | `50` | Max simultaneous clones |
| `Config.MaxSlots` | `50` | Robbery stash slots |
| `Config.InvinciblePeds` | `true` | Clones take no damage |
| `Config.PlayerSkinsColumn` | `'citizenid'` | Column in `playerskins` linking to `charId` |
| `Config.AdminSystem.acePermission` | `'rde.sleepmod'` | ACE node for admin access |

### Sleeping Animations

`Config.SleepingAnimations` accepts **only `@idle_a` entries**. The `@base` intro is derived and played automatically before the loop starts. Do not add `@base` clips manually — they will loop and cause the twitch bug.

```lua
-- ✅ Correct
{ dict = 'amb@world_human_bum_slumped@male@laying_on_back@idle_a', clip = 'idle_a' },

-- ❌ Wrong — @base clips loop the lie-down intro forever
{ dict = 'amb@world_human_bum_slumped@male@laying_on_back@base', clip = 'base' },
```

All three built-in dicts are ambient world animations — always loaded, no mission dependency.

---

## 🛡️ Admin

Admin check runs in order: `ace` → `oxcore` → `steam`.

```lua
Config.AdminSystem = {
    acePermission = 'rde.sleepmod',
    steamIds      = { 'steam:110000xxxxxxxxx' },
    oxGroups      = { ['admin'] = 0, ['superadmin'] = 0 },
    checkOrder    = { 'ace', 'oxcore', 'steam' },
}
```

Add the ACE node to a group in `server.cfg`:
```cfg
add_ace group.admin rde.sleepmod allow
```

---

## 📤 Exports

```lua
-- Get sleeping data for one player
exports.rde_sleep:GetSleepingPlayer(stateId)  -- returns table or nil

-- Get all sleeping players
exports.rde_sleep:GetAllSleepingPlayers()  -- returns table<stateId, data>

-- Remove a sleeping entry (wake up programmatically)
exports.rde_sleep:RemoveSleepingPlayer(stateId)

-- Check if a ped entity is a sleeping clone
exports.rde_sleep:IsSleepingClone(entity)  -- returns boolean
```

---

## 📋 Changelog

### v1.3.0
- **FIX** `@base` animation clips removed from `Config.SleepingAnimations` — they caused an idle-twitch loop when played with flag `1`. Config now accepts `@idle_a` entries only.
- **FIX** Two-phase animation in `SpawnSleepingPed`: `@base` intro played once (ped lies down), then transitions to `@idle_a` loop (ped sleeps). Carry-drop goes straight to `@idle_a` (ped already horizontal).
- **DOCS** `Wait(0)` in carry detection thread documented as intentional Standards exception (required for `IsControlJustPressed` frame-accuracy).

### v1.2.9
- Fixed `@base` / `@idle_a` clip name comments
- Proximity loop stability improvements

### v1.2.x
- ox_core migration (ESX removed)
- GlobalState statebag sync
- Carry + robbery system
- illenium-appearance skin support
- Auto-save thread

---

## 📜 License

MIT — free forever. No Tebex. No paywalls.  
**Free code, free minds.** 🐉⚡777
