-- NerzorsUILib-1.0 :: Core/Skin.lua
--
-- Texture frames for themes that want more than flat colours (Minor 7).
-- A theme may carry an optional `skin` table; without one every widget
-- looks exactly as before. Today one part exists:
--
--   skin.frame = {
--     bg          = texture path    Background picture, stretched over the
--                                   frame (minus the corner squares).
--     bgColor     = color           Optional tint for `bg` (default white).
--     corners     = { tl, tr, bl, br }   Corner textures, `cornerSize` px.
--     cornerSize  = number          Default 16.
--     fill        = color           The colour inside the corner textures.
--                                   Frames with a colour fill (opts.fill)
--                                   use it instead of theirs, so corners
--                                   and fill meet without a seam.
--     edge        = color           Lines between the corners.
--     edgeThickness = number        Default 2.
--     titleAlign  = "CENTER"|"LEFT" Window title (Widgets/Window.lua).
--     titleColor  = color           Window title colour (default text.primary).
--     close       = { fill, hover, icon }   The window's close button as a
--                                   framed square (Widgets/Button.lua).
--   }
--   skin.list = {                     ScrollList (Widgets/ScrollList.lua)
--     bg          = color           The list's area (default bg.elevated).
--     row, rowAlt = color           Rows, alternating (default bg.panel /
--                                   bg.elevated); hover stays bg.hover.
--   }
--   skin.surface = { header, tab, sidebar, navItem = color }
--                                   Surfaces the host draws itself
--                                   (NUL:Surface / NUL:SurfaceColor); a role
--                                   without an entry keeps its theme colour.
--   skin.iconTint = color           Plain icon buttons without a colour of
--                                   their own (Widgets/Button.lua).
--   skin.text = {
--     labelCase   = "upper"         Labels with a role (column headers, field
--                                   titles; NUL:SkinLabel) in capitals.
--     labelColor  = color           ...and in this colour.
--   }
--
-- The background is cut into three bands (top, middle, bottom) so it never
-- shows under the corners: their outer triangle is transparent, which is
-- what makes the bevelled look. The texture coordinates follow the frame
-- size, so the picture stays one picture whatever the frame's size.
--
-- NUL:SkinFrame(frame, theme[, opts]) creates the textures once and shows
-- or hides them for the given theme; every widget with a frame of its own
-- calls it from its _repaint, so switching themes works both ways without
-- a reload. opts:
--   fill = color   Fill the bands with this colour instead of the picture -
--                  for small frames (tooltip, menu, dropdown list, cards),
--                  where the window picture would just look squashed.
--   corners = false  Edges only, square, all the way round - for frames
--                  whose children reach into the corners (dropdown list).
-- A frame smaller than two corners gets smaller corners (half its short
-- side), so nothing sticks out of a one-line tooltip.

local NUL = LibStub("NerzorsUILib-1.0")
local WHITE = "Interface\\Buttons\\WHITE8x8"

local CORNER_POINTS = {
    tl = "TOPLEFT", tr = "TOPRIGHT", bl = "BOTTOMLEFT", br = "BOTTOMRIGHT",
}

-- The skin part of `theme` for frames, or nil.
function NUL:FrameSkin(theme)
    theme = theme or self:GetTheme()
    local sk = theme and theme.skin
    return sk and sk.frame or nil
end

local anchor   -- below

-- Corner size for the frame's current size, anchors when it changed, and
-- the texture coordinates of the three picture bands.
local function layoutBands(s)
    local frame = s.frame
    local w, h = frame:GetWidth() or 0, frame:GetHeight() or 0
    local cs = s.wantCs or 16
    if cs > 0 and w > 0 and h > 0 then
        local half = math.floor(math.min(w, h) / 2)
        if half < cs then cs = math.max(1, half) end
    end
    if cs ~= s.cs or s.th ~= s.wantTh then anchor(s, cs, s.wantTh) end
    if s.fill or w <= 0 or h <= 0 then return end
    local u, v = cs / w, cs / h
    if u > 0.5 then u = 0.5 end
    if v > 0.5 then v = 0.5 end
    s.bgTop:SetTexCoord(u, 1 - u, 0, v)
    s.bgMid:SetTexCoord(0, 1, v, 1 - v)
    s.bgBot:SetTexCoord(u, 1 - u, 1 - v, 1)
end

local function build(frame)
    local s = { frame = frame, parts = {} }
    local function tex(layer, sub)
        local t = frame:CreateTexture(nil, layer, nil, sub)
        s.parts[#s.parts + 1] = t
        return t
    end
    -- above a flat FillBackground / gradient (BACKGROUND 0), below content
    s.bgTop, s.bgMid, s.bgBot = tex("BACKGROUND", 2), tex("BACKGROUND", 2), tex("BACKGROUND", 2)
    s.corners = {}
    for key in pairs(CORNER_POINTS) do s.corners[key] = tex("BORDER", 3) end
    s.edges = {
        top = tex("BORDER", 2), bottom = tex("BORDER", 2),
        left = tex("BORDER", 2), right = tex("BORDER", 2),
    }
    frame:HookScript("OnSizeChanged", function()
        if s.on then layoutBands(s) end
    end)
    return s
end

-- Size-dependent anchors; redone when the corner size or the edge
-- thickness change.
function anchor(s, cs, th)
    local f = s.frame
    s.bgTop:ClearAllPoints()
    s.bgTop:SetPoint("TOPLEFT", f, "TOPLEFT", cs, 0)
    s.bgTop:SetPoint("BOTTOMRIGHT", f, "TOPRIGHT", -cs, -cs)
    s.bgMid:ClearAllPoints()
    s.bgMid:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -cs)
    s.bgMid:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, cs)
    s.bgBot:ClearAllPoints()
    s.bgBot:SetPoint("TOPLEFT", f, "BOTTOMLEFT", cs, cs)
    s.bgBot:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -cs, 0)
    for key, point in pairs(CORNER_POINTS) do
        local c = s.corners[key]
        c:ClearAllPoints()
        c:SetPoint(point, f, point, 0, 0)
        c:SetSize(cs, cs)
    end
    local e = s.edges
    e.top:ClearAllPoints()
    e.top:SetPoint("TOPLEFT", f, "TOPLEFT", cs, 0)
    e.top:SetPoint("TOPRIGHT", f, "TOPRIGHT", -cs, 0)
    e.top:SetHeight(th)
    e.bottom:ClearAllPoints()
    e.bottom:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", cs, 0)
    e.bottom:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -cs, 0)
    e.bottom:SetHeight(th)
    e.left:ClearAllPoints()
    e.left:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -cs)
    e.left:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 0, cs)
    e.left:SetWidth(th)
    e.right:ClearAllPoints()
    e.right:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, -cs)
    e.right:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, cs)
    e.right:SetWidth(th)
    s.cs, s.th = cs, th
end

-- Show the theme's frame skin on `frame` (true) or hide it again (false,
-- also when the theme has none). Textures are made on first use only, so
-- frames under a theme without a skin never get any.
function NUL:SkinFrame(frame, theme, opts)
    if not frame then return false end
    local sk = self:FrameSkin(theme)
    local s = frame._nulSkin
    if not sk then
        if s and s.on then
            for _, t in ipairs(s.parts) do t:Hide() end
            s.on = false
        end
        return false
    end
    if not s then
        s = build(frame)
        frame._nulSkin = s
    end
    local noCorners = opts and opts.corners == false
    s.wantCs = noCorners and 0 or (sk.cornerSize or 16)
    s.wantTh = sk.edgeThickness or 2
    -- A colour fill takes the skin's own fill when it has one: the corner
    -- textures carry a fixed inside colour, any other would show a seam.
    -- Without corners there is no seam, so the caller's colour stays.
    s.fill = opts and opts.fill and ((not noCorners and sk.fill) or opts.fill) or nil

    local hasBg = s.fill ~= nil or sk.bg ~= nil
    for _, band in ipairs({ s.bgTop, s.bgMid, s.bgBot }) do
        if s.fill then
            band:SetTexture(WHITE)
            band:SetTexCoord(0, 1, 0, 1)
            NUL.SetTextureColor(band, s.fill)
        elseif sk.bg then
            band:SetTexture(sk.bg)
            local c = sk.bgColor
            if c then band:SetVertexColor(c.r, c.g, c.b, c.a or 1) else band:SetVertexColor(1, 1, 1, 1) end
        end
        band:SetShown(hasBg)
    end
    local corners = sk.corners or {}
    for key, c in pairs(s.corners) do
        local path = corners[key]
        if path then c:SetTexture(path) end
        c:SetShown(path ~= nil and not noCorners)
    end
    for _, e in pairs(s.edges) do
        if sk.edge then NUL.SetTextureColor(e, sk.edge) end
        e:SetShown(sk.edge ~= nil)
    end
    s.on = true
    layoutBands(s)
    return true
end

-- Hide a frame's skin textures, whatever the theme (a frame that keeps its
-- skin only for some roles, e.g. a close button under a skin without one).
function NUL:UnskinFrame(frame)
    local s = frame and frame._nulSkin
    if s and s.on then
        for _, t in ipairs(s.parts) do t:Hide() end
        s.on = false
    end
end

-- ─── Text ───────────────────────────────────────────────────────────────

-- Capitals for UTF-8 text. string.upper only knows A-Z, so "Hinzugefügt"
-- would come out "HINZUGEFüGT" and Russian not at all. This also covers
-- Latin-1 (ä ö ü é à ñ ...), Latin Extended-A (ą ł ő ...) and Cyrillic
-- (а-я, ё, і ...). ß stays ß (no capital in everyday use).
local function upperCodepoint(cp)
    if cp >= 0xE0 and cp <= 0xFE and cp ~= 0xF7 then return cp - 0x20 end   -- à-þ
    if cp == 0xFF then return 0x178 end                                       -- ÿ
    if cp >= 0x100 and cp <= 0x17F then                                       -- Latin Ext-A
        if (cp >= 0x139 and cp <= 0x148) or (cp >= 0x179 and cp <= 0x17E) then
            if cp % 2 == 0 then return cp - 1 end
        elseif cp ~= 0x138 and cp ~= 0x149 and cp ~= 0x17F then
            if cp % 2 == 1 then return cp - 1 end
        end
        return cp
    end
    if cp >= 0x430 and cp <= 0x44F then return cp - 0x20 end                  -- а-я
    if cp >= 0x450 and cp <= 0x45F then return cp - 0x50 end                  -- ѐ-џ
    return cp
end

function NUL.Upper(s)
    if type(s) ~= "string" then return s end
    s = s:gsub("([\192-\223])([\128-\191])", function(a, b)
        local cp = (a:byte() - 192) * 64 + (b:byte() - 128)
        local up = upperCodepoint(cp)
        if up == cp then return nil end
        return string.char(192 + math.floor(up / 64), 128 + up % 64)
    end)
    return (s:upper())   -- ASCII; bytes above 127 stay as they are
end

local function textSkin(theme)
    local sk = (theme or NUL:GetTheme()).skin
    return sk and sk.text or nil
end

-- Give a FontString a label role ("column" header or "field" title above
-- an input). Under a theme whose skin.text asks for it, its text shows in
-- capitals and in labelColor; otherwise exactly as set. The FontString's
-- own SetText / SetTextColor keep working as before - they store what the
-- caller wants and show the themed form - and a theme switch re-applies it.
-- NUL:CreateLabel calls this for opts.role. Returns `fs`.
function NUL:SkinLabel(fs, role)
    if not fs or fs._nulRole then return fs end
    fs._nulRole = role or "field"
    local rawSetText, rawSetColor = fs.SetText, fs.SetTextColor
    fs._nulText = fs.GetText and fs:GetText() or nil
    if fs.GetTextColor then
        local r, g, b, a = fs:GetTextColor()
        if r then fs._nulColor = { r, g, b, a } end
    end
    function fs:SetText(text)
        self._nulText = text
        local ts = textSkin()
        if ts and ts.labelCase == "upper" then text = NUL.Upper(text) end
        return rawSetText(self, text)
    end
    function fs:SetTextColor(r, g, b, a)
        self._nulColor = { r, g, b, a }
        local ts = textSkin()
        local c = ts and ts.labelColor
        if c then return rawSetColor(self, c.r, c.g, c.b, c.a or 1) end
        return rawSetColor(self, r, g, b, a)
    end
    self:RegisterCustomPainter(fs, function(f)
        f:SetText(f._nulText)
        local c = f._nulColor
        if c then f:SetTextColor(c[1], c[2], c[3], c[4]) end
    end)
    return fs
end

-- ─── Surfaces ───────────────────────────────────────────────────────────

-- Flat surfaces the host addon draws itself (list header rows, tab
-- buttons, a settings sidebar and its entries). A role names what the
-- surface is; the colour comes from skin.surface[role] when the theme has
-- one, else from the theme colour that role always used - so themes
-- without a skin look exactly as before.
local SURFACE_COLORS = {
    header  = "bg.panel",
    tab     = "bg.panel",
    sidebar = "bg.elevated",
    navItem = "bg.base",
}

function NUL:SurfaceColor(role, theme)
    theme = theme or self:GetTheme()
    local ss = theme.skin and theme.skin.surface
    if ss and ss[role] then return ss[role] end
    return self:GetColor(SURFACE_COLORS[role] or "bg.panel", theme)
end

-- A background texture for `frame` in its role's colour, repainted on
-- every theme switch. Returns the texture.
function NUL:Surface(frame, role)
    local tex = self:FillBackground(frame, self:SurfaceColor(role))
    tex._nulSurfaceRole = role
    self:RegisterCustomPainter(tex, function(t)
        NUL.SetTextureColor(t, NUL:SurfaceColor(t._nulSurfaceRole))
    end)
    return tex
end
