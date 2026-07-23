-- NerzorsUILib-1.0 :: Widgets/Confirm.lua
-- Yes/No confirmation popup. Uses Blizzard's StaticPopupDialogs so
-- everything plays nicely with /reload prompts, focus, escape, etc.
--
-- opts:
--   id        string    StaticPopupDialogs registry key. Default
--                       "NUL_CONFIRM" - reuse across calls is fine,
--                       Blizzard overwrites the previous spec on call.
--   text      string    Prompt text. Required.
--   onAccept  function  Called when the user clicks Yes.
--   onCancel  function  Optional - called on No.
--   acceptLabel / cancelLabel  Override button labels.

local NUL = LibStub("NerzorsUILib-1.0")

function NUL:Confirm(opts)
    opts = opts or {}
    local id = opts.id or "NUL_CONFIRM"
    StaticPopupDialogs[id] = {
        text     = opts.text or "",
        button1  = opts.acceptLabel or (YES or "Yes"),
        button2  = opts.cancelLabel or (NO or "No"),
        OnAccept = opts.onAccept,
        OnCancel = opts.onCancel,
        timeout       = 0,
        whileDead     = true,
        hideOnEscape  = true,
        preferredIndex = 3,
    }
    StaticPopup_Show(id)
end
