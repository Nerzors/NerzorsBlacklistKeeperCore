local _, NBK = ...
local L = NBK.L

local BlacklistTab = NBK:GetModule("BlacklistTab")
if not BlacklistTab then return end

function BlacklistTab:DisplaySettings()
    return NBK.db and NBK.db.settings and NBK.db.settings.display or {}
end

function BlacklistTab:FormatDate(ts)
    if not ts then return "-" end
    return date("%d.%m.%Y", ts)
end

function BlacklistTab:ColoredName(entry, useColor)
    if useColor then
        return ("|cff%s%s|r"):format(NBK:GetClassHex(entry.class), entry.name)
    end
    return entry.name
end

local function lc(s) return (s or ""):lower() end

local function fieldValue(entry, key)
    if key == "name"   then return lc(entry.name)
    elseif key == "realm"  then return lc(entry.realm)
    elseif key == "class"  then return lc(entry.class)
    elseif key == "reason" then return lc(entry.reason)
    elseif key == "zone"   then return lc(entry.zone)
    elseif key == "added"  then return entry.addedAt or 0
    elseif key == "seen"   then return entry.lastSeen or 0
    end
    return lc(entry.name)
end

local function makeComparator(sortKey, sortDir)
    local asc = sortDir ~= "desc"
    return function(a, b)
        local va, vb = fieldValue(a, sortKey), fieldValue(b, sortKey)
        if va == vb then
            return lc(a.name) < lc(b.name)
        end
        if asc then return va < vb end
        return va > vb
    end
end

function BlacklistTab:SortedEntries(filter, sortKey, sortDir)
    local list = {}
    filter = filter and filter:lower() or ""
    for _, entry in pairs(NBK:GetEntries()) do
        if filter == ""
           or entry.name:lower():find(filter, 1, true)
           or (entry.realm  or ""):lower():find(filter, 1, true)
           or (entry.reason or ""):lower():find(filter, 1, true)
           or (entry.zone   or ""):lower():find(filter, 1, true) then
            table.insert(list, entry)
        end
    end
    table.sort(list, makeComparator(sortKey or "name", sortDir or "asc"))
    return list
end

function BlacklistTab:ComputeColumns()
    local s = self:DisplaySettings()
    local cols = {}

    table.insert(cols, {
        key = "name", label = L["Name"],
        width = s.combinedName and 170 or 110, sortable = true,
    })

    if not s.combinedName then
        table.insert(cols, { key = "realm", label = L["Realm"], width = 100, sortable = true })
    end

    if s.classDisplay == "name" then
        table.insert(cols, { key = "class", label = L["Class"], width = 80, sortable = true })
    else

        table.insert(cols, {
            key = "class", label = L["Class"], width = 26,
            sortable = true, compact = true,
        })
    end

    table.insert(cols, { key = "reason", label = L["Reason"], width = 0, flex = true, sortable = true })

    table.insert(cols, {
        key = "note", label = L["Note"], width = 36,
        sortable = false, compact = true, icon = "notes.png",
    })

    if s.showZoneColumn then
        table.insert(cols, { key = "zone", label = L["Zone"], width = 120, sortable = true })
    end
    if s.showAddedColumn then
        table.insert(cols, { key = "added", label = L["Date"], width = 80, sortable = true })
    end
    if s.showSeenColumn then
        table.insert(cols, { key = "seen", label = L["Last seen"], width = 90, sortable = true })
    end

    table.insert(cols, {
        key = "options", label = L["Options"] or "Options",
        width = self.OPTIONS_WIDTH, sortable = false,
    })

    return cols
end
