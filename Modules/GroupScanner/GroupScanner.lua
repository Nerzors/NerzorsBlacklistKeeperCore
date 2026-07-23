local _, NBK = ...

local GroupScanner = NBK:RegisterModule("GroupScanner")

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
    local reason = (entry.reason and entry.reason ~= "") and entry.reason or L["no reason logged"]

    if gw.chat ~= false then

        local msg = (L["Group warning: %s-%s is on your blacklist - %s"]):format(
            ("|cff%s%s|r"):format(color, entry.name), entry.realm, reason)
        NBK:Print("|cffff6666" .. msg .. "|r")
    end

    if gw.popup ~= false then
        StaticPopup_Show("NBK_GROUP_WARNING",
            entry.name .. "-" .. entry.realm,
            reason)
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

local function scan()
    wipe(currentKeys)

    if not IsInGroup() then
        wipe(warned)
        notifyListeners()
        return
    end

    for _, unit in ipairs(collectUnits()) do
        if UnitExists(unit) and UnitIsPlayer(unit) then
            local name, realm = UnitName(unit)
            if name then
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

function GroupScanner:IsInGroup(name, realm)
    local key = NBK:NormalizeKey(name, realm)
    return key and currentKeys[key] == true or false
end

function GroupScanner:OnRosterChanged(callback)
    table.insert(rosterListeners, callback)
end

function GroupScanner:OnEnable()
    local L = NBK.L
    StaticPopupDialogs["NBK_GROUP_WARNING"] = {
        text = "|cffff6666NBK - " .. L["Blacklisted"] .. "|r\n\n|cffffffff%s|r\n\n" .. L["Reason"] .. ": %s",
        button1 = L["Open list"],
        button2 = CLOSE or L["Close"],
        OnAccept = function()
            local lw = NBK:GetModule("ListWindow")
            if lw then lw:Show() end
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
        showAlert = true,
    }

    NBK:RegisterEvent("GROUP_ROSTER_UPDATE", scan)
    NBK:RegisterEvent("PLAYER_ENTERING_WORLD", scan)
end
