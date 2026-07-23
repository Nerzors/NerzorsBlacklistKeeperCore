-- NerzorsUILib-1.0 :: Widgets/ScrollList.lua
-- Virtualized-ish vertical list. Reuses row frames across SetData calls.
--
-- opts:
--   rowHeight  number    Per-row height in px. Required.
--   rowBuilder function(row) -> function(row, entry, index)
--                        Called once per row to set up the row's child
--                        widgets and returns a populate function that
--                        the list calls on each SetData with the row's
--                        data entry.
--   striped    boolean   Default true - alternates panel/elevated per row.
--
-- list:SetData(array)    Renders the array; reuses rows where possible.
-- list:Refresh()         Re-runs populate without changing the dataset.
-- list:GetRow(i)         Returns the row frame at index i, if any.

local NUL = LibStub("NerzorsUILib-1.0")

local function clamp(v, lo, hi) return math.max(lo, math.min(hi, v)) end

-- Replace the default (Blizzard "classic") UIPanelScrollFrameTemplate
-- scrollbar with a minimal themed one: a thin accent thumb on a subtle
-- track, plus arrow-icon up/down buttons with no border/background. The
-- native scrollbar's field layout changed across game versions (its
-- up/down buttons aren't reliably reachable by name), so instead of
-- hunting individual buttons we hide the WHOLE native scrollbar and drive
-- scrolling ourselves via SetVerticalScroll. Returns a controller with
-- `update(self)` (recompute thumb geometry / visibility) and `paint(theme)`
-- (recolour on theme swap).
--
--   scroll     the ScrollFrame (UIPanelScrollFrameTemplate)
--   container  the bordered frame that hosts the scroll frame; the themed
--              bar lives in its right gutter (the 22px the scroll frame
--              leaves free on its right edge).
--   step       scroll delta per wheel notch / button click (px).
function NUL:_AttachThemedScrollBar(scroll, container, step)
    local NUL = self
    step = step or 20

    -- 1. Kill the native scrollbar completely (whole frame, not just its
    --    buttons) so none of the classic chrome shows. Override Show so the
    --    template can't bring it back on a range change.
    local native = scroll.ScrollBar
    if native then
        native:EnableMouse(false)
        native:SetAlpha(0)
        if native.Hide then native:Hide() end
        native.Show = native.Hide
    end

    -- 2. Themed bar, aligned to the SCROLL frame's right edge (works for any
    --    caller: list, multi-line editbox, config/news windows). Parented to
    --    the scroll's parent (or an explicit container) so it isn't clipped by
    --    the scroll frame, and anchored to the scroll itself so it always
    --    matches the scrollable area's height regardless of surrounding padding.
    local host = container or scroll:GetParent()
    local bar = CreateFrame("Frame", nil, host)
    bar:SetWidth(12)
    bar:SetPoint("TOPLEFT",    scroll, "TOPRIGHT",    4, 0)
    bar:SetPoint("BOTTOMLEFT", scroll, "BOTTOMRIGHT", 4, 0)

    local BTN = 12
    local function arrowButton(icon, anchor)
        local b = CreateFrame("Button", nil, bar)
        b:SetSize(BTN, BTN)
        b:SetPoint(anchor, 0, 0)
        local tex = b:CreateTexture(nil, "ARTWORK")
        tex:SetAllPoints()
        tex:SetTexture(NUL:ResolveIcon(icon))
        tex:SetAlpha(0.8)
        b._tex = tex
        b:SetScript("OnEnter", function() tex:SetAlpha(1) end)
        b:SetScript("OnLeave", function() tex:SetAlpha(0.8) end)
        return b
    end
    local up   = arrowButton("arrow-up.png",   "TOP")
    local down = arrowButton("arrow-down.png", "BOTTOM")

    -- Track (thin, centred) between the two buttons.
    local track = CreateFrame("Frame", nil, bar)
    track:SetWidth(4)
    track:SetPoint("TOP",    up,   "BOTTOM", 0, -3)
    track:SetPoint("BOTTOM", down, "TOP",    0,  3)
    local trackTex = track:CreateTexture(nil, "BACKGROUND")
    trackTex:SetAllPoints()

    -- Draggable thumb.
    local thumb = CreateFrame("Frame", nil, track)
    thumb:SetPoint("LEFT")
    thumb:SetPoint("RIGHT")
    thumb:SetHeight(24)
    local thumbTex = thumb:CreateTexture(nil, "ARTWORK")
    thumbTex:SetAllPoints()
    thumb:EnableMouse(true)
    thumb:RegisterForDrag("LeftButton")

    local function scrollBy(delta)
        local range = scroll:GetVerticalScrollRange() or 0
        local cur   = scroll:GetVerticalScroll() or 0
        scroll:SetVerticalScroll(clamp(cur + delta, 0, range))
    end

    local ctrl = {}
    function ctrl.update()
        -- The bar strictly follows the scroll frame: hidden scroll (e.g. a
        -- Config tab that isn't the active one) → no bar; nothing to scroll →
        -- no bar. Lets several stacked scroll frames share one gutter cleanly.
        if not scroll:IsShown() then bar:Hide(); return end
        local range = scroll:GetVerticalScrollRange() or 0
        if range <= 0.5 then bar:Hide(); return end
        bar:Show()
        local trackH  = track:GetHeight() or 1
        local visible = scroll:GetHeight() or 1
        local content = visible + range
        local thumbH  = clamp(trackH * (visible / content), 16, trackH)
        thumb:SetHeight(thumbH)
        local cur  = scroll:GetVerticalScroll() or 0
        local frac = (range > 0) and (cur / range) or 0
        thumb:ClearAllPoints()
        thumb:SetPoint("LEFT"); thumb:SetPoint("RIGHT")
        thumb:SetPoint("TOP", track, "TOP", 0, -(trackH - thumbH) * frac)
    end

    -- Wheel + buttons + drag → SetVerticalScroll, then refresh the thumb.
    scroll:EnableMouseWheel(true)
    scroll:SetScript("OnMouseWheel", function(_, d) scrollBy(-d * step); ctrl.update() end)
    up:SetScript("OnClick",   function() scrollBy(-step); ctrl.update() end)
    down:SetScript("OnClick", function() scrollBy(step);  ctrl.update() end)

    thumb:SetScript("OnDragStart", function(self)
        self._startY      = select(2, GetCursorPosition())
        self._startScroll = scroll:GetVerticalScroll() or 0
        self:SetScript("OnUpdate", function(s)
            local scale   = UIParent:GetEffectiveScale()
            local y       = select(2, GetCursorPosition())
            local dyPx    = (s._startY - y) / scale
            local trackH  = track:GetHeight() or 1
            local thumbH  = thumb:GetHeight() or 1
            local range   = scroll:GetVerticalScrollRange() or 0
            local usable  = math.max(1, trackH - thumbH)
            scroll:SetVerticalScroll(clamp(s._startScroll + (dyPx / usable) * range, 0, range))
            ctrl.update()
        end)
    end)
    thumb:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)

    -- All additive hooks (HookScript), so a caller's own handlers still run.
    -- Note: NUL:ScrollList re-SetScripts OnSizeChanged after this call, which
    -- would drop an OnSizeChanged hook - so it calls ctrl.update from there
    -- itself. Every other caller keeps this hook.
    scroll:HookScript("OnVerticalScroll",     ctrl.update)
    scroll:HookScript("OnScrollRangeChanged", ctrl.update)
    scroll:HookScript("OnSizeChanged",        ctrl.update)
    scroll:HookScript("OnShow",               ctrl.update)
    scroll:HookScript("OnHide",               function() bar:Hide() end)

    function ctrl.paint(t)
        t = t or NUL:GetTheme()
        local subtle = t.colors.border.subtle
        local accent = t.colors.accent.primary
        trackTex:SetTexture(t.media.bg)
        trackTex:SetVertexColor(subtle.r, subtle.g, subtle.b, 0.5)
        thumbTex:SetTexture(t.media.bg)
        thumbTex:SetVertexColor(accent.r, accent.g, accent.b, 0.85)
    end
    ctrl.paint(NUL:GetTheme())

    return ctrl
end

function NUL:ScrollList(parent, opts)
    opts = opts or {}
    local theme = self:GetTheme()
    local rowHeight  = opts.rowHeight or theme.metrics.rowHeight
    local rowBuilder = opts.rowBuilder
    assert(type(rowBuilder) == "function", "ScrollList: opts.rowBuilder required")
    local striped = opts.striped ~= false

    local container = CreateFrame("Frame", nil, parent)
    container.bg      = self:FillBackground(container)
    container.borders = self:AddBorder(container, nil, theme.metrics.borderThickness)

    local scroll = CreateFrame("ScrollFrame", nil, container, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 2, -2)
    scroll:SetPoint("BOTTOMRIGHT", -22, 2)

    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(1, 1)
    scroll:SetScrollChild(content)

    -- Swap the classic Blizzard scrollbar for a minimal themed one (thin
    -- accent thumb + arrow-icon buttons, no border/bg). See
    -- _AttachThemedScrollBar above.
    local sbar = self:_AttachThemedScrollBar(scroll, container, rowHeight)

    local rows = {}
    local list = {
        container   = container,
        scrollFrame = scroll,
        content     = content,
        rows        = rows,
        _rowHeight  = rowHeight,
        _striped    = striped,
        _sbar       = sbar,
    }

    local function stripeFor(i, t)
        if not striped then return t.colors.bg.elevated end
        return (i % 2 == 0) and t.colors.bg.elevated or t.colors.bg.panel
    end

    local function acquireRow(i)
        local row = rows[i]
        if not row then
            row = CreateFrame("Button", nil, content)
            row:SetHeight(rowHeight)
            row.bg = row:CreateTexture(nil, "BACKGROUND")
            row.bg:SetAllPoints()
            row._index = i
            row._stripe = stripeFor(i, NUL:GetTheme())
            NUL.SetTextureColor(row.bg, row._stripe)
            row:SetScript("OnEnter", function(self) NUL.SetTextureColor(self.bg, NUL:GetTheme().colors.bg.hover) end)
            row:SetScript("OnLeave", function(self) NUL.SetTextureColor(self.bg, self._stripe) end)
            row.populate = rowBuilder(row)
            rows[i] = row
        end
        return row
    end

    function list:SetData(data)
        self.data = data
        local count = #data
        content:SetWidth(scroll:GetWidth())
        content:SetHeight(math.max(count * rowHeight, 1))
        for i, entry in ipairs(data) do
            local row = acquireRow(i)
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT",  content, "TOPLEFT",  0, -(i - 1) * rowHeight)
            row:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, -(i - 1) * rowHeight)
            row:Show()
            row.populate(row, entry, i)
        end
        for i = count + 1, #rows do rows[i]:Hide() end
        -- Refresh the themed scrollbar's thumb/visibility. The scroll range
        -- only settles a frame after the content height change, so run it
        -- now and once more next frame.
        if self._sbar then
            self._sbar.update()
            if C_Timer and C_Timer.After then C_Timer.After(0, self._sbar.update) end
        end
    end

    function list:Refresh()
        if self.data then self:SetData(self.data) end
    end

    function list:GetRow(i) return rows[i] end

    function list:_repaint(t)
        NUL.SetTextureColor(self.container.bg, t.colors.bg.elevated)
        NUL:RecolorBorder(self.container.borders, t.colors.border.subtle)
        for i, row in ipairs(rows) do
            row._stripe = stripeFor(i, t)
            NUL.SetTextureColor(row.bg, row._stripe)
        end
        if self._sbar then self._sbar.paint(t) end
    end

    scroll:SetScript("OnSizeChanged", function(_, w)
        content:SetWidth(w)
        if sbar then sbar.update() end
    end)

    NUL:_Track(list)
    list:_repaint(theme)
    return list
end
