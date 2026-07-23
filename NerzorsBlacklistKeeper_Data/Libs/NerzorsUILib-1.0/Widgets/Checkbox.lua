-- NerzorsUILib-1.0 :: Widgets/Checkbox.lua
-- Two sizes share the same internals: full ("standard") with right-side
-- label, and compact ("small") without label.
--
-- opts:
--   label     string    Right-side label text (standard variant only).
--   checked   boolean   Initial state. Default false.
--   size      "standard" | "small". Default "standard".
--   onChange  function(checked, self).

local NUL = LibStub("NerzorsUILib-1.0")

local STANDARD = { width = 280, height = 22, box = 16 }
local SMALL    = { width = 16,  height = 16, box = 16 }

function NUL:Checkbox(parent, opts)
    opts = opts or {}
    local sz = (opts.size == "small") and SMALL or STANDARD
    local cb = CreateFrame("Button", nil, parent)
    cb:SetSize(sz.width, sz.height)
    cb:EnableMouse(true)

    local theme = self:GetTheme()

    -- Box square: background + border + (hidden by default) checkmark.
    local box = CreateFrame("Frame", nil, cb)
    box:SetSize(sz.box, sz.box)
    box:SetPoint("LEFT", 0, 0)
    box.bg      = self:FillBackground(box)
    box.borders = self:AddBorder(box, nil, theme.metrics.borderThickness)

    local check = box:CreateTexture(nil, "ARTWORK")
    check:SetPoint("TOPLEFT", 3, -3)
    check:SetPoint("BOTTOMRIGHT", -3, 3)
    check:Hide()
    cb.box   = box
    cb.check = check

    if sz == STANDARD and opts.label then
        cb.labelFS = self:CreateLabel(cb, { text = opts.label })
        cb.labelFS:SetPoint("LEFT", box, "RIGHT", 8, 0)
    end

    cb._state = opts.checked and true or false

    function cb:SetChecked(v)
        self._state = v and true or false
        self.check:SetShown(self._state)
    end
    function cb:GetChecked() return self._state end
    function cb:SetOnChange(fn) self._onChange = fn end
    function cb:SetLabel(text)
        if self.labelFS then self.labelFS:SetText(text or "") end
    end

    function cb:_repaint(t)
        NUL.SetTextureColor(self.box.bg, t.colors.bg.elevated)
        NUL:RecolorBorder(self.box.borders, t.colors.border.subtle)
        NUL.SetTextureColor(self.check, t.colors.accent.primary)
        if self.labelFS then NUL.SetFontColor(self.labelFS, t.colors.text.primary) end
    end

    cb:SetScript("OnClick", function(self)
        self._state = not self._state
        self.check:SetShown(self._state)
        if self._onChange then self._onChange(self._state, self) end
    end)
    cb:SetScript("OnEnter", function(self) NUL.SetTextureColor(self.box.bg, NUL:GetTheme().colors.bg.hover) end)
    cb:SetScript("OnLeave", function(self) NUL.SetTextureColor(self.box.bg, NUL:GetTheme().colors.bg.elevated) end)

    if opts.onChange then cb._onChange = opts.onChange end
    self:_Track(cb)
    cb:_repaint(theme)
    cb:SetChecked(cb._state)
    return cb
end
