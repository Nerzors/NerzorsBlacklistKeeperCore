-- NerzorsUILib-1.0 :: Widgets/Tabs.lua
-- Tab strip with optional content stack. Two orientations:
--   "top":  horizontal strip across the top of the content area.
--   "left": vertical strip down the left side.
--
-- opts:
--   parent       Frame
--   orientation  "top" | "left"   Default "top".
--   tabWidth     number  (left orient)  Default 140.
--   tabHeight    number  (top orient)   Default 26.
--   tabs         array  { { key, label, icon, build }, ... }
--   onChange     function(key, panel, tabs)
--   active       string  Initial active key. Default tabs[1].key.

local NUL = LibStub("NerzorsUILib-1.0")

function NUL:Tabs(parent, opts)
    opts = opts or {}
    local theme       = self:GetTheme()
    local orientation = opts.orientation or "top"
    local tabWidth    = opts.tabWidth  or 140
    local tabHeight   = opts.tabHeight or 26
    local tabsDef     = opts.tabs or {}

    local strip   = CreateFrame("Frame", nil, parent)
    local content = CreateFrame("Frame", nil, parent)

    if orientation == "left" then
        strip:SetPoint("TOPLEFT")
        strip:SetPoint("BOTTOMLEFT")
        strip:SetWidth(tabWidth)
        content:SetPoint("TOPLEFT",     strip, "TOPRIGHT", 6, 0)
        content:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT")
    else
        strip:SetPoint("TOPLEFT")
        strip:SetPoint("TOPRIGHT")
        strip:SetHeight(tabHeight)
        content:SetPoint("TOPLEFT",     strip, "BOTTOMLEFT",  0, -6)
        content:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT")
    end

    local self_ = {
        strip   = strip,
        content = content,
        _tabs   = {},
        _order  = {},
        _active = nil,
    }

    local function styleTab(btn, active)
        local t = NUL:GetTheme()
        NUL.SetTextureColor(btn.bg, active and t.colors.bg.hover or t.colors.bg.panel)
        NUL:RecolorBorder(btn.borders,
            active and t.colors.border.accent or t.colors.border.subtle)
        if btn.accentStripe then
            btn.accentStripe:SetShown(active)
            NUL.SetTextureColor(btn.accentStripe, t.colors.accent.primary)
        end
        NUL.SetFontColor(btn.label, active and t.colors.text.primary or t.colors.text.muted)
    end

    local function buildTabButton(def, index)
        local b = CreateFrame("Button", nil, strip)
        if orientation == "left" then
            b:SetSize(tabWidth, tabHeight)
            b:SetPoint("TOPLEFT", 0, -((index - 1) * (tabHeight + 2)))
        else
            b:SetHeight(tabHeight)
        end
        b.bg      = NUL:FillBackground(b)
        b.borders = NUL:AddBorder(b, nil, theme.metrics.borderThickness)
        b.label   = NUL:CreateLabel(b, {
            text     = def.label or def.key or "",
            justifyH = "CENTER",
        })
        b.label:SetPoint("CENTER", 0, 0)

        local stripe = b:CreateTexture(nil, "OVERLAY")
        b.accentStripe = stripe
        if orientation == "left" then
            stripe:SetWidth(2)
            stripe:SetPoint("TOPLEFT");    stripe:SetPoint("BOTTOMLEFT")
        else
            stripe:SetHeight(2)
            stripe:SetPoint("BOTTOMLEFT"); stripe:SetPoint("BOTTOMRIGHT")
        end
        stripe:Hide()

        if orientation ~= "left" then
            local w = math.max(80, b.label:GetStringWidth() + 24)
            b:SetWidth(w)
        end

        b:SetScript("OnClick", function() self_:SetActive(def.key) end)
        b:SetScript("OnEnter", function(self)
            if self_._active ~= def.key then
                NUL.SetTextureColor(self.bg, NUL:GetTheme().colors.bg.hover)
            end
        end)
        b:SetScript("OnLeave", function() styleTab(b, self_._active == def.key) end)

        return b
    end

    local function layoutTopTabs()
        local x = 0
        for _, key in ipairs(self_._order) do
            local entry = self_._tabs[key]
            entry.btn:ClearAllPoints()
            entry.btn:SetPoint("TOPLEFT", strip, "TOPLEFT", x, 0)
            x = x + entry.btn:GetWidth() + 2
        end
    end

    for i, def in ipairs(tabsDef) do
        local btn   = buildTabButton(def, i)
        local panel = CreateFrame("Frame", nil, content)
        panel:SetAllPoints()
        panel:Hide()
        self_._tabs[def.key] = { btn = btn, panel = panel, build = def.build, opts = def, built = false }
        table.insert(self_._order, def.key)
    end
    if orientation ~= "left" then layoutTopTabs() end

    function self_:SetActive(key)
        local entry = self._tabs[key]
        if not entry then return end
        if self._active == key and entry.panel:IsShown() then return end
        if self._active and self._tabs[self._active] then
            self._tabs[self._active].panel:Hide()
            styleTab(self._tabs[self._active].btn, false)
        end
        self._active = key
        entry.panel:Show()
        styleTab(entry.btn, true)
        if not entry.built and type(entry.build) == "function" then
            entry.built = true
            local ok, err = pcall(entry.build, entry.panel, key)
            if not ok then print("|cffff5555Tab build error:|r", tostring(err)) end
        end
        if opts.onChange then opts.onChange(key, entry.panel, self) end
    end

    function self_:GetActive()    return self._active end
    function self_:GetPanel(key)  return self._tabs[key] and self._tabs[key].panel end
    function self_:GetButton(key) return self._tabs[key] and self._tabs[key].btn end

    function self_:_repaint(t)
        for key, entry in pairs(self._tabs) do
            styleTab(entry.btn, self._active == key)
        end
    end
    NUL:_Track(self_)

    local first = opts.active or (tabsDef[1] and tabsDef[1].key)
    if first then self_:SetActive(first) end
    return self_
end
