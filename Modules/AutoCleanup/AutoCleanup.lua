local _, NBK = ...

local AutoCleanup = NBK:RegisterModule("AutoCleanup")

local SECONDS_PER_MONTH = 30 * 24 * 60 * 60

local function cutoff(months)
    return time() - (months or 6) * SECONDS_PER_MONTH
end

function AutoCleanup:CountStale(months)
    local c = 0
    local t = cutoff(months)
    for _, e in pairs(NBK:GetEntries()) do
        if not e.pinned then
            local ref = e.lastSeen or e.addedAt or 0
            if ref > 0 and ref < t then c = c + 1 end
        end
    end
    return c
end

function AutoCleanup:Prune(months)
    local entries = NBK:GetEntries()
    if not entries then return 0 end

    local t = cutoff(months)
    local victims = {}
    for key, e in pairs(entries) do
        if not e.pinned then
            local ref = e.lastSeen or e.addedAt or 0
            if ref > 0 and ref < t then victims[#victims + 1] = key end
        end
    end

    for _, key in ipairs(victims) do entries[key] = nil end

    local lw = NBK:GetModule("ListWindow")
    if lw and lw.Refresh then lw:Refresh() end

    return #victims
end

local function maybeRunOnLogin()
    local settings = NBK.db and NBK.db.settings or {}
    local cfg = settings.autoCleanup or {}
    if cfg.enabled ~= true then return end

    local months = tonumber(cfg.months) or 6
    if months < 1 then months = 1 end

    local removed = AutoCleanup:Prune(months)
    if removed > 0 then
        local L = NBK.L
        NBK:Print((L["Auto-cleanup: removed %d stale entries (older than %d months)."])
            :format(removed, months))
    end
end

function AutoCleanup:OnEnable()

    if C_Timer and C_Timer.After then
        C_Timer.After(1, maybeRunOnLogin)
    else
        maybeRunOnLogin()
    end
end
