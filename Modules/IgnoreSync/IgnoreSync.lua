local _, NBK = ...
local NUL = LibStub("NerzorsUILib-1.0")

local IgnoreSync = NBK:RegisterModule("IgnoreSync")

local function api()
    local C = C_FriendList
    if C and C.AddIgnore and C.DelIgnore and C.GetNumIgnores and C.GetIgnoreName then
        return C
    end
end

local function ignoreName(name, realm)
    if type(name) ~= "string" or #name == 0 then return nil end
    local own = GetNormalizedRealmName and GetNormalizedRealmName() or GetRealmName()
    if type(realm) ~= "string" or #realm == 0 or realm == own then return name end
    return name .. "-" .. realm
end

local function splitIgnore(full)
    if type(full) ~= "string" then return nil end
    local name, realm = full:match("^([^%-]+)%-(.+)$")
    if name then return name, realm end
    return full, nil
end

function IgnoreSync:IsAvailable()
    return api() ~= nil
end

function IgnoreSync:GetIgnoreList()
    local C, out = api(), {}
    if not C then return out end
    for i = 1, (C.GetNumIgnores() or 0) do
        local n = C.GetIgnoreName(i)
        if type(n) == "string" and #n > 0 then out[#out + 1] = n end
    end
    return out
end

function IgnoreSync:IsIgnored(name, realm)
    local C    = api()
    local full = ignoreName(name, realm)
    if not C or not full then return false end
    if C.IsIgnored then return C.IsIgnored(full) and true or false end

    for _, n in ipairs(self:GetIgnoreList()) do
        if n == full then return true end
    end
    return false
end

function IgnoreSync:GetUntracked()
    local out = {}
    for _, full in ipairs(self:GetIgnoreList()) do
        local name, realm = splitIgnore(full)
        if name and not NBK:IsBlacklisted(name, realm) then
            out[#out + 1] = { full = full, name = name, realm = realm }
        end
    end
    return out
end

IgnoreSync._pending = {}

function IgnoreSync:_VerifyPending()
    if not next(self._pending) then return end
    local present = {}
    for _, n in ipairs(self:GetIgnoreList()) do present[n] = true end

    local missed = 0
    for full in pairs(self._pending) do
        if present[full] then
            self._pending[full] = nil
        else
            missed = missed + 1
        end
    end
    if missed == 0 or self._warnedFull then return end

    self._warnedFull = true
    self._listFull   = true
    wipe(self._pending)
    local msg = "Your ignore list is full - those players stay on the blacklist, " ..
                "but the game won't ignore them."
    NBK:Print("|cffff5555" .. (NBK.L[msg] or msg) .. "|r")
end

function IgnoreSync:Add(name, realm)
    local C    = api()
    local full = ignoreName(name, realm)
    if not C or not full or self._listFull then return false end
    if self:IsIgnored(name, realm) then return true end

    self._pending[full] = true
    C.AddIgnore(full)

    if C_Timer and C_Timer.After then
        C_Timer.After(2, function() self:_VerifyPending() end)
    end
    return true
end

function IgnoreSync:Remove(name, realm)
    local C    = api()
    local full = ignoreName(name, realm)
    if not C or not full then return false end
    self._pending[full] = nil
    C.DelIgnore(full)
    return true
end

function IgnoreSync:OnEntryAdded(entry)
    if not entry or not self:IsAvailable() then return end
    local s = NBK.db and NBK.db.settings or {}
    if not s.autoIgnore then return end

    if entry.mute == false then return end
    if self:IsIgnored(entry.name, entry.realm) then return end
    if self:Add(entry.name, entry.realm) then
        entry.ignoredByNBK = true
    end
end

function IgnoreSync:OnEntryRemoved(entry)
    if not entry or not self:IsAvailable() then return end
    if not entry.ignoredByNBK then return end
    self:Remove(entry.name, entry.realm)
end

function IgnoreSync:_BuildImport()
    if self._importFrame then return self._importFrame end
    local L = NBK.L

    local f = NUL:Window({
        name   = "NBKIgnoreImportWindow",
        title  = L["Import from ignore list"] or "Import from ignore list",
        width  = 420, height = 440,
        strata = "DIALOG",
    })
    f:SetPositionKey("IgnoreImport", NBK.db)
    f:RestorePosition()

    local hint = NUL:CreateLabel(f.content, {
        text  = L["Pick the ignored players you want on your blacklist."]
             or "Pick the ignored players you want on your blacklist.",
        size  = "sm",
        color = NUL:GetTheme().colors.text.muted,
    })
    hint:SetPoint("TOPLEFT")
    hint:SetPoint("TOPRIGHT")

    local host = CreateFrame("Frame", nil, f.content)
    host:SetPoint("TOPLEFT",     0, -24)
    host:SetPoint("BOTTOMRIGHT", 0,  34)

    self._candidates = {}
    self._list = NUL:MultiSelectList(host, {
        get           = function() return self._candidates end,
        addable       = false,
        newDefaultsOn = true,
    })

    local importBtn = NUL:Button(f.content, {
        label = L["Import"] or "Import",
        width = 130, height = 26, style = "accent",
        onClick = function() self:_DoImport() end,
    })
    importBtn:SetPoint("BOTTOMRIGHT", 0, 0)

    local cancelBtn = NUL:Button(f.content, {
        label = L["Cancel"] or "Cancel",
        width = 110, height = 26,
        onClick = function() f:Hide() end,
    })
    cancelBtn:SetPoint("BOTTOMRIGHT", importBtn, "BOTTOMLEFT", -6, 0)

    self._importFrame = f
    return f
end

function IgnoreSync:_DoImport()
    local keys = self._list and self._list:GetSelectedKeys() or {}
    local added = 0
    for _, full in ipairs(keys) do
        local name, realm = splitIgnore(full)
        if name and not NBK:IsBlacklisted(name, realm) then
            local entry = NBK:AddPlayer(name, realm,
                NBK.L["Imported from ignore list"] or "Imported from ignore list")
            if entry then

                entry.ignoredByNBK = false
                added = added + 1
            end
        end
    end
    if self._importFrame then self._importFrame:Hide() end

    NBK:Print((NBK.L["Imported %d player(s) from the ignore list."]
        or "Imported %d player(s) from the ignore list."):format(added))

    local lw = NBK:GetModule("ListWindow")
    if lw and lw.Refresh then lw:Refresh() end
end

function IgnoreSync:ShowImport()
    if not self:IsAvailable() then
        NBK:Print(NBK.L["The ignore list isn't available on this client."]
            or "The ignore list isn't available on this client.")
        return
    end

    local untracked = self:GetUntracked()
    if #untracked == 0 then
        NBK:Print(NBK.L["Nothing to import - every ignored player is already on your blacklist."]
            or "Nothing to import - every ignored player is already on your blacklist.")
        return
    end

    self:_BuildImport()
    wipe(self._candidates)
    for _, rec in ipairs(untracked) do
        self._candidates[#self._candidates + 1] = { key = rec.full, enabled = true }
    end
    self._list:Refresh()
    self._importFrame:Show()
end

function IgnoreSync:OnEnable()
    if not self:IsAvailable() then return end

    NBK:RegisterEvent("IGNORELIST_CHANGED", function()
        if self._importFrame and self._importFrame:IsShown() then
            self:ShowImport()
        end
    end)
end
