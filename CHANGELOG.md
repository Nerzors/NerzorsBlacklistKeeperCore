# What's new? (Last 3 Changes/Updates)


## 2.1.0 - Ignore-Manager + WoW: Forever
> Nerzors & Veplo

> [!CAUTION]
> **WoW: Forever - names saved the wrong way before 2.1.0.**
> Up to 2.0.0, players added through the target, the context
> menu or the group were saved with their second name as the realm
> ("First-Second" instead of "First Second"). The tooltip and the group
> warning didn't recognize them, and the same player could be on your
> blacklist twice. 2.1.0 fixes this once: at login a window explains it,
> lists every affected entry and offers to export your blacklist first,
> nothing changes until you click "Switch now".

### New
- **Ignore Manager** (new module, full download only). The "All characters"
  view in the "Ignore list" tab shows the ignore lists of all your characters
  side by side - who is ignored where, and how up to date each character's
  list is. Log in once on each character so the overview is complete.
- **Change other characters' lists without logging over.** Click a field to
  ignore or remove a player there. The change waits for that character's
  next login - NBK asks first, or runs it right away if you switch that on
  under "Notifications". *(Ignore Manager)*
- **"Ignore everywhere" and "Remove everywhere".** Tick players and change
  them on all your characters at once - right away on this one, at the next
  login on the others. *(Ignore Manager)*
- **Characters that no longer exist** are greyed out on characters that
  haven't logged in since. "Clean up" takes them out of the overview - and
  off your blacklist, if you like. *(Ignore Manager)*
- **Names on WoW: Forever.** Names read "First Second" everywhere, without
  the long server ID behind them. The realm column, the "name and realm in
  one column" setting and the "Top realms" card are gone there, and the
  search no longer matches the server ID.
- **Both names in slash commands on Forever:** `/nbk add First Second
  reason`. Texts that talked about realms are worded for Forever.
- **Export only what you ticked.** "Export..." in the blacklist's selection
  bar exports just the selected players.
- **Quoted names** work in slash commands on every client:
  `/nbk add "Name" reason`.
- **Outdated sub-addons.** If old NBK sub-addons (Tooltip, Nameplates) are
  still enabled, NBK tells you at login and can disable them for you.
- **Retail-only modules off elsewhere.** Group Finder and Remember Me only
  work on Retail; on other clients NBK switches them off once, so the AddOn
  list no longer shows them as enabled.

### Changed
- **Built-in reasons in your language.** "Toxic", "Quitter" and the other
  built-in reasons now show translated - for the entries you already have and
  for lists others share with you, too.
- **Pinned entries in the remove dialog.** The "Ignore list" tab says how many
  pinned entries would leave the blacklist too.
- **All tabs fit.** The main window is a little wider at its smallest, so all
  tabs fit in every language. The blacklist's selection bar no longer has a
  "Cancel" button - "Done" does the same - and its buttons don't overlap with
  longer translations any more.
- **Clearer hover frames** on buttons in the Nerzors and Midnight themes.

### Fixed
- **One player, not two (Forever).** A player picked from the target, the
  group or a tooltip and the same player from the ignore list or chat were
  stored as two different players. They are one now. Entries saved the old
  way are switched once: a window explains it first, lists every entry and
  lets you export your blacklist before.
- **Ignore list spelling.** Removing a player from the ignore list could
  silently miss them when the game spelled the name differently (for example
  in lower case).
- **"Import to NBK"** in the "Ignore list" tab: the player now shows up in
  the blacklist right away.
- **Cut-off tooltips.** Longer tooltips that wrap onto several lines were cut
  off after the first line.
- **Statistics month names** now follow your game language.
- **Chat filter whitelist hint** was always in English.