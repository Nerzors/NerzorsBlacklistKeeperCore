-- NerzorsUILib-1.0 :: Core/Layout.lua
-- Container helpers that replace the "y = y - 26" pixel-pushing pattern.
--
--   local stack = NUL:Stack(parent, { orientation = "vertical", gap = 6,
--                                     padding = 8 })
--   stack:Add(widget, { fill = true })           -- fills container width
--   stack:Add(widget, { width = 120 })           -- fixed
--   stack:Add({ height = 12 })                   -- spacer
--   stack:Layout()                               -- recompute (auto on resize)
--
-- Resize-aware: the stack listens to its frame's OnSizeChanged and
-- re-runs Layout, so child widgets with `fill = true` always span the
-- container width regardless of dynamic window resize.
--
-- For grids:
--   local grid = NUL:Grid(parent, { cols = 2, rowGap = 4, colGap = 8 })
--   grid:Add(widget)  grid:Add(widget)  grid:Add(widget)
--   grid:Layout()
-- Children flow row-major; column widths divide the container evenly.

local NUL = LibStub("NerzorsUILib-1.0")

-- ─── Stack ──────────────────────────────────────────────────────────────

local Stack = {}
Stack.__index = Stack

function Stack:Add(widgetOrSpec, opts)
    -- Spacer form: Add({ height = 12 }) or Add({ width = 20 }).
    if type(widgetOrSpec) == "table" and widgetOrSpec.GetObjectType == nil then
        table.insert(self._items, {
            spacer = true,
            width  = widgetOrSpec.width,
            height = widgetOrSpec.height,
        })
        return
    end
    table.insert(self._items, { widget = widgetOrSpec, opts = opts or {} })
end

function Stack:Clear()
    -- Children stay parented; caller is responsible for hiding/destroying.
    self._items = {}
end

function Stack:Layout()
    local frame = self._frame
    local pad   = self._padding
    local gap   = self._gap
    local horiz = (self._orientation == "horizontal")
    local cw    = frame:GetWidth()  - pad * 2
    local ch    = frame:GetHeight() - pad * 2
    if cw <= 0 or ch <= 0 then return end -- not yet sized

    local cursor = pad
    for _, item in ipairs(self._items) do
        if item.spacer then
            cursor = cursor + (horiz and (item.width or gap) or (item.height or gap))
        else
            local w, opts = item.widget, item.opts
            w:ClearAllPoints()
            if horiz then
                w:SetPoint("LEFT", frame, "LEFT", cursor, 0)
                if opts.fill then w:SetHeight(ch) end
                if opts.width then w:SetWidth(opts.width) end
                cursor = cursor + w:GetWidth() + gap
            else
                w:SetPoint("TOPLEFT",  frame, "TOPLEFT",  pad, -cursor)
                if opts.fill then
                    w:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -pad, -cursor)
                end
                if opts.height then w:SetHeight(opts.height) end
                cursor = cursor + w:GetHeight() + gap
            end
        end
    end
    self._naturalSize = cursor + pad - gap -- last gap was extra
end

-- Returns the cumulative pixel length the stack occupied in its main
-- axis after the last Layout pass. Useful for "auto-size the parent".
function Stack:GetNaturalSize()
    return self._naturalSize or 0
end

-- opts: { orientation = "vertical"|"horizontal", gap, padding }
function NUL:Stack(parent, opts)
    opts = opts or {}
    local s = setmetatable({}, Stack)
    s._frame       = parent
    s._items       = {}
    s._orientation = opts.orientation or "vertical"
    s._gap         = opts.gap or 6
    s._padding     = opts.padding or 0
    s._naturalSize = 0
    parent:HookScript("OnSizeChanged", function() s:Layout() end)
    return s
end

-- ─── Grid ───────────────────────────────────────────────────────────────

local Grid = {}
Grid.__index = Grid

function Grid:Add(widget)
    table.insert(self._items, widget)
end

function Grid:Clear() self._items = {} end

function Grid:Layout()
    local frame  = self._frame
    local cols   = self._cols
    local pad    = self._padding
    local rowGap = self._rowGap
    local colGap = self._colGap
    local cw     = frame:GetWidth() - pad * 2
    if cw <= 0 then return end

    local cellW = math.floor((cw - colGap * (cols - 1)) / cols)
    local row, col, rowH = 0, 0, 0
    local y = pad
    for _, w in ipairs(self._items) do
        w:ClearAllPoints()
        local x = pad + col * (cellW + colGap)
        w:SetPoint("TOPLEFT", frame, "TOPLEFT", x, -y)
        if self._fillCellWidth ~= false then w:SetWidth(cellW) end
        rowH = math.max(rowH, w:GetHeight())
        col = col + 1
        if col >= cols then
            col = 0; row = row + 1
            y = y + rowH + rowGap
            rowH = 0
        end
    end
    self._naturalSize = y + rowH + pad
end

function Grid:GetNaturalSize() return self._naturalSize or 0 end

-- opts: { cols, rowGap, colGap, padding, fillCellWidth }
function NUL:Grid(parent, opts)
    opts = opts or {}
    local g = setmetatable({}, Grid)
    g._frame          = parent
    g._items          = {}
    g._cols           = math.max(1, opts.cols or 2)
    g._rowGap         = opts.rowGap or 4
    g._colGap         = opts.colGap or 8
    g._padding        = opts.padding or 0
    g._fillCellWidth  = opts.fillCellWidth
    g._naturalSize    = 0
    parent:HookScript("OnSizeChanged", function() g:Layout() end)
    return g
end
