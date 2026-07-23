local _, NBK = ...
local Config = NBK:GetModule("Config")
if not Config then return end

local NUL = LibStub("NerzorsUILib-1.0")

local function buildTooltipTab(parent)
    local L = NBK.L

    local panel = CreateFrame("Frame", nil, parent)
    panel:SetAllPoints()

    local y = 0
    local _, ny = Config:AddSectionLabel(panel, y, "Tooltip"); y = ny

    local _, ny1 = Config:AddCheckboxRow(panel, y,
        "Show blacklist info in unit tooltips",
        {"tooltip", "enabled"}, true); y = ny1

    local _, nyDiv = Config:AddDivider(panel, y); y = nyDiv
    local _, ny2 = Config:AddSectionLabel(panel, y, "Tooltip fields"); y = ny2

    local _, ny3 = Config:AddCheckboxRow(panel, y, "Show reason",
        {"tooltip", "showReason"}, true); y = ny3
    local _, ny4 = Config:AddCheckboxRow(panel, y, "Show notes",
        {"tooltip", "showNotes"}, true); y = ny4
    local _, ny5 = Config:AddCheckboxRow(panel, y, "Show zone where added",
        {"tooltip", "showZone"}, true); y = ny5
    local _, ny6 = Config:AddCheckboxRow(panel, y, "Show encounter history",
        {"tooltip", "showEncounters"}, true); y = ny6
    local _, ny7 = Config:AddCheckboxRow(panel, y, "Show chat-muted indicator",
        {"tooltip", "showMute"}, true); y = ny7
    local _, ny8 = Config:AddCheckboxRow(panel, y, "Show pinned indicator",
        {"tooltip", "showPin"}, true); y = ny8

    panel.lastY = y
    return panel
end

Config:RegisterTab({
    key      = "Tooltip",
    labelKey = "Tooltip",
    build    = buildTooltipTab,
    order    = 15,
    icon     = "tab-tooltip.png",
    category = "core",
})
