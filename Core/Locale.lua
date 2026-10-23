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

local currentLocaleName = GetLocale() or "enUS"

if currentLocaleName == "enGB" then currentLocaleName = "enUS" end

local LOCALE_FALLBACK = {
    esES = "esMX",
}

local function pick(loc, key)
    local v = loc and loc[key]
    if type(v) == "string" then return v end
end

local L = setmetatable({}, {
    __index = function(_, key)
        return pick(NBK.locales[currentLocaleName], key)
            or pick(NBK.locales[LOCALE_FALLBACK[currentLocaleName]], key)
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
