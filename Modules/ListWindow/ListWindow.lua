local _, NBK = ...
local NUL = LibStub("NerzorsUILib-1.0")
local L   = NBK.L

local ListWindow = NBK:RegisterModule("ListWindow")

local TAB_HEIGHT = 26
local TAB_GAP    = 4
local TAB_PAD    = 14

ListWindow._tabs       = {}
ListWindow._tabOrder   = {}
ListWindow._tabFrames  = {}
ListWindow._tabButtons = {}
ListWindow._activeTab  = nil

function ListWindow:RegisterTab(spec)
    if type(spec) ~= "table" or type(spec.key) ~= "string" then return end
    if type(spec.build) ~= "function" then return end
    if self._tabs[spec.key] then return end
    spec.order = spec.order or 50
    self._tabs[spec.key] = spec
    table.insert(self._tabOrder, spec.key)
    table.sort(self._tabOrder, function(a, b)
        return (self._tabs[a].order or 50) < (self._tabs[b].order or 50)
    end)

    if self.frame then self:_RebuildTabBar() end
end

function ListWindow:GetActiveTab() return self._activeTab end

function ListWindow:GetActiveTabSpec()
    return self._activeTab and self._tabs[self._activeTab] or nil
end

function ListWindow:GetTabSpec(key)
    return self._tabs[key]
end

function ListWindow:Build()
    if self.frame then return self.frame end
    local theme = NUL:GetTheme()

    local LOGO_MODE       = "absolute"
    local LOGO_ANCHOR     = "TOPLEFT"
    local LOGO_SIZE       = 64
    local LOGO_OFFSET     = { x = -16, y = 22 }
    local LOGO_TITLE_LEFT = 46

    local f = NUL:Window({
        name   = "NBKListWindow",
        title  = L["Nerzors Blacklist Keeper"],
        width  = 920, height = 560,
        logo   = {
            path       = theme.media.logo,
            mode       = LOGO_MODE,
            anchor     = LOGO_ANCHOR,
            size       = LOGO_SIZE,
            offset     = LOGO_OFFSET,
            titleInset = LOGO_TITLE_LEFT,
        },
    })
    self.frame = f
    f:SetPositionKey("ListWindow", NBK.db)
    f:MakeResizable({ minW = 700, minH = 420, maxW = 1600, maxH = 1100 })
    f:RestorePosition()

    self._resizeDirty = false
    f:HookScript("OnSizeChanged", function()
        if self._resizeDirty then return end
        self._resizeDirty = true
        if C_Timer and C_Timer.After then
            C_Timer.After(0.05, function()
                self._resizeDirty = false
                self:Refresh()
            end)
        else
            self._resizeDirty = false
            self:Refresh()
        end
    end)

    local settingsBtn = NUL:IconButton(f.titleBar, {
        icon    = "cog.png",
        size    = 22,
        plain   = true,
        tooltip = L["Settings"],
        onClick = function()
            local cfg = NBK:GetModule("Config")
            if cfg then cfg:Toggle() end
        end,
    })
    settingsBtn:SetPoint("RIGHT", f.closeButton, "LEFT", -4, 0)

    local content = f.content

    local tabBar = CreateFrame("Frame", nil, content)
    tabBar:SetHeight(TAB_HEIGHT)
    tabBar:SetPoint("TOPLEFT")
    tabBar:SetPoint("TOPRIGHT")
    self.tabBar = tabBar

    local divider = tabBar:CreateTexture(nil, "ARTWORK")
    divider:SetHeight(1)
    divider:SetPoint("BOTTOMLEFT",  tabBar, "BOTTOMLEFT",  0, -1)
    divider:SetPoint("BOTTOMRIGHT", tabBar, "BOTTOMRIGHT", 0, -1)
    NUL.SetTextureColor(divider, NUL.WithAlpha(theme.colors.border.subtle, 0.5))
    self.tabDivider = divider

    local FOOTER_H = 20
    local footerHost = CreateFrame("Frame", nil, content)
    footerHost:SetHeight(FOOTER_H)
    footerHost:SetPoint("BOTTOMLEFT",  content, "BOTTOMLEFT",  0, 0)
    footerHost:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", 0, 0)
    self.footerHost = footerHost

    local tabContent = CreateFrame("Frame", nil, content)
    tabContent:SetPoint("TOPLEFT",     tabBar,     "BOTTOMLEFT", 0, -8)
    tabContent:SetPoint("BOTTOMRIGHT", footerHost, "TOPRIGHT",   0, 2)
    self.tabContent = tabContent

    self:_RebuildFooter()

    self:_RebuildTabBar()

    local target = self:_PickInitialTab()
    if target then self:SwitchTab(target) end

    return f
end

local SOCIAL_POPUP_ID = "NBK_OPEN_URL"
StaticPopupDialogs[SOCIAL_POPUP_ID] = {
    text         = "%s",
    button1      = OKAY or "OK",
    hasEditBox   = true,
    editBoxWidth = 320,
    timeout      = 0,
    whileDead    = true,
    hideOnEscape = true,
    preferredIndex = 3,
    OnShow = function(self, data)

        local eb = self.editBox or self.EditBox
        if eb then
            eb:SetText(data and data.url or "")
            eb:HighlightText()
            eb:SetFocus()
        end
    end,
    EditBoxOnEscapePressed = function(self) self:GetParent():Hide() end,
    EditBoxOnEnterPressed  = function(self) self:GetParent():Hide() end,
}

local function showUrlPopup(label, url)
    StaticPopup_Show(SOCIAL_POPUP_ID, label, nil, { url = url })
end

function ListWindow:_RebuildFooter()
    local host = self.footerHost
    if not host then return end

    if self._footerChildren then
        for _, c in ipairs(self._footerChildren) do
            c:Hide()
            c:ClearAllPoints()
            c:SetParent(nil)
        end
    end
    self._footerChildren = {}

    local theme  = NUL:GetTheme()
    local footer = NBK.FOOTER or {}

    local function on(key) return footer[key] ~= false end

    local L = NBK.L

    local chunks = {}

    if on("showCredits") then
        local txt = L["Created by Nerzors-Eredar (www.nerzors.de)"]
                  or "Created by Nerzors-Eredar (www.nerzors.de)"
        table.insert(chunks, {
            kind = "label", text = txt,
            build = function(parent)
                return NUL:CreateLabel(parent, {
                    text = txt, size = "sm",
                    color = theme.colors.text.muted,
                })
            end,
        })
    end

    if on("showVersion") then
        local txt = (L["Version: %s"] or "Version: %s")
            :format("2.0.0-dev." .. tostring(NBK.version))
        table.insert(chunks, {
            kind = "label", text = txt,
            build = function(parent)
                return NUL:CreateLabel(parent, {
                    text = txt, size = "sm",
                    color = theme.colors.text.muted,
                })
            end,
        })
    end

    for _, link in ipairs(NBK.SOCIAL_LINKS or {}) do
        if link.enabled ~= false then
            table.insert(chunks, {
                kind  = "icon",
                build = function(parent)
                    local btn = NUL:IconButton(parent, {
                        icon    = link.icon,
                        size    = 18,
                        tooltip = link.tooltip or link.id,
                        onClick = function()
                            showUrlPopup(link.tooltip or link.id, link.url or "")
                        end,
                    })
                    return btn
                end,
            })
        end
    end

    if #chunks == 0 then return end

    local GAP_TEXT = 8
    local GAP_ICON = 4
    local SEP      = "  |cff666666•|r  "

    local realised = {}
    for i, ch in ipairs(chunks) do
        local frame = ch.build(host)
        realised[i] = { frame = frame, kind = ch.kind }
        table.insert(self._footerChildren, frame)
    end

    local laid = {}
    for i, r in ipairs(realised) do
        local prev = laid[#laid]
        if prev and prev.kind == "label" and r.kind == "label" then
            local sepFS = NUL:CreateLabel(host, {
                text = SEP, size = "sm", color = theme.colors.text.muted,
            })
            table.insert(self._footerChildren, sepFS)
            table.insert(laid, { frame = sepFS, kind = "sep" })
        end
        table.insert(laid, r)
    end

    local function applyLayout()

        local total = 0
        for i, r in ipairs(laid) do
            local w
            if r.kind == "icon" then
                w = r.frame:GetWidth() or 0
            else
                w = r.frame:GetStringWidth() or 0
            end
            total = total + w
            if i < #laid then
                local next_ = laid[i + 1]

                local gap = (r.kind == "icon" and next_.kind == "icon") and GAP_ICON or GAP_TEXT
                total = total + gap
            end
        end

        local startX = -math.floor(total / 2)
        local prev
        for i, r in ipairs(laid) do
            r.frame:ClearAllPoints()
            if not prev then
                r.frame:SetPoint("LEFT", host, "CENTER", startX, 0)
            else
                local prevR = laid[i - 1]
                local gap = (prevR.kind == "icon" and r.kind == "icon") and GAP_ICON or GAP_TEXT
                r.frame:SetPoint("LEFT", prev, "RIGHT", gap, 0)
            end
            prev = r.frame
        end
    end

    applyLayout()
    if C_Timer and C_Timer.After then C_Timer.After(0, applyLayout) end
end

function ListWindow:_PickInitialTab()
    local s = NBK.db and NBK.db.settings and NBK.db.settings.display or {}
    local pref = s.defaultTab or "blacklist"
    if self._tabs[pref] then return pref end
    return self._tabOrder[1]
end

function ListWindow:_RebuildTabBar()
    if not self.tabBar then return end

    for _, btn in pairs(self._tabButtons) do btn:Hide() end

    local x = 0
    for _, key in ipairs(self._tabOrder) do
        local spec = self._tabs[key]
        local btn = self._tabButtons[key]
        if not btn then
            btn = self:_BuildTabButton(spec)
            self._tabButtons[key] = btn
        end
        btn:Show()
        btn:ClearAllPoints()
        btn:SetPoint("BOTTOMLEFT", self.tabBar, "BOTTOMLEFT", x, 0)
        x = x + btn:GetWidth() + TAB_GAP
        btn:SetActive(self._activeTab == key)
    end
end

function ListWindow:_BuildTabButton(spec)
    local theme = NUL:GetTheme()
    local labelText = L[spec.labelKey] or spec.labelKey or spec.key

    local btn = CreateFrame("Button", nil, self.tabBar)
    btn:SetHeight(TAB_HEIGHT)

    local lbl = NUL:CreateLabel(btn, { text = labelText, justifyH = "CENTER" })
    lbl:SetPoint("LEFT",  TAB_PAD, 0)
    lbl:SetPoint("RIGHT", -TAB_PAD, 0)
    btn._label = lbl

    local w = math.max(80, lbl:GetStringWidth() + TAB_PAD * 2)
    btn:SetWidth(w)

    btn.bg = NUL:FillBackground(btn, theme.colors.bg.panel)

    local stripe = btn:CreateTexture(nil, "OVERLAY")
    stripe:SetPoint("BOTTOMLEFT",  0, 0)
    stripe:SetPoint("BOTTOMRIGHT", 0, 0)
    stripe:SetHeight(2)
    NUL.SetTextureColor(stripe, theme.colors.accent.primary)
    stripe:Hide()
    btn._stripe = stripe

    function btn:SetActive(active)
        local t = NUL:GetTheme()
        if active then
            self._stripe:Show()
            NUL.SetFontColor(self._label, t.colors.accent.primary)
        else
            self._stripe:Hide()
            NUL.SetFontColor(self._label, t.colors.text.muted)
        end
    end

    btn:SetScript("OnEnter", function(self)
        if ListWindow._activeTab ~= spec.key then
            NUL.SetFontColor(self._label, NUL:GetTheme().colors.text.primary)
        end
    end)
    btn:SetScript("OnLeave", function(self)
        self:SetActive(ListWindow._activeTab == spec.key)
    end)
    btn:SetScript("OnClick", function() ListWindow:SwitchTab(spec.key) end)

    return btn
end

function ListWindow:SwitchTab(key)
    if not self.frame then return end
    local spec = self._tabs[key]
    if not spec then return end
    if self._activeTab == key and self._tabFrames[key] then return end

    local prev = self._activeTab
    if prev and self._tabs[prev] then
        local prevSpec = self._tabs[prev]
        local prevFrame = self._tabFrames[prev]
        if prevFrame and prevFrame.Hide then prevFrame:Hide() end
        if prevSpec.onHide then
            local ok, err = pcall(prevSpec.onHide, prevSpec)
            if not ok then geterrorhandler()(err) end
        end
    end

    local frame = self._tabFrames[key]
    if not frame then
        local ok, result = pcall(spec.build, self.tabContent, spec)
        if not ok then
            geterrorhandler()(result)
        else
            frame = (type(result) == "table" and result) or self.tabContent
            self._tabFrames[key] = frame
        end
    end
    if frame and frame.Show then frame:Show() end

    self._activeTab = key

    for k, btn in pairs(self._tabButtons) do
        btn:SetActive(k == key)
    end

    if spec.onShow then
        local ok, err = pcall(spec.onShow, spec)
        if not ok then geterrorhandler()(err) end
    end
end

function ListWindow:Refresh()
    local spec = self:GetActiveTabSpec()
    if spec and spec.refresh then
        local ok, err = pcall(spec.refresh, spec)
        if not ok then geterrorhandler()(err) end
    end
end

function ListWindow:RebuildLayout()
    for _, spec in pairs(self._tabs) do
        if spec.rebuildLayout then
            local ok, err = pcall(spec.rebuildLayout, spec)
            if not ok then geterrorhandler()(err) end
        end
    end
end

local function blacklistSpec()
    return ListWindow._tabs and ListWindow._tabs.blacklist or nil
end

function ListWindow:ShowAddDialog(prefill)
    self:Build()
    self:SwitchTab("blacklist")
    local spec = blacklistSpec()
    if spec and spec.showAddDialog then spec.showAddDialog(spec, prefill) end
end

function ListWindow:ShowEditDialog(entry)
    self:Build()
    self:SwitchTab("blacklist")
    local spec = blacklistSpec()
    if spec and spec.showEditDialog then spec.showEditDialog(spec, entry) end
end

function ListWindow:RefreshAddDialogPills()
    local spec = blacklistSpec()
    if spec and spec.refreshAddDialogPills then spec.refreshAddDialogPills(spec) end
end

function ListWindow:Show()
    self:Build()
    self.frame:Show()
    self:Refresh()

    local news = NBK:GetModule("News")
    if news and news.MaybeAutoOpen then news:MaybeAutoOpen() end
end

function ListWindow:Toggle()
    self:Build()
    if self.frame:IsShown() then self.frame:Hide() else self:Show() end
end

function ListWindow:OnEnable()

end
