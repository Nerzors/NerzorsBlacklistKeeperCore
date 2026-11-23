local _, NBK = ...
local Config = NBK:GetModule("Config")
if not Config then return end

local NUL = LibStub("NerzorsUILib-1.0")

function Config:SelectTab(key)
    for k, panel in pairs(self._panels or {}) do
        panel:SetShown(k == key)
    end
    for k, btn in pairs(self._navButtons or {}) do
        btn:SetSelected(k == key)
    end
    self._activeTab = key
end

function Config:_makeSectionHeader(parent, text)
    local theme = NUL:GetTheme()
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(self.NAV_WIDTH - 16, self.NAV_SECTION_HEAD_H)

    local label = NUL:CreateLabel(frame, {
        text     = (text or ""):upper(),
        size     = "sm",
        color    = theme.colors.accent.primary,
        justifyH = "LEFT",
    })
    label:SetPoint("LEFT",  4, 0)
    label:SetPoint("RIGHT", -4, 0)
    frame.label = label

    local rule = frame:CreateTexture(nil, "ARTWORK")
    rule:SetHeight(1)
    rule:SetPoint("BOTTOMLEFT",  4, 2)
    rule:SetPoint("BOTTOMRIGHT", -4, 2)
    NUL.SetTextureColor(rule, NUL.WithAlpha(theme.colors.border.subtle, 0.5))

    return frame
end

function Config.NavLabelCut(fs)
    if not fs then return false end
    if fs.IsTruncated then
        local ok, cut = pcall(fs.IsTruncated, fs)
        if ok then return cut and true or false end
    end
    local tw, w = tonumber(fs:GetStringWidth()) or 0, tonumber(fs:GetWidth()) or 0
    return w > 0 and tw > w + 0.5
end

function Config:_makeNavButton(parent, text, iconPath)
    local theme = NUL:GetTheme()
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(self.NAV_WIDTH - 16, self.NAV_BTN_HEIGHT)

    b.bg = NUL:FillBackground(b, NUL:SurfaceColor("navItem", theme))

    local icon, labelLeftX
    if iconPath and iconPath ~= "" then
        icon = b:CreateTexture(nil, "ARTWORK")
        icon:SetSize(18, 18)
        icon:SetPoint("LEFT", 8, 0)
        icon:SetTexture(NUL:ResolveIcon(iconPath))
        b.icon = icon
        labelLeftX = 32
    else
        labelLeftX = 12
    end

    b.label = NUL:CreateLabel(b, {
        text     = text,
        justifyH = "LEFT",
        wrap     = false,
    })
    b.label:SetPoint("LEFT",  labelLeftX, 0)
    b.label:SetPoint("RIGHT", -4, 0)

    local accent = b:CreateTexture(nil, "OVERLAY")
    accent:SetSize(3, 20)
    accent:SetPoint("LEFT", 0, 0)
    NUL.SetTextureColor(accent, theme.colors.accent.primary)
    accent:Hide()
    b.accent = accent

    b._selected = false
    local function refresh()
        local t = NUL:GetTheme()
        if b._selected then
            NUL.SetTextureColor(b.bg, t.colors.bg.hover)
            accent:Show()
            NUL.SetTextureColor(accent, t.colors.accent.primary)
            NUL.SetFontColor(b.label, t.colors.text.primary)
            if icon then icon:SetVertexColor(1, 1, 1, 1) end
        else
            NUL.SetTextureColor(b.bg, NUL:SurfaceColor("navItem", t))
            accent:Hide()
            NUL.SetFontColor(b.label, t.colors.text.muted)

            if icon then icon:SetVertexColor(0.75, 0.75, 0.78, 1) end
        end
    end
    function b:SetSelected(v) self._selected = v and true or false; refresh() end

    NUL:RegisterCustomPainter(b, function() refresh() end)
    refresh()

    b:SetScript("OnEnter", function(self)
        if not self._selected then
            NUL.SetTextureColor(self.bg, NUL:GetTheme().colors.bg.panel)
            if icon then icon:SetVertexColor(1, 1, 1, 1) end
        end

        if Config.NavLabelCut(self.label) and GameTooltip then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(self.label:GetText() or "", 1, 1, 1)
            GameTooltip:Show()
            self._tip = true
        end
    end)
    b:SetScript("OnLeave", function(self)
        if self._tip and GameTooltip then GameTooltip:Hide() end
        self._tip = nil
        refresh()
    end)

    return b
end

local ALERT_ICON = "Interface\\DialogFrame\\UI-Dialog-Icon-AlertNew"

local function accentName(name)
    return "|cff" .. NUL.ToHex(NUL:GetTheme().colors.accent.primary) .. name .. "|r"
end

function Config:_makeExternalNotice(parent, tab)
    local L = NBK.L
    local f = CreateFrame("Frame", nil, parent)
    f:SetHeight(44)
    f.bg = f:CreateTexture(nil, "BACKGROUND")
    f.bg:SetAllPoints()
    f.borders = NUL:AddBorder(f, nil, 1)

    local icon = f:CreateTexture(nil, "ARTWORK")
    icon:SetSize(24, 24)
    icon:SetPoint("LEFT", 10, 0)
    icon:SetTexture(ALERT_ICON)

    local name = self:ExternalName(tab)
    local text = NUL:CreateLabel(f, {
        text     = "",
        justifyH = "LEFT",
        wrap     = true,
    })
    text:SetPoint("LEFT", icon, "RIGHT", 10, 0)
    text:SetPoint("RIGHT", f, "RIGHT", -10, 0)
    f.text = text

    local function paint()
        local t = NUL:GetTheme()
        local warn = (t.colors.state and t.colors.state.warning) or t.colors.accent.primary
        NUL.SetTextureColor(f.bg, NUL.WithAlpha(warn, 0.14))
        NUL:RecolorBorder(f.borders, NUL.WithAlpha(warn, 0.7))
        NUL.SetFontColor(text, t.colors.text.primary)
        text:SetText((L["%s is an external module. It was not made by the NBK team, so we can't give support for it."])
            :format(accentName(name)))
    end
    local function fit()
        local h = (text:GetStringHeight() or 0) + 18
        f:SetHeight(math.max(44, math.ceil(h)))
    end
    f:SetScript("OnSizeChanged", fit)
    NUL:RegisterCustomPainter(f, function() paint(); fit() end)
    paint(); fit()
    return f
end

function Config:_markExternalSection(panel, y, section)
    local L = NBK.L
    local t = NUL:GetTheme()
    local warn = (t.colors.state and t.colors.state.warning) or t.colors.accent.primary
    local line = NUL:CreateLabel(panel, {
        text  = "|T" .. ALERT_ICON .. ":14:14|t " .. (L["External module: %s"]):format(accentName(self:ExternalName(section))),
        size  = "sm",
        color = warn,
    })
    line:SetPoint("TOPLEFT", 0, y - 6)
    return y - 26
end

function Config:_runSections(tabKey, panel)
    local list = self._sections[tabKey]
    if not list or #list == 0 then return end
    table.sort(list, function(a, b) return (a.order or 100) < (b.order or 100) end)
    for _, section in ipairs(list) do
        if self.IsExternalSection and self:IsExternalSection(section) then
            panel.lastY = self:_markExternalSection(panel, panel.lastY or 0, section)
        end
        local startY = panel.lastY or 0
        local ok, newY = pcall(section.build, panel, startY)
        if ok and type(newY) == "number" then
            panel.lastY = newY
        elseif not ok then
            NBK:Print("section builder failed for tab '" .. tabKey .. "': " .. tostring(newY))
        end
    end
end
