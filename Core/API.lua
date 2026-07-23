local _, NBK = ...

local API = NBK:RegisterModule("API")

local function classInfoFromFile(classFile)
    return classFile, classFile and NBK:GetClassHex(classFile) or nil
end

local function classInfoFromUnit(unit)
    if not unit or not UnitExists(unit) then return nil, nil end
    local _, classFile = UnitClass(unit)
    return classInfoFromFile(classFile)
end

local CANDIDATE_UNITS = { "target", "focus", "mouseover" }
local function findUnitForPlayer(name, realm)
    if not name then return nil end
    local myRealm = GetNormalizedRealmName() or GetRealmName() or ""
    realm = (realm and realm ~= "") and realm or myRealm

    local function matches(unit)
        if not UnitExists(unit) or not UnitIsPlayer(unit) then return false end
        local n, r = UnitName(unit)
        if n ~= name then return false end
        r = (r and r ~= "") and r or myRealm
        return r == realm
    end

    for _, u in ipairs(CANDIDATE_UNITS) do
        if matches(u) then return u end
    end
    for i = 1, 4 do
        local u = "party" .. i
        if matches(u) then return u end
    end
    for i = 1, 40 do
        local u = "raid" .. i
        if matches(u) then return u end
    end
    return nil
end

local function classFromGuild(name, realm)
    if not IsInGuild or not IsInGuild() then return nil end
    if not GetNumGuildMembers or not GetGuildRosterInfo then return nil end
    local myRealm = GetNormalizedRealmName() or GetRealmName() or ""
    realm = (realm and realm ~= "") and realm or myRealm
    local num = GetNumGuildMembers() or 0
    for i = 1, num do
        local fullname, _, _, _, _, _, _, _, _, _, classFile = GetGuildRosterInfo(i)
        if type(fullname) == "string" and fullname ~= "" then
            local n, r = strsplit("-", fullname, 2)
            local rr = (r and r ~= "") and r or myRealm
            if n == name and rr == realm and classFile then
                return classFile
            end
        end
    end
    return nil
end

local function classFromOurOwnData(name, realm)
    local recents = NBK.GetModule and NBK:GetModule("Recents")
    if recents and recents.GetEntries then
        local list = recents:GetEntries()
        for _, e in ipairs(list) do
            if e.name == name and (e.realm or "") == (realm or "") and e.class then
                return e.class
            end
        end
    end
    local rm = NBK.GetModule and NBK:GetModule("RememberMe")
    if rm and rm.GetEntry then
        local entry = rm:GetEntry(name, realm)
        if entry and entry.class then return entry.class end
    end
    return nil
end

function NBK:ResolveClass(name, realm, unit)
    local classFile, hex = classInfoFromUnit(unit)
    if classFile then return classFile, hex end

    local found = findUnitForPlayer(name, realm)
    if found then return classInfoFromUnit(found) end

    classFile = classFromGuild(name, realm)
    if classFile then return classInfoFromFile(classFile) end

    classFile = classFromOurOwnData(name, realm)
    if classFile then return classInfoFromFile(classFile) end

    return nil, nil
end

function NBK:AddPlayer(name, realm, reason, unit)
    local key, cleanName, cleanRealm = self:NormalizeKey(name, realm)
    if not key then return nil, "invalid name" end
    if self.db.entries[key] then return nil, "already blacklisted" end

    local class, classColor = self:ResolveClass(cleanName, cleanRealm, unit)
    local zone = GetRealZoneText() or GetZoneText() or ""
    local player = UnitName("player")
    local playerRealm = GetNormalizedRealmName and GetNormalizedRealmName() or GetRealmName()

    local settings = self.db and self.db.settings or {}
    local muteDefault      = settings.autoMute ~= false
    local shareableDefault = self:GetSyncSetting("defaultShareable", true) and true or false

    local entry = {
        name = cleanName,
        realm = cleanRealm,
        class = class,
        classColor = classColor,
        addedAt = time(),
        zone = zone,
        reason = reason or "",
        notes = "",
        mute = muteDefault,
        shareable = shareableDefault,
        addedBy = player .. "-" .. playerRealm,

        lastSeen        = nil,
        encounterCount  = 0,
        pinned          = false,
    }

    self.db.entries[key] = entry
    self:Print(("added |cff%s%s|r-%s"):format(self:GetClassHex(class), cleanName, cleanRealm))

    if self._FireApiEvent then
        self:_FireApiEvent("BLACKLIST_ENTRY_ADDED", cleanName, cleanRealm, entry)
    end
    return entry
end

function NBK:RemovePlayer(name, realm)
    local key = self:NormalizeKey(name, realm)
    if not key or not self.db.entries[key] then return false, "not found" end
    local entry = self.db.entries[key]
    self.db.entries[key] = nil
    self:Print(("removed %s-%s"):format(entry.name, entry.realm))
    if self._FireApiEvent then
        self:_FireApiEvent("BLACKLIST_ENTRY_REMOVED", entry.name, entry.realm)
    end
    return true
end

function NBK:GetPlayer(name, realm)
    local key = self:NormalizeKey(name, realm)
    return key and self.db.entries[key] or nil
end

function NBK:IsBlacklisted(name, realm)
    return self:GetPlayer(name, realm) ~= nil
end

function NBK:IsMuted(name, realm)
    local entry = self:GetPlayer(name, realm)
    if not entry then return false end
    return entry.mute ~= false
end

function NBK:GetEntries()
    return self.db.entries
end

function NBK:CountEntries()
    local n = 0
    for _ in pairs(self.db.entries) do n = n + 1 end
    return n
end

function NBK:GetSyncSetting(key, default)
    local db = self.GetAddonDB and self:GetAddonDB("Sync")
    if not db then return default end
    local v = db[key]
    if v == nil then return default end
    return v
end

function NBK:UpdateEntry(name, realm, fields)
    local entry = self:GetPlayer(name, realm)
    if not entry then return false, "not found" end
    for k, v in pairs(fields) do entry[k] = v end
    if self._FireApiEvent then
        self:_FireApiEvent("BLACKLIST_ENTRY_CHANGED", entry.name, entry.realm, entry)
    end
    return true
end

local ENCOUNTER_THROTTLE = 30 * 60
function NBK:RecordEncounter(name, realm)
    local entry = self:GetPlayer(name, realm)
    if not entry then return false end
    local now = time()
    local last = entry.lastSeen or 0
    if now - last > ENCOUNTER_THROTTLE then
        entry.encounterCount = (entry.encounterCount or 0) + 1
    end
    entry.lastSeen = now
    return true
end

function NBK:TryEnrichClass(name, realm, unit)
    local entry = self:GetPlayer(name, realm)
    if not entry or entry.class then return end
    local classFile, hex = self:ResolveClass(name, realm, unit)
    if classFile then
        entry.class = classFile
        entry.classColor = hex
    end
end

API.OnInitialize = function() end
