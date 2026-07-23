<div align="center">
<img src="https://media.nerzors.de/addons/nbk/nbk-banner_og_920x360.jpg" alt="Nerzors Blacklist Keeper Banner"/>

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

</div>

<br/>

> *"Trust is earned in dungeons and lost in one bad behavior."*

**Nerzors Blacklist Keeper (NBK)** is a modular addon for World of Warcraft that helps you keep track of players you do, or do not -> want to play with again.

Maintain your personal blacklist with reasons, notes, mute flags and class information. Get alerts when blacklisted players appear in your group, group finder or chat.

NBK also includes a positive **Remember Me** list for trusted players, recent party tracking and optional post-run rating prompts. Think of it as your own personal Codex of Allies and Adversaries, minus the Light's judgment, plus a mute button.

---

## Development Status

> [!IMPORTANT]
> **Classic support is here.** One download now covers **Retail, Classic Era
> and Classic MoP** - the right version is picked automatically by your
> client, no separate package needed.

> [!IMPORTANT]
> With Updated `2.0.0-dev.0.39.0`: The `Tooltip` sub-addon is gone. Its functionality is now part of the main addon. You no longer need to install `NerzorsBlacklistKeeper_Tooltip` and can delete the old folder.

> NBK V2 is currently in active development.

Version 2 is a full rebuild of the original addon with a modular architecture.
NBK V1 is retired and will no longer receive updates. *Rest in peace, V1 you served your purpose, like a good DK Ghoul.*

---

## ADDON - Core Information

| Property | Value |
|----------|-------|
| Author | Nerzors |
| Co-Author | Veplo (Discord: Veplo) |
| Language | English / Deutsch |
| Game Version | WoW Retail, Classic Era, Classic MoP |
| Current Branch | 2.0 Development (2.0.0-dev.0.42.0) |

---

## Features

| Module | Description |
|--------|-------------|
| Blacklist | Store players with reasons, notes, pins and mute flags |
| Group Warning | Alerts when blacklisted players join your group |
| Tooltip | Shows blacklist info in tooltips |
| Chat Filter | Hide blacklisted players and blocked words |
| Message History | Message from muted blacklisted players is no longer lost |
| Group Finder | Detect blacklisted players in LFG |
| Recents | Track recent party members |
| Remember Me | Positive player list with ratings |
| Sync | Share and sync entries with trusted players |

> In the **Core-Only** edition you get *Blacklist*, *Group Warning* and
> *Tooltip*. Everything below that line lives in the optional modules and
> ships with the
> [All-in-One edition](https://github.com/Nerzors/NerzorsBlacklistKeeper).

---

## Installation (Manual)

Install folders into:

```txt
World of Warcraft/_retail_/Interface/AddOns/        (Retail)
World of Warcraft/_classic_era_/Interface/AddOns/   (Classic Era)
World of Warcraft/_classic_/Interface/AddOns/       (Classic MoP)
```

The Core-Only edition is exactly two folders - both required:

```txt
NerzorsBlacklistKeeper_Data
NerzorsBlacklistKeeper
```

Want the optional modules on top? Grab the
[All-in-One edition](https://github.com/Nerzors/NerzorsBlacklistKeeper)
instead - it contains these two plus every module.

---

## Modules

This edition ships only what's needed to run:

| Folder | Required | Purpose |
|--------|----------|---------|
| `_Data` | Yes | Shared assets and libraries |
| `Core` | Yes | Main addon functionality |

The optional modules below are **not** part of the Core-Only edition. They
come with the [All-in-One edition](https://github.com/Nerzors/NerzorsBlacklistKeeper):

| Folder | Purpose |
|--------|---------|
| `_ChatFilters` | Chat filtering + Message History |
| `_GroupFinder` | LFG warnings *(Retail only)* |
| `_Sync` | Sharing & sync |
| `_Recents` | Recent player tracking |
| `_RememberMe` | Positive player list *(Retail only)* |

> **Want the full package?** Switch to the
> **[All-in-One edition](https://github.com/Nerzors/NerzorsBlacklistKeeper)** -
> same core, plus every optional module. Your saved blacklist carries over.

---

## External Modules

Add-ons by others:

| Module | Author | Purpose |
|--------|--------|---------|
| [tRP3_NBK](https://github.com/Nerzors/tRP3_NBK) | Veplo | Total RP 3 integration - surfaces blacklist status inside TRP3 profiles |

---

## Slash Commands

| Command | Action |
|---------|--------|
| `/nbk` | Open main window |
| `/nbk config` | Open settings |
| `/nbk add name` | Add player |
| `/nbk remove name` | Remove player |
| `/nbk check name` | Check player |
| `/nbk list` | Print blacklist |
| `/nbk news` | Open news window |

Alias:

```txt
/blacklistkeeper
```

---

## Sharing & Auto-Sync

> [!NOTE]
> Sharing lives in the optional `_Sync` module, which is **not** part of the
> Core-Only edition. Install the
> [All-in-One edition](https://github.com/Nerzors/NerzorsBlacklistKeeper)
> to use it. Documented here so you know what you'd be getting.

NBK supports peer-to-peer sharing through WoW's addon communication.

You control:

- Who can send entries
- Who receives sync data
- Which entries are shareable

Auto-Sync can instantly share newly added blacklist entries with:

- Your Guild
- Friends
- Custom player lists

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
| 🐛 Issues | [GitHub Issues](https://github.com/Nerzors/NerzorsBlacklistKeeperCore/issues) |
| 📬 Addon Mail | [nbk.addon@nerzors.de](mailto:nbk.addon@nerzors.de) |
| ✉️ General Contact | [dev@nerzors.de](mailto:dev@nerzors.de) |

<div align="center">
<sub>Created with 🩸&♥️ by Nerzors | because someone has to remember who pulled without asking.</sub>
</div>
