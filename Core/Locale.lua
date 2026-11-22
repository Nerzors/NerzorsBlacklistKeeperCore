local _, NBK = ...

NBK.locales = NBK.locales or {}

function NBK:GetLocale(name, isDefault)
    self.locales[name] = self.locales[name] or {}
    if isDefault then self.defaultLocale = self.locales[name] end
    return self.locales[name]
end

function NBK:RegisterLocaleStrings(locale, strings, isDefault)
    if type(locale) ~= "string" or type(strings) ~= "table" then return end
    local L = self:GetLocale(locale, isDefault)
    for k, v in pairs(strings) do
        L[k] = v
    end
    return L
end

NBK.flavorLocales = NBK.flavorLocales or {}

function NBK:RegisterFlavorStrings(flavor, locale, strings)
    if flavor ~= self.FLAVOR or type(locale) ~= "string" or type(strings) ~= "table" then return end
    self.flavorLocales[locale] = self.flavorLocales[locale] or {}
    for k, v in pairs(strings) do
        if type(v) == "string" then self.flavorLocales[locale][k] = v end
    end
end

local clientLocale = GetLocale() or "enUS"
if clientLocale == "enGB" then clientLocale = "enUS" end

local DEV_FORCE_LOCALE = nil

local currentLocaleName = DEV_FORCE_LOCALE or clientLocale

NBK.LANGUAGES = {
    { code = "enUS", label = "English" },
    { code = "deDE", label = "Deutsch" },
    { code = "esES", label = "Español (España)" },
    { code = "esMX", label = "Español (México)" },
    { code = "frFR", label = "Français" },
    { code = "itIT", label = "Italiano" },
    { code = "ptBR", label = "Português (Brasil)" },
    { code = "ruRU", label = "Русский" },
}

function NBK:ClientLocale() return clientLocale end

local function isLanguage(code)
    for _, l in ipairs(NBK.LANGUAGES) do
        if l.code == code then return true end
    end
    return false
end

function NBK:SetLocale(code)
    local want = (type(code) == "string" and code ~= "auto" and isLanguage(code)) and code or clientLocale
    currentLocaleName = DEV_FORCE_LOCALE or want
    self.currentLocale = currentLocaleName
    return currentLocaleName
end

local LOCALE_FALLBACK = {
    esES = "esMX",
}

local function pick(loc, key)
    local v = loc and loc[key]
    if type(v) == "string" then return v end
end

local L = setmetatable({}, {
    __index = function(_, key)
        local fallback = LOCALE_FALLBACK[currentLocaleName]
        local flavor   = NBK.flavorLocales
        return pick(flavor[currentLocaleName], key)
            or (fallback and pick(flavor[fallback], key))
            or pick(NBK.locales[currentLocaleName], key)
            or pick(NBK.locales[fallback], key)
            or pick(flavor.enUS, key)
            or pick(NBK.defaultLocale, key)
            or key
    end,
})

NBK.L = L
NBK.currentLocale = currentLocaleName

function NBK:FormatDate(ts)
    if not ts then return "-" end
    return date(L["%d.%m.%Y"], ts)
end

function NBK:FormatDateTime(ts)
    if not ts then return "-" end
    return date(L["%d.%m. %H:%M"], ts)
end
