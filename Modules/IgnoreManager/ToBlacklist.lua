local _, NBK = ...
local NUL = LibStub("NerzorsUILib-1.0")

local ToBL = NBK:RegisterModule("IgnoreToBlacklist")

local WAIT = 10
local CONFIRM_ID = "NBK_IGNORE_TO_BLACKLIST"

local function settings() return NBK.db and NBK.db.settings or {} end

local function ignoreSync()
    local s = NBK:GetModule("IgnoreSync")
    return (s and s:IsAvailable()) and s or nil
end

local function core() return NBK:GetModule("IgnoreManager") end

local function now() return GetTime and GetTime() or time() end

local function isSecret(v) return issecretvalue ~= nil and issecretvalue(v) and true or false end

local function listEntry(key)
    for _, full in ipairs(ignoreSync():GetIgnoreList()) do
        if NBK:NormalizeKey(full) == key then return full end
    end
    return nil
end

local function refresh()
    local lw = NBK:GetModule("ListWindow")
    if lw and lw.Refresh then lw:Refresh() end
    local im = core()
    if im and im.RefreshTab then im:RefreshTab() end
end

ToBL._waiting = {}
ToBL._queue   = {}
ToBL._asking  = false

function ToBL:_AskingWanted()
    local s = settings()
    return s.askOnIgnore ~= false and not s.autoImportIgnore
end

function ToBL:_OnIgnoreCall(arg)
    local sync = ignoreSync()
    if not sync or sync._ownAdd then return end
    if isSecret(arg) or type(arg) ~= "string" or arg == "" then return end
    if not self:_AskingWanted() then return end
    local im = core()
    if not (im and im._ready) then return end
    local key = NBK:NormalizeKey(arg)
    if not key then return end

    local c = im:_CharData(false)
    local rec = c and c.names[key]
    if rec and (rec.first or 0) < time() - 1 then return end
    self._seq = (self._seq or 0) + 1
    self._waiting[key] = { at = now(), seq = self._seq }
    if C_Timer and C_Timer.After then
        C_Timer.After(WAIT + 1, function() self:_CheckWaiting() end)
    end
end

function ToBL:_CheckWaiting()
    if not next(self._waiting) then return end
    if not self:_AskingWanted() then wipe(self._waiting) return end
    local t, found = now(), {}
    for key, w in pairs(self._waiting) do
        local full = listEntry(key)
        if full then
            self._waiting[key] = nil
            if not NBK:GetPlayer(full) then found[#found + 1] = { full = full, seq = w.seq } end
        elseif t - w.at > WAIT then
            self._waiting[key] = nil
        end
    end

    table.sort(found, function(a, b) return a.seq < b.seq end)
    for _, f in ipairs(found) do self:_Enqueue(f.full) end
end

function ToBL:_Enqueue(full)
    for _, f in ipairs(self._queue) do if f == full then return end end
    self._queue[#self._queue + 1] = full
    if not self._asking then self:_AskNext() end
end

function ToBL:_AskNext()
    local full
    repeat
        full = table.remove(self._queue, 1)
    until not full or (self:_AskingWanted() and not NBK:GetPlayer(full))
    if not full then self._asking = false return end

    self._asking = true
    local L = NBK.L
    NUL:Confirm({
        id         = CONFIRM_ID,
        text       = L["You ignored %s. Put them on your blacklist too?"]:format(full),
        checkLabel = L["Don't ask again"],
        onAccept   = function(stop) self:_Add(full); self:_Answered(stop) end,
        onCancel   = function(stop) self:_Answered(stop) end,
    })
end

function ToBL:_Answered(stop)
    if stop then
        settings().askOnIgnore = false
        wipe(self._queue)
        wipe(self._waiting)
        self._asking = false
        NBK:Print(NBK.L["NBK won't ask any more. You can turn the question back on under Settings > Notifications > Ignore list."])
        return
    end
    self:_AskNext()
end

function ToBL:_Add(full)
    local sync = ignoreSync()
    if sync and sync:ImportNames({ full }) > 0 then refresh() end
end

function ToBL:AutoImport()
    if not settings().autoImportIgnore then return 0 end
    local sync, im = ignoreSync(), core()
    if not sync or not (im and im._ready) then return 0 end
    local c = im:_CharData(false)
    local fulls = {}
    for _, u in ipairs(sync:GetUntracked()) do
        local key = NBK:NormalizeKey(u.full)
        local rec = c and key and c.names[key]
        if not (rec and rec.noBlacklist) then fulls[#fulls + 1] = u.full end
    end
    if #fulls == 0 then return 0 end

    local added = sync:ImportNames(fulls)
    if added > 0 then
        NBK:Print(NBK.L["Put on the blacklist automatically from your ignore list: %d"]:format(added))
        refresh()
    end
    return added
end

function ToBL:_OnListUpdate()
    if settings().autoImportIgnore then
        wipe(self._waiting)
        self:AutoImport()
    else
        self:_CheckWaiting()
    end
end

function ToBL:_OnEntryRemoved(entry)
    if type(entry) ~= "table" then return end
    local key = NBK:NormalizeKey(entry.name, entry.realm)
    local db = NBK.db and NBK.db.ignore
    if not key or not db or not db.chars then return end
    for _, c in pairs(db.chars) do
        local rec = c.names and c.names[key]
        if rec then rec.noBlacklist = true end
    end
end

function ToBL:OnEnable()
    local sync, im = ignoreSync(), core()
    if not sync or not im then return end

    local function onCall(arg) pcall(ToBL._OnIgnoreCall, ToBL, arg) end
    for _, fn in ipairs({ "AddOrDelIgnore", "AddIgnore" }) do
        if C_FriendList and type(C_FriendList[fn]) == "function" then
            pcall(hooksecurefunc, C_FriendList, fn, onCall)
        end
    end
    hooksecurefunc(im, "_OnListUpdate", function() ToBL:_OnListUpdate() end)
    hooksecurefunc(sync, "OnEntryRemoved", function(_, entry) ToBL:_OnEntryRemoved(entry) end)

    if im._ready then self:_OnListUpdate() end
end
