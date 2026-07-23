-- NerzorsUILib-1.0 :: Widgets/Dropdown.lua
-- Themed select-style dropdown. Avoids Blizzard's UIDropDownMenu so the
-- skin stays consistent.
--
-- opts:
--   width    number    Container width (px). Default 200.
--   height   number    Container height. Default rowHeight - 2.
--   options  array     { { key, label }, ... }
--   value    any       Initial selected key.
--   onSelect function(key, label, self)
--   arrowIcon string   Custom dropdown arrow icon (path or short name).

local NUL = LibStub("NerzorsUILib-1.0")

function NUL:Dropdown(parent, opts)
    opts = opts or {}
    local theme  = self:GetTheme()
    local width  = opts.width  or 200
    local height = opts.height or (theme.metrics.rowHeight - 2)

    local dd = CreateFrame("Button", nil, parent)
    dd:SetSize(width, height)
    dd.bg      = self:FillBackground(dd)
    dd.borders = self:AddBorder(dd, nil, theme.metrics.borderThickness)

    local label = self:CreateLabel(dd, { text = "", justifyH = "LEFT", wrap = false })
    label:SetPoint("LEFT", 8, 0)
    label:SetPoint("RIGHT", -20, 0)
    dd.label = label

    -- Chevron so the field reads as a dropdown. Defaults to the shared
    -- "arrow-down.png" (same asset the themed scrollbar uses); callers can
    -- override via opts.arrowIcon. Tinted to the label colour in _repaint.
    local arrow = dd:CreateTexture(nil, "OVERLAY")
    arrow:SetSize(10, 10)
    arrow:SetPoint("RIGHT", -6, 0)
    arrow:SetTexture(self:ResolveIcon(opts.arrowIcon or "arrow-down.png"))
    dd.arrow = arrow

    -- Popup lives on UIParent (TOOLTIP strata) so it draws above any
    -- container it pops out of (notably modal dialogs).
    local popup = CreateFrame("Frame", nil, UIParent)
    popup:SetFrameStrata("TOOLTIP")
    popup:SetFrameLevel(400)
    popup:Hide()
    popup.bg      = self:FillBackground(popup)
    popup.borders = self:AddBorder(popup, nil, theme.metrics.borderThickness)
    dd.popup = popup

    dd._buttons = {}
    dd._options = {}
    dd._enabled = true

    local function hidePopup() popup:Hide() end

    function dd:SetOptions(options)
        self._options = options or {}
        for _, b in ipairs(self._buttons) do b:Hide(); b:SetParent(nil) end
        wipe(self._buttons)

        local rowH = 22
        popup:SetSize(width, math.max(1, #self._options) * rowH + 4)

        for i, opt in ipairs(self._options) do
            local b = NUL:Button(popup, {
                label  = opt.label,
                width  = width - 4,
                height = rowH - 2,
                onClick = function()
                    self:SetValue(opt.key)
                    hidePopup()
                    if self._onSelect then self._onSelect(opt.key, opt.label, self) end
                end,
            })
            b:SetPoint("TOPLEFT", 2, -((i - 1) * rowH) - 2)
            self._buttons[i] = b
        end
    end

    function dd:SetValue(key)
        self._value = key
        for _, opt in ipairs(self._options) do
            if opt.key == key then
                self.label:SetText(opt.label)
                return
            end
        end
        self.label:SetText("")
    end

    function dd:GetValue() return self._value end
    function dd:SetOnSelect(fn) self._onSelect = fn end

    function dd:SetEnabled(v)
        self._enabled = v and true or false
        if not v then popup:Hide() end
        self:_repaint(NUL:GetTheme())
    end

    function dd:_repaint(t)
        NUL.SetTextureColor(self.bg, t.colors.bg.elevated)
        NUL:RecolorBorder(self.borders, t.colors.border.subtle)
        NUL.SetTextureColor(self.popup.bg, t.colors.bg.base)
        NUL:RecolorBorder(self.popup.borders, t.colors.border.subtle)
        local lc = self._enabled and t.colors.text.primary or t.colors.text.muted
        NUL.SetFontColor(self.label, lc)
        self.arrow:SetVertexColor(lc.r, lc.g, lc.b, self._enabled and 1 or 0.6)
    end

    dd:SetScript("OnClick", function(self)
        if not self._enabled then return end
        if popup:IsShown() then
            popup:Hide()
        else
            popup:ClearAllPoints()
            popup:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 0, -2)
            popup:Show()
            popup:Raise()
        end
    end)
    dd:SetScript("OnHide", function() popup:Hide() end)
    dd:SetScript("OnEnter", function(self)
        if self._enabled then NUL:RecolorBorder(self.borders, NUL:GetTheme().colors.border.accent) end
    end)
    dd:SetScript("OnLeave", function(self) NUL:RecolorBorder(self.borders, NUL:GetTheme().colors.border.subtle) end)

    if opts.options then dd:SetOptions(opts.options) end
    if opts.value   then dd:SetValue(opts.value)     end
    if opts.onSelect then dd._onSelect = opts.onSelect end

    self:_Track(dd)
    dd:_repaint(theme)
    return dd
end
