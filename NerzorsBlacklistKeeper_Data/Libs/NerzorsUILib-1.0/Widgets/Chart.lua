-- NerzorsUILib-1.0 :: Widgets/Chart.lua
-- Texture-based charts. Deliberately bars only - no CreateLine, no pie/donut:
-- bars render identically on Retail, Classic Era and MoP Classic with zero
-- API risk, and for the comparisons we show they're the clearer form anyway.
--
-- Both charts share the same contract:
--   data  = { { label = "Jul", value = 12, color = <colorTable|nil> }, … }
--   :SetData(array)     replace the dataset and re-layout
--   :Refresh()          re-layout with the current dataset
--   `color` is optional; omitted → theme accent. Pass a { r, g, b, a } table
--   (NUL.hex("rrggbb") builds one, e.g. from a class colour).
--
-- Values are auto-scaled to the largest data point. Empty / all-zero data
-- renders an "empty" caption instead of a blank box (opts.emptyText).
-- Every bar is a mouse-enabled frame wired to the themed tooltip, so hovering
-- shows the exact "label: value".
--
-- NUL:BarChart(parent, opts)     vertical bars + x-axis labels (time series)
--     opts.height, opts.emptyText
-- NUL:RankedBars(parent, opts)   horizontal ranked rows (label | bar | value)
--     opts.rowHeight (18), opts.maxRows (8), opts.emptyText
--     :GetNaturalHeight()  → rows * rowHeight, so a Card can size itself

local NUL = LibStub("NerzorsUILib-1.0")

local function barColor(item, theme)
    return (item and item.color) or theme.colors.accent.primary
end

local function fmtTip(item)
    return tostring(item.label or "?") .. ": " .. tostring(item.value or 0)
end

-- ─── Vertical bar chart ──────────────────────────────────────────────────

function NUL:BarChart(parent, opts)
    opts = opts or {}
    local theme    = self:GetTheme()
    local LABEL_H  = 14
    local GAP      = 4

    local chart = CreateFrame("Frame", nil, parent)
    chart:SetHeight(opts.height or 120)
    chart._bars      = {}
    chart._data      = {}
    chart._emptyText = opts.emptyText or ""

    chart.axis = chart:CreateTexture(nil, "ARTWORK")
    chart.axis:SetHeight(1)
    chart.axis:SetPoint("BOTTOMLEFT",  0, LABEL_H)
    chart.axis:SetPoint("BOTTOMRIGHT", 0, LABEL_H)

    chart.empty = self:CreateLabel(chart, { text = chart._emptyText, size = "sm", justifyH = "CENTER" })
    chart.empty:SetPoint("CENTER")
    chart.empty:Hide()

    local function acquireBar(i)
        local b = chart._bars[i]
        if not b then
            b = CreateFrame("Frame", nil, chart)
            b:EnableMouse(true)
            b.fill = b:CreateTexture(nil, "ARTWORK")
            b.fill:SetPoint("BOTTOMLEFT")
            b.fill:SetPoint("BOTTOMRIGHT")
            b.label = NUL:CreateLabel(chart, {
                text = "", size = "xs", justifyH = "CENTER", wrap = false,
            })
            -- Tooltip text is refreshed per SetData; the function form reads
            -- the current value so one hook survives every data change.
            NUL:AttachTooltip(b, function(self) return self._tip end)
            chart._bars[i] = b
        end
        return b
    end

    function chart:Refresh()
        local t    = NUL:GetTheme()
        local data = self._data or {}
        local n    = #data
        local w    = self:GetWidth() or 0
        local h    = (self:GetHeight() or 0) - LABEL_H
        if w <= 1 or h <= 1 then return end  -- not laid out yet; OnSizeChanged retries

        local maxV = 0
        for _, d in ipairs(data) do
            local v = d.value or 0
            if v > maxV then maxV = v end
        end

        if n == 0 or maxV <= 0 then
            for _, b in ipairs(self._bars) do b:Hide(); b.label:Hide() end
            self.empty:SetText(self._emptyText)
            self.empty:Show()
            return
        end
        self.empty:Hide()

        local barW = math.max(3, (w - GAP * (n - 1)) / n)
        for i, d in ipairs(data) do
            local b = acquireBar(i)
            local x = (i - 1) * (barW + GAP)
            b:SetSize(barW, h)
            b:ClearAllPoints()
            b:SetPoint("BOTTOMLEFT", self, "BOTTOMLEFT", x, LABEL_H)

            b.fill:SetTexture(t.media.bg)
            NUL.SetTextureColor(b.fill, barColor(d, t))
            b.fill:SetHeight(math.max(1, h * ((d.value or 0) / maxV)))

            b._tip = fmtTip(d)
            b.label:SetText(d.label or "")
            b.label:SetWidth(barW)
            b.label:ClearAllPoints()
            b.label:SetPoint("TOP", b, "BOTTOM", 0, -2)
            NUL.SetFontColor(b.label, t.colors.text.muted)
            b:Show(); b.label:Show()
        end
        for i = n + 1, #self._bars do
            self._bars[i]:Hide()
            self._bars[i].label:Hide()
        end
    end

    function chart:SetData(data)
        self._data = data or {}
        self:Refresh()
    end

    function chart:_repaint(t)
        NUL.SetTextureColor(self.axis, NUL.WithAlpha(t.colors.border.subtle, 0.6))
        NUL.SetFontColor(self.empty, t.colors.text.muted)
        self:Refresh()
    end

    chart:HookScript("OnSizeChanged", function(self) self:Refresh() end)

    self:_Track(chart)
    chart:_repaint(theme)
    return chart
end

-- ─── Horizontal ranked bars ──────────────────────────────────────────────

function NUL:RankedBars(parent, opts)
    opts = opts or {}
    local theme     = self:GetTheme()
    local ROW_H     = opts.rowHeight or 18
    local MAX_ROWS  = opts.maxRows or 8
    local VALUE_W   = 44
    local GAP       = 6

    local chart = CreateFrame("Frame", nil, parent)
    chart._rows      = {}
    chart._data      = {}
    chart._rowHeight = ROW_H
    chart._maxRows   = MAX_ROWS
    chart._emptyText = opts.emptyText or ""

    chart.empty = self:CreateLabel(chart, { text = chart._emptyText, size = "sm", justifyH = "CENTER" })
    chart.empty:SetPoint("CENTER")
    chart.empty:Hide()

    local function acquireRow(i)
        local r = chart._rows[i]
        if not r then
            r = CreateFrame("Frame", nil, chart)
            r:EnableMouse(true)
            r:SetHeight(ROW_H)

            r.track = r:CreateTexture(nil, "BACKGROUND")
            r.fill  = r:CreateTexture(nil, "ARTWORK")

            r.label = NUL:CreateLabel(r, { text = "", size = "sm", justifyH = "LEFT",  wrap = false })
            r.value = NUL:CreateLabel(r, { text = "", size = "sm", justifyH = "RIGHT", wrap = false })

            NUL:AttachTooltip(r, function(self) return self._tip end)
            chart._rows[i] = r
        end
        return r
    end

    function chart:Refresh()
        local t    = NUL:GetTheme()
        local data = self._data or {}
        local n    = math.min(#data, self._maxRows)
        local w    = self:GetWidth() or 0
        if w <= 1 then return end

        if n == 0 then
            for _, r in ipairs(self._rows) do r:Hide() end
            self.empty:SetText(self._emptyText)
            self.empty:Show()
            return
        end
        self.empty:Hide()

        local maxV = 0
        for i = 1, n do
            local v = data[i].value or 0
            if v > maxV then maxV = v end
        end
        if maxV <= 0 then maxV = 1 end

        -- Label column scales with the widget but stays in a sane range.
        local labelW = math.max(60, math.min(150, math.floor(w * 0.38)))
        local barMax = math.max(10, w - labelW - VALUE_W - GAP * 2)

        for i = 1, n do
            local d = data[i]
            local r = acquireRow(i)
            r:ClearAllPoints()
            r:SetPoint("TOPLEFT",  self, "TOPLEFT",  0, -(i - 1) * ROW_H)
            r:SetPoint("TOPRIGHT", self, "TOPRIGHT", 0, -(i - 1) * ROW_H)

            r.label:ClearAllPoints()
            r.label:SetPoint("LEFT", r, "LEFT", 0, 0)
            r.label:SetWidth(labelW)
            r.label:SetText(d.label or "")
            NUL.SetFontColor(r.label, t.colors.text.primary)

            -- Track (full bar area) + proportional fill on top of it.
            r.track:ClearAllPoints()
            r.track:SetPoint("LEFT", r, "LEFT", labelW + GAP, 0)
            r.track:SetHeight(math.max(6, ROW_H - 8))
            r.track:SetWidth(barMax)
            r.track:SetTexture(t.media.bg)
            NUL.SetTextureColor(r.track, NUL.WithAlpha(t.colors.border.subtle, 0.35))

            r.fill:ClearAllPoints()
            r.fill:SetPoint("LEFT", r, "LEFT", labelW + GAP, 0)
            r.fill:SetHeight(math.max(6, ROW_H - 8))
            r.fill:SetWidth(math.max(1, barMax * ((d.value or 0) / maxV)))
            r.fill:SetTexture(t.media.bg)
            NUL.SetTextureColor(r.fill, barColor(d, t))

            r.value:ClearAllPoints()
            r.value:SetPoint("RIGHT", r, "RIGHT", 0, 0)
            r.value:SetWidth(VALUE_W)
            r.value:SetText(tostring(d.value or 0))
            NUL.SetFontColor(r.value, t.colors.text.muted)

            r._tip = fmtTip(d)
            r:Show()
        end
        for i = n + 1, #self._rows do self._rows[i]:Hide() end
    end

    function chart:SetData(data)
        self._data = data or {}
        self:Refresh()
    end

    -- Height this chart wants for its current dataset - let a Card size itself.
    function chart:GetNaturalHeight()
        local n = math.min(#(self._data or {}), self._maxRows)
        return math.max(ROW_H, n * ROW_H)
    end

    function chart:_repaint(t)
        NUL.SetFontColor(self.empty, t.colors.text.muted)
        self:Refresh()
    end

    chart:HookScript("OnSizeChanged", function(self) self:Refresh() end)

    self:_Track(chart)
    chart:_repaint(theme)
    return chart
end
