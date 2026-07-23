local _, NBK = ...
local NUL = LibStub("NerzorsUILib-1.0")
local L   = NBK.L

local BlacklistTab = NBK:RegisterModule("BlacklistTab")

BlacklistTab.ROW_HEIGHT    = 26
BlacklistTab.OPTIONS_WIDTH = 120

function BlacklistTab:_Build(parent)
    if self.frame then return self.frame end
    local theme = NUL:GetTheme()

    self.sortKey = self.sortKey or "name"
    self.sortDir = self.sortDir or "asc"

    local root = CreateFrame("Frame", nil, parent)
    root:SetAllPoints()
    self.frame = root

    local searchBox = NUL:EditBox(root, {
        width       = 260, height = 26,
        placeholder = L["Search name, realm, reason..."],
        onTextChanged = function() self:_Refresh() end,
    })
    searchBox:SetPoint("TOPLEFT")
    self.searchEB = searchBox

    local addBtn = NUL:Button(root, {
        label = L["+ Add"], height = 26, style = "accent",
        onClick = function() self:_ShowAddDialog() end,
    })
    addBtn:SetPoint("LEFT", searchBox, "RIGHT", 8, 0)

    local countLabel = NUL:CreateLabel(root, { text = "", color = theme.colors.text.muted })
    countLabel:SetPoint("RIGHT")
    self.countLabel = countLabel

    self.layoutAnchor = searchBox
    self:_RebuildLayout()

    local gs = NBK:GetModule("GroupScanner")
    if gs and gs.OnRosterChanged and not self._rosterHooked then
        self._rosterHooked = true
        gs:OnRosterChanged(function()
            local lw = NBK:GetModule("ListWindow")
            if lw and lw.frame and lw.frame:IsShown() and lw:GetActiveTab() == "blacklist" then
                self:_Refresh()
            end
        end)
    end

    return root
end

function BlacklistTab:_RebuildLayout()
    if not self.frame then return end
    local theme = NUL:GetTheme()
    local root  = self.frame

    if self.header then self.header:Hide(); self.header:SetParent(nil); self.header = nil end
    if self.list then
        self.list.container:Hide()
        self.list.container:SetParent(nil)
        self.list = nil
    end

    local columns = self:ComputeColumns()

    local header = CreateFrame("Frame", nil, root)
    header:SetHeight(20)
    header:SetPoint("TOPLEFT", self.layoutAnchor, "BOTTOMLEFT", 0, -8)
    header:SetPoint("RIGHT")
    NUL:FillBackground(header, theme.colors.bg.panel)

    header._columns = columns
    header._cells   = {}

    local self_ref = self
    local function buildHeaderCell(col)
        local cell = CreateFrame("Frame", nil, header)
        cell:SetHeight(20)
        cell._col = col

        local fs = NUL:CreateLabel(cell, {
            text     = "",
            size     = "sm",
            color    = theme.colors.text.muted,
            justifyH = "LEFT",
        })
        fs:SetPoint("LEFT", cell, "LEFT", 0, 0)

        fs:SetPoint("RIGHT", cell, "RIGHT", -14, 0)
        cell._label = fs

        local arrow = cell:CreateTexture(nil, "OVERLAY")
        arrow:SetSize(10, 10)
        arrow:SetPoint("RIGHT", cell, "RIGHT", -2, 0)
        arrow:Hide()
        cell._arrow = arrow

        if col.sortable then
            cell:EnableMouse(true)
            cell:SetScript("OnMouseDown", function() self_ref:_SetSort(col.key) end)
            cell:SetScript("OnEnter", function()
                NUL.SetFontColor(fs, NUL:GetTheme().colors.text.primary)
            end)
            cell:SetScript("OnLeave", function()
                local t = NUL:GetTheme()
                local active = self_ref.sortKey == col.key
                NUL.SetFontColor(fs, active and t.colors.accent.primary or t.colors.text.muted)
            end)
        end

        return cell
    end

    local function paintCell(cell)
        local t = NUL:GetTheme()
        local col = cell._col
        local active = col.sortable and self.sortKey == col.key
        cell._label:SetText(col.label or "")
        NUL.SetFontColor(cell._label, active and t.colors.accent.primary or t.colors.text.muted)

        if cell._arrow then
            if active then
                local iconName = (self.sortDir == "desc") and "arrow-down.png" or "arrow-up.png"
                cell._arrow:SetTexture(NBK:IconPath(iconName))
                local a = t.colors.accent.primary
                cell._arrow:SetVertexColor(a.r, a.g, a.b, 1)
                cell._arrow:Show()
            else
                cell._arrow:Hide()
            end
        end
    end

    local function layoutHeader()
        local w = header:GetWidth()
        local fixed = 0
        for _, col in ipairs(columns) do
            if not col.flex then fixed = fixed + col.width end
        end
        local flexW = math.max(60, w - fixed - (#columns * 4) - 8)
        local x = 8
        for i, col in ipairs(columns) do
            local cell = header._cells[i]
            if not cell then
                cell = buildHeaderCell(col)
                header._cells[i] = cell
            end
            local cw = col.flex and flexW or col.width
            cell:ClearAllPoints()
            cell:SetPoint("LEFT", header, "LEFT", x, 0)
            cell:SetWidth(cw)
            paintCell(cell)
            x = x + cw + 4
        end
    end
    header:SetScript("OnSizeChanged", layoutHeader)
    header._paint = function()
        for _, cell in ipairs(header._cells) do paintCell(cell) end
    end
    self.header = header

    local list = NUL:ScrollList(root, {
        rowHeight  = self.ROW_HEIGHT,
        rowBuilder = self:MakeRowBuilder(columns),
    })
    list.container:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -2)
    list.container:SetPoint("BOTTOMRIGHT")
    self.list = list

    layoutHeader()
    self:_Refresh()
end

function BlacklistTab:_Refresh()
    if not self.frame or not self.list then return end
    local filter = self.searchEB and self.searchEB:GetText() or ""
    local entries = self:SortedEntries(filter, self.sortKey, self.sortDir)
    self.list:SetData(entries)
    local total = NBK:CountEntries()
    local shown = #entries
    self.countLabel:SetText(shown == total and (L["%d entries"]):format(total)
                                           or (L["%d / %d"]):format(shown, total))
end

function BlacklistTab:_SetSort(key)
    if not key then return end
    if self.sortKey == key then
        self.sortDir = (self.sortDir == "asc") and "desc" or "asc"
    else
        self.sortKey = key
        self.sortDir = "asc"
    end
    if self.header and self.header._paint then self.header._paint() end
    self:_Refresh()
end

function BlacklistTab:OnEnable()
    local lw = NBK:GetModule("ListWindow")
    if not lw or not lw.RegisterTab then return end

    lw:RegisterTab({
        key      = "blacklist",
        labelKey = "Blacklist",
        order    = 10,
        build    = function(parent) return BlacklistTab:_Build(parent) end,
        refresh  = function() BlacklistTab:_Refresh() end,
        rebuildLayout = function() BlacklistTab:_RebuildLayout() end,
        showAddDialog  = function(_, prefill) BlacklistTab:_ShowAddDialog(prefill) end,
        showEditDialog = function(_, entry)   BlacklistTab:_ShowEditDialog(entry) end,
        refreshAddDialogPills = function() BlacklistTab:_RefreshAddDialogPills() end,
    })
end
