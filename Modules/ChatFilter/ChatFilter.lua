local _, NBK = ...

local ChatFilter = NBK:RegisterModule("ChatFilter")

local HARD_FILTER_EVENTS = {
    "CHAT_MSG_SAY",
    "CHAT_MSG_YELL",
    "CHAT_MSG_EMOTE",
    "CHAT_MSG_TEXT_EMOTE",
    "CHAT_MSG_PARTY",
    "CHAT_MSG_PARTY_LEADER",
    "CHAT_MSG_RAID",
    "CHAT_MSG_RAID_LEADER",
    "CHAT_MSG_RAID_WARNING",
    "CHAT_MSG_INSTANCE_CHAT",
    "CHAT_MSG_INSTANCE_CHAT_LEADER",
    "CHAT_MSG_GUILD",
    "CHAT_MSG_OFFICER",
    "CHAT_MSG_WHISPER",
    "CHAT_MSG_CHANNEL",
}

local warned = {}

local function splitSender(sender)
    if not sender or sender == "" then return nil, nil end
    local name, realm = strsplit("-", sender, 2)
    if not name or name == "" then return nil, nil end
    if not realm or realm == "" then
        realm = GetNormalizedRealmName()
    end
    return name, realm
end

local function senderIsMuted(sender)
    local name, realm = splitSender(sender)
    if not name then return false end
    return NBK:IsMuted(name, realm)
end

local function hardFilter(_, _, _, sender)
    local settings = NBK.db and NBK.db.settings or {}
    if settings.filterChat == false then return false end
    return senderIsMuted(sender)
end

local function whisperSoftWarn(_, _, _, sender)
    local settings = NBK.db and NBK.db.settings or {}
    if settings.filterChat == false then return false end

    local name, realm = splitSender(sender)
    if not name then return false end

    local entry = NBK:GetPlayer(name, realm)
    if not entry or entry.mute ~= false then return false end

    local key = (name .. "-" .. (realm or "")):lower()
    if warned[key] then return false end
    warned[key] = true

    NBK:RecordEncounter(name, realm)

    local L = NBK.L
    local hex = NBK:GetClassHex(entry.class)
    local reason = (entry.reason and entry.reason ~= "") and entry.reason
                 or L["no reason logged"]
    NBK:Print((L["whisper from blacklisted |cff%s%s|r-%s (%s)"] )
        :format(hex, name, realm or "", reason))

    return false
end

function ChatFilter:OnEnable()
    for _, ev in ipairs(HARD_FILTER_EVENTS) do
        ChatFrame_AddMessageEventFilter(ev, hardFilter)
    end

    ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER", whisperSoftWarn)
end
