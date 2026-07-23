-- NerzorsUILib-1.0 :: Widgets/Window.lua
-- Themed floating window: title bar, drag-to-move, close button, optional
-- gradient background (Sci-Fi theme), optional resize grip with bounds
-- and persistence, and a flexible "brand logo" that can either sit inline
-- in the title bar ("embed" mode) or break out of the window edge like a
-- CSS `position: absolute` element ("absolute" mode).
--
-- opts:
--   name       string       Global frame name (for /framestack + UISpecialFrames).
--   title      string       Title text shown in the title bar.
--   width      number
--   height     number
--   parent     Frame        Default UIParent.
--   strata     string       Default "HIGH".
--   gradient   boolean      Default = theme.window.useGradient.
--   onClose    function     Called when the X button is clicked.
--
--   ─── Brand logo (all optional) ─────────────────────────────────────
--   icon       string       LEGACY shortcut: same as logo = { path = … }.
--                           Triggers "embed" mode at 48 px. Kept so old
--                           callers (`icon = theme.media.logo`) keep
--                           working without changes.
--   iconSize   number       LEGACY shortcut: square size for `icon`.
--   logo       table|nil    Rich logo config. Fields:
--     path        string    Texture path. Resolved via :ResolveIcon().
--     mode        string    "embed"    -> sits inside the title bar at
--                                         the left, scaled to bar height
--                                         (default for `icon = …`)
--                           "absolute" -> breaks out of the frame edge,
--                                         CSS-style. Anchor + offset
--                                         drive where it sticks out.
--     size        number|{w,h}        Square size or explicit dims.
--                                     Defaults: embed = titleBarHeight,
--                                     absolute = 64.
--     anchor      string    "TOPLEFT" | "TOPRIGHT" | "BOTTOMLEFT" |
--                           "BOTTOMRIGHT". Absolute mode only - the
--                           corner of the WINDOW the logo anchors to.
--                           Default "TOPLEFT".
--     offset      {x, y}    Fine-tune pixel offset relative to the
--                           anchor corner. Negative pushes outward
--                           (-12, 12) is the classic "stick out beyond
--                           the edge" look. Default { -12, 12 } for
--                           TOPLEFT, mirrored sensibly per anchor.
--     titleInset  number    X-offset for the title text when the logo
--                           covers part of the title bar. Default 54 in
--                           embed mode, 0 in absolute mode (since the
--                           logo overflows outside the bar).
--     drawLayer   string    "OVERLAY" by default. Set "BACKGROUND" /
--                           "ARTWORK" if you need the logo behind
--                           other title-bar widgets.

local NUL = LibStub("NerzorsUILib-1.0")

local function readPositions(db)
    if not db then return nil end
    db.settings = db.settings or {}
    db.settings.windowPositions = db.settings.windowPositions or {}
    return db.settings.windowPositions
end

function NUL:Window(opts)
    opts = opts or {}
    local theme  = self:GetTheme()
    local width  = opts.width  or 600
    local height = opts.height or 420
    local parent = opts.parent or UIParent

    local f = CreateFrame("Frame", opts.name, parent)
    f:SetSize(width, height)
    f:SetPoint("CENTER")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:SetClampedToScreen(true)
    f:SetFrameStrata(opts.strata or "HIGH")
    f:Hide()
    if opts.name then tinsert(UISpecialFrames, opts.name) end

    -- Background: gradient if the theme opts in (or the caller forces it),
    -- otherwise a solid bg.base fill.
    local useGradient = opts.gradient
    if useGradient == nil then useGradient = theme.window and theme.window.useGradient end
    if useGradient then
        f.bg = self:GradientBackground(f, {
            orientation = (theme.window and theme.window.gradientOrientation) or "VERTICAL",
        })
    else
        f.bg = self:FillBackground(f, theme.colors.bg.base)
    end
    f.borders = self:AddBorder(f, nil, theme.metrics.borderThickness)

    -- Title bar
    local tb = CreateFrame("Frame", nil, f)
    tb:SetHeight(theme.metrics.titleBarHeight)
    tb:SetPoint("TOPLEFT",  1, -1)
    tb:SetPoint("TOPRIGHT", -1, -1)
    tb.bg = self:FillBackground(tb)

    -- Title bar accent line at the bottom (signature stripe).
    local accent = tb:CreateTexture(nil, "ARTWORK")
    accent:SetPoint("BOTTOMLEFT")
    accent:SetPoint("BOTTOMRIGHT")
    accent:SetHeight(1)
    tb.accent = accent

    tb:EnableMouse(true); tb:RegisterForDrag("LeftButton")
    tb:SetScript("OnDragStart", function() f:StartMoving() end)
    tb:SetScript("OnDragStop", function()
        f:StopMovingOrSizing()
        if f._positionKey and f._positionDB then
            local positions = readPositions(f._positionDB)
            local point, _, _, x, y = f:GetPoint()
            positions[f._positionKey] = positions[f._positionKey] or {}
            local saved = positions[f._positionKey]
            saved.point, saved.x, saved.y = point, x, y
        end
    end)

    f.titleText = self:CreateLabel(tb, {
        text = opts.title or "",
        size = "xl",
    })
    f.titleText:SetPoint("LEFT", 10, 0)
    function f:SetTitle(text) self.titleText:SetText(text or "") end

    f.closeButton = self:IconButton(tb, {
        icon  = "app-close.png",
        size  = 22,
        style = "danger",
        plain = true,
        onClick = function()
            f:Hide()
            if opts.onClose then opts.onClose(f) end
        end,
    })
    f.closeButton:SetPoint("RIGHT", -6, 0)

    f.content = CreateFrame("Frame", nil, f)
    f.content:SetPoint("TOPLEFT", tb, "BOTTOMLEFT",
        theme.metrics.windowPadding, -theme.metrics.windowPadding)
    f.content:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT",
        -theme.metrics.windowPadding, theme.metrics.windowPadding)

    f.titleBar = tb

    -- ─── Brand logo (embed | absolute) ─────────────────────────────────
    --
    -- Two layout modes share the same texture region. `embed` is the
    -- classic in-bar look (left-anchored, scaled to bar height) - what
    -- the legacy SetIcon used to produce. `absolute` parks the texture
    -- relative to a CORNER OF THE WINDOW with a free offset, letting it
    -- overhang the frame edge CSS-style. We re-parent the texture to the
    -- window itself in absolute mode so clamping against the title bar
    -- edges doesn't clip the overflow.

    local function defaultOffsetForAnchor(anchor)
        -- Stick OUTWARD from the chosen corner by default. Callers can
        -- still override via opts.logo.offset; this just gives "I only
        -- set anchor = TOPRIGHT" a sane look without further tuning.
        if anchor == "TOPRIGHT"    then return { 12,  12 } end
        if anchor == "BOTTOMLEFT"  then return { -12, -12 } end
        if anchor == "BOTTOMRIGHT" then return { 12, -12 } end
        return { -12, 12 }  -- TOPLEFT default
    end

    function f:SetLogo(cfg)
        -- Allow `nil` to clear the logo, mirror the SetIcon(nil) pattern.
        if not cfg then
            if self.logo then self.logo:Hide() end
            self.titleText:ClearAllPoints()
            self.titleText:SetPoint("LEFT", self.titleBar, "LEFT", 10, 0)
            return
        end

        local mode       = cfg.mode or "embed"
        local anchor     = cfg.anchor or "TOPLEFT"
        local drawLayer  = cfg.drawLayer or "OVERLAY"

        -- Resolve size: number = square, {w,h} = explicit. Mode-specific
        -- defaults so callers can leave it nil and still get something
        -- visually right.
        local w, h
        if type(cfg.size) == "number" then
            w, h = cfg.size, cfg.size
        elseif type(cfg.size) == "table" then
            w = cfg.size.w or cfg.size[1] or 48
            h = cfg.size.h or cfg.size[2] or w
        elseif mode == "absolute" then
            w, h = 64, 64
        else
            local barH = (NUL:GetTheme().metrics and NUL:GetTheme().metrics.titleBarHeight) or 28
            w, h = barH, barH
        end

        local offset = cfg.offset or defaultOffsetForAnchor(anchor)
        local ox = offset.x or offset[1] or 0
        local oy = offset.y or offset[2] or 0

        -- Parent + draw-layer choice.
        --
        -- Z-order in WoW: textures live on draw layers of a frame, but
        -- CHILD FRAMES always render on top of their parent's textures
        -- regardless of layer. The titleBar is a child of the window, so
        -- anything we hang on the window itself (even at OVERLAY) gets
        -- painted underneath the title text. Parenting the logo to the
        -- titleBar fixes that - it now lives in the same z-stack as the
        -- title text, and our explicit "OVERLAY + sublevel 7" beats the
        -- titleText's default OVERLAY/0.
        --
        -- The anchor side stays free: a logo parented to the titleBar
        -- can still anchor to the WINDOW's corner so it overhangs the
        -- frame edge CSS-style (frames don't clip their textures, so a
        -- texture spilling outside the titleBar rect renders fine).
        if self.logo then self.logo:Hide(); self.logo = nil end

        local tex = self.titleBar:CreateTexture(nil, drawLayer, nil, 7)
        tex:SetSize(w, h)
        tex:ClearAllPoints()

        if mode == "absolute" then
            -- CSS `position: absolute`: pin the chosen logo corner to the
            -- corresponding WINDOW corner, then shift by offset. Negative
            -- offsets push outward beyond the edge.
            tex:SetPoint(anchor, self, anchor, ox, oy)
        else
            -- Embed: TOPLEFT of the title bar plus offset.
            tex:SetPoint("TOPLEFT", self.titleBar, "TOPLEFT", ox, oy)
        end
        tex:SetTexture(NUL:ResolveIcon(cfg.path or ""))
        tex:Show()
        self.logo = tex

        -- Title-text inset. In embed mode we have to make room for the
        -- logo or it overlaps the text; in absolute mode the texture
        -- overflows outside the bar so the title text starts at the
        -- normal inset unless the caller explicitly requested one.
        local inset = cfg.titleInset
        if not inset then
            inset = (mode == "embed") and (w + (ox > 0 and ox or 4) + 8) or 10
        end
        self.titleText:ClearAllPoints()
        self.titleText:SetPoint("LEFT", self.titleBar, "LEFT", inset, 0)
    end

    -- Legacy: `f:SetIcon(path, size)` and `opts.icon = …` keep working
    -- by translating to a SetLogo({ mode = "embed", … }) call.
    function f:SetIcon(path, size)
        self:SetLogo({ mode = "embed", path = path, size = size or 48 })
    end

    -- Apply opts.logo (rich form) preferentially, then fall back to the
    -- legacy `icon` / `iconSize` shortcuts.
    if opts.logo then
        f:SetLogo(opts.logo)
    elseif opts.icon then
        f:SetIcon(opts.icon, opts.iconSize)
    end

    -- ─── Position persistence + resize ─────────────────────────────────

    function f:SetPositionKey(key, db)
        self._positionKey = key
        self._positionDB  = db
    end

    function f:RestorePosition()
        if not self._positionKey then return end
        local positions = readPositions(self._positionDB)
        local saved = positions and positions[self._positionKey]
        if not saved then return end
        if saved.point then
            self:ClearAllPoints()
            self:SetPoint(saved.point, UIParent, saved.point, saved.x or 0, saved.y or 0)
        end
        if self:IsResizable() and saved.width and saved.height then
            local w, h = saved.width, saved.height
            if self._minW then w = math.max(self._minW, math.min(self._maxW or w, w)) end
            if self._minH then h = math.max(self._minH, math.min(self._maxH or h, h)) end
            self:SetSize(w, h)
        end
    end

    function f:MakeResizable(args)
        args = args or {}
        local minW, minH = args.minW or 600, args.minH or 400
        local maxW, maxH = args.maxW or 1600, args.maxH or 1200
        self._minW, self._minH, self._maxW, self._maxH = minW, minH, maxW, maxH

        self:SetResizable(true)
        if self.SetResizeBounds then
            self:SetResizeBounds(minW, minH, maxW, maxH)
        elseif self.SetMinResize then
            self:SetMinResize(minW, minH)
            if self.SetMaxResize then self:SetMaxResize(maxW, maxH) end
        end

        local grip = CreateFrame("Button", nil, self)
        grip:SetSize(16, 16)
        grip:SetPoint("BOTTOMRIGHT", -1, 1)
        grip:EnableMouse(true)
        grip:RegisterForDrag("LeftButton")
        grip:SetFrameLevel((self:GetFrameLevel() or 0) + 5)

        -- Six-dot triangular grip - classic affordance without competing
        -- visually with the rest of the window.
        local t = NUL:GetTheme()
        local dots = {}
        for ix = 0, 2 do
            for iy = 0, 2 do
                if ix + iy <= 2 then
                    local d = grip:CreateTexture(nil, "OVERLAY")
                    d:SetSize(2, 2)
                    d:SetPoint("BOTTOMRIGHT", -ix * 4, iy * 4)
                    NUL.SetTextureColor(d, NUL.WithAlpha(t.colors.text.muted, 0.7))
                    table.insert(dots, d)
                end
            end
        end

        grip:SetScript("OnEnter", function()
            local c = NUL:GetTheme().colors.accent.secondary
            for _, d in ipairs(dots) do NUL.SetTextureColor(d, c) end
        end)
        grip:SetScript("OnLeave", function()
            local c = NUL:GetTheme().colors.text.muted
            for _, d in ipairs(dots) do
                NUL.SetTextureColor(d, NUL.WithAlpha(c, 0.7))
            end
        end)
        grip:SetScript("OnDragStart", function() self:StartSizing("BOTTOMRIGHT") end)
        grip:SetScript("OnDragStop", function()
            self:StopMovingOrSizing()
            if self._positionKey and self._positionDB then
                local positions = readPositions(self._positionDB)
                local saved = positions[self._positionKey] or {}
                saved.width  = self:GetWidth()
                saved.height = self:GetHeight()
                local point, _, _, x, y = self:GetPoint()
                if point then saved.point, saved.x, saved.y = point, x, y end
                positions[self._positionKey] = saved
            end
        end)
        self.resizeGrip = grip
    end

    -- Repaint: re-color every visible surface. Gradient backgrounds know
    -- how to re-read the theme via their own Refresh().
    function f:_repaint(t)
        if self.bg and self.bg.Refresh then
            self.bg:Refresh()
        elseif self.bg then
            NUL.SetTextureColor(self.bg, t.colors.bg.base)
        end
        NUL:RecolorBorder(self.borders, t.colors.border.subtle)
        NUL.SetTextureColor(self.titleBar.bg, t.colors.bg.panel)
        NUL.SetTextureColor(self.titleBar.accent, t.colors.accent.primary)
        NUL.SetFontColor(self.titleText, t.colors.text.primary)
    end

    self:_Track(f)
    f:_repaint(theme)
    return f
end
