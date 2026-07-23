-- NerzorsUILib-1.0 :: Widgets/Dialog.lua
-- Form-style modal dialog: stacks label + edit box for each declared
-- field, plus accept/cancel buttons. Built on Window for skin parity.
--
-- opts:
--   name      string       Global frame name (for UISpecialFrames).
--   title     string
--   width     number       Default 360.
--   fields    array        { { key, label, required, readonly, multiline,
--                              height, placeholder }, ... }
--   onAccept  function(values, dialog) -> ok, errMsg
--   acceptLabel / cancelLabel  Custom button labels.
--   onCancel  function     Optional - called on Cancel/X.

local NUL = LibStub("NerzorsUILib-1.0")

function NUL:Dialog(opts)
    opts = opts or {}
    local theme   = self:GetTheme()
    local width   = opts.width or 360
    local fields  = opts.fields or {}
    local labelH  = 14
    local spacing = 6

    -- Pre-compute total height: title bar + padding + sum of rows +
    -- buttons + padding. Multiline rows are taller.
    local rowsHeight = 0
    for _, field in ipairs(fields) do
        local rowH = field.multiline and (field.height or 90) or (theme.metrics.rowHeight)
        rowsHeight = rowsHeight + labelH + rowH + spacing
    end
    local height = theme.metrics.titleBarHeight
                 + theme.metrics.windowPadding * 2
                 + rowsHeight + 36

    local f = NUL:Window({
        name   = opts.name,
        title  = opts.title or "",
        width  = width,
        height = height,
        strata = "DIALOG",
    })
    f:SetFrameLevel(200)

    local inputs = {}
    local y = 0
    local innerWidth = width - theme.metrics.windowPadding * 2 - 2

    for _, field in ipairs(fields) do
        local lab = NUL:CreateLabel(f.content, {
            text  = field.label or field.key,
            color = theme.colors.text.muted,
        })
        lab:SetPoint("TOPLEFT", 0, y)

        local rowH = field.multiline and (field.height or 90) or (theme.metrics.rowHeight)
        local box = NUL:EditBox(f.content, {
            width       = innerWidth,
            height      = rowH,
            placeholder = field.placeholder,
            multiline   = field.multiline or false,
            readonly    = field.readonly or false,
        })
        box:SetPoint("TOPLEFT", 0, y - labelH)
        inputs[field.key] = box
        y = y - (rowH + spacing + labelH)
    end

    local cancel = NUL:Button(f.content, {
        label = opts.cancelLabel or (CANCEL or "Cancel"),
        width = 80, height = 24,
        onClick = function()
            f:Hide()
            if opts.onCancel then opts.onCancel(f) end
        end,
    })
    cancel:SetPoint("BOTTOMRIGHT", 0, 0)

    local accept = NUL:Button(f.content, {
        label = opts.acceptLabel or (OKAY or "OK"),
        width = 80, height = 24, style = "accent",
    })
    accept:SetPoint("BOTTOMRIGHT", cancel, "BOTTOMLEFT", -6, 0)

    f.inputs       = inputs
    f.acceptButton = accept
    f.cancelButton = cancel

    function f:SetValues(values)
        for key, input in pairs(self.inputs) do
            input:SetText(values and values[key] or "")
            if input.SetCursorPosition then input:SetCursorPosition(0) end
        end
    end

    function f:GetValues()
        local v = {}
        for key, input in pairs(self.inputs) do v[key] = input:GetText() end
        return v
    end

    function f:SetOnAccept(callback)
        accept:SetScript("OnClick", function()
            local values = self:GetValues()
            local ok, err = callback(values, self)
            if ok ~= false then self:Hide() end
            if err then print("|cffff5555" .. tostring(err) .. "|r") end
        end)
    end

    if opts.onAccept then f:SetOnAccept(opts.onAccept) end
    return f
end
