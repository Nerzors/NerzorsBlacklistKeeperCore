-- NerzorsUILib-1.0 :: Core/Gradient.lua
-- Soft gradient backgrounds for windows/panels. Used by themes that opt
-- into the Sci-Fi gradient look (theme.window.useGradient = true).
--
-- Reads theme.window.gradient.{start,end} as anchor colors; falls back
-- to bg.base / bg.elevated so a theme without explicit gradient settings
-- still renders a visible (if flat) background.
--
-- Blizzard changed Texture:SetGradient between expansions:
--   9.x:    SetGradientAlpha(orientation, r1,g1,b1,a1, r2,g2,b2,a2)
--   10.x+:  SetGradient(orientation, ColorMixinA, ColorMixinB)
-- We feature-detect once and pick the working path.

local NUL = LibStub("NerzorsUILib-1.0")

local function makeColorMixin(c)
    if CreateColor then
        local r, g, b, a = NUL.unpackColor(c)
        return CreateColor(r, g, b, a)
    end
    return c
end

local function applyGradient(tex, orientation, c1, c2)
    if not tex then return end
    if tex.SetGradient then
        local okMixin = pcall(tex.SetGradient, tex, orientation,
            makeColorMixin(c1), makeColorMixin(c2))
        if okMixin then return end
    end
    if tex.SetGradientAlpha then
        local r1, g1, b1, a1 = NUL.unpackColor(c1)
        local r2, g2, b2, a2 = NUL.unpackColor(c2)
        tex:SetGradientAlpha(orientation, r1, g1, b1, a1, r2, g2, b2, a2)
        return
    end
    NUL.SetTextureColor(tex, c1)
end

-- Resolve gradient anchor colors from a theme. Lookups (in order):
--   theme.window.gradient.start / .["end"]
--   theme.colors.bg.base / .elevated
local function gradientColors(theme, opts)
    local c1 = opts.c1
    local c2 = opts.c2
    local g  = theme.window and theme.window.gradient or nil
    if g then
        c1 = c1 or g.start
        c2 = c2 or g["end"]
    end
    local bg = theme.colors and theme.colors.bg or nil
    if bg then
        c1 = c1 or bg.base
        c2 = c2 or bg.elevated or bg.base
    end
    return c1, c2
end

-- Replace `parent`'s background with a gradient. Returns the Texture so
-- callers can recolor in a repaint pass via tex:Refresh(c1, c2).
function NUL:GradientBackground(parent, opts)
    opts = opts or {}
    local theme = self:GetTheme()
    local c1, c2 = gradientColors(theme, opts)
    local orientation = opts.orientation
        or (theme.window and theme.window.gradientOrientation)
        or "VERTICAL"

    local tex = parent:CreateTexture(nil, "BACKGROUND")
    tex:SetAllPoints()
    tex:SetColorTexture(1, 1, 1, 1) -- gradient needs a base white-ish texture
    applyGradient(tex, orientation, c1, c2)

    tex._gradOrientation = orientation
    function tex:Refresh(newC1, newC2, newOrientation)
        local t = NUL:GetTheme()
        local rc1, rc2 = gradientColors(t, { c1 = newC1, c2 = newC2 })
        applyGradient(self, newOrientation or self._gradOrientation, rc1, rc2)
    end
    return tex
end
