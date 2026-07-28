local _, NBK = ...
local NUL = LibStub("NerzorsUILib-1.0")

function NBK:SetupColumnHeader(cell, col)
    if not cell or not col then return end
    cell._col = col
    if not col.compact then return end

    if col.icon then
        local tex = cell:CreateTexture(nil, "ARTWORK")
        tex:SetSize(14, 14)
        tex:SetPoint("LEFT", cell, "LEFT", 0, 0)
        tex:SetTexture(self:IconPath(col.icon))
        cell._icon = tex
    end

    if col.label and col.label ~= "" then
        cell:EnableMouse(true)
        cell:HookScript("OnEnter", function(s) NUL:ShowTooltip(s, col.label) end)
        cell:HookScript("OnLeave", function() NUL:HideTooltip() end)
    end
end

function NBK:PaintColumnHeader(cell, col, active)
    if not cell or not col or not col.compact then return false end
    local t = NUL:GetTheme()

    cell._label:SetText("")

    if cell._arrow then

        cell._arrow:ClearAllPoints()
        cell._arrow:SetPoint("LEFT", cell, "LEFT", 0, 0)
        if active then
            local a = t.colors.accent.primary
            cell._arrow:SetVertexColor(a.r, a.g, a.b, 1)
            cell._arrow:Show()
        elseif col.sortable and not col.icon then

            local c = t.colors.text.muted
            cell._arrow:SetVertexColor(c.r, c.g, c.b, 0.45)
            cell._arrow:Show()
        else
            cell._arrow:Hide()
        end
    end

    if cell._icon then
        cell._icon:SetShown(not active)
        local c = t.colors.text.muted
        cell._icon:SetVertexColor(c.r, c.g, c.b, 1)
    end
    return true
end
