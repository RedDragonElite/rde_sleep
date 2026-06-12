# 🐉 rde_sleep

[![Version](https://img.shields.io/badge/version-1.3.2-red?style=for-the-badge)](https://github.com/RedDragonElite/rde_sleep)
[![License](https://img.shields.io/badge/license-RDE%20Black%20Flag-black?style=for-the-badge)](LICENSE)
[![FiveM](https://img.shields.io/badge/FiveM-Compatible-blue?style=for-the-badge)](https://fivem.net)
[![ox_core](https://img.shields.io/badge/Framework-ox__core-blue?style=for-the-badge)](https://github.com/overextended/ox_core)
[![ox_inventory](https://img.shields.io/badge/ox__inventory-supported-green?style=for-the-badge)](https://github.com/overextended/ox_inventory)
[![ox_target](https://img.shields.io/badge/ox__target-supported-green?style=for-the-badge)](https://github.com/overextended/ox_target)
[![Nostr](https://img.shields.io/badge/Nostr-Decentralized-purple?style=for-the-badge)](https://github.com/RedDragonElite/rde_nostr_log)
[![Quality](https://img.shields.io/badge/Quality-Production-gold?style=for-the-badge)](https://github.com/RedDragonElite)

**😴 RDE SLEEP | Next-Gen Offline Sleep System for FiveM ox_core | Proximity-Loaded Clones | StateBag-Synced | Skin-Persistent | Robbable | Free Forever**

*Built by [Red Dragon Elite](https://rd-elite.com) | Free Forever | No Paywalls | No Legacy*

[📖 Installation](#-installation) • [⚙️ Configuration](#️-configuration) • [📡 Exports](#-exports) • [🐛 Troubleshooting](#-troubleshooting) • [🌐 Website](https://rd-elite.com) • [🔭 Terminal](https://rd-elite.com/Files/NOSTR/)

---

## 🔥 Why This Destroys Every Other Sleep Script

Every other sleep script either ignores players when they disconnect or shows a static, skinless, unanimated ghost. We said no.

| ❌ Other Sleep Scripts | ✅ rde_sleep |
|---|---|
| Paid or locked behind Tebex | 100% free forever — RDE Black Flag |
| Skinless placeholder ped | Full skin restore via illenium-appearance or manual fallback |
| Static T-pose on disconnect | Two-phase animation: real lie-down → breathing idle loop |
| No inventory interaction | Full ox_inventory stash — rob sleeping players, stolen items removed on reconnect |
| No carry system | Pick up and carry sleeping players, drop them anywhere — position persists |
| Single global entity table | Proximity-based spawn/despawn — zero entities when nobody is nearby |
| Hardcoded position on reconnect | Tracks carry-drops in DB + characters table — player wakes up where they were left |
| ESX / QBCore only | ox_core native — the future, not the past |
| Resource restarts break everything | Full DB persistence + `activeStashes` guard with ox_inventory empty-check |

---

## 🎯 Key Features

- 😴 **Proximity clone spawning** — sleeping peds spawn within `renderDistance`, despawn beyond `despawnDistance`. Zero entities when no players are nearby.
- 🎨 **Full skin persistence** — reads from `playerskins` via illenium-appearance. Falls back to manual component/overlay/tattoo application.
- 🎒 **Persistent inventory** — items accessible via ox_inventory stash. Stolen items are deducted from the player's inventory on reconnect.
- 💪 **Carry system** — pick up any sleeping player, carry them across the map, drop them. DB + `characters` table updated on drop.
- 🔍 **Robbery** — progress-bar search with ox_inventory stash integration. First open populates; subsequent opens use live stash state.
- 🔔 **Admin wake** — triple-layer auth: ACE → ox_core groups → Steam ID whitelist.
- 🎬 **Two-phase sleep animation** — `@base` lie-down intro plays once, then `@idle_a` loops with realistic breathing. No more idle-twitch bug from looping `@base` clips. Animation verified post-play with auto-retry against illenium race condition.
- 🎯 **ox_target integration** — Rob / Carry / Wake context menu on every sleeping clone.
- 📡 **StateBag sync** — `GlobalState.sleepingPlayers` keeps all clients in sync without polling.
- 💾 **Auto-save** — coordinates + skin cached every 30 seconds and on resource stop.
- 🔒 **Stash dedup guard** — ox_inventory persists stash contents in DB across resource restarts. Items are never re-added if the stash is already populated.

---

## 📦 Dependencies

```
oxmysql        → https://github.com/overextended/oxmysql
ox_lib         → https://github.com/overextended/ox_lib
ox_core        → https://github.com/overextended/ox_core
ox_inventory   → https://github.com/overextended/ox_inventory
ox_target      → https://github.com/overextended/ox_target

optional:
illenium-appearance  → full skin restore (falls back to manual if absent)
```

---

## 🚀 Installation

### Step 1: Clone or download

```bash
cd resources
git clone https://github.com/RedDragonElite/rde_sleep.git
```

### Step 2: Add to server.cfg

```cfg
ensure oxmysql
ensure ox_lib
ensure ox_core
ensure ox_target
ensure ox_inventory
ensure rde_sleep
```

### Step 3: Configure

Edit `config.lua` — defaults work out of the box. Key values:

- `Config.PlayerSkinsColumn` — column in `playerskins` linking to `charId` (`'citizenid'` or `'charid'`)
- `Config.AdminSystem` — ACE permission, Steam IDs, ox_core group names
- `Config.Performance.renderDistance` — clone spawn radius

### Step 4: Start your server

Tables auto-create on first run. No SQL import needed.

---

## ⚙️ Configuration

```lua
Config.Debug = false                     -- verbose console output
Config.Performance.renderDistance  = 200.0  -- clone spawn range
Config.Performance.proximityTick   = 1000   -- proximity loop (ms)
Config.Performance.maxVisiblePeds  = 50     -- max simultaneous clones
Config.InvinciblePeds = true             -- clones take no damage
Config.PlayerSkinsColumn = 'citizenid'   -- playerskins column → charId
```

### Admin

```lua
Config.AdminSystem = {
    acePermission = 'rde.sleepmod',
    steamIds      = { 'steam:110000xxxxxxxxx' },
    oxGroups      = { ['admin'] = 0, ['superadmin'] = 0 },
    checkOrder    = { 'ace', 'oxcore', 'steam' },
}
```

ACE setup in `server.cfg`:
```cfg
add_ace group.admin rde.sleepmod allow
```

### Sleeping Animations

`Config.SleepingAnimations` accepts **only `@idle_a` entries**. The `@base` intro is derived and played automatically. Do not add `@base` clips — they will loop and cause the twitch bug.

```lua
-- ✅ Correct
{ dict = 'amb@world_human_bum_slumped@male@laying_on_back@idle_a', clip = 'idle_a' },

-- ❌ Wrong — @base clips with flag=1 loop the lie-down intro forever
{ dict = 'amb@world_human_bum_slumped@male@laying_on_back@base', clip = 'base' },
```

---

## 📡 Exports

### Server

```lua
-- Get sleeping data for one player
exports.rde_sleep:GetSleepingPlayer(stateId)   -- table | nil

-- Get all sleeping players
exports.rde_sleep:GetAllSleepingPlayers()      -- table<stateId, data>

-- Remove a sleeping entry (programmatic wake)
exports.rde_sleep:RemoveSleepingPlayer(stateId)
```

### Client

```lua
-- Check if a ped entity is a sleeping clone
exports.rde_sleep:IsSleepingClone(entity)      -- boolean
exports.rde_sleep:IsClone(entity)              -- boolean (alias)
```

---

## 🔧 Debug Commands

Enable with `Config.Debug = true`, then in-game:

| Command | Description |
|---------|-------------|
| `sleeplogout` | Manually trigger a sleeping entry (simulate logout) |
| `sleeptest` | Print spawned ped count vs GlobalState count to console |

---

## 🗂 Folder Structure

```
rde_sleep/
├── fxmanifest.lua
├── config.lua
├── README.md
├── LICENSE
├── client.lua      ← proximity loop, ped spawn/despawn, carry, robbery, animations
└── server.lua      ← DB, statebag sync, playerDropped, stash, admin, exports
```

---

## 🐛 Troubleshooting

### Sleeping clone stands upright after server restart

You're on v1.3.1 or earlier. The post-skin delay was 500ms — not enough on server restart because illenium-appearance clears ped tasks asynchronously. Fixed in v1.3.2: delay increased to 1000ms + animation verified with auto-retry via `IsEntityPlayingAnim`.

### Items duplicate in sleeping player stash after resource restart

You're on v1.3.1 or earlier. `activeStashes` is in-memory — cleared on resource restart. ox_inventory persists stash contents in DB, so snapshot items were added on top on next access. Fixed in v1.3.2: `RegisterStash` now calls `GetInventory` first and only populates if the stash is genuinely empty.

### Sleeping clone twitches instead of sleeping

You're on v1.2.9 or earlier. `@base` clips with loop flag=1 repeat the lie-down intro forever. Fixed in v1.3.0: Config now accepts only `@idle_a` entries. The `@base` intro is played once automatically, then transitions to the `@idle_a` loop.

### Skin not applied to sleeping clone

1. Verify `Config.PlayerSkinsColumn` matches your `playerskins` table column (`citizenid` or `charid`)
2. Confirm illenium-appearance is installed and started before `rde_sleep`
3. Enable `Config.Debug = true` — check for `Skin via illenium-appearance` or `Skin applied manually` in console
4. If using manual fallback: confirm your skin JSON uses the illenium-appearance format

### Clone spawns at wrong position after being carried

The `characters` table is updated on every carry-drop via `rde_sleepmod:updatePosition`. If the position is still wrong on reconnect, check that oxmysql is running and the `UPDATE characters` query has write permissions.

### `attempt to index a nil value` on startup

Confirm `ox_core` and `ox_lib` are started before `rde_sleep` in `server.cfg`.

---

## 📚 Tech Stack

```
ox_core              → Player & group management, statebags
ox_lib               → Callbacks, notifications, progress bars, TextUI
ox_inventory         → Stash system, item management
ox_target            → World interaction zones on sleeping clones
oxmysql              → Async database (auto-create tables)
illenium-appearance  → Ped skin restore (optional, with manual fallback)
GlobalState          → Client-side sync for sleeping player list
```

---

## 📋 Changelog

### v1.3.2
- **FIX** Sleeping clone stands upright after server restart — post-skin delay increased from 500ms to 1000ms. illenium-appearance clears ped tasks asynchronously; 500ms was a race condition on restart. Added animation verification: if `IsEntityPlayingAnim` returns false after Phase 2, `TaskPlayAnim` retries once.

### v1.3.1
- **FIX** Stash item duplication on resource restart — `activeStashes` is in-memory only and gets wiped on restart. ox_inventory persists stash contents in DB, so snapshot items were added on top of existing items on next access. `RegisterStash` now checks `GetInventory` first and only populates from snapshot if the stash is genuinely empty.

### v1.3.0
- **FIX** `@base` animation clips removed from `Config.SleepingAnimations` — they caused an idle-twitch loop when played with flag `1`. Config now accepts `@idle_a` entries only.
- **FIX** Two-phase animation in `SpawnSleepingPed`: `@base` intro played once (ped lies down), then transitions to `@idle_a` loop (ped sleeps). Carry-drop goes straight to `@idle_a` (ped already horizontal).
- **DOCS** `Wait(0)` in carry detection thread documented as intentional Standards exception (required for `IsControlJustPressed` frame-accuracy).

### v1.2.9
- Proximity loop stability improvements
- skinApplyDelay / animApplyDelay tuning

### v1.2.x
- ox_core migration (ESX removed)
- GlobalState statebag sync
- Carry + robbery system
- illenium-appearance skin support
- Auto-save thread
- Full DB persistence

---

## 🤝 Contributing

PRs welcome.

1. **Fork** the repository
2. **Branch**: `git checkout -b fix/your-fix`
3. **Test** on a live server before submitting
4. **Commit**: follow existing format — `🐛 fix(scope): description`
5. **Open** a Pull Request with a clear description

**Guidelines:**

- ✅ Keep the RDE header in all files
- ✅ Follow ox_core / ox_lib / StateBag patterns — no polling where statebags exist
- ✅ `Config.SleepingAnimations` — `@idle_a` entries only. Never `@base`.
- ✅ `Wait(0)` only for per-frame control polling (`IsControlJustPressed`). Use `Wait(N≥100)` for everything else.
- ✅ Server-side validation stays — stash dedup, admin checks, input validation
- ❌ No telemetry, no paywalls, no ESX/QBCore
- ❌ Don't hardcode user-facing strings — use `GetLanguageString('key')` and add the key to both locale tables in `config.lua`

---

## ⚡ Related Projects

| Resource | Description |
|----------|-------------|
| [rde_aipd](https://github.com/RedDragonElite/rde_aipd) | Next-Gen AI Police & Crime System — ox_core native, StateBag-Synced |
| [rde_nostr_log](https://github.com/RedDragonElite/rde_nostr_log) | Decentralized FiveM logging via Nostr — replace Discord forever |
| [awesome-ox-rde](https://github.com/RedDragonElite/awesome-ox-rde) | Curated list of the best ox_core resources |

---

## 📜 License

**RDE Black Flag Source License v6.66**

```
###################################################################################
#                                                                                 #
#      .:: RED DRAGON ELITE (RDE)  -  BLACK FLAG SOURCE LICENSE v6.66 ::.         #
#                                                                                 #
#   PROJECT:    RDE_SLEEP (NEXT-GEN OFFLINE SLEEP SYSTEM FOR FIVEM OX_CORE)       #
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
#      If I find this script on any paid store, Patreon, or "Premium Pack":       #
#      > I will DMCA your store into oblivion.                                    #
#      > I will publicly shame your community on Nostr. Permanently.              #
#      > I hope every sleeping ped spawns directly inside your player model.      #
#      SELLING FREE WORK IS THEFT. AND I AM THE JUDGE.                            #
#                                                                                 #
#   3. // THE CREDIT OATH                                                         #
#      Keep this header. If you remove my name, you admit you have no skill.      #
#      You can add "Edited by [YourName]", but never erase the original creator.  #
#      Don't be a skid. Respect the architecture.                                 #
#                                                                                 #
#   4. // THE CURSE OF THE COPY-PASTE                                             #
#      This code implements real StateBag sync, server-side authority,            #
#      async MySQL, proximity loading, and skin persistence.                      #
#      If you copy-paste without understanding, you WILL break something.         #
#      Don't come crying to my DMs. RTFM.                                         #
#                                                                                 #
#   --------------------------------------------------------------------------    #
#   "We build the future on the graves of paid resources."                        #
#   "REJECT MODERN MEDIOCRITY. EMBRACE RDE SUPERIORITY."                          #
#   --------------------------------------------------------------------------    #
###################################################################################
```

**TL;DR:**
- ✅ **Free forever** — use it, edit it, learn from it
- ✅ **Keep the header** — credit where it's due
- ❌ **Don't sell it** — commercial use = instant DMCA + public shaming on Nostr
- ❌ **Don't be a skid** — copy-paste without reading will break things

---

## 🌐 Community & Support

| | |
|---|---|
| 🌍 **Website** | [rd-elite.com](https://rd-elite.com) |
| 🔭 **Nostr Terminal** | [rd-elite.com/Files/NOSTR/Terminal](https://rd-elite.com/Files/NOSTR/Terminal/) |
| 🐙 **GitHub** | [github.com/RedDragonElite](https://github.com/RedDragonElite) |
| 🟣 **Nostr** | `npub1wr4e24zn6zzjqx8kvnelfvktf0pu6l2gx4gvw06zead2eqyn23sq9tsd94` |

**Before opening an issue:**
- ✅ Read this README fully
- ✅ Check the [Troubleshooting](#-troubleshooting) section
- ✅ Enable `Config.Debug = true` and include console output
- ❌ Don't open issues without logs — we can't help without them

---

**Made with 🔥 and zero tolerance for paid garbage by [Red Dragon Elite](https://rd-elite.com)**

*The future is ours. We are already inside.*

**REJECT MODERN MEDIOCRITY. EMBRACE RDE SUPERIORITY.**

**RDE FOREVER. SYSTEM FAILURE. ⚡777⚡**

[![Website](https://img.shields.io/badge/Website-Visit-red?style=for-the-badge&logo=google-chrome)](https://rd-elite.com)
[![Nostr](https://img.shields.io/badge/Nostr-Follow-purple?style=for-the-badge&logo=rss)](https://primal.net/p/npub1wr4e24zn6zzjqx8kvnelfvktf0pu6l2gx4gvw06zead2eqyn23sq9tsd94)
[![Terminal](https://img.shields.io/badge/Terminal-Live-green?style=for-the-badge&logo=gnome-terminal)](https://rd-elite.com/Files/NOSTR/)
