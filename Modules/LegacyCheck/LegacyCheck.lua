local _, NBK = ...
local NUL = LibStub("NerzorsUILib-1.0")

local LegacyCheck = NBK:RegisterModule("LegacyCheck")

local PREFIX  = "NerzorsBlacklistKeeper"
local CHROME  = 28 + 1 + 12 * 2

local FOLDERS = {
    retail  = "_retail_",
    era     = "_classic_era_, _anniversary_",
    mop     = "_classic_",
    forever = "_forever_",
}
local ALL_FOLDERS = "_retail_, _classic_, _classic_era_, _anniversary_, _forever_"

local REASONS = {
    merged       = "Now part of the core - no longer needed.",
    discontinued = "No longer supported and discontinued.",
}

local ui = {}

function LegacyCheck:Find()
    local out = {}
    for _, m in ipairs(NBK.REMOVED_MODULES or {}) do
        local folder = PREFIX .. m.tag
        if NBK:AddOnExists(folder) and NBK:IsAddOnEnabled(folder) then
            out[#out + 1] = { folder = folder, reason = m.reason }
        end
    end
    return out
end

local function disableAddOn(folder)
    local disable = (C_AddOns and C_AddOns.DisableAddOn) or DisableAddOn
    if disable then pcall(disable, folder) end
end

function LegacyCheck:DisableAndReload(found)
    for _, f in ipairs(found) do disableAddOn(f.folder) end
    local reload = (C_UI and C_UI.Reload) or ReloadUI
    if reload then reload() end
end

function LegacyCheck:DisableRetailOnly()
    if NBK:IsRetail() then return {} end
    local off = {}
    for _, tag in ipairs(NBK.RETAIL_ONLY_MODULES or {}) do
        local folder = PREFIX .. tag
        if NBK:AddOnExists(folder) and NBK:IsAddOnEnabled(folder)
           and not NBK:IsAddOnLoadable(folder) then
            disableAddOn(folder)
            off[#off + 1] = NBK:GetModuleLabel(tag)
        end
    end
    if #off > 0 then
        NBK:Print(NBK.L["Only available on Retail, so turned off on this client: %s"]
            :format(table.concat(off, ", ")))
    end
    return off
end

local function fitHeight()
    local h = 0
    for _, fs in ipairs({ ui.intro, ui.list, ui.advice, ui.howto }) do
        h = h + math.max(14, fs:GetStringHeight() or 0)
    end
    ui.f:SetHeight(math.ceil(h + 3 * 10 + 16 + 26 + CHROME))
end

local function build()
    if ui.f then return ui.f end
    local L, theme = NBK.L, NUL:GetTheme()

    local f = NUL:Window({
        name   = "NBKLegacyModulesWindow",
        title  = L["NBK Core Information"],
        width  = 520, height = 300,
        strata = "DIALOG",
    })
    ui.f = f

    local function label(anchor, opts)
        local fs = NUL:CreateLabel(f.content, opts)
        fs:SetJustifyH("LEFT")
        if anchor then
            fs:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -10)
            fs:SetPoint("TOPRIGHT", anchor, "BOTTOMRIGHT", 0, -10)
        else
            fs:SetPoint("TOPLEFT", 0, 0)
            fs:SetPoint("TOPRIGHT", 0, 0)
        end
        return fs
    end

    ui.intro  = label(nil, { text = L["You still have outdated NBK sub-addons enabled in your AddOns folder:"],
                             color = theme.colors.text.primary })
    ui.list   = label(ui.intro,  { text = "", color = theme.colors.text.primary })
    ui.advice = label(ui.list,   { text = L["You can delete or disable them; we recommend deleting them."],
                                   color = theme.colors.text.primary })
    ui.howto  = label(ui.advice, {
        text  = L["To delete them: in the Battle.net app, click the cog next to 'Play' and choose 'Show in Explorer' (Mac: 'Show in Finder'). In the folder of your game version (%s) open %s and delete the folders listed above."]
                    :format(FOLDERS[NBK:GetFlavor()] or ALL_FOLDERS, "Interface\\AddOns"),
        size  = "sm",
        color = theme.colors.text.muted,
    })

    ui.disable = NUL:Button(f.content, {
        label = L["Disable and reload"], width = 170, height = 26, style = "primary",
        onClick = function()
            f:Hide()
            LegacyCheck:DisableAndReload(ui.found or {})
        end,
    })
    ui.disable:SetPoint("BOTTOMRIGHT", 0, 0)

    local close = NUL:Button(f.content, {
        label = L["Got it"], width = 110, height = 26,
        onClick = function() f:Hide() end,
    })
    close:SetPoint("RIGHT", ui.disable, "LEFT", -6, 0)

    f:HookScript("OnShow", function()
        if C_Timer and C_Timer.After then C_Timer.After(0, fitHeight) end
    end)
    return f
end

function LegacyCheck:Show(found)
    if not found or #found == 0 then return end
    local L = NBK.L
    local f = build()
    ui.found = found

    local accent = NUL.ToHex(NUL:GetTheme().colors.accent.primary)
    local lines = {}
    for _, item in ipairs(found) do
        local why = REASONS[item.reason]
        lines[#lines + 1] = ("• |cff%s%s|r%s"):format(accent, item.folder,
            why and (": " .. L[why]) or "")
    end
    ui.list:SetText(table.concat(lines, "\n"))

    fitHeight()
    f:Show()
end

function LegacyCheck:OnEnable()

    local function check()
        LegacyCheck:DisableRetailOnly()
        LegacyCheck:Show(LegacyCheck:Find())
    end
    if C_Timer and C_Timer.After then
        C_Timer.After(2, check)
    else
        check()
    end
end
