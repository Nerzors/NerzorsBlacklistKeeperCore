local _, NBK = ...
local Config = NBK:GetModule("Config")
if not Config then return end

local NUL = LibStub("NerzorsUILib-1.0")

local function buildNotificationsTab(parent)
    local L     = NBK.L
    local theme = NUL:GetTheme()

    local panel = CreateFrame("Frame", nil, parent)
    panel:SetAllPoints()

    local y = 0
    local _, ny = Config:AddSectionLabel(panel, y, "Notifications"); y = ny

    local _, ny1 = Config:AddCheckboxRow(panel, y, "Warn when a blacklisted player joins my group",
        {"groupWarning", "enabled"}, true); y = ny1
    local _, ny2 = Config:AddCheckboxRow(panel, y, "Show chat message on warning",
        {"groupWarning", "chat"}, true); y = ny2
    local _, ny3 = Config:AddCheckboxRow(panel, y, "Show popup on warning",
        {"groupWarning", "popup"}, true); y = ny3
    local _, ny4 = Config:AddCheckboxRow(panel, y, "Play sound on warning",
        {"groupWarning", "sound"}, true); y = ny4

    local soundLabel = NUL:CreateLabel(panel, {
        text  = L["Warning sound"],
        color = theme.colors.text.muted,
    })
    soundLabel:SetPoint("TOPLEFT", 12, y); y = y - 18

    local soundOptions = {}
    for _, s in ipairs(NBK.MEDIA.sounds or {}) do
        table.insert(soundOptions, { key = s, label = s })
    end

    local soundDD = NUL:Dropdown(panel, {
        width = 200, height = 24,
        options = soundOptions,
        value = Config:GetPath({"groupWarning", "soundFile"}, "AirHorn"),
        onSelect = function(v) Config:SetPath({"groupWarning", "soundFile"}, v) end,
    })
    soundDD:SetPoint("TOPLEFT", 12, y)

    local previewBtn = NUL:IconButton(panel, {
        icon    = "arrow-right.png",
        size    = 24,
        style   = "accent",
        tooltip = L["Preview"] or "Preview",
        onClick = function()
            local name = soundDD:GetValue() or Config:GetPath({"groupWarning", "soundFile"}, "AirHorn")
            local path = NBK:SoundPath(name)
            if path and PlaySoundFile then PlaySoundFile(path, "Master") end
        end,
    })
    previewBtn:SetPoint("LEFT", soundDD, "RIGHT", 6, 0)
    y = y - 34

    local _, ny5 = Config:AddDivider(panel, y); y = ny5

    local _, ny6 = Config:AddCheckboxRow(panel, y, "Hide chat messages from blacklisted players",
        {"filterChat"}, true); y = ny6
    local _, ny7 = Config:AddCheckboxRow(panel, y, "Mute new players by default",
        {"autoMute"}, true); y = ny7

    panel.lastY = y
    return panel
end

Config:RegisterTab({
    key      = "Notifications",
    labelKey = "Notifications",
    build    = buildNotificationsTab,
    order    = 20,
    icon     = "tab-notifications.png",
    category = "core",
})
