local _, NBK = ...
local NUL = LibStub("NerzorsUILib-1.0")
local L   = NBK.L

local BlacklistTab = NBK:GetModule("BlacklistTab")
if not BlacklistTab then return end

BlacklistTab.selectMode = false
BlacklistTab.selected   = {}

function BlacklistTab:IsSelected(key)
    return self.selected[key] ~= nil
end

function BlacklistTab:SelectedCount()
    local n = 0
    for _ in pairs(self.selected) do n = n + 1 end
    return n
end

function BlacklistTab:SetRowSelected(entry, on)
    local key, name, realm = NBK:NormalizeKey(entry.name, entry.realm)
    if not key then return end
    if on then
        self.selected[key] = { name = name, realm = realm }
    else
        self.selected[key] = nil
    end
    self:_UpdateActionBar()
end

function BlacklistTab:ClearSelection()
    wipe(self.selected)
    self:_UpdateActionBar()
end

function BlacklistTab:ToggleSelectMode()
    self.selectMode = not self.selectMode
    if not self.selectMode then wipe(self.selected) end

    if self.actionBar then self.actionBar:SetShown(self.selectMode) end
    self.layoutAnchor = (self.selectMode and self.actionBar) or self.searchEB
    if self.selectBtn then
        self.selectBtn:SetLabel(self.selectMode and (L["Done"] or "Done")
                                                or  (L["Select"] or "Select"))
    end

    self:_RebuildLayout()
    self:_UpdateActionBar()
end

function BlacklistTab:_BuildActionBar(root)
    if self.actionBar then return self.actionBar end
    local theme = NUL:GetTheme()

    local bar = CreateFrame("Frame", nil, root)
    bar:SetHeight(28)
    bar:SetPoint("TOPLEFT",  self.searchEB, "BOTTOMLEFT", 0, -6)
    bar:SetPoint("TOPRIGHT", root, "TOPRIGHT", 0, 0)
    bar:Hide()

    local count = NUL:CreateLabel(bar, { text = "", color = theme.colors.text.muted })
    count:SetPoint("LEFT", 2, 0)
    bar._count = count

    local x = 150
    local function place(btn, w)
        btn:SetPoint("LEFT", bar, "LEFT", x, 0)
        x = x + w + 6
    end

    local selAll = NUL:Button(bar, {
        label = L["Select all"] or "Select all", height = 22, width = 100,
        onClick = function() self:_ToggleSelectAll() end,
    })
    place(selAll, 100)
    bar._selAll = selAll

    local del = NUL:Button(bar, {
        label = L["Delete"] or "Delete", height = 22, width = 90, style = "danger",
        onClick = function() self:_DeleteSelected() end,
    })
    place(del, 90)

    if NBK:GetModule("Sync") then
        local share = NUL:Button(bar, {
            label = L["Mark shareable"] or "Mark shareable", height = 22, width = 130,
            onClick = function() self:_MarkSelected("shareable", true) end,
        })
        place(share, 130)
        local priv = NUL:Button(bar, {
            label = L["Mark private"] or "Mark private", height = 22, width = 120,
            onClick = function() self:_MarkSelected("shareable", false) end,
        })
        place(priv, 120)
    end

    local cancel = NUL:Button(bar, {
        label = L["Cancel"] or "Cancel", height = 22, width = 90,
        onClick = function() self:ToggleSelectMode() end,
    })
    cancel:SetPoint("RIGHT", bar, "RIGHT", 0, 0)

    self.actionBar = bar
    return bar
end

function BlacklistTab:_UpdateActionBar()
    local bar = self.actionBar
    if not bar or not bar._count then return end
    local n = self:SelectedCount()
    bar._count:SetText((L["%d selected"] or "%d selected"):format(n))

    if bar._selAll then
        local allSelected = self:_AllVisibleSelected()
        bar._selAll:SetLabel(allSelected and (L["Select none"] or "Select none")
                                          or (L["Select all"] or "Select all"))
    end
end

function BlacklistTab:_VisibleEntries()
    local filter = self.searchEB and self.searchEB:GetText() or ""
    return self:SortedEntries(filter, self.sortKey, self.sortDir)
end

function BlacklistTab:_AllVisibleSelected()
    local vis = self:_VisibleEntries()
    if #vis == 0 then return false end
    for _, e in ipairs(vis) do
        local key = NBK:NormalizeKey(e.name, e.realm)
        if key and not self.selected[key] then return false end
    end
    return true
end

function BlacklistTab:_ToggleSelectAll()
    if self:_AllVisibleSelected() then
        wipe(self.selected)
    else
        for _, e in ipairs(self:_VisibleEntries()) do
            self:SetRowSelected(e, true)
        end
    end
    self:_Refresh()
    self:_UpdateActionBar()
end

function BlacklistTab:_DeleteSelected()
    local n = self:SelectedCount()
    if n == 0 then return end
    NUL:Confirm({
        text = (L["Delete %d selected entries?"] or "Delete %d selected entries?"):format(n),
        onAccept = function()
            for _, who in pairs(self.selected) do
                NBK:RemovePlayer(who.name, who.realm)
            end
            wipe(self.selected)
            self:_Refresh()
            self:_UpdateActionBar()
        end,
    })
end

function BlacklistTab:_MarkSelected(field, value)
    if self:SelectedCount() == 0 then return end
    for _, who in pairs(self.selected) do
        NBK:UpdateEntry(who.name, who.realm, { [field] = value })
    end
    self:_Refresh()
end
