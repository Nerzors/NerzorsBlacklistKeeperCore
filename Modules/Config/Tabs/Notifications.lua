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

    local rb = NBK:GetModule("RequestBlock")
    if rb and rb.KINDS then
        local has = {}
        for _, kind in ipairs(rb.KINDS) do
            if rb._registered[kind.key] then has[kind.setting] = true end
        end
        local rows = {
            { setting = "trade", label = "Trade requests" },
            { setting = "party", label = "Group invites" },
            { setting = "duel",  label = "Duel requests (pet battles too)" },
            { setting = "guild", label = "Guild invites" },
        }
        if next(has) then
            y = y - 6
            local head = NUL:CreateLabel(panel, {
                text = L["Decline requests from muted blacklisted players:"], justifyH = "LEFT",
            })
            head:SetPoint("TOPLEFT", 0, y)
            head:SetPoint("RIGHT", 0, 0)

            local help = L["Only for muted entries. Players on the game's ignore list are already blocked by the game. NBK says so in chat once per player until the next reload."]
            y = y - 20
            for _, r in ipairs(rows) do
                if has[r.setting] then
                    local cb, nyr = Config:AddCheckboxRow(panel, y, r.label,
                        {"requestBlock", r.setting}, true)
                    cb:ClearAllPoints()
                    cb:SetPoint("TOPLEFT", 12, y)
                    NUL:AttachTooltip(cb, help)
                    y = nyr
                end
            end
        end
    end

    local ignoreSync = NBK:GetModule("IgnoreSync")
    if ignoreSync and ignoreSync:IsAvailable() then
        local _, ny8 = Config:AddDivider(panel, y); y = ny8
        local _, ny9 = Config:AddSectionLabel(panel, y, "Ignore list"); y = ny9

        local _, ny10 = Config:AddCheckboxRow(panel, y,
            "Also add muted players to the game's ignore list",
            {"autoIgnore"}, false); y = ny10

        local capNote = NUL:CreateLabel(panel, {
            text  = L["The game's ignore list holds far fewer players than your blacklist."]
                 or "The game's ignore list holds far fewer players than your blacklist.",
            size  = "xs",
            color = NUL:GetTheme().colors.text.muted,
        })
        capNote:SetPoint("TOPLEFT", 0, y)
        y = y - 18

    end

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
