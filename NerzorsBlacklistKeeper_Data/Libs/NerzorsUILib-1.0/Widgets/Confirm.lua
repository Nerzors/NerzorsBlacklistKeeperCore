-- NerzorsUILib-1.0 :: Widgets/Confirm.lua
-- Yes/No question in the library's own window (minor 9, NBK 2.4.0 D1).
-- Until minor 8 this was a Blizzard StaticPopup; as a NUL:Window it takes
-- the theme and follows NUL:SetScale like every other window. The options
-- did not change, so callers keep working as they are.
--
-- opts:
--   id        string    One window per id. Asking again with the same id
--                       replaces the open question (as StaticPopups did);
--                       a different id opens its own window, shifted a
--                       little so both stay visible. Default "NUL_CONFIRM".
--   text      string    Prompt text. Required. Wraps; the window grows.
--   title     string    Optional title bar text (default: SetConfirmDefaults).
--   onAccept  function  Yes / Enter.
--   onCancel  function  Optional - No, Esc and the window's X.
--   acceptLabel / cancelLabel  Override button labels.
--   extraLabel / onExtra       Optional third button (minor 8), e.g.
--                       "Show entries" next to Yes / No. Only shown when
--                       both are given. Closes the question, no onCancel.
--
-- NUL:SetConfirmDefaults({ title = fn, accept = fn, cancel = fn }) - the
-- addon's own words for title and buttons, read on every question (so a
-- language switch applies). Without it: no title, the game's YES / NO.

local NUL = LibStub("NerzorsUILib-1.0")

local WIDTH, BTN_H, GAP, SHIFT = 380, 24, 14, 24

NUL._confirms = NUL._confirms or {}   -- id -> window

function NUL:SetConfirmDefaults(d)
    self._confirmDefaults = type(d) == "table" and d or nil
end

local function default(key, fallback)
    local d = NUL._confirmDefaults
    local f = d and d[key]
    local v = type(f) == "function" and f() or f
    if type(v) == "string" and v ~= "" then return v end
    return fallback
end

-- Number of other questions open right now (for the shift).
local function openOthers(except)
    local n = 0
    for _, w in pairs(NUL._confirms) do
        if w ~= except and w:IsShown() then n = n + 1 end
    end
    return n
end

local function build(id)
    local theme = NUL:GetTheme()
    local name = "NULConfirm_" .. tostring(id):gsub("[^%w_]", "_")
    local f = NUL:Window({ name = name, title = "", width = WIDTH, height = 140,
                           strata = "FULLSCREEN_DIALOG" })
    f:SetToplevel(true)

    f.text = NUL:CreateLabel(f.content, { text = "", justifyH = "LEFT" })
    f.text:SetPoint("TOPLEFT", 0, 0)
    f.text:SetPoint("TOPRIGHT", 0, 0)
    if f.text.SetWordWrap then f.text:SetWordWrap(true) end

    -- Answer once: the button, then hide. A hide without an answer (Esc,
    -- X, a newer question with the same id) counts as No.
    local function answer(kind)
        local o = f._opts
        f._answered = true
        f:Hide()
        local fn = o and ((kind == "accept" and o.onAccept) or (kind == "cancel" and o.onCancel)
                          or (kind == "extra" and o.onExtra))
        if fn then fn() end
    end
    f._answer = answer

    f.accept = NUL:Button(f.content, { label = "", height = BTN_H, style = "primary",
                                       onClick = function() answer("accept") end })
    f.cancel = NUL:Button(f.content, { label = "", height = BTN_H, style = "secondary",
                                       onClick = function() answer("cancel") end })
    f.extra  = NUL:Button(f.content, { label = "", height = BTN_H, style = "secondary",
                                       onClick = function() answer("extra") end })
    f.cancel:SetPoint("BOTTOMRIGHT", 0, 0)
    f.accept:SetPoint("BOTTOMRIGHT", f.cancel, "BOTTOMLEFT", -6, 0)
    f.extra:SetPoint("BOTTOMLEFT", 0, 0)

    f:HookScript("OnHide", function(self)
        if self._answered then return end
        self._answered = true
        local o = self._opts
        if o and o.onCancel then o.onCancel() end
    end)

    -- Enter = Yes. Only taken when the window opens out of combat: then
    -- every key is passed on to the game first (movement, chat ...) and
    -- only Enter is kept. In combat the game restricts that switch, so
    -- there the window takes no keys at all - Esc and the buttons work.
    f:SetScript("OnKeyDown", function(self, key)
        if key ~= "ENTER" then return end
        if self.SetPropagateKeyboardInput then pcall(self.SetPropagateKeyboardInput, self, false) end
        answer("accept")
    end)
    f:HookScript("OnShow", function(self)
        local free = not (InCombatLockdown and InCombatLockdown())
        local ok = free and self.SetPropagateKeyboardInput
                   and pcall(self.SetPropagateKeyboardInput, self, true)
        if self.EnableKeyboard then pcall(self.EnableKeyboard, self, ok and true or false) end
    end)

    f._theme = theme
    return f
end

function NUL:Confirm(opts)
    opts = opts or {}
    local id = opts.id or "NUL_CONFIRM"
    local f = self._confirms[id]
    if not f then
        f = build(id)
        self._confirms[id] = f
    elseif f:IsShown() then
        -- the older question with this id is replaced: it counts as No
        f:Hide()
    end
    f._opts, f._answered = opts, false

    local theme = self:GetTheme()
    f:SetTitle(opts.title or default("title", ""))
    f.accept:SetLabel(opts.acceptLabel or default("accept", YES or "Yes"))
    f.cancel:SetLabel(opts.cancelLabel or default("cancel", NO or "No"))
    f.accept:AutoSize(80)
    f.cancel:AutoSize(80)
    local extra = opts.extraLabel and opts.onExtra
    if extra then
        f.extra:SetLabel(opts.extraLabel)
        f.extra:AutoSize(80)
        f.extra:Show()
    else
        f.extra:Hide()
    end

    -- Height from the wrapped text; wider when the buttons need it.
    local pad = theme.metrics.windowPadding
    local btnW = f.accept:GetWidth() + 6 + f.cancel:GetWidth() + (extra and (f.extra:GetWidth() + 12) or 0)
    local width = math.max(WIDTH, math.ceil(btnW) + pad * 2 + 2)
    f:SetWidth(width)
    f.text:SetWidth(width - pad * 2 - 2)
    f.text:SetText(opts.text or "")
    local textH = math.ceil(tonumber(f.text:GetStringHeight()) or 14)
    f:SetHeight(theme.metrics.titleBarHeight + pad * 2 + textH + GAP + BTN_H + 2)

    -- Centred; shifted down-right per other open question.
    local n = openOthers(f)
    f:ClearAllPoints()
    f:SetPoint("CENTER", UIParent, "CENTER", n * SHIFT, 80 - n * SHIFT)
    f:Show()
    f:Raise()
    return f
end
