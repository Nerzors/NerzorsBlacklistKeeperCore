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

-- Minor 7 (NBK 2.3.0): optional theme `skin` - texture frames (Core/Skin.lua).
-- Minor 8 (NBK 2.4.0): NUL:Confirm takes an optional third button
-- (extraLabel / onExtra).
-- Minor 9 (NBK 2.4.0 D1): NUL:Confirm is the library's own window (theme,
-- scale) instead of a StaticPopup; NUL:SetConfirmDefaults.
-- Minor 10 (NBK 2.5.0 Z4): NUL:Confirm takes an optional checkbox
-- (checkLabel / checked); the answer callbacks get its state.
local MAJOR, MINOR = "NerzorsUILib-1.0", 10
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

-- ─── Scale ─────────────────────────────────────────────────────────────
-- One factor for everything the lib puts on screen. Windows register
-- themselves (Widgets/Window.lua) and keep their place when it changes;
-- helpers that live on UIParent instead of inside a window - the tooltip,
-- dropdown popups - follow through NUL:_FollowScale. The host persists the
-- value and calls NUL:SetScale once its settings are loaded.

NUL.MIN_SCALE = 0.5
NUL.MAX_SCALE = 2

NUL._scale    = NUL._scale    or 1
NUL._windows  = NUL._windows  or setmetatable({}, { __mode = "k" })
NUL._floaters = NUL._floaters or setmetatable({}, { __mode = "k" })

function NUL:GetScale() return self._scale end

function NUL:_FollowScale(frame)
    if not frame then return frame end
    self._floaters[frame] = true
    frame:SetScale(self._scale)
    return frame
end

function NUL:SetScale(scale)
    scale = tonumber(scale) or 1
    if scale < self.MIN_SCALE then scale = self.MIN_SCALE end
    if scale > self.MAX_SCALE then scale = self.MAX_SCALE end
    self._scale = scale
    for w in pairs(self._windows) do
        local ok, err = pcall(w._applyScale, w, scale)
        if not ok then print("|cffff5555NerzorsUILib scale error:|r", tostring(err)) end
    end
    for f in pairs(self._floaters) do f:SetScale(scale) end
end

-- Migration hook for future MINOR bumps. Currently a no-op.
if oldMinor then
    -- Reserved for upgrade-in-place behavior between minors.
end
