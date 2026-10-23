-- NerzorsUILib-1.0 :: Core/Util.lua
-- Color/font/region helpers shared by every widget.
--
-- A color is either:
--   { r = …, g = …, b = …, a = … }    (preferred, produced by hex())
--   { r, g, b, a }                   (legacy array form, still accepted)
-- All helpers degrade gracefully on nil input (no error, no-op).

local NUL = LibStub("NerzorsUILib-1.0")

-- ─── Color unpack helpers ──────────────────────────────────────────────
-- Centralized so widget code never has to guard for both formats.

local function rgba(c)
    if not c then return 0, 0, 0, 1 end
    return c.r or c[1] or 0,
           c.g or c[2] or 0,
           c.b or c[3] or 0,
           c.a or c[4] or 1
end
NUL.unpackColor = rgba

-- Apply a color to a Texture region.
function NUL.SetTextureColor(tex, c)
    if not tex or not c then return end
    tex:SetColorTexture(rgba(c))
end

-- Return a copy of `c` with alpha `a`. Used to derive resting-state dim
-- backgrounds from a saturated accent without having to register two
-- separate theme tokens.
function NUL.WithAlpha(c, alpha)
    if not c then return { r = 1, g = 1, b = 1, a = alpha or 1 } end
    local r, g, b = rgba(c)
    return { r = r, g = g, b = b, a = alpha or 1 }
end

-- Color table → "rrggbb", the form WoW's |cffRRGGBB escape wants. The
-- inverse of NUL.hex. For inline colouring inside a single string, where
-- SetFontColor can't help because only part of the text is tinted.
function NUL.ToHex(c)
    if not c then return "ffffff" end
    local r, g, b = rgba(c)
    return ("%02x%02x%02x"):format(
        math.floor(r * 255 + 0.5),
        math.floor(g * 255 + 0.5),
        math.floor(b * 255 + 0.5))
end

-- Apply a color to a FontString.
function NUL.SetFontColor(fs, c)
    if not fs or not c then return end
    fs:SetTextColor(rgba(c))
end

-- ─── Contrast helpers ──────────────────────────────────────────────────
-- WCAG 2.x relative luminance + contrast ratio. Lets a widget pick a
-- readable text colour for whatever fill the theme hands it, instead of
-- assuming light text works on every accent (it doesn't on a gold one).

local function linear(v)
    if v <= 0.03928 then return v / 12.92 end
    return ((v + 0.055) / 1.055) ^ 2.4
end

function NUL.Luminance(c)
    local r, g, b = rgba(c)
    return 0.2126 * linear(r) + 0.7152 * linear(g) + 0.0722 * linear(b)
end

-- Contrast ratio of two colours: 1 (none) .. 21 (black on white).
function NUL.Contrast(c1, c2)
    local l1, l2 = NUL.Luminance(c1), NUL.Luminance(c2)
    if l1 < l2 then l1, l2 = l2, l1 end
    return (l1 + 0.05) / (l2 + 0.05)
end

-- `top` composited over an opaque `bottom`, using top's alpha as coverage.
function NUL.Blend(top, bottom)
    local r1, g1, b1, a = rgba(top)
    local r2, g2, b2    = rgba(bottom)
    return { r = r1 * a + r2 * (1 - a), g = g1 * a + g2 * (1 - a),
             b = b1 * a + b2 * (1 - a), a = 1 }
end

-- Below this the theme's light text gives way to text.inverse (WCAG AA).
NUL.MIN_TEXT_CONTRAST = 4.5

-- Readable text colour on `fill`, staying inside the theme's palette: the
-- first of text.primary, text.inverse, bg.base (the darkest surface - for
-- themes whose inverse is a mid tone) that reaches MIN_TEXT_CONTRAST, or
-- else whichever of them contrasts most. A translucent fill is judged over
-- `under` (default bg.panel), which is what it sits on in practice.
function NUL:ReadableTextOn(fill, theme, under)
    theme = theme or self:GetTheme()
    local c = theme.colors
    if not fill then return c.text.primary end
    local _, _, _, a = rgba(fill)
    if a < 1 then fill = NUL.Blend(fill, under or c.bg.panel) end
    local cands = { c.text.primary, c.text.inverse, c.bg.base }
    local best, bestRatio = c.text.primary, 0
    for i = 1, 3 do   -- not ipairs: a theme without text.inverse leaves a hole
        local cand = cands[i]
        if cand then
            local ratio = NUL.Contrast(cand, fill)
            if ratio >= NUL.MIN_TEXT_CONTRAST then return cand end
            if ratio > bestRatio then best, bestRatio = cand, ratio end
        end
    end
    return best
end

-- ─── Frame primitives ──────────────────────────────────────────────────

function NUL:FillBackground(parent, color)
    local bg = parent:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    if color then NUL.SetTextureColor(bg, color) end
    return bg
end

-- Pixel-thin frame around `parent`. Returns { top, bottom, left, right }
-- of Texture regions.
function NUL:AddBorder(parent, color, thickness)
    thickness = thickness or 1
    local anchors = {
        top    = { "TOPLEFT",    "TOPRIGHT",    "height" },
        bottom = { "BOTTOMLEFT", "BOTTOMRIGHT", "height" },
        left   = { "TOPLEFT",    "BOTTOMLEFT",  "width"  },
        right  = { "TOPRIGHT",   "BOTTOMRIGHT", "width"  },
    }
    local edges = {}
    for name, a in pairs(anchors) do
        local t = parent:CreateTexture(nil, "BORDER")
        t:SetPoint(a[1]); t:SetPoint(a[2])
        if a[3] == "height" then t:SetHeight(thickness) else t:SetWidth(thickness) end
        if color then NUL.SetTextureColor(t, color) end
        edges[name] = t
    end
    return edges
end

function NUL:RecolorBorder(edges, color)
    if not edges or not color then return end
    for _, t in pairs(edges) do NUL.SetTextureColor(t, color) end
end

-- ─── FontString ────────────────────────────────────────────────────────
-- opts: { text, size, color, font (path), justifyH, justifyV, wrap }
-- `size` accepts:
--   nil               -> fontSizes.md (default body text)
--   a number          -> literal pixel size
--   "xs"/"sm"/"md"    -> token names resolved against theme.fontSizes
--   "lg"/"xl"
-- `font` accepts:
--   nil               -> fonts.regular
--   "regular"/"bold"  -> token name resolved against theme.fonts
--   "mono"/"heading"
--   any other string  -> used as-is (absolute font path)

local function resolveFont(theme, font)
    if not font then return theme.fonts and theme.fonts.regular end
    if type(font) == "string" and theme.fonts and theme.fonts[font] then
        return theme.fonts[font]
    end
    return font
end

local function resolveSize(theme, size)
    if not size then
        return (theme.fontSizes and theme.fontSizes.md) or 12
    end
    if type(size) == "string" then
        return (theme.fontSizes and theme.fontSizes[size]) or 12
    end
    return size
end

function NUL:CreateLabel(parent, opts)
    opts = opts or {}
    local fs = parent:CreateFontString(nil, "OVERLAY")
    local theme = self:GetTheme()
    local font = resolveFont(theme, opts.font)
    local size = resolveSize(theme, opts.size)
    if font then fs:SetFont(font, size, "") end
    fs:SetText(opts.text or "")
    NUL.SetFontColor(fs, opts.color or (theme and theme.colors and theme.colors.text and theme.colors.text.primary))
    if opts.justifyH then fs:SetJustifyH(opts.justifyH) end
    if opts.justifyV then fs:SetJustifyV(opts.justifyV) end
    if opts.wrap == false then fs:SetWordWrap(false) end
    return fs
end

-- ─── Icon resolver passthrough ─────────────────────────────────────────
-- Hosts register a resolver (NBK:IconPath) so widgets accept short names
-- like "app-close.png" alongside full Interface paths.

function NUL:ResolveIcon(name)
    if not name or name == "" then return nil end
    if type(name) ~= "string" then return name end
    if name:find("[\\/]") then return name end
    local r = self._iconResolver
    if r then return r(name) end
    return name
end

function NUL:SetIconResolver(fn)
    self._iconResolver = fn
end
