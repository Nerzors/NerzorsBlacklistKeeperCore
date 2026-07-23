-- NerzorsUILib-1.0 :: Widgets/MultiSelectList.lua
--
-- A bordered, scrollable list of string entries where each row carries a
-- checkbox in addition to a delete button. Useful for "include / exclude
-- these N items" pickers - e.g. the Auto-Sync recipient list ("send
-- shares to these specific characters"). An add row at the bottom lets
-- the user type new entries; the caller chooses whether new entries
-- start enabled.
--
-- Data model: the caller's get() returns an array of plain tables
--
--     { { key = "Nerzors-Eredar", enabled = true  },
--       { key = "Bob-Stormrage",  enabled = false }, ... }
--
-- The widget mutates that array in place (push on add, table.remove on
-- delete, flip .enabled on toggle) and calls onChange(action, entry)
-- after every mutation so the caller can persist.
--
-- opts:
--   get             function() -> array (live reference, mutated in place)
--   onChange        function(action, entry)  "added" | "removed" | "toggled"
--   addable         boolean  show the add row at the bottom (default true)
--   newDefaultsOn   boolean  add-row: new entries start checked (default true)
--   addPlaceholder  string   placeholder for the add EditBox
--   rowHeight       number   default 26
--
-- Convenience methods on the returned ScrollList:
--   :Refresh()         re-render from get() (use after an external mutation)
--   :GetSelectedKeys() -> array of keys whose .enabled is true
--
-- Anchoring: like Config:BuildManagedList, the widget fills the `parent`
-- frame (TOPLEFT 0,0 → BOTTOMRIGHT 0, 34 leaves room for the add row).
-- Caller sizes `parent`; the bottom 34 px hold the EditBox + Add button
-- when addable is on. When addable is false, the scroll list fills the
-- whole parent.

local NUL = LibStub("NerzorsUILib-1.0")

function NUL:MultiSelectList(parent, opts)
    opts = opts or {}
    local theme        = self:GetTheme()
    local rowHeight    = opts.rowHeight or 26
    local addable      = opts.addable ~= false
    local newDefaultsOn = (opts.newDefaultsOn ~= false)
    local get          = opts.get or function() return {} end
    local onChange     = opts.onChange or function() end

    local list  -- forward-declared for the closures

    -- Find an entry by key. Returns (index, entry) or nil.
    local function find(key)
        local arr = get()
        for i, e in ipairs(arr) do
            if e.key == key then return i, e end
        end
        return nil
    end

    local function refresh()
        list:SetData(get())
    end

    list = self:ScrollList(parent, {
        rowHeight  = rowHeight,
        rowBuilder = function(row)
            -- Per-row checkbox - the multi-select handle. Toggling it
            -- flips .enabled on the underlying entry and fires onChange.
            local cb = NUL:Checkbox(row, { size = "small" })
            cb:SetPoint("LEFT", 8, 0)
            cb:SetOnChange(function(checked)
                local entry = row._entry
                if not entry then return end
                entry.enabled = checked and true or false
                onChange("toggled", entry)
            end)

            local label = NUL:CreateLabel(row, { text = "", justifyH = "LEFT", wrap = false })
            label:SetPoint("LEFT", cb, "RIGHT", 8, 0)
            label:SetPoint("RIGHT", -36, 0)

            local del = NUL:IconButton(row, {
                icon  = "app-close.png", size = 20, style = "danger", plain = true,
                onClick = function()
                    local entry = row._entry
                    if not entry then return end
                    local i = find(entry.key)
                    if i then
                        table.remove(get(), i)
                        refresh()
                        onChange("removed", entry)
                    end
                end,
            })
            del:SetPoint("RIGHT", -8, 0)

            row._cb, row._label = cb, label

            return function(r, entry)
                r._entry = entry
                r._label:SetText(tostring(entry.key or ""))
                r._cb:SetChecked(entry.enabled and true or false)
            end
        end,
    })

    if addable then
        list.container:SetPoint("TOPLEFT",     parent, "TOPLEFT",     0, 0)
        list.container:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", 0, 34)
    else
        list.container:SetAllPoints(parent)
    end

    if addable then
        local addBox
        local function doAdd()
            local txt = addBox and addBox:GetText()
            txt = txt and txt:match("^%s*(.-)%s*$")
            if not txt or txt == "" then return end
            -- Refuse silent duplicates - the existing row's checkbox is
            -- the right "I want this back" affordance, not a second copy.
            if find(txt) then return end
            local entry = { key = txt, enabled = newDefaultsOn }
            table.insert(get(), entry)
            addBox:SetText("")
            refresh()
            onChange("added", entry)
        end

        local addBtn = self:Button(parent, {
            label   = "+ Add", height = 26, style = "accent",
            onClick = doAdd,
        })
        addBtn:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", 0, 0)

        addBox = self:EditBox(parent, {
            height         = 26,
            placeholder    = opts.addPlaceholder or "Add...",
            onEnterPressed = doAdd,
        })
        addBox:ClearAllPoints()
        addBox:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 0, 0)
        addBox:SetPoint("RIGHT", addBtn, "LEFT", -8, 0)
    end

    function list:Refresh() refresh() end

    -- Returns the keys of currently-enabled entries, in display order.
    function list:GetSelectedKeys()
        local out = {}
        for _, e in ipairs(get()) do
            if e.enabled then out[#out + 1] = e.key end
        end
        return out
    end

    refresh()
    return list
end
