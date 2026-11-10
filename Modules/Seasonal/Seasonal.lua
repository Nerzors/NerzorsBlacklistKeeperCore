local _, NBK = ...
local NUL = LibStub("NerzorsUILib-1.0")

local Seasonal = NBK:RegisterModule("Seasonal")

local TEX = "Interface\\AddOns\\NerzorsBlacklistKeeper_Data\\Textures\\seasonal\\"

local BUTTON = { h = 12, lift = 8,  capOut = 2, stripIn = 6,  sublevel = 6 }
local WINDOW = { h = 20, lift = 14, capOut = 3, stripIn = 10, sublevel = 5 }

function Seasonal:inDecember()
    local t = date("*t")
    return t ~= nil and t.month == 12
end

function Seasonal:IsActive()
    local s = NBK.db and NBK.db.settings
    if not s or (s.display and s.display.seasonalDecor == false) then return false end
    return self._force == "xmas" or Seasonal:inDecember()
end

local function mainWindow()
    local lw = NBK:GetModule("ListWindow")
    return lw and lw.frame
end

local function inMainWindow(frame)
    local root = mainWindow()
    local p = root and frame:GetParent()
    while p do
        if p == root then return true end
        p = p:GetParent()
    end
    return false
end

local function buildSnow(host, edge, d)
    local mid = host:CreateTexture(nil, "OVERLAY", nil, d.sublevel)
    mid:SetTexture(TEX .. "snow-cap.png", "REPEAT", "CLAMP")
    mid:SetPoint("TOPLEFT", edge, "TOPLEFT", d.stripIn, d.lift)
    mid:SetPoint("TOPRIGHT", edge, "TOPRIGHT", -d.stripIn, d.lift)
    mid:SetHeight(d.h)

    local left = host:CreateTexture(nil, "OVERLAY", nil, d.sublevel + 1)
    left:SetTexture(TEX .. "snow-cap-end.png")
    left:SetSize(d.h, d.h)
    left:SetPoint("TOPLEFT", edge, "TOPLEFT", -d.capOut, d.lift)

    local right = host:CreateTexture(nil, "OVERLAY", nil, d.sublevel + 1)
    right:SetTexture(TEX .. "snow-cap-end.png")
    right:SetTexCoord(1, 0, 0, 1)
    right:SetSize(d.h, d.h)
    right:SetPoint("TOPRIGHT", edge, "TOPRIGHT", d.capOut, d.lift)

    local tileW  = d.h * 512 / 32
    local offset = math.random()
    local function fit()
        local w = math.max(0, edge:GetWidth() - 2 * d.stripIn)
        mid:SetTexCoord(offset, offset + w / tileW, 0, 1)
    end
    edge:HookScript("OnSizeChanged", fit)
    fit()
    return { mid, left, right }
end

local function show(list, on)
    for _, tex in ipairs(list or {}) do tex:SetShown(on) end
end

local function decorateButton(b)
    local on = Seasonal:IsActive() and inMainWindow(b)
    if on and not b._nbkSnow then b._nbkSnow = buildSnow(b, b, BUTTON) end
    show(b._nbkSnow, on)
end

local function decorateWindow()
    local f = mainWindow()
    if not (f and f.titleBar) then return end
    local on = Seasonal:IsActive()
    if on and not f._nbkSnow then f._nbkSnow = buildSnow(f.titleBar, f, WINDOW) end
    show(f._nbkSnow, on)
end

function Seasonal:Refresh()
    decorateWindow()
    NUL:ApplyButtonDecor()
end

function Seasonal:OnEnable()
    NUL:SetButtonDecor(decorateButton)

    local lw = NBK:GetModule("ListWindow")
    if lw and lw.Show then
        hooksecurefunc(lw, "Show", function() Seasonal:Refresh() end)
    end
end
