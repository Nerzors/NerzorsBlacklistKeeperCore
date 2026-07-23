-- NerzorsUILib-1.0 :: Widgets/Tooltip.lua
-- One shared, themed tooltip for the whole UI - matches the addon skin
-- (themed bg + accent border + top stripe + Nerzors font) instead of the
-- default Blizzard GameTooltip.
--
-- Two flavours, backed by the SAME singleton frame (a title + a body
-- FontString that get shown/hidden per call):
--
--   Single-line  NUL:ShowTooltip(owner, text, opts)
--       One compact line; wraps only if it would exceed opts.maxWidth
--       (default 320). Used for button hints ("Edit", "Remove", …).
--
--   Multi-line   NUL:ShowTooltipMultiline(owner, opts)
--       opts.title (accent header) + opts.body (wrapped at opts.maxWidth,
--       default 300). Used for the blacklist note popup, where the body is
--       free text that can run several lines.
--
--   NUL:HideTooltip()
--   NUL:AttachTooltip(frame, textOrFn, opts)   -- single-line convenience;
--       hooks OnEnter/OnLeave. textOrFn is a string or function(frame)->string
--       so state-dependent hints (a toggle's on/off text) recompute per hover.

local NUL = LibStub("NerzorsUILib-1.0")

local PAD_X     = 9
local PAD_TOP   = 8   -- leaves room for the accent stripe
local PAD_BOT   = 6
local TITLE_GAP = 3   -- between title and body in multi-line mode

local tip  -- singleton, built on first use

local function ensureTip()
    if tip then return tip end
    local theme = NUL:GetTheme()

    local f = CreateFrame("Frame", "NerzorsUILibTooltip", UIParent)
    f:SetFrameStrata("TOOLTIP")
    f:SetFrameLevel(1000)
    f:SetClampedToScreen(true)
    f:Hide()

    f.bg      = NUL:FillBackground(f, theme.colors.bg.base)
    f.borders = NUL:AddBorder(f, nil, theme.metrics.borderThickness)

    -- Signature accent stripe along the top edge (same cue the windows use).
    f.stripe = f:CreateTexture(nil, "OVERLAY")
    f.stripe:SetHeight(2)
    f.stripe:SetPoint("TOPLEFT", 1, -1)
    f.stripe:SetPoint("TOPRIGHT", -1, -1)

    f.title = NUL:CreateLabel(f, { text = "", justifyH = "LEFT" })
    f.body  = NUL:CreateLabel(f, { text = "", justifyH = "LEFT" })

    function f:_repaint(t)
        NUL.SetTextureColor(self.bg, t.colors.bg.base)
        NUL:RecolorBorder(self.borders, t.colors.border.accent)
        NUL.SetTextureColor(self.stripe, t.colors.accent.primary)
        NUL.SetFontColor(self.title, t.colors.accent.primary)
        NUL.SetFontColor(self.body,  t.colors.text.primary)
    end
    NUL:_Track(f)
    f:_repaint(theme)

    tip = f
    return f
end

-- Natural single-line width of `text` on `fs` (measured at a large scratch
-- width with wrapping off, so the frame's prior width doesn't skew it).
local function naturalWidth(fs, text)
    fs:SetWordWrap(false)
    fs:SetWidth(4000)
    fs:SetText(text or "")
    return fs:GetStringWidth() or 0
end

local function anchorTo(f, owner, anchor)
    f:ClearAllPoints()
    if anchor == "BOTTOM" then
        f:SetPoint("TOP", owner, "BOTTOM", 0, -6)
    elseif anchor == "LEFT" then
        f:SetPoint("RIGHT", owner, "LEFT", -6, 0)
    elseif anchor == "RIGHT" then
        f:SetPoint("LEFT", owner, "RIGHT", 6, 0)
    else -- TOP (default)
        f:SetPoint("BOTTOM", owner, "TOP", 0, 6)
    end
end

-- ─── Single-line ─────────────────────────────────────────────────────────
function NUL:ShowTooltip(owner, text, opts)
    if not owner or not text or text == "" then return end
    opts = opts or {}
    local maxW = opts.maxWidth or 320
    local f = ensureTip()
    f.title:Hide()

    local nat = naturalWidth(f.body, text)
    f.body:ClearAllPoints()
    f.body:SetPoint("TOPLEFT", PAD_X, -PAD_TOP)

    local w
    if nat > maxW then
        f.body:SetWordWrap(true)
        f.body:SetWidth(maxW)
        w = maxW
    else
        f.body:SetWordWrap(false)
        w = math.max(1, math.ceil(nat))
        f.body:SetWidth(w)
    end
    f.body:SetText(text)
    f.body:Show()
    local h = math.max(12, math.ceil(f.body:GetStringHeight() or 12))

    f:SetSize(w + PAD_X * 2, h + PAD_TOP + PAD_BOT)
    anchorTo(f, owner, opts.anchor or "TOP")
    f:Show()
    f:Raise()
end

-- ─── Multi-line (accent title + wrapped body) ────────────────────────────
function NUL:ShowTooltipMultiline(owner, opts)
    if not owner then return end
    opts = opts or {}
    local title, body = opts.title, opts.body
    if (not title or title == "") and (not body or body == "") then return end
    local maxW = opts.maxWidth or 300
    local f = ensureTip()

    -- Content width = widest of the two natural widths, capped at maxW.
    local tNat = (title and title ~= "") and naturalWidth(f.title, title) or 0
    local bNat = (body  and body  ~= "") and naturalWidth(f.body,  body)  or 0
    local contentW = math.min(maxW, math.max(1, math.ceil(math.max(tNat, bNat))))

    local y = -PAD_TOP
    local totalH = 0

    if title and title ~= "" then
        f.title:ClearAllPoints()
        f.title:SetPoint("TOPLEFT", PAD_X, y)
        f.title:SetWordWrap(false)
        f.title:SetWidth(contentW)
        f.title:SetText(title)
        f.title:Show()
        local th = math.ceil(f.title:GetStringHeight() or 12)
        y = y - th - TITLE_GAP
        totalH = totalH + th + TITLE_GAP
    else
        f.title:Hide()
    end

    if body and body ~= "" then
        f.body:ClearAllPoints()
        f.body:SetPoint("TOPLEFT", PAD_X, y)
        f.body:SetWordWrap(true)
        f.body:SetWidth(contentW)
        f.body:SetText(body)
        f.body:Show()
        totalH = totalH + math.ceil(f.body:GetStringHeight() or 12)
    else
        f.body:Hide()
    end

    f:SetSize(contentW + PAD_X * 2, math.max(12, totalH) + PAD_TOP + PAD_BOT)
    anchorTo(f, owner, opts.anchor or "TOP")
    f:Show()
    f:Raise()
end

function NUL:HideTooltip()
    if tip then tip:Hide() end
end

function NUL:AttachTooltip(frame, textOrFn, opts)
    if not frame then return end
    frame:HookScript("OnEnter", function(self)
        local txt = (type(textOrFn) == "function") and textOrFn(self) or textOrFn
        if txt and txt ~= "" then NUL:ShowTooltip(self, txt, opts) end
    end)
    frame:HookScript("OnLeave", function() NUL:HideTooltip() end)
end
