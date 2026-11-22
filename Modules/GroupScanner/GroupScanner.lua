local _, NBK = ...
local NUL = LibStub("NerzorsUILib-1.0")

local GroupScanner = NBK:RegisterModule("GroupScanner")

local ALERT = "|TInterface\\DialogFrame\\UI-Dialog-Icon-AlertNew:18:18|t"

local warned = {}

local currentKeys = {}

local function groupWarning()
    local s = NBK.db and NBK.db.settings or {}
    return s.groupWarning or {}
end

local function collectUnits()
    local units = {}
    if IsInRaid() then
        for i = 1, GetNumGroupMembers() do
            units[#units+1] = "raid" .. i
        end
    elseif IsInGroup() then
        for i = 1, GetNumGroupMembers() - 1 do
            units[#units+1] = "party" .. i
        end
    end
    return units
end

local function warn(entry)
    local gw = groupWarning()
    if gw.enabled == false then return end

    local L = NBK.L
    local color  = NBK:GetClassHex(entry.class)
    local reason = (entry.reason and entry.reason ~= "") and NBK:ReasonText(entry.reason) or L["no reason logged"]

    if gw.chat ~= false then
        local msg = L["Group warning: %s is on your blacklist - %s"]:format(
            NBK:DisplayName(entry.name, entry.realm, color), reason)
        NBK:Print("|cffff6666" .. msg .. "|r")
    end

    if gw.popup ~= false then
        NUL:Confirm({
            id   = "NBK_GROUP_WARNING",
            text = ("%s |cffff6666%s|r\n\n%s\n\n%s: %s"):format(ALERT, L["Blacklisted"],
                       NBK:DisplayName(entry.name, entry.realm, color), L["Reason"], reason),
            acceptLabel = L["Open list"],
            cancelLabel = L["Close"],
            onAccept = function()
                local lw = NBK:GetModule("ListWindow")
                if lw then lw:Show() end
            end,
        })
    end

    if gw.sound then
        local path = NBK:SoundPath(gw.soundFile or "AirHorn")
        if path and PlaySoundFile then
            PlaySoundFile(path, "Master")
        end
    end
end

local rosterListeners = {}

local function notifyListeners()
    for _, fn in ipairs(rosterListeners) do
        local ok, err = pcall(fn)
        if not ok then
            geterrorhandler()(err)
        end
    end
end

local function isSecret(v) return issecretvalue ~= nil and issecretvalue(v) and true or false end
local sawSecret = false

local function scan()
    wipe(currentKeys)
    sawSecret = false

    if not IsInGroup() then
        wipe(warned)
        notifyListeners()
        return
    end

    for _, unit in ipairs(collectUnits()) do
        if UnitExists(unit) and UnitIsPlayer(unit) then
            local name, realm = NBK:UnitPlayer(unit)
            if isSecret(name) or isSecret(realm) then
                sawSecret = true
            elseif name then
                if not realm or realm == "" then
                    realm = GetNormalizedRealmName()
                end

                NBK:TryEnrichClass(name, realm, unit)

                local key = NBK:NormalizeKey(name, realm)
                if key then
                    currentKeys[key] = true
                    if not warned[key] and NBK:IsBlacklisted(name, realm) then
                        warned[key] = true
                        local entry = NBK:GetPlayer(name, realm)
                        if entry then
                            warn(entry)
                            NBK:RecordEncounter(name, realm)
                        end
                    end
                end
            end
        end
    end

    notifyListeners()
end

GroupScanner.scan = scan
GroupScanner._Warn = warn

function GroupScanner:IsInGroup(name, realm)
    local key = NBK:NormalizeKey(name, realm)
    return key and currentKeys[key] == true or false
end

function GroupScanner:OnRosterChanged(callback)
    table.insert(rosterListeners, callback)
end

function GroupScanner:OnEnable()
    NBK:RegisterEvent("GROUP_ROSTER_UPDATE", scan)
    NBK:RegisterEvent("PLAYER_ENTERING_WORLD", scan)
    NBK:RegisterEvent("PLAYER_REGEN_ENABLED", function()
        if sawSecret then scan() end
    end)
end
