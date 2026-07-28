# What's new?

## 2.0.0-dev.0.44.0 - Fixes

### Fixed
- **"What's new?" showed English on German clients.** The language wasn't detected correctly; localised text now displays properly.
- **Login error** about the ignore list (`unknown event`). The ignore-list integration now loads cleanly.

### Changed
- **List column headers.** In the Blacklist, Remember Me and Recents tabs the class column (as an icon) was too narrow for the word "Class", and "Note" was truncated to "N...". Those columns now show an icon instead of clipped text, with the full name in a hover tooltip.
- **"Saved messages" window.** Long messages were cut off - they now wrap across multiple lines so the whole text is visible.