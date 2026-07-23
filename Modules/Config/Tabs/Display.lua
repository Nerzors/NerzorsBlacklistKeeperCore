local _, NBK = ...
local Config = NBK:GetModule("Config")
if not Config then return end

local NUL = LibStub("NerzorsUILib-1.0")

local function buildDisplayTab(parent)
    local L     = NBK.L
    local theme = NUL:GetTheme()

    local panel = CreateFrame("Frame", nil, parent)
    panel:SetAllPoints()

    local y = 0
    local _, ny = Config:AddSectionLabel(panel, y, "Display"); y = ny

    local themeLabel = NUL:CreateLabel(panel, {
        text  = L["Theme"] or "Theme",
        color = theme.colors.text.muted,
    })
    themeLabel:SetPoint("TOPLEFT", 0, y); y = y - 18

    local themeOptions = {}
    for _, name in ipairs(NUL:GetThemeNames()) do
        table.insert(themeOptions, { key = name, label = name })
    end
    local themeDD = NUL:Dropdown(panel, {
        width = 180, height = 24,
        options  = themeOptions,
        value    = NUL:GetCurrentThemeName(),
        onSelect = function(v) NUL:SetTheme(v) end,
    })
    themeDD:SetPoint("TOPLEFT", 0, y); y = y - 34

    local _, ny1 = Config:AddDivider(panel, y); y = ny1

    local classLabel = NUL:CreateLabel(panel, {
        text  = L["Show class as"],
        color = theme.colors.text.muted,
    })
    classLabel:SetPoint("TOPLEFT", 0, y); y = y - 18

    local classDD = NUL:Dropdown(panel, {
        width = 180, height = 24,
        options = {
            { key = "icon", label = L["Class icon"] },
            { key = "name", label = L["Class name"] },
        },
        value = Config:GetPath({"display", "classDisplay"}, "icon"),
        onSelect = function(v)
            Config:SetPath({"display", "classDisplay"}, v)
            Config:RefreshList()
        end,
    })
    classDD:SetPoint("TOPLEFT", 0, y); y = y - 34

    local styleLabel = NUL:CreateLabel(panel, {
        text  = L["Icon style"],
        color = theme.colors.text.muted,
    })
    styleLabel:SetPoint("TOPLEFT", 0, y); y = y - 18

    local styleOptions = {}
    for _, style in ipairs(NBK.CLASS_SPRITE_STYLES or {}) do
        table.insert(styleOptions, { key = style, label = L[style] or style })
    end
    local styleDD = NUL:Dropdown(panel, {
        width = 180, height = 24,
        options = styleOptions,
        value = Config:GetPath({"display", "iconStyle"}, "classic"),
        onSelect = function(v)
            Config:SetPath({"display", "iconStyle"}, v)
            Config:RefreshList()
        end,
    })
    styleDD:SetPoint("TOPLEFT", 0, y); y = y - 36

    local _, ny2 = Config:AddDivider(panel, y); y = ny2

    local refresh = function() Config:RefreshList() end
    local _, ny3 = Config:AddCheckboxRow(panel, y, "Color player names by class",
        {"display", "colorNameByClass"}, true, refresh); y = ny3
    local _, ny4 = Config:AddCheckboxRow(panel, y, "Show name and realm in one column",
        {"display", "combinedName"}, true, refresh); y = ny4
    local _, ny5 = Config:AddCheckboxRow(panel, y, "Show zone column",
        {"display", "showZoneColumn"}, false, refresh); y = ny5
    local _, ny6 = Config:AddCheckboxRow(panel, y, "Show date-added column",
        {"display", "showAddedColumn"}, false, refresh); y = ny6
    local _, ny7 = Config:AddCheckboxRow(panel, y, "Show last-seen column",
        {"display", "showSeenColumn"}, false, refresh); y = ny7

    local lw = NBK:GetModule("ListWindow")
    local registeredOrder = lw and lw._tabOrder or {}
    if #registeredOrder > 1 then
        y = y - 6
        local tabLabel = NUL:CreateLabel(panel, {
            text  = L["Default tab"] or "Default tab",
            color = theme.colors.text.muted,
        })
        tabLabel:SetPoint("TOPLEFT", 0, y); y = y - 18

        local options = {}
        for _, key in ipairs(registeredOrder) do
            local spec = lw._tabs[key]
            local labelText = (spec and L[spec.labelKey]) or (spec and spec.labelKey) or key
            table.insert(options, { key = key, label = labelText })
        end
        local tabDD = NUL:Dropdown(panel, {
            width = 200, height = 24,
            options = options,
            value = Config:GetPath({"display", "defaultTab"}, "blacklist"),
            onSelect = function(v) Config:SetPath({"display", "defaultTab"}, v) end,
        })
        tabDD:SetPoint("TOPLEFT", 0, y); y = y - 34
    end

    panel.lastY = y
    return panel
end

Config:RegisterTab({
    key      = "Display",
    labelKey = "Display",
    build    = buildDisplayTab,
    order    = 10,
    icon     = "tab-display.png",
    category = "core",
})
