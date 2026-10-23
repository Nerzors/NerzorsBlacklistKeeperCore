local _, NBK = ...
local NUL = LibStub("NerzorsUILib-1.0")

local IgnoreManager = NBK:RegisterModule("IgnoreManager")

IgnoreManager.CAP = 50

local DELETED_WINDOW = 10

local function ignoreSync()
    local s = NBK:GetModule("IgnoreSync")
    return (s and s:IsAvailable()) and s or nil
end

function IgnoreManager:IsAvailable()
    return ignoreSync() ~= nil
end

local function store()
    local db = NBK.db
    if not db then return nil end
    db.ignore         = db.ignore or {}
    db.ignore.chars   = db.ignore.chars or {}
    db.ignore.deleted = db.ignore.deleted or {}
    return db.ignore
end

local function charKey()
    local name  = UnitName("player")
    local realm = GetNormalizedRealmName and GetNormalizedRealmName() or GetRealmName()
    if not name or not realm then return nil end
    return name .. "-" .. realm
end

function IgnoreManager:_CharData(create)
    local s, k = store(), charKey()
    if not s or not k then return nil end
    local c = s.chars[k]
    if not c and create then
        c = { names = {} }
        s.chars[k] = c
    end
    return c
end

IgnoreManager._removing = {}

function IgnoreManager:Snapshot()
    local IS = ignoreSync()
    if not IS or not self._ready then return {} end
    local c = self:_CharData(true)
    if not c then return {} end

    local now = time()
    c.firstScanAt = c.firstScanAt or now

    local present = {}
    for _, full in ipairs(IS:GetIgnoreList()) do
        local key = NBK:NormalizeKey(full)
        if key then
            present[key] = true
            local rec = c.names[key]
            if rec then rec.full = full else c.names[key] = { first = now, full = full } end
        end
    end

    local vanished = {}
    for key, rec in pairs(c.names) do
        if not present[key] then
            if self._removing[key] then
                self._removing[key] = nil
            else
                vanished[#vanished + 1] = { key = key, full = rec.full or key }
            end
            c.names[key] = nil
        end
    end
    c.scannedAt = now
    return vanished
end

function IgnoreManager:_OnListUpdate()
    self._ready = true
    local vanished = self:Snapshot()
    if #vanished > 0 then
        self._lastVanished = { at = time(), list = vanished }
    end
    self:_MatchDeleted()
    self:RefreshTab()
end

function IgnoreManager:_OnSystemMessage(msg)
    if issecretvalue and issecretvalue(msg) then return end
    if type(msg) ~= "string" or not ERR_IGNORE_DELETED or msg ~= ERR_IGNORE_DELETED then return end

    self._deletedSeen = (self._deletedSeen or 0) + 1
    self._deletedAt   = time()

    if not self._deletedTimer and C_Timer and C_Timer.After then
        self._deletedTimer = true
        C_Timer.After(1, function()
            self._deletedTimer = nil
            self:_MatchDeleted()
        end)
    end
end

function IgnoreManager:_MatchDeleted()
    local seen = self._deletedSeen or 0
    if seen == 0 then return end
    if time() - (self._deletedAt or 0) > DELETED_WINDOW then
        self._deletedSeen = 0
        return
    end
    local last = self._lastVanished
    if not last or time() - last.at > DELETED_WINDOW then return end

    self._deletedSeen, self._lastVanished = 0, nil
    if #last.list <= seen then self:_ReportDeleted(last.list) end
end

function IgnoreManager:_ReportDeleted(vanished)
    local L, s = NBK.L, store()
    local stillListed = {}
    for _, v in ipairs(vanished) do
        if s then s.deleted[v.key] = time() end
        NBK:Print(L["%s no longer exists - the game removed it from your ignore list."]:format(v.full))
        local entry = NBK:GetPlayer(v.key)
        if entry then stillListed[#stillListed + 1] = entry end
    end
    if #stillListed == 0 then return end

    NUL:Confirm({
        id   = "NBK_IGNORE_DELETED",
        text = L["Characters that no longer exist are still on your blacklist: %d. Remove them from the blacklist?"]
                :format(#stillListed),
        onAccept = function()
            for _, entry in ipairs(stillListed) do

                entry.ignoredByNBK = false
                NBK:RemovePlayer(entry.name, entry.realm)
            end
            local lw = NBK:GetModule("ListWindow")
            if lw and lw.Refresh then lw:Refresh() end
        end,
    })
end

function IgnoreManager:GetEntries()
    local out, IS = {}, ignoreSync()
    if not IS then return out end
    local c = self:_CharData(false)
    for _, full in ipairs(IS:GetIgnoreList()) do
        local key, name, realm = NBK:NormalizeKey(full)
        if key then
            local rec = c and c.names[key]
            local bl  = NBK:GetPlayer(name, realm)
            out[#out + 1] = {
                key         = key,
                full        = full,
                name        = (bl and bl.name) or name,
                realm       = (bl and bl.realm) or realm,
                class       = bl and bl.class,
                since       = rec and rec.first,
                sinceBefore = rec and c.firstScanAt and rec.first <= c.firstScanAt,
                bl          = bl,
            }
        end
    end
    return out
end

function IgnoreManager:Count()
    local IS = ignoreSync()
    return IS and #IS:GetIgnoreList() or 0
end

function IgnoreManager:RequestList()
    if not self._ready and C_FriendList and C_FriendList.ShowFriends then
        C_FriendList.ShowFriends()
    end
end

function IgnoreManager:Remove(entries, alsoBlacklist)
    local IS = ignoreSync()
    if not IS or #entries == 0 then return end
    local L = NBK.L
    local removed, fromBlacklist = 0, 0

    for _, e in ipairs(entries) do
        if e.bl then

            NBK:UpdateEntry(e.name, e.realm, { ignoredByNBK = false })
            if alsoBlacklist and NBK:RemovePlayer(e.name, e.realm) then
                fromBlacklist = fromBlacklist + 1
            end
        end
        self._removing[e.key] = true
        if IS:Remove(e.name, e.realm) then removed = removed + 1 end
    end

    NBK:Print(L["Removed from the ignore list: %d"]:format(removed))
    if fromBlacklist > 0 then
        NBK:Print(L["Removed from the blacklist: %d"]:format(fromBlacklist))
    end
    local lw = NBK:GetModule("ListWindow")
    if lw and lw.Refresh then lw:Refresh() end
end

function IgnoreManager:Import(entries)
    local IS = ignoreSync()
    if not IS then return 0 end
    local fulls = {}
    for _, e in ipairs(entries) do
        if not e.bl then fulls[#fulls + 1] = e.full end
    end
    local added = IS:ImportNames(fulls)
    NBK:Print(NBK.L["Imported %d player(s) from the ignore list."]:format(added))
    self:RefreshTab()
    return added
end

function IgnoreManager:RefreshTab() end

function IgnoreManager:OnEnable()
    if not self:IsAvailable() then return end

    pcall(function()
        NBK:RegisterEvent("IGNORELIST_UPDATE", function() self:_OnListUpdate() end)
    end)
    pcall(function()
        NBK:RegisterEvent("CHAT_MSG_SYSTEM", function(_, msg) self:_OnSystemMessage(msg) end)
    end)
    self:RequestList()
end
