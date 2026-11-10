local _, NBK = ...

local ForeverNames = {}
NBK.ForeverNames = ForeverNames

local function ownRealm()
    local own = GetNormalizedRealmName and GetNormalizedRealmName()
    if type(own) ~= "string" or own == "" then return nil end
    return own
end

local function same(a, b)
    return a:gsub("%s+", ""):lower() == b:gsub("%s+", ""):lower()
end

local function earlier(a, b)
    if a and (not b or a < b) then return a end
    return b
end

function ForeverNames:Convert(name, realm, addedBy, own)
    if not NBK:IsForever() then return nil end
    own = own or ownRealm()
    if not own then return nil end
    if type(name) ~= "string" or type(realm) ~= "string" then return nil end
    if name == "" or realm == "" or name:find("[%s%-]") then return nil end
    if realm:find("[%s%d%-]") or same(realm, own) then return nil end
    if addedBy ~= nil then
        local by = type(addedBy) == "string" and addedBy:match("%-([^%-]+)$")
        if not by or not same(by, own) then return nil end
    end
    return name .. " " .. realm, own
end

function ForeverNames:FixRow(entry)
    if type(entry) ~= "table" then return end
    local name, realm = self:Convert(entry.name, entry.realm, entry.addedBy or "")
    if name then entry.name, entry.realm = name, realm end
end

function ForeverNames:Plan()
    local plan = {}
    local entries = NBK.db and NBK.db.entries
    local own = ownRealm()
    if not NBK:IsForever() or type(entries) ~= "table" or not own then return plan end
    for key, e in pairs(entries) do
        if type(e) == "table" then
            local name, realm = self:Convert(e.name, e.realm, e.addedBy or "", own)
            local newKey = name and NBK:NormalizeKey(name, realm)
            if newKey and newKey ~= key then
                plan[#plan + 1] = { key = key, e = e, name = name, realm = realm,
                                    newKey = newKey, dup = entries[newKey] ~= nil }
            end
        end
    end
    table.sort(plan, function(a, b) return a.name:lower() < b.name:lower() end)
    return plan
end

function ForeverNames:Apply()
    local entries = NBK.db and NBK.db.entries
    if type(entries) ~= "table" then return end
    local switched, dropped = 0, 0
    for _, p in ipairs(self:Plan()) do
        if entries[p.newKey] == nil then
            p.e.name, p.e.realm = p.name, p.realm
            entries[p.newKey] = p.e
            switched = switched + 1
        else
            dropped = dropped + 1
        end
        entries[p.key] = nil
    end

    local L = NBK.L
    if switched > 0 then
        NBK:Print(L["Switched %d blacklist entries to WoW: Forever names (first and second name)."]:format(switched))
    end
    if dropped > 0 then
        NBK:Print(L["Removed %d entries in the old form that were already on the blacklist with first and second name."]:format(dropped))
    end

    local lw = NBK:GetModule("ListWindow")
    if lw and lw.Refresh then lw:Refresh() end
    local im = NBK:GetModule("IgnoreManager")
    if im and im.RefreshTab then im:RefreshTab() end
end

local function switchAddedBy(entries, oldMe, newMe)
    for _, e in pairs(entries) do
        if type(e) == "table" and e.addedBy == oldMe then e.addedBy = newMe end
    end
end

local function switchIgnoreData(oldMe, newMe, own)
    local ig = NBK.db and NBK.db.ignore
    if type(ig) ~= "table" then return end

    local chars = ig.chars
    local old = type(chars) == "table" and chars[oldMe]
    if type(old) == "table" then
        local cur = chars[newMe]
        if type(cur) ~= "table" then
            chars[newMe] = old
        else

            cur.firstScanAt = earlier(old.firstScanAt, cur.firstScanAt)
            cur.class = cur.class or old.class
            if type(cur.names) == "table" then
                for key, rec in pairs(old.names or {}) do
                    local now = cur.names[key]
                    if type(now) == "table" and type(rec) == "table" then
                        now.first = earlier(rec.first, now.first)
                    end
                end
            end
        end
        chars[oldMe] = nil
    end

    local q = ig.queue
    if type(q) ~= "table" then return end
    if type(q[oldMe]) == "table" then
        q[newMe] = q[newMe] or {}
        for key, job in pairs(q[oldMe]) do
            if q[newMe][key] == nil then q[newMe][key] = job end
        end
        q[oldMe] = nil
    end
    for _, cq in pairs(q) do
        if type(cq) == "table" then
            local moves = {}
            for key, job in pairs(cq) do
                if type(job) == "table" then
                    if job.by == oldMe then job.by = newMe end
                    local name, realm = ForeverNames:Convert(job.name, job.realm, nil, own)
                    if name then moves[#moves + 1] = { key = key, job = job, name = name, realm = realm } end
                end
            end
            for _, m in ipairs(moves) do
                local newKey = NBK:NormalizeKey(m.name, m.realm)
                if newKey and newKey ~= m.key then
                    cq[m.key] = nil
                    if cq[newKey] == nil then
                        m.job.name, m.job.realm = m.name, m.realm
                        cq[newKey] = m.job
                    end
                end
            end
        end
    end
end

local function recentKey(name, realm)
    return (name .. "-" .. (realm or "")):lower()
end

local function switchRecents(list, own)
    if type(list) ~= "table" then return end
    local byKey = {}
    for _, e in ipairs(list) do
        if type(e) == "table" and type(e.name) == "string" then
            byKey[recentKey(e.name, e.realm)] = e
        end
    end

    local i = 1
    while i <= #list do
        local e = list[i]
        local name, realm
        if type(e) == "table" then name, realm = ForeverNames:Convert(e.name, e.realm, nil, own) end
        local twin = name and byKey[recentKey(name, realm)]
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
            if name then
                e.name, e.realm = name, realm
                byKey[recentKey(name, realm)] = e
            end
            i = i + 1
        end
    end
end

local CHROME   = 28 + 1 + 12 * 2
local MAX_ROWS = 8
local ui = {}

local function fitHeight()
    local h = ui.listH + 10
    for _, fs in ipairs({ ui.why, ui.what, ui.dup, ui.sorry, ui.later }) do
        if fs:IsShown() then h = h + math.max(14, fs:GetStringHeight() or 0) + 10 end
    end
    ui.f:SetHeight(math.ceil(h + 16 + 26 + CHROME))
end

local function build()
    if ui.f then return ui.f end
    local L, NUL = NBK.L, LibStub("NerzorsUILib-1.0")
    local theme = NUL:GetTheme()

    local f = NUL:Window({
        name   = "NBKForeverNamesWindow",
        title  = L["WoW: Forever: correcting names"],
        width  = 560, height = 420,
        strata = "DIALOG",
    })
    ui.f = f

    local function label(opts)
        local fs = NUL:CreateLabel(f.content, opts)
        fs:SetJustifyH("LEFT")
        return fs
    end
    local function below(item, anchor)
        item:ClearAllPoints()
        if anchor then
            item:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -10)
            item:SetPoint("TOPRIGHT", anchor, "BOTTOMRIGHT", 0, -10)
        else
            item:SetPoint("TOPLEFT", 0, 0)
            item:SetPoint("TOPRIGHT", 0, 0)
        end
    end

    local primary = theme.colors.text.primary
    ui.why   = label({ text = L["On WoW: Forever every character has a first and a second name. Up to 2.1.0-beta.1, NBK saved the second name as the realm when you added a player through the target, the context menu or the group (\"First-Second\" instead of \"First Second\"). The tooltip and the group warning didn't recognize these entries, and the same player could end up on the list twice."],
                       color = primary })
    ui.what  = label({ text = "", color = primary })
    ui.dup   = label({ text = "", color = primary })
    ui.sorry = label({ text = L["NBK recognizes the old form automatically. If an entry doesn't come out right, we're sorry - please check your blacklist afterwards and edit or re-add it. To be safe, you can export your blacklist first."],
                       color = primary })
    ui.later = label({ text = L["\"Later\" closes this window; it comes back at your next login."],
                       size = "sm", color = theme.colors.text.muted })

    ui.list = NUL:ScrollList(f.content, {
        rowBuilder = function(row)
            local fs = NUL:CreateLabel(row, { text = "", color = primary })
            fs:SetPoint("LEFT", 6, 0)
            fs:SetPoint("RIGHT", -6, 0)
            fs:SetJustifyH("LEFT")
            fs:SetWordWrap(false)
            return function(_, item) fs:SetText(item.text) end
        end,
    })
    ui.rowH = theme.metrics.rowHeight

    below(ui.why)
    below(ui.what, ui.why)

    ui.switch = NUL:Button(f.content, {
        label = L["Switch now"], width = 150, height = 26, style = "primary",
        onClick = function()
            f:Hide()
            ForeverNames:Apply()
        end,
    })
    ui.switch:SetPoint("BOTTOMRIGHT", 0, 0)

    local later = NUL:Button(f.content, {
        label = L["Later"], width = 110, height = 26,
        onClick = function() f:Hide() end,
    })
    later:SetPoint("RIGHT", ui.switch, "LEFT", -6, 0)

    local export = NUL:Button(f.content, {
        label = L["Export first"], width = 150, height = 26,
        onClick = function()
            local Config = NBK:GetModule("Config")
            if Config and Config.ShowExportDialog then Config:ShowExportDialog({ all = true }) end
        end,
    })
    export:SetPoint("BOTTOMLEFT", 0, 0)

    f:HookScript("OnShow", function()
        if C_Timer and C_Timer.After then C_Timer.After(0, fitHeight) end
    end)
    return f
end

function ForeverNames:ShowDialog()
    local plan = self:Plan()
    if #plan == 0 then return end
    local L, NUL = NBK.L, LibStub("NerzorsUILib-1.0")
    local f = build()

    local dups = 0
    local muted = NUL.ToHex(NUL:GetTheme().colors.text.muted)
    local rows = {}
    for _, p in ipairs(plan) do
        local hex = p.e.class and NBK:GetClassHex(p.e.class) or nil
        local text = NBK:DisplayName(p.e.name, p.e.realm, hex)
                  .. ("  |cff%s->|r  "):format(muted)
                  .. NBK:DisplayName(p.name, p.realm, hex)
        if p.dup then
            dups = dups + 1
            text = text .. ("  |cff%s(%s)|r"):format(muted, L["already listed - old copy removed"])
        end
        rows[#rows + 1] = { text = text }
    end

    ui.what:SetText(L["NBK now switches these entries to the correct form, once. Entries affected: %d"]:format(#plan))
    if dups > 0 then
        ui.dup:SetText(L["Of these, %d are already on your blacklist in the correct form. The correct entry stays, the old copy is removed."]:format(dups))
        ui.dup:Show()
    else
        ui.dup:Hide()
    end

    local listTop = dups > 0 and ui.dup or ui.what
    if dups > 0 then
        ui.dup:ClearAllPoints()
        ui.dup:SetPoint("TOPLEFT", ui.what, "BOTTOMLEFT", 0, -10)
        ui.dup:SetPoint("TOPRIGHT", ui.what, "BOTTOMRIGHT", 0, -10)
    end
    ui.listH = math.min(#rows, MAX_ROWS) * ui.rowH + 4
    local box = ui.list.container
    box:ClearAllPoints()
    box:SetPoint("TOPLEFT", listTop, "BOTTOMLEFT", 0, -10)
    box:SetPoint("TOPRIGHT", listTop, "BOTTOMRIGHT", 0, -10)
    box:SetHeight(ui.listH)

    ui.sorry:ClearAllPoints()
    ui.sorry:SetPoint("TOPLEFT", box, "BOTTOMLEFT", 0, -10)
    ui.sorry:SetPoint("TOPRIGHT", box, "BOTTOMRIGHT", 0, -10)
    ui.later:ClearAllPoints()
    ui.later:SetPoint("TOPLEFT", ui.sorry, "BOTTOMLEFT", 0, -10)
    ui.later:SetPoint("TOPRIGHT", ui.sorry, "BOTTOMRIGHT", 0, -10)

    fitHeight()
    f:Show()
    ui.list:SetData(rows)
end

function ForeverNames:_ScheduleDialog()
    local function show()
        local legacy = _G.NBKLegacyModulesWindow
        if legacy and legacy:IsShown() then
            if not self._afterLegacy then
                self._afterLegacy = true
                legacy:HookScript("OnHide", function()
                    if self._waiting then
                        self._waiting = nil
                        self:ShowDialog()
                    end
                end)
            end
            self._waiting = true
            return
        end
        self:ShowDialog()
    end
    if C_Timer and C_Timer.After then C_Timer.After(3, show) else show() end
end

function ForeverNames:Run()
    if not NBK:IsForever() or type(NBK.db) ~= "table" then return end
    local own = ownRealm()
    if not own then return end

    local entries = type(NBK.db.entries) == "table" and NBK.db.entries or {}
    local first = UnitName("player")
    local oldMe = type(first) == "string" and (first .. "-" .. own) or nil
    local newMe = NBK:PlayerFullName()
    if oldMe and newMe and oldMe ~= newMe then
        switchAddedBy(entries, oldMe, newMe)
        switchIgnoreData(oldMe, newMe, own)
    end

    local recents = NBK.GetAddonDB and NBK:GetAddonDB("Recents")
    switchRecents(type(recents) == "table" and recents.entries or nil, own)
    local recentsChar = _G.NerzorsBlacklistKeeperRecentsCharDB
    switchRecents(type(recentsChar) == "table" and recentsChar.entries or nil, own)

    if #self:Plan() > 0 then self:_ScheduleDialog() end
end
