local _, NBK = ...
local NUL = LibStub("NerzorsUILib-1.0")

local News = NBK:RegisterModule("News")

local SECTION_META = {
    new = {
        labelEn = "New",     labelDe = "Neu",
        colorToken = "state.success",
    },
    fixed = {
        labelEn = "Fixed",   labelDe = "Behoben",
        colorToken = "state.info",
    },
    changed = {
        labelEn = "Changed", labelDe = "Geändert",
        colorToken = "state.warning",
    },
    note = {
        labelEn = "Note",    labelDe = "Hinweis",
        colorToken = "text.muted",
    },
}

local function sectionLabel(kind)
    local meta = SECTION_META[kind or "note"] or SECTION_META.note
    local loc = GetLocale and GetLocale() or "enUS"
    if loc == "deDE" then return meta.labelDe else return meta.labelEn end
end

local function tokenColor(theme, path)

    local t = theme.colors
    for part in tostring(path):gmatch("[^%.]+") do
        if type(t) ~= "table" then return nil end
        t = t[part]
    end
    return t
end

local PADDING         = 14
local VERSION_GAP     = 10
local SECTION_GAP     = 8
local ITEM_GAP        = 5
local SECTION_PILL_H  = 18
local PILL_PAD        = 9
local CARD_PAD        = 10
local CARD_CHROME     = 40
local BULLET_W        = 12
local BULLET_GAP      = 4
local ROW_INDENT      = 2

function News:_Build()
    if self.frame then return self.frame end

    local L = NBK.L
    local f = NUL:Window({
        name   = "NBKNewsWindow",
        title  = L["What's new?"] or "What's new?",
        width  = 540, height = 560,
        strata = "DIALOG",
    })
    f:SetPositionKey("NewsWindow", NBK.db)
    f:MakeResizable({ minW = 460, minH = 360, maxW = 900, maxH = 900 })
    f:RestorePosition()

    f:SetScript("OnHide", function() self:_MarkSeen() end)

    local scroll = CreateFrame("ScrollFrame", nil, f.content, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT")
    scroll:SetPoint("BOTTOMRIGHT", -22, 32)

    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(1, 1)
    scroll:SetScrollChild(content)
    self._scroll = scroll
    self._content = content

    self._sbar = NUL:_AttachThemedScrollBar(scroll, f.content)

    local footRule = f.content:CreateTexture(nil, "ARTWORK")
    footRule:SetHeight(1)
    footRule:SetPoint("BOTTOMLEFT",  0, 32)
    footRule:SetPoint("BOTTOMRIGHT", 0, 32)
    self._footRule = footRule

    local okBtn = NUL:Button(f.content, {
        label = L["Got it"] or "Got it",
        width = 140, height = 26, style = "accent",
        onClick = function() f:Hide() end,
    })
    okBtn:SetPoint("BOTTOM", 0, 0)
    self._okBtn = okBtn

    scroll:HookScript("OnSizeChanged", function(_, w)
        if w and w > 0 then content:SetWidth(w) end
        if self._populateDebounce then return end
        self._populateDebounce = true
        C_Timer.After(0.08, function()
            self._populateDebounce = false
            if self.frame and self.frame:IsShown() then self:_Populate() end
        end)
    end)

    self.frame = f
    return f
end

function News:_IsUnseen(version)
    local seen = NBK.db and NBK.db.settings and NBK.db.settings.lastSeenNews
    if not seen then return true end
    return NBK:_VersionGreater(version, seen)
end

function News:_AnyUnseen()
    for _, entry in ipairs(NBK:GetVisibleNews()) do
        if self:_IsUnseen(entry.version) then return true end
    end
    return false
end

function News:_IsExpanded(version, index, anyUnseen)
    local override = self._collapsed and self._collapsed[version]
    if override ~= nil then return not override end
    if anyUnseen == nil then anyUnseen = self:_AnyUnseen() end
    if anyUnseen then return self:_IsUnseen(version) end
    return index == 1
end

function News:_ToggleVersion(version, index)
    self._collapsed = self._collapsed or {}
    self._collapsed[version] = self:_IsExpanded(version, index)
    self:_Populate()
end

function News:_Populate()
    local theme   = NUL:GetTheme()
    local content = self._content
    if not content then return end

    if self._renderedFrames then
        for _, fr in ipairs(self._renderedFrames) do
            fr:Hide(); fr:ClearAllPoints(); fr:SetParent(nil)
        end
    end
    self._renderedFrames = {}

    local function track(fr) table.insert(self._renderedFrames, fr); return fr end

    local scrollWidth = self._scroll and self._scroll:GetWidth() or 0
    if scrollWidth < 32 then scrollWidth = 500 end
    content:SetWidth(scrollWidth)

    local cardWidth     = math.max(120, scrollWidth - 2 * PADDING)
    local cardInnerW    = cardWidth - 2 * CARD_PAD
    local bodyTextWidth = math.max(
        100,
        cardInnerW - ROW_INDENT - BULLET_W - BULLET_GAP
    )

    local entries   = NBK:GetVisibleNews()
    local anyUnseen = self:_AnyUnseen()
    local y = -PADDING

    for vi, entry in ipairs(entries) do
        local expanded = self:_IsExpanded(entry.version, vi, anyUnseen)

        local card = track(NUL:Card(content, { title = "v" .. tostring(entry.version or "?") }))
        card:SetWidth(cardWidth)
        card:SetPoint("TOPLEFT", content, "TOPLEFT", PADDING, y)

        if entry.date and entry.date ~= "" then
            local dateFS = NUL:CreateLabel(card, {
                text = entry.date, size = "sm",
                color = theme.colors.text.muted, wrap = false,
            })

            dateFS:SetPoint("TOPLEFT", card, "TOPLEFT",
                CARD_PAD + math.max(44, card.title:GetStringWidth() + 8), -CARD_PAD - 1)
        end

        local rightX = -CARD_PAD

        local chevron = card:CreateTexture(nil, "OVERLAY")
        chevron:SetSize(10, 10)
        chevron:SetPoint("TOPRIGHT", rightX, -CARD_PAD - 4)
        chevron:SetTexture(NUL:ResolveIcon(expanded and "arrow-up.png" or "arrow-down.png"))
        NUL.SetTextureColor(chevron, theme.colors.text.muted)
        rightX = rightX - 16

        if entry.highlight and self:_IsUnseen(entry.version) then

            local label  = sectionLabel("new")
            local pill   = CreateFrame("Frame", nil, card)
            local pillFS = NUL:CreateLabel(pill, {
                text = label, size = "xs",
                color = theme.colors.text.inverse,
                justifyH = "CENTER", wrap = false,
            })
            pillFS:SetPoint("CENTER")
            pill:SetSize(math.max(34, pillFS:GetStringWidth() + 12), 15)
            pill:SetPoint("TOPRIGHT", rightX, -CARD_PAD - 2)
            pill.bg = NUL:FillBackground(pill, theme.colors.accent.primary)
        end

        local hdrBtn = CreateFrame("Button", nil, card)
        hdrBtn:SetPoint("TOPLEFT",  CARD_PAD, -CARD_PAD)
        hdrBtn:SetPoint("TOPRIGHT", -CARD_PAD, -CARD_PAD)
        hdrBtn:SetHeight(20)
        hdrBtn:SetScript("OnClick", function()
            self:_ToggleVersion(entry.version, vi)
        end)

        local innerY = 0

        if expanded then
            for _, section in ipairs(entry.sections or {}) do
                local meta  = SECTION_META[section.kind] or SECTION_META.note
                local color = tokenColor(theme, meta.colorToken) or theme.colors.text.muted

                local pill   = CreateFrame("Frame", nil, card.content)
                local pillFS = NUL:CreateLabel(pill, {
                    text  = sectionLabel(section.kind),
                    size  = "sm", color = color,
                    justifyH = "CENTER", wrap = false,
                })
                pillFS:SetPoint("CENTER")
                pill:SetSize(math.max(48, pillFS:GetStringWidth() + PILL_PAD * 2),
                             SECTION_PILL_H)
                pill:SetPoint("TOPLEFT", card.content, "TOPLEFT", 0, -innerY)

                pill.bg = NUL:FillBackground(pill, NUL.WithAlpha(color, 0.15))
                innerY = innerY + SECTION_PILL_H + 5

                for _, rec in ipairs(section.items or {}) do
                    local text = NBK:LocalizeNewsItem(rec.item)
                    if text and text ~= "" then

                        local badge = rec.sub and NBK:GetModuleLabel(rec.sub)
                        if badge then
                            text = ("|cff%s%s|r  %s"):format(
                                NUL.ToHex(theme.colors.accent.secondary), badge, text)
                        end

                        local row = CreateFrame("Frame", nil, card.content)
                        row:SetPoint("TOPLEFT",  card.content, "TOPLEFT",  ROW_INDENT, -innerY)
                        row:SetPoint("TOPRIGHT", card.content, "TOPRIGHT", 0,          -innerY)

                        local bullet = NUL:CreateLabel(row, {
                            text = "•", size = "md",
                            color = theme.colors.accent.primary,
                        })
                        bullet:SetPoint("TOPLEFT", 0, 0)
                        bullet:SetWidth(BULLET_W)

                        local body = NUL:CreateLabel(row, {
                            text = text, size = "md",
                            color = theme.colors.text.primary,
                            justifyH = "LEFT",
                        })
                        body:SetPoint("TOPLEFT", bullet, "TOPRIGHT", BULLET_GAP, 0)

                        body:SetWidth(bodyTextWidth)
                        body:SetWordWrap(true)

                        local h = math.max(16, math.ceil(body:GetStringHeight() or 16) + 2)
                        row:SetHeight(h)
                        innerY = innerY + h + ITEM_GAP
                    end
                end

                innerY = innerY + SECTION_GAP
            end
            innerY = math.max(0, innerY - SECTION_GAP)
        end

        card:SetHeight(innerY + CARD_CHROME)
        y = y - card:GetHeight() - VERSION_GAP
    end

    if self._footRule then
        NUL.SetTextureColor(self._footRule,
            NUL.WithAlpha(theme.colors.border.subtle, 0.6))
    end

    local totalHeight = math.abs(y) + PADDING
    content:SetHeight(totalHeight)
    if self._scroll then
        content:SetWidth(self._scroll:GetWidth())
    end
end

function News:Show()
    self:_Build()
    self:_Populate()
    self.frame:Show()

    if C_Timer and C_Timer.After then
        C_Timer.After(0, function()
            if self.frame and self.frame:IsShown() then self:_Populate() end
        end)
    end
end

function News:Hide()
    if self.frame then self.frame:Hide() end
end

function News:Toggle()
    self:_Build()
    if self.frame:IsShown() then self:Hide() else self:Show() end
end

function News:_LatestVersion()
    local entries = NBK.WHATS_NEW or {}
    local first = entries[1]
    return first and first.version or nil
end

function News:_MarkSeen()
    local s = NBK.db and NBK.db.settings
    if not s then return end
    local latest = self:_LatestVersion()
    if latest then s.lastSeenNews = latest end
end

function News:MaybeAutoOpen()
    local latest = self:_LatestVersion()
    if not latest then return end
    local s = NBK.db and NBK.db.settings
    if not s then return end
    if not NBK:_VersionGreater(latest, s.lastSeenNews) then return end

    local visible = NBK:GetVisibleNews()
    if #visible == 0 or not NBK:_VersionGreater(visible[1].version, s.lastSeenNews) then
        s.lastSeenNews = latest
        return
    end

    if C_Timer and C_Timer.After then
        C_Timer.After(0.4, function() self:Show() end)
    else
        self:Show()
    end
end

function News:OnEnable()

end
