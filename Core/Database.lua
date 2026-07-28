local _, NBK = ...

local DB_VERSION = 4

local function defaultPresets()
    local t = {}
    for i, v in ipairs(NBK.PRESET_REASONS or {}) do t[i] = v end
    return t
end

local DEFAULTS = {
    version = DB_VERSION,
    entries = {},
    settings = {

        filterChat    = true,
        autoMute      = true,

        autoIgnore    = false,

        presetReasons = nil,

        minimapIcon = { hide = false, angle = 225 },

        windowPositions = {},

        lastSeenNews = nil,

        display = {
            classDisplay    = "icon",
            iconStyle       = "classic",
            colorNameByClass = true,
            combinedName    = true,
            showZoneColumn  = false,
            showAddedColumn = false,
            showSeenColumn  = false,

            defaultTab      = "blacklist",

        },

        tooltip = {
            enabled        = true,
            showReason     = true,
            showNotes      = true,
            showZone       = true,
            showEncounters = true,
            showMute       = true,
            showPin        = true,
        },

        groupWarning = {
            enabled   = true,
            chat      = true,
            popup     = true,
            sound     = true,
            soundFile = "AirHorn",
        },

        autoCleanup = {
            enabled = false,
            months  = 6,
        },

    },
}

local Database = NBK:RegisterModule("Database")

local function deepCopy(tbl)
    local copy = {}
    for k, v in pairs(tbl) do
        copy[k] = type(v) == "table" and deepCopy(v) or v
    end
    return copy
end

local function mergeDefaults(target, defaults)
    for k, v in pairs(defaults) do
        if type(v) == "table" then
            if type(target[k]) ~= "table" then target[k] = {} end
            mergeDefaults(target[k], v)
        elseif target[k] == nil then
            target[k] = v
        end
    end
end

function NBK:MergeDefaults(target, defaults)
    if type(target) ~= "table" or type(defaults) ~= "table" then return end
    mergeDefaults(target, defaults)
end

NBK._deferredSettingsDefaults = NBK._deferredSettingsDefaults or {}

function NBK:RegisterSettingsDefaults(defaults)
    if type(defaults) ~= "table" then return end
    if self.db and self.db.settings then
        mergeDefaults(self.db.settings, defaults)
    else
        table.insert(self._deferredSettingsDefaults, defaults)
    end
end

function NBK:NormalizeKey(name, realm)

    if not name then return nil end
    if not realm then
        local n, r = strsplit("-", name, 2)
        name, realm = n, r
    end
    if not realm then
        realm = GetNormalizedRealmName and GetNormalizedRealmName() or GetRealmName()
    end
    realm = realm:gsub("%s+", "")
    return (name:lower() .. "-" .. realm:lower()), name, realm
end

local function migrateV1toV2(db)

    local s = db.settings
    if s then
        if s.notifyOnGroup ~= nil then
            s.groupWarning = s.groupWarning or {}
            if s.groupWarning.enabled == nil then
                s.groupWarning.enabled = s.notifyOnGroup and true or false
            end
            s.notifyOnGroup = nil
        end
    end
end

local function migrateV3toV4(db)

    if type(db.entries) == "table" then
        for _, entry in pairs(db.entries) do
            if entry.encounterCount == nil then entry.encounterCount = 0 end
            if entry.pinned         == nil then entry.pinned         = false end

        end
    end
end

local function migrateV2toV3(db)

    local defaultShareable = true
    if db.settings and db.settings.sync and db.settings.sync.defaultShareable ~= nil then
        defaultShareable = db.settings.sync.defaultShareable and true or false
    end
    if type(db.entries) == "table" then
        for _, entry in pairs(db.entries) do
            if entry.shareable == nil then
                entry.shareable = defaultShareable
            end
        end
    end
end

function Database:OnInitialize()
    if type(NBKDB) ~= "table" then NBKDB = deepCopy(DEFAULTS) end

    if type(NBKDB.settings) ~= "table" then NBKDB.settings = {} end
    if type(NBKDB.settings.presetReasons) ~= "table" then
        NBKDB.settings.presetReasons = defaultPresets()
    end

    local fromVer = NBKDB.version or 1
    if fromVer < 2 then migrateV1toV2(NBKDB) end
    if fromVer < 3 then migrateV2toV3(NBKDB) end
    if fromVer < 4 then migrateV3toV4(NBKDB) end

    mergeDefaults(NBKDB, DEFAULTS)

    for _, extra in ipairs(NBK._deferredSettingsDefaults) do
        mergeDefaults(NBKDB.settings, extra)
    end
    wipe(NBK._deferredSettingsDefaults)

    NBKDB.version = DB_VERSION
    self.db = NBKDB
    NBK.db = NBKDB
end

function Database:OnEnable()
    local count = 0
    for _ in pairs(self.db.entries) do count = count + 1 end
    NBK:Print(("loaded v%s - %d entries"):format(NBK.version, count))
end
