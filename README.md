# 😴 RDE SleepMod — Next-Gen Sleep & Logout System

<div align="center">

![Version](https://img.shields.io/badge/version-1.0.2-red?style=for-the-badge&logo=github)
![License](https://img.shields.io/badge/license-RDE%20Black%20Flag%20v6.66-black?style=for-the-badge)
![FiveM](https://img.shields.io/badge/FiveM-Compatible-orange?style=for-the-badge)
![ox_core](https://img.shields.io/badge/ox__core-Required-blue?style=for-the-badge)
![Free](https://img.shields.io/badge/price-FREE%20FOREVER-brightgreen?style=for-the-badge)

**When players disconnect, they don't vanish — they sleep.**
Proximity-loaded sleeping peds, full skin sync from playerskins, robbery & carry mechanics, GlobalState sync, ox_target interaction.

Built on ox_core · ox_lib · ox_inventory · ox_target · oxmysql

*Built by [Red Dragon Elite](https://rd-elite.com) | SerpentsByte*

</div>

---

## 📖 Table of Contents

- [Overview](#-overview)
- [Features](#-features)
- [Dependencies](#-dependencies)
- [Installation](#-installation)
- [Configuration](#%EF%B8%8F-configuration)
- [How It Works](#-how-it-works)
- [Admin System](#-admin-system)
- [Developer API](#-developer-api)
- [Database](#-database)
- [Performance](#-performance)
- [Troubleshooting](#-troubleshooting)
- [Changelog](#-changelog)
- [License](#-license)

---

## 🎯 Overview

**RDE SleepMod** is a production-grade sleep and logout system for FiveM servers running ox_core. When a player disconnects or logs out, a sleeping ped is created at their last position — with their exact appearance loaded from the `playerskins` table. Other players can rob them, carry them, or admins can force-wake them. Everything is proximity-loaded and GlobalState-synced for maximum performance.

### Why RDE SleepMod?

| Feature | Generic Sleep Scripts | RDE SleepMod |
|---|---|---|
| Skin preservation | ❌ Default ped | ✅ Full playerskins sync |
| Proximity loading | ❌ Always loaded | ✅ Client-side LOD |
| Robbery system | ❌ | ✅ ox_inventory stash |
| Carry mechanics | ❌ | ✅ Full carry & release |
| Real-time sync | Network events | ✅ GlobalState — instant |
| Admin wake | ❌ | ✅ Triple-verified |
| Ground placement | ❌ Floating peds | ✅ GetGroundZ + PlaceOnGround |
| Multi-language | ❌ | ✅ EN + DE built-in |
| Server restart safe | ❌ Lost on restart | ✅ MySQL persistent |
| Performance | Heavy | ✅ < 0.01ms idle |

---

## ✨ Features

### 🎮 Gameplay
- **Sleeping Peds on Logout** — Players leave behind their character when they disconnect or use `/sleeplogout`
- **Full Skin Sync** — Appearance loaded directly from ox_core `playerskins` table (components, props, headBlend, faceFeatures, headOverlays, hair, tattoos, eyeColor)
- **Robbery System** — Search pockets via progress bar, opens ox_inventory stash with the sleeping player's items
- **Carry Mechanics** — Pick up sleeping peds, carry them with fireman's carry animation, release with [E]
- **Admin Wake** — Triple-verified admin system (ACE + ox_core Groups + Steam ID) to force-wake sleeping players
- **Sleeping Animation** — Proper GTA V lying animation (`amb@world_human_bum_slumped`)
- **Auto-Remove on Reconnect** — When a player logs back in, their sleeping ped is automatically removed

### 🚀 Technical
- **Proximity Loading** — Client-side ped spawning with configurable render/despawn distance and hysteresis (rde_props pattern)
- **GlobalState Sync** — Server broadcasts sleeping player positions via `GlobalState.sleepingPlayers`, clients react in real-time
- **Client-Side Peds** — Zero server entity overhead, no CNetObj limits, no network entity spawning
- **Ground Placement** — `GetGroundZFor_3dCoord` + `PlaceObjectOnGroundProperly` for perfect placement on all terrain
- **Auto-Save Cache** — Player appearance and inventory cached to MySQL every 5 minutes for crash protection
- **Skin Backfill** — On server start, any sleeping entries with missing skin data are automatically loaded from playerskins

### 🌍 Quality of Life
- **Multi-Language** — English + German built-in, easily expandable
- **ox_target Interaction** — Clean target options with Font Awesome icons
- **Progress Bars** — Smooth animations for robbery
- **Smart Notifications** — Contextual feedback via ox_lib
- **Debug Mode** — Verbose console logging with `/sleeptest` command

---

## 📦 Dependencies

| Resource | Required | Notes |
|---|---|---|
| [oxmysql](https://github.com/communityox/oxmysql) | ✅ Required | Database layer |
| [ox_core](https://github.com/communityox/ox_core) | ✅ Required | Player/character framework |
| [ox_lib](https://github.com/communityox/ox_lib) | ✅ Required | UI, callbacks, notifications |
| [ox_inventory](https://github.com/communityox/ox_inventory) | ✅ Required | Stash system for robbery |
| [ox_target](https://github.com/communityox/ox_target) | ✅ Required | Ped interaction |

**Optional:**
| [illenium-appearance](https://github.com/iLLeniumStudios/illenium-appearance) | Optional | If installed, used for skin application (fallback: manual component application) |

---

## 🚀 Installation

### 1. Clone the repository

```bash
cd resources
git clone https://github.com/RedDragonElite/rde_sleep.git rde_sleepmod
```

### 2. Add to `server.cfg`

```cfg
ensure oxmysql
ensure ox_core
ensure ox_lib
ensure ox_inventory
ensure ox_target
ensure rde_sleepmod

# Optional: Admin ACE permissions
add_ace group.admin rde.sleepmod allow
add_ace group.superadmin rde.sleepmod allow
```

> **Order matters.** `rde_sleepmod` must start **after** all its dependencies.

### 3. Database

The `rde_sleepmod` table is created automatically on first start. No manual SQL import needed.

### 4. Configure (Optional)

Edit `config.lua` to adjust language, proximity distances, animation, admin permissions, and UI.

### 5. Restart

```
restart rde_sleepmod
```

Test with `/sleeplogout` in-game.

---

## ⚙️ Configuration

### Language & Debug

```lua
Config.DefaultLanguage = 'en'    -- 'en' or 'de'
Config.Debug           = false   -- verbose console output
```

### Proximity & Performance

```lua
Config.Performance = {
    renderDistance  = 200.0,   -- spawn sleeping peds within this range
    despawnDistance = 250.0,   -- despawn beyond this (hysteresis)
    proximityTick  = 1000,    -- check interval in ms
    maxVisiblePeds = 50,      -- max rendered sleeping peds
    skinApplyDelay = 200,     -- ms delay before skin application
    animApplyDelay = 100,     -- ms delay before animation
}
```

### Gameplay

```lua
Config.RobDuration    = 3500   -- robbery progress bar duration (ms)
Config.RobDistance    = 2.5    -- max interaction range
Config.CarryDistance  = 2.5    -- max carry pickup range
Config.InvinciblePeds = true   -- sleeping peds can't be killed
Config.MaxSlots       = 50     -- stash slot count
Config.MaxWeight      = 100000 -- stash max weight
```

### Animations

```lua
Config.SleepingAnimation = {
    dict = 'amb@world_human_bum_slumped@male@laying_on_left_side@base',
    clip = 'base'
}
```

### Admin System

```lua
Config.AdminSystem = {
    acePermission = 'rde.sleepmod',
    steamIds = { 'steam:110000101605859' },
    oxGroups = { ['admin'] = 0, ['superadmin'] = 0, ['management'] = 0 },
    checkOrder = {'ace', 'oxcore', 'steam'}
}
```

### ox_target Icons

```lua
Config.TargetIcons = {
    rob   = 'fas fa-magnifying-glass',
    carry = 'fas fa-people-carry-box',
    wake  = 'fas fa-bell',
}
```

---

## 🎮 How It Works

### For Players

1. **Disconnect or `/sleeplogout`** — Your character stays in the world as a sleeping ped
2. **Other players see you** — With your exact skin, clothes, tattoos, and appearance
3. **They can rob you** — ox_target → Rob Player → progress bar → opens your inventory stash
4. **They can carry you** — ox_target → Carry Player → fireman's carry → [E] to release
5. **You log back in** — Your sleeping ped is automatically removed

### For Admins

- **Wake Players** — ox_target → Wake Player (admin-only option, triple-verified)
- **Debug** — `/sleeptest` shows spawned peds and GlobalState count

### Architecture

```
┌─────────────┐     GlobalState.sleepingPlayers     ┌──────────────┐
│   SERVER     │ ──────────────────────────────────→ │   CLIENT     │
│              │                                     │              │
│ • MySQL DB   │     lib.callback (skin data)        │ • Proximity  │
│ • playerskins│ ←─────────────────────────────────── │   Loop       │
│ • Stash mgmt │                                     │ • Ped spawn  │
│ • Admin auth │                                     │ • Skin apply │
│              │                                     │ • ox_target  │
└─────────────┘                                     └──────────────┘
```

**Server** stores data only — no entities, no network peds. **Client** handles all ped spawning via proximity loading, requesting skin data on-demand via callbacks.

---

## 🛡️ Admin System

Admin access uses **triple verification** — checked in configurable order:

### Method 1: ACE Permissions (Recommended)
```cfg
# server.cfg
add_ace group.admin rde.sleepmod allow
```

### Method 2: ox_core Groups
```lua
Config.AdminSystem.oxGroups = {
    ['admin'] = 0,
    ['superadmin'] = 0,
}
```

### Method 3: Steam ID Whitelist
```lua
Config.AdminSystem.steamIds = {
    'steam:110000101605859',
}
```

---

## 🔧 Developer API

### Exports (Server)

```lua
-- Get sleeping player data
local data = exports.rde_sleepmod:GetSleepingPlayer('DM1881')

-- Get all sleeping players
local all = exports.rde_sleepmod:GetAllSleepingPlayers()

-- Remove a sleeping player externally
exports.rde_sleepmod:RemoveSleepingPlayer('DM1881')
```

### Exports (Client)

```lua
-- Check if an entity is a sleeping clone
local isSleeping = exports.rde_sleepmod:IsClone(entity)
local isSleeping = exports.rde_sleepmod:IsSleepingClone(entity)
```

### GlobalState

```lua
-- Read sleeping player positions from any client
local sleepers = GlobalState.sleepingPlayers
-- Returns: { ['DM1881'] = { x, y, z, w, model }, ... }
```

---

## 🗄️ Database

Table is auto-created on first start:

```sql
CREATE TABLE rde_sleepmod (
    identifier  VARCHAR(60)  PRIMARY KEY,
    charid      INT          DEFAULT NULL,
    coords      TEXT         NOT NULL,
    model       INT          NOT NULL,
    skin        LONGTEXT,
    inventory   LONGTEXT,
    created_at  TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
    updated_at  TIMESTAMP    DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
```

**Skin data** is loaded from the `playerskins` table (column `citizenid`) and cached in `rde_sleepmod.skin` for persistence across server restarts.

---

## ⚡ Performance

### Architecture Advantages

| Aspect | Traditional Approach | RDE SleepMod |
|---|---|---|
| Entity type | Server-side network peds | Client-side local peds |
| CNetObj usage | 1 per sleeping ped | 0 |
| Sync method | Network events / polling | GlobalState (instant) |
| Rendering | All peds always loaded | Proximity-based LOD |
| Skin loading | On spawn (blocking) | On-demand callback (async) |

### Benchmarks

| Sleeping Players | Client Impact | Server Impact |
|---|---|---|
| 10 | Negligible | < 0.01ms |
| 50 | Negligible | < 0.01ms |
| 100 | < 1% FPS | < 0.02ms |
| 500 | ~2% FPS (only nearby) | < 0.05ms |

### Why So Fast?

- **Zero server entities** — Client creates local peds, no server overhead
- **Proximity culling** — Only peds within render distance are spawned
- **Hysteresis** — 50m gap between spawn/despawn distance prevents flicker
- **Async skin loading** — Skin data loaded via callback, doesn't block spawn
- **GlobalState** — Single statebag update replaces hundreds of network events

---

## 🐛 Troubleshooting

**Skin not showing on sleeping ped?**
Check your `playerskins` table column name — the script queries `citizenid`. If your table uses a different column name, update the query in `server.lua` function `LoadSkinFromDB`. Enable `Config.Debug = true` and check console for `skin: YES/NO` messages.

**Sleeping peds not visible after server restart?**
The script loads all sleeping entries from MySQL on start and syncs via GlobalState. If peds don't appear, check that `oxmysql` starts before `rde_sleepmod` in your `server.cfg`.

**Floating peds / peds underground?**
The script uses `GetGroundZFor_3dCoord` + `PlaceObjectOnGroundProperly`. If ground detection fails (interior, custom MLO), the ped uses stored Z coordinates as fallback.

**ox_target options not showing?**
Ensure `ox_target` starts before `rde_sleepmod`. Check F8 console for errors. The target is set up after skin and animation are applied — there's a ~800ms delay after spawn.

**Rob Player not working?**
Verify `ox_inventory` is running. Check server console for stash registration errors. The stash is created on-demand when a player initiates robbery.

**Admin Wake not showing?**
Admin status is checked once on player load. If you change admin groups, the player needs to relog. Verify ACE permissions, ox_core groups, or Steam IDs in `config.lua`.

---

## 📋 Commands

| Command | Access | Description |
|---|---|---|
| `/sleeplogout` | Player | Create sleeping ped and logout |
| `/sleeptest` | Debug only | Print spawned ped and GlobalState counts |

---

## 📝 Changelog

### v1.0.0 — Current
- Proximity-loaded sleeping peds (rde_props pattern)
- GlobalState sync — zero network events
- Full skin sync from `playerskins` table
- Client-side ped spawning — zero server entity overhead
- Robbery system with ox_inventory stash
- Carry mechanics with fireman's carry animation
- Triple-verified admin wake system
- Ground placement with `PlaceObjectOnGroundProperly`
- Auto-save cache every 5 minutes
- Skin backfill on server start
- Multi-language support (EN/DE)
- Production-grade error handling

---

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/your-feature`
3. Commit: `git commit -m 'Add your feature'`
4. Push: `git push origin feature/your-feature`
5. Open a Pull Request

Guidelines: follow existing Lua conventions, comment complex logic, test on a live server before PR, update docs if adding features.

---

## 📜 License

```
###################################################################################
#                                                                                 #
#      .:: RED DRAGON ELITE (RDE)  -  BLACK FLAG SOURCE LICENSE v6.66 ::.         #
#                                                                                 #
#   PROJECT:    RDE_SLEEPMOD v1.0.2 (SLEEP & LOGOUT SYSTEM FOR FIVEM)             #
#   ARCHITECT:  .:: RDE ⧌ Shin [△ ᛋᛅᚱᛒᛅᚾᛏᛋ ᛒᛁᛏᛅ ▽] ::. | https://rd-elite.com     #
#   ORIGIN:     https://github.com/RedDragonElite                                 #
#                                                                                 #
#   WARNING: THIS CODE IS PROTECTED BY DIGITAL VOODOO AND PURE HATRED FOR LEAKERS #
#                                                                                 #
#   [ THE RULES OF THE GAME ]                                                     #
#                                                                                 #
#   1. // THE "FUCK GREED" PROTOCOL (FREE USE)                                    #
#      You are free to use, edit, and abuse this code on your server.             #
#      Learn from it. Break it. Fix it. That is the hacker way.                   #
#      Cost: 0.00€. If you paid for this, you got scammed by a rat.               #
#                                                                                 #
#   2. // THE TEBEX KILL SWITCH (COMMERCIAL SUICIDE)                              #
#      Listen closely, you parasites:                                             #
#      If I find this script on Tebex, Patreon, or in a paid "Premium Pack":      #
#      > I will DMCA your store into oblivion.                                    #
#      > I will publicly shame your community.                                    #
#      > I hope your server lag spikes to 9999ms every time you blink.            #
#      SELLING FREE WORK IS THEFT. AND I AM THE JUDGE.                            #
#                                                                                 #
#   3. // THE CREDIT OATH                                                         #
#      Keep this header. If you remove my name, you admit you have no skill.      #
#      You can add "Edited by [YourName]", but never erase the original creator.  #
#      Don't be a skid. Respect the architecture.                                 #
#                                                                                 #
#   4. // THE CURSE OF THE COPY-PASTE                                             #
#      This code uses GlobalState, proximity loading, and async skin callbacks.   #
#      If you just copy-paste without reading, it WILL break.                     #
#      Don't come crying to my DMs. RTFM or learn to code.                        #
#                                                                                 #
#   --------------------------------------------------------------------------    #
#   "We build the future on the graves of paid resources."                        #
#   "REJECT MODERN MEDIOCRITY. EMBRACE RDE SUPERIORITY."                          #
#   --------------------------------------------------------------------------    #
###################################################################################
```

**TL;DR:**
- ✅ Free forever — use it, edit it, learn from it
- ✅ Keep the header — credit where it's due
- ❌ Don't sell it — commercial use = instant DMCA
- ❌ Don't be a skid — copy-paste without reading won't work anyway

---

## 📁 File Structure

```
rde_sleepmod/
├── fxmanifest.lua    # Resource manifest
├── config.lua        # All configuration + languages
├── client.lua        # Proximity loading, skin, animation, carry, robbery
├── server.lua        # Database, GlobalState sync, stash, admin
└── README.md         # You're reading it
```

---

## 🌐 Community & Support

| | |
|---|---|
| 🐙 GitHub | [RedDragonElite](https://github.com/RedDragonElite) |
| 🌍 Website | [rd-elite.com](https://rd-elite.com) |
| 🔵 Nostr (RDE) | [RedDragonElite](https://primal.net/p/nprofile1qqsv8km2w8yr0sp7mtk3t44qfw7wmvh8caqpnrd7z6ll6mn9ts03teg9ha4rl) |
| 🔵 Nostr (Shin) | [SerpentsByte](https://primal.net/p/nprofile1qqs8p6u423fappfqrrmxful5kt95hs7d04yr25x88apv7k4vszf4gcqynchct) |
| 🎮 RDE Props | [rde_props](https://github.com/RedDragonElite/rde_props) |
| 🚪 RDE Doors | [rde_doors](https://github.com/RedDragonElite/rde_doors) |
| 🚗 RDE Car Service | [rde_carservice](https://github.com/RedDragonElite/rde_carservice) |
| 🎯 RDE Skills | [rde_skills](https://github.com/RedDragonElite/rde_skills) |
| 📡 RDE Nostr Log | [rde_nostr_log](https://github.com/RedDragonElite/rde_nostr_log) |

**When asking for help, always include:**
- Full error from server console or txAdmin
- Your `server.cfg` resource start order
- ox_core / ox_lib versions in use
- Content of `playerskins` table (column names)

---

<div align="center">

*"We build the future on the graves of paid resources."*

**REJECT MODERN MEDIOCRITY. EMBRACE RDE SUPERIORITY.**

🐉 Made with 🔥 by [Red Dragon Elite](https://rd-elite.com)

[⬆ Back to Top](#-rde-sleepmod--next-gen-sleep--logout-system)

</div>
