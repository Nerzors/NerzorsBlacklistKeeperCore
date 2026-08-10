# What's new? (Last 3 Changes/Updates)


## c2.0.0-dev.0.45.0 (by Veplo)
### New
- NBK now appears in the game's settings. Options > AddOns has an NBK entry with a button that opens the addon's settings - where you'd look first for any addon.

### Fixed
- small other thinks

## c2.0.0-dev.0.44.0 - Fixes

### Fixed
- **"What's new?" showed English on German clients.** The language wasn't detected correctly; localised text now displays properly.
- **Login error** about the ignore list (`unknown event`). The ignore-list integration now loads cleanly.

### Changed
- **List column headers.** In the Blacklist, Remember Me and Recents tabs the class column (as an icon) was too narrow for the word "Class", and "Note" was truncated to "N...". Those columns now show an icon instead of clipped text, with the full name in a hover tooltip.
- **"Saved messages" window.** Long messages were cut off - they now wrap across multiple lines so the whole text is visible.

## c2.0.0-dev.0.43.0 (by Veplo)

### New
- **Ignore-list integration.** Optionally, blacklisted players you mute get ignored by the game as well - no chat, no whispers, no invites from them. **Off** by default; turn it on under Settings → Notifications.
- **Import from your ignore list.** Already ignoring people? Pull them onto the blacklist in one go - you pick who before anything happens.
- Removing someone from the blacklist lifts the ignore again, but only if the addon set it. Players you ignored by hand are never touched.

### Changed
- **"What's new?" rebuilt.** Every version is its own card you can fold open and shut. Anything you haven't read yet starts open, so skipping a few updates gives you all of them at a glance instead of an endless stack.
- **Entries show which module they belong to.** Changes to an optional module are labelled with its name - and if you don't have that module installed, the entry doesn't show up at all.

### Fixed
- **The minimap tooltip listed "Tooltip" as an active module**, even though it has been part of the main addon since 0.39.0.
- **"Statistics" was missing** from that same list when installed.