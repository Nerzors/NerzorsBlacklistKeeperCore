local _, NBK = ...

local ForeverRealm = {}
NBK.ForeverRealm = ForeverRealm

local function earlier(a, b)
    if a and (not b or a < b) then return a end
    return b
end

local function later(a, b)
    if a and (not b or a > b) then return a end
    return b
end

local function bareKey(key)
    if type(key) ~= "string" then return key end
    local n = key:match("^(.-)%-")
    return n and (n .. "-") or key
end

local function mergeEntry(older, newer)
    local a, b = older.notes or "", newer.notes or ""
    if b ~= "" and b ~= a then older.notes = (a ~= "") and (a .. " / " .. b) or b end
    if (older.reason or "") == "" then older.reason = newer.reason end
    older.encounterCount = (older.encounterCount or 0) + (newer.encounterCount or 0)
    older.lastSeen   = later(older.lastSeen, newer.lastSeen)
    older.class      = older.class or newer.class
    older.classColor = older.classColor or newer.classColor
    older.role       = older.role or newer.role
    older.pinned       = (older.pinned or newer.pinned) and true or false
    older.mute         = (older.mute or newer.mute) and true or false
    older.ignoredByNBK = (older.ignoredByNBK or newer.ignoredByNBK) and true or false
end

local function switchEntries(entries)
    local moved, merged = 0, 0
    if type(entries) ~= "table" then return moved, merged end
    local out = {}
    for key, e in pairs(entries) do
        if type(e) == "table" and type(e.name) == "string" then
            local newKey = NBK:NormalizeKey(e.name, e.realm)
            if newKey ~= key or (e.realm or "") ~= "" then moved = moved + 1 end
            e.realm = ""
            if type(e.addedBy) == "string" then e.addedBy = bareKey(e.addedBy) end
            local other = out[newKey]
            if not other then
                out[newKey] = e
            else
                merged = merged + 1
                local older, newer = other, e
                if (e.addedAt or 0) < (other.addedAt or 0) then older, newer = e, other end
                mergeEntry(older, newer)
                out[newKey] = older
            end
        else
            out[key] = e
        end
    end
    for k in pairs(entries) do entries[k] = nil end
    for k, e in pairs(out) do entries[k] = e end
    return moved, merged
end

local function rekeyNames(names)
    if type(names) ~= "table" then return names end
    local out = {}
    for key, rec in pairs(names) do
        local k = bareKey(key)
        local have = out[k]
        if type(have) == "table" and type(rec) == "table" then
            have.first = earlier(rec.first, have.first)
        else
            out[k] = rec
        end
    end
    return out
end

local function switchIgnore(ig)
    local moved = 0
    if type(ig) ~= "table" then return moved end

    if type(ig.chars) == "table" then
        local out = {}
        for key, c in pairs(ig.chars) do
            local k = bareKey(key)
            if k ~= key then moved = moved + 1 end
            if type(c) == "table" then c.names = rekeyNames(c.names) end
            local have = out[k]
            if type(have) == "table" and type(c) == "table" then

                local new, old = have, c
                if (c.scannedAt or 0) > (have.scannedAt or 0) then new, old = c, have end
                new.firstScanAt = earlier(old.firstScanAt, new.firstScanAt)
                new.class = new.class or old.class
                for nk, rec in pairs(new.names or {}) do
                    local o = old.names and old.names[nk]
                    if type(o) == "table" and type(rec) == "table" then rec.first = earlier(o.first, rec.first) end
                end
                out[k] = new
            else
                out[k] = c
            end
        end
        ig.chars = out
    end

    if type(ig.deleted) == "table" then
        local out = {}
        for key, at in pairs(ig.deleted) do
            local k = bareKey(key)
            out[k] = later(out[k], at)
        end
        ig.deleted = out
    end

    if type(ig.queue) == "table" then
        local out = {}
        for charKey, cq in pairs(ig.queue) do
            local ck = bareKey(charKey)
            if ck ~= charKey then moved = moved + 1 end
            if type(cq) == "table" then
                out[ck] = out[ck] or {}
                for key, job in pairs(cq) do
                    local k = bareKey(key)
                    if type(job) == "table" then
                        job.realm = ""
                        if type(job.by) == "string" then job.by = bareKey(job.by) end
                    end
                    local have = out[ck][k]
                    if not have or (type(job) == "table" and (job.at or 0) > (have.at or 0)) then
                        out[ck][k] = job
                    end
                end
            end
        end
        ig.queue = out
    end
    return moved
end

local function recentKey(name, realm)
    return (name .. "-" .. (realm or "")):lower()
end

local function switchRecents(list)
    if type(list) ~= "table" then return 0 end
    local moved, byKey, i = 0, {}, 1
    while i <= #list do
        local e = list[i]
        if type(e) == "table" and type(e.name) == "string" then
            if (e.realm or "") ~= "" then moved = moved + 1 end
            e.realm = ""
            local k = recentKey(e.name, "")
            local twin = byKey[k]
            if twin then
                twin.count     = (twin.count or 1) + (e.count or 1)
                twin.firstSeen = earlier(e.firstSeen, twin.firstSeen)
                if (e.lastSeen or 0) > (twin.lastSeen or 0) then
                    twin.lastSeen = e.lastSeen
                    twin.zone     = e.zone or twin.zone
                end
                twin.class      = twin.class or e.class
                twin.classColor = twin.classColor or e.classColor
                table.remove(list, i)
            else
                byKey[k] = e
                i = i + 1
            end
        else
            i = i + 1
        end
    end
    return moved
end

local function switchRememberMe(db)
    if type(db) ~= "table" or type(db.entries) ~= "table" then return 0 end
    local moved, out = 0, {}
    for key, e in pairs(db.entries) do
        if type(e) == "table" and type(e.name) == "string" then
            local k = NBK:NormalizeKey(e.name, e.realm)
            if k ~= key or (e.realm or "") ~= "" then moved = moved + 1 end
            e.realm = ""
            local other = out[k]
            if not other then
                out[k] = e
            else

                local newer, older = e, other
                if (other.addedAt or 0) > (e.addedAt or 0) then newer, older = other, e end
                local a, b = newer.notes or "", older.notes or ""
                if b ~= "" and b ~= a then newer.notes = (a ~= "") and (a .. " / " .. b) or b end
                out[k] = newer
            end
        else
            out[key] = e
        end
    end
    db.entries = out
    return moved
end

function ForeverRealm:Run()
    if not NBK:IsForever() or type(NBK.db) ~= "table" then return end
    local moved, merged = switchEntries(NBK.db.entries)
    moved = moved + switchIgnore(NBK.db.ignore)

    local recents = NBK.GetAddonDB and NBK:GetAddonDB("Recents")
    moved = moved + switchRecents(type(recents) == "table" and recents.entries or nil)
    local recentsChar = _G.NerzorsBlacklistKeeperRecentsCharDB
    moved = moved + switchRecents(type(recentsChar) == "table" and recentsChar.entries or nil)
    local rm = NBK.GetAddonDB and NBK:GetAddonDB("RememberMe")
    moved = moved + switchRememberMe(rm)

    self.lastRun = { moved = moved, merged = merged }
    if moved > 0 or merged > 0 then
        NBK:Print(NBK.L["WoW: Forever: saved players and characters switched to names without server: %d (merged: %d)."]
            :format(moved, merged))
    end
end

ForeverRealm._bareKey = bareKey
