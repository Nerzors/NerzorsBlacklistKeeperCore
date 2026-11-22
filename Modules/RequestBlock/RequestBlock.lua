local _, NBK = ...

local RequestBlock = NBK:RegisterModule("RequestBlock")

local function isSecret(v) return issecretvalue ~= nil and issecretvalue(v) and true or false end

local function hidePopup(which)
    if StaticPopup_Hide then pcall(StaticPopup_Hide, which) end
end

RequestBlock.KINDS = {
    {
        key = "trade", setting = "trade", event = "TRADE_SHOW",
        who = function() return UnitName("NPC") end,
        available = function() return type(CancelTrade) == "function" end,
        decline = function() CancelTrade() end,
        text = "Trade with %s declined (blacklist, muted).",
    },
    {
        key = "party", setting = "party", event = "PARTY_INVITE_REQUEST",
        who = function(name) return name end,
        available = function() return type(DeclineGroup) == "function" end,
        decline = function() DeclineGroup() end,
        hide = function() hidePopup("PARTY_INVITE") end,
        text = "Group invite from %s declined (blacklist, muted).",
    },
    {
        key = "duel", setting = "duel", event = "DUEL_REQUESTED",
        who = function(name) return name end,
        available = function() return type(CancelDuel) == "function" end,
        decline = function() CancelDuel() end,
        hide = function() hidePopup("DUEL_REQUESTED") end,
        text = "Duel request from %s declined (blacklist, muted).",
    },
    {
        key = "petduel", setting = "duel", event = "PET_BATTLE_PVP_DUEL_REQUESTED",
        who = function(name) return name end,
        available = function()
            return type(C_PetBattles) == "table" and type(C_PetBattles.CancelPVPDuel) == "function"
        end,
        decline = function() C_PetBattles.CancelPVPDuel() end,
        hide = function() hidePopup("PET_BATTLE_PVP_DUEL_REQUESTED") end,
        text = "Pet battle duel from %s declined (blacklist, muted).",
    },
    {
        key = "guild", setting = "guild", event = "GUILD_INVITE_REQUEST",
        who = function(name) return name end,
        available = function() return type(DeclineGuild) == "function" end,
        decline = function() DeclineGuild() end,
        hide = function()
            hidePopup("GUILD_INVITE")
            if GuildInviteFrame and GuildInviteFrame.Hide then pcall(GuildInviteFrame.Hide, GuildInviteFrame) end
        end,
        text = "Guild invite from %s declined (blacklist, muted).",
    },
}

RequestBlock._registered = {}
RequestBlock._log        = {}
RequestBlock._told       = {}
RequestBlock._blocked    = {}

local LOG_MAX = 8

local function log(kind, who, result)
    table.insert(RequestBlock._log, 1, {
        at = date and date("%H:%M:%S") or "", kind = kind, who = who, result = result,
    })
    RequestBlock._log[LOG_MAX + 1] = nil
end

function RequestBlock:IsOn(setting)
    local s = NBK.db and NBK.db.settings and NBK.db.settings.requestBlock
    return not (type(s) == "table" and s[setting] == false)
end

function RequestBlock.Resolve(name, realm)
    if name == nil then return nil end
    if isSecret(name) or (realm ~= nil and isSecret(realm)) then return nil, nil, true end
    if type(name) ~= "string" or name == "" then return nil end
    if realm == "" then realm = nil end
    name, realm = NBK:FromUnitName(name, realm)
    if realm == nil then
        local n, r = name:match("^(.-)%-(.+)$")
        if n and n ~= "" then name, realm = n, r end
    end
    if realm == nil or realm == "" then
        realm = (GetNormalizedRealmName and GetNormalizedRealmName()) or (GetRealmName and GetRealmName())
    end
    return name, realm
end

function RequestBlock:Handle(kind, ...)
    local okWho, rawName, rawRealm = pcall(kind.who, ...)
    if not okWho then log(kind.key, "?", "error: " .. tostring(rawName)); return "error" end
    local name, realm, secret = RequestBlock.Resolve(rawName, rawRealm)
    if secret then log(kind.key, "(secret)", "secret"); return "secret" end
    if not name then log(kind.key, "?", "unknown"); return "unknown" end
    local who = name .. "-" .. tostring(realm)
    if not self:IsOn(kind.setting) then log(kind.key, who, "off"); return "off" end
    if not NBK:IsMuted(name, realm) then log(kind.key, who, "not muted"); return "not muted" end

    local ok, err = pcall(kind.decline)
    local result = ok and "declined" or ("error: " .. tostring(err))
    log(kind.key, who, result)
    if not ok then return result end

    if kind.hide then
        pcall(kind.hide)
        if C_Timer and C_Timer.After then C_Timer.After(0, function() pcall(kind.hide) end) end
    end

    NBK:RecordEncounter(name, realm)
    local tellKey = kind.key .. "|" .. (NBK:NormalizeKey(name, realm) or who:lower())
    if not self._told[tellKey] then
        self._told[tellKey] = true
        local entry = NBK:GetPlayer(name, realm)
        local hex = NBK:GetClassHex(entry and entry.class or nil)
        NBK:Print(NBK.L[kind.text]:format(NBK:DisplayName(name, realm, hex)))
    end
    return result
end

function RequestBlock:Report()
    local out = {}
    for _, kind in ipairs(self.KINDS) do
        local okAvail, avail = pcall(kind.available)
        out[#out + 1] = ("%s: event %s=%s  decline=%s  setting %s=%s"):format(
            kind.key, kind.event, tostring(self._registered[kind.key]),
            tostring(okAvail and avail or false), kind.setting, self:IsOn(kind.setting) and "on" or "off")
    end
    if #self._log == 0 then
        out[#out + 1] = "log: (nothing yet - a muted blacklisted player has to trade / invite / duel you)"
    else
        for _, e in ipairs(self._log) do
            out[#out + 1] = ("log: %s %s %s -> %s"):format(e.at, e.kind, tostring(e.who), e.result)
        end
    end
    out[#out + 1] = ("blocked actions for NBK this session: %d%s"):format(#self._blocked,
        #self._blocked > 0 and (" (last: " .. tostring(self._blocked[1]) .. ")") or "")
    return out
end

function RequestBlock:OnEnable()
    for _, kind in ipairs(self.KINDS) do
        local okAvail, avail = pcall(kind.available)
        if okAvail and avail then
            local ok = pcall(NBK.RegisterEvent, NBK, kind.event, function(_, ...)
                self:Handle(kind, ...)
            end)
            self._registered[kind.key] = ok
        else
            self._registered[kind.key] = false
        end
    end

    for _, ev in ipairs({ "ADDON_ACTION_BLOCKED", "ADDON_ACTION_FORBIDDEN" }) do
        pcall(NBK.RegisterEvent, NBK, ev, function(event, addon, func)
            if type(addon) == "string" and addon:find("^NerzorsBlacklistKeeper") then
                table.insert(self._blocked, 1, event .. " " .. tostring(func))
                self._blocked[6] = nil
            end
        end)
    end
end
