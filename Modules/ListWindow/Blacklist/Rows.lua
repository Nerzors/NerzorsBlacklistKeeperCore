local _, NBK = ...
local NUL = LibStub("NerzorsUILib-1.0")
local UI  = NBK.UI
local L   = NBK.L

local BlacklistTab = NBK:GetModule("BlacklistTab")
if not BlacklistTab then return end

local function buildNoteCell(row, theme)
    local f = CreateFrame("Frame", nil, row)
    f:SetSize(18, 18)
    f:EnableMouse(true)

    local tex = f:CreateTexture(nil, "ARTWORK")
    tex:SetAllPoints()
    tex:SetTexture(NBK:IconPath("notes.png"))
    local c = theme.colors.text.muted
    tex:SetVertexColor(c.r, c.g, c.b, 1)
    f.icon = tex

    f._note = ""
    f:SetScript("OnEnter", function(self)
        if not self._note or self._note == "" then return end

        NUL:ShowTooltipMultiline(self, {
            title  = L["Note"] or "Note",
            body   = self._note,
            anchor = "RIGHT",
        })
    end)
    f:SetScript("OnLeave", function() NUL:HideTooltip() end)

    function f:SetNote(note)
        self._note = note or ""
        if self._note == "" then self:Hide() else self:Show() end
    end

    return f
end

local function buildOptionsCell(row, theme)
    local f = CreateFrame("Frame", nil, row)
    f:SetSize(BlacklistTab.OPTIONS_WIDTH, 26)

    local function makeToggle(texture, tooltipFn)
        local b = NUL:IconButton(f, { icon = texture, size = 24, plain = true })
        b._tooltipFn = tooltipFn

        NUL:AttachTooltip(b, function(self) return self._tooltipFn and self._tooltipFn(self) end)
        return b
    end

    local function applyToggleTint(btn, on)
        local t = NUL:GetTheme()
        local c = on and t.colors.accent.primary or t.colors.text.muted
        btn.icon:SetVertexColor(c.r, c.g, c.b, 1)
    end

    f.mute = makeToggle("invisible.png", function(self)
        return self._on and (L["Mute (on) - click to unmute"] or "Mute (on) - click to unmute")
                       or  (L["Mute (off) - click to mute"]   or "Mute (off) - click to mute")
    end)

    f.sync = makeToggle("share.png", function(self)
        return self._on and (L["Shareable - click to mark private"] or "Shareable - click to mark private")
                       or  (L["Private - click to mark shareable"] or "Private - click to mark shareable")
    end)

    f.edit = NUL:IconButton(f, {
        icon = "edit.png", size = 24, plain = true, tooltip = L["Edit"] or "Edit",
    })
    f.remove = NUL:IconButton(f, {
        icon = "app-close.png", size = 24, style = "danger", plain = true,
        tooltip = L["Remove"] or "Remove",
    })

    f._applyToggleTint = applyToggleTint

    function f:Relayout(showSync)
        local order
        if showSync then
            order = { self.mute, self.sync, self.edit, self.remove }
        else
            order = { self.mute, self.edit, self.remove }
            self.sync:Hide()
        end
        local x = 0
        for _, b in ipairs(order) do
            b:Show()
            b:ClearAllPoints()
            b:SetPoint("LEFT", self, "LEFT", x, 0)
            x = x + 24 + 2
        end
    end

    return f
end

function BlacklistTab:MakeRowBuilder(columns)
    return function(row)
        local theme = NUL:GetTheme()
        local cells = {}

        for i, col in ipairs(columns) do
            local cell, fixed
            if col.key == "class" then
                if BlacklistTab:DisplaySettings().classDisplay == "name" then
                    cell = NUL:CreateLabel(row, {
                        text = "", color = theme.colors.text.muted,
                        justifyH = "LEFT", wrap = false,
                    })
                else
                    cell = UI:CreateClassIcon(row, 18)
                    fixed = true
                end
            elseif col.key == "note" then
                cell = buildNoteCell(row, theme)
                fixed = true
            elseif col.key == "options" then
                cell = buildOptionsCell(row, theme)
                fixed = true
            else
                cell = NUL:CreateLabel(row, { text = "", justifyH = "LEFT", wrap = false })
            end
            cell._fixedSize = fixed or false
            cells[i] = cell
        end

        local function layout(totalWidth)
            local fixed = 0
            for _, col in ipairs(columns) do
                if not col.flex then fixed = fixed + col.width end
            end
            local flexW = math.max(60, totalWidth - fixed - (#columns * 4) - 8)
            local x = 8
            for i, col in ipairs(columns) do
                local c = cells[i]
                local w = col.flex and flexW or col.width
                c:ClearAllPoints()
                if not c._fixedSize and c.SetWidth then
                    c:SetWidth(w)
                end
                c:SetPoint("LEFT", row, "LEFT", x, 0)
                x = x + w + 4
            end
        end
        row._layout = layout
        row._cells  = cells

        return function(r, entry)
            local dispS = BlacklistTab:DisplaySettings()
            r._layout(r:GetWidth())

            if not r._activeStripe then
                local stripe = r:CreateTexture(nil, "ARTWORK")
                stripe:SetPoint("TOPLEFT", r, "TOPLEFT", 0, 0)
                stripe:SetPoint("BOTTOMLEFT", r, "BOTTOMLEFT", 0, 0)
                stripe:SetWidth(3)
                NUL.SetTextureColor(stripe, theme.colors.accent.primary)
                stripe:Hide()
                r._activeStripe = stripe
            end
            local gs = NBK:GetModule("GroupScanner")
            local inGroup = gs and gs:IsInGroup(entry.name, entry.realm) or false
            if inGroup then r._activeStripe:Show() else r._activeStripe:Hide() end

            for i, col in ipairs(columns) do
                local c = cells[i]

                if col.key == "name" then
                    local text
                    if dispS.combinedName then
                        text = ("%s-%s"):format(BlacklistTab:ColoredName(entry, dispS.colorNameByClass), entry.realm)
                    else
                        text = BlacklistTab:ColoredName(entry, dispS.colorNameByClass)
                    end
                    c:SetText(text)

                elseif col.key == "realm" then
                    c:SetText(entry.realm or "")

                elseif col.key == "class" then
                    if dispS.classDisplay == "name" then
                        c:SetText(NBK:GetClassDisplayName(entry.class))
                    else
                        c:SetClass(entry.class, dispS.iconStyle)
                    end

                elseif col.key == "reason" then
                    c:SetText((entry.reason and entry.reason ~= "") and entry.reason or "|cff666666-|r")

                elseif col.key == "zone" then
                    c:SetText(entry.zone or "")

                elseif col.key == "added" then
                    c:SetText(entry.addedAt and BlacklistTab:FormatDate(entry.addedAt) or "-")

                elseif col.key == "seen" then
                    if entry.lastSeen then
                        c:SetText(BlacklistTab:FormatDate(entry.lastSeen))
                    else
                        c:SetText("|cff666666" .. (L["never"] or "never") .. "|r")
                    end

                elseif col.key == "note" then
                    c:SetNote(entry.notes)

                elseif col.key == "options" then
                    local syncLoaded = NBK:GetModule("Sync") ~= nil
                    c:Relayout(syncLoaded)

                    local muteOn = entry.mute ~= false
                    c.mute._on = muteOn
                    c._applyToggleTint(c.mute, muteOn)
                    c.mute:SetScript("OnClick", function()
                        local newVal = not (entry.mute ~= false)
                        NBK:UpdateEntry(entry.name, entry.realm, { mute = newVal })
                        entry.mute = newVal
                        c.mute._on = newVal
                        c._applyToggleTint(c.mute, newVal)
                    end)

                    if syncLoaded then
                        local shareOn = entry.shareable ~= false
                        c.sync._on = shareOn
                        c._applyToggleTint(c.sync, shareOn)
                        c.sync:SetScript("OnClick", function()
                            local newVal = not (entry.shareable ~= false)
                            NBK:UpdateEntry(entry.name, entry.realm, { shareable = newVal })
                            entry.shareable = newVal
                            c.sync._on = newVal
                            c._applyToggleTint(c.sync, newVal)
                        end)
                    end

                    c.edit:SetScript("OnClick", function()
                        BlacklistTab:_ShowEditDialog(entry)
                    end)

                    c.remove:SetScript("OnClick", function()
                        NUL:Confirm({
                            text = (L["Remove %s-%s from blacklist?"]):format(entry.name, entry.realm),
                            onAccept = function()
                                NBK:RemovePlayer(entry.name, entry.realm)
                                BlacklistTab:_Refresh()
                            end,
                        })
                    end)
                end
            end
        end
    end
end
