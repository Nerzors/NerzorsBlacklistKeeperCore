-- NerzorsUILib-1.0 :: Widgets/CopyBox.lua
-- A small window with one line of text, already selected, so the player can
-- copy it with Ctrl+C. Addons can't write to the clipboard themselves; this
-- is the usual way round it. Esc or Enter closes it. One shared window.
--
--   NUL:ShowCopyBox({ title = "...", text = "...", hint = "..." })
--     title  window title (the host's wording)
--     text   what to copy
--     hint   small line under the field, e.g. "Press Ctrl+C to copy."
--   NUL:HideCopyBox()

local NUL = LibStub("NerzorsUILib-1.0")

local box   -- the shared window, built on first use

local function build()
    if box then return box end
    local theme = NUL:GetTheme()
    local f = NUL:Window({
        name   = "NerzorsUILibCopyBox",
        title  = "",
        width  = 360, height = 120,
        strata = "FULLSCREEN_DIALOG",
    })
    f:SetFrameLevel(220)
    box = f

    f.field = NUL:EditBox(f.content, { width = 320, height = 26 })
    f.field:SetPoint("TOPLEFT", 0, -2)
    f.field:SetPoint("RIGHT", f.content, "RIGHT", 0, 0)
    local eb = f.field.editBox
    -- Esc and Enter close; the text stays as given even if a key slips in.
    eb:SetScript("OnEscapePressed", function() f:Hide() end)
    eb:SetScript("OnEnterPressed",  function() f:Hide() end)
    eb:HookScript("OnTextChanged", function(self, user)
        if user and f._text and self:GetText() ~= f._text then
            self:SetText(f._text)
            self:HighlightText()
        end
    end)

    f.hint = NUL:CreateLabel(f.content, {
        text = "", size = "sm", color = theme.colors.text.muted, justifyH = "LEFT",
    })
    f.hint:SetPoint("TOPLEFT", f.field, "BOTTOMLEFT", 2, -6)
    f.hint:SetPoint("RIGHT", f.content, "RIGHT", 0, 0)
    return f
end

function NUL:ShowCopyBox(opts)
    opts = opts or {}
    local f = build()
    f._text = opts.text or ""
    f:SetTitle(opts.title or "")
    f.hint:SetText(opts.hint or "")
    f.field:SetText(f._text)
    f:Show()
    f:Raise()
    local eb = f.field.editBox
    eb:SetFocus()
    eb:HighlightText()
    return f
end

function NUL:HideCopyBox()
    if box then box:Hide() end
end
