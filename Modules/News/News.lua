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
local VERSION_GAP     = 18
local SECTION_GAP     = 6
local ITEM_GAP        = 4
local SECTION_PILL_W  = 80
local SECTION_PILL_H  = 18

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

    local BULLET_W   = 12
    local BULLET_GAP = 4
    local ROW_INDENT = 6
    local bodyTextWidth = math.max(
        100,
        scrollWidth - 2 * PADDING - ROW_INDENT - BULLET_W - BULLET_GAP
    )

    local entries = NBK.WHATS_NEW or {}
    local y = -PADDING
    local contentWidth = scrollWidth

    for vi, entry in ipairs(entries) do

        local header = track(CreateFrame("Frame", nil, content))
        header:SetHeight(22)
        header:SetPoint("TOPLEFT",  content, "TOPLEFT",  PADDING,  y)
        header:SetPoint("TOPRIGHT", content, "TOPRIGHT", -PADDING, y)

        local titleFS = NUL:CreateLabel(header, {
            text = "v" .. tostring(entry.version or "?"),
            size = "lg", justifyH = "LEFT",
            color = theme.colors.accent.primary,
        })
        titleFS:SetPoint("LEFT", 0, 0)
        track(titleFS)

        if entry.date and entry.date ~= "" then
            local dateFS = NUL:CreateLabel(header, {
                text = entry.date, size = "sm",
                color = theme.colors.text.muted,
            })
            dateFS:SetPoint("LEFT", titleFS, "RIGHT", 8, -1)
            track(dateFS)
        end

        if vi == 1 and entry.highlight then
            local pill = CreateFrame("Frame", nil, header)
            pill:SetSize(40, 16)
            pill:SetPoint("RIGHT", 0, 0)
            pill.bg = NUL:FillBackground(pill, theme.colors.accent.primary)
            local pillFS = NUL:CreateLabel(pill, {
                text = "NEW", size = "xs",
                color = theme.colors.text.inverse,
                justifyH = "CENTER",
            })
            pillFS:SetPoint("CENTER")
            track(pill)
        end

        y = y - 24

        local rule = track(content:CreateTexture(nil, "ARTWORK"))
        rule:SetHeight(1)
        rule:SetPoint("LEFT",  content, "LEFT",  PADDING,  y)
        rule:SetPoint("RIGHT", content, "RIGHT", -PADDING, y)
        NUL.SetTextureColor(rule, NUL.WithAlpha(theme.colors.border.subtle, 0.5))
        y = y - 8

        for _, section in ipairs(entry.sections or {}) do
            local meta = SECTION_META[section.kind] or SECTION_META.note
            local color = tokenColor(theme, meta.colorToken) or theme.colors.text.muted

            local pill = track(CreateFrame("Frame", nil, content))
            pill:SetSize(SECTION_PILL_W, SECTION_PILL_H)
            pill:SetPoint("TOPLEFT", content, "TOPLEFT", PADDING, y)
            pill.bg = NUL:FillBackground(pill, NUL.WithAlpha(color, 0.25))
            local pillFS = NUL:CreateLabel(pill, {
                text  = sectionLabel(section.kind),
                size  = "sm",
                color = color,
                justifyH = "CENTER",
            })
            pillFS:SetPoint("CENTER")
            y = y - (SECTION_PILL_H + 4)

            for _, item in ipairs(section.items or {}) do
                local text = NBK:LocalizeNewsItem(item)
                if text and text ~= "" then
                    local row = track(CreateFrame("Frame", nil, content))
                    row:SetPoint("TOPLEFT",  content, "TOPLEFT",
                        PADDING + ROW_INDENT, y)
                    row:SetPoint("TOPRIGHT", content, "TOPRIGHT",
                        -PADDING,             y)

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
                    y = y - (h + ITEM_GAP)
                end
            end

            y = y - SECTION_GAP
        end

        y = y - VERSION_GAP
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

    if C_Timer and C_Timer.After then
        C_Timer.After(0.4, function() self:Show() end)
    else
        self:Show()
    end
end

function News:OnEnable()

end
