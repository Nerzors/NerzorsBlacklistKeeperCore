local _, NBK = ...
local L = NBK.L
local NUL = LibStub("NerzorsUILib-1.0")

local BlacklistTab = NBK:GetModule("BlacklistTab")
if not BlacklistTab then return end

function BlacklistTab:DisplaySettings()
    return NBK.db and NBK.db.settings and NBK.db.settings.display or {}
end

function BlacklistTab:FormatDate(ts)
    return NBK:FormatDate(ts)
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
    elseif key == "reason" then return lc(NBK:ReasonText(entry.reason))
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

    local byRealm = not NBK:IsForever()
    for _, entry in pairs(NBK:GetEntries()) do
        if filter == ""
           or entry.name:lower():find(filter, 1, true)
           or (byRealm and (entry.realm or ""):lower():find(filter, 1, true))
           or (NBK:ReasonText(entry.reason) or ""):lower():find(filter, 1, true)
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

    if self.selectMode then
        table.insert(cols, { key = "select", label = "", width = 24, sortable = false })
    end

    local combined = s.combinedName or NBK:IsForever()
    table.insert(cols, {
        key = "name", label = L["Name"],
        width = combined and 170 or 110, sortable = true,
    })

    if not combined then
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

        table.insert(cols, {
            key = "zone", label = L["Zone"], sortable = true,
            width = self._zoneWidth or self.ZONE_MIN_WIDTH,
        })
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

BlacklistTab.ZONE_MIN_WIDTH   = 110
BlacklistTab.ZONE_MAX_WIDTH   = 240
BlacklistTab.REASON_MIN_WIDTH = 140
local ZONE_PAD = 12
local SORT_ARROW = 16

function BlacklistTab:ZoneWidthFor(columns, zones, measure, headerWidth, label)
    local want = (label and measure(label) or 0) + SORT_ARROW
    for _, z in ipairs(zones) do
        local w = measure(z) + ZONE_PAD
        if w > want then want = w end
    end
    want = math.ceil(want)
    if want < self.ZONE_MIN_WIDTH then want = self.ZONE_MIN_WIDTH end
    if want > self.ZONE_MAX_WIDTH then want = self.ZONE_MAX_WIDTH end

    if headerWidth and headerWidth > 0 then
        local others = 0
        for _, col in ipairs(columns) do
            if not col.flex and col.key ~= "zone" then others = others + col.width end
        end
        local room = headerWidth - others - (#columns * 4) - 8 - self.REASON_MIN_WIDTH
        if want > room then want = math.max(self.ZONE_MIN_WIDTH, math.floor(room)) end
    end
    return want
end

function BlacklistTab:FitZoneColumn()
    local header = self.header
    if not header or not header._columns then return false end
    local zoneCol
    for _, col in ipairs(header._columns) do
        if col.key == "zone" then zoneCol = col end
    end
    if not zoneCol then return false end

    if not self._zoneMeasure then
        local fs = NUL:CreateLabel(self.frame, { text = "", wrap = false })
        fs:Hide()
        self._zoneMeasure = fs
    end
    local fs = self._zoneMeasure
    local function measure(text)
        fs:SetText(text)
        return tonumber(fs:GetStringWidth()) or 0
    end

    local seen, zones = {}, {}
    for _, e in pairs(NBK:GetEntries()) do
        local z = e.zone
        if type(z) == "string" and z ~= "" and not seen[z] then
            seen[z] = true
            zones[#zones + 1] = z
        end
    end

    local w = self:ZoneWidthFor(header._columns, zones, measure, tonumber(header:GetWidth()) or 0, zoneCol.label)
    self._zoneWidth = w
    if zoneCol.width == w then return false end
    zoneCol.width = w
    return true
end
