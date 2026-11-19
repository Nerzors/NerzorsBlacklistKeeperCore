-- Nerzors Blacklist Keeper - Public API  (LibNBKApi-1.0)
--
-- A STABLE, versioned read surface for *other addons* (Plater scripts,
-- WeakAuras, custom UI, third-party tools) to query NBK's lists and react
-- to changes. Unlike the internal NBK namespace (Core/API.lua) - which
-- moves around as the addon is refactored - everything here is a
-- guaranteed-stable contract: function names and signatures only ever
-- change with a MAJOR version bump.
--
-- ─── How to access it ──────────────────────────────────────────────────
--
--   -- Preferred: via LibStub (works even without the _G.NBK global)
--   local NBKApi = LibStub and LibStub("LibNBKApi-1.0", true)
--   if NBKApi then
--       if NBKApi:IsUnitBlacklisted("mouseover") then ... end    -- MINOR 2
--       if NBKApi:IsBlacklisted("Jaina", "Stormrage") then ... end
--   end
--
--   -- Also exposed on the namespace for in-tree code:
--   _G.NBK.API
--
-- Always guard with `if NBKApi then` - the user may not have NBK installed.
--
-- ─── Versioning ────────────────────────────────────────────────────────
--
--   NBKApi.VERSION  -> number    Current MINOR. Additive changes (new
--                                functions / events) bump MINOR; nothing
--                                existing breaks. A breaking change would
--                                ship as LibNBKApi-2.0.
--
--     MINOR 1  name queries, iterators, events
--     MINOR 2  unit queries (Is/GetUnit...), FromUnitName, WoW: Forever
--              names from a unit work in the name queries too (NBK 2.3.0)
--
--   Check before using a newer function:
--     if NBKApi.VERSION >= 2 then ... NBKApi:IsUnitBlacklisted(unit) ... end
--
-- ─── Read surface ──────────────────────────────────────────────────────
--
--   All name lookups normalize case + trim realm whitespace, so
--   "Jaina-Stormrage", "jaina-stormrage " resolve the same. `realm` is
--   optional everywhere; omitted = the player's current realm.
--
--   Have a unit token ("target", "mouseover", "party1", ...)? Use the
--   unit queries: they read the name the way NBK's own tooltip does, on
--   every client. A unit that doesn't exist, isn't a player, or whose name
--   the game keeps secret (Retail instances) gives false / nil, never an
--   error.
--
--   Every entry returned is a SHALLOW COPY - mutating it does NOT touch
--   NBK's database. Treat them as read-only snapshots.
--
--   Blacklist (always available):
--     NBKApi:IsBlacklisted(name, realm)      -> boolean
--     NBKApi:IsMuted(name, realm)            -> boolean   (blacklisted + mute flag)
--     NBKApi:GetBlacklistEntry(name, realm)  -> entry | nil
--     NBKApi:IsUnitBlacklisted(unit)         -> boolean        (MINOR 2)
--     NBKApi:IsUnitMuted(unit)               -> boolean        (MINOR 2)
--     NBKApi:GetUnitBlacklistEntry(unit)     -> entry | nil    (MINOR 2)
--     NBKApi:CountBlacklist()                -> number
--     NBKApi:IterateBlacklist()              -> iterator → (key, entry)
--
--   Remember Me (sub-addon; calls degrade to nil/false/empty if absent):
--     NBKApi:IsRemembered(name, realm)       -> boolean
--     NBKApi:GetRememberEntry(name, realm)   -> entry | nil
--     NBKApi:IsUnitRemembered(unit)          -> boolean        (MINOR 2)
--     NBKApi:GetUnitRememberEntry(unit)      -> entry | nil    (MINOR 2)
--     NBKApi:IterateRemembered()             -> iterator → (key, entry)
--
--   Names:
--     NBKApi:FromUnitName(name, realm)       -> name, realm    (MINOR 2)
--         See "Names on WoW: Forever" below.
--
--   Recents (sub-addon; same graceful degradation):
--     NBKApi:IsRecent(name, realm)           -> boolean
--     NBKApi:GetRecents()                    -> array of entry copies
--
--   Blacklist entry shape:
--     { name, realm, class, classColor, addedAt, zone, reason, notes,
--       mute, shareable, addedBy, lastSeen, encounterCount, pinned }
--
-- ─── Names on WoW: Forever ─────────────────────────────────────────────
--
--   Every character on WoW: Forever has a first and a second name. NBK
--   stores such a player as name = "Freyja Runa" (with the space) and
--   realm = the server ID ("CAMWOWEU5Realm3PvE"); NBK hides that ID in
--   its own lists.
--
--   UnitName / UnitFullName return the two names separately there -
--   ("Freyja", "Runa"), the second one where other clients put the realm -
--   and IDs built from them read "Freyja-Runa". Since MINOR 2 you don't
--   have to care:
--     * the unit queries read the unit the right way themselves;
--     * the name queries accept that form too: ("Freyja", "Runa"),
--       "Freyja-Runa", ("Freyja Runa", "CAMWOWEU5Realm3PvE") and
--       "Freyja Runa" all find the same player.
--   The rule: on WoW: Forever, a "realm" without digits is a second name
--   (a server ID always has digits). On every other client nothing
--   changes.
--
--   NBKApi:FromUnitName(name, realm) applies that rule and hands the result
--   back, for your own display or comparisons:
--     NBKApi:FromUnitName("Freyja", "Runa")  -> "Freyja Runa", nil
--     NBKApi:FromUnitName("Freyja-Runa")     -> "Freyja Runa", nil
--     NBKApi:FromUnitName("Jaina", "Stormrage") -> "Jaina", "Stormrage"
--   A nil realm means "this server".
--
-- ─── Events (CallbackHandler-1.0) ──────────────────────────────────────
--
--   NBKApi:RegisterCallback(event, handler[, arg])
--   NBKApi:UnregisterCallback(event)
--   NBKApi:UnregisterAllCallbacks()
--
--   `handler` is either a function or a "methodName" string on `arg`.
--   The first value passed to the handler is always the event name.
--
--   Events:
--     "BLACKLIST_ENTRY_ADDED"   (event, name, realm, entry)
--     "BLACKLIST_ENTRY_REMOVED" (event, name, realm)
--     "BLACKLIST_ENTRY_CHANGED" (event, name, realm, entry)
--     "BLACKLIST_CHANGED"       (event)
--         Coarse "the list changed somehow" - fired alongside each of the
--         three per-entry events AND once after a bulk import / reset
--         (where per-entry events would be spammy). Register just this
--         one if you only need "re-read everything now".
--
--   Example:
--     NBKApi:RegisterCallback("BLACKLIST_ENTRY_ADDED",
--         function(_, name, realm, entry)
--             print(name, "blacklisted:", entry.reason)
--         end)

local _, NBK = ...

local LibStub = _G.LibStub
if not LibStub then
    -- No LibStub → no Public API. The addon itself still works fully;
    -- only third-party integration is unavailable.
    NBK:Print("|cffff5555LibStub missing - Public API (LibNBKApi-1.0) disabled.|r")
    return
end

local MAJOR, MINOR = "LibNBKApi-1.0", 2
local Api = LibStub:NewLibrary(MAJOR, MINOR)
if not Api then return end  -- a same-or-newer copy is already registered

NBK.API     = Api
Api.VERSION = MINOR

-- Event registry. CallbackHandler-1.0 ships in NerzorsBlacklistKeeper_Data.
-- If it's somehow missing, the read surface still works - only events go
-- dark (RegisterCallback would be nil; _FireApiEvent no-ops).
local CallbackHandler = LibStub:GetLibrary("CallbackHandler-1.0", true)
if CallbackHandler then
    Api.callbacks = Api.callbacks or CallbackHandler:New(Api)
end

-- Shallow copy: entries are flat records, so one level is enough. Handing
-- out copies keeps external addons from mutating the live DB by accident.
local function copyEntry(e)
    if type(e) ~= "table" then return nil end
    local c = {}
    for k, v in pairs(e) do c[k] = v end
    return c
end

-- Generic "iterate a key→entry table, yielding copies" factory.
local function copyingIterator(src)
    src = src or {}
    local k
    return function()
        local entry
        k, entry = next(src, k)
        if k == nil then return nil end
        return k, copyEntry(entry)
    end
end

-- ─── Names (MINOR 2) ───────────────────────────────────────────────────
-- Every name query below goes through NBK:FromUnitName first (Core/Core.lua):
-- on WoW: Forever a name taken from a unit ("Freyja", "Runa" or
-- "Freyja-Runa") becomes the stored form "Freyja Runa"; anything else, and
-- every other client, is passed on unchanged (2.3.0 A1, I25).

function Api:FromUnitName(name, realm)
    return NBK:FromUnitName(name, realm)
end

-- Runs fn(name, realm) for a player unit, the way NBK's own tooltip reads
-- it (NBK:UnitPlayer). nil for a missing unit, a non-player, or a value the
-- game keeps secret (Retail instances): those raise inside the lookup,
-- which the pcall turns into "not found".
local function withUnit(unit, fn)
    if type(unit) ~= "string" then return nil end
    local ok, result = pcall(function()
        if not UnitExists(unit) or not UnitIsPlayer(unit) then return nil end
        local name, realm = NBK:UnitPlayer(unit)
        if not name then return nil end
        return fn(name, realm)
    end)
    if ok then return result end
    return nil
end

-- ─── Blacklist (core - always available) ───────────────────────────────

function Api:IsBlacklisted(name, realm)
    return NBK:IsBlacklisted(NBK:FromUnitName(name, realm)) and true or false
end

function Api:IsMuted(name, realm)
    return NBK:IsMuted(NBK:FromUnitName(name, realm)) and true or false
end

function Api:GetBlacklistEntry(name, realm)
    return copyEntry(NBK:GetPlayer(NBK:FromUnitName(name, realm)))
end

function Api:IsUnitBlacklisted(unit)
    return withUnit(unit, function(n, r) return NBK:IsBlacklisted(n, r) end) and true or false
end

function Api:IsUnitMuted(unit)
    return withUnit(unit, function(n, r) return NBK:IsMuted(n, r) end) and true or false
end

function Api:GetUnitBlacklistEntry(unit)
    return copyEntry(withUnit(unit, function(n, r) return NBK:GetPlayer(n, r) end))
end

function Api:CountBlacklist()
    return NBK:CountEntries()
end

function Api:IterateBlacklist()
    return copyingIterator(NBK:GetEntries())
end

-- ─── Remember Me (sub-addon - degrades gracefully when not installed) ──

local function rememberMeModule()
    local rm = NBK:GetModule("RememberMe")
    return (rm and rm.GetEntries) and rm or nil
end

function Api:IsRemembered(name, realm)
    local rm = rememberMeModule()
    return (rm and rm.HasEntry and rm:HasEntry(NBK:FromUnitName(name, realm))) and true or false
end

function Api:GetRememberEntry(name, realm)
    local rm = rememberMeModule()
    if not rm or not rm.GetEntry then return nil end
    return copyEntry(rm:GetEntry(NBK:FromUnitName(name, realm)))
end

function Api:IsUnitRemembered(unit)
    local rm = rememberMeModule()
    if not rm or not rm.HasEntry then return false end
    return withUnit(unit, function(n, r) return rm:HasEntry(n, r) end) and true or false
end

function Api:GetUnitRememberEntry(unit)
    local rm = rememberMeModule()
    if not rm or not rm.GetEntry then return nil end
    return copyEntry(withUnit(unit, function(n, r) return rm:GetEntry(n, r) end))
end

function Api:IterateRemembered()
    local rm = rememberMeModule()
    return copyingIterator(rm and rm:GetEntries())
end

-- ─── Recents (sub-addon - same graceful degradation) ───────────────────

local function recentsModule()
    local r = NBK:GetModule("Recents")
    return (r and r.GetEntries) and r or nil
end

function Api:IsRecent(name, realm)
    local r = recentsModule()
    return (r and r.HasEntry and r:HasEntry(name, realm)) and true or false
end

-- Recents:GetEntries() is an ARRAY (most-recent ordering), not a keyed
-- table - return an array of copies to preserve that order.
function Api:GetRecents()
    local r = recentsModule()
    local src = (r and r:GetEntries()) or {}
    local out = {}
    for i, e in ipairs(src) do out[i] = copyEntry(e) end
    return out
end

-- ─── Internal event bridge ─────────────────────────────────────────────
-- Called from Core/API.lua (Add/Remove/Update) and Core/Serializer.lua
-- (bulk import/reset). Kept on the NBK namespace - not the public Api -
-- so external addons can't fire fake events. API.lua guards every call
-- with `if self._FireApiEvent then` so it's safe even if this file fails
-- to load (no LibStub, etc.).
function NBK:_FireApiEvent(event, name, realm, entry)
    if not Api.callbacks then return end
    if entry then
        Api.callbacks:Fire(event, name, realm, copyEntry(entry))
    elseif name then
        Api.callbacks:Fire(event, name, realm)
    else
        Api.callbacks:Fire(event)
    end
    -- Any per-entry blacklist event also fires the coarse "list changed".
    if event ~= "BLACKLIST_CHANGED" then
        Api.callbacks:Fire("BLACKLIST_CHANGED")
    end
end
