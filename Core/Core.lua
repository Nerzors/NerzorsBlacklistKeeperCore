local addonName, NBK = ...
_G.NBK = NBK

NBK.name = addonName
local getMeta = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
NBK.version = (getMeta and getMeta(addonName, "Version")) or "0.2.0"
NBK.prefix = "|cff9b59b6NBK|r"

NBK.modules = {}
NBK.callbacks = {}

NBK._subAddons = {}

local frame = CreateFrame("Frame", addonName .. "EventFrame")
NBK.frame = frame

function NBK:RegisterModule(name, module)
    assert(type(name) == "string", "module name must be a string")
    assert(not self.modules[name], "module already registered: " .. name)
    module = module or {}
    module.name = name
    module.enabled = module.enabled ~= false
    self.modules[name] = module

    self:_CatchUpModule(module)
    return module
end

function NBK:_CatchUpModule(module)
    if not module or not module.enabled then return end
    if self._initDone and module.OnInitialize and not module._inited then
        module._inited = true
        local ok, err = pcall(module.OnInitialize, module)
        if not ok then self:Print("init failed for", module.name, ":", err) end
    end
    if self._loginDone and module.OnEnable and not module._enabled then
        module._enabled = true
        local ok, err = pcall(module.OnEnable, module)
        if not ok then self:Print("enable failed for", module.name, ":", err) end
    end
end

function NBK:_CatchUpAllModules()
    for _, module in pairs(self.modules) do
        self:_CatchUpModule(module)
    end
end

function NBK:GetModule(name)
    return self.modules[name]
end

function NBK:RegisterEvent(event, handler)
    self.callbacks[event] = self.callbacks[event] or {}
    table.insert(self.callbacks[event], handler)
    frame:RegisterEvent(event)
end

frame:SetScript("OnEvent", function(_, event, ...)
    local handlers = NBK.callbacks[event]
    if not handlers then return end
    for _, handler in ipairs(handlers) do
        local ok, err = pcall(handler, event, ...)
        if not ok then
            print(NBK.prefix, "error in", event, ":", err)
        end
    end
end)

function NBK:Print(...)
    print(self.prefix, ...)
end

function NBK:OnLoad()
    self._initDone = true
    self:_CatchUpAllModules()
end

function NBK:OnLogin()
    self._loginDone = true
    self:_CatchUpAllModules()

    local NUL = LibStub("NerzorsUILib-1.0")
    NUL:RegisterThemeChangedCallback(function(theme, name)
        for _, module in pairs(NBK.modules) do
            if module.enabled and module.OnThemeChanged then
                local ok, err = pcall(module.OnThemeChanged, module, theme, name)
                if not ok then
                    NBK:Print("OnThemeChanged failed for", module.name, ":", err)
                end
            end
        end
    end)
end

function NBK:_InitAddonDB(spec)
    if spec._initialized then return spec.db end
    if type(_G[spec.svName]) ~= "table" then _G[spec.svName] = {} end
    local db = _G[spec.svName]

    local isFirstLoad = (db.version == nil)

    if not isFirstLoad and spec.migrate and (db.version or 0) < (spec.version or 1) then
        local ok, err = pcall(spec.migrate, db, db.version)
        if not ok then self:Print("migrate failed for", spec.key, ":", err) end
    end

    if spec.defaults then self:MergeDefaults(db, spec.defaults) end

    if isFirstLoad and spec.onFirstLoad then
        local ok, err = pcall(spec.onFirstLoad, db)
        if not ok then self:Print("onFirstLoad failed for", spec.key, ":", err) end
    end

    db.version = spec.version or 1
    spec.db = db
    spec._initialized = true

    if spec.onReady then
        local ok, err = pcall(spec.onReady, db)
        if not ok then self:Print("onReady failed for", spec.key, ":", err) end
    end
    return db
end

function NBK:RegisterAddonDB(spec)
    assert(type(spec) == "table", "NBK:RegisterAddonDB: spec must be a table")
    assert(spec.addonName, "NBK:RegisterAddonDB: spec.addonName required")
    assert(spec.key,       "NBK:RegisterAddonDB: spec.key required")
    assert(spec.svName,    "NBK:RegisterAddonDB: spec.svName required")
    self._subAddons[spec.addonName] = spec

    local isLoaded = C_AddOns and C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded(spec.addonName)
                  or (IsAddOnLoaded and IsAddOnLoaded(spec.addonName))
    if isLoaded and _G[spec.svName] ~= nil then
        self:_InitAddonDB(spec)
    end
    return spec
end

function NBK:GetAddonDB(key)
    for _, spec in pairs(self._subAddons) do
        if spec.key == key then return spec.db end
    end
end

NBK:RegisterEvent("ADDON_LOADED", function(_, loadedAddon)
    if loadedAddon == addonName then
        NBK:OnLoad()
    end

    local spec = NBK._subAddons[loadedAddon]
    if spec and not spec._initialized then
        NBK:_InitAddonDB(spec)
    end

    if loadedAddon ~= addonName then
        NBK:_CatchUpAllModules()
    end
end)

NBK:RegisterEvent("PLAYER_LOGIN", function()
    NBK:OnLogin()
    NBK:_VerifyDataAddon()
end)

function NBK:_VerifyDataAddon()
    local isLoaded = C_AddOns and C_AddOns.IsAddOnLoaded
                  and C_AddOns.IsAddOnLoaded("NerzorsBlacklistKeeper_Data")
                  or (IsAddOnLoaded and IsAddOnLoaded("NerzorsBlacklistKeeper_Data"))
    if not isLoaded then
        self:Print("|cffff5555NerzorsBlacklistKeeper_Data is not loaded.|r " ..
            "Fonts/textures/sounds will be missing. Enable it in the AddOns list.")
    end
end
