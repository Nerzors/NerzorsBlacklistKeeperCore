local _, NBK = ...

function NBK:PopulateLauncherTooltip(tt, opts)
    if not tt then return end
    opts = opts or {}
    local L = NBK.L

    tt:AddLine("|cff9b59b6" .. (L["Nerzors Blacklist Keeper"] or "Nerzors Blacklist Keeper") .. "|r")
    tt:AddLine((L["%d entries"] or "%d entries"):format(NBK:CountEntries()), 1, 1, 1)

    local active = {}
    for _, m in ipairs(NBK.OPTIONAL_MODULES or {}) do
        if NBK:GetModule(m.key) then
            active[#active + 1] = L[m.labelKey] or m.labelKey
        end
    end
    if #active > 0 then
        tt:AddLine(" ")
        tt:AddLine(L["Modules"] or "Modules", 1, 0.82, 0)
        for _, label in ipairs(active) do
            tt:AddLine("  |cff5cb85c|TInterface\\Buttons\\UI-CheckBox-Check:0:0:0:0|t|r " .. label, 0.85, 0.85, 0.85)
        end
    end

    tt:AddLine(" ")
    tt:AddLine(L["Left-click: open list"] or "Left-click: open list", 0.7, 0.7, 0.7)
    tt:AddLine(L["Right-click: settings"] or "Right-click: settings", 0.7, 0.7, 0.7)
    if opts.drag then
        tt:AddLine(L["Drag: move around minimap"] or "Drag: move around minimap", 0.7, 0.7, 0.7)
    end
end
