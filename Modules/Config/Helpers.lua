local _, NBK = ...
local Config = NBK:GetModule("Config")
if not Config then return end

local NUL = LibStub("NerzorsUILib-1.0")

function Config:Settings()
    return NBK.db and NBK.db.settings or {}
end

function Config:SetPath(path, value)
    local t = self:Settings()
    for i = 1, #path - 1 do
        if type(t[path[i]]) ~= "table" then t[path[i]] = {} end
        t = t[path[i]]
    end
    t[path[#path]] = value
end

function Config:GetPath(path, default)
    local t = self:Settings()
    for i = 1, #path - 1 do
        t = t and t[path[i]]
    end
    if not t then return default end
    local v = t[path[#path]]
    if v == nil then return default end
    return v
end

function Config:RefreshList()
    local lw = NBK:GetModule("ListWindow")
    if lw and lw.RebuildLayout then lw:RebuildLayout() end
end

function Config:RefreshListData()
    local lw = NBK:GetModule("ListWindow")
    if lw and lw.Refresh then lw:Refresh() end
end

function Config:RefreshMinimap()
    local mm = NBK:GetModule("MinimapIcon")
    if mm and mm.Refresh then mm:Refresh() end
end

function Config:RefreshAddDialogPills()
    local lw = NBK:GetModule("ListWindow")
    if lw and lw.RefreshAddDialogPills then lw:RefreshAddDialogPills() end
end

function Config:AddCheckboxRow(parent, y, labelKey, path, defaultVal, onChanged)
    local L = NBK.L
    local cb = NUL:Checkbox(parent, {
        label   = L[labelKey],
        checked = self:GetPath(path, defaultVal) and true or false,
        onChange = function(v)
            Config:SetPath(path, v and true or false)
            if onChanged then onChanged(v) end
        end,
    })
    cb:SetPoint("TOPLEFT", 0, y)
    return cb, y - 26
end

function Config:AddSectionLabel(parent, y, textKey)
    local L = NBK.L
    local theme = NUL:GetTheme()
    local fs = NUL:CreateLabel(parent, {
        text  = L[textKey] or textKey,
        size  = "lg",
        color = theme.colors.accent.primary,
    })
    fs:SetPoint("TOPLEFT", 0, y)
    return fs, y - 22
end

function Config:AddDivider(parent, y)
    local theme = NUL:GetTheme()
    local tex = parent:CreateTexture(nil, "ARTWORK")
    tex:SetHeight(1)
    tex:SetPoint("TOPLEFT",  0, y)
    tex:SetPoint("TOPRIGHT", 0, y)

    NUL.SetTextureColor(tex, NUL.WithAlpha(theme.colors.border.subtle, 0.6))
    return tex, y - 12
end

function Config:BuildManagedList(parent, opts)
    opts = opts or {}
    local L           = NBK.L
    local rowHeight   = opts.rowHeight or 26
    local reorderable = opts.reorderable and true or false
    local get         = opts.get      or function() return {} end
    local onChange    = opts.onChange or function() end

    local list

    local function refresh()
        list:SetData(get())
        onChange()
    end

    list = NUL:ScrollList(parent, {
        rowHeight  = rowHeight,
        rowBuilder = function(row)
            local label = NUL:CreateLabel(row, { text = "", justifyH = "LEFT", wrap = false })
            label:SetPoint("LEFT", 8, 0)

            label:SetPoint("RIGHT", reorderable and -88 or -36, 0)

            local del = NUL:IconButton(row, {
                icon = "app-close.png", size = 20, style = "danger", plain = true,
                tooltip = L["Remove"] or "Remove",
                onClick = function()
                    local i, arr = row._idx, get()
                    if i then table.remove(arr, i); refresh() end
                end,
            })
            del:SetPoint("RIGHT", -8, 0)

            local up, down
            if reorderable then
                up = NUL:IconButton(row, {
                    icon = "arrow-up.png", size = 20, plain = true,
                    tooltip = L["Move up"] or "Move up",
                    onClick = function()
                        local i, arr = row._idx, get()
                        if i and i > 1 then
                            arr[i], arr[i - 1] = arr[i - 1], arr[i]
                            refresh()
                        end
                    end,
                })
                up:SetPoint("RIGHT", -60, 0)
                down = NUL:IconButton(row, {
                    icon = "arrow-down.png", size = 20, plain = true,
                    tooltip = L["Move down"] or "Move down",
                    onClick = function()
                        local i, arr = row._idx, get()
                        if i and i < #arr then
                            arr[i], arr[i + 1] = arr[i + 1], arr[i]
                            refresh()
                        end
                    end,
                })
                down:SetPoint("RIGHT", -34, 0)
            end
            row._up, row._down = up, down

            return function(r, entry, i)
                r._idx = i
                label:SetText(tostring(entry))
                if r._up   then r._up:SetEnabled(i > 1) end
                if r._down then r._down:SetEnabled(i < #get()) end
            end
        end,
    })

    list.container:SetPoint("TOPLEFT",     parent, "TOPLEFT",     0, 0)
    list.container:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", 0, 34)

    local addBox
    local function doAdd()
        local txt = addBox and addBox:GetText()
        txt = txt and txt:match("^%s*(.-)%s*$")
        if txt and txt ~= "" then
            table.insert(get(), txt)
            addBox:SetText("")
            refresh()
        end
    end

    local addBtn = NUL:Button(parent, {
        label   = "+ " .. ((L["+ Add"] or "+ Add"):gsub("^%+%s*", "")),
        height  = 26,
        style   = "accent",
        onClick = doAdd,
    })
    addBtn:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", 0, 0)

    addBox = NUL:EditBox(parent, {
        height         = 26,
        placeholder    = opts.addPlaceholder or (L["Add..."] or "Add..."),
        onEnterPressed = doAdd,
    })
    addBox:ClearAllPoints()
    addBox:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 0, 0)
    addBox:SetPoint("RIGHT", addBtn, "LEFT", -8, 0)

    list:SetData(get())
    return list
end
