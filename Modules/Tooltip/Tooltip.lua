local _, NBK = ...

local Tooltip = NBK:RegisterModule("Tooltip")

local BRAND = "|cff9b59b6NBK|r"
local RED   = "|cffff6666"
local DIM   = "|cff888c99"
local MUTE  = "|cffff9955"
local WHITE = "|cffffffff"

local function settings()
    local s = NBK.db and NBK.db.settings and NBK.db.settings.tooltip
    return s or {}
end

local function on(key)
    return settings()[key] ~= false
end

local function formatDate(ts)
    if not ts then return "-" end
    return date("%d.%m.%Y", ts)
end

local function reasonLine(entry, L)
    if entry.reason and entry.reason ~= "" then
        return entry.reason
    end
    return DIM .. L["no reason logged"] .. "|r"
end

local function onTooltipSetUnit(tooltip)
    if tooltip ~= GameTooltip then return end
    if not on("enabled") then return end

    if InCombatLockdown() then return end

    if not UnitExists("mouseover") then return end
    if not UnitIsPlayer("mouseover") then return end

    local name, realm = UnitName("mouseover")
    if not name then return end
    realm = realm or GetNormalizedRealmName()

    local ok, entry = pcall(NBK.GetPlayer, NBK, name, realm)
    if not ok or not entry then return end

    if not entry.class then
        local _, classFile = UnitClass("mouseover")
        if classFile then
            entry.class = classFile
            entry.classColor = NBK:GetClassHex(classFile)
        end
    end

    local L = NBK.L

    tooltip:AddLine(" ")
    tooltip:AddDoubleLine(
        BRAND .. " " .. RED .. L["Blacklisted"] .. "|r",
        DIM .. formatDate(entry.addedAt) .. "|r",
        1, 1, 1,
        1, 1, 1)

    if on("showReason") then
        tooltip:AddLine(WHITE .. L["Reason"] .. ":|r " .. reasonLine(entry, L),
            1, 0.85, 0.85, true)
    end

    if on("showNotes") and entry.notes and entry.notes ~= "" then
        tooltip:AddLine(DIM .. L["Notes"] .. ":|r " .. entry.notes,
            0.8, 0.8, 0.85, true)
    end

    if on("showZone") and entry.zone and entry.zone ~= "" then
        tooltip:AddLine(DIM .. L["Added in"] .. ":|r " .. entry.zone,
            0.75, 0.75, 0.8, true)
    end

    if on("showEncounters") then
        local count = entry.encounterCount or 0
        if count > 0 then
            local lastTxt = entry.lastSeen and formatDate(entry.lastSeen) or "-"
            tooltip:AddLine(
                DIM .. L["Encounters"] .. ":|r " ..
                ("%d "):format(count) .. DIM .. ("(" .. L["last %s"]:format(lastTxt) .. ")|r"),
                0.75, 0.75, 0.8, false)
        end
    end

    if on("showMute") and entry.mute ~= false then
        tooltip:AddLine(MUTE .. L["Chat muted"] .. "|r",
            1, 0.6, 0.33, false)
    end

    if on("showPin") and entry.pinned then
        tooltip:AddLine(DIM .. L["Pinned"] .. "|r", 0.7, 0.7, 0.8, false)
    end

    tooltip:Show()
end

function Tooltip:OnEnable()
    if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall
       and Enum and Enum.TooltipDataType then
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, onTooltipSetUnit)
    elseif GameTooltip and GameTooltip.HookScript then
        GameTooltip:HookScript("OnTooltipSetUnit", onTooltipSetUnit)
    end
end
