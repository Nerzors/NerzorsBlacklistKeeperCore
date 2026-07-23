local _, NBK = ...
local Config = NBK:GetModule("Config")
if not Config then return end

local NUL = LibStub("NerzorsUILib-1.0")

local function buildPresetsTab(parent)
    local L     = NBK.L
    local theme = NUL:GetTheme()

    local panel = CreateFrame("Frame", nil, parent)
    panel:SetAllPoints()

    local y = 0
    local _, ny = Config:AddSectionLabel(panel, y, "Presets"); y = ny

    local hint = NUL:CreateLabel(panel, {
        text  = L["Presets:"],
        color = theme.colors.text.muted,
    })
    hint:SetPoint("TOPLEFT", 0, y); y = y - 22

    local listArea = CreateFrame("Frame", nil, panel)
    listArea:SetPoint("TOPLEFT",     panel, "TOPLEFT",     0, y)
    listArea:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", 0, 0)

    Config:BuildManagedList(listArea, {
        reorderable    = true,
        addPlaceholder = L["Custom reason..."],
        get = function()
            local s = Config:Settings()
            if type(s.presetReasons) ~= "table" then s.presetReasons = {} end
            return s.presetReasons
        end,
        onChange = function()
            Config:RefreshAddDialogPills()
        end,
    })

    panel.lastY = -396
    return panel
end

Config:RegisterTab({
    key      = "Presets",
    labelKey = "Presets",
    build    = buildPresetsTab,
    order    = 30,
    icon     = "tab-presets.png",
    category = "core",
})
