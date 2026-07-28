# What's new?

## 2.0.0-dev.0.43.0 - Ignore list + a rebuilt "What's new?"

### New
- **Ignore-list integration.** Optionally, blacklisted players you mute get
  ignored by the game as well - no chat, no whispers, no invites from them.
  **Off** by default; turn it on under Settings → Notifications.
- **Import from your ignore list.** Already ignoring people? Pull them onto
  the blacklist in one go - you pick who before anything happens.
- Removing someone from the blacklist lifts the ignore again, but only if
  the addon set it. Players you ignored by hand are never touched.

### Changed
- **"What's new?" rebuilt.** Every version is its own card you can fold open
  and shut. Anything you haven't read yet starts open, so skipping a few
  updates gives you all of them at a glance instead of an endless stack.
- **Entries show which module they belong to.** Changes to an optional
  module are labelled with its name - and if you don't have that module
  installed, the entry doesn't show up at all.

### Fixed
- **The minimap tooltip listed "Tooltip" as an active module**, even though
  it has been part of the main addon since 0.39.0.
- **"Statistics" was missing** from that same list when installed.

---

## 2.0.0-dev.0.42.0 - Statistics dashboard

### New
- **Statistics tab.** Charts over your own blacklist: entries per month,
  top reasons and zones, class spread, the players you run into most, and
  what the chat filters have spared you. Hover any bar for the exact number.
  It's built entirely from data the addon already collected, so it's
  meaningful from the very first login instead of starting at zero.

### Fixed
- **Lua error from Message History in dungeons/raids during combat**
  (`attempt to compare local 'text' a secret string value`). Chat text is
  protected inside instances now; the history no longer trips over it.
- **Dropdowns were missing their arrow**, so they didn't read as dropdowns.

---

## 2.0.0-dev.0.41.0 - UI polish + Classic cleanup

### Changed
- **Themed scrollbars everywhere.** The settings, import/export and
  "What's new?" windows now use the same slim scrollbar as the lists -
  no more chunky default Blizzard one.
- **Dropdowns now show an arrow** so they read as select fields.
- **Flat icon buttons** in the list rows (and the window's settings/close
  buttons) - no more little boxes around them.
- **Tooltips in the addon's style** instead of the Blizzard look. The note
  tooltip shows the full note text again.
- **Minimap tooltip** lists only the modules you actually have installed -
  inactive/unavailable ones are no longer shown greyed out.

### Fixed
- **Classic:** the Group Finder and Remember Me modules (which don't exist
  on Classic) no longer show up or load there.

---

## 2.0.0-dev.0.40.0 - Message history + UI polish

### New
- **Message History.** Chat from muted blacklisted players is no longer
  lost. It's saved and viewable in the new **"Message history"** tab: a
  list of players, and clicking one opens a detail window with **every
  message and where it was said** (whisper, party, raid, trade, …).
- **Automatic retention.** Messages are kept for a configurable time
  (default **30 days**); older ones are cleaned up automatically on
  login. Time span, on/off and "Clear all" live in the Chat filters
  settings.

### Changed
- **Themed scrollbars.** The chunky default Blizzard scrollbar is
  replaced by a slim accent-coloured thumb with clean arrow icons, in
  line with the rest of the design.

### Fixed
- **Footer was pushed to the right** instead of centered ("Created by …").

### Note
- Message history only archives what's **actually hidden**. Turn on
  "Hide chat messages from blacklisted players" (Notifications) so muted
  players' chat disappears from chat - and lands in history.

---

## 2.0.0-dev.0.38.2 - Tooltip in Core + realm taint fix

### Changed  
- **The "Tooltip" sub-addon is gone.** Its functionality is now part of the main addon - you no longer need to install `NerzorsBlacklistKeeper_Tooltip` and can delete the old folder.  
  
### New  
- **Per-row tooltip toggles.** You can now individually toggle which pieces of info show up in the tooltip: reason, notes, zone, encounter history, mute marker, pin marker.  
  
### Fixed  
- **Lua error in dungeons and raids** when hovering players (`attemptto compare local 'realm' a secret string value`).  

---


Short, player-focused summary of what changed. For the gritty
developer-level details (code paths, function names, protocol jargon),
see `changelog.md`.

---

## 2.0.0-dev.0.37.3 - "What's New?" + M+ fix

### New
- **"What's new?" window.** Auto-opens **once** after every update,
  the moment you open the main window (minimap icon / `/nbk`). Lists
  every change since your last login.
- **`/nbk news`** to reopen it any time.

### Fixed
- **Mythic+ "Remember player?" popup opened at the start of a run**
  (when the keystone was inserted) instead of at the end. The popup
  now waits for a real run (at least 30 seconds of elapsed time)
  before showing up.

---

## 2.0.0-dev.0.37.2 - UI polish

### New
- **Brand logo on the main window.** The logo is now freely positioned
  on the window and can overhang the frame edge (like a sticker peeking
  past the corner). Size and offset can be fine-tuned per theme.
- **New centered footer with quick links.** The credits line at the
  bottom of the main window is now **centered** and includes small icons
  for
  - Website (nerzors.de)
  - Discord
  - GitHub
  - Ko-fi

  Clicking an icon opens a small window with the URL ready to copy
  (WoW doesn't allow direct external links). Each line and each icon can
  be **individually toggled** in the Display settings - hide what you
  don't need.

### Fixed
- The logo used to sit *behind* the window title and was barely visible
  - it now renders on top correctly.

---

## 2.0.0-dev.0.37.1 - Auto-Sync polish

### New
- **Prettier "entry was shared with you" popup.** When someone Auto-
  Syncs a blacklist entry to you, you now see a clean card with a
  coloured accent stripe, the player name in class color, sender,
  reason - and the **note**, if one was included.

### Fixed
- **"Share this entry" was being ignored by Auto-Sync.** If you
  unchecked the box in the Add dialog, the entry was still being sent.
  The entry is now only auto-shared if the checkbox really is active
  by the time the dialog closes.

---

## 2.0.0-dev.0.37.0 - Auto-Sync

### New
- **Auto-Sync - share entries automatically.** A big new toggle in the
  Sharing tab: when on, every new blacklist entry (if marked
  "shareable") goes out to the chosen recipients immediately. You no
  longer have to manually click "Send to guild" each time.
  - **Pick your audience:** your guild, all online friends on your
    realm, or a **custom list** of specific names.
  - The recipient sees a small confirm popup instead of the full
    import overview - accept or decline with one click.
- **Sync now supports more than just the blacklist.** You can now also
  share your **Remember-Me** list.

### Fixed
- **Mythic+ tooltip error.** If you moused over a player during dungeon
  combat, you'd occasionally get a Lua error from Blizzard's protected-
  data system. The tooltip hook now bows out gracefully in that
  situation (a brief moment of no blacklist info is better than an
  error).
- Sync-received import strings sometimes wouldn't parse ("unknown list
  type"). Parsing is fixed.

---

## 2.0.0-dev.0.35.0 - Multi-list export/import

### New
- **Export/import handles multiple lists.** Both the **blacklist** and
  the **Remember-Me** list are exportable now. Pick the list in the
  Export dialog; on Import the list type is auto-detected from the
  string.
- Old export strings (blacklist-only) still import fine.

### Fixed
- "Share this entry" sometimes turned itself off in the Add dialog.

---

## 2.0.0-dev.0.34.0 - Public API for other addons

### New
- **Public read-API for third-party addons.** WeakAuras, Plater scripts
  or your own mini-addons can now cleanly query whether a player is on
  your blacklist / Remember-Me list - and react to changes - without
  reaching into the internal data.
- If you don't script anything yourself you won't notice this directly,
  but tools other people make can now integrate properly.

---

## 2.0.0-dev.0.33.8 - UX polish

### Fixed
- All settings tabs now have correct icons.
- **Preset reasons** tab used to overflow its frame with many entries;
  the list now scrolls cleanly inside its own area.
- **Chat filter** edit fields sometimes overlapped their labels. The
  "Blocked words" / "Whitelist" lists are now tidied up and changes
  take effect **immediately** (no Save button anymore).
- **Sound preview button** in the Notifications tab showed an empty
  box - now a proper "▶".
- **Star symbols (★)** in the Remember-Me tab occasionally rendered as
  boxes. Now a proper star everywhere.

---

## 2.0.0-dev.0.33.7 - Mythic+ end-of-run dialog fixed

### Fixed
- **The "Remember player?" popup after a Mythic+ run** never opened.
  It works again now - both after a **completed** run and after an
  **abandoned** run. **Inserting the keystone** correctly does **not**
  trigger a popup.

---

## 2.0.0-dev.0.33.5 - Sync works again

### Fixed
- **"Sync isn't working"** - the worst bug of the bunch: receiving
  shared entries was completely broken because an initialisation step
  was being skipped. Sending and receiving both work reliably again.

### New
- **Very long entries no longer get dropped.** Previously, entries with
  an unusually long reason text were silently discarded on send. They
  are now automatically split into multiple packets and reassembled on
  the receiver's side.

---

## 2.0.0-dev.0.33.0 - Longer note fields

### New
- **Note fields are multi-line now** and hold up to 1000 characters.
  Previously a single line, 500 chars max. Applies to the Blacklist
  Add/Edit dialog and Remember-Me.

### Fixed
- In multi-line text fields only the first line was clickable - the
  cursor wouldn't jump to lower lines. Clicking anywhere in the field
  now focuses it correctly. Applies to all note/reason fields,
  Import/Export and the chat-filter word lists.

---

## 2.0.0-dev.0.32.5 - Three themes

### New
- **Three built-in themes** selectable in the Display settings:
  - **Nerzors** (default) - muted dark blue with cyan accent
  - **Midnight** - same palette with a magenta accent
  - **Sci-Fi** - gradient backdrop and glowing magenta accents
  Switching is live, no reload required. Your choice is remembered.

---

## 2.0.0-dev.0.30.0 - The 3.0 reset

Big plumbing rebuild. Mostly invisible to players, but:

- **Shared data addon** (`NerzorsBlacklistKeeper_Data`) bundles
  textures, fonts and sounds. If this addon isn't active, the main
  addon warns you on login - please keep it enabled.
- **Custom UI library** under the hood - windows look more consistent
  and all sub-addons (Sync, Recents, RememberMe, Nameplates, Tooltip,
  ChatFilters, GroupFinder) feel like one cohesive whole.
