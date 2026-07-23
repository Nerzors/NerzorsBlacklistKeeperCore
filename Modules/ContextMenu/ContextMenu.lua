local _, NBK = ...

local ContextMenu = NBK:RegisterModule("ContextMenu")

local MENU_TAGS = {
    "MENU_UNIT_PLAYER",
    "MENU_UNIT_PARTY",
    "MENU_UNIT_RAID",
    "MENU_UNIT_RAID_PLAYER",
    "MENU_UNIT_TARGET",
    "MENU_UNIT_FOCUS",
    "MENU_UNIT_FRIEND",
    "MENU_UNIT_BN_FRIEND",
    "MENU_UNIT_ENEMY_PLAYER",
    "MENU_UNIT_BATTLEGROUND",
    "MENU_UNIT_ARENAENEMY",
    "MENU_UNIT_COMMUNITIES_GUILD_MEMBER",
    "MENU_UNIT_COMMUNITIES_MEMBER",
    "MENU_UNIT_CHAT_USER",
    "MENU_UNIT_CHAT_ROSTER",
    "MENU_UNIT_WHO",
}

local registered = {}

function ContextMenu:RegisterAction(spec)
    if type(spec) ~= "table" or type(spec.builder) ~= "function" then return end
    spec.order = spec.order or 50
    table.insert(registered, spec)
    table.sort(registered, function(a, b) return (a.order or 50) < (b.order or 50) end)
end

local function extractPlayer(contextData)
    if not contextData then return nil end

    local unit = contextData.unit
    if unit and UnitExists(unit) and UnitIsPlayer(unit) then
        local name, realm = UnitName(unit)
        if name then
            if not realm or realm == "" then
                realm = GetNormalizedRealmName()
            end
            return name, realm, unit
        end
    end

    local rawName = contextData.name or contextData.chatTarget
    if type(rawName) == "string" and rawName ~= "" then
        local n, r = strsplit("-", rawName, 2)
        if n and n ~= "" then
            local server = (r and r ~= "" and r)
                        or contextData.server
                        or GetNormalizedRealmName()
            return n, server, nil
        end
    end

    return nil
end

local function isOwnPlayer(name, realm)
    local me = UnitName("player")
    local myRealm = GetNormalizedRealmName() or GetRealmName() or ""
    return name == me and (realm or "") == myRealm
end

local function refreshListWindowIfOpen()
    local lw = NBK:GetModule("ListWindow")
    if lw and lw.frame and lw.frame:IsShown() then lw:Refresh() end
end

ContextMenu.RefreshListWindow = refreshListWindowIfOpen

local function buildCoreBlacklistActions(rootDescription, name, realm, unit, contextData)
    local L = NBK.L

    if NBK:IsBlacklisted(name, realm) then
        local entry = NBK:GetPlayer(name, realm)
        rootDescription:CreateButton(L["Edit blacklist entry"], function()
            local lw = NBK:GetModule("ListWindow")
            if lw then
                lw:Build()
                lw:ShowEditDialog(entry)
            end
        end)

        if NBK:GetModule("Sync") then
            local shareLabel
            if entry.shareable == false then
                shareLabel = L["Mark shareable"] or "Mark shareable"
            else
                shareLabel = L["Mark private"] or "Mark private"
            end
            rootDescription:CreateButton(shareLabel, function()
                NBK:UpdateEntry(name, realm, { shareable = not (entry.shareable ~= false) })
                refreshListWindowIfOpen()
            end)
        end
        rootDescription:CreateButton(L["Remove from blacklist"], function()
            NBK:RemovePlayer(name, realm)
            refreshListWindowIfOpen()
        end)
    else
        rootDescription:CreateButton(L["Add to blacklist"], function()
            NBK:AddPlayer(name, realm, nil, unit)
            refreshListWindowIfOpen()
        end)
        rootDescription:CreateButton(L["Add to blacklist with reason..."], function()
            local lw = NBK:GetModule("ListWindow")
            if lw then

                local class = NBK.ResolveClass and NBK:ResolveClass(name, realm, unit) or nil
                lw:ShowAddDialog({
                    name  = name .. "-" .. realm,
                    class = class,
                })
            end
        end)
    end
end

local function injectMenu(owner, rootDescription, contextData)
    local name, realm, unit = extractPlayer(contextData)
    if not name then return end
    if isOwnPlayer(name, realm) then return end

    rootDescription:CreateDivider()
    rootDescription:CreateTitle("|cff9b59b6NBK|r")

    for _, action in ipairs(registered) do
        local ok, err = pcall(action.builder, rootDescription, name, realm, unit, contextData)
        if not ok then geterrorhandler()(err) end
    end
end

function ContextMenu:OnEnable()

    self:RegisterAction({
        key     = "core_blacklist",
        order   = 10,
        builder = buildCoreBlacklistActions,
    })

    if not Menu or not Menu.ModifyMenu then
        NBK:Print("ContextMenu disabled - Menu.ModifyMenu unavailable")
        return
    end
    for _, tag in ipairs(MENU_TAGS) do
        Menu.ModifyMenu(tag, injectMenu)
    end
end
