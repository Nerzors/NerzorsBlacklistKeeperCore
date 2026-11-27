local _, NBK = ...

local History = NBK:RegisterModule("RemovalHistory")

History.MIN, History.MAX, History.DEFAULT = 5, 25, 10

local function store()
    local db = NBK.db
    if not db then return nil end
    db.history = db.history or {}
    db.history.manual = db.history.manual or {}
    return db.history
end

local function copy(v)
    if type(v) ~= "table" then return v end
    local out = {}
    for k, x in pairs(v) do out[k] = copy(x) end
    return out
end

function History:Size()
    local n = tonumber(NBK.db and NBK.db.settings and NBK.db.settings.historySize) or self.DEFAULT
    return math.max(self.MIN, math.min(self.MAX, math.floor(n + 0.5)))
end

function History:Trim()
    local h = store()
    if not h then return end
    local n = self:Size()
    for i = #h.manual, n + 1, -1 do h.manual[i] = nil end
end

local function record(key, entry, lifted)
    return { key = key, entry = copy(entry), at = time(), lifted = lifted and true or false }
end

function History:Record(key, entry, lifted)
    local h = store()
    if not h or not key or type(entry) ~= "table" then return end
    local batch = NBK._removeBatch
    if batch then
        batch.items[#batch.items + 1] = record(key, entry, lifted)
        return
    end
    table.insert(h.manual, 1, record(key, entry, lifted))
    self:Trim()
    self:_Changed()
end

function History:StoreRun(source, items)
    local h = store()
    if not h or type(items) ~= "table" or #items == 0 then return end
    h.cleanup = { source = source, at = time(), items = items }
    self:_Changed()
end

function History:RecordRun(source, keys, entries, lifted)
    local items = {}
    for _, key in ipairs(keys or {}) do
        local e = entries and entries[key]
        if e then items[#items + 1] = record(key, e, lifted and lifted[key]) end
    end
    self:StoreRun(source, items)
end

function History:Manual() local h = store(); return h and h.manual or {} end
function History:Cleanup() local h = store(); return h and h.cleanup or nil end

function NBK:RunAsCleanup(source, fn)
    local outer = self._removeBatch
    if outer then return fn() end
    local batch = { source = source, items = {} }
    self._removeBatch = batch
    local ok, err = pcall(fn)
    self._removeBatch = nil
    History:StoreRun(source, batch.items)
    if not ok then error(err, 0) end
end

local function removeFrom(list, rec)
    for i, r in ipairs(list) do
        if r == rec then table.remove(list, i) return true end
    end
    return false
end

function History:Restore(rec, quiet)
    local L = NBK.L
    if type(rec) ~= "table" or not rec.key or type(rec.entry) ~= "table" then return false end
    local db = NBK.db
    if not db or not db.entries then return false end
    local e = rec.entry
    local h = store()

    if db.entries[rec.key] then

        if not quiet then NBK:Print(L["%s is already on your blacklist."]:format(NBK:DisplayName(e.name, e.realm))) end
    else
        local entry = copy(e)
        db.entries[rec.key] = entry

        local IS = NBK:GetModule("IgnoreSync")
        if rec.lifted and IS and IS:IsAvailable() and not IS:IsIgnored(entry.name, entry.realm) then
            if not IS:Add(entry.name, entry.realm) then entry.ignoredByNBK = false end
        end
        if NBK._FireApiEvent then NBK:_FireApiEvent("BLACKLIST_ENTRY_ADDED", entry.name, entry.realm, entry) end
        if not quiet then
            NBK:Print(L["Restored: %s"]:format(NBK:DisplayName(entry.name, entry.realm, NBK:GetClassHex(entry.class))))
        end
    end

    if h then
        if not removeFrom(h.manual, rec) and h.cleanup then
            removeFrom(h.cleanup.items, rec)
            if #h.cleanup.items == 0 then h.cleanup = nil end
        end
    end
    self:_Changed()
    return true
end

function History:RestoreRun()
    local run = self:Cleanup()
    if not run then return 0 end
    local n = 0
    local items = {}
    for i, r in ipairs(run.items) do items[i] = r end
    for _, r in ipairs(items) do
        if self:Restore(r, true) then n = n + 1 end
    end
    NBK:Print(NBK.L["Restored: %d"]:format(n))
    return n
end

History._listeners = {}
function History:OnChanged(fn) if type(fn) == "function" then self._listeners[#self._listeners + 1] = fn end end
function History:_Changed()
    for _, fn in ipairs(self._listeners) do pcall(fn) end
    local lw = NBK:GetModule("ListWindow")
    if lw and lw.Refresh then lw:Refresh() end
end
