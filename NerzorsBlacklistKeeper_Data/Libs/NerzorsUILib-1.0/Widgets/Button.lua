-- NerzorsUILib-1.0 :: Widgets/Button.lua
-- Flavors share the same core: text Button, IconButton (texture instead of
-- label), ImageButton (a plain, chrome-less IconButton), Pill (compact
-- chip-style toggle).
--
-- Common opts:
--   label   string         Text content (Button + Pill).
--   icon    string         Texture path or short name (IconButton).
--   width   number|"auto"  Fixed px or auto-fit-to-label (text Button only).
--   height  number         Defaults to theme.metrics.rowHeight - 4.
--   style   string         "default" | "accent" | "danger".
--   plain   boolean        IconButton only - drop the bg + border, hover
--                          feedback via icon brightness (= NUL:ImageButton).
--   tooltip string         Hover tooltip text.
--   onClick function       Click handler. Receives the button as `self`.
--   selected boolean       Pill only - initial toggled state.
--
-- All buttons implement :SetLabel / :SetEnabled / :_repaint.

local NUL = LibStub("NerzorsUILib-1.0")

-- Resolve resting + hover background colors per style. Resting buttons use
-- a low-alpha accent ("dim") rather than a separate theme token so theme
-- variants only need to override one color slot to re-style every button.
local function styleColors(theme, style)
    local c = theme.colors
    if style == "accent" then
        return NUL.WithAlpha(c.accent.primary, 0.35), c.accent.primary
    elseif style == "danger" then
        return NUL.WithAlpha(c.state.danger,   0.35), c.state.danger
    end
    return c.bg.panel, c.accent.primary
end

-- Centralised tooltip behaviour so all button variants behave identically
-- on hover. Routes through the themed NUL tooltip (Widgets/Tooltip.lua)
-- rather than Blizzard's GameTooltip, so it matches the rest of the skin.
local function attachTooltip(frame, text)
    if not text then return end
    NUL:AttachTooltip(frame, text)
end

-- ─── Text Button ────────────────────────────────────────────────────────

function NUL:Button(parent, opts)
    opts = opts or {}
    local b = CreateFrame("Button", nil, parent)
    local theme = self:GetTheme()

    local autoWidth = (opts.width == "auto" or opts.width == nil)
    local height    = opts.height or (theme.metrics.rowHeight - 4)
    b:SetSize(type(opts.width) == "number" and opts.width or 80, height)

    b._style   = opts.style or "default"
    b._opts    = opts
    b._enabled = true

    b.bg      = self:FillBackground(b)
    b.borders = self:AddBorder(b, nil, theme.metrics.borderThickness)
    b.label   = self:CreateLabel(b, { text = opts.label or "" })
    b.label:SetPoint("CENTER")

    function b:AutoSize(minWidth, padding)
        minWidth = minWidth or 60
        padding  = padding  or 24
        local w = math.ceil(self.label:GetStringWidth()) + padding
        self:SetWidth(math.max(minWidth, w))
    end

    function b:SetLabel(text)
        self.label:SetText(text or "")
        if autoWidth then self:AutoSize() end
    end

    function b:SetEnabled(v)
        self._enabled = v and true or false
        self:_repaint(NUL:GetTheme())
    end

    function b:_repaint(t)
        local rest, hover = styleColors(t, self._style)
        self._restColor  = rest
        self._hoverColor = hover
        NUL.SetTextureColor(self.bg, rest)
        NUL:RecolorBorder(self.borders, t.colors.border.subtle)
        local fc = self._enabled and t.colors.text.primary or t.colors.text.disabled
        NUL.SetFontColor(self.label, fc)
    end

    b:SetScript("OnEnter", function(self)
        if not self._enabled then return end
        NUL.SetTextureColor(self.bg, self._hoverColor)
        NUL:RecolorBorder(self.borders, NUL:GetTheme().colors.border.accent)
    end)
    b:SetScript("OnLeave", function(self)
        NUL.SetTextureColor(self.bg, self._restColor)
        NUL:RecolorBorder(self.borders, NUL:GetTheme().colors.border.subtle)
    end)
    b:SetScript("OnMouseDown", function(self)
        if self._enabled then self.label:SetPoint("CENTER", 1, -1) end
    end)
    b:SetScript("OnMouseUp", function(self) self.label:SetPoint("CENTER") end)
    if opts.onClick then
        b:SetScript("OnClick", function(self) if self._enabled then opts.onClick(self) end end)
    end

    attachTooltip(b, opts.tooltip)
    self:_Track(b)
    b:_repaint(theme)
    if autoWidth then b:AutoSize() end
    return b
end

-- ─── IconButton ─────────────────────────────────────────────────────────
--
-- Extra opts:
--   plain  boolean  Image-only button - no background, no border. Hover
--                   feedback is a brightness change on the icon itself
--                   (rest ~0.85 alpha → full on hover) instead of a bg/border
--                   swap. See NUL:ImageButton for a named shortcut.
--
-- Brightness is driven via icon:SetAlpha (rest/hover) while the HUE stays on
-- SetVertexColor. Keeping the two channels separate lets callers own the hue
-- (e.g. the blacklist row's mute/share toggles tint the icon accent/muted)
-- without the button's own repaint/hover clobbering it.

function NUL:IconButton(parent, opts)
    opts = opts or {}
    local size  = opts.size or 20
    local plain = opts.plain and true or false
    local b     = CreateFrame("Button", nil, parent)
    local theme = self:GetTheme()
    b:SetSize(size, size)

    b._style   = opts.style or "default"
    b._enabled = true
    b._plain   = plain

    -- Plain buttons carry no chrome; the others get the themed bg + border.
    if not plain then
        b.bg      = self:FillBackground(b)
        b.borders = self:AddBorder(b, nil, theme.metrics.borderThickness)
    end

    local inset = math.max(2, math.floor(size * 0.2))
    b.icon = b:CreateTexture(nil, "OVERLAY")
    b.icon:SetPoint("TOPLEFT", inset, -inset)
    b.icon:SetPoint("BOTTOMRIGHT", -inset, inset)
    b.icon:SetTexture(self:ResolveIcon(opts.icon))
    b.icon:SetVertexColor(1, 1, 1, 1)

    -- Resting brightness: dim slightly for plain (so hover reads), full for
    -- chromed (the bg/border carries the affordance); dimmed when disabled.
    function b:_iconRestAlpha()
        if not self._enabled then return 0.4 end
        return self._plain and 0.85 or 1
    end

    function b:SetIcon(name) self.icon:SetTexture(NUL:ResolveIcon(name)) end
    function b:SetEnabled(v)
        self._enabled = v and true or false
        self:_repaint(NUL:GetTheme())
    end
    function b:_repaint(t)
        if self.bg then
            local rest, hover = styleColors(t, self._style)
            self._restColor, self._hoverColor = rest, hover
            NUL.SetTextureColor(self.bg, rest)
            NUL:RecolorBorder(self.borders, t.colors.border.subtle)
        end
        -- HUE only: danger tints red; default leaves whatever hue the caller
        -- set (white by default, or a toggle's accent/muted tint). Brightness
        -- is applied separately via SetAlpha so we never fight that tint.
        if self._style == "danger" then
            local d = t.colors.state.danger
            self.icon:SetVertexColor(d.r, d.g, d.b, 1)
        end
        self.icon:SetAlpha(self:_iconRestAlpha())
    end

    b:SetScript("OnEnter", function(self)
        if not self._enabled then return end
        if self._plain then
            self.icon:SetAlpha(1)
        else
            NUL.SetTextureColor(self.bg, self._hoverColor)
            NUL:RecolorBorder(self.borders, NUL:GetTheme().colors.border.accent)
        end
    end)
    b:SetScript("OnLeave", function(self)
        if self._plain then
            self.icon:SetAlpha(self:_iconRestAlpha())
        else
            NUL.SetTextureColor(self.bg, self._restColor)
            NUL:RecolorBorder(self.borders, NUL:GetTheme().colors.border.subtle)
        end
    end)
    if opts.onClick then
        b:SetScript("OnClick", function(self) if self._enabled then opts.onClick(self) end end)
    end

    attachTooltip(b, opts.tooltip)
    self:_Track(b)
    b:_repaint(theme)
    return b
end

-- ─── ImageButton ────────────────────────────────────────────────────────
-- Named shortcut for a plain (no bg / no border) icon button. Same opts as
-- IconButton; `plain` is forced on.

function NUL:ImageButton(parent, opts)
    opts = opts or {}
    opts.plain = true
    return self:IconButton(parent, opts)
end

-- ─── Pill ───────────────────────────────────────────────────────────────

function NUL:Pill(parent, opts)
    opts = opts or {}
    local b     = CreateFrame("Button", nil, parent)
    local theme = self:GetTheme()
    b:SetHeight(20)

    b.label = self:CreateLabel(b, {
        text     = opts.label or "",
        size     = "sm",
        justifyH = "CENTER",
    })
    b.label:SetPoint("LEFT", 8, 0)
    b.label:SetPoint("RIGHT", -8, 0)

    local w = math.max(36, b.label:GetStringWidth() + 16)
    b:SetWidth(w)

    b.bg      = self:FillBackground(b)
    b.borders = self:AddBorder(b, nil, theme.metrics.borderThickness)
    b._selected = opts.selected and true or false

    function b:SetSelected(v)
        self._selected = v and true or false
        self:_repaint(NUL:GetTheme())
    end
    function b:IsSelected() return self._selected end
    function b:SetLabel(text)
        self.label:SetText(text or "")
        self:SetWidth(math.max(36, self.label:GetStringWidth() + 16))
    end

    function b:_repaint(t)
        if self._selected then
            NUL.SetTextureColor(self.bg, t.colors.accent.primary)
        else
            NUL.SetTextureColor(self.bg, t.colors.bg.panel)
        end
        NUL.SetFontColor(self.label, t.colors.text.primary)
        NUL:RecolorBorder(self.borders, t.colors.border.subtle)
    end

    b:SetScript("OnEnter", function(self)
        if self._selected then return end
        NUL.SetTextureColor(self.bg, NUL:GetTheme().colors.bg.hover)
    end)
    b:SetScript("OnLeave", function(self) self:_repaint(NUL:GetTheme()) end)
    b:SetScript("OnClick", function(self)
        if opts.onClick then opts.onClick(self)
        else self:SetSelected(not self._selected) end
    end)

    self:_Track(b)
    b:_repaint(theme)
    return b
end
