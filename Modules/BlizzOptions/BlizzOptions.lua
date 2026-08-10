local _, NBK = ...
local NUL = LibStub("NerzorsUILib-1.0")

local BlizzOptions = NBK:RegisterModule("BlizzOptions")

local function buildPanel()
    local L = NBK.L
    local theme = NUL:GetTheme()

    local panel = CreateFrame("Frame", "NBKBlizzOptionsPanel")

    local title = NUL:CreateLabel(panel, {
        text = L["Nerzors Blacklist Keeper"] or "Nerzors Blacklist Keeper",
        size = "xl", color = theme.colors.accent.primary,
    })
    title:SetPoint("TOPLEFT", 16, -16)

    local version = NUL:CreateLabel(panel, {
        text  = "v" .. tostring(NBK.version or "?"),
        size  = "sm", color = theme.colors.text.muted,
    })
    version:SetPoint("LEFT", title, "RIGHT", 8, -1)

    local desc = NUL:CreateLabel(panel, {
        text = L["All settings live in the addon's own window."]
            or "All settings live in the addon's own window.",
        size = "md", color = theme.colors.text.primary, justifyH = "LEFT",
    })
    desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -12)
    desc:SetPoint("RIGHT", panel, "RIGHT", -16, 0)

    local openBtn = NUL:Button(panel, {
        label = L["Open settings"] or "Open settings",
        width = 200, height = 28, style = "accent",
        onClick = function()

            if SettingsPanel and SettingsPanel:IsShown() then
                HideUIPanel(SettingsPanel)
            elseif InterfaceOptionsFrame and InterfaceOptionsFrame:IsShown() then
                HideUIPanel(InterfaceOptionsFrame)
            end
            local cfg = NBK:GetModule("Config")
            if cfg then cfg:Show() end
        end,
    })
    openBtn:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, -18)

    return panel
end

local function register(panel, name)
    if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then

        local category = Settings.RegisterCanvasLayoutCategory(panel, name)
        category.ID = name
        Settings.RegisterAddOnCategory(category)
        return category
    elseif InterfaceOptions_AddCategory then

        panel.name = name
        InterfaceOptions_AddCategory(panel)
        return panel
    end

end

function BlizzOptions:OnEnable()
    if self._panel then return end
    local name = (NBK.L and NBK.L["Nerzors Blacklist Keeper"]) or "Nerzors Blacklist Keeper"
    self._panel = buildPanel()
    self._category = register(self._panel, name)
end
