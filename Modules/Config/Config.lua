local _, NBK = ...

local Config = NBK:RegisterModule("Config")

Config.NAV_WIDTH           = 200

Config.WINDOW_W            = 755
Config.WINDOW_H            = 460
Config.NAV_BTN_HEIGHT      = 26
Config.NAV_BTN_GAP         = 2
Config.NAV_SECTION_HEAD_H  = 22
Config.NAV_SECTION_GAP     = 4

Config.WINDOW_MAX_H        = 800
Config.NAV_BOTTOM_PAD      = 8
Config.NAV_SCROLL_GUTTER   = 16

function Config:FitHeight(navH, chrome, maxH)
    local cap = self.WINDOW_MAX_H
    if maxH and maxH > 0 and maxH < cap then cap = maxH end
    local want = math.max(self.WINDOW_H, math.ceil(navH + chrome))
    if want <= cap then return want, false end
    return math.max(self.WINDOW_H, math.floor(cap)), true
end

Config._tabs     = Config._tabs     or {}
Config._sections = Config._sections or {}

Config.CORE_TABS = { Display = true, Tooltip = true, Notifications = true, Presets = true, Advanced = true }
local CORE_FOLDER = "NerzorsBlacklistKeeper"

function Config._CallerFolder(level)
    if type(debugstack) ~= "function" then return nil end
    local ok, stack = pcall(debugstack, level or 3, 1, 0)
    if not ok or type(stack) ~= "string" then return nil end
    return stack:match("[Aa]dd[Oo]ns[/\\]([^/\\\"%]]+)[/\\]")
end

function Config._IsOfficialFolder(folder)
    if folder == CORE_FOLDER or folder == CORE_FOLDER .. "_Data" then return true end
    for _, m in ipairs(NBK.OPTIONAL_MODULES or {}) do
        if folder == CORE_FOLDER .. m.tag then return true end
    end
    return false
end

function Config._IsOfficialTabKey(key)
    if Config.CORE_TABS[key] then return true end
    for _, m in ipairs(NBK.OPTIONAL_MODULES or {}) do
        if m.configTab and m.configTab == key then return true end
    end
    return false
end

local function folderOf(spec)
    if spec._origin then return spec._origin end
    for addonName, db in pairs(NBK._subAddons or {}) do
        if type(db) == "table" and db.key == spec.key then return addonName end
    end
    return nil
end

function Config:IsExternalTab(spec)
    if not Config._IsOfficialTabKey(spec.key) then return true end
    local folder = folderOf(spec)
    return folder ~= nil and not Config._IsOfficialFolder(folder)
end

function Config:IsExternalSection(section)
    return section._origin ~= nil and not Config._IsOfficialFolder(section._origin)
end

function Config:ExternalName(specOrSection)
    local L = NBK.L
    if specOrSection.labelKey then
        local label = L and L[specOrSection.labelKey] or specOrSection.labelKey
        if type(label) == "string" and label ~= "" then return label end
    end
    local folder = specOrSection._origin or (specOrSection.key and folderOf(specOrSection))
    if not folder then return "?" end
    local getMeta = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
    local title = getMeta and select(2, pcall(getMeta, folder, "Title")) or nil
    if type(title) == "string" and title ~= "" then
        title = title:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
        if title ~= "" then return title end
    end
    return folder
end

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

    spec._origin  = Config._CallerFolder(3)

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
    table.insert(self._sections[tabKey], {
        build = buildFn, order = order or 100,
        _origin = Config._CallerFolder(3),
    })
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
    NUL:Surface(nav, "sidebar")

    local navScroll = CreateFrame("ScrollFrame", nil, nav)
    navScroll:SetPoint("TOPLEFT")
    navScroll:SetPoint("BOTTOMRIGHT")
    local navInner = CreateFrame("Frame", nil, navScroll)
    navInner:SetSize(self.NAV_WIDTH, 1)
    navScroll:SetScrollChild(navInner)

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
    local seenGroups = { core = true, modules = true, external = true }
    for _, tab in ipairs(self._tabs) do
        tab._external = self:IsExternalTab(tab)
        local cat = tab._external and "external" or (tab.category or "core")
        if cat == "external" and not tab._external then cat = "modules" end
        if not seenGroups[cat] then
            table.insert(groupOrder, cat)
            seenGroups[cat] = true
        end
        groups[cat] = groups[cat] or {}
        table.insert(groups[cat], tab)
    end
    table.insert(groupOrder, "external")
    for _, list in pairs(groups) do
        table.sort(list, function(a, b) return (a.order or 100) < (b.order or 100) end)
    end

    local sectionLabels = {
        core     = L["Core"]    or "Core",
        modules  = L["Modules"] or "Modules",
        external = L["External modules"] or "External modules",
    }

    local SCROLLBAR_GAP = 22

    local navY  = -8
    local first = true
    for _, cat in ipairs(groupOrder) do
        local list = groups[cat]
        if list and #list > 0 then
            if not first then navY = navY - self.NAV_SECTION_GAP end
            first = false

            local header = self:_makeSectionHeader(navInner, sectionLabels[cat] or cat)
            header:SetPoint("TOPLEFT", 8, navY)
            navY = navY - self.NAV_SECTION_HEAD_H

            for _, tab in ipairs(list) do
                local btn = self:_makeNavButton(navInner, L[tab.labelKey], tab.icon)
                btn:SetPoint("TOPLEFT", 8, navY)
                btn:SetScript("OnClick", function() self:SelectTab(tab.key) end)
                self._navButtons[tab.key] = btn

                local scroll = CreateFrame("ScrollFrame", nil, body, "UIPanelScrollFrameTemplate")

                local notice = tab._external and self:_makeExternalNotice(body, tab) or nil
                if notice then
                    notice:SetPoint("TOPLEFT",  body, "TOPLEFT",  0, 0)
                    notice:SetPoint("TOPRIGHT", body, "TOPRIGHT", -SCROLLBAR_GAP, 0)
                    scroll:SetPoint("TOPLEFT", notice, "BOTTOMLEFT", 0, -8)
                    scroll:HookScript("OnShow", function() notice:Show() end)
                    scroll:HookScript("OnHide", function() notice:Hide() end)
                    notice:Hide()
                else
                    scroll:SetPoint("TOPLEFT", body, "TOPLEFT", 0, 0)
                end
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

    local navH = -navY + self.NAV_BOTTOM_PAD
    navInner:SetHeight(navH)
    local m = theme.metrics or {}
    local chrome = 1 + (m.titleBarHeight or 32) + 2 * (m.windowPadding or 10)
    local ui = UIParent and UIParent:GetHeight() or 0
    local k = (UIParent and UIParent:GetEffectiveScale() or 1) > 0
        and (f:GetEffectiveScale() / UIParent:GetEffectiveScale()) or 1
    local screenH = (ui > 0 and k > 0) and (ui / k - 40) or nil
    local h, scrolls = self:FitHeight(navH, chrome, screenH)
    f:SetHeight(h)
    if scrolls then
        nav:SetWidth(self.NAV_WIDTH + self.NAV_SCROLL_GUTTER)
        navScroll:SetPoint("BOTTOMRIGHT", -self.NAV_SCROLL_GUTTER, 0)
        NUL:_AttachThemedScrollBar(navScroll, nav)
    end
    self._navHeight, self._navScrolls = navH, scrolls

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
