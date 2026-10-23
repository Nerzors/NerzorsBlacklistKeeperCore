local _, NBK = ...

local Slash = NBK:RegisterModule("SlashCommands")

local function usage()
    local L = NBK.L
    NBK:Print("|cffffd100" .. L["/nbk (no args) - open window"] .. "|r")
    NBK:Print("|cffffd100" .. L["/nbk config - open settings"] .. "|r")
    NBK:Print("|cffffd100/nbk add|r <name[-realm]> [reason]")
    NBK:Print("|cffffd100/nbk remove|r <name[-realm]>")
    NBK:Print("|cffffd100/nbk check|r <name[-realm]>")
    NBK:Print("|cffffd100/nbk list|r")

    if NBK:GetModule("Sync") then
        NBK:Print("|cffffd100/nbk share|r <name[-realm]> |cff888c99" .. (L["share via whisper"] or "share via whisper") .. "|r")
        NBK:Print("|cffffd100/nbk share guild|r |cff888c99" .. (L["broadcast to guild"] or "broadcast to guild") .. "|r")
    end

    NBK:Print("|cffffd100/nbk theme|r |cff888c99[Name] | list|r")
    NBK:Print("|cffffd100/nbk news|r |cff888c99" .. (L["show 'What's new?'"] or "show 'What's new?'") .. "|r")

end

local handlers = {}

function handlers.show()
    local lw = NBK:GetModule("ListWindow")
    if lw then lw:Show() else NBK:Print("ListWindow module not loaded") end
end

handlers.open   = handlers.show
handlers.toggle = function()
    local lw = NBK:GetModule("ListWindow")
    if lw then lw:Toggle() end
end

function handlers.config()
    local cfg = NBK:GetModule("Config")
    if cfg then cfg:Toggle() else NBK:Print("Config module not loaded") end
end
handlers.options  = handlers.config
handlers.settings = handlers.config

function handlers.add(args)
    local target, rest = args:match("^(%S+)%s*(.*)$")
    if not target then return usage() end
    local entry, err = NBK:AddPlayer(target, nil, rest ~= "" and rest or nil)

    if not entry then NBK:Print(NBK.L["could not add:"], NBK.L[err]) end
end

function handlers.remove(args)
    local target = args:match("^(%S+)")
    if not target then return usage() end
    local ok, err = NBK:RemovePlayer(target)
    if not ok then NBK:Print(NBK.L["could not remove:"], NBK.L[err]) end
end

handlers.rm = handlers.remove
handlers.delete = handlers.remove

function handlers.check(args)
    local target = args:match("^(%S+)")
    if not target then return usage() end
    local L = NBK.L
    local entry = NBK:GetPlayer(target)
    if entry then
        local color = NBK:GetClassHex(entry.class)
        local details = L["reason: %s (zone: %s)"]:format(
            entry.reason ~= "" and entry.reason or "-",
            entry.zone ~= "" and entry.zone or "-")
        NBK:Print(("|cff%s%s|r-%s - %s"):format(color, entry.name, entry.realm, details))
    else
        NBK:Print(L["not on the list:"], target)
    end
end

function handlers.list()
    local L = NBK.L
    local count = NBK:CountEntries()
    if count == 0 then
        NBK:Print(L["blacklist is empty"])
        return
    end
    NBK:Print(L["%d entries:"]:format(count))
    for _, entry in pairs(NBK:GetEntries()) do
        local color = NBK:GetClassHex(entry.class)
        local reason = entry.reason ~= "" and entry.reason or "-"
        print(("  |cff%s%s|r-%s - %s"):format(color, entry.name, entry.realm, reason))
    end
end

function handlers.share(args)
    local L = NBK.L
    if not NBK:GetModule("Sync") then
        NBK:Print(L["share unavailable - install NerzorsBlacklistKeeper_Sync"])
        return
    end
    local first = args:match("^(%S+)")
    if not first or first == "" then
        NBK:Print(L["usage:"], "/nbk share <name[-realm]> | /nbk share guild | /nbk share show")
        return
    end
    local lower = first:lower()
    local ok, sentOrErr
    if lower == "guild" then
        ok, sentOrErr = NBK:Share("GUILD")
    elseif lower == "party" then
        ok, sentOrErr = NBK:Share("PARTY")
    elseif lower == "raid" then
        ok, sentOrErr = NBK:Share("RAID")
    elseif lower == "show" then
        return NBK:ShowPendingShare()
    else
        ok, sentOrErr = NBK:Share("WHISPER", first)
    end
    if not ok then NBK:Print(L["share failed:"], L[sentOrErr]) end
end

function handlers.theme(args)
    local NUL = LibStub("NerzorsUILib-1.0")
    local L = NBK.L
    local first = (args or ""):match("^(%S*)$")
    if not first or first == "" or first:lower() == "list" then
        local active = NUL:GetCurrentThemeName() or "-"
        NBK:Print(L["themes (active: %s):"]:format("|cff48a8dc" .. active .. "|r"))
        for _, name in ipairs(NUL:GetThemeNames()) do
            local marker = (name == active) and "|cff48a8dc*|r " or "  "
            NBK:Print("  " .. marker .. name)
        end
        return
    end
    if not NUL:HasTheme(first) then
        NBK:Print(L["unknown theme: %s (try /nbk theme list)"]:format(first))
        return
    end
    local ok = NUL:SetTheme(first)
    if ok then
        NBK:Print(L["theme: %s"]:format("|cff48a8dc" .. first .. "|r"))
    end
end

function handlers.news()
    local news = NBK:GetModule("News")
    if news and news.Show then
        news:Show()
    else
        NBK:Print("news module not loaded")
    end
end
handlers.whatsnew = handlers.news

function handlers.help() usage() end

SLASH_NBK1 = "/nbk"
SLASH_NBK2 = "/blacklistkeeper"
SlashCmdList.NBK = function(msg)
    msg = msg or ""
    local cmd, rest = msg:match("^(%S*)%s*(.*)$")
    cmd = (cmd or ""):lower()
    if cmd == "" then return handlers.show() end
    local h = handlers[cmd]
    if not h then
        NBK:Print(NBK.L["unknown command:"], cmd)
        return usage()
    end
    h(rest or "")
end

Slash.OnInitialize = function() end
