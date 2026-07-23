local _, NBK = ...
local Config = NBK:GetModule("Config")
if not Config then return end

local NUL = LibStub("NerzorsUILib-1.0")

function Config:ShowResetDialog()
    local L     = NBK.L
    local count = NBK:CountEntries()

    NUL:Confirm({
        id   = "NBK_CONFIRM_RESET",
        text = (L["Clear all %d blacklist entries? This cannot be undone."]):format(count),
        acceptLabel = L["Yes"],
        cancelLabel = L["No"],
        onAccept = function()
            local removed = NBK:ResetEntries()
            NBK:Print((L["Cleared %d entries."]):format(removed))
            self:RefreshListData()
        end,
    })
end
