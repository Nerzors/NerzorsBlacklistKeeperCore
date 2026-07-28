local _, NBK = ...

function NBK:LocalizeNewsItem(item)
    if type(item) == "string" then return item end
    if type(item) ~= "table" then return tostring(item) end
    local loc = GetLocale and GetLocale() or "enUS"
    return item[loc] or item.enUS or item.en or item[1] or ""
end

function NBK:_VersionGreater(a, b)
    if not a then return false end
    if not b then return true end
    local function parts(v)
        local t = {}
        for n in tostring(v):gmatch("(%d+)") do t[#t + 1] = tonumber(n) or 0 end
        return t
    end
    local pa, pb = parts(a), parts(b)
    local len = math.max(#pa, #pb)
    for i = 1, len do
        local na, nb = pa[i] or 0, pb[i] or 0
        if na ~= nb then return na > nb end
    end
    return false
end

function NBK:GetVisibleNews()
    local out = {}
    for _, entry in ipairs(self.WHATS_NEW or {}) do
        local sections = {}
        for _, section in ipairs(entry.sections or {}) do
            local items = {}
            for _, item in ipairs(section.items or {}) do
                local sub = (type(item) == "table" and item.sub) or section.sub
                if self:ShouldShowForModule(sub) then
                    items[#items + 1] = { item = item, sub = sub }
                end
            end
            if #items > 0 then
                sections[#sections + 1] = { kind = section.kind, items = items }
            end
        end
        if #sections > 0 then
            out[#out + 1] = {
                version   = entry.version,
                date      = entry.date,
                highlight = entry.highlight,
                sections  = sections,
            }
        end
    end
    return out
end

NBK.WHATS_NEW = {
    {
        version   = "0.43.0",
        date      = "2026-07-23",
        highlight = true,
        sections  = {
            {
                kind  = "new",
                items = {
                    {
                        en = "Ignore-list integration: blacklisted players you mute can now be ignored by the game as well - no chat, no whispers, no invites from them. It's off by default; switch it on under Settings > Notifications.",
                        de = "Anbindung an die Ignorieren-Liste: Blacklist-Spieler, die du stummschaltest, können jetzt auch vom Spiel ignoriert werden - dann kommen von ihnen weder Chat noch Flüstern oder Einladungen durch. Standardmäßig aus; einzuschalten unter Einstellungen > Benachrichtigungen.",
                    },
                    {
                        en = "Import from your ignore list: already ignoring people? Pull them onto your blacklist in one go - you pick who first, nothing happens behind your back.",
                        de = "Import aus der Ignorieren-Liste: Du ignorierst schon Spieler? Hol sie mit einem Klick auf die Blacklist - du wählst vorher aus, wen; es passiert nichts ungefragt.",
                    },
                    {
                        en = "Taking someone off the blacklist lifts the ignore again - but only if the addon was the one that set it. Players you ignored by hand stay untouched.",
                        de = "Nimmst du jemanden von der Blacklist, wird auch das Ignorieren aufgehoben - aber nur, wenn das Addon es gesetzt hat. Von Hand ignorierte Spieler bleiben unangetastet.",
                    },
                },
            },
            {
                kind  = "changed",
                items = {
                    {
                        en = "\"What's new?\" rebuilt: every version is its own card you can fold open and shut. Anything you haven't read starts open, so skipping a few updates now gives you all of them at a glance instead of one endless stack.",
                        de = "\"Was ist neu?\" überarbeitet: Jede Version ist eine eigene Karte zum Auf- und Zuklappen. Offen ist, was du noch nicht gelesen hast - wer mehrere Updates übersprungen hat, sieht sie alle auf einen Blick statt als endlosen Stapel.",
                    },
                    {
                        en = "Entries now show which module they belong to, and entries for modules you haven't installed are hidden entirely.",
                        de = "Einträge zeigen jetzt, zu welchem Modul sie gehören - und Einträge zu Modulen, die du nicht installiert hast, werden gar nicht erst angezeigt.",
                    },
                },
            },
            {
                kind  = "fixed",
                items = {
                    {
                        en = "The minimap tooltip listed \"Tooltip\" as an active module, although it has been part of the main addon since 0.39.0.",
                        de = "Der Minimap-Tooltip führte \"Tooltip\" als aktives Modul, obwohl es seit 0.39.0 fest zum Haupt-Addon gehört.",
                    },
                    {
                        en = "\"Statistics\" was missing from that same module list even when installed.",
                        de = "\"Statistik\" fehlte in derselben Modulliste, obwohl es installiert war.",
                        sub = "_Statistics",
                    },
                },
            },
            {
                kind  = "note",
                items = {
                    {
                        en = "The game's ignore list holds far fewer players than your blacklist does. Once it's full, the rest simply stay blacklisted without being ignored - you'll get one message when that happens, not one per player.",
                        de = "Die Ignorieren-Liste des Spiels fasst deutlich weniger Spieler als deine Blacklist. Ist sie voll, bleiben die übrigen einfach nur geblacklistet, ohne ignoriert zu werden - du bekommst dann eine Meldung, nicht eine pro Spieler.",
                    },
                },
            },
        },
    },
    {
        version   = "0.42.0",
        date      = "2026-07-18",
        highlight = true,
        sections  = {
            {
                kind  = "new",
                items = {
                    {
                        en = "Statistics: a new tab with charts over your blacklist - growth per month, top reasons and zones, class spread, the players you run into most, and what the chat filters have spared you. Built entirely from data the addon already had, so it's meaningful from the first login.",
                        de = "Statistik: ein neuer Reiter mit Diagrammen zu deiner Blacklist - Wachstum pro Monat, Top-Gründe und -Zonen, Klassenverteilung, die Spieler, denen du am häufigsten begegnest, und was dir die Chat-Filter erspart haben. Komplett aus bereits vorhandenen Daten gebaut, also gleich beim ersten Login aussagekräftig.",
                        sub = "_Statistics",
                    },
                },
            },
            {
                kind  = "fixed",
                items = {
                    {
                        en = "Lua error from the Message History while in combat in a dungeon or raid (\"attempt to compare local 'text' a secret string value\"). Chat text is protected in instances now; the history no longer trips over that.",
                        de = "Lua-Fehler des Nachrichtenverlaufs im Kampf in Dungeons und Schlachtzügen (\"attempt to compare local 'text' a secret string value\"). Chat-Text ist in Instanzen geschützt; der Verlauf stolpert nicht mehr darüber.",
                        sub = "_ChatFilters",
                    },
                    {
                        en = "Dropdowns were missing their arrow, so they didn't read as dropdowns.",
                        de = "Dropdowns fehlte der Pfeil, dadurch waren sie nicht als Auswahlfeld erkennbar.",
                    },
                },
            },
        },
    },
    {
        version   = "0.41.0",
        date      = "2026-07-10",
        sections  = {
            {
                kind  = "changed",
                items = {
                    {
                        en = "Themed scrollbars everywhere: the settings, import/export and \"What's new?\" windows now use the same slim scrollbar as the lists, not the default Blizzard one.",
                        de = "Einheitliche Scrollbalken überall: Einstellungen, Import/Export und das \"Was ist neu?\"-Fenster nutzen jetzt denselben schlanken Scrollbalken wie die Listen, nicht mehr den Blizzard-Standard.",
                    },
                    {
                        en = "Dropdowns now show a little arrow so they're recognisable as dropdowns.",
                        de = "Dropdowns zeigen jetzt einen kleinen Pfeil, damit man sie als Dropdown erkennt.",
                    },
                    {
                        en = "Cleaner flat icon buttons in the list rows (and the window's settings/close buttons) - no more little boxes around them.",
                        de = "Aufgeräumtere, flache Icon-Buttons in den Listenzeilen (und die Einstellungen-/Schließen-Buttons) - keine Kästchen mehr drumherum.",
                    },
                    {
                        en = "Tooltips now match the addon's look instead of the default Blizzard style. The note tooltip shows the full note text again.",
                        de = "Tooltips passen jetzt zum Addon-Design statt zum Blizzard-Standard. Der Notiz-Tooltip zeigt wieder den vollständigen Notiztext.",
                    },
                    {
                        en = "The minimap tooltip lists only the modules you actually have installed - inactive/unavailable ones are no longer shown greyed out.",
                        de = "Der Minimap-Tooltip listet nur noch die tatsächlich installierten Module - inaktive/nicht vorhandene werden nicht mehr ausgegraut angezeigt.",
                    },
                },
            },
            {
                kind  = "fixed",
                items = {
                    {
                        en = "Classic: the Group Finder and Remember Me modules (which don't exist on Classic) no longer show up or load there.",
                        de = "Classic: Die Module Gruppensuche und Remember Me (die es auf Classic nicht gibt) tauchen dort nicht mehr auf und werden nicht mehr geladen.",
                    },
                },
            },
        },
    },
    {
        version   = "0.40.0",
        date      = "2026-07-04",
        sections  = {
            {
                kind  = "new",
                items = {
                    {
                        en = "Message History: chat from muted blacklisted players is no longer lost. It's saved and viewable in the new \"Message history\" tab - a list of players, and clicking one opens a detail window with every message and where it was said (whisper, party, raid, trade, ...).",
                        de = "Nachrichtenverlauf: Die Nachrichten von Blacklist-Spieler (Mute) geht nicht mehr verloren. Er wird gespeichert und im neuen Reiter \"Nachrichtenverlauf\" einsehbar - Dies ist eine Liste von Spielern: ein Klick darauf öffnet ein Detailfenster mit jeder Nachricht und dem jeweiligen Kanal (Flüstern, Gruppe, Schlachtzug, Handel …).",
                        sub = "_ChatFilters",
                    },
                    {
                        en = "Message history keeps messages for a configurable time (default 30 days), older ones are cleaned up automatically on login. Time span, on/off and \"Clear all\" live in the chat filters settings.",
                        de = "Nachrichten werden für einen konfigurierbaren Zeitraum aufbewahrt (Standard 30 Tage), ältere Nachrichten werden beim Einloggen automatisch gelöscht. Einstellungen für den Zeitraum, die Aktivierung/Deaktivierung sowie die Option \"Alles löschen\" finden sich in den Chatfilter-Optionen.",
                        sub = "_ChatFilters",
                    },
                },
            },
            {
                kind  = "changed",
                items = {
                    {
                        en = "Scrollbars restyled to match the addon's look - a slim accent thumb with clean arrow icons instead of the default Blizzard scrollbar.",
                        de = "Scrollbalken an das Addon-Design angepasst - schlanker Akzent-Regler mit sauberen Pfeil-Icons statt des Standard-Blizzard-Scrollbalkens.",
                    },
                },
            },
            {
                kind  = "fixed",
                items = {
                    {
                        en = "The \"Created by ...\" footer was pushed to the right instead of centered.",
                        de = "Der \"Created by ...\"-Footer war nach rechts verschoben statt mittig.",
                    },
                },
            },
            {
                kind  = "note",
                items = {
                    {
                        en = "Message history only archives what's actually hidden. Turn on \"Hide chat messages from blacklisted players\" (Notifications) so muted players' chat is hidden from chat - and saved to history.",
                        de = "Der Nachrichtenverlauf speichert nur, was auch wirklich ausgeblendet wird. Aktiviere \"Hide chat messages from blacklisted players\" (Benachrichtigungen), damit der Chat stummgeschalteter Spieler ausgeblendet - und im Verlauf gesichert - wird.",
                        sub = "_ChatFilters",
                    },
                },
            },
        },
    },
    {
        version   = "0.39.0",
        date      = "2026-06-19",
        sections  = {
            {
                kind  = "changed",
                items = {
                    {
                        en = "The \"Tooltip\" sub-addon is gone - it's now part of the core addon. You don't need to install it separately anymore. (You can delete the old NerzorsBlacklistKeeper_Tooltip folder.)",
                        de = "Das \"Tooltip\"-Sub-Addon ist weg - es ist jetzt Teil des Haupt-Addons. Du brauchst es nicht mehr extra zu installieren. (Den alten Ordner NerzorsBlacklistKeeper_Tooltip kannst du löschen.)",
                    },
                },
            },
            {
                kind  = "new",
                items = {
                    {
                        en = "Tooltip settings now let you toggle each row separately: reason, notes, zone, encounter history, mute indicator, pinned indicator.",
                        de = "Tooltip-Einstellungen erlauben jetzt jede Zeile einzeln an-/auszuschalten: Grund, Notizen, Zone, Begegnungs-Historie, Stumm-Marker, Pin-Marker.",
                    },
                },
            },
            {
                kind  = "fixed",
                items = {
                    {
                        en = "Lua error in dungeons and raids when hovering over players (\"attempt to compare local 'realm' a secret string value\"). Same family of bug as the older \"name\" one, now also fixed for the realm field and for the post-Mythic+ party capture.",
                        de = "Lua-Fehler in Dungeons und Schlachtzügen beim Hovern von Spielern (\"attempt to compare local 'realm' a secret string value\"). Gleicher Bug-Typ wie damals bei \"name\", jetzt auch fürs Realm-Feld und für die M+-Gruppen-Erfassung behoben.",
                    },
                },
            },
        },
    },
    {
        version   = "0.38.0",
        date      = "2026-06-18",
        sections  = {
            {
                kind  = "new",
                items = {
                    {
                        en = "\"_Nameplates\" This module has been removed and is no longer active.",
                        de = "\"_Nameplates\" Dieses Modul wurde entfernt und ist nicht mehr aktiv.",
                    },
                },
            },
            {
                kind  = "fixed",
                items = {
                    {
                        en = "Core \"Created by ...\" The links were wrong / incorrect.",
                        de = "Core \"Created by ...\" Links waren falsch bzw. inkorrekt",
                    },
                },
            },
        },
    },
    {
        version   = "0.37.3",
        date      = "2026-05-18",
        sections  = {
            {
                kind  = "new",
                items = {
                    {
                        en = "\"What's New?\" window. Opens once after every update so you don't miss what changed.",
                        de = "\"Was ist neu?\"-Fenster. Öffnet sich nach jedem Update einmal automatisch, damit du keine Änderungen verpasst.",
                    },
                    {
                        en = "/nbk news to reopen this window any time.",
                        de = "/nbk news zum jederzeit erneuten Öffnen.",
                    },
                },
            },
            {
                kind  = "fixed",
                items = {
                    {
                        en = "Mythic+ \"Remember player?\" popup opened the moment you inserted the keystone instead of after the run. It now waits for a real run (at least 30 seconds elapsed) before showing up.",
                        de = "Mythic+ \"Spieler merken?\"-Popup öffnete sich beim Einsetzen des Keystones statt nach dem Run. Es wartet jetzt auf einen echten Run (mindestens 30 Sekunden Spielzeit), bevor es erscheint.",
                        sub = "_RememberMe",
                    },
                },
            },
        },
    },
    {
        version  = "0.37.2",
        date     = "2026-05-18",
        sections = {
            {
                kind  = "new",
                items = {
                    {
                        en = "Logo on the main window can be freely positioned and overhang the frame edge.",
                        de = "Logo am Hauptfenster ist frei positionierbar und darf über den Fensterrand ragen.",
                    },
                    {
                        en = "New centered footer with quick-link icons for Website, Discord, GitHub and Ko-fi. Click an icon to copy the URL. Each icon individually toggle-able in Display settings.",
                        de = "Neuer mittiger Footer mit Schnellzugriff-Icons für Website, Discord, GitHub und Ko-fi. Klick öffnet die URL zum Kopieren. Jedes Icon in den Darstellungs-Einstellungen einzeln abschaltbar.",
                    },
                },
            },
            {
                kind  = "fixed",
                items = {
                    {
                        en = "Logo used to render behind the window title - now in front.",
                        de = "Logo lag hinter dem Fenstertitel - jetzt davor.",
                    },
                },
            },
        },
    },
    {
        version  = "0.37.1",
        date     = "2026-05-18",
        sections = {
            {
                kind  = "new",
                items = {
                    {
                        en = "Auto-Sync receive popup redesigned: clean card with accent stripe, class-coloured player name, and the entry's note if one was attached.",
                        de = "Auto-Sync Empfangs-Popup neu gestaltet: aufgeräumte Karte mit farbigem Akzentstreifen, Spielername in Klassenfarbe und Notiz (falls eine mitgeschickt wurde).",
                        sub = "_Sync",
                    },
                },
            },
            {
                kind  = "fixed",
                items = {
                    {
                        en = "Auto-Sync ignored the \"Share this entry\" checkbox when adding a player - entries went out anyway. Now respected.",
                        de = "Auto-Sync ignorierte das \"Diesen Eintrag teilen\"-Häkchen beim Hinzufügen - Einträge wurden trotzdem geteilt. Wird jetzt respektiert.",
                        sub = "_Sync",
                    },
                },
            },
        },
    },
    {
        version  = "0.37.0",
        date     = "2026-05-17",
        sections = {
            {
                kind  = "new",
                items = {
                    {
                        en = "Auto-Sync: automatically share new blacklist entries the moment you add them. Pick recipients: your guild, online friends on your realm, or a custom name list.",
                        de = "Auto-Sync: neu hinzugefügte Blacklist-Einträge sofort automatisch teilen. Empfänger wählbar: eigene Gilde, Online-Freunde auf deinem Realm oder eine selbst zusammengestellte Namensliste.",
                        sub = "_Sync",
                    },
                    {
                        en = "Sync now supports the Remember-Me list too, not just the blacklist.",
                        de = "Sync unterstützt jetzt auch die Remember-Me-Liste, nicht mehr nur die Blacklist.",
                        sub = "_Sync",
                    },
                },
            },
            {
                kind  = "fixed",
                items = {
                    {
                        en = "Tooltip Lua error during Mythic+ combat (Blizzard's protected-data system). The tooltip hook now bows out gracefully in instances + combat.",
                        de = "Tooltip-Lua-Fehler im Mythic+-Kampf (Blizzards Sicherheitssystem). Der Tooltip-Hook hält sich in Instanzen + Kampf jetzt sauber zurück.",
                    },
                },
            },
        },
    },
    {
        version  = "0.35.0",
        date     = "2026-05-15",
        sections = {
            {
                kind  = "new",
                items = {
                    {
                        en = "Multi-list export/import: both the blacklist and the Remember-Me list are exportable. Import auto-detects which list the string belongs to.",
                        de = "Multi-List Export/Import: sowohl Blacklist als auch Remember-Me sind exportierbar. Import erkennt automatisch, zu welcher Liste der String gehört.",
                    },
                },
            },
        },
    },
}
