-- NerzorsUILib-1.0 :: Widgets/EditBox.lua
-- Single-line and multi-line styled EditBox.
--
-- opts:
--   width        number|"fill"   px or container-width
--   height       number          single-line: fixed; multiline: minimum
--   placeholder  string          ghost text shown when empty
--   maxLetters   number          Blizzard cap, default 200 (single) / 50000 (multi)
--   multiline    boolean         ScrollFrame-wrapped multi-line EditBox
--   autoGrow     boolean         multiline only - grows up to maxHeight
--   maxHeight    number          multiline only - default 240
--   numeric      boolean         single-line - SetNumeric(true)
--   readonly     boolean         steals focus on focus-gained (visual stays)
--   onTextChanged function(text, self)
--   onEnterPressed function(self)  single-line only
--
-- Returns: container, eb. The container exposes :SetText / :GetText /
-- :SetFocus / :ClearFocus / :SetEnabled / :SetCursorPosition passthroughs.

local NUL = LibStub("NerzorsUILib-1.0")

local function applyFocusBorder(borders, theme, focused)
    NUL:RecolorBorder(borders,
        focused and theme.colors.border.accent or theme.colors.border.subtle)
end

-- Resolve opts.maxLetters to a value safe for EditBox:SetMaxLetters.
-- Caveat: unlike SetMaxBytes(0) (which means "no limit"), SetMaxLetters(0)
-- actually clamps the box to ZERO letters - SetText then stores nothing.
-- So a caller passing 0 (intending "unlimited") would get a silently
-- empty box. Map 0 / negative to a very large number instead; nil falls
-- back to the per-variant default.
local function resolveMaxLetters(v, default)
    if v == nil then return default end
    if v <= 0 then return 1000000 end
    return v
end

-- ─── Single-line ────────────────────────────────────────────────────────

local function singleLine(parent, opts)
    local theme  = NUL:GetTheme()
    local width  = (type(opts.width) == "number") and opts.width or 200
    local height = opts.height or (theme.metrics.rowHeight - 2)

    local c = CreateFrame("Frame", nil, parent)
    c:SetSize(width, height)
    c.bg      = NUL:FillBackground(c)
    c.borders = NUL:AddBorder(c, nil, theme.metrics.borderThickness)

    local eb = CreateFrame("EditBox", nil, c)
    eb:SetPoint("TOPLEFT", 6, -1)
    eb:SetPoint("BOTTOMRIGHT", -6, 1)
    eb:SetAutoFocus(false)
    eb:SetFont(theme.fonts.regular, theme.fontSizes.md, "")
    NUL.SetFontColor(eb, theme.colors.text.primary)
    eb:SetMaxLetters(resolveMaxLetters(opts.maxLetters, 200))
    if opts.numeric then eb:SetNumeric(true) end
    eb:SetScript("OnEscapePressed", eb.ClearFocus)
    eb:SetScript("OnEnterPressed",  function(self)
        if opts.onEnterPressed then opts.onEnterPressed(self) end
        self:ClearFocus()
    end)
    eb:SetScript("OnEditFocusGained", function(self)
        if opts.readonly then self:ClearFocus(); return end
        applyFocusBorder(c.borders, NUL:GetTheme(), true)
    end)
    eb:SetScript("OnEditFocusLost", function() applyFocusBorder(c.borders, NUL:GetTheme(), false) end)
    if opts.onTextChanged then
        eb:SetScript("OnTextChanged", function(self) opts.onTextChanged(self:GetText() or "", self) end)
    end

    if opts.placeholder then
        local ph = NUL:CreateLabel(eb, {
            text  = opts.placeholder,
            color = theme.colors.text.muted,
        })
        ph:SetPoint("LEFT")
        c.placeholder = ph
        local function refresh() ph:SetShown((eb:GetText() or "") == "") end
        eb:HookScript("OnTextChanged", refresh); refresh()
    end

    function c:_repaint(t)
        NUL.SetTextureColor(self.bg, t.colors.bg.elevated)
        applyFocusBorder(self.borders, t, eb:HasFocus())
        eb:SetFont(t.fonts.regular, t.fontSizes.md, "")
        NUL.SetFontColor(eb, opts.readonly and t.colors.text.muted or t.colors.text.primary)
        if self.placeholder then NUL.SetFontColor(self.placeholder, t.colors.text.muted) end
    end
    c.editBox = eb
    c.SetText      = function(self, v) eb:SetText(v or "") end
    c.GetText      = function(self)    return eb:GetText() or "" end
    c.SetFocus     = function(self)    eb:SetFocus() end
    c.ClearFocus   = function(self)    eb:ClearFocus() end
    c.SetEnabled   = function(self, v) eb:SetEnabled(v) end
    c.SetCursorPosition = function(self, p) eb:SetCursorPosition(p or 0) end

    NUL:_Track(c)
    c:_repaint(theme)
    return c, eb
end

-- ─── Multi-line ─────────────────────────────────────────────────────────

local function multiline(parent, opts)
    local theme  = NUL:GetTheme()
    local width  = (type(opts.width) == "number") and opts.width or 320
    local height = opts.height or 90
    local maxH   = opts.maxHeight or 240

    local c = CreateFrame("Frame", nil, parent)
    c:SetSize(width, height)
    c.bg      = NUL:FillBackground(c)
    c.borders = NUL:AddBorder(c, nil, theme.metrics.borderThickness)

    local scroll = CreateFrame("ScrollFrame", nil, c, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 6, -4)
    scroll:SetPoint("BOTTOMRIGHT", -22, 4)

    local eb = CreateFrame("EditBox", nil, scroll)
    eb:SetMultiLine(true)
    eb:SetAutoFocus(false)
    eb:SetFont(theme.fonts.regular, theme.fontSizes.md, "")
    NUL.SetFontColor(eb, theme.colors.text.primary)
    eb:SetMaxLetters(resolveMaxLetters(opts.maxLetters, 50000))
    eb:SetWidth(width - 28)
    eb:SetHeight(height - 8)
    eb:SetScript("OnEscapePressed", eb.ClearFocus)
    eb:SetScript("OnEditFocusGained", function(self)
        if opts.readonly then self:ClearFocus(); return end
        applyFocusBorder(c.borders, NUL:GetTheme(), true)
    end)
    eb:SetScript("OnEditFocusLost", function() applyFocusBorder(c.borders, NUL:GetTheme(), false) end)
    scroll:SetScrollChild(eb)

    -- Themed scrollbar (same slim accent look as the lists) instead of the
    -- classic Blizzard one. Scroll frame already reserves 22px on the right.
    c._sbar = NUL:_AttachThemedScrollBar(scroll, c, theme.fontSizes.md * 2)

    -- An empty (or short) multi-line EditBox only occupies one text line
    -- of height, so clicks anywhere below that line land on the
    -- ScrollFrame or the container frame instead of the EditBox - and
    -- nothing focuses. Forward those clicks to the EditBox so the whole
    -- visible box is a valid click target. Cursor goes to the end so the
    -- user starts typing where the text is.
    local function focusEditBox()
        if opts.readonly then return end
        eb:SetFocus()
        eb:SetCursorPosition(#(eb:GetText() or ""))
    end
    scroll:EnableMouse(true)
    scroll:SetScript("OnMouseDown", focusEditBox)
    c:EnableMouse(true)
    c:SetScript("OnMouseDown", focusEditBox)

    -- Keep inner-width in sync with the ScrollFrame so word-wrap behaves
    -- correctly when the container resizes.
    scroll:SetScript("OnSizeChanged", function(_, w) eb:SetWidth(w) end)

    -- Auto-scroll to the caret on cursor moves; standard pattern for
    -- multi-line edit boxes inside a scroll frame.
    eb:SetScript("OnCursorChanged", function(self, _, y, _, h)
        local viewTop = scroll:GetVerticalScroll()
        local viewH   = scroll:GetHeight()
        local caretTop, caretBot = -y, -y + h
        if caretTop < viewTop then
            scroll:SetVerticalScroll(caretTop)
        elseif caretBot > viewTop + viewH then
            scroll:SetVerticalScroll(caretBot - viewH)
        end
    end)

    local function resizeForContent()
        if not opts.autoGrow then return end
        local needed = math.min(maxH, math.max(height, eb:GetHeight() + 8))
        if math.abs((c:GetHeight() or 0) - needed) > 0.5 then
            c:SetHeight(needed)
        end
    end
    eb:SetScript("OnTextChanged", function(self)
        if opts.onTextChanged then opts.onTextChanged(self:GetText() or "", self) end
        resizeForContent()
    end)

    if opts.placeholder then
        local ph = NUL:CreateLabel(eb, {
            text     = opts.placeholder,
            color    = theme.colors.text.muted,
            justifyH = "LEFT",
            justifyV = "TOP",
        })
        ph:SetPoint("TOPLEFT", 0, 0)
        ph:SetPoint("RIGHT", 0, 0)
        c.placeholder = ph
        local function refresh() ph:SetShown((eb:GetText() or "") == "") end
        eb:HookScript("OnTextChanged", refresh); refresh()
    end

    function c:_repaint(t)
        NUL.SetTextureColor(self.bg, t.colors.bg.elevated)
        applyFocusBorder(self.borders, t, eb:HasFocus())
        eb:SetFont(t.fonts.regular, t.fontSizes.md, "")
        NUL.SetFontColor(eb, opts.readonly and t.colors.text.muted or t.colors.text.primary)
        if self.placeholder then NUL.SetFontColor(self.placeholder, t.colors.text.muted) end
        if self._sbar then self._sbar.paint(t) end
    end
    c.editBox = eb
    c.scrollFrame = scroll
    c.SetText      = function(self, v) eb:SetText(v or "") end
    c.GetText      = function(self)    return eb:GetText() or "" end
    c.SetFocus     = function(self)    eb:SetFocus() end
    c.ClearFocus   = function(self)    eb:ClearFocus() end
    c.SetEnabled   = function(self, v) eb:SetEnabled(v) end
    c.SetCursorPosition = function(self, p) eb:SetCursorPosition(p or 0) end

    NUL:_Track(c)
    c:_repaint(theme)
    return c, eb
end

function NUL:EditBox(parent, opts)
    opts = opts or {}
    if opts.multiline then return multiline(parent, opts) end
    return singleLine(parent, opts)
end
