-- NerzorsUILib-1.0 :: Widgets/Button.lua
-- Flavors share the same core: text Button, IconButton (texture instead of
-- label), ImageButton (a plain, chrome-less IconButton), Pill (compact
-- chip-style toggle).
--
-- Common opts:
--   label   string         Text content (Button + Pill).
--   icon    string         Texture path or short name (IconButton).
--   width   number|"auto"  Fixed px or auto-fit-to-label (text Button only).
--                          A fixed width still grows when the label needs
--                          more room (a longer translation), never shrinks.
--   fit     boolean        Text Button only, default true. false keeps a
--                          fixed width exactly (e.g. Dropdown option rows).
--   height  number         Defaults to theme.metrics.rowHeight - 4.
--   style   string         primary | secondary | danger | ghost.
--                          Compatibility: default=secondary, accent=primary.
--   plain   boolean        IconButton only - drop the bg + border, hover
--                          feedback via icon brightness (= NUL:ImageButton).
--   tooltip string         Hover tooltip text.
--   onClick function       Click handler. Receives the button as `self`.
--   selected boolean       Pill only - initial toggled state.
--   selectedStyle string   Pill only - role while selected (default primary).
--
-- Text buttons/Pills implement SetLabel; all variants implement SetEnabled.

local NUL = LibStub("NerzorsUILib-1.0")

local aliases = {default = "secondary", accent = "primary"}
local roles = {primary = true, secondary = true, danger = true, ghost = true}

-- Themes may override colors.btn[role][normal|hover|pressed|disabled].
-- Every state contains bg/text/border and optionally icon. Missing fields,
-- states or whole palettes fall back to the theme's general vocabulary:
-- primary/danger fill with their colour (35 % at rest), secondary/ghost
-- light up as a neutral surface, and the text is whatever reads on the
-- resolved fill (NUL:ReadableTextOn), so even a partial palette stays legible.
function NUL:ResolveButtonColors(style, state, theme)
    theme = theme or self:GetTheme()
    local role = aliases[style] or style
    if not roles[role] then role = "secondary" end
    state = state or "normal"
    local c = theme.colors
    local active = state == "hover" or state == "pressed"
    local bg = c.bg.panel
    if role == "primary" then bg = active and c.accent.primary or NUL.WithAlpha(c.accent.primary, 0.35)
    elseif role == "danger" then bg = active and c.state.danger or NUL.WithAlpha(c.state.danger, 0.35)
    elseif role == "ghost" then bg = active and c.bg.hover or NUL.WithAlpha(c.bg.panel, 0)
    elseif active then bg = c.bg.hover end
    local fallback = {bg = bg,
        border = active and c.border.accent or c.border.subtle,
        icon = role == "danger" and c.state.danger or nil}
    local palette = c.btn and c.btn[role]
    local normal = palette and palette.normal or {}
    local current = palette and palette[state] or {}
    local out = {}
    for _, field in ipairs({"bg", "border", "icon"}) do
        out[field] = current[field] or normal[field] or fallback[field]
    end
    out.text = current.text or normal.text
        or (state == "disabled" and c.text.disabled)
        or NUL:ReadableTextOn(out.bg, theme)
    return out
end

local function stateOf(b)
    if not b._enabled then return "disabled" end
    if b._pressed then return "pressed" end
    if b._hovered then return "hover" end
    return "normal"
end

-- Enabled state lives in our own flag only. The native Button:Disable()
-- would also stop OnEnter/OnLeave, so tooltips on disabled buttons and the
-- hover reset below would no longer fire; OnClick checks the flag instead.
local function wireState(b)
    function b:SetEnabled(v)
        self._enabled = v and true or false
        if not self._enabled then self._pressed = false end
        self:_repaint(NUL:GetTheme())
    end
    function b:IsEnabled() return self._enabled end
    b:SetScript("OnEnter", function(self)
        self._hovered = true; self:_repaint(NUL:GetTheme())
    end)
    b:SetScript("OnLeave", function(self)
        self._hovered, self._pressed = false, false; self:_repaint(NUL:GetTheme())
    end)
    b:SetScript("OnMouseDown", function(self, button)
        if self._enabled and (not button or button == "LeftButton") then
            self._pressed = true; self:_repaint(NUL:GetTheme())
        end
    end)
    b:SetScript("OnMouseUp", function(self)
        self._pressed = false; self:_repaint(NUL:GetTheme())
    end)
    b:HookScript("OnHide", function(self)
        self._hovered, self._pressed = false, false; self:_repaint(NUL:GetTheme())
    end)
end

-- Horizontal room around a label (both sides together) when a button sizes
-- itself to its text. A fixed-width button only grows once its label leaves
-- less than LABEL_MIN_PAD, so small square ones ("+", "x") stay as they are.
local LABEL_PAD     = 24
local LABEL_MIN_PAD = 8

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
    local fit       = opts.fit ~= false
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
        padding  = padding  or LABEL_PAD
        local w = math.ceil(self.label:GetStringWidth()) + padding
        self:SetWidth(math.max(minWidth, w))
    end

    -- Auto-width buttons re-fit both ways; fixed-width ones only grow, so a
    -- longer translation stays inside the frame without reflowing layouts
    -- that already fit.
    function b:_FitLabel()
        if autoWidth then self:AutoSize(); return end
        if not fit then return end
        local textW = math.ceil(self.label:GetStringWidth())
        if textW + LABEL_MIN_PAD > self:GetWidth() then
            self:SetWidth(textW + LABEL_PAD)
        end
    end

    function b:SetLabel(text)
        self.label:SetText(text or "")
        self:_FitLabel()
    end

    function b:_repaint(t)
        local colors = NUL:ResolveButtonColors(self._style, stateOf(self), t)
        NUL.SetTextureColor(self.bg, colors.bg)
        NUL:RecolorBorder(self.borders, colors.border)
        NUL.SetFontColor(self.label, colors.text)
        self.label:ClearAllPoints()
        local down = self._pressed and self._enabled
        self.label:SetPoint("CENTER", down and 1 or 0, down and -1 or 0)
    end

    wireState(b)
    -- The custom font reports GetStringWidth() == 0 until it has been drawn
    -- once, so a cold first measure comes out short: fit again on show and
    -- one frame later.
    b:HookScript("OnShow", function(self)
        self:_FitLabel()
        if C_Timer and C_Timer.After then
            C_Timer.After(0, function() self:_FitLabel() end)
        end
    end)
    if opts.onClick then
        b:SetScript("OnClick", function(self) if self._enabled then opts.onClick(self) end end)
    end

    attachTooltip(b, opts.tooltip)
    self:_Track(b)
    b:_repaint(theme)
    b:_FitLabel()
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
-- without the button's own repaint/hover clobbering it. Chromed buttons take
-- the role's text colour as hue, plain ones only an explicit icon token.

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
    function b:_repaint(t)
        local state = stateOf(self)
        local colors = NUL:ResolveButtonColors(self._style, state, t)
        if self.bg then
            NUL.SetTextureColor(self.bg, colors.bg)
            NUL:RecolorBorder(self.borders, colors.border)
        end
        -- Plain toggles own their hue (mute/share in blacklist rows).
        -- Only an explicit icon token, e.g. danger, takes ownership of hue.
        local tint = colors.icon or (not self._plain and colors.text)
        if tint then
            self.icon:SetVertexColor(tint.r, tint.g, tint.b, tint.a or 1)
        end
        local alpha = self:_iconRestAlpha()
        if self._enabled and self._plain then
            alpha = state == "pressed" and 0.65 or (state == "hover" and 1 or alpha)
        end
        self.icon:SetAlpha(alpha)
    end

    wireState(b)
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
    b._enabled = true
    b._style = opts.style or "secondary"
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
        local role = self._selected and (opts.selectedStyle or "primary") or self._style
        local colors = NUL:ResolveButtonColors(role, stateOf(self), t)
        NUL.SetTextureColor(self.bg, colors.bg)
        NUL.SetFontColor(self.label, colors.text)
        NUL:RecolorBorder(self.borders, colors.border)
    end

    wireState(b)
    b:SetScript("OnClick", function(self)
        if not self._enabled then return end
        if opts.onClick then opts.onClick(self)
        else self:SetSelected(not self._selected) end
    end)

    self:_Track(b)
    b:_repaint(theme)
    return b
end
