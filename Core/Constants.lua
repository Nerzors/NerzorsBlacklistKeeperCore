local _, NBK = ...

NBK.PRESET_REASONS = {
    "Bad player",
    "Quitter",
    "AFKer",
    "Toxic",
    "Scammer",
    "Bigot",
    "Boosting",
    "Other",
}

NBK.MEDIA = {
    iconBase    = "Interface\\AddOns\\NerzorsBlacklistKeeper_Data\\Textures\\icons\\",
    classBase   = "Interface\\AddOns\\NerzorsBlacklistKeeper_Data\\Textures\\class\\",
    soundBase   = "Interface\\AddOns\\NerzorsBlacklistKeeper_Data\\Sounds\\",
    sounds = {
        "AirHorn",
        "BananaPeelSlip",
        "BikeHorn",
        "BoxingArenaSound",
        "WaterDrop",
    },
}

function NBK:SoundPath(name)
    if not name or name == "" then return nil end
    return self.MEDIA.soundBase .. name .. ".ogg"
end

function NBK:IconPath(name)
    if not name or name == "" then return nil end
    return self.MEDIA.iconBase .. name
end

NBK.FOOTER = {
    showCredits = true,
    showVersion = true,
}

NBK.SOCIAL_LINKS = {

    {
        id      = "web",
        enabled = true,
        url     = "https://www.nerzors.de/en/",
        icon    = "social-web.png",
        tooltip = "www.nerzors.de",
    },
    {
        id      = "discord",
        enabled = true,
        url     = "https://discord.nerzors.de/",
        icon    = "social-discord.png",
        tooltip = "Discord",
    },
    {
        id      = "github",
        enabled = true,
        url     = "https://github.com/Nerzors/NerzorsBlacklistKeeper",
        icon    = "social-github.png",
        tooltip = "GitHub",
    },
    {
        id      = "kofi",
        enabled = true,
        url     = "https://ko-fi.com/Nerzors",
        icon    = "social-kofi.png",
        tooltip = "Ko-fi",
    },
}

NBK.CLASS_SPRITE_TEX = {
    midnight = NBK.MEDIA.classBase .. "midnight",
    classic  = NBK.MEDIA.classBase .. "classic",
}

NBK.CLASS_SPRITE_COORDS = {
    WARRIOR     = { 0,     0.125, 0,     0.125 },
    MAGE        = { 0.125, 0.25,  0,     0.125 },
    ROGUE       = { 0.25,  0.375, 0,     0.125 },
    DRUID       = { 0.375, 0.5,   0,     0.125 },
    EVOKER      = { 0.5,   0.625, 0,     0.125 },
    HUNTER      = { 0,     0.125, 0.125, 0.25  },
    SHAMAN      = { 0.125, 0.25,  0.125, 0.25  },
    PRIEST      = { 0.25,  0.375, 0.125, 0.25  },
    WARLOCK     = { 0.375, 0.5,   0.125, 0.25  },
    PALADIN     = { 0,     0.125, 0.25,  0.375 },
    DEATHKNIGHT = { 0.125, 0.25,  0.25,  0.375 },
    MONK        = { 0.25,  0.375, 0.25,  0.375 },
    DEMONHUNTER = { 0.375, 0.5,   0.25,  0.375 },
}

NBK.CLASS_SPRITE_STYLES = { "midnight", "classic" }

NBK.CLASS_COLORS = {
    WARRIOR     = { 0.78, 0.61, 0.43 },
    PALADIN     = { 0.96, 0.55, 0.73 },
    HUNTER      = { 0.67, 0.83, 0.45 },
    ROGUE       = { 1.00, 0.96, 0.41 },
    PRIEST      = { 1.00, 1.00, 1.00 },
    SHAMAN      = { 0.00, 0.44, 0.87 },
    MAGE        = { 0.25, 0.78, 0.92 },
    WARLOCK     = { 0.53, 0.53, 0.93 },
    MONK        = { 0.00, 1.00, 0.59 },
    DRUID       = { 1.00, 0.49, 0.04 },
    DEMONHUNTER = { 0.64, 0.19, 0.79 },
    DEATHKNIGHT = { 0.77, 0.12, 0.23 },
    EVOKER      = { 0.20, 0.58, 0.50 },
}

local function toHex(c)
    return ("%02x%02x%02x"):format(
        math.floor((c[1] or 1) * 255 + 0.5),
        math.floor((c[2] or 1) * 255 + 0.5),
        math.floor((c[3] or 1) * 255 + 0.5))
end

NBK.CLASS_HEX = {}
for k, c in pairs(NBK.CLASS_COLORS) do NBK.CLASS_HEX[k] = toHex(c) end

function NBK:GetClassHex(classFile)
    if not classFile then return "ffffff" end
    return self.CLASS_HEX[classFile] or "ffffff"
end

function NBK:GetClassRGB(classFile)
    local c = classFile and self.CLASS_COLORS[classFile]
    if c then return c[1], c[2], c[3] end
    return 1, 1, 1
end
