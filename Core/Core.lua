local addonName, NBK = ...
_G.NBK = NBK

NBK.name = addonName
local getMeta = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
NBK.version = (getMeta and getMeta(addonName, "Version")) or "0.2.0"
NBK.prefix = "|cff9b59b6NBK|r"

NBK.modules = {}
NBK.callbacks = {}

NBK._subAddons = {}

NBK.OPTIONAL_MODULES = {
    { tag = "_ChatFilters", key = "ChatFilters", labelKey = "Chat filters" },
    { tag = "_GroupFinder", key = "GroupFinder", labelKey = "Group Finder" },
    { tag = "_Sync",        key = "Sync",        labelKey = "Sharing"      },
    { tag = "_Recents",     key = "Recents",     labelKey = "Recents"      },
    { tag = "_RememberMe",  key = "RememberMe",  labelKey = "Remember Me"  },
    { tag = "_Statistics",  key = "Statistics",  labelKey = "Statistics"   },
    { tag = "_IgnoreManager", key = "IgnoreAllChars", labelKey = "Ignore Manager" },
}

NBK.RETAIL_ONLY_MODULES = { "_GroupFinder", "_RememberMe" }

NBK.REMOVED_MODULES = {
    { tag = "_Tooltip",    reason = "merged" },
    { tag = "_Nameplates", reason = "discontinued" },
}

function NBK:ShouldShowForModule(name)
    if not name or name == "" then return true end
    for _, m in ipairs(self.OPTIONAL_MODULES) do
        if m.tag == name or m.key == name then
            return self:GetModule(m.key) ~= nil
        end
    end
    return true
end

function NBK:GetModuleLabel(name)
    if not name or name == "" then return nil end
    for _, m in ipairs(self.OPTIONAL_MODULES) do
        if m.tag == name or m.key == name then
            return (self.L and self.L[m.labelKey]) or m.labelKey
        end
    end
    return name
end

local function detectFlavor()
    local id = WOW_PROJECT_ID
    if id == (WOW_PROJECT_MAINLINE or 1)       then return "retail"  end
    if id == (WOW_PROJECT_CLASSIC or 2)        then return "era"     end
    if id == (WOW_PROJECT_MISTS_CLASSIC or 19) then return "mop"     end
    if id == (WOW_PROJECT_CAMELOT or 18)       then return "forever" end
    return "unknown"
end
NBK.FLAVOR = detectFlavor()

function NBK:GetFlavor() return self.FLAVOR end
function NBK:IsRetail()  return self.FLAVOR == "retail" end
function NBK:IsForever() return self.FLAVOR == "forever" end

function NBK:IsClassic() return self.FLAVOR ~= "retail" end

function NBK:UnitPlayer(unit)
    local name, second = UnitName(unit)
    if not self:IsForever() or not name then return name, second end
    if issecretvalue and (issecretvalue(name) or issecretvalue(second)) then
        return name, second
    end
    if type(second) == "string" and second ~= "" then
        return name .. " " .. second, nil
    end
    return name, nil
end

function NBK:PlayerName()
    return (self:UnitPlayer("player"))
end

function NBK:PlayerFullName()
    local name  = self:PlayerName()
    local realm = GetNormalizedRealmName and GetNormalizedRealmName() or GetRealmName()
    if not name or not realm then return nil end
    return name .. "-" .. realm
end

function NBK:RealmSuffix(realm)
    if not self:IsForever() then return "-" .. (realm or "") end
    if realm == nil or (issecretvalue and issecretvalue(realm)) then return "" end
    local own = GetNormalizedRealmName and GetNormalizedRealmName()
    local norm = realm:gsub("%s+", ""):lower()
    if norm == "" or not own or norm == own:lower() then return "" end
    return "-" .. realm
end

function NBK:SplitNameArg(args)
    if type(args) ~= "string" then return nil, "" end
    local quoted, rest = args:match('^%s*"([^"]+)"%s*(.*)$')
    if quoted then return quoted, rest end
    local first, after = args:match("^%s*(%S+)%s*(.*)$")
    if not first then return nil, "" end
    if self:IsForever() and not first:find("-", 1, true) then
        local second, rest2 = after:match("^(%S+)%s*(.*)$")
        if second then return first .. " " .. second, rest2 end
    end
    return first, after
end

function NBK:DisplayName(name, realm, hex)
    local shown = name or "?"
    if hex then shown = ("|cff%s%s|r"):format(hex, shown) end
    return shown .. self:RealmSuffix(realm)
end

function NBK:AddOnExists(name)
    local C = C_AddOns
    if C and C.DoesAddOnExist then
        local ok, yes = pcall(C.DoesAddOnExist, name)
        return ok and yes == true
    end
    local getInfo = (C and C.GetAddOnInfo) or GetAddOnInfo
    if not getInfo then return false end
    local ok, _, title, _, _, reason = pcall(getInfo, name)
    return ok and title ~= nil and reason ~= "MISSING"
end

function NBK:IsAddOnLoaded(name)
    local isLoaded = (C_AddOns and C_AddOns.IsAddOnLoaded) or IsAddOnLoaded
    if not isLoaded then return false end
    local ok, loaded = pcall(isLoaded, name)
    return ok and loaded and true or false
end

function NBK:IsAddOnLoadable(name)
    local getInfo = (C_AddOns and C_AddOns.GetAddOnInfo) or GetAddOnInfo
    if not getInfo then return true end
    local ok, _, _, _, loadable = pcall(getInfo, name)
    if not ok then return true end
    return loadable and true or false
end

function NBK:IsAddOnEnabled(name)
    local C, me = C_AddOns, UnitName("player")
    local ok, state
    if C and C.GetAddOnEnableState then
        ok, state = pcall(C.GetAddOnEnableState, name, me)
    elseif GetAddOnEnableState then
        ok, state = pcall(GetAddOnEnableState, me, name)
    end
    if ok and type(state) == "number" and state > 0 then return true end
    return self:IsAddOnLoaded(name)
end

local function parseGoTo(target)
    if type(target) ~= "string" then return nil end
    return target:match("^(%a+):(.+)$")
end

function NBK:CanGoTo(target)
    local where, key = parseGoTo(target)
    if where == "settings" then
        local cfg = self:GetModule("Config")
        for _, tab in ipairs(cfg and cfg._tabs or {}) do
            if tab.key == key then return true end
        end
    elseif where == "list" then
        local lw = self:GetModule("ListWindow")
        return (lw and lw.GetTabSpec and lw:GetTabSpec(key)) ~= nil
    end
    return false
end

function NBK:GoTo(target)
    if not self:CanGoTo(target) then return false end
    local where, key = parseGoTo(target)
    if where == "settings" then
        local cfg = self:GetModule("Config")
        cfg:Show()
        cfg:SelectTab(key)
    else
        local lw = self:GetModule("ListWindow")
        lw:Show()
        lw:SwitchTab(key)
    end
    return true
end

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

    if self.ForeverNames then
        local ok, err = pcall(self.ForeverNames.Run, self.ForeverNames)
        if not ok then self:Print("ForeverNames failed:", err) end
    end

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
