-- NerzorsUILib-1.0 :: Widgets/Card.lua
-- Dashboard building blocks: a titled panel (Card) and a big-number tile
-- (StatTile). Used by the Statistics tab, but generic enough for any
-- "sections of content" layout.
--
-- NUL:Card(parent, opts)
--   opts.title   string   Accent-coloured header at the top of the panel.
--   opts.height  number   Fixed height (default 120). Width is set by caller.
--   Returns the card frame. Put your content into `card.content` - it's the
--   inner region below the title, already inset by the card padding.
--   card:SetTitle(text)
--
-- NUL:StatTile(parent, opts)
--   opts.value   string|number  The headline number.
--   opts.label   string         Caption under the value.
--   opts.sub     string         Optional third, dimmer line.
--   tile:SetValue(v) / :SetLabel(t) / :SetSub(t)

local NUL = LibStub("NerzorsUILib-1.0")

local CARD_PAD = 10
local TITLE_H  = 20

function NUL:Card(parent, opts)
    opts = opts or {}
    local theme = self:GetTheme()

    local card = CreateFrame("Frame", nil, parent)
    card:SetHeight(opts.height or 120)
    card.bg      = self:FillBackground(card, theme.colors.bg.panel)
    card.borders = self:AddBorder(card, nil, theme.metrics.borderThickness)

    card.title = self:CreateLabel(card, {
        text = opts.title or "", size = "lg", justifyH = "LEFT", wrap = false,
    })
    card.title:SetPoint("TOPLEFT",  CARD_PAD, -CARD_PAD)
    card.title:SetPoint("TOPRIGHT", -CARD_PAD, -CARD_PAD)

    -- Inner region for the caller's content (chart, tiles, …).
    card.content = CreateFrame("Frame", nil, card)
    card.content:SetPoint("TOPLEFT",     CARD_PAD,  -(CARD_PAD + TITLE_H))
    card.content:SetPoint("BOTTOMRIGHT", -CARD_PAD, CARD_PAD)

    function card:SetTitle(text) self.title:SetText(text or "") end

    function card:_repaint(t)
        NUL.SetTextureColor(self.bg, t.colors.bg.panel)
        NUL:RecolorBorder(self.borders, t.colors.border.subtle)
        NUL.SetFontColor(self.title, t.colors.accent.primary)
    end

    self:_Track(card)
    card:_repaint(theme)
    return card
end

function NUL:StatTile(parent, opts)
    opts = opts or {}
    local theme = self:GetTheme()

    local tile = CreateFrame("Frame", nil, parent)
    tile:SetHeight(opts.height or 58)
    tile.bg      = self:FillBackground(tile, theme.colors.bg.elevated)
    tile.borders = self:AddBorder(tile, nil, theme.metrics.borderThickness)

    tile.value = self:CreateLabel(tile, {
        text = tostring(opts.value or "0"), size = "xl", justifyH = "LEFT", wrap = false,
    })
    tile.value:SetPoint("TOPLEFT", 10, -7)

    tile.label = self:CreateLabel(tile, {
        text = opts.label or "", size = "sm", justifyH = "LEFT", wrap = false,
    })
    tile.label:SetPoint("TOPLEFT", tile.value, "BOTTOMLEFT", 0, -2)

    tile.sub = self:CreateLabel(tile, {
        text = opts.sub or "", size = "xs", justifyH = "LEFT", wrap = false,
    })
    tile.sub:SetPoint("TOPLEFT", tile.label, "BOTTOMLEFT", 0, -1)

    function tile:SetValue(v) self.value:SetText(tostring(v or "0")) end
    function tile:SetLabel(x) self.label:SetText(x or "") end
    function tile:SetSub(x)   self.sub:SetText(x or "") end

    function tile:_repaint(t)
        NUL.SetTextureColor(self.bg, t.colors.bg.elevated)
        NUL:RecolorBorder(self.borders, t.colors.border.subtle)
        NUL.SetFontColor(self.value, t.colors.accent.primary)
        NUL.SetFontColor(self.label, t.colors.text.primary)
        NUL.SetFontColor(self.sub,   t.colors.text.muted)
    end

    self:_Track(tile)
    tile:_repaint(theme)
    return tile
end
