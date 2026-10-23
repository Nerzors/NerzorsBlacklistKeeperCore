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
local LOGO_FOREVER = DATA .. "Textures\\NerzorsBlacklistKeeper_Forever_Logo"
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

local function buttonPalette(p)
    local function state(bg, border, text, icon)
        return {bg = hex(bg), border = hex(border), text = hex(text or p.text), icon = icon and hex(icon)}
    end
    local function role(row)
        return {
            normal = state(row.normal, row.border),
            hover = state(row.hover, row.hoverBorder or row.border),
            pressed = state(row.pressed, row.hoverBorder or row.border),
            disabled = state(p.disabled.bg, p.disabled.border, p.disabled.text),
        }
    end
    local primary, secondary = role(p.primary), role(p.secondary)
    return {
        primary = primary,
        secondary = secondary,
        danger = {
            normal = state("#51262c", "#96535a", nil, "#ee9298"),
            hover = state("#673039", "#c0767d", nil, "#ffc0c4"),
            pressed = state("#411f26", "#c0767d", nil, "#ee9298"),
            disabled = state(p.disabled.bg, p.disabled.border, p.disabled.text, p.disabled.text),
        },
        ghost = {
            normal = state("#00000000", "#00000000", p.muted),
            hover = state(p.secondary.hover, p.secondary.border),
            pressed = state(p.secondary.pressed, p.secondary.border),
            disabled = state("#00000000", "#00000000", p.disabled.text),
        },
    }
end

NUL:RegisterTheme("Nerzors", withShape({
    colors = {
        btn = buttonPalette({
            text = "#e6edf3", muted = "#8b9aa8",
            primary = {normal = "#21445b", hover = "#2b5773", pressed = "#19374b", border = "#3b7396", hoverBorder = "#5594b8"},
            secondary = {normal = "#161e26", hover = "#243240", pressed = "#1d2731", border = "#2a3744", hoverBorder = "#486078"},
            disabled = {bg = "#17232d", text = "#8795a3", border = "#2a3744"},
        }),
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
            secondary = hex("#2a3744"),
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
        btn = buttonPalette({
            text = "#ece6f3", muted = "#9b8fb0",
            primary = {normal = "#402d53", hover = "#523968", pressed = "#322341", border = "#805899", hoverBorder = "#a779be"},
            secondary = {normal = "#15101e", hover = "#281e36", pressed = "#1d1628", border = "#2c2238", hoverBorder = "#665077"},
            disabled = {bg = "#201a29", text = "#9689a4", border = "#34283f"},
        }),
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
            secondary = hex("#2c2238"),
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

NUL:RegisterTheme("Forever∞", withShape({
    colors = {
        btn = buttonPalette({
            text = "#eae9e1", muted = "#969eb2",
            primary = {normal = "#164652", hover = "#1d5968", pressed = "#123945", border = "#32758a", hoverBorder = "#4590a5"},
            secondary = {normal = "#141824", hover = "#203148", pressed = "#161d30", border = "#285a64", hoverBorder = "#3f7781"},
            disabled = {bg = "#18242c", text = "#8b9da2", border = "#2c4850"},
        }),
        bg = {
            base     = hex("#0e101a"),
            panel    = hex("#141824"),
            elevated = hex("#161d30"),
            hover    = hex("#203148"),
            active   = hex("#2a4258"),
        },
        border = {
            subtle = hex("#285a64"),
            accent = hex("#2ea5cd"),
        },
        text = {
            primary  = hex("#eae9e1"),
            muted    = hex("#969eb2"),
            disabled = hex("#556c70"),
            inverse  = hex("#0c3e5a"),
        },
        accent = {
            primary   = hex("#d6b884"),
            secondary = hex("#285a64"),
        },
        state = {
            success = hex("#3dd6bd"),
            warning = hex("#e8945c"),
            danger  = hex("#d9534f"),
            info    = hex("#5ccde8"),
        },
    },
    window = {
        useGradient         = true,
        gradientOrientation = "VERTICAL",
        gradient = {
            start  = hex("#0e0f11"),
            ["end"] = hex("#151d24"),
        },
        glow = hex("#2ea5cd4d"),
    },
    media = { logo = LOGO_FOREVER, edge = EDGE, bg = BG },
}))

NBK:RegisterEvent("PLAYER_LOGIN", function()
    local s = NBK.db and NBK.db.settings

    if s and (s.theme == "Sci-Fi" or s.theme == "Forever") then s.theme = "Forever∞" end
    if s and s.theme and NUL:HasTheme(s.theme) then
        NUL:SetTheme(s.theme)
    end
end)

NUL:RegisterThemeChangedCallback(function(_, name)
    if NBK.db and NBK.db.settings then
        NBK.db.settings.theme = name
    end
end)
