local _, NBK = ...
local Config = NBK:GetModule("Config")
if not Config then return end

local NUL = LibStub("NerzorsUILib-1.0")

local function buildAdvancedTab(parent)
    local L     = NBK.L
    local theme = NUL:GetTheme()

    local panel = CreateFrame("Frame", nil, parent)
    panel:SetAllPoints()

    local y = 0
    local _, ny = Config:AddSectionLabel(panel, y, "Advanced"); y = ny

    local mmCb = NUL:Checkbox(panel, {
        label    = L["Show minimap icon"],
        checked  = not Config:GetPath({"minimapIcon", "hide"}, false),
        onChange = function(v)
            Config:SetPath({"minimapIcon", "hide"}, not v)
            Config:RefreshMinimap()
        end,
    })
    mmCb:SetPoint("TOPLEFT", 0, y); y = y - 32

    local _, nyAcSec = Config:AddSectionLabel(panel, y, "Auto-cleanup"); y = nyAcSec

    local _, nyAc = Config:AddCheckboxRow(panel, y, "Auto-remove stale entries on login",
        {"autoCleanup", "enabled"}, false); y = nyAc - 2

    local monthsLabel = NUL:CreateLabel(panel, {
        text  = L["Older than:"],
        color = theme.colors.text.muted,
    })
    monthsLabel:SetPoint("TOPLEFT", 0, y - 4)

    local monthsDD = NUL:Dropdown(panel, {
        width = 110, height = 24,
        options = {
            { key = 1,  label = (L["%d month"]  or "%d month"):format(1)   },
            { key = 3,  label = (L["%d months"] or "%d months"):format(3)  },
            { key = 6,  label = (L["%d months"] or "%d months"):format(6)  },
            { key = 12, label = (L["%d months"] or "%d months"):format(12) },
            { key = 24, label = (L["%d months"] or "%d months"):format(24) },
        },
        value = Config:GetPath({"autoCleanup", "months"}, 6),
        onSelect = function(key)
            Config:SetPath({"autoCleanup", "months"}, tonumber(key) or 6)
        end,
    })
    monthsDD:SetPoint("LEFT", monthsLabel, "RIGHT", 8, 0)
    y = y - 32

    local runBtn = NUL:Button(panel, {
        label = L["Run cleanup now"], width = 150, height = 24, style = "accent",
        onClick = function()
            local months = tonumber(Config:GetPath({"autoCleanup", "months"}, 6)) or 6
            local ac = NBK:GetModule("AutoCleanup")
            if not ac then return end
            local count = ac:CountStale(months)
            if count == 0 then
                NBK:Print((L["No stale entries (older than %d months)."]):format(months))
                return
            end
            NUL:Confirm({
                text = (L["Remove %d stale entries (older than %d months)? Pinned entries are kept."])
                        :format(count, months),
                onAccept = function()
                    local removed = ac:Prune(months)
                    NBK:Print((L["Auto-cleanup: removed %d stale entries (older than %d months)."])
                        :format(removed, months))
                end,
            })
        end,
    })
    runBtn:SetPoint("TOPLEFT", 0, y); y = y - 36

    local _, ny2 = Config:AddDivider(panel, y); y = ny2

    local _, ny3 = Config:AddSectionLabel(panel, y, "Backup & data"); y = ny3

    local descLbl = NUL:CreateLabel(panel, {
        text  = L["Export your list to share or back up. Import merges or replaces what's on your current list."],
        size  = "sm",
        color = theme.colors.text.muted,
        justifyH = "LEFT",
    })
    descLbl:SetPoint("TOPLEFT", 0, y)
    descLbl:SetPoint("RIGHT",   0, 0)
    y = y - 34

    local exportBtn = NUL:Button(panel, {
        label = L["Export..."], width = 130, height = 26, style = "accent",
        onClick = function() if Config.ShowExportDialog then Config:ShowExportDialog() end end,
    })
    exportBtn:SetPoint("TOPLEFT", 0, y)

    local importBtn = NUL:Button(panel, {
        label = L["Import..."], width = 130, height = 26, style = "accent",
        onClick = function() if Config.ShowImportDialog then Config:ShowImportDialog() end end,
    })
    importBtn:SetPoint("LEFT", exportBtn, "RIGHT", 8, 0)

    local resetBtn = NUL:Button(panel, {
        label = L["Clear list..."], width = 130, height = 26, style = "danger",
        onClick = function() if Config.ShowResetDialog then Config:ShowResetDialog() end end,
    })
    resetBtn:SetPoint("LEFT", importBtn, "RIGHT", 8, 0)

    panel.lastY = y - 36

    local hint = NUL:CreateLabel(panel, {
        text  = L["Changes save automatically."],
        size  = "sm",
        color = theme.colors.text.muted,
    })
    hint:SetPoint("BOTTOMLEFT", 0, 0)

    return panel
end

Config:RegisterTab({
    key      = "Advanced",
    labelKey = "Advanced",
    build    = buildAdvancedTab,
    order    = 50,
    icon     = "tab-advanced.png",
    category = "core",
})
