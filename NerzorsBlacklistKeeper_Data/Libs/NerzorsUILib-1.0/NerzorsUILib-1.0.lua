-- NerzorsUILib-1.0
-- A small, themeable widget library for World of Warcraft addons.
-- Author: Nerzors
--
-- Design goals:
--   * Table-options API (no positional-arg fragility):
--       NUL:Button(parent, { label = "OK", style = "accent", onClick = fn })
--   * Centralized theme system with hot-swap and per-widget repaint callbacks.
--   * Dynamic-width-aware widgets: width = "fill" / "auto" / <number>.
--   * Multiline EditBox built in.
--   * No external runtime dependencies beyond LibStub.
--
-- Lib object layout:
--   NUL.themes       table  name -> theme spec       (Core/Theme.lua)
--   NUL._activeName  string                          (Core/Theme.lua)
--   NUL._widgets     table  weak-keyed live widgets  (this file)
--   NUL:<Widget>(...)       widget constructors      (Widgets/*.lua)

local MAJOR, MINOR = "NerzorsUILib-1.0", 1
local NUL, oldMinor = LibStub:NewLibrary(MAJOR, MINOR)
if not NUL then return end -- already loaded at this or higher minor

-- Library version constants (read-only for consumers).
NUL.MAJOR_VERSION = MAJOR
NUL.MINOR_VERSION = MINOR

-- Theme registry (filled by Core/Theme.lua). Keep tables non-nil so
-- consumers can read NUL.themes before Theme.lua runs without crashing
-- (load order is XML-driven and stable, but defensive cheap).
NUL.themes      = NUL.themes      or {}
NUL._activeName = NUL._activeName or nil

-- Live-widget registry. Each widget that wants to react to a theme swap
-- defines `widget._repaint(self, theme)` and is added here via
-- NUL:_Track(widget). Weak keys let frames be GC'd with their parent.
NUL._widgets = NUL._widgets or setmetatable({}, { __mode = "k" })

function NUL:_Track(widget)
    if not widget or type(widget._repaint) ~= "function" then return widget end
    self._widgets[widget] = true
    return widget
end

-- Repaint every tracked widget with the current theme. Called by
-- SetTheme (Core/Theme.lua) after switching the active spec.
function NUL:_RepaintAll()
    local theme = self:GetTheme()
    for w in pairs(self._widgets) do
        local ok, err = pcall(w._repaint, w, theme)
        if not ok then
            -- Don't let one bad widget block the rest of the repaint pass.
            -- Print so users notice in dev; silent failure would mask bugs.
            print("|cffff5555NerzorsUILib repaint error:|r", tostring(err))
        end
    end
end

-- Migration hook for future MINOR bumps. Currently a no-op.
if oldMinor then
    -- Reserved for upgrade-in-place behavior between minors.
end
