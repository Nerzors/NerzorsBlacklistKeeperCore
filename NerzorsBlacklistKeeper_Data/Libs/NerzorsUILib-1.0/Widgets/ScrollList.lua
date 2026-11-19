-- NerzorsUILib-1.0 :: Widgets/ScrollList.lua
-- Virtualized vertical list: only the rows in view have a frame (plus one
-- spare), however long the data is. Scrolling re-binds those frames to the
-- entries that come into view.
--
-- opts:
--   rowHeight  number    Per-row height in px. Default theme.metrics.rowHeight.
--   rowBuilder function(row) -> function(row, entry, index)
--                        Called once per row FRAME to set up its child
--                        widgets; returns a populate function. A frame
--                        shows a different entry whenever the list scrolls
--                        or the data changes, so populate must set
--                        everything the row displays or does (texts,
--                        checks, click handlers, tooltips) from `entry` -
--                        nothing may be left over from the previous one.
--   striped    boolean   Default true - alternates panel/elevated per row
--                        (by data index, so stripes scroll with the rows).
--   emptyText  string    Caption shown while the list has no entries.
--
-- list:SetData(array)    Shows the array. Keeps the scroll position (clamped
--                        to the new length) and re-populates the rows in view.
-- list:Refresh()         Re-populates the rows in view from the same data.
-- list:SetEmptyText(s)   Sets / clears the empty-state caption.
-- list:ScrollToTop()
-- list:GetRow(i)         The frame showing entry i, or nil if out of view.

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

    -- Row pool. Slot = ((dataIndex - 1) % pool) + 1, so while an entry stays
    -- in view it keeps its frame: scrolling by one row re-populates one row,
    -- and the frame under the cursor changes (OnLeave / OnEnter fire as
    -- they did when every entry had a frame of its own). Slots are built on
    -- first use and kept when the pool shrinks, so `rows` can have holes
    -- and more frames than the pool: walk it with pairs().
    local rows = {}
    local list = {
        container   = container,
        scrollFrame = scroll,
        content     = content,
        rows        = rows,
        data        = {},
        _rowHeight  = rowHeight,
        _striped    = striped,
        _sbar       = sbar,
        _pool       = 0,
        _emptyText  = opts.emptyText or "",
    }

    -- A theme skin may give lists their own colours (skin.list, Core/Skin.lua)
    -- - ModernBlizz lets the window picture show through the rows.
    local function stripeFor(i, t)
        local sl = t.skin and t.skin.list
        if sl then
            if not striped then return sl.row end
            return (i % 2 == 0) and (sl.rowAlt or sl.row) or sl.row
        end
        if not striped then return t.colors.bg.elevated end
        return (i % 2 == 0) and t.colors.bg.elevated or t.colors.bg.panel
    end

    -- The hover flag is only ever set by the scripts below; a builder that
    -- replaces them (for its own tooltip) simply gets no hover tint, as before.
    local function paintRow(row, t)
        if row._hover and not row:IsMouseOver() then row._hover = false end
        NUL.SetTextureColor(row.bg, row._hover and t.colors.bg.hover or row._stripe)
    end

    local function buildRow(slot)
        local row = CreateFrame("Button", nil, content)
        row:SetHeight(rowHeight)
        row.bg = row:CreateTexture(nil, "BACKGROUND")
        row.bg:SetAllPoints()
        row._slot   = slot
        row._stripe = stripeFor(slot, NUL:GetTheme())
        NUL.SetTextureColor(row.bg, row._stripe)
        row:SetScript("OnEnter", function(self)
            self._hover = true
            NUL.SetTextureColor(self.bg, NUL:GetTheme().colors.bg.hover)
        end)
        row:SetScript("OnLeave", function(self)
            self._hover = false
            NUL.SetTextureColor(self.bg, self._stripe)
        end)
        row:Hide()
        row.populate = rowBuilder(row)
        rows[slot] = row
        return row
    end

    local function release(row)
        row._dataIndex, row._entry, row._hover = nil, nil, false
        row:Hide()
    end

    -- Height of the visible area, and whether it is known yet. Before the
    -- first layout pass an anchored frame can still report 0.
    local function viewHeight()
        local h = scroll:GetHeight() or 0
        if h >= 1 then return h, true end
        return 600, false
    end

    local rendering = false

    -- Bind the rows in view to their entries. `force` re-populates every
    -- visible row (new data, Refresh); without it only rows whose entry
    -- changed are touched, which is what scrolling and resizing need.
    local function render(force)
        if rendering then return end
        rendering = true

        local data  = list.data
        local count = #data
        local viewH, known = viewHeight()

        -- Pool = rows that fit, plus one for the row cut off at the edge. A
        -- different size changes which slot an entry maps to, so every
        -- binding is dropped and the (few) rows in view are bound afresh.
        local pool = math.ceil(viewH / rowHeight) + 1
        if pool ~= list._pool then
            for _, row in pairs(rows) do release(row) end
            list._pool = pool
            force = true
        end

        -- Keep the offset inside the new content (a shorter result list
        -- while scrolled down). The frame's own range settles a frame late.
        local offset = scroll:GetVerticalScroll() or 0
        if known then
            local maxOffset = math.max(0, count * rowHeight - viewH)
            if offset > maxOffset then
                offset = maxOffset
                scroll:SetVerticalScroll(offset)
            end
        end
        if offset < 0 then offset = 0 end

        local first = math.floor(offset / rowHeight) + 1
        local last  = math.min(count, first + pool - 1)
        local t     = NUL:GetTheme()

        for _, row in pairs(rows) do
            local i = row._dataIndex
            if i and (i < first or i > last) then release(row) end
        end

        for i = first, last do
            local slot  = ((i - 1) % pool) + 1
            local row   = rows[slot] or buildRow(slot)
            local entry = data[i]
            if force or row._dataIndex ~= i or row._entry ~= entry then
                row._dataIndex, row._entry = i, entry
                row:ClearAllPoints()
                row:SetPoint("TOPLEFT",  content, "TOPLEFT",  0, -(i - 1) * rowHeight)
                row:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, -(i - 1) * rowHeight)
                row._stripe = stripeFor(i, t)
                row:Show()
                paintRow(row, t)
                row.populate(row, entry, i)
            end
        end

        rendering = false
    end

    -- Empty-state caption, centred near the top of the box. Built on first use.
    local function updateEmpty()
        local show = list._emptyText ~= "" and #list.data == 0
        local fs = list._emptyLabel
        if not fs then
            if not show then return end
            fs = NUL:CreateLabel(container, {
                text = "", color = NUL:GetTheme().colors.text.muted, justifyH = "CENTER",
            })
            fs:SetPoint("TOPLEFT",  container, "TOPLEFT",  24, -24)
            fs:SetPoint("TOPRIGHT", container, "TOPRIGHT", -24, -24)
            list._emptyLabel = fs
        end
        if show then fs:SetText(list._emptyText) end
        fs:SetShown(show)
    end

    function list:SetData(data)
        self.data = data or {}
        content:SetWidth(scroll:GetWidth())
        content:SetHeight(math.max(#self.data * rowHeight, 1))
        render(true)
        updateEmpty()
        -- The scroll range (and, on a first show, the frame's own height)
        -- only settles a frame after the content height change, so run the
        -- thumb update now and once more next frame, with a cheap re-bind.
        sbar.update()
        if C_Timer and C_Timer.After then
            C_Timer.After(0, function() render(false); sbar.update() end)
        end
    end

    function list:Refresh()
        self:SetData(self.data)
    end

    -- Caption shown instead of rows while the list has no entries; "" or
    -- nil turns it off. Set it before SetData, or any time after.
    function list:SetEmptyText(text)
        self._emptyText = text or ""
        updateEmpty()
    end

    -- The frame currently showing entry `i`; nil while that entry is
    -- scrolled out of view.
    function list:GetRow(i)
        if not i or self._pool == 0 then return nil end
        local row = rows[((i - 1) % self._pool) + 1]
        if row and row._dataIndex == i then return row end
        return nil
    end

    function list:ScrollToTop()
        scroll:SetVerticalScroll(0)
        render(false)
        sbar.update()
    end

    function list:_repaint(t)
        local sl = t.skin and t.skin.list
        NUL.SetTextureColor(self.container.bg, (sl and sl.bg) or t.colors.bg.elevated)
        NUL:RecolorBorder(self.container.borders, t.colors.border.subtle)
        for slot, row in pairs(rows) do
            row._stripe = stripeFor(row._dataIndex or slot, t)
            paintRow(row, t)
        end
        if self._emptyLabel then NUL.SetFontColor(self._emptyLabel, t.colors.text.muted) end
        if self._sbar then self._sbar.paint(t) end
    end

    scroll:HookScript("OnVerticalScroll", function() render(false) end)
    scroll:SetScript("OnSizeChanged", function(_, w)
        content:SetWidth(w)
        render(false)
        sbar.update()
    end)

    NUL:_Track(list)
    list:_repaint(theme)
    return list
end
