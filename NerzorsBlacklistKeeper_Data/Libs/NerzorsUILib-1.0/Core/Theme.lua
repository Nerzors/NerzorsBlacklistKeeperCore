-- NerzorsUILib-1.0 :: Core/Theme.lua
--
-- Theme registry with a nested, semantic schema. Inspired by - and aligned
-- with - the Nerzors-family design system (NerzorsQoL_Data Theme).
--
-- Schema:
--   colors = {
--     bg     = { base, panel, elevated, hover, active },
--     border = { subtle, accent },
--     text   = { primary, muted, disabled, inverse },
--     accent = { primary, secondary },
--     state  = { success, warning, danger, info },
--   }
--   fonts      = { regular, bold, mono, heading }     -- font file paths
--   fontSizes  = { xs, sm, md, lg, xl }
--   spacing    = { xs, sm, md, lg }                   -- design tokens
--   radius     = number                               -- corner radius hint
--   media      = { logo, edge, bg }
--   window     = {                                    -- skin-level extras
--     useGradient, gradientOrientation,
--     gradient = { start = color, ["end"] = color },
--     glow     = color,
--   }
--
-- Each color is a table { r, g, b, a } in 0..1. The `hex("#RRGGBB[AA]")`
-- helper builds those for you so theme definitions read like a design tool.
--
-- Switching themes at runtime:
--   NUL:SetTheme("Midnight")                 sets active + repaints + fires module hooks
--   /nbk theme Sci-Fi                        slash-command equivalent (host addon side)
--   NUL:RegisterThemeChangedCallback(fn)     fires (theme, name) on every swap
--
-- Path lookup:
--   NUL:GetColor("accent.primary")           -> { r, g, b, a } table
--   NUL:RGBA("accent.primary")               -> r, g, b, a (Blizzard-API friendly)

local NUL = LibStub("NerzorsUILib-1.0")

-- ─── hex() helper ───────────────────────────────────────────────────────
-- Accepts "#RRGGBB", "RRGGBB", "#RRGGBBAA", "RRGGBBAA". Returns
-- { r, g, b, a } with named fields in 0..1.
local function hex(s)
    s = tostring(s):gsub("^#", "")
    local r = tonumber(s:sub(1, 2), 16) or 0
    local g = tonumber(s:sub(3, 4), 16) or 0
    local b = tonumber(s:sub(5, 6), 16) or 0
    local a = (#s >= 8) and tonumber(s:sub(7, 8), 16) or 255
    return { r = r / 255, g = g / 255, b = b / 255, a = a / 255 }
end
NUL.hex = hex

-- ─── Common shape (generic fallbacks) ───────────────────────────────────
-- Design-token defaults filled into any theme that omits them (see
-- fillShape). These are deliberately GENERIC: the HOST ADDON supplies the
-- real palette, fonts, media and metrics with its theme definitions (see
-- NerzorsBlacklistKeeper/UI/Theme.lua). Keeping the lib free of app-specific
-- paths lets it be reused by any addon without dragging NBK assets along.

local GAME_FONT = "Fonts\\FRIZQT__.TTF"
local WHITE     = "Interface\\Buttons\\WHITE8x8"

local commonShape = {
    radius    = 4,
    spacing   = { xs = 4, sm = 8, md = 12, lg = 18 },
    fonts     = {
        regular = GAME_FONT,
        bold    = GAME_FONT,
        mono    = "Fonts\\ARIALN.TTF",
        heading = GAME_FONT,
    },
    fontSizes = { xs = 10, sm = 11, md = 12, lg = 14, xl = 18 },
    -- metrics: opinionated widget dimensions that aren't quite design tokens
    -- (a button's resting height, a title bar's pixel height) but want to
    -- be themable. Most themes won't override these.
    metrics   = {
        borderThickness = 1,
        rowHeight       = 26,
        windowPadding   = 12,  -- matches spacing.md
        titleBarHeight  = 28,
    },
    media     = { edge = WHITE, bg = WHITE },
}

-- ─── Registry + lookup ──────────────────────────────────────────────────

NUL._themes = NUL._themes or {}
NUL._themeOrder = NUL._themeOrder or {}
NUL._themeCallbacks = NUL._themeCallbacks or {}

local function fillShape(rec)
    rec.radius     = rec.radius     or commonShape.radius
    rec.spacing    = rec.spacing    or commonShape.spacing
    rec.fonts      = rec.fonts      or commonShape.fonts
    rec.fontSizes  = rec.fontSizes  or commonShape.fontSizes
    rec.metrics    = rec.metrics    or commonShape.metrics
    rec.media      = rec.media      or commonShape.media
    return rec
end

function NUL:RegisterTheme(name, themeRec)
    assert(type(name) == "string" and name ~= "", "RegisterTheme: name required")
    assert(type(themeRec) == "table", "RegisterTheme: spec must be a table")
    themeRec.name = name
    fillShape(themeRec)
    if not self._themes[name] then table.insert(self._themeOrder, name) end
    self._themes[name] = themeRec
    if not self._activeName then self._activeName = name end
    return themeRec
end

function NUL:HasTheme(name)
    return self._themes[name] ~= nil
end

function NUL:GetThemeNames()
    local out = {}
    for _, n in ipairs(self._themeOrder) do out[#out + 1] = n end
    return out
end

function NUL:GetCurrentThemeName()
    return self._activeName
end

function NUL:GetTheme(name)
    name = name or self._activeName
    return (name and self._themes[name]) or self._themes[self._themeOrder[1]]
end

-- Resolve a dotted color path ("accent.primary", "bg.panel") against the
-- current theme. Returns the color table { r, g, b, a } or nil.
function NUL:GetColor(path, themeRec)
    local t = (themeRec or self:GetTheme()).colors
    for segment in tostring(path):gmatch("[^.]+") do
        if type(t) ~= "table" then return nil end
        t = t[segment]
    end
    return t
end

-- Convenience: same as GetColor but unpacked to r, g, b, a (0..1).
-- Falls back to opaque white if the path resolves to nothing, so
-- consumers that pass a typo'd path still get visible output instead of
-- a crash.
function NUL:RGBA(path, themeRec)
    local c = self:GetColor(path, themeRec)
    if not c then return 1, 1, 1, 1 end
    return c.r or 1, c.g or 1, c.b or 1, c.a or 1
end

-- ─── Active theme + repaint ─────────────────────────────────────────────

function NUL:SetTheme(name)
    if not self:HasTheme(name) then
        return false, "unknown theme: " .. tostring(name)
    end
    self._activeName = name
    self:_RepaintAll()
    local theme = self:GetTheme()
    for _, cb in ipairs(self._themeCallbacks) do
        local ok, err = pcall(cb, theme, name)
        if not ok then print("|cffff5555NerzorsUILib theme callback error:|r", tostring(err)) end
    end
    return true
end

function NUL:RegisterThemeChangedCallback(fn)
    if type(fn) == "function" then table.insert(self._themeCallbacks, fn) end
end

-- ─── Auto-skin helpers ──────────────────────────────────────────────────
-- For frames built outside the lib's widget constructors: register them
-- once and they get a themed background + border + re-paint on swap.

NUL._skinned = NUL._skinned or setmetatable({}, { __mode = "k" })
NUL._customPainters = NUL._customPainters or setmetatable({}, { __mode = "k" })

-- Apply a themed background + 1-px border to `frame`. `opts`:
--   bgPath     ("bg.panel" by default)
--   edgePath   ("border.subtle" by default)
--   bgAlpha    overrides the color's alpha
--   edgeSize   border thickness (0 to omit; default 1)
function NUL:ApplyTheme(frame, opts)
    opts = opts or {}
    self._skinned[frame] = opts
    local t = self:GetTheme()
    local bg   = self:GetColor(opts.bgPath   or "bg.panel",     t) or self:GetColor("bg.panel", t)
    local edge = self:GetColor(opts.edgePath or "border.subtle", t) or self:GetColor("border.subtle", t)

    if not frame._nulBg then
        frame._nulBg = frame:CreateTexture(nil, "BACKGROUND")
        frame._nulBg:SetAllPoints(true)
        frame._nulBg:SetTexture(t.media.bg)
    end
    if bg then
        frame._nulBg:SetVertexColor(bg.r, bg.g, bg.b, opts.bgAlpha or bg.a or 1)
    end

    local edgeSize = opts.edgeSize == nil and 1 or opts.edgeSize
    if edgeSize > 0 then
        if not frame._nulBorder then
            frame._nulBorder = CreateFrame("Frame", nil, frame, "BackdropTemplate")
            frame._nulBorder:SetAllPoints(true)
            frame._nulBorder:SetFrameLevel(frame:GetFrameLevel())
        end
        frame._nulBorder:SetBackdrop({ edgeFile = t.media.edge, edgeSize = edgeSize })
        if edge then
            frame._nulBorder:SetBackdropBorderColor(edge.r, edge.g, edge.b, opts.edgeAlpha or 1)
        end
        frame._nulBorder:Show()
    elseif frame._nulBorder then
        frame._nulBorder:Hide()
    end
end

-- Accent stripe (e.g. for active sidebar entry). Returns the texture so
-- callers can Hide/Show it cheaply.
-- side: "LEFT" | "RIGHT" | "TOP" | "BOTTOM"   thickness: pixels
function NUL:AccentStripe(parent, side, thickness)
    side = side or "LEFT"
    thickness = thickness or 2
    local tex = parent:CreateTexture(nil, "OVERLAY")
    tex:SetTexture("Interface\\Buttons\\WHITE8x8")
    tex:SetVertexColor(self:RGBA("accent.primary"))
    if side == "LEFT" then
        tex:SetPoint("TOPLEFT");    tex:SetPoint("BOTTOMLEFT");    tex:SetWidth(thickness)
    elseif side == "RIGHT" then
        tex:SetPoint("TOPRIGHT");   tex:SetPoint("BOTTOMRIGHT");   tex:SetWidth(thickness)
    elseif side == "TOP" then
        tex:SetPoint("TOPLEFT");    tex:SetPoint("TOPRIGHT");      tex:SetHeight(thickness)
    elseif side == "BOTTOM" then
        tex:SetPoint("BOTTOMLEFT"); tex:SetPoint("BOTTOMRIGHT");   tex:SetHeight(thickness)
    end
    return tex
end

-- Register a custom paint function for a widget that doesn't fit
-- ApplyTheme (multi-state buttons, sliders, charts). The painter is
-- called immediately for first render and re-called by every theme swap.
function NUL:RegisterCustomPainter(frame, paintFn)
    if type(paintFn) ~= "function" then return end
    self._customPainters[frame] = paintFn
    pcall(paintFn, frame)
end

-- Walk the registries and re-skin every frame. Called by SetTheme; also
-- safe to call manually after registering many frames at once.
function NUL:_RepaintAll()
    -- 1. Lib-internal widgets via their own _repaint
    local theme = self:GetTheme()
    for w in pairs(self._widgets) do
        local ok, err = pcall(w._repaint, w, theme)
        if not ok then print("|cffff5555NerzorsUILib repaint error:|r", tostring(err)) end
    end
    -- 2. External frames auto-skinned via ApplyTheme
    for frame, opts in pairs(self._skinned) do
        if frame.GetObjectType then pcall(self.ApplyTheme, self, frame, opts) end
    end
    -- 3. Custom painters
    for frame, paintFn in pairs(self._customPainters) do
        pcall(paintFn, frame)
    end
end

-- Built-in themes are registered by the HOST ADDON, not here - see
-- NerzorsBlacklistKeeper/UI/Theme.lua, which calls NUL:RegisterTheme for
-- each palette at load. The lib ships no themes of its own so it stays a
-- pure engine.
