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

function Config:_makeNavButton(parent, text, iconPath)
    local theme = NUL:GetTheme()
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(self.NAV_WIDTH - 16, self.NAV_BTN_HEIGHT)

    b.bg = NUL:FillBackground(b, theme.colors.bg.base)

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
            b.label:SetTextColor(1, 1, 1, 1)
            if icon then icon:SetVertexColor(1, 1, 1, 1) end
        else
            NUL.SetTextureColor(b.bg, t.colors.bg.base)
            accent:Hide()
            NUL.SetFontColor(b.label, t.colors.text.muted)

            if icon then icon:SetVertexColor(0.75, 0.75, 0.78, 1) end
        end
    end
    function b:SetSelected(v) self._selected = v and true or false; refresh() end
    refresh()

    b:SetScript("OnEnter", function(self)
        if not self._selected then
            NUL.SetTextureColor(self.bg, NUL:GetTheme().colors.bg.panel)
            if icon then icon:SetVertexColor(1, 1, 1, 1) end
        end
    end)
    b:SetScript("OnLeave", function() refresh() end)

    return b
end

function Config:_runSections(tabKey, panel)
    local list = self._sections[tabKey]
    if not list or #list == 0 then return end
    table.sort(list, function(a, b) return (a.order or 100) < (b.order or 100) end)
    for _, section in ipairs(list) do
        local startY = panel.lastY or 0
        local ok, newY = pcall(section.build, panel, startY)
        if ok and type(newY) == "number" then
            panel.lastY = newY
        elseif not ok then
            NBK:Print("section builder failed for tab '" .. tabKey .. "': " .. tostring(newY))
        end
    end
end
