local _, NBK = ...
NBK.UI = NBK.UI or {}

local NUL = LibStub("NerzorsUILib-1.0")

NUL:SetIconResolver(function(name)
    return NBK and NBK.IconPath and NBK:IconPath(name) or name
end)

local hex = NUL.hex

local DATA = "Interface\\AddOns\\NerzorsBlacklistKeeper_Data\\"
local FONT_NERZORS  = DATA .. "Fonts\\Nerzors.ttf"
local LOGO_MIDNIGHT = DATA .. "Textures\\NerzorsBlacklistKeeper_Midnight_Logo"
local LOGO_BASE     = DATA .. "Textures\\NerzorsBlacklistKeeper_Midnight_Logo"
local LOGO_NERZORS  = DATA .. "Textures\\NNerzorsBlacklistKeeper_Midnight_Logo"
local EDGE = "Interface\\Buttons\\WHITE8x8"
local BG   = "Interface\\Buttons\\WHITE8x8"

local commonShape = {
    radius    = 4,
    spacing   = { xs = 4, sm = 8, md = 12, lg = 18 },
    fonts     = {
        regular = FONT_NERZORS,
        bold    = FONT_NERZORS,
        mono    = FONT_NERZORS,
        heading = FONT_NERZORS,
    },
    fontSizes = { xs = 10, sm = 11, md = 12, lg = 14, xl = 18 },

    metrics   = {
        borderThickness = 1,
        rowHeight       = 26,
        windowPadding   = 12,
        titleBarHeight  = 28,
    },
    media     = { logo = LOGO_NERZORS, edge = EDGE, bg = BG },
}

local function withShape(rec)
    for k, v in pairs(commonShape) do
        if rec[k] == nil then rec[k] = v end
    end
    return rec
end

NUL:RegisterTheme("Nerzors", withShape({
    colors = {
        bg = {
            base     = hex("#0e1419"),
            panel    = hex("#161e26"),
            elevated = hex("#1d2731"),
            hover    = hex("#243240"),
            active   = hex("#2c3d4d"),
        },
        border = {
            subtle = hex("#2a3744"),
            accent = hex("#48a8dc"),
        },
        text = {
            primary  = hex("#e6edf3"),
            muted    = hex("#8b9aa8"),
            disabled = hex("#5a6772"),
            inverse  = hex("#0e1419"),
        },
        accent = {
            primary   = hex("#48a8dc"),
            secondary = hex("#be4ae9"),
        },
        state = {
            success = hex("#5cb85c"),
            warning = hex("#f0ad4e"),
            danger  = hex("#d9534f"),
            info    = hex("#48a8dc"),
        },
    },
    media = { logo = LOGO_BASE, edge = EDGE, bg = BG },
}))

NUL:RegisterTheme("Midnight", withShape({
    colors = {
        bg = {
            base     = hex("#0d0a14"),
            panel    = hex("#15101e"),
            elevated = hex("#1d1628"),
            hover    = hex("#281e36"),
            active   = hex("#322642"),
        },
        border = {
            subtle = hex("#2c2238"),
            accent = hex("#be4ae9"),
        },
        text = {
            primary  = hex("#ece6f3"),
            muted    = hex("#9b8fb0"),
            disabled = hex("#615570"),
            inverse  = hex("#0d0a14"),
        },
        accent = {
            primary   = hex("#be4ae9"),
            secondary = hex("#48a8dc"),
        },
        state = {
            success = hex("#5cb85c"),
            warning = hex("#f0ad4e"),
            danger  = hex("#d9534f"),
            info    = hex("#be4ae9"),
        },
    },
    media = { logo = LOGO_MIDNIGHT, edge = EDGE, bg = BG },
}))

NUL:RegisterTheme("Sci-Fi", withShape({
    colors = {
        bg = {
            base     = hex("#080812"),
            panel    = hex("#101022"),
            elevated = hex("#161630"),
            hover    = hex("#202048"),
            active   = hex("#2a2a58"),
        },
        border = {
            subtle = hex("#2a2a4a"),
            accent = hex("#48a8dc"),
        },
        text = {
            primary  = hex("#ece6f3"),
            muted    = hex("#9b8fb0"),
            disabled = hex("#615570"),
            inverse  = hex("#080812"),
        },
        accent = {
            primary   = hex("#be4ae9"),
            secondary = hex("#48a8dc"),
        },
        state = {
            success = hex("#5cb85c"),
            warning = hex("#f0ad4e"),
            danger  = hex("#d9534f"),
            info    = hex("#48a8dc"),
        },
    },
    window = {
        useGradient         = true,
        gradientOrientation = "VERTICAL",
        gradient = {
            start  = hex("#0a0a18"),
            ["end"] = hex("#000005"),
        },
        glow = hex("#48a8dc4d"),
    },
    media = { logo = LOGO_MIDNIGHT, edge = EDGE, bg = BG },
}))

NBK:RegisterEvent("PLAYER_LOGIN", function()
    local s = NBK.db and NBK.db.settings
    if s and s.theme and NUL:HasTheme(s.theme) then
        NUL:SetTheme(s.theme)
    end
end)

NUL:RegisterThemeChangedCallback(function(_, name)
    if NBK.db and NBK.db.settings then
        NBK.db.settings.theme = name
    end
end)
