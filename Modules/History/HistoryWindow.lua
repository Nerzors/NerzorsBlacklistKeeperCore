local _, NBK = ...
local NUL = LibStub("NerzorsUILib-1.0")

local History = NBK:GetModule("RemovalHistory")
if not History then return end

local ROW_HEIGHT, VISIBLE_ROWS = 24, 9
local ui = { tab = "manual" }

local SOURCES = {
    autoCleanup = "Auto-cleanup",
    ignoreTool  = "Ignore Manager: Clean up",
    deleted     = "Characters that no longer exist",
}

local function rowBuilder(row)
    local theme = NUL:GetTheme()
    local name = NUL:CreateLabel(row, { text = "", justifyH = "LEFT", wrap = false })
    name:SetPoint("LEFT", 8, 0)
    name:SetWidth(150)
    local reason = NUL:CreateLabel(row, {
        text = "", size = "sm", color = theme.colors.text.muted, justifyH = "LEFT", wrap = false,
    })
    reason:SetPoint("LEFT", name, "RIGHT", 8, 0)
    reason:SetWidth(130)
    local restore = NUL:Button(row, {
        label = NBK.L["Restore"], width = 110, height = 20,
        onClick = function() if row._rec then History:Restore(row._rec) end end,
    })
    restore:SetPoint("RIGHT", -24, 0)
    local when = NUL:CreateLabel(row, {
        text = "", size = "sm", color = theme.colors.text.muted, justifyH = "RIGHT", wrap = false,
    })
    when:SetPoint("RIGHT", restore, "LEFT", -8, 0)

    return function(_, rec)
        row._rec = rec
        local e = rec.entry or {}
        name:SetText(NBK:DisplayName(e.name, e.realm, NBK:GetClassHex(e.class)))
        local r = (e.reason and e.reason ~= "") and (NBK.ReasonText and NBK:ReasonText(e.reason) or e.reason) or ""
        reason:SetText(r)
        when:SetText(rec.at and NBK:FormatDateTime(rec.at) or "")
    end
end

local PILL_PAD, PILL_MIN = 28, 110
local function setPill(pill, text)
    pill:SetLabel(text)
    local w = tonumber(pill.label and pill.label.GetStringWidth and pill.label:GetStringWidth()) or 0
    pill:SetWidth(math.max(PILL_MIN, math.ceil(w) + PILL_PAD))
end

local function update()
    if not ui.f then return end
    local L = NBK.L
    local manual, run = History:Manual(), History:Cleanup()
    local runItems = run and run.items or {}
    setPill(ui.manualPill, L["Your removals (%d)"]:format(#manual))
    setPill(ui.cleanupPill, L["Clean-up (%d)"]:format(#runItems))
    ui.cleanupPill:ClearAllPoints()
    ui.cleanupPill:SetPoint("LEFT", ui.manualPill, "RIGHT", 6, 0)
    ui.manualPill:SetSelected(ui.tab == "manual")
    ui.cleanupPill:SetSelected(ui.tab == "cleanup")

    if ui.tab == "manual" then
        ui.info:SetText(L["Your last %d removals. How many are kept: Settings > Advanced."]:format(History:Size()))
        ui.list:SetEmptyText(L["Nothing removed yet."])
        ui.list:SetData(manual)
        ui.all:Hide()
    else
        if run then
            ui.info:SetText(L["Last clean-up: %s, %s"]:format(L[SOURCES[run.source] or "Auto-cleanup"],
                NBK:FormatDateTime(run.at)))
        else
            ui.info:SetText(L["No clean-up run yet."])
        end
        ui.list:SetEmptyText(L["Nothing removed yet."])
        ui.list:SetData(runItems)
        ui.all:SetShown(#runItems > 0)
    end
end
History._UpdateWindow = update

local function build()
    if ui.f then return ui.f end
    local L, theme = NBK.L, NUL:GetTheme()

    local f = NUL:Window({
        name   = "NBKRemovalHistory",
        title  = L["Removal history"],
        width  = 560, height = 360,
        strata = "DIALOG",
    })
    if f.SetPositionKey then f:SetPositionKey("RemovalHistory", NBK.db); f:RestorePosition() end
    ui.f = f

    ui.manualPill = NUL:Pill(f.content, {
        label = "", onClick = function() ui.tab = "manual"; update() end,
    })
    ui.manualPill:SetPoint("TOPLEFT", 0, 0)
    ui.cleanupPill = NUL:Pill(f.content, {
        label = "", onClick = function() ui.tab = "cleanup"; update() end,
    })
    for _, p in ipairs({ ui.manualPill, ui.cleanupPill }) do
        if p.label and p.label.SetWordWrap then p.label:SetWordWrap(false) end
    end

    ui.info = NUL:CreateLabel(f.content, {
        text = "", size = "sm", color = theme.colors.text.muted, justifyH = "LEFT",
    })
    ui.info:SetPoint("TOPLEFT", ui.manualPill, "BOTTOMLEFT", 0, -8)
    ui.info:SetPoint("RIGHT", f.content, "RIGHT", 0, 0)

    ui.list = NUL:ScrollList(f.content, { rowHeight = ROW_HEIGHT, rowBuilder = rowBuilder })
    ui.list.container:SetPoint("TOPLEFT", ui.info, "BOTTOMLEFT", 0, -6)
    ui.list.container:SetPoint("RIGHT", f.content, "RIGHT", 0, 0)
    ui.list.container:SetHeight(ROW_HEIGHT * VISIBLE_ROWS + 4)

    local close = NUL:Button(f.content, {
        label = L["Close"], width = 110, height = 26,
        onClick = function() f:Hide() end,
    })
    close:SetPoint("BOTTOMRIGHT", 0, 0)

    ui.all = NUL:Button(f.content, {
        label = L["Restore all"], width = 140, height = 26, style = "primary",
        onClick = function() History:RestoreRun() end,
    })
    ui.all:SetPoint("RIGHT", close, "LEFT", -6, 0)

    History:OnChanged(function() if f:IsShown() then update() end end)
    return f
end

function History:ShowWindow(tab)
    local f = build()
    if tab then ui.tab = tab end
    update()
    f:Show()
    if f.Raise then f:Raise() end

    if C_Timer and C_Timer.After then C_Timer.After(0, update) end
end
