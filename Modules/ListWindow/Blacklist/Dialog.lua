local _, NBK = ...
local NUL = LibStub("NerzorsUILib-1.0")
local L   = NBK.L

local BlacklistTab = NBK:GetModule("BlacklistTab")
if not BlacklistTab then return end

local PILL_LINE, PILL_GAP = 22, 2
local PILLS_MIN_H = 48
local BASE_H = 502

local function buildRichDialog(globalName, titleKey)
    local theme = NUL:GetTheme()
    local W = 440

    local f = NUL:Window({
        name   = globalName,
        title  = L[titleKey],
        width  = W, height = BASE_H,
        strata = "DIALOG",
    })
    f:SetFrameLevel(200)
    f:SetPositionKey(globalName, NBK.db)
    f:RestorePosition()

    local content = f.content
    local y = 0

    local nameLabel = NUL:CreateLabel(content, {
        text  = L["Name"] .. " (Name-Realm)",
        color = theme.colors.text.muted,
        role  = "field",
    })
    nameLabel:SetPoint("TOPLEFT", 0, y); y = y - 16

    local nameBox = NUL:EditBox(content, { width = W - 24, height = 26 })
    nameBox:SetPoint("TOPLEFT", 0, y); y = y - 34

    local presetLabel = NUL:CreateLabel(content, {
        text  = L["Presets:"],
        color = theme.colors.text.muted,
        role  = "field",
    })
    presetLabel:SetPoint("TOPLEFT", 0, y); y = y - 16

    local presetContainer = CreateFrame("Frame", nil, content)

    presetContainer:SetPoint("TOPLEFT", 0, y)
    presetContainer:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, y)
    presetContainer:SetHeight(PILLS_MIN_H)
    f._presetContainer = presetContainer
    f._pills, f._pillPool = {}, {}

    y = y - (PILLS_MIN_H + 6)
    local placed = {}
    local function place(widget, x, py)
        placed[#placed + 1] = { widget = widget, x = x, y = py }
        widget:SetPoint("TOPLEFT", content, "TOPLEFT", x, py)
    end
    f._placed = placed

    local reasonLabel = NUL:CreateLabel(content, {
        text  = L["Custom reason..."],
        color = theme.colors.text.muted,
        role  = "field",
    })
    place(reasonLabel, 0, y); y = y - 16

    local reasonBox = NUL:EditBox(content, { width = W - 24, height = 26 })
    place(reasonBox, 0, y); y = y - 34

    local notesLabel = NUL:CreateLabel(content, {
        text  = L["Notes"],
        color = theme.colors.text.muted,
        role  = "field",
    })
    place(notesLabel, 0, y); y = y - 16

    local notesBox = NUL:EditBox(content, {
        width      = W - 24,
        height     = 70,
        multiline  = true,
        maxLetters = 1000,
    })
    place(notesBox, 0, y); y = y - 78

    local classLabel = NUL:CreateLabel(content, {
        text  = L["Class"] or "Class",
        color = theme.colors.text.muted,
        role  = "field",
    })
    place(classLabel, 0, y)

    local classOpts = { { key = "", label = L["(no class)"] or "(no class)" } }
    if CLASS_SORT_ORDER then
        for _, classFile in ipairs(CLASS_SORT_ORDER) do
            local label = (LOCALIZED_CLASS_NAMES_MALE and LOCALIZED_CLASS_NAMES_MALE[classFile]) or classFile
            table.insert(classOpts, { key = classFile, label = label })
        end
    end
    local classDD = NUL:Dropdown(content, {
        width = 180, height = 24, options = classOpts, value = "",
    })
    place(classDD, 0, y - 18)

    local ROLE_X = 200
    local roleLabel = NUL:CreateLabel(content, {
        text  = L["Role"] or "Role",
        color = theme.colors.text.muted,
        role  = "field",
    })
    place(roleLabel, ROLE_X, y); y = y - 18

    local roleDD = NUL:Dropdown(content, {
        width = 180, height = 24,
        options = {
            { key = "",        label = L["(no role)"] or "(no role)" },
            { key = "TANK",    label = L["Tank"]      or "Tank"      },
            { key = "HEALER",  label = L["Healer"]    or "Healer"    },
            { key = "DAMAGER", label = L["DPS"]       or "DPS"       },
        },
        value = "",
    })
    place(roleDD, ROLE_X, y); y = y - 34

    local muteCB = NUL:Checkbox(content, { label = L["Mute chat from this player"] })
    place(muteCB, 0, y); y = y - 24

    local pinCB = NUL:Checkbox(content, { label = L["Pin entry (protect from auto-cleanup)"] })
    place(pinCB, 0, y); y = y - 24

    local shareCB
    if NBK:GetModule("Sync") then
        shareCB = NUL:Checkbox(content, { label = L["Share this entry"] })
        place(shareCB, 0, y)
    end

    local cancel = NUL:Button(content, {
        label = L["Cancel"], width = 80, height = 24,
        onClick = function() f:Hide() end,
    })
    cancel:SetPoint("BOTTOMRIGHT", 0, 0)

    local accept = NUL:Button(content, {
        label = L["OK"], width = 80, height = 24, style = "accent",
    })
    accept:SetPoint("BOTTOMRIGHT", cancel, "BOTTOMLEFT", -6, 0)

    f._nameEB, f._reasonEB, f._notesEB = nameBox, reasonBox, notesBox
    f._muteCB, f._shareCB, f._pinCB    = muteCB, shareCB, pinCB
    f._roleDD, f._classDD              = roleDD, classDD
    f.acceptButton = accept

    local function acquirePill(i)
        local pill = f._pillPool[i]
        if not pill then
            pill = NUL:Pill(presetContainer, {
                onClick = function(self)
                    f._reasonEB:SetText(self._text or "")
                    for _, other in ipairs(f._pills) do
                        other:SetSelected(other == self)
                    end
                end,
            })
            pill.label:SetWordWrap(false)
            pill:HookScript("OnEnter", function(self)
                if not self._cut then return end
                GameTooltip:SetOwner(self, "ANCHOR_TOP")
                GameTooltip:SetText(self._text or "", 1, 1, 1, 1, true)
                GameTooltip:Show()
            end)
            pill:HookScript("OnLeave", function(self)
                if self._cut and GameTooltip:IsOwned(self) then GameTooltip:Hide() end
            end)
            f._pillPool[i] = pill
        end
        return pill
    end

    function f:RefreshPills()
        for _, p in ipairs(self._pillPool) do p:Hide() end
        wipe(self._pills)

        local presets = (NBK.db and NBK.db.settings and NBK.db.settings.presetReasons)
                        or NBK.PRESET_REASONS
        local rowW = presetContainer:GetWidth()
        if rowW <= 0 then rowW = W - 24 end

        local x, rowY = 0, 0
        for i, preset in ipairs(presets) do

            local label = NBK:ReasonText(preset)
            local pill = acquirePill(i)
            pill._text = label
            pill:SetLabel(label)
            pill:SetSelected(label == (f._reasonEB:GetText() or ""))
            local pw = pill:GetWidth()
            pill._cut = pw > rowW
            if pill._cut then
                pw = rowW
                pill:SetWidth(pw)
            end
            if x > 0 and x + pw > rowW then
                x = 0
                rowY = rowY - PILL_LINE - PILL_GAP
            end
            pill:ClearAllPoints()
            pill:SetPoint("TOPLEFT", presetContainer, "TOPLEFT", x, rowY)
            pill:Show()
            x = x + pw + 4
            table.insert(self._pills, pill)
        end

        local h = math.max(PILLS_MIN_H, -rowY + PILL_LINE)
        presetContainer:SetHeight(h)
        local extra = h - PILLS_MIN_H
        for _, p in ipairs(placed) do
            p.widget:SetPoint("TOPLEFT", content, "TOPLEFT", p.x, p.y - extra)
        end
        self:SetHeight(BASE_H + extra)
    end

    function f:SetValues(values)
        values = values or {}
        self._nameEB:SetText(values.name or "")
        self._nameEB:SetCursorPosition(0)
        self._reasonEB:SetText(NBK:ReasonText(values.reason) or "")
        self._reasonEB:SetCursorPosition(0)
        self._notesEB:SetText(values.notes or "")
        self._notesEB:SetCursorPosition(0)

        local settings = (NBK.db and NBK.db.settings) or {}
        local muteDefault = settings.autoMute ~= false
        local m = values.mute
        if m == nil then m = muteDefault end
        self._muteCB:SetChecked(m and true or false)

        if self._shareCB then
            local shareDefault = NBK:GetSyncSetting("defaultShareable", true) and true or false
            local s = values.shareable
            if s == nil then s = shareDefault end
            self._shareCB:SetChecked(s and true or false)
        end

        if self._pinCB then
            self._pinCB:SetChecked(values.pinned and true or false)
        end
        if self._roleDD then
            self._roleDD:SetValue(values.role or "")
        end
        if self._classDD then
            self._classDD:SetValue(values.class or "")
        end

        local r = NBK:ReasonText(values.reason)
        for _, pill in ipairs(self._pills) do
            pill:SetSelected(pill.label:GetText() == r)
        end
    end

    function f:GetValues()
        local role  = self._roleDD  and self._roleDD:GetValue()  or ""
        local class = self._classDD and self._classDD:GetValue() or ""
        return {
            name      = self._nameEB:GetText(),
            reason    = self._reasonEB:GetText(),
            notes     = self._notesEB:GetText(),
            mute      = self._muteCB:GetChecked(),

            shareable = self._shareCB and self._shareCB:GetChecked(),
            pinned    = self._pinCB and self._pinCB:GetChecked() or false,

            role      = (role  ~= "" and role)  or nil,
            class     = (class ~= "" and class) or nil,
        }
    end

    function f:SetOnAccept(callback)
        accept:SetScript("OnClick", function()
            local values = self:GetValues()
            local ok, err = callback(values)
            if ok ~= false then self:Hide() end
            if err then NBK:Print(err) end
        end)
    end

    function f:SetNameEditable(editable)
        self._nameEditable = editable and true or false
        local theme = NUL:GetTheme()
        local eb = self._nameEB.editBox
        if editable then
            eb:EnableMouse(true)
            NUL.SetFontColor(eb, theme.colors.text.primary)
            eb:SetScript("OnEditFocusGained", nil)
        else
            NUL.SetFontColor(eb, theme.colors.text.muted)
            eb:SetScript("OnEditFocusGained", function(self) self:ClearFocus() end)
        end
    end

    function f:_Accept()
        local onClick = accept:GetScript("OnClick")
        if onClick then onClick(accept) end
    end

    local fields = { nameBox, reasonBox, notesBox }
    local function usable(box) return box ~= nameBox or f._nameEditable ~= false end
    local function step(from, dir)
        local i = 1
        for k, box in ipairs(fields) do if box == from then i = k end end
        for _ = 1, #fields do
            i = ((i - 1 + dir) % #fields) + 1
            if usable(fields[i]) then return fields[i] end
        end
    end
    for _, box in ipairs(fields) do
        box.editBox:SetScript("OnTabPressed", function()
            local nextBox = step(box, IsShiftKeyDown and IsShiftKeyDown() and -1 or 1)
            if nextBox then nextBox:SetFocus() end
        end)
    end

    for _, box in ipairs({ nameBox, reasonBox }) do
        box.editBox:SetScript("OnEnterPressed", function(self)
            self:ClearFocus()
            f:_Accept()
        end)
    end

    function f:FocusFirst()
        if self._nameEditable ~= false and (self._nameEB:GetText() or "") == "" then
            self._nameEB:SetFocus()
        else
            self._reasonEB:SetFocus()
        end
    end

    local lastW
    presetContainer:SetScript("OnSizeChanged", function(_, w)
        if w ~= lastW then lastW = w; f:RefreshPills() end
    end)
    f:HookScript("OnShow", function(self) self:RefreshPills() end)

    return f
end

function BlacklistTab:_ShowAddDialog(prefill)
    if not self.addDialog then
        self.addDialog = buildRichDialog("NBKAddDialog", "Add to blacklist")
    end
    local dialog = self.addDialog
    dialog:SetNameEditable(true)

    if dialog._classDD then
        local hasKnownClass = prefill and prefill.class and prefill.class ~= ""
        dialog._classDD:SetEnabled(not hasKnownClass)
    end
    dialog:SetOnAccept(function(values)

        local name = values.name and strtrim(values.name):gsub("%s+", " ")
        if not name or name == "" then
            return false, L["name required"]
        end
        local entry, err = NBK:AddPlayer(name, nil, values.reason)
        if not entry then return false, L[err] end
        local fields = {
            notes  = values.notes or "",
            mute   = values.mute and true or false,
            pinned = values.pinned and true or false,
        }
        if values.shareable ~= nil then
            fields.shareable = values.shareable and true or false
        end
        NBK:UpdateEntry(entry.name, entry.realm, fields)

        local saved = NBK:GetPlayer(entry.name, entry.realm)
        if saved then
            saved.role = values.role

            if prefill and type(prefill.zone) == "string" and prefill.zone ~= "" then
                saved.zone = prefill.zone
            end
            if values.class then
                saved.class      = values.class
                saved.classColor = NBK:GetClassHex(values.class)
            end
        end
        self:_Refresh()
        return true
    end)
    dialog:SetValues(prefill or {})
    dialog:Show()
    dialog:FocusFirst()
end

function BlacklistTab:_ShowEditDialog(entry)
    if not self.editDialog then
        self.editDialog = buildRichDialog("NBKEditDialog", "Edit blacklist entry")
    end
    local dialog = self.editDialog
    dialog:SetNameEditable(false)

    if dialog._classDD then dialog._classDD:SetEnabled(true) end
    dialog:SetValues({
        name      = NBK:DisplayName(entry.name, entry.realm),
        reason    = entry.reason or "",
        notes     = entry.notes  or "",
        mute      = entry.mute,
        shareable = entry.shareable,
        pinned    = entry.pinned,
        role      = entry.role,
        class     = entry.class,
    })
    dialog:SetOnAccept(function(values)
        local fields = {
            reason = values.reason or "",
            notes  = values.notes  or "",
            mute   = values.mute and true or false,
            pinned = values.pinned and true or false,
        }
        if values.shareable ~= nil then
            fields.shareable = values.shareable and true or false
        end
        NBK:UpdateEntry(entry.name, entry.realm, fields)

        local saved = NBK:GetPlayer(entry.name, entry.realm)
        if saved then
            saved.role       = values.role
            saved.class      = values.class
            saved.classColor = values.class and NBK:GetClassHex(values.class) or nil
        end
        self:_Refresh()
        return true
    end)
    dialog:Show()
    dialog:FocusFirst()
end

function BlacklistTab:_RefreshAddDialogPills()
    if self.addDialog and self.addDialog.RefreshPills then
        self.addDialog:RefreshPills()
    end
    if self.editDialog and self.editDialog.RefreshPills then
        self.editDialog:RefreshPills()
    end
end
