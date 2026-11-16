-- NerzorsUILib-1.0 :: Widgets/Menu.lua
-- A small pop-up menu in the theme's colours: a column of entries, opened
-- under a button or at the mouse. Avoids Blizzard's menus so the skin stays
-- the same on every client. One popup is shared; opening a menu closes the
-- one before.
--
--   NUL:ShowMenu(owner, items, opts)
--     owner   Frame   what the menu belongs to (it closes when owner hides)
--     items   array   { label, onClick, disabled, tooltip } or
--                     { separator = true }
--     opts.anchor     "below" (default: under owner, left edges aligned)
--                     | "cursor" (at the mouse, e.g. a right-click)
--     opts.minWidth   number, default the owner's width ("below") or 140
--   NUL:HideMenu()
--   NUL:IsMenuShownFor(owner) -> bool
--
--   NUL:MenuButton(parent, opts)   text Button with a chevron that opens a
--     menu. opts as for NUL:Button plus `items` (array, or a function that
--     returns one - built fresh on every open, so entries can depend on
--     the current state).
--
-- It closes when an entry is chosen, on a mouse click anywhere else
-- (GLOBAL_MOUSE_DOWN, where the client has it) and when the owner hides.
-- Lives on UIParent at TOOLTIP strata like the dropdown popup, and follows
-- the lib scale (NUL:_FollowScale).

local NUL = LibStub("NerzorsUILib-1.0")

local ROW_H    = 22
local PAD      = 2
local SEP_H    = 7
local TEXT_PAD = 10    -- left and right of an entry's text
local CHEVRON  = 14    -- room for the MenuButton arrow

local menu   -- the shared popup, built on first use

local function textColor(t, item)
    return item.disabled and t.colors.text.muted or t.colors.text.primary
end

local function buildPopup()
    if menu then return menu end
    local f = CreateFrame("Frame", "NerzorsUILibMenu", UIParent)
    f:SetFrameStrata("TOOLTIP")
    f:SetFrameLevel(400)
    f:SetClampedToScreen(true)
    f:EnableMouse(true)
    f:Hide()
    NUL:_FollowScale(f)
    f.bg      = NUL:FillBackground(f)
    f.borders = NUL:AddBorder(f, nil, NUL:GetTheme().metrics.borderThickness)
    f.rows = {}

    -- A click outside closes the menu. Mouse-down fires before the owner's
    -- OnClick, so clicking the owner of an open menu leaves it to the
    -- owner, which toggles it.
    local ok = pcall(f.RegisterEvent, f, "GLOBAL_MOUSE_DOWN")
    if ok then
        f:SetScript("OnEvent", function(self)
            if not self:IsShown() then return end
            -- The frame method, not the old global MouseIsOver (gone from
            -- current clients).
            if self:IsMouseOver() then return end
            if self.owner and self.owner:IsVisible() and self.owner:IsMouseOver() then return end
            self:Hide()
        end)
    end
    f:SetScript("OnHide", function(self)
        self.owner = nil
        NUL:HideTooltip()
    end)
    menu = f
    return f
end

local function rowFor(f, i)
    local r = f.rows[i]
    if r then return r end
    r = CreateFrame("Button", nil, f)
    r:SetHeight(ROW_H)
    r.hl = r:CreateTexture(nil, "BACKGROUND")
    r.hl:SetAllPoints()
    r.hl:Hide()
    r.line = r:CreateTexture(nil, "ARTWORK")
    r.line:SetHeight(1)
    r.line:SetPoint("LEFT", TEXT_PAD - 4, 0)
    r.line:SetPoint("RIGHT", -(TEXT_PAD - 4), 0)
    r.label = NUL:CreateLabel(r, { text = "", justifyH = "LEFT", wrap = false })
    r.label:SetPoint("LEFT", TEXT_PAD, 0)
    r.label:SetPoint("RIGHT", -TEXT_PAD, 0)
    r:SetScript("OnEnter", function(self)
        local item = self.item
        if not item or item.separator then return end
        if not item.disabled then self.hl:Show() end
        if item.tooltip then NUL:ShowTooltip(self, item.tooltip, { anchor = "RIGHT" }) end
    end)
    r:SetScript("OnLeave", function(self)
        self.hl:Hide()
        NUL:HideTooltip()
    end)
    r:SetScript("OnClick", function(self)
        local item = self.item
        if not item or item.separator or item.disabled then return end
        f:Hide()
        if item.onClick then item.onClick() end
    end)
    f.rows[i] = r
    return r
end

-- Lay the entries out; widths come from the labels, which the custom font
-- can measure as 0 before its first draw - so this runs again a frame later.
local function layout(f, minWidth)
    local t = NUL:GetTheme()
    local w, y = minWidth or 140, -PAD
    for i, item in ipairs(f.items) do
        local r = rowFor(f, i)
        r.item = item
        r:ClearAllPoints()
        r:SetPoint("TOPLEFT", PAD, y)
        r:SetPoint("RIGHT", f, "RIGHT", -PAD, 0)
        if item.separator then
            r:SetHeight(SEP_H)
            r.label:SetText("")
            r.line:Show()
            NUL.SetTextureColor(r.line, t.colors.border.subtle)
            r:EnableMouse(false)
        else
            r:SetHeight(ROW_H)
            r.label:SetText(item.label or "")
            NUL.SetFontColor(r.label, textColor(t, item))
            r.line:Hide()
            r:EnableMouse(true)
            w = math.max(w, math.ceil(r.label:GetStringWidth()) + TEXT_PAD * 2 + PAD * 2)
        end
        NUL.SetTextureColor(r.hl, t.colors.bg.hover)
        r.hl:Hide()
        r:Show()
        y = y - r:GetHeight()
    end
    for i = #f.items + 1, #f.rows do f.rows[i]:Hide() end
    f:SetSize(w, -y + PAD)
end

function NUL:ShowMenu(owner, items, opts)
    opts = opts or {}
    local f = buildPopup()
    local t = self:GetTheme()
    NUL.SetTextureColor(f.bg, t.colors.bg.base)
    NUL:RecolorBorder(f.borders, t.colors.border.subtle)

    f.items = items or {}
    f.owner = owner
    local minWidth = opts.minWidth
        or (opts.anchor ~= "cursor" and owner and owner:GetWidth() * (owner:GetEffectiveScale() / f:GetEffectiveScale()))
        or 140
    layout(f, minWidth)

    f:ClearAllPoints()
    if opts.anchor == "cursor" then
        local x, y = GetCursorPosition()
        local s = f:GetEffectiveScale()
        f:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x / s, y / s)
    elseif owner then
        f:SetPoint("TOPLEFT", owner, "BOTTOMLEFT", 0, -2)
    else
        f:SetPoint("CENTER")
    end

    -- Close with the owner (its window closing, a tab switch).
    if owner and not owner._nulMenuHooked then
        owner._nulMenuHooked = true
        owner:HookScript("OnHide", function(self)
            if menu and menu.owner == self then menu:Hide() end
        end)
    end

    f:Show()
    f:Raise()
    if C_Timer and C_Timer.After then
        C_Timer.After(0, function()
            if f:IsShown() and f.items == items then layout(f, minWidth) end
        end)
    end
    return f
end

function NUL:HideMenu()
    if menu then menu:Hide() end
end

function NUL:IsMenuShownFor(owner)
    return menu ~= nil and menu:IsShown() and menu.owner == owner
end

-- ─── MenuButton ─────────────────────────────────────────────────────────

function NUL:MenuButton(parent, opts)
    opts = opts or {}
    local o = {}
    for k, v in pairs(opts) do o[k] = v end
    o.onClick = nil
    local b = self:Button(parent, o)

    local arrow = b:CreateTexture(nil, "OVERLAY")
    arrow:SetSize(10, 10)
    arrow:SetPoint("RIGHT", -7, 0)
    arrow:SetTexture(self:ResolveIcon(opts.arrowIcon or "arrow-down.png"))
    b.arrow = arrow

    -- The label moves left by half the chevron's room, and the button is
    -- that much wider than a plain one would be.
    local baseRepaint, baseFit = b._repaint, b._FitLabel
    function b:_repaint(t)
        baseRepaint(self, t)
        local down = self._pressed and self._enabled
        self.label:ClearAllPoints()
        self.label:SetPoint("CENTER", -CHEVRON / 2 + (down and 1 or 0), down and -1 or 0)
        local c = NUL:ResolveButtonColors(self._style, self._enabled and "normal" or "disabled", t).text
        if c then self.arrow:SetVertexColor(c.r, c.g, c.b, self._enabled and 1 or 0.6) end
    end
    function b:_FitLabel()
        baseFit(self)
        local need = math.ceil(self.label:GetStringWidth()) + 24 + CHEVRON
        if need > self:GetWidth() then self:SetWidth(need) end
    end

    b:SetScript("OnClick", function(self)
        if not self._enabled then return end
        if NUL:IsMenuShownFor(self) then
            NUL:HideMenu()
            return
        end
        local items = opts.items
        if type(items) == "function" then items = items(self) end
        NUL:ShowMenu(self, items or {}, { anchor = "below" })
    end)

    b:_repaint(self:GetTheme())
    b:_FitLabel()
    return b
end
