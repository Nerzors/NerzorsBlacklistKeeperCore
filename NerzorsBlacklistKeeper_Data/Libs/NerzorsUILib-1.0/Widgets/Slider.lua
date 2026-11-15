-- NerzorsUILib-1.0 :: Widgets/Slider.lua
-- Horizontal slider: a thin track, an accent fill up to the thumb, and the
-- current value as text to its right. Built on the plain "Slider" frame
-- type (no Blizzard template), which exists on every client and does the
-- dragging; everything visible is our own textures.
--
-- opts:
--   min, max    number    Range. Default 0 .. 100.
--   step        number    Values snap to min + n * step. Default 1.
--   value       number    Initial value. Default min.
--   width       number    Track width in px. Default 180.
--   valueWidth  number    Room for the value text. Default 48; 0 hides it.
--   format      string | function(value) -> string
--                         How the value is shown. Default "%d".
--   onChange    function(value, self)   Every step while dragging.
--   onRelease   function(value, self)   Once the value has settled (mouse
--                         button up, a wheel notch). Use this one for
--                         anything costly or anything that moves the
--                         slider itself.
--   wheel       boolean   Mouse wheel changes the value. Default false: a
--                         slider inside a scrolling page would otherwise
--                         swallow the wheel and change while scrolling by.
--   tooltip     string    Themed tooltip on the track.
--
-- slider:SetValue(v)   Snaps + clamps; does not call onChange / onRelease.
-- slider:GetValue()
-- slider:SetEnabled(bool)

local NUL = LibStub("NerzorsUILib-1.0")

local HEIGHT  = 20
local TRACK_H = 4
local THUMB_W, THUMB_H = 10, 16
local GAP     = 8

function NUL:Slider(parent, opts)
    opts = opts or {}
    local theme  = self:GetTheme()
    local minV   = opts.min or 0
    local maxV   = opts.max or 100
    if maxV < minV then minV, maxV = maxV, minV end
    local step   = (opts.step and opts.step > 0) and opts.step or 1
    local trackW = opts.width or 180
    local valueW = opts.valueWidth or 48

    local function snap(v)
        v = tonumber(v) or minV
        v = minV + math.floor((v - minV) / step + 0.5) * step
        if v < minV then v = minV elseif v > maxV then v = maxV end
        return v
    end

    local function text(v)
        local f = opts.format
        if type(f) == "function" then return f(v) end
        return (f or "%d"):format(v)
    end

    local c = CreateFrame("Frame", nil, parent)
    c:SetSize(trackW + (valueW > 0 and (GAP + valueW) or 0), HEIGHT)

    local s = CreateFrame("Slider", nil, c)
    s:SetOrientation("HORIZONTAL")
    s:SetSize(trackW, HEIGHT)
    s:SetPoint("LEFT", 0, 0)
    s:SetMinMaxValues(minV, maxV)
    s:SetValueStep(step)
    if s.SetObeyStepOnDrag then s:SetObeyStepOnDrag(true) end
    s:EnableMouse(true)
    s:EnableMouseWheel(opts.wheel and true or false)
    c.slider = s

    local track = s:CreateTexture(nil, "BACKGROUND")
    track:SetHeight(TRACK_H)
    track:SetPoint("LEFT", 0, 0)
    track:SetPoint("RIGHT", 0, 0)

    local thumb = s:CreateTexture(nil, "OVERLAY")
    thumb:SetSize(THUMB_W, THUMB_H)
    s:SetThumbTexture(thumb)

    -- Fill from the left end to the middle of the thumb; it follows the
    -- thumb because it is anchored to it.
    local fill = s:CreateTexture(nil, "ARTWORK")
    fill:SetHeight(TRACK_H)
    fill:SetPoint("LEFT", track, "LEFT", 0, 0)
    fill:SetPoint("RIGHT", thumb, "CENTER", 0, 0)

    local label
    if valueW > 0 then
        label = self:CreateLabel(c, { text = "", justifyH = "LEFT", wrap = false })
        label:SetPoint("LEFT", s, "RIGHT", GAP, 0)
        label:SetWidth(valueW)
    end
    c.track, c.thumb, c.fill, c.label = track, thumb, fill, label

    c._enabled   = true
    c._hover     = false
    c._value     = snap(opts.value or minV)
    c._settled   = c._value      -- last value reported through onRelease
    c._fromCode  = false

    local function paint(t)
        t = t or NUL:GetTheme()
        NUL.SetTextureColor(track, t.colors.border.subtle)
        NUL.SetTextureColor(fill,  t.colors.accent.primary)
        NUL.SetTextureColor(thumb, (c._hover and c._enabled) and t.colors.text.primary
                                                             or t.colors.accent.primary)
        if label then
            NUL.SetFontColor(label, c._enabled and t.colors.text.primary or t.colors.text.muted)
        end
        c:SetAlpha(c._enabled and 1 or 0.5)
    end

    local function showValue()
        if label then label:SetText(text(c._value)) end
    end

    -- Report a settled value once (dragging ends, wheel, click on the track).
    local function settle()
        if c._value == c._settled then return end
        c._settled = c._value
        if opts.onRelease then opts.onRelease(c._value, c) end
    end

    s:SetScript("OnValueChanged", function(_, raw)
        local v = snap(raw)
        if v == c._value then return end
        c._value = v
        showValue()
        if not c._fromCode and opts.onChange then opts.onChange(v, c) end
    end)
    s:SetScript("OnMouseUp", function() if c._enabled then settle() end end)
    s:SetScript("OnMouseWheel", function(_, delta)
        if not c._enabled then return end
        s:SetValue(snap(c._value + (delta > 0 and step or -step)))
        settle()
    end)
    s:SetScript("OnEnter", function() c._hover = true;  paint() end)
    s:SetScript("OnLeave", function() c._hover = false; paint() end)
    if opts.tooltip then self:AttachTooltip(s, opts.tooltip) end

    function c:SetValue(v)
        v = snap(v)
        self._fromCode = true
        s:SetValue(v)
        self._fromCode = false
        -- OnValueChanged doesn't fire when the frame already holds `v`.
        self._value, self._settled = v, v
        showValue()
    end

    function c:GetValue() return self._value end

    function c:SetEnabled(v)
        self._enabled = v and true or false
        s:EnableMouse(self._enabled)
        s:EnableMouseWheel(self._enabled and opts.wheel and true or false)
        paint()
    end

    function c:_repaint(t) paint(t) end

    self:_Track(c)
    c:SetValue(c._value)
    paint(theme)
    return c
end
