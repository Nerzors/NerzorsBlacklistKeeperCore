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

local L = setmetatable({}, {
    __index = function(_, key)
        local loc = NBK.locales[currentLocaleName]
        if loc then
            local v = loc[key]
            if type(v) == "string" then return v end
        end
        local def = NBK.defaultLocale
        if def then
            local v = def[key]
            if type(v) == "string" then return v end
        end
        return key
    end,
})

NBK.L = L
NBK.currentLocale = currentLocaleName
