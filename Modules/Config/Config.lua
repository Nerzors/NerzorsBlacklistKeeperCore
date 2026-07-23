local _, NBK = ...

local Config = NBK:RegisterModule("Config")

Config.NAV_WIDTH           = 175
Config.WINDOW_W            = 680
Config.WINDOW_H            = 460
Config.NAV_BTN_HEIGHT      = 26
Config.NAV_BTN_GAP         = 2
Config.NAV_SECTION_HEAD_H  = 22
Config.NAV_SECTION_GAP     = 4

Config._tabs     = Config._tabs     or {}
Config._sections = Config._sections or {}

function Config:RegisterTab(keyOrSpec, labelKey, buildFn, order)
    local spec
    if type(keyOrSpec) == "table" then
        spec = keyOrSpec
    else
        spec = { key = keyOrSpec, labelKey = labelKey, build = buildFn, order = order }
    end
    if not spec.key or type(spec.build) ~= "function" then return end
    spec.labelKey = spec.labelKey or spec.key
    spec.order    = spec.order    or 100
    spec.category = spec.category or "core"

    for i, t in ipairs(self._tabs) do
        if t.key == spec.key then
            self._tabs[i] = spec
            return
        end
    end
    table.insert(self._tabs, spec)
end

function Config:RegisterSection(tabKey, buildFn, order)
    if not tabKey or not buildFn then return end
    self._sections[tabKey] = self._sections[tabKey] or {}
    table.insert(self._sections[tabKey], { build = buildFn, order = order or 100 })
end

function Config:Build()
    if self.frame then return self.frame end
    local NUL = LibStub("NerzorsUILib-1.0")
    local L   = NBK.L
    local theme = NUL:GetTheme()

    local f = NUL:Window({
        name   = "NBKConfigWindow",
        title  = L["NBK - Settings"],
        width  = self.WINDOW_W,
        height = self.WINDOW_H,
        strata = "DIALOG",
        icon   = theme.media.logo,
    })
    f:SetFrameLevel(100)
    f:SetPositionKey("ConfigWindow", NBK.db)
    f:RestorePosition()
    self.frame = f

    local content = f.content

    local nav = CreateFrame("Frame", nil, content)
    nav:SetWidth(self.NAV_WIDTH)
    nav:SetPoint("TOPLEFT")
    nav:SetPoint("BOTTOMLEFT")
    NUL:FillBackground(nav, theme.colors.bg.elevated)

    local navDivider = content:CreateTexture(nil, "ARTWORK")
    navDivider:SetWidth(1)
    navDivider:SetPoint("TOPLEFT",    nav, "TOPRIGHT",    0, 0)
    navDivider:SetPoint("BOTTOMLEFT", nav, "BOTTOMRIGHT", 0, 0)
    NUL.SetTextureColor(navDivider, theme.colors.border.subtle)

    local body = CreateFrame("Frame", nil, content)
    body:SetPoint("TOPLEFT",     nav, "TOPRIGHT", 10, 0)
    body:SetPoint("BOTTOMRIGHT", 0, 0)

    self._navButtons = {}
    self._panels     = {}
    self._tabPanels  = {}

    local groups, groupOrder = {}, { "core", "modules" }
    local seenGroups = { core = true, modules = true }
    for _, tab in ipairs(self._tabs) do
        local cat = tab.category or "core"
        if not seenGroups[cat] then
            table.insert(groupOrder, cat)
            seenGroups[cat] = true
        end
        groups[cat] = groups[cat] or {}
        table.insert(groups[cat], tab)
    end
    for _, list in pairs(groups) do
        table.sort(list, function(a, b) return (a.order or 100) < (b.order or 100) end)
    end

    local sectionLabels = {
        core    = L["Core"]    or "Core",
        modules = L["Modules"] or "Modules",
    }

    local SCROLLBAR_GAP = 22

    local navY  = -8
    local first = true
    for _, cat in ipairs(groupOrder) do
        local list = groups[cat]
        if list and #list > 0 then
            if not first then navY = navY - self.NAV_SECTION_GAP end
            first = false

            local header = self:_makeSectionHeader(nav, sectionLabels[cat] or cat)
            header:SetPoint("TOPLEFT", 8, navY)
            navY = navY - self.NAV_SECTION_HEAD_H

            for _, tab in ipairs(list) do
                local btn = self:_makeNavButton(nav, L[tab.labelKey], tab.icon)
                btn:SetPoint("TOPLEFT", 8, navY)
                btn:SetScript("OnClick", function() self:SelectTab(tab.key) end)
                self._navButtons[tab.key] = btn

                local scroll = CreateFrame("ScrollFrame", nil, body, "UIPanelScrollFrameTemplate")
                scroll:SetPoint("TOPLEFT",     body, "TOPLEFT",     0, 0)
                scroll:SetPoint("BOTTOMRIGHT", body, "BOTTOMRIGHT", -SCROLLBAR_GAP, 0)

                local scrollContent = CreateFrame("Frame", nil, scroll)
                scrollContent:SetSize(1, 1)
                scroll:SetScrollChild(scrollContent)

                NUL:_AttachThemedScrollBar(scroll, body)

                local function syncWidth()
                    local w = scroll:GetWidth()
                    if w and w > 1 then scrollContent:SetWidth(w) end
                end
                scroll:HookScript("OnSizeChanged", syncWidth)
                syncWidth()

                local panel = tab.build(scrollContent)
                self._panels[tab.key]    = scroll
                self._tabPanels[tab.key] = panel

                self:_runSections(tab.key, panel)

                local function syncHeight()
                    local h = math.abs(panel.lastY or -200) + 12
                    scrollContent:SetHeight(h)
                end
                syncHeight()
                panel._syncScrollHeight = syncHeight

                scroll:Hide()
                navY = navY - (self.NAV_BTN_HEIGHT + self.NAV_BTN_GAP)
            end
        end
    end

    self:SelectTab("Display")
    return f
end

function Config:Show()
    self:Build()
    self.frame:Show()
end

function Config:Toggle()
    self:Build()
    if self.frame:IsShown() then self.frame:Hide() else self.frame:Show() end
end
