local _, NBK = ...
local NUL = LibStub("NerzorsUILib-1.0")

local AutoCleanup = NBK:GetModule("AutoCleanup")
if not AutoCleanup then return end

local ROW_H = 26
local ui = {}

local function refresh()
    if not ui.f then return end
    local L = NBK.L
    local list = AutoCleanup:ListStale(ui.months)
    ui.hint:SetText(L["Entries older than %d months. Pin one to keep it."]:format(ui.months))
    ui.list:SetEmptyText(L["Nothing to remove right now."])
    ui.list:SetData(list)
    ui.count:SetText(L["%d entries"]:format(#list))
end

local function pin(e)
    if not e then return end
    NBK:UpdateEntry(e.name, e.realm, { pinned = true })
    e.pinned = true
    refresh()
    local lw = NBK:GetModule("ListWindow")
    if lw and lw.Refresh then lw:Refresh() end
    if ui.onChange then pcall(ui.onChange) end
end

local function rowBuilder(row)
    local name = NUL:CreateLabel(row, { text = "", justifyH = "LEFT", wrap = false })
    name:SetPoint("LEFT", row, "LEFT", 8, 0)
    name:SetWidth(170)
    local reason = NUL:CreateLabel(row, { text = "", justifyH = "LEFT", wrap = false })
    reason:SetPoint("LEFT", row, "LEFT", 184, 0)
    reason:SetWidth(180)
    local when = NUL:CreateLabel(row, { text = "", size = "sm", justifyH = "LEFT", wrap = false })
    when:SetPoint("LEFT", row, "LEFT", 370, 0)
    when:SetPoint("RIGHT", row, "RIGHT", -36, 0)

    local pinBtn = NUL:IconButton(row, { icon = "pinned.png", size = 24, plain = true,
                                         tooltip = NBK.L["Pin"] })
    pinBtn._ownHue = true
    pinBtn:SetPoint("RIGHT", row, "RIGHT", -6, 0)

    return function(r, e)
        local L, c = NBK.L, NUL:GetTheme().colors
        name:SetText(NBK:DisplayName(e.name, e.realm, NBK:GetClassHex(e.class)))
        reason:SetText((e.reason and e.reason ~= "") and NBK:ReasonText(e.reason) or "|cff666666-|r")
        if e.lastSeen then
            when:SetText(L["last %s"]:format(NBK:FormatDate(e.lastSeen)))
        else
            when:SetText(L["added %s"]:format(NBK:FormatDate(e.addedAt)))
        end
        NUL.SetFontColor(when, c.text.muted)
        if pinBtn.icon then
            pinBtn.icon:SetVertexColor(c.accent.primary.r, c.accent.primary.g, c.accent.primary.b, 1)
        end
        pinBtn:SetScript("OnClick", function() pin(e) end)
    end
end

local function build()
    if ui.f then return ui.f end
    local L, theme = NBK.L, NUL:GetTheme()

    local f = NUL:Window({
        name   = "NBKAutoCleanupPreview",
        title  = L["Auto-cleanup preview"],
        width  = 580, height = 420,
        strata = "DIALOG",
    })
    ui.f = f

    ui.hint = NUL:CreateLabel(f.content, {
        text = "", size = "sm", color = theme.colors.text.muted, justifyH = "LEFT",
    })
    ui.hint:SetPoint("TOPLEFT", 0, 0)
    ui.hint:SetPoint("RIGHT", f.content, "RIGHT", 0, 0)

    local close = NUL:Button(f.content, {
        label = L["Close"], width = 110, height = 26, onClick = function() f:Hide() end,
    })
    close:SetPoint("BOTTOMRIGHT", 0, 0)
    ui.count = NUL:CreateLabel(f.content, { text = "", color = theme.colors.text.muted, wrap = false })
    ui.count:SetPoint("BOTTOMLEFT", 0, 6)

    ui.list = NUL:ScrollList(f.content, { rowHeight = ROW_H, rowBuilder = rowBuilder })
    ui.list.container:SetPoint("TOPLEFT", ui.hint, "BOTTOMLEFT", 0, -10)
    ui.list.container:SetPoint("BOTTOMRIGHT", close, "TOPRIGHT", 0, 10)

    f:HookScript("OnHide", function() NUL:HideTooltip() end)
    return f
end

function AutoCleanup:ShowPreview(months, onChange)
    ui.months   = tonumber(months) or 6
    ui.onChange = onChange
    local f = build()
    refresh()
    ui.list:ScrollToTop()
    f:Show()
    if f.Raise then f:Raise() end
end
