local _, NBK = ...
local NUL = LibStub("NerzorsUILib-1.0")
local L   = NBK.L

local BlacklistTab = NBK:GetModule("BlacklistTab")
if not BlacklistTab then return end

local function buildRichDialog(globalName, titleKey)
    local theme = NUL:GetTheme()
    local W = 440

    local f = NUL:Window({
        name   = globalName,
        title  = L[titleKey],
        width  = W, height = 554,
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
    })
    nameLabel:SetPoint("TOPLEFT", 0, y); y = y - 16

    local nameBox = NUL:EditBox(content, { width = W - 24, height = 26 })
    nameBox:SetPoint("TOPLEFT", 0, y); y = y - 34

    local presetLabel = NUL:CreateLabel(content, {
        text  = L["Presets:"],
        color = theme.colors.text.muted,
    })
    presetLabel:SetPoint("TOPLEFT", 0, y); y = y - 16

    local presetContainer = CreateFrame("Frame", nil, content)
    presetContainer:SetPoint("TOPLEFT", 0, y)
    presetContainer:SetPoint("RIGHT", 0, 0)
    presetContainer:SetHeight(48)
    f._presetContainer = presetContainer
    f._pills = {}
    y = y - 54

    local reasonLabel = NUL:CreateLabel(content, {
        text  = L["Custom reason..."],
        color = theme.colors.text.muted,
    })
    reasonLabel:SetPoint("TOPLEFT", 0, y); y = y - 16

    local reasonBox = NUL:EditBox(content, { width = W - 24, height = 26 })
    reasonBox:SetPoint("TOPLEFT", 0, y); y = y - 34

    local notesLabel = NUL:CreateLabel(content, {
        text  = L["Notes"],
        color = theme.colors.text.muted,
    })
    notesLabel:SetPoint("TOPLEFT", 0, y); y = y - 16

    local notesBox = NUL:EditBox(content, {
        width      = W - 24,
        height     = 70,
        multiline  = true,
        maxLetters = 1000,
    })
    notesBox:SetPoint("TOPLEFT", 0, y); y = y - 78

    local classLabel = NUL:CreateLabel(content, {
        text  = L["Class"] or "Class",
        color = theme.colors.text.muted,
    })
    classLabel:SetPoint("TOPLEFT", 0, y); y = y - 18

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
    classDD:SetPoint("TOPLEFT", 0, y); y = y - 34

    local roleLabel = NUL:CreateLabel(content, {
        text  = L["Role"] or "Role",
        color = theme.colors.text.muted,
    })
    roleLabel:SetPoint("TOPLEFT", 0, y); y = y - 18

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
    roleDD:SetPoint("TOPLEFT", 0, y); y = y - 34

    local muteCB = NUL:Checkbox(content, { label = L["Mute chat from this player"] })
    muteCB:SetPoint("TOPLEFT", 0, y); y = y - 24

    local pinCB = NUL:Checkbox(content, { label = L["Pin entry (protect from auto-cleanup)"] })
    pinCB:SetPoint("TOPLEFT", 0, y); y = y - 24

    local shareCB
    if NBK:GetModule("Sync") then
        shareCB = NUL:Checkbox(content, { label = L["Share this entry"] })
        shareCB:SetPoint("TOPLEFT", 0, y)
    end

    local cancel = NUL:Button(content, {
        label = CANCEL or L["Cancel"], width = 80, height = 24,
        onClick = function() f:Hide() end,
    })
    cancel:SetPoint("BOTTOMRIGHT", 0, 0)

    local accept = NUL:Button(content, {
        label = OKAY or "OK", width = 80, height = 24, style = "accent",
    })
    accept:SetPoint("BOTTOMRIGHT", cancel, "BOTTOMLEFT", -6, 0)

    f._nameEB, f._reasonEB, f._notesEB = nameBox, reasonBox, notesBox
    f._muteCB, f._shareCB, f._pinCB    = muteCB, shareCB, pinCB
    f._roleDD, f._classDD              = roleDD, classDD
    f.acceptButton = accept

    function f:RefreshPills()
        for _, p in ipairs(self._pills) do p:Hide() end
        wipe(self._pills)

        local presets = (NBK.db and NBK.db.settings and NBK.db.settings.presetReasons)
                        or NBK.PRESET_REASONS
        local rowW = presetContainer:GetWidth()
        if rowW <= 0 then rowW = W - 24 end

        local x, rowY, lineH = 0, 0, 22
        for _, preset in ipairs(presets) do
            local label = L[preset] or preset
            local pill = NUL:Pill(presetContainer, {
                label = label,
                onClick = function(self)
                    f._reasonEB:SetText(label)
                    for _, other in ipairs(f._pills) do
                        other:SetSelected(other == self)
                    end
                end,
            })
            local pw = pill:GetWidth()
            if x + pw > rowW then
                x = 0
                rowY = rowY - lineH - 2
            end
            pill:ClearAllPoints()
            pill:SetPoint("TOPLEFT", presetContainer, "TOPLEFT", x, rowY)
            x = x + pw + 4
            table.insert(self._pills, pill)
        end
    end

    function f:SetValues(values)
        values = values or {}
        self._nameEB:SetText(values.name or "")
        self._nameEB:SetCursorPosition(0)
        self._reasonEB:SetText(values.reason or "")
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

        local r = values.reason
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

    presetContainer:SetScript("OnSizeChanged", function() f:RefreshPills() end)
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
        if not values.name or values.name == "" then
            return false, "name required"
        end
        local entry, err = NBK:AddPlayer(values.name, nil, values.reason)
        if not entry then return false, err end
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
end

function BlacklistTab:_ShowEditDialog(entry)
    if not self.editDialog then
        self.editDialog = buildRichDialog("NBKEditDialog", "Edit blacklist entry")
    end
    local dialog = self.editDialog
    dialog:SetNameEditable(false)

    if dialog._classDD then dialog._classDD:SetEnabled(true) end
    dialog:SetValues({
        name      = entry.name .. "-" .. entry.realm,
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
end

function BlacklistTab:_RefreshAddDialogPills()
    if self.addDialog and self.addDialog.RefreshPills then
        self.addDialog:RefreshPills()
    end
    if self.editDialog and self.editDialog.RefreshPills then
        self.editDialog:RefreshPills()
    end
end
