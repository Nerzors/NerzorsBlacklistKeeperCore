local _, NBK = ...
local NUL = LibStub("NerzorsUILib-1.0")

local MinimapIcon = NBK:RegisterModule("MinimapIcon")

local SIZE = 32
local RADIUS = 80

local function settings()
    local s = NBK.db.settings.minimapIcon
    if type(s.angle) ~= "number" then s.angle = 225 end
    return s
end

local function updatePosition(btn)
    local angle = math.rad(settings().angle)
    local x = math.cos(angle) * RADIUS
    local y = math.sin(angle) * RADIUS
    btn:ClearAllPoints()
    btn:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

local function onUpdateDragging(btn)
    local mx, my = Minimap:GetCenter()
    if not mx then return end
    local scale = Minimap:GetEffectiveScale()
    local cx, cy = GetCursorPosition()
    cx, cy = cx / scale, cy / scale
    local angle = math.deg(math.atan2(cy - my, cx - mx))
    if angle < 0 then angle = angle + 360 end
    settings().angle = angle
    updatePosition(btn)
end

function MinimapIcon:Build()
    if self.button then return self.button end

    local btn = CreateFrame("Button", "NBKMinimapButton", Minimap)
    btn:SetSize(SIZE, SIZE)
    btn:SetFrameStrata("MEDIUM")
    btn:SetFrameLevel(8)
    btn:SetMovable(true)
    btn:SetClampedToScreen(true)
    btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    btn:RegisterForDrag("LeftButton")

    local icon = btn:CreateTexture(nil, "BACKGROUND")
    icon:SetSize(SIZE - 8, SIZE - 8)
    icon:SetPoint("CENTER")
    icon:SetTexture(NUL:GetTheme().media.logo)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    local border = btn:CreateTexture(nil, "OVERLAY")
    border:SetSize(SIZE + 20, SIZE + 20)
    border:SetPoint("CENTER", 4, -4)
    border:SetTexture(nil)

    btn:SetScript("OnClick", function(_, click)
        if click == "RightButton" then
            local cfg = NBK:GetModule("Config")
            if cfg then cfg:Toggle() end
        else
            local lw = NBK:GetModule("ListWindow")
            if lw then lw:Toggle() end
        end
    end)

    btn:SetScript("OnDragStart", function(self) self:SetScript("OnUpdate", onUpdateDragging) end)
    btn:SetScript("OnDragStop",  function(self) self:SetScript("OnUpdate", nil) end)

    btn:SetScript("OnEnter", function(self)
        local L = NBK.L
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText("|cff9b59b6" .. L["Nerzors Blacklist Keeper"] .. "|r")
        GameTooltip:AddLine((L["%d entries"]):format(NBK:CountEntries()), 1, 1, 1)

        local subs = {
            { key = "Tooltip",     label = L["Tooltip"]      or "Tooltip"      },
            { key = "ChatFilters", label = L["Chat filters"] or "Chat filters" },
            { key = "GroupFinder", label = L["Group Finder"] or "Group Finder" },
            { key = "Sync",        label = L["Sharing"]      or "Sharing"      },
            { key = "Recents",     label = L["Recents"]      or "Recents"      },
            { key = "RememberMe",  label = L["Remember Me"]  or "Remember Me"  },
        }
        local active = {}
        for _, sub in ipairs(subs) do
            if NBK:GetModule(sub.key) then active[#active + 1] = sub.label end
        end
        if #active > 0 then
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine(L["Modules"] or "Modules", 1, 0.82, 0)
            for _, label in ipairs(active) do
                GameTooltip:AddLine("  |cff5cb85c|TInterface\\Buttons\\UI-CheckBox-Check:0:0:0:0|t|r " .. label, 0.85, 0.85, 0.85)
            end
        end

        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(L["Left-click: open list"],     0.7, 0.7, 0.7)
        GameTooltip:AddLine(L["Right-click: settings"],     0.7, 0.7, 0.7)
        GameTooltip:AddLine(L["Drag: move around minimap"], 0.7, 0.7, 0.7)
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", GameTooltip_Hide)

    self.button = btn
    updatePosition(btn)
    return btn
end

function MinimapIcon:Refresh()
    self:Build()
    if settings().hide then
        self.button:Hide()
    else
        self.button:Show()
        updatePosition(self.button)
    end
end

function MinimapIcon:OnEnable()
    self:Refresh()
end
