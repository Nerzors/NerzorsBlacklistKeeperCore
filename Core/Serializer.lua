local _, NBK = ...

local MAGIC = "!NBK1!"

local function escape(s)
    if s == nil then return "" end
    s = tostring(s)
    s = s:gsub("\\", "\\\\")
    s = s:gsub("|",  "\\p")
    s = s:gsub("\n", "\\n")
    s = s:gsub("\r", "")
    return s
end

local function unescape(s)
    if not s then return "" end
    s = s:gsub("\\n",  "\n")
    s = s:gsub("\\p",  "|")
    s = s:gsub("\\\\", "\\")
    return s
end

function NBK:EscapeField(s)   return escape(s)   end
function NBK:UnescapeField(s) return unescape(s) end

local function splitFields(line)
    local fields = {}
    for part in (line .. "|"):gmatch("(.-)|") do
        table.insert(fields, unescape(part))
    end
    return fields
end

NBK._listTypes = NBK._listTypes or {}
NBK._listTypeOrder = NBK._listTypeOrder or {}
NBK._listCodeAlias = NBK._listCodeAlias or {}

function NBK:RegisterListType(id, spec)
    assert(type(id) == "string" and id ~= "", "RegisterListType: id required")
    assert(type(spec) == "table", "RegisterListType: spec must be a table")
    spec.id = id
    if not self._listTypes[id] then
        table.insert(self._listTypeOrder, id)
    end
    self._listTypes[id] = spec
    if type(spec.codeList) == "string" and spec.codeList ~= id then
        self._listCodeAlias[spec.codeList] = id
    end
    return spec
end

function NBK:GetListType(id)
    return self._listTypes[id or "blacklist"]
end

function NBK:ListTypeLabel(id)
    local spec = self._listTypes[id or "blacklist"]
    local key = spec and spec.label
    if type(key) ~= "string" or key == "" then return id end
    return self.L[key]
end

function NBK:GetListTypes()
    local out = {}
    for _, id in ipairs(self._listTypeOrder) do
        local spec = self._listTypes[id]
        if not spec.hidden then
            out[#out + 1] = { id = id, label = self:ListTypeLabel(id) }
        end
    end
    return out
end

local function collect(spec, opts)
    local sorted = {}
    for _, e in pairs(spec.getEntries(opts) or {}) do
        local key = spec.entryKey(e)
        if key and (not opts.keys or opts.keys[key]) then
            sorted[#sorted + 1] = { key = key, entry = e }
        end
    end
    table.sort(sorted, function(a, b) return a.key < b.key end)
    return sorted
end

function NBK:ExportString(opts)
    opts = opts or {}
    local listId = opts.list or "blacklist"
    local spec = self:GetListType(listId)
    if not spec then return MAGIC .. "|" .. listId .. "\n", 0 end

    local sorted = collect(spec, opts)

    local lines = { MAGIC .. "|" .. listId }
    for _, pair in ipairs(sorted) do
        local raw = spec.serializeRow(pair.entry) or {}
        local escaped = {}
        for i = 1, #raw do escaped[i] = escape(raw[i]) end
        lines[#lines + 1] = table.concat(escaped, "|")
    end

    return table.concat(lines, "\n"), #sorted
end

local CODE_FORMAT = 1

function NBK:RecordName(r)
    local name, realm = r.name, r.realm
    if type(name) ~= "string" or name == "" or name:find("[|%c]") then return nil end
    if self:IsForever() then return name, "" end
    if name:find("%s") then return nil end
    if type(realm) ~= "string" or realm == "" or realm:find("[|%c]") then return nil end
    return name, realm
end

function NBK:RecordText(v)
    if type(v) == "string" and v ~= "" then return v end
end

function NBK:RecordTime(v)
    if type(v) == "number" and v > 0 and v <= time() then return math.floor(v) end
end

function NBK:RecordClass(v)
    if type(v) == "string" and v:find("^%u+$") then return v end
end

function NBK:ExportCode(opts)
    opts = opts or {}
    local listId = opts.list or "blacklist"
    local spec = self:GetListType(listId)
    if not (spec and spec.toRecord and self.Codec) then return nil, 0 end

    local doc = {
        format  = CODE_FORMAT,
        list    = spec.codeList or listId,
        game    = self:GetFlavor(),
        version = self.version,
        entries = {},
    }
    for k, v in pairs(spec.codeMeta and spec.codeMeta(opts) or {}) do
        if doc[k] == nil then doc[k] = v end
    end
    local sorted = collect(spec, opts)
    for i, pair in ipairs(sorted) do
        local rec = spec.toRecord(pair.entry) or {}
        for k, v in pairs(rec) do
            if v == "" then rec[k] = nil end
        end
        doc.entries[i] = rec
    end
    return "!NBK:" .. (spec.codeName or listId) .. ":" .. self.Codec.Pack(doc), #sorted
end

local function parseCode(self, code, result)
    result.magic, result.version = true, "NBK:" .. CODE_FORMAT
    local doc = self.Codec and self.Codec.Unpack(code)
    if type(doc) ~= "table" or type(doc.entries) ~= "table" then
        result.error, result.errors[1] = "damaged", "damaged text"
        return result
    end
    if type(doc.format) ~= "number" or doc.format > CODE_FORMAT then
        result.error, result.errors[1] = "newer", "made by a newer version"
        return result
    end
    local list = type(doc.list) == "string" and doc.list or "blacklist"
    local listId = self._listCodeAlias[list] or list
    result.list = listId
    result.from = type(doc.from) == "string" and doc.from or nil
    local spec = self:GetListType(listId)
    if not (spec and spec.fromRecord) then
        result.error, result.errors[1] = "unknown", "unknown list type: " .. tostring(listId)
        return result
    end
    for _, rec in ipairs(doc.entries) do
        local entry = type(rec) == "table" and spec.fromRecord(rec) or nil
        if entry then
            result.entries[#result.entries + 1] = entry
        else
            result.skipped = result.skipped + 1
        end
    end
    result.ok = true
    return result
end

function NBK:ParseImport(text)
    local result = { ok = false, magic = false, list = nil, entries = {}, skipped = 0, errors = {} }
    if type(text) ~= "string" or text == "" then
        result.errors[1] = "empty input"
        return result
    end

    text = text:gsub("\r\n", "\n"):gsub("\r", "\n")
    text = text:match("^%s*(.-)%s*$") or text

    local code = text:match("!NBK:%a+:([%w+/=%s]*)")
    if code then return parseCode(self, code, result) end

    local firstNL = text:find("\n", 1, true)
    local header  = firstNL and text:sub(1, firstNL - 1) or text
    local body    = firstNL and text:sub(firstNL + 1) or ""

    header = NBK:UnescapeFromDisplay(header)

    if header:sub(1, #MAGIC) ~= MAGIC then
        result.errors[1] = "missing !NBK1! header"
        return result
    end
    result.magic   = true
    result.version = "NBK1"

    local listTag = header:match("^!NBK1!|(.+)$")
    local listId  = (listTag and listTag ~= "" and listTag) or "blacklist"
    result.list = listId

    local spec = self:GetListType(listId)
    if not spec then
        result.errors[1] = "unknown list type: " .. tostring(listId)
        return result
    end

    for line in body:gmatch("[^\n]+") do
        if line:match("^%s*$") then

        else
            local fields = splitFields(line)

            if #fields > 11 then
                line = NBK:UnescapeFromDisplay(line)
                fields = splitFields(line)
            end
            local entry = spec.parseRow(fields)
            if entry then
                result.entries[#result.entries + 1] = entry
            else
                result.skipped = result.skipped + 1
                result.errors[#result.errors + 1] = "malformed line: " .. line:sub(1, 60)
            end
        end
    end

    result.ok = true
    return result
end

function NBK:ImportErrorText(parsed)
    local L = self.L
    if not parsed or not parsed.magic then return L["No NBK export found in this text."] end
    if parsed.error == "damaged" then return L["This export is damaged - copy all of it again."] end
    if parsed.error == "newer" then return L["This export comes from a newer version of NBK - please update NBK."] end
    return L["This export holds a list this version of NBK does not know."]
end

function NBK:ClassifyImport(parsed)
    local classify = { total = 0, new = 0, duplicate = 0, newKeys = {}, dupKeys = {} }
    if not parsed or not parsed.ok then return classify end
    local spec = self:GetListType(parsed.list)
    if not spec then return classify end

    for _, e in ipairs(parsed.entries) do
        classify.total = classify.total + 1
        local key = spec.entryKey(e)
        if spec.hasEntry(e) then
            classify.duplicate = classify.duplicate + 1
            classify.dupKeys[#classify.dupKeys + 1] = key
        else
            classify.new = classify.new + 1
            classify.newKeys[#classify.newKeys + 1] = key
        end
    end
    return classify
end

function NBK:ApplyImport(parsed, mode)
    mode = mode or "merge"
    local counts = { added = 0, skipped = 0, overwritten = 0, removed = 0 }
    if not parsed or not parsed.ok then return counts end
    local spec = self:GetListType(parsed.list)
    if not spec then return counts end

    if spec.beginApply then
        counts.removed = spec.beginApply(mode) or 0
    end

    for _, e in ipairs(parsed.entries) do
        local action = spec.applyEntry(e, mode)
        if action == "added" then
            counts.added = counts.added + 1
        elseif action == "overwritten" then
            counts.overwritten = counts.overwritten + 1
        else
            counts.skipped = counts.skipped + 1
        end
    end

    if parsed.list == "blacklist" and self._FireApiEvent
       and (counts.added > 0 or counts.overwritten > 0 or counts.removed > 0) then
        self:_FireApiEvent("BLACKLIST_CHANGED")
    end

    return counts
end

function NBK:ResetEntries()
    local removed = 0
    if self.db and self.db.entries then
        for _ in pairs(self.db.entries) do removed = removed + 1 end
        self.db.entries = {}
    end
    if removed > 0 and self._FireApiEvent then
        self:_FireApiEvent("BLACKLIST_CHANGED")
    end
    return removed
end

function NBK:EscapeForDisplay(s)
    if type(s) ~= "string" then return s end
    return (s:gsub("|", "||"))
end

function NBK:UnescapeFromDisplay(s)
    if type(s) ~= "string" then return s end
    return (s:gsub("||", "|"))
end

NBK:RegisterListType("blacklist", {
    label = "Blacklist",
    codeName = "Blacklist",

    toRecord = function(e)
        return {
            name      = e.name,
            realm     = e.realm,
            class     = e.class,
            addedAt   = (tonumber(e.addedAt) or 0) > 0 and e.addedAt or nil,
            reason    = e.reason,
            notes     = e.notes,
            zone      = e.zone,
            addedBy   = e.addedBy,
            mute      = e.mute ~= false,
            shareable = e.shareable ~= false,
        }
    end,

    fromRecord = function(r)
        local name, realm = NBK:RecordName(r)
        if not name then return nil end
        local entry = {
            name      = name,
            realm     = realm,
            class     = NBK:RecordClass(r.class),
            addedAt   = NBK:RecordTime(r.addedAt) or time(),
            reason    = NBK:ReasonKey(NBK:RecordText(r.reason) or ""),
            notes     = NBK:RecordText(r.notes) or "",
            mute      = r.mute ~= false,
            zone      = NBK:RecordText(r.zone) or "",
            addedBy   = NBK:RecordText(r.addedBy) or "",
            shareable = r.shareable ~= false,
        }
        entry.classColor = entry.class and NBK:GetClassHex(entry.class) or nil
        return entry
    end,

    getEntries = function(opts)
        local entries = NBK.db and NBK.db.entries or {}
        if not (opts and opts.sharedOnly) then return entries end

        local filtered = {}
        for k, e in pairs(entries) do
            if e.shareable ~= false then filtered[k] = e end
        end
        return filtered
    end,

    entryKey = function(entry)
        return NBK:NormalizeKey(entry.name, entry.realm)
    end,

    hasEntry = function(entry)
        local key = NBK:NormalizeKey(entry.name, entry.realm)
        return key ~= nil and NBK.db and NBK.db.entries and NBK.db.entries[key] ~= nil
    end,

    serializeRow = function(e)
        return {
            e.name,
            e.realm,
            e.class or "",
            tostring(e.addedAt or 0),
            e.reason or "",
            e.notes or "",
            (e.mute ~= false) and "1" or "0",
            e.zone or "",
            e.addedBy or "",
            (e.shareable == false) and "0" or "1",
        }
    end,

    parseRow = function(fields)
        if #fields < 3 then return nil end
        local addedAt = tonumber(fields[4]) or 0
        local shareable
        if fields[10] == nil or fields[10] == "" then
            shareable = true
        else
            shareable = (fields[10] == "1")
        end
        local entry = {
            name      = fields[1],
            realm     = fields[2],
            class     = (fields[3] ~= "" and fields[3]) or nil,
            addedAt   = addedAt > 0 and addedAt or time(),

            reason    = NBK:ReasonKey(fields[5] or ""),
            notes     = fields[6] or "",
            mute      = (fields[7] == "1"),
            zone      = fields[8] or "",
            addedBy   = fields[9] or "",
            shareable = shareable,
        }
        entry.classColor = entry.class and NBK:GetClassHex(entry.class) or nil

        if NBK.ForeverNames then NBK.ForeverNames:FixRow(entry) end
        return entry
    end,

    beginApply = function(mode)
        local db = NBK.db
        if not db then return 0 end
        db.entries = db.entries or {}
        if mode == "replace" then
            local before = 0
            for _ in pairs(db.entries) do before = before + 1 end
            db.entries = {}
            return before
        end
        return 0
    end,

    applyEntry = function(entry, mode)
        local db = NBK.db
        if not db then return "skipped" end
        db.entries = db.entries or {}
        local key = NBK:NormalizeKey(entry.name, entry.realm)
        if not key then return "skipped" end
        if db.entries[key] then
            if mode == "overwrite" then
                db.entries[key] = entry
                return "overwritten"
            end
            return "skipped"
        end
        db.entries[key] = entry
        return "added"
    end,

    countEntries = function()
        return NBK:CountEntries()
    end,
})
