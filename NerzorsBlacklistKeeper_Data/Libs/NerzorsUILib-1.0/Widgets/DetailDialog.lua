-- NerzorsUILib-1.0 :: Widgets/DetailDialog.lua
--
-- A small "card" popup for "here's an entity, do you want to act on it?"
-- prompts. Pattern is a coloured accent stripe down the left edge, a bold
-- headline at the top, a stack of label/value rows beneath it, and an
-- Accept/Cancel button pair at the bottom.
--
-- Use cases in the Nerzors-family addons:
--   - Sync auto-push popup ("X wants to share an entry with you")
--   - RememberMe end-of-run prompts
--   - Any "review one item" interaction that's too heavy for a Confirm()
--     and too light to deserve a full Window.
--
-- API:
--   local dlg = NUL:DetailDialog({
--       name         = "MyDialog",          -- global frame name (optional)
--       title        = "Auto-Sync push",    -- title bar text
--       width        = 460,                 -- default 440
--       height       = 240,                 -- default = auto from rows
--       strata       = "DIALOG",
--       accent       = "primary",           -- "primary" | "secondary" |
--                                           -- "danger" | "warning" | "success"
--                                           -- or a {r,g,b,a} color
--       acceptLabel  = "Add",
--       cancelLabel  = "Decline",
--       onAccept     = function(self) ... end,
--       onCancel     = function(self) ... end,   -- optional
--   })
--
--   dlg:SetHeadline("Player-Realm")          -- bold top line, supports |c…|r
--   dlg:SetDetails({
--       { label = "From",   value = "SenderName" },
--       { label = "Reason", value = "ninja-pulled in DBR" },
--       { label = "Note",   value = "" },     -- empty rows are skipped
--   })
--   dlg:SetAccentStyle("danger")             -- restyle stripe on the fly
--   dlg:Show()
--
-- Notes:
--   * The dialog grows vertically to fit detail rows. Wrapping value labels
--     are accounted for (each row measures its own height after layout).
--   * Calling SetDetails again rebuilds the row stack; previous frames are
--     hidden + reused where possible.
--   * Inherits theming from NUL:Window - re-themes automatically on
--     SetTheme, so no extra wiring is needed in callers.

local NUL = LibStub("NerzorsUILib-1.0")

-- Resolve the accent stripe color from either a token string or a raw
-- color table. Returns a {r,g,b,a} table.
local function resolveAccent(theme, accent)
    if type(accent) == "table" then return accent end
    local c = theme.colors
    if accent == "secondary" then return c.accent.secondary end
    if accent == "danger"    then return c.state.danger    end
    if accent == "warning"   then return c.state.warning   end
    if accent == "success"   then return c.state.success   end
    if accent == "info"      then return c.state.info      end
    return c.accent.primary  -- "primary" / default
end

local STRIPE_W   = 4
local HEADLINE_H = 22
local ROW_GAP    = 4
local BTN_GAP    = 14
local BTN_H      = 26
local PAD_LEFT   = STRIPE_W + 10   -- past the accent stripe
local PAD_RIGHT  = 12

function NUL:DetailDialog(opts)
    opts = opts or {}
    local theme  = self:GetTheme()
    local width  = opts.width  or 440

    -- Build on top of NUL:Window so we get drag, close, theming for free.
    local f = self:Window({
        name   = opts.name,
        title  = opts.title or "",
        width  = width,
        height = opts.height or 200,
        strata = opts.strata or "DIALOG",
        onClose = opts.onCancel,
    })

    f._accent      = opts.accent or "primary"
    f._opts        = opts
    f._detailRows  = {}

    -- ─── Accent stripe ──────────────────────────────────────────────────
    -- Vertical bar that hugs the left edge of the content area. Acts as
    -- a visual category cue ("primary push" vs "danger remove" etc.) and
    -- gives the dialog its distinctive card feel.
    local stripe = f.content:CreateTexture(nil, "ARTWORK")
    stripe:SetPoint("TOPLEFT")
    stripe:SetPoint("BOTTOMLEFT")
    stripe:SetWidth(STRIPE_W)
    NUL.SetTextureColor(stripe, resolveAccent(theme, f._accent))
    f._stripe = stripe

    -- ─── Headline ───────────────────────────────────────────────────────
    local headline = NUL:CreateLabel(f.content, {
        text     = "",
        size     = "lg",
        justifyH = "LEFT",
        wrap     = false,
    })
    headline:SetPoint("TOPLEFT",  PAD_LEFT, 0)
    headline:SetPoint("TOPRIGHT", -PAD_RIGHT, 0)
    headline:SetHeight(HEADLINE_H)
    f._headline = headline

    -- ─── Row container ──────────────────────────────────────────────────
    -- All label/value rows live in here. Pinned below the headline, above
    -- the button row. Its height is the leftover, but rows are anchored
    -- relative to it from the top.
    local rowHost = CreateFrame("Frame", nil, f.content)
    rowHost:SetPoint("TOPLEFT",  PAD_LEFT,  -(HEADLINE_H + 6))
    rowHost:SetPoint("TOPRIGHT", -PAD_RIGHT, -(HEADLINE_H + 6))
    rowHost:SetPoint("BOTTOM",    0, BTN_H + BTN_GAP)
    f._rowHost = rowHost

    -- ─── Buttons ────────────────────────────────────────────────────────
    local accept = NUL:Button(f.content, {
        label = opts.acceptLabel or (ACCEPT or "Accept"),
        width = 140, height = BTN_H, style = "accent",
        onClick = function()
            if opts.onAccept then opts.onAccept(f) end
            f:Hide()
        end,
    })
    accept:SetPoint("BOTTOMLEFT", PAD_LEFT, 0)
    f._acceptBtn = accept

    local cancel = NUL:Button(f.content, {
        label = opts.cancelLabel or (CANCEL or "Cancel"),
        width = 120, height = BTN_H,
        onClick = function()
            if opts.onCancel then opts.onCancel(f) end
            f:Hide()
        end,
    })
    cancel:SetPoint("BOTTOMRIGHT", -PAD_RIGHT, 0)
    f._cancelBtn = cancel

    -- ─── Public API on the dialog itself ────────────────────────────────

    function f:SetHeadline(text)
        self._headline:SetText(text or "")
    end

    function f:SetAcceptLabel(text)
        if self._acceptBtn and self._acceptBtn.SetLabel then
            self._acceptBtn:SetLabel(text or "")
        end
    end

    function f:SetCancelLabel(text)
        if self._cancelBtn and self._cancelBtn.SetLabel then
            self._cancelBtn:SetLabel(text or "")
        end
    end

    function f:SetAccentStyle(style)
        self._accent = style
        NUL.SetTextureColor(self._stripe, resolveAccent(NUL:GetTheme(), style))
    end

    -- Hand back the inner frame for callers that want to drop extra widgets
    -- below the auto-built rows. Anchors are theirs to manage.
    function f:GetRowHost() return self._rowHost end

    -- Rebuild the label/value stack. Empty / nil-value rows are skipped so
    -- callers can pass a fixed schema and omit fields conditionally.
    function f:SetDetails(rows)
        local theme2 = NUL:GetTheme()

        -- Hide everything we built last time, then re-show only what we
        -- need for this call. Cheaper than recreating frames every push.
        for _, r in ipairs(self._detailRows) do
            r.frame:Hide()
            r.labelFS:SetText("")
            r.valueFS:SetText("")
        end

        local visible = {}
        for _, row in ipairs(rows or {}) do
            local value = row.value
            if value ~= nil and value ~= "" then
                table.insert(visible, row)
            end
        end

        local host       = self._rowHost
        local labelWidth = 70   -- right-aligned column for labels

        for i, row in ipairs(visible) do
            local rec = self._detailRows[i]
            if not rec then
                local container = CreateFrame("Frame", nil, host)
                container:SetPoint("LEFT")
                container:SetPoint("RIGHT")

                local labelFS = NUL:CreateLabel(container, {
                    size = "sm", justifyH = "RIGHT", wrap = false,
                })
                labelFS:SetPoint("TOPLEFT")
                labelFS:SetWidth(labelWidth)

                local valueFS = NUL:CreateLabel(container, {
                    size = "sm", justifyH = "LEFT", wrap = true,
                })
                valueFS:SetPoint("TOPLEFT",  labelWidth + 8, 0)
                valueFS:SetPoint("TOPRIGHT", 0, 0)

                rec = { frame = container, labelFS = labelFS, valueFS = valueFS }
                self._detailRows[i] = rec
            end
            rec.frame:Show()
            rec.frame:ClearAllPoints()
            rec.frame:SetPoint("LEFT")
            rec.frame:SetPoint("RIGHT")
            rec.labelFS:SetText((row.label or "") .. ":")
            rec.valueFS:SetText(tostring(row.value))
            NUL.SetFontColor(rec.labelFS, theme2.colors.text.muted)
            NUL.SetFontColor(rec.valueFS, theme2.colors.text.primary)
        end

        -- Two-pass layout: stack visible rows top-to-bottom, then measure
        -- their actual on-screen height (wrapping value labels can be 2+
        -- lines tall) so the next row sits directly below.
        host:SetWidth(width - PAD_LEFT - PAD_RIGHT)
        local y = 0
        for i = 1, #visible do
            local rec = self._detailRows[i]
            rec.frame:ClearAllPoints()
            rec.frame:SetPoint("TOPLEFT",  host, "TOPLEFT",  0, y)
            rec.frame:SetPoint("TOPRIGHT", host, "TOPRIGHT", 0, y)
            -- A row's height = max(label, value). Label is single-line
            -- (sm font), value may wrap. Add 2px padding for descenders.
            local lh = rec.labelFS:GetStringHeight() or 14
            local vh = rec.valueFS:GetStringHeight() or 14
            local rowH = math.max(lh, vh) + 2
            rec.frame:SetHeight(rowH)
            y = y - (rowH + ROW_GAP)
        end

        -- Auto-grow the window so all rows are visible without manual
        -- height tuning at the call site. Respect explicit opts.height if
        -- the caller set one (treat it as the floor).
        local rowsHeight = math.max(0, -y - ROW_GAP)
        local needed = (NUL:GetTheme().metrics.titleBarHeight or 28)
                      + (NUL:GetTheme().metrics.windowPadding or 12) * 2
                      + HEADLINE_H + 6
                      + rowsHeight
                      + BTN_H + BTN_GAP
        local minH = opts.height or 0
        if needed < minH then needed = minH end
        if needed ~= self:GetHeight() then self:SetHeight(needed) end
    end

    -- Re-color the stripe when the host swaps themes. NUL:Window already
    -- repaints itself; we just need to keep our accent in sync.
    local prevRepaint = f._repaint
    function f:_repaint(t)
        prevRepaint(self, t)
        if self._stripe then
            NUL.SetTextureColor(self._stripe, resolveAccent(t, self._accent))
        end
    end

    return f
end
