local _, NBK = ...
local UI = NBK.UI

local function currentStyle()
    local s = NBK.db and NBK.db.settings and NBK.db.settings.display
                    and NBK.db.settings.display.iconStyle
    if s and NBK.CLASS_SPRITE_TEX[s] then return s end
    return NBK.CLASS_SPRITE_STYLES[1] or "classic"
end

function UI:CreateClassIcon(parent, size)
    size = 20
    local tex = parent:CreateTexture(nil, "ARTWORK")
    tex:SetSize(size, size)
    tex:Hide()

    tex._class = nil
    tex._style = nil

    function tex:SetClass(classFile, style)
        self._class = classFile
        self._style = style
        self:Refresh()
    end

    function tex:SetStyle(style)
        self._style = style
        self:Refresh()
    end

    function tex:Refresh()
        local classFile = self._class
        if not classFile or classFile == "" then
            self:Hide()
            return
        end
        local coords = NBK.CLASS_SPRITE_COORDS[classFile]
        if not coords then
            self:Hide()
            return
        end
        local style = self._style or currentStyle()
        local path = NBK.CLASS_SPRITE_TEX[style] or NBK.CLASS_SPRITE_TEX.midnight
        self:SetTexture(path)
        self:SetTexCoord(coords[1], coords[2], coords[3], coords[4])
        self:Show()
    end

    return tex
end

function NBK:GetClassDisplayName(classFile)
    if not classFile then return "" end
    local t = LOCALIZED_CLASS_NAMES_MALE or {}
    return t[classFile] or classFile
end
