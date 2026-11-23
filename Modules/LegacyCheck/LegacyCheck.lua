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

function LegacyCheck:Disable(found)
    for _, f in ipairs(found) do disableAddOn(f.folder) end
end

function LegacyCheck:DisableAndReload(found)
    self:Disable(found)
    NBK:RequestReload()
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

    NBK:SecureReloadOver(ui.disable, function()
        f:Hide()
        LegacyCheck:Disable(ui.found or {})
    end)

    fitHeight()
    f:Show()
end

local REOFFER = {
    { tag = "_RememberMe",
      textKey = "Remember the players you enjoyed playing with: rate your party, add a note and see it in the tooltip." },
}

local BEFORE_OFFER = { "NBKLegacyModulesWindow", "NBKForeverNamesWindow" }

local function reofferState()
    local s = NBK.db and NBK.db.settings
    if type(s) ~= "table" then return nil end
    if type(s.reoffer) ~= "table" then s.reoffer = {} end
    return s.reoffer
end

local function loadsWhenEnabled(folder)
    local getInfo = (C_AddOns and C_AddOns.GetAddOnInfo) or GetAddOnInfo
    if not getInfo then return true end
    local ok, _, _, _, loadable, reason = pcall(getInfo, folder)
    if not ok or loadable then return true end
    return reason == nil or reason == "DISABLED"
end

function LegacyCheck:FindOffer()
    if NBK:IsRetail() then return nil end
    local state = reofferState()
    if not state then return nil end
    local offer
    for _, m in ipairs(REOFFER) do
        local folder = PREFIX .. m.tag
        if NBK:AddOnExists(folder) then
            if NBK:IsAddOnEnabled(folder) then
                state[m.tag] = state[m.tag] or "seen"
            elseif not offer and not state[m.tag] and loadsWhenEnabled(folder) then
                offer = { tag = m.tag, folder = folder, textKey = m.textKey }
            end
        end
    end
    return offer
end

function LegacyCheck:OfferStatus()
    local out, state = {}, reofferState() or {}
    local getInfo = (C_AddOns and C_AddOns.GetAddOnInfo) or GetAddOnInfo
    for _, m in ipairs(REOFFER) do
        local folder = PREFIX .. m.tag
        local loadable, reason
        if getInfo then
            local ok, _, _, _, l, r = pcall(getInfo, folder)
            if ok then loadable, reason = l, r end
        end
        local exists, enabled = NBK:AddOnExists(folder), NBK:IsAddOnEnabled(folder)
        local verdict
        if NBK:IsRetail() then           verdict = "no - Retail"
        elseif not exists then           verdict = "no - folder missing"
        elseif enabled then              verdict = "no - enabled (stamped seen)"
        elseif state[m.tag] then         verdict = "no - answer stored: " .. tostring(state[m.tag])
        elseif not loadsWhenEnabled(folder) then verdict = "no - the client would not load it"
        else                             verdict = "yes" end
        out[#out + 1] = ("%s: exists %s, enabled %s, loaded %s, loadable %s, reason %s, answer %s -> offer %s")
            :format(folder, tostring(exists), tostring(enabled), tostring(NBK:IsAddOnLoaded(folder)),
                    tostring(loadable), tostring(reason), tostring(state[m.tag]), verdict)
    end
    return out
end

local function enableAddOn(folder)
    local enable = (C_AddOns and C_AddOns.EnableAddOn) or EnableAddOn
    if enable then pcall(enable, folder) end
end

local offerUi = {}

local function fitOfferHeight()
    local h = 0
    for _, fs in ipairs({ offerUi.what, offerUi.why }) do
        h = h + math.max(14, fs:GetStringHeight() or 0)
    end
    offerUi.f:SetHeight(math.ceil(h + 10 + 16 + 26 + CHROME))
end

local function buildOffer()
    if offerUi.f then return offerUi.f end
    local L, theme = NBK.L, NUL:GetTheme()

    local f = NUL:Window({
        name   = "NBKReofferWindow",
        title  = L["NBK Core Information"],
        width  = 460, height = 200,
        strata = "DIALOG",
    })
    offerUi.f = f

    offerUi.what = NUL:CreateLabel(f.content, { text = "", color = theme.colors.text.primary })
    offerUi.what:SetJustifyH("LEFT")
    offerUi.what:SetPoint("TOPLEFT", 0, 0)
    offerUi.what:SetPoint("TOPRIGHT", 0, 0)

    offerUi.why = NUL:CreateLabel(f.content, {
        text  = L["An earlier NBK version turned it off on this client because it only ran on Retail. Turn it on now?"],
        color = theme.colors.text.primary,
    })
    offerUi.why:SetJustifyH("LEFT")
    offerUi.why:SetPoint("TOPLEFT", offerUi.what, "BOTTOMLEFT", 0, -10)
    offerUi.why:SetPoint("TOPRIGHT", offerUi.what, "BOTTOMRIGHT", 0, -10)

    offerUi.enable = NUL:Button(f.content, {
        label = L["Enable and reload"], width = 170, height = 26, style = "primary",
        onClick = function() LegacyCheck:AnswerOffer(true) end,
    })
    offerUi.enable:SetPoint("BOTTOMRIGHT", 0, 0)

    local no = NUL:Button(f.content, {
        label = L["No thanks"], width = 110, height = 26,
        onClick = function() LegacyCheck:AnswerOffer(false) end,
    })
    no:SetPoint("RIGHT", offerUi.enable, "LEFT", -6, 0)

    f:HookScript("OnShow", function()
        if C_Timer and C_Timer.After then C_Timer.After(0, fitOfferHeight) end
    end)

    f:HookScript("OnHide", function()
        local o = offerUi.offer
        if not o or offerUi.answered then return end
        offerUi.answered = true
        local label = NBK:GetModuleLabel(o.tag)
        NBK:Print(L["You can turn on %s any time in the AddOns list."]:format(label))
    end)
    return f
end

function LegacyCheck:ShowOffer(offer)
    if not offer then return end
    local L = NBK.L
    local state = reofferState()
    if state then state[offer.tag] = "asked" end
    local f = buildOffer()
    offerUi.offer, offerUi.answered = offer, false

    local accent = NUL.ToHex(NUL:GetTheme().colors.accent.primary)
    local label = NBK:GetModuleLabel(offer.tag)
    offerUi.what:SetText(("|cff%s%s|r\n%s"):format(accent,
        L["%s is now available here too"]:format(label), L[offer.textKey]))

    NBK:SecureReloadOver(offerUi.enable, function() LegacyCheck:AnswerOffer(true, true) end)

    fitOfferHeight()
    f:Show()
end

function LegacyCheck:AnswerOffer(yes, viaSecure)
    local o = offerUi.offer
    if not o then return end
    local state = reofferState()
    if yes then
        if state then state[o.tag] = "enabled" end
        offerUi.answered = true
        enableAddOn(o.folder)
        if not viaSecure then NBK:RequestReload() end
    else
        if state then state[o.tag] = "declined" end
        if offerUi.f then offerUi.f:Hide() end
    end
end

function LegacyCheck:_TryOffer()
    for _, name in ipairs(BEFORE_OFFER) do
        local w = _G[name]
        if w and w:IsShown() then
            self._offerHooked = self._offerHooked or {}
            if not self._offerHooked[name] then
                self._offerHooked[name] = true
                w:HookScript("OnHide", function()
                    if not self._offerWaiting then return end
                    if C_Timer and C_Timer.After then
                        C_Timer.After(0.5, function() self:_TryOffer() end)
                    else
                        self:_TryOffer()
                    end
                end)
            end
            self._offerWaiting = true
            return
        end
    end
    self._offerWaiting = nil

    self:ShowOffer(self:FindOffer())
end

function LegacyCheck:OnEnable()

    local function check()
        LegacyCheck:DisableRetailOnly()
        LegacyCheck:Show(LegacyCheck:Find())
        if C_Timer and C_Timer.After then
            C_Timer.After(2, function() LegacyCheck:_TryOffer() end)
        else
            LegacyCheck:_TryOffer()
        end
    end
    if C_Timer and C_Timer.After then
        C_Timer.After(2, check)
    else
        check()
    end
end
