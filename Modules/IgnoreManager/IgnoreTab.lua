local _, NBK = ...
local NUL = LibStub("NerzorsUILib-1.0")

local IgnoreManager = NBK:GetModule("IgnoreManager")
if not IgnoreManager then return end

local IgnoreTab = NBK:RegisterModule("IgnoreTab")

local ROW_HEIGHT = 26
local GAP        = 4
local LEFT_PAD   = 8

local ui = {}
IgnoreTab.selected = {}

local function columns()
    local L = NBK.L
    return {
        { key = "select", label = "",                width = 20 },
        { key = "class",  label = L["Class"],        width = 26, compact = true },
        { key = "name",   label = L["Name"],         width = 180 },
        { key = "since",  label = L["Ignored since"], width = 110 },
        { key = "added",  label = L["Blacklist"],    width = 90 },
        { key = "reason", label = L["Reason"],       width = 0, flex = true },
        { key = "note",   label = L["Note"],         width = 22, compact = true, icon = "notes.png" },
        { key = "opts",   label = L["Options"],      width = 60 },
    }
end

local function layoutColumns(cols, totalWidth)
    local fixed = 0
    for _, col in ipairs(cols) do
        if not col.flex then fixed = fixed + col.width end
    end
    local flexW = math.max(60, totalWidth - fixed - #cols * GAP - LEFT_PAD)
    local out, x = {}, LEFT_PAD
    for i, col in ipairs(cols) do
        local w = col.flex and flexW or col.width
        out[i] = { x = x, w = w }
        x = x + w + GAP
    end
    return out
end

local function buildHeader(parent, cols)
    local theme  = NUL:GetTheme()
    local header = CreateFrame("Frame", nil, parent)
    header:SetHeight(20)
    NUL:FillBackground(header, theme.colors.bg.panel)

    local cells = {}
    for i, col in ipairs(cols) do
        local cell = CreateFrame("Frame", nil, header)
        cell:SetHeight(20)
        local fs = NUL:CreateLabel(cell, {
            text     = col.compact and "" or col.label,
            size     = "sm",
            color    = theme.colors.text.muted,
            justifyH = "LEFT",
            wrap     = false,
        })
        fs:SetPoint("LEFT"); fs:SetPoint("RIGHT")
        cell._label = fs
        NBK:SetupColumnHeader(cell, col)
        cells[i] = cell
    end

    header:SetScript("OnSizeChanged", function()
        local pos = layoutColumns(cols, header:GetWidth())
        for i, cell in ipairs(cells) do
            cell:ClearAllPoints()
            cell:SetPoint("LEFT", header, "LEFT", pos[i].x, 0)
            cell:SetWidth(pos[i].w)
        end
    end)
    return header
end

local function sinceText(e)
    if not e.since then return "-" end
    local d = NBK:FormatDate(e.since)
    return e.sinceBefore and NBK.L["before %s"]:format(d) or d
end

local function tooltipBody(e)
    local L = NBK.L
    local lines = { ("%s: %s"):format(L["Ignored since"], sinceText(e)) }
    if e.bl then
        local accent = NUL.ToHex(NUL:GetTheme().colors.accent.primary)
        lines[#lines + 1] = " "
        lines[#lines + 1] = ("|cff%s%s|r"):format(accent, L["Blacklisted"])
        lines[#lines + 1] = ("%s: %s"):format(L["Added"], NBK:FormatDate(e.bl.addedAt))
        local reason = e.bl.reason ~= "" and e.bl.reason or L["no reason logged"]
        lines[#lines + 1] = ("%s: %s"):format(L["Reason"], reason)
        if e.bl.notes and e.bl.notes ~= "" then
            lines[#lines + 1] = ("%s: %s"):format(L["Note"], e.bl.notes)
        end
    end
    return table.concat(lines, "\n")
end

function IgnoreTab:IsSelected(key) return self.selected[key] == true end

function IgnoreTab:SetSelected(e, on)
    self.selected[e.key] = on and true or nil
    self:_UpdateActionBar()
end

function IgnoreTab:SelectedEntries()
    local out = {}
    for _, e in ipairs(IgnoreManager:GetEntries()) do
        if self.selected[e.key] then out[#out + 1] = e end
    end
    return out
end

function IgnoreTab:SelectedCount()
    return #self:SelectedEntries()
end

local function makeRowBuilder(cols)
    return function(row)
        local L     = NBK.L
        local theme = NUL:GetTheme()
        local c     = {}

        c.select = NUL:Checkbox(row, { size = "small" })
        c.class  = NBK.UI:CreateClassIcon(row, 18)
        c.name   = NUL:CreateLabel(row, { text = "", justifyH = "LEFT", wrap = false })
        c.since  = NUL:CreateLabel(row, { text = "", color = theme.colors.text.muted, justifyH = "LEFT", wrap = false })
        c.added  = NUL:CreateLabel(row, { text = "", justifyH = "LEFT", wrap = false })
        c.reason = NUL:CreateLabel(row, { text = "", size = "sm", color = theme.colors.text.muted,
                                          justifyH = "LEFT", wrap = false })

        c.note = row:CreateTexture(nil, "ARTWORK")
        c.note:SetSize(14, 14)
        c.note:SetTexture(NBK:IconPath("notes.png"))

        c.opts = CreateFrame("Frame", nil, row)
        c.opts:SetSize(60, ROW_HEIGHT)
        c.import = NUL:IconButton(c.opts, {
            icon = "block.png", size = 24, plain = true,
            tooltip = L["Import to NBK"],
        })
        c.import:SetPoint("LEFT", 0, 0)
        c.remove = NUL:IconButton(c.opts, {
            icon = "app-close.png", size = 24, style = "danger", plain = true,
            tooltip = L["Remove from ignore list"],
        })
        c.remove:SetPoint("LEFT", 28, 0)

        local sized = { name = true, since = true, added = true, reason = true }

        local function layout(width)
            local pos = layoutColumns(cols, width)
            for i, col in ipairs(cols) do
                local cell = c[col.key]
                cell:ClearAllPoints()
                cell:SetPoint("LEFT", row, "LEFT", pos[i].x, 0)
                if sized[col.key] then cell:SetWidth(pos[i].w) end
            end
        end

        row:EnableMouse(true)

        return function(r, e)
            local t = NUL:GetTheme()
            layout(r:GetWidth())

            c.select:SetChecked(IgnoreTab:IsSelected(e.key))
            c.select:SetOnChange(function(on) IgnoreTab:SetSelected(e, on) end)

            c.class:SetClass(e.class)
            local hex = e.class and NBK:GetClassHex(e.class) or "ffffff"
            c.name:SetText(("|cff%s%s|r-%s"):format(hex, e.name or "?", e.realm or ""))
            c.since:SetText(sinceText(e))

            if e.bl then
                c.added:SetText(NBK:FormatDate(e.bl.addedAt))
                NUL.SetFontColor(c.added, t.colors.accent.primary)
                c.reason:SetText(e.bl.reason or "")
            else
                c.added:SetText("-")
                NUL.SetFontColor(c.added, t.colors.text.muted)
                c.reason:SetText("")
            end
            c.note:SetShown(e.bl ~= nil and e.bl.notes ~= nil and e.bl.notes ~= "")

            c.import:SetShown(not e.bl)
            c.import:SetScript("OnClick", function() IgnoreManager:Import({ e }) end)
            c.remove:SetScript("OnClick", function() IgnoreTab:ConfirmRemove({ e }) end)

            r:SetScript("OnEnter", function(self)
                NUL:ShowTooltipMultiline(self, {
                    title = ("%s-%s"):format(e.name or "?", e.realm or ""),
                    body  = tooltipBody(e),
                })
            end)
            r:SetScript("OnLeave", function() NUL:HideTooltip() end)
        end
    end
end

function IgnoreTab:_BuildRemoveDialog()
    if self._dialog then return self._dialog end
    local L     = NBK.L
    local theme = NUL:GetTheme()

    local f = NUL:Window({
        name   = "NBKIgnoreRemoveDialog",
        title  = L["Remove from ignore list"],
        width  = 400, height = 170,
        strata = "DIALOG",
    })

    f.text = NUL:CreateLabel(f.content, { text = "", justifyH = "LEFT" })
    f.text:SetPoint("TOPLEFT", 0, 0)
    f.text:SetPoint("TOPRIGHT", 0, 0)

    f.alsoBL = NUL:Checkbox(f.content, { label = "" })
    f.alsoBL:SetPoint("TOPLEFT", 0, -44)
    f.alsoBL:SetWidth(370)

    local accept = NUL:Button(f.content, {
        label = L["Remove"], width = 120, height = 26, style = "danger",
        onClick = function()
            local entries, also = f._entries or {}, f.alsoBL:IsShown() and f.alsoBL:GetChecked()
            f:Hide()
            IgnoreManager:Remove(entries, also)
            for _, e in ipairs(entries) do self.selected[e.key] = nil end
            self:Refresh()
        end,
    })
    accept:SetPoint("BOTTOMRIGHT", 0, 0)

    local cancel = NUL:Button(f.content, {
        label = L["Cancel"], width = 110, height = 26,
        onClick = function() f:Hide() end,
    })
    cancel:SetPoint("BOTTOMRIGHT", accept, "BOTTOMLEFT", -6, 0)

    NUL.SetFontColor(f.text, theme.colors.text.primary)
    self._dialog = f
    return f
end

function IgnoreTab:ConfirmRemove(entries)
    local L = NBK.L
    if #entries == 0 then
        NBK:Print(L["Select at least one player first."])
        return
    end
    local onBlacklist = 0
    for _, e in ipairs(entries) do
        if e.bl then onBlacklist = onBlacklist + 1 end
    end

    local f = self:_BuildRemoveDialog()
    f._entries = entries
    f.text:SetText(L["Remove %d selected players from the game's ignore list?"]:format(#entries))
    f.alsoBL:SetLabel(L["Also remove them from the blacklist (%d)"]:format(onBlacklist))
    f.alsoBL:SetChecked(false)
    f.alsoBL:SetShown(onBlacklist > 0)
    f:Show()
end

function IgnoreTab:_Build(parent)
    if ui.root then return ui.root end
    local L     = NBK.L
    local theme = NUL:GetTheme()
    local cols  = columns()

    local root = CreateFrame("Frame", nil, parent)
    root:SetAllPoints()
    ui.root = root

    ui.search = NUL:EditBox(root, {
        width = 260, height = 26,
        placeholder = L["Search name, realm, reason..."],
        onTextChanged = function() IgnoreTab:Refresh() end,
    })
    ui.search:SetPoint("TOPLEFT")

    ui.count = NUL:CreateLabel(root, { text = "", color = theme.colors.text.muted })
    ui.count:SetPoint("RIGHT", root, "TOPRIGHT", 0, -13)

    ui.hint = NUL:CreateLabel(root, {
        text  = L["The game doesn't store dates - \"Ignored since\" is when NBK first saw the entry."],
        size  = "sm",
        color = theme.colors.text.muted,
    })
    ui.hint:SetPoint("TOPLEFT", ui.search, "BOTTOMLEFT", 2, -6)

    local bar = CreateFrame("Frame", nil, root)
    bar:SetHeight(26)
    bar:SetPoint("TOPLEFT",  ui.hint, "BOTTOMLEFT", -2, -6)
    bar:SetPoint("TOPRIGHT", root, "TOPRIGHT", 0, 0)
    ui.bar = bar

    ui.selAll = NUL:Button(bar, {
        label = L["Select all"], width = 110, height = 22,
        onClick = function() IgnoreTab:_ToggleSelectAll() end,
    })
    ui.selAll:SetPoint("LEFT", 0, 0)

    local importBtn = NUL:Button(bar, {
        label = L["Import to NBK"], width = 130, height = 22, style = "accent",
        onClick = function()
            local sel = IgnoreTab:SelectedEntries()
            if #sel == 0 then NBK:Print(L["Select at least one player first."]); return end
            IgnoreManager:Import(sel)
        end,
    })
    importBtn:SetPoint("LEFT", ui.selAll, "RIGHT", 6, 0)

    local removeBtn = NUL:Button(bar, {
        label = L["Remove from ignore list"], width = 190, height = 22, style = "danger",
        onClick = function() IgnoreTab:ConfirmRemove(IgnoreTab:SelectedEntries()) end,
    })
    removeBtn:SetPoint("LEFT", importBtn, "RIGHT", 6, 0)

    ui.selCount = NUL:CreateLabel(bar, { text = "", color = theme.colors.text.muted })
    ui.selCount:SetPoint("RIGHT", bar, "RIGHT", 0, 0)

    local header = buildHeader(root, cols)
    header:SetPoint("TOPLEFT", bar, "BOTTOMLEFT", 0, -6)
    header:SetPoint("RIGHT")
    ui.header = header

    local list = NUL:ScrollList(root, {
        rowHeight  = ROW_HEIGHT,
        rowBuilder = makeRowBuilder(cols),
    })
    list.container:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -2)
    list.container:SetPoint("BOTTOMRIGHT")
    ui.list = list

    self:Refresh()
    return root
end

function IgnoreTab:_Visible()
    local filter = (ui.search and ui.search:GetText() or ""):lower()
    local out = {}
    for _, e in ipairs(IgnoreManager:GetEntries()) do
        local reason = e.bl and e.bl.reason or ""
        if filter == ""
           or (e.name or ""):lower():find(filter, 1, true)
           or (e.realm or ""):lower():find(filter, 1, true)
           or reason:lower():find(filter, 1, true) then
            out[#out + 1] = e
        end
    end
    table.sort(out, function(a, b) return (a.name or ""):lower() < (b.name or ""):lower() end)
    return out
end

function IgnoreTab:_ToggleSelectAll()
    local vis, all = self:_Visible(), true
    for _, e in ipairs(vis) do
        if not self.selected[e.key] then all = false; break end
    end
    for _, e in ipairs(vis) do self.selected[e.key] = (not all) or nil end
    self:Refresh()
end

function IgnoreTab:_UpdateActionBar()
    if not ui.selCount then return end
    local L = NBK.L
    ui.selCount:SetText(L["%d selected"]:format(self:SelectedCount()))

    local vis, all = self:_Visible(), true
    for _, e in ipairs(vis) do
        if not self.selected[e.key] then all = false; break end
    end
    ui.selAll:SetLabel((all and #vis > 0) and L["Select none"] or L["Select all"])
end

function IgnoreTab:Refresh()
    if not ui.list then return end
    local L, theme = NBK.L, NUL:GetTheme()

    local present = {}
    for _, e in ipairs(IgnoreManager:GetEntries()) do present[e.key] = true end
    for key in pairs(self.selected) do
        if not present[key] then self.selected[key] = nil end
    end

    ui.list:SetData(self:_Visible())

    local n, cap = IgnoreManager:Count(), IgnoreManager.CAP
    ui.count:SetText(L["Ignore list: %d / %d"]:format(n, cap))
    NUL.SetFontColor(ui.count, (n >= cap - 5) and theme.colors.state.warning or theme.colors.text.muted)

    self:_UpdateActionBar()
end

function IgnoreManager:RefreshTab() IgnoreTab:Refresh() end

function IgnoreTab:OnEnable()
    if not IgnoreManager:IsAvailable() then return end
    local lw = NBK:GetModule("ListWindow")
    if not (lw and lw.RegisterTab) then return end

    lw:RegisterTab({
        key      = "ignore",
        labelKey = "Ignore list",
        order    = 15,
        build    = function(parent) return IgnoreTab:_Build(parent) end,
        refresh  = function() IgnoreTab:Refresh() end,
        onShow   = function()
            IgnoreManager:RequestList()
            IgnoreTab:Refresh()
        end,
    })
end
