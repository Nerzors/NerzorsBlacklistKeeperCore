local _, NBK = ...
local Config = NBK:GetModule("Config")
if not Config then return end

local NUL = LibStub("NerzorsUILib-1.0")

function Config:ShowExportDialog()
    if self._exportDlg then
        self:_refreshExportDialog()
        self._exportDlg:Show()
        return
    end

    local L     = NBK.L
    local theme = NUL:GetTheme()

    local f = NUL:Window({
        name   = "NBKExportDialog",
        title  = L["Export blacklist"],
        width  = 560, height = 460,
        strata = "FULLSCREEN_DIALOG",
    })
    f:SetFrameLevel(200)
    self._exportDlg = f
    f._listId = "blacklist"

    local content = f.content

    local listTypes = NBK:GetListTypes()
    local topInset  = -4
    if #listTypes > 1 then
        local pickLabel = NUL:CreateLabel(content, {
            text = L["List"] or "List", color = theme.colors.text.muted,
        })
        pickLabel:SetPoint("TOPLEFT", 4, -6)

        local options = {}
        for _, t in ipairs(listTypes) do
            options[#options + 1] = { key = t.id, label = t.label }
        end
        local listDD = NUL:Dropdown(content, {
            width = 200, height = 24,
            options = options,
            value   = "blacklist",
            onSelect = function(id)
                f._listId = id
                Config:_refreshExportDialog()
            end,
        })
        listDD:SetPoint("LEFT", pickLabel, "RIGHT", 8, 0)
        topInset = -36
    end

    local info = NUL:CreateLabel(content, {
        text = "", color = theme.colors.text.muted, justifyH = "LEFT",
    })
    info:SetPoint("TOPLEFT", 4, topInset)
    info:SetPoint("RIGHT",   -4, 0)
    f._info = info

    local hint = NUL:CreateLabel(content, {
        text  = L["Click the box below, press Ctrl+A, then Ctrl+C to copy."],
        size  = "sm",
        color = theme.colors.text.muted,
        justifyH = "LEFT",
    })
    hint:SetPoint("TOPLEFT", 4, topInset - 20)
    hint:SetPoint("RIGHT",   -4, 0)

    local exportBox = NUL:EditBox(content, {
        multiline  = true,
        maxLetters = 0,
    })
    exportBox:ClearAllPoints()
    exportBox:SetPoint("TOPLEFT",     content, "TOPLEFT",     4, topInset - 44)
    exportBox:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", -4, 40)
    exportBox.editBox:SetMaxBytes(0)
    f._eb = exportBox

    local selectBtn = NUL:Button(content, {
        label = L["Select all"], height = 24, style = "accent",
        onClick = function()
            local eb = exportBox.editBox
            eb:SetFocus()
            eb:HighlightText()
        end,
    })
    selectBtn:SetPoint("BOTTOMLEFT", 4, 6)

    local closeBtn = NUL:Button(content, {
        label = L["Close"], height = 24,
        onClick = function() f:Hide() end,
    })
    closeBtn:SetPoint("BOTTOMRIGHT", -4, 6)

    self:_refreshExportDialog()
    f:Show()
end

function Config:_refreshExportDialog()
    local f = self._exportDlg
    if not f then return end
    local L = NBK.L
    local listId = f._listId or "blacklist"

    local sharedOnly = (listId == "blacklist")
        and (NBK:GetSyncSetting("exportSharedOnly", false) and true or false)
        or false

    local text, count = NBK:ExportString({ list = listId, sharedOnly = sharedOnly })

    f._eb:SetText(NBK:EscapeForDisplay(text or ""))

    local spec      = NBK:GetListType(listId)
    local listLabel = (spec and spec.label) or listId
    local summary
    if sharedOnly then
        summary = (L["%d shareable entries exported."]
            or "%d shareable entries exported."):format(count or 0)
    else
        summary = (L["%d entries exported."] or "%d entries exported."):format(count or 0)
    end

    if #NBK:GetListTypes() > 1 then
        summary = summary .. "  (" .. listLabel .. ")"
    end
    f._info:SetText(summary)
end
