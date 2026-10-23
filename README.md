<div align="center">
<img src="https://media.nerzors.de/addons/nbk/nbk_logo.v2.png" alt="Nerzors Blacklist Keeper Banner"/>

<h1><img src="https://media.nerzors.de/addons/nbk/nbkAddon_Midnight.final-v3.png" width="32" alt="Nerzors Blacklist Keeper Logo"/> Nerzors Blacklist Keeper <sup>Core</sup></h1>

<p><i>Remember the players you never want to group with again... and the good ones too.</i></p>

<p><b>This is the Core-Only edition</b> - just the main addon and its shared
assets, without the optional modules.<br/>
Looking for chat filters, sharing, statistics and the rest?
Get the <a href="https://github.com/Nerzors/NerzorsBlacklistKeeper"><b>All-in-One edition</b></a>.</p>

<p>
  <a href="https://www.curseforge.com/wow/addons/nerzorsblacklistkeepercore">
    <img src="https://img.shields.io/badge/CurseForge-1B1F2B?style=for-the-badge&logo=curseforge&logoColor=e04e14&labelColor=1B1F2B" alt="CurseForge"/>
  </a>
  <a href="https://www.curseforge.com/wow/addons/nerzorsblacklistkeepercore">
    <img src="https://img.shields.io/badge/WoWUp-1B1F2B?style=for-the-badge&logoColor=A87CE8&labelColor=1B1F2B" alt="WoWUp"/>
  </a>
  <a href="https://addons.wago.io/addons/nerzorsblacklistkeepercore">
    <img src="https://img.shields.io/badge/Wago.io-1B1F2B?style=for-the-badge&logoColor=A87CE8&labelColor=1B1F2B" alt="Wago.io"/>
  </a>
</p>

<p>
  <img src="https://cf.way2muchnoise.eu/1553125.svg?gameVersionTypeId=517" alt="CurseForge Downloads"/>
  <img src="https://img.shields.io/github/v/release/Nerzors/NerzorsBlacklistKeeperCore?style=flat-square&color=252669&labelColor=1B1F2B" alt="Latest Release"/>
  <img src="https://img.shields.io/github/last-commit/Nerzors/NerzorsBlacklistKeeperCore?style=flat-square&color=A87CE8&labelColor=1B1F2B" alt="Last Commit"/>
  <img src="https://img.shields.io/github/issues/Nerzors/NerzorsBlacklistKeeperCore?style=flat-square&color=252669&labelColor=1B1F2B" alt="Open Issues"/>
  <img src="https://img.shields.io/github/stars/Nerzors/NerzorsBlacklistKeeperCore?style=flat-square&color=A87CE8&labelColor=1B1F2B" alt="Stars"/>
</p>

[Install](#installation) &nbsp;|&nbsp; [Features](#features) &nbsp;|&nbsp; [Modules](#modules) &nbsp;|&nbsp; [Commands](#slash-commands) &nbsp;|&nbsp; [Changelog](https://github.com/Nerzors/NerzorsBlacklistKeeper/blob/HEAD/CHANGELOG.md)

</div>

> *"Trust is earned in dungeons and lost in one bad behavior."*

**Nerzors Blacklist Keeper (NBK)** is a modular addon for World of Warcraft that helps you keep track of players you do, or do not -> want to play with again.

Maintain your personal blacklist with reasons, notes, mute flags and class information. Get alerts when blacklisted players appear in your group, group finder or chat.

NBK also includes a positive **Remember Me** list for trusted players, recent party tracking and optional post-run rating prompts. Think of it as your own personal Codex of Allies and Adversaries, minus the Light's judgment, plus a mute button.

---

> [!IMPORTANT]
> **Forever support is here.** One download now covers **Retail, Classic Era, Classic MoP
> and WoW Forever**, the right version is picked automatically by your client, no separate package needed.
> Two modules stay Retail-only because the game systems behind them don't
> exist on Classic: `_GroupFinder` and `_RememberMe`. On Classic they simply don't show up in your AddOns list.

| Property | Value |
|----------|-------|
| Author | Nerzors · [www.nerzors.de](https://www.nerzors.de) |
| Co-Author | Veplo (Discord: Veplo) - [Git](https://github.com/veplo-ops) - [cf](https://www.curseforge.com/members/veplo/projects) |
| Language | see [Languages](#languages) (auto-detected from your client) |
| Game Version | Retail, Classic Era, Classic MoP and WoW: Forever |
| Versioning: | semantic versioning - `2.0.1` for fixes, `2.1.0` for new features. The version is the same on every client. |

---

## Features

- **Blacklist** with reason presets, free-form notes, per-entry mute, pin,
  class detection and a sortable, searchable list window.
- **Group warning** - chat message, popup and/or sound when a blacklisted
  player joins your group.
- **Tooltip integration** - blacklist / remember-me info right in the unit tooltip.
- **Ignore list** - an "Ignore list" tab for the game's own /ignore list:
  multi-select removal (optionally from the blacklist too), one-click import
  to NBK, blacklist date/reason/note per player, an "ignored since" date, and
  a notice when the game drops a character that no longer exists. Muted
  players can optionally be added to /ignore as well.
- **Chat filter** - optionally hide messages from blacklisted players, plus a
  configurable blocked-words / whitelist filter and a message history for
  muted players.
- **Group Finder (LFG)** - warns when a blacklisted player appears in a
  Premade Group Finder listing or applies to your group.
- **Recents** - tracks the last unique party-mates you grouped with.
- **Remember Me** - a positive list with star ratings, notes and an optional
  post-Mythic+ "rate your group" prompt.
- **Sharing / Sync** - peer-to-peer blacklist + remember-me sharing over the
  addon comm channel (whisper / guild), including per-entry **Auto-Sync**.
- **Multi-list Export / Import** - export the blacklist or the remember-me
  list to a string; import auto-detects which list it is.
- **Statistics** - a dashboard with charts over your blacklist: growth, top
  reasons, zones and realms, class spread, most-encountered players, chat impact.
- **Themes** - three built-in looks (Nerzors, Midnight, Forever), switchable
  live.
- **"What's new?" window** - opens once after every update.

---

## Installation

1. Install from one of the **official sources** listed in
   [`LICENSE.md`](LICENSE.md): GitHub Releases, CurseForge or Wago.io.
2. Extract so each folder lands directly in your AddOns directory
   (`_retail_`, `_classic_era_`, `_classic_` or `_classic_beta_` for WoW: Forever -
   the same files work in all):

   ```
   World of Warcraft/_retail_/Interface/AddOns/
   ├── NerzorsBlacklistKeeper_Data        (required - shared assets + libraries)
   └── NerzorsBlacklistKeeper             (core - includes tooltip enrichment)
   ```

3. `NerzorsBlacklistKeeper_Data` is a **hard dependency** for everything else -
   keep it enabled. The other sub-addons are optional: install only the
   features you want. On Classic and WoW: Forever, the two Retail-only modules simply don't
   show up in the AddOns list.
   
Want the optional modules on top? Grab the
[All-in-One edition](https://github.com/Nerzors/NerzorsBlacklistKeeper)
instead - it contains these two plus every module.

---

## Modules

| Folder | What it adds | Required? |
| --- | --- | --- |
| `_Data` | Shared libraries, textures, fonts, sounds. | **Yes** |
| `NerzorsBlacklistKeeper` | Core: blacklist, list window, settings, slash commands, **tooltip enrichment**. | **Yes** |
| `_ChatFilters` | Hide blacklisted players' chat + blocked-words filter + message history. | Optional |
| `_GroupFinder` | LFG / Premade Group Finder warnings. *(Retail only)* | Optional |
| `_Sync` | Peer-to-peer sharing + Auto-Sync. | Optional |
| `_Recents` | Recent party-mate tracking. | Optional |
| `_RememberMe` | Positive list, star ratings, Mythic+ prompt. *(Retail only)* | Optional |
| `_Statistics` | Charts dashboard over your blacklist. | Optional |

> In the **Core-Only** edition you get *Blacklist*, *Group Warning* and
> *Tooltip*. Everything below that line lives in the optional modules and
> ships with the
> [All-in-One edition](https://github.com/Nerzors/NerzorsBlacklistKeeper).
---

## External Modules

Addons by others:

| Module | Author | Purpose |
|--------|--------|---------|
| [tRP3_NBK](https://github.com/Nerzors/tRP3_NBK) | Veplo | Total RP 3 integration - surfaces blacklist status inside TRP3 profiles |

---

## Languages

The language follows your game client automatically.

| Locale | Status |
|--------|--------|
| English (`enUS`) | Full |
| Deutsch (`deDE`) | Full |
| Italian (`itIT`) | Community review |
| French (`frFR`) | Community review |
| Portuguese (`ptBR`) | Community review |
| Spanish (Latin America) (`esMX`) | Community review |
| Spanish (Spain) (`esES`) | Community review |
| Russian (`ruRU`) | Community review |
| Other locales | Fall back to English |

*Community review* means the translation is complete but hasn't been
proofread by a native speaker yet - corrections are very welcome. The
"What's new?" release notes stay in English and German.

---

## Slash commands

| Command | Action |
| --- | --- |
| `/nbk` | Open the main window |
| `/nbk config` | Open settings |
| `/nbk add <name[-realm]> [reason]` | Add a player |
| `/nbk remove <name[-realm]>` | Remove a player |
| `/nbk check <name[-realm]>` | Check whether a player is listed |
| `/nbk list` | Print the blacklist to chat |
| `/nbk share <name[-realm]>` | Share via whisper *(requires `_Sync`)* |
| `/nbk share guild` | Broadcast to guild *(requires `_Sync`)* |
| `/nbk news` | Reopen the "What's new?" window |

`/blacklistkeeper` works as a long-form alias for `/nbk`.

---

## Sharing & Auto-Sync

> [!NOTE]
> Sharing lives in the optional `_Sync` module, which is **not** part of the
> Core-Only edition. Install the
> [All-in-One edition](https://github.com/Nerzors/NerzorsBlacklistKeeper)
> to use it. Documented here so you know what you'd be getting.

NBK supports peer-to-peer sharing through WoW's addon communication.
You control who you accept shares from (anyone / guild / friends / nobody) in the **Sharing** tab.

**Auto-Sync** (opt-in) pushes each newly blacklisted entry to your chosen
recipients - your guild, online friends on your realm, or a custom name list -
the moment you add it, as long as that entry is marked shareable.

> Note: Blizzard's anti-spam means addon whispers only reach recipients who
> are online and in a recent contact relationship (friend / guildmate /
> group / recently whispered). Guild channel is the most reliable.

---

## Embedded Libraries

-   [libstub](https://www.wowace.com/projects/libstub)
-   [callbackhandler](https://www.wowace.com/projects/callbackhandler)
-   [libdeflate](https://github.com/SafeteeWoW/LibDeflate)
-   [libsharedmedia-3.0](https://www.wowace.com/projects/libsharedmedia-3-0)

Libraries retain their original licenses.

---

## Support

| Platform | Link |
|----------|------|
| 🌐 Website | [www.nerzors.de](https://www.nerzors.de/en/) |
| 🐛 Issues | [GitHub Issues](https://github.com/Nerzors/NerzorsBlacklistKeeper/issues) |
| 📬 Addon Mail | [nbk.addon@nerzors.de](mailto:nbk.addon@nerzors.de) |
| ✉️ General Contact | [dev@nerzors.de](mailto:dev@nerzors.de) |

<div align="center">
<sub>Created with 🩸&♥️ by Nerzors & Veplo | because someone has to remember who pulled without asking.</sub>
</div>
