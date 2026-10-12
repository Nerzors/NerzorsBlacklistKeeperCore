local _, NBK = ...
local NUL = LibStub("NerzorsUILib-1.0")

local BrokerLauncher = NBK:RegisterModule("BrokerLauncher")

local function logoTexture()

    local theme = NUL:GetTheme()
    return (theme and theme.media and theme.media.logo)
        or "Interface\\AddOns\\NerzorsBlacklistKeeper_Data\\Textures\\NerzorsBlacklistKeeper_Midnight_Logo"
end

function BrokerLauncher:OnEnable()
    if self._obj then return end
    local LDB = LibStub and LibStub:GetLibrary("LibDataBroker-1.1", true)
    if not LDB then return end

    local L = NBK.L
    self._obj = LDB:NewDataObject("NerzorsBlacklistKeeper", {
        type  = "launcher",
        label = L["Nerzors Blacklist Keeper"] or "Nerzors Blacklist Keeper",
        text  = L["Blacklist"] or "Blacklist",
        icon  = logoTexture(),
        OnClick = function(_, button)
            if button == "RightButton" then
                local cfg = NBK:GetModule("Config")
                if cfg then cfg:Toggle() end
            else
                local lw = NBK:GetModule("ListWindow")
                if lw then lw:Toggle() end
            end
        end,
        OnTooltipShow = function(tt)
            NBK:PopulateLauncherTooltip(tt)
        end,
    })
end

function BrokerLauncher:OnThemeChanged()
    if self._obj then self._obj.icon = logoTexture() end
end
