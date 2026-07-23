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
    if not entry then NBK:Print("could not add:", err) end
end

function handlers.remove(args)
    local target = args:match("^(%S+)")
    if not target then return usage() end
    local ok, err = NBK:RemovePlayer(target)
    if not ok then NBK:Print("could not remove:", err) end
end

handlers.rm = handlers.remove
handlers.delete = handlers.remove

function handlers.check(args)
    local target = args:match("^(%S+)")
    if not target then return usage() end
    local entry = NBK:GetPlayer(target)
    if entry then
        local color = NBK:GetClassHex(entry.class)
        NBK:Print(("|cff%s%s|r-%s - reason: %s (zone: %s)"):format(
            color, entry.name, entry.realm,
            entry.reason ~= "" and entry.reason or "-",
            entry.zone ~= "" and entry.zone or "-"))
    else
        NBK:Print("not on the list:", target)
    end
end

function handlers.list()
    local count = NBK:CountEntries()
    if count == 0 then
        NBK:Print("blacklist is empty")
        return
    end
    NBK:Print(("%d entries:"):format(count))
    for _, entry in pairs(NBK:GetEntries()) do
        local color = NBK:GetClassHex(entry.class)
        local reason = entry.reason ~= "" and entry.reason or "-"
        print(("  |cff%s%s|r-%s - %s"):format(color, entry.name, entry.realm, reason))
    end
end

function handlers.share(args)
    if not NBK:GetModule("Sync") then
        NBK:Print("share unavailable - install NerzorsBlacklistKeeper_Sync")
        return
    end
    local first = args:match("^(%S+)")
    if not first or first == "" then
        NBK:Print("usage: /nbk share <name[-realm]> | /nbk share guild | /nbk share show")
        return
    end
    local lower = first:lower()
    if lower == "guild" then
        local ok, sentOrErr = NBK:Share("GUILD")
        if not ok then NBK:Print("share failed:", sentOrErr) end
    elseif lower == "party" then
        local ok, sentOrErr = NBK:Share("PARTY")
        if not ok then NBK:Print("share failed:", sentOrErr) end
    elseif lower == "raid" then
        local ok, sentOrErr = NBK:Share("RAID")
        if not ok then NBK:Print("share failed:", sentOrErr) end
    elseif lower == "show" then
        NBK:ShowPendingShare()
    else
        local ok, sentOrErr = NBK:Share("WHISPER", first)
        if not ok then NBK:Print("share failed:", sentOrErr) end
    end
end

function handlers.theme(args)
    local NUL = LibStub("NerzorsUILib-1.0")
    local first = (args or ""):match("^(%S*)$")
    if not first or first == "" or first:lower() == "list" then
        local active = NUL:GetCurrentThemeName() or "-"
        NBK:Print(("themes (active: |cff48a8dc%s|r):"):format(active))
        for _, name in ipairs(NUL:GetThemeNames()) do
            local marker = (name == active) and "|cff48a8dc*|r " or "  "
            NBK:Print("  " .. marker .. name)
        end
        return
    end
    if not NUL:HasTheme(first) then
        NBK:Print(("unknown theme: %s (try /nbk theme list)"):format(first))
        return
    end
    local ok = NUL:SetTheme(first)
    if ok then
        NBK:Print(("theme: |cff48a8dc%s|r"):format(first))
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
        NBK:Print("unknown command:", cmd)
        return usage()
    end
    h(rest or "")
end

Slash.OnInitialize = function() end
