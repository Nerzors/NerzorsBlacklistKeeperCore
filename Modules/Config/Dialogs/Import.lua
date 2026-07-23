local _, NBK = ...
local Config = NBK:GetModule("Config")
if not Config then return end

local NUL = LibStub("NerzorsUILib-1.0")

function Config:ShowImportDialog()
    if self._importDlg then
        self:_resetImportDialog()
        self._importDlg:Show()
        return
    end

    local L     = NBK.L
    local theme = NUL:GetTheme()

    local f = NUL:Window({
        name   = "NBKImportDialog",
        title  = L["Import blacklist"],
        width  = 560, height = 460,
        strata = "FULLSCREEN_DIALOG",
    })
    f:SetFrameLevel(200)
    self._importDlg = f

    local content = f.content

    local hint = NUL:CreateLabel(content, {
        text  = L["Paste an exported blacklist string below, then click Preview."],
        size  = "sm",
        color = theme.colors.text.muted,
        justifyH = "LEFT",
    })
    hint:SetPoint("TOPLEFT", 4, -4)
    hint:SetPoint("RIGHT",   -4, 0)

    local importBox = NUL:EditBox(content, {
        multiline  = true,
        maxLetters = 0,
    })
    importBox:ClearAllPoints()
    importBox:SetPoint("TOPLEFT",  content, "TOPLEFT",  4, -24)
    importBox:SetPoint("TOPRIGHT", content, "TOPRIGHT", -4, -24)
    importBox:SetHeight(180)
    importBox.editBox:SetMaxBytes(0)
    f._eb = importBox

    local preview = NUL:CreateLabel(content, {
        text = "", color = theme.colors.text.primary, justifyH = "LEFT",
    })
    preview:SetPoint("TOPLEFT", 4, -214)
    preview:SetPoint("RIGHT",   -4, 0)
    f._preview = preview

    local modeHint = NUL:CreateLabel(content, {
        text  = L["Import mode:"],
        color = theme.colors.text.muted,
    })
    modeHint:SetPoint("TOPLEFT", 4, -258)

    local modeDD = NUL:Dropdown(content, {
        width = 360, height = 24,
        options = {
            { key = "merge",     label = L["Merge - add new only"] },
            { key = "overwrite", label = L["Overwrite - replace duplicates"] },
            { key = "replace",   label = L["Replace - wipe current, import all"] },
        },
        value = "merge",
    })
    modeDD:SetPoint("TOPLEFT", 4, -278)
    f._modeDD = modeDD

    local previewBtn = NUL:Button(content, {
        label = L["Preview"], width = 110, height = 24,
        onClick = function() Config:_doPreviewImport() end,
    })
    previewBtn:SetPoint("BOTTOMLEFT", 4, 40)

    local importBtn = NUL:Button(content, {
        label = L["Import"], width = 110, height = 24, style = "accent",
        onClick = function() Config:_doApplyImport() end,
    })
    importBtn:SetPoint("LEFT", previewBtn, "RIGHT", 8, 0)
    importBtn:SetEnabled(false)
    f._importBtn = importBtn

    local closeBtn = NUL:Button(content, {
        label = L["Close"], width = 100, height = 24,
        onClick = function() f:Hide() end,
    })
    closeBtn:SetPoint("BOTTOMRIGHT", -4, 6)

    self:_resetImportDialog()
    f:Show()
end

function Config:_resetImportDialog()
    local f = self._importDlg
    if not f then return end
    if f._eb        then f._eb:SetText("")     end
    if f._preview   then f._preview:SetText("") end
    if f._importBtn then f._importBtn:SetEnabled(false) end
    f._parsed = nil
end

function Config:ShowImportDialogWithText(text, senderLabel)
    self:ShowImportDialog()
    local f = self._importDlg
    if not f or not f._eb then return end

    f._eb:SetText(NBK:EscapeForDisplay(text or ""))
    if senderLabel and f.titleText then
        local L = NBK.L
        local base = L["Import blacklist"] or "Import blacklist"
        local from = L["from %s"]          or "from %s"
        f.titleText:SetText(base .. " - " .. from:format(senderLabel))
    end
    self:_doPreviewImport()
end

function Config:_doPreviewImport()
    local f = self._importDlg
    if not f then return end
    local L     = NBK.L
    local theme = NUL:GetTheme()

    local function fail(msg)
        NUL.SetFontColor(f._preview, theme.colors.state.danger)
        f._preview:SetText(msg)
        f._importBtn:SetEnabled(false)
        f._parsed = nil
    end

    local text   = f._eb:GetText() or ""
    local parsed = NBK:ParseImport(text)

    if not parsed.magic then
        return fail(L["Invalid input - missing !NBK1! header."])
    end
    if not parsed.ok then

        return fail(parsed.errors and parsed.errors[1]
            or (L["Invalid input - missing !NBK1! header."]))
    end

    local classify  = NBK:ClassifyImport(parsed)
    local spec      = NBK:GetListType(parsed.list)
    local listLabel = (spec and spec.label) or parsed.list

    f._preview:SetTextColor(1, 1, 1)

    f._preview:SetText(("[%s]  "):format(listLabel) ..
        (L["Found %d entries: %d new, %d duplicate. Skipped: %d."])
        :format(classify.total, classify.new, classify.duplicate, parsed.skipped or 0))
    f._importBtn:SetEnabled(classify.total > 0)
    f._parsed = parsed
end

function Config:_doApplyImport()
    local f = self._importDlg
    local L = NBK.L
    if not f or not f._parsed then return end
    local mode   = f._modeDD:GetValue() or "merge"
    local counts = NBK:ApplyImport(f._parsed, mode)
    NBK:Print((L["Import done: +%d added, %d skipped, %d overwritten, %d removed."])
        :format(counts.added, counts.skipped, counts.overwritten, counts.removed))

    if f._parsed.list == "blacklist" then
        self:RefreshListData()
    else

        local mod = NBK:GetModule(f._parsed.list == "rememberme" and "RememberMe" or "")
        if mod and mod.RefreshTab then mod:RefreshTab() end
    end
    f:Hide()
end
