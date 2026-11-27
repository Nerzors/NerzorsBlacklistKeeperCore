local _, NBK = ...

function NBK:LocalizeNewsItem(item)
    if type(item) == "string" then return item end
    if type(item) ~= "table" then return tostring(item) end

    local loc   = NBK.currentLocale or "enUS"
    local short = loc:sub(1, 2):lower()
    return item[loc] or item[short] or item.enUS or item.en or item[1] or ""
end

local function parseVersion(v)
    v = (tostring(v):gsub("%+.*$", ""))
    local core, pre = v:match("^([^%-]*)%-(.+)$")
    local nums = {}
    for n in (core or v):gmatch("%d+") do nums[#nums + 1] = tonumber(n) end
    local ids
    if pre then
        ids = {}
        for id in pre:gmatch("[^%.]+") do ids[#ids + 1] = tonumber(id) or id:lower() end
    end
    return nums, ids
end

local function comparePre(x, y)
    for i = 1, math.max(#x, #y) do
        local p, q = x[i], y[i]
        if p == nil then return -1 end
        if q == nil then return 1 end
        if p ~= q then
            if type(p) ~= type(q) then return type(p) == "number" and -1 or 1 end
            return p < q and -1 or 1
        end
    end
    return 0
end

function NBK:_VersionGreater(a, b)
    if not a then return false end
    if not b then return true end
    local na, pa = parseVersion(a)
    local nb, pb = parseVersion(b)
    for i = 1, math.max(#na, #nb) do
        local x, y = na[i] or 0, nb[i] or 0
        if x ~= y then return x > y end
    end
    if not pa then return pb ~= nil end
    if not pb then return false end
    return comparePre(pa, pb) > 0
end

function NBK:GetVisibleNews()
    local out = {}
    for _, entry in ipairs(self.WHATS_NEW or {}) do
        local sections = {}
        for _, section in ipairs(entry.sections or {}) do
            local items = {}
            for _, item in ipairs(section.items or {}) do
                local sub = (type(item) == "table" and item.sub) or section.sub
                local flavor = (type(item) == "table" and item.flavor) or section.flavor
                local onFlavor = not flavor or flavor == self.FLAVOR
                              or (flavor == "classic" and self:IsClassic())
                if self:ShouldShowForModule(sub) and onFlavor then
                    local go = type(item) == "table" and item.go or nil
                    if go and not self:CanGoTo(go) then go = nil end
                    items[#items + 1] = { item = item, sub = sub, go = go }
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
        version   = "2.5.1",
        date      = "2026-11-27",
        highlight = true,
        sections  = {
            {
                kind  = "changed",
                items = {
                    {
                        en = "New export format: an export is now one single encoded text (starting with !NBK:) instead of many lines. Line breaks or a stray | picked up while copying - through Discord or a forum, say - can no longer break it, and a checksum notices if something is missing anyway. The text is also much shorter. Applies to the blacklist, Remember Me and the ignore list.",
                        de = "Neues Export-Format: Ein Export ist jetzt ein einziger kodierter Text (beginnt mit !NBK:) statt vieler Zeilen. Zeilenumbrüche oder ein falsch gesetztes | beim Kopieren, etwa über Discord oder ein Forum, machen ihn nicht mehr kaputt, und eine Prüfsumme merkt, wenn doch etwas fehlt. Der Text ist außerdem deutlich kürzer. Gilt für Blacklist, Merken und Ignorieren-Liste.",
                        go = "settings:Advanced",
                    },
                    {
                        en = "Old exports still work: the import reads texts from older versions (!NBK1!) as before. To read a new export you need 2.5.1 or later.",
                        de = "Alte Exporte gehen weiter: Texte aus älteren Versionen (!NBK1!) liest der Import wie bisher. Wer einen neuen Export einlesen will, braucht mindestens 2.5.1.",
                    },
                },
            },
            {
                kind  = "fixed",
                items = {
                    {
                        en = "When the auto-cleanup at login removes old entries, it now also lifts the ignores NBK set itself - just like removing by hand. Ignores you set yourself stay, and \"Restore\" in the history sets the ignore again.",
                        de = "Entfernt das automatische Aufräumen beim Login alte Einträge, hebt es jetzt auch die Ignores auf, die NBK selbst gesetzt hat - wie beim Entfernen von Hand. Ignores, die du selbst gesetzt hast, bleiben, und \"Wiederherstellen\" im Verlauf setzt das Ignore wieder.",
                        go = "settings:Advanced",
                    },
                },
            },
        },
    },
    {
        version   = "2.5.0",
        date      = "2026-11-23",
        highlight = true,
        sections  = {
            {
                kind  = "new",
                items = {
                    {
                        en = "Ignore someone (/ignore, right-click, friends list) and NBK asks whether they should go on your blacklist too - Yes puts them there right away. \"Don't ask again\" turns the question off; it's under \"Notifications\" > \"Ignore list\".",
                        de = "Ignorierst du jemanden (/ignore, Rechtsklick, Freundesliste), fragt NBK, ob er auch auf deine Blacklist soll - Ja trägt ihn sofort ein. \"Nicht mehr fragen\" schaltet die Frage ab; sie steht unter \"Benachrichtigungen\" > \"Ignorieren-Liste\".",
                        go = "settings:Notifications",
                    },
                    {
                        en = "Player request: NBK can put everyone on your ignore list on the blacklist by itself - at login and whenever the list changes. Off by default; switch it on under \"Notifications\" > \"Ignore list\". Players you take off the blacklist stay off.",
                        de = "Spielerwunsch: NBK kann alle von deiner Ignorieren-Liste selbst auf die Blacklist setzen - beim Login und bei jeder Änderung der Liste. Von Haus aus aus; einschalten unter \"Benachrichtigungen\" > \"Ignorieren-Liste\". Wen du von der Blacklist nimmst, der bleibt draußen.",
                        go = "settings:Notifications",
                    },
                    {
                        en = "Removing someone from the blacklist who is ignored on this character: the question now offers \"Also remove from the ignore list\" - ticked if NBK set that ignore. Until now NBK lifted its own ignores without saying so.",
                        de = "Nimmst du jemanden von der Blacklist, der auf diesem Charakter ignoriert ist, bietet die Frage jetzt \"Auch von der Ignorieren-Liste entfernen\" an - angehakt, wenn NBK das Ignorieren gesetzt hat. Bisher hob NBK seine eigenen Ignores ohne Hinweis mit auf.",
                        go = "list:blacklist",
                    },
                    {
                        en = "Blacklist: the new \"History\" button shows your last removals (5 to 25, set under \"Advanced\") and the last clean-up run on its own tab. \"Restore\" puts a player back exactly as they were - reason, note, date, pin and the ignore too.",
                        de = "Blacklist: Der neue Knopf \"Verlauf\" zeigt deine letzten Löschungen (5 bis 25, einstellbar unter \"Erweitert\") und in einem eigenen Reiter das letzte Aufräumen. \"Wiederherstellen\" holt einen Spieler genau so zurück, wie er war - mit Grund, Notiz, Datum, Pin und auch dem Ignorieren.",
                        go = "list:blacklist",
                    },
                    {
                        en = "Blacklist: right-click a player and pick \"Ignore everywhere\" to ignore them on all your characters - also players who aren't on any ignore list yet.",
                        de = "Blacklist: Rechtsklick auf einen Spieler > \"Überall ignorieren\" ignoriert ihn auf all deinen Charakteren - auch Spieler, die noch auf keiner Ignorieren-Liste stehen.",
                        sub = "_IgnoreManager",
                        go = "list:blacklist",
                    },
                    {
                        en = "Ignore Manager: when the changes planned for this character come up at login, \"Also put on the blacklist\" puts the planned ignores on your blacklist too - already ticked if NBK asks you when you ignore someone.",
                        de = "Ignore-Manager: Im Fenster mit den geplanten Änderungen beim Login setzt \"Auch auf die Blacklist setzen\" die geplanten Ignores gleich mit auf deine Blacklist - schon angehakt, wenn NBK beim Ignorieren fragt.",
                        sub = "_IgnoreManager",
                        go = "list:ignore",
                    },
                    {
                        en = "Group Finder: as group leader you spot blacklisted applicants at a glance - a red stripe and a red name in Blizzard's list and in EllesmereUI's, the reason in the member's tooltip. The chat warning stays.",
                        de = "Gruppensuche: Als Gruppenleiter erkennst du gelistete Bewerber sofort - rote Leiste und roter Name in Blizzards Liste und in der von EllesmereUI, der Grund im Tooltip. Die Warnung im Chat bleibt.",
                        sub = "_GroupFinder",
                        flavor = "retail",
                        go = "settings:GroupFinder",
                    },
                    {
                        en = "Two new warning sounds: \"boepboep\" and \"metalgearPing\" - pick one under \"Notifications\".",
                        de = "Zwei neue Warntöne: \"boepboep\" und \"metalgearPing\" - auswählbar unter \"Benachrichtigungen\".",
                        go = "settings:Notifications",
                    },
                },
            },
            {
                kind  = "changed",
                items = {
                    {
                        en = "Settings: the window and its navigation are a bit wider, so long names and options are no longer cut off. A name that still doesn't fit shows in full when you hover it.",
                        de = "Einstellungen: Das Fenster und die Navigation sind etwas breiter, damit lange Namen und Optionen nicht mehr abgeschnitten werden. Ein Name, der trotzdem nicht passt, steht ganz da, wenn du mit der Maus darüber gehst.",
                    },
                },
            },
            {
                kind  = "fixed",
                items = {
                    {
                        en = "WoW: Forever: \"Reload now\" after choosing a language (and \"Enable / Disable and reload\" at login) ended in an error and didn't reload. NBK now reloads through the game's own /reload.",
                        de = "WoW: Forever: \"Jetzt neu laden\" nach der Sprachwahl (und \"Einschalten / Deaktivieren und neu laden\" beim Login) endete mit einem Fehler und lud nicht neu. NBK lädt jetzt über das /reload des Spiels neu.",
                        flavor = "forever",
                    },
                    {
                        en = "Settings: an option switched somewhere else - \"Don't ask again\" after /ignore, or \"Run planned changes automatically from now on\" - still showed its old state until you reloaded. The settings now show the current state every time.",
                        de = "Einstellungen: Eine Option, die woanders umgeschaltet wurde - \"Nicht mehr fragen\" nach /ignore oder \"Geplante Änderungen künftig automatisch ausführen\" -, zeigte bis zum Neuladen noch den alten Stand. Jetzt zeigen die Einstellungen immer den aktuellen Stand.",
                        go = "settings:Notifications",
                    },
                },
            },
            {
                kind  = "note",
                items = {
                    {
                        en = "WoW: Forever still forgets the ignore list when you log out - a bug in the game itself. NBK now asks right when you ignore someone whether they should go on your blacklist too; say Yes and you keep them.",
                        de = "WoW: Forever vergisst die Ignorieren-Liste weiterhin beim Ausloggen - ein Fehler im Spiel selbst. NBK fragt jetzt direkt beim Ignorieren, ob der Spieler auch auf deine Blacklist soll; mit Ja bleibt er dir erhalten.",
                        flavor = "forever",
                        go = "settings:Notifications",
                    },
                    {
                        en = "Thanks to everyone who tested the beta and sent in bugs and wishes - on our website nbk.nerzors.com, on Discord, GitHub and CurseForge!",
                        de = "Danke an alle, die die Beta getestet und Fehler und Wünsche gemeldet haben - auf unserer Webseite nbk.nerzors.com, im Discord, auf GitHub und CurseForge!",
                    },
                },
            },
        },
    },
    {
        version   = "2.4.0",
        date      = "2026-11-22",
        highlight = true,
        sections  = {
            {
                kind  = "new",
                items = {
                    {
                        en = "Muted players on your blacklist can no longer trade with you, invite you to a group or guild, or challenge you to a duel (pet battle duels too) - NBK declines right away and says so once in chat. One switch per kind under \"Notifications\", all on.",
                        de = "Stummgeschaltete Spieler deiner Blacklist können nicht mehr mit dir handeln, dich in Gruppe oder Gilde einladen oder zum Duell fordern (auch zum Haustierkampf) - NBK lehnt sofort ab und sagt es einmal im Chat. Ein Schalter je Art unter \"Benachrichtigungen\", alle an.",
                        go = "settings:Notifications",
                    },
                    {
                        en = "Group Finder: groups whose leader is on Remember Me get a green stripe, a green name and your star rating - in Blizzard's list and in EllesmereUI's. The group's tooltip shows the rating, your note and the run. The blacklist always wins.",
                        de = "Gruppensuche: Gruppen, deren Leiter in Merken steht, bekommen eine grüne Leiste, einen grünen Namen und deine Sterne - in Blizzards Liste und in der von EllesmereUI. Der Tooltip der Gruppe zeigt Bewertung, Notiz und Lauf. Die Blacklist hat immer Vorrang.",
                        sub = "_GroupFinder",
                        flavor = "retail",
                        go = "settings:GroupFinder",
                    },
                    {
                        en = "Group Finder: as group leader you see remembered applicants the same way in the applicant list - every member of an application on its own.",
                        de = "Gruppensuche: Als Gruppenleiter siehst du gemerkte Bewerber genauso in der Bewerberliste - jedes Mitglied einer Bewerbung für sich.",
                        sub = "_GroupFinder",
                        flavor = "retail",
                    },
                    {
                        en = "Language: NBK can now speak another language than your game - pick it under \"Display\" > \"Language\" (English, Deutsch, Español, Français, Italiano, Português, Русский). The game's own texts such as class and zone names stay in the game's language.",
                        de = "Sprache: NBK kann jetzt eine andere Sprache sprechen als dein Spiel - auswählbar unter \"Darstellung\" > \"Sprache\" (English, Deutsch, Español, Français, Italiano, Português, Русский). Texte des Spiels wie Klassen- und Zonennamen bleiben in der Spielsprache.",
                        go = "settings:Display",
                    },
                    {
                        en = "Blacklist: small icons behind the name show at a glance who is pinned (the auto-cleanup keeps them) and who is ignored on this character. Hover them for a short explanation.",
                        de = "Blacklist: Kleine Symbole hinter dem Namen zeigen auf einen Blick, wer angeheftet ist (bleibt beim Auto-Aufräumen) und wer auf diesem Charakter ignoriert wird. Mit der Maus darüber gibt es eine kurze Erklärung.",
                        go = "list:blacklist",
                    },
                    {
                        en = "Auto-cleanup preview: under \"Advanced\" NBK shows how many entries the cleanup would remove right now, and \"Show entries\" lists them - pin the ones you want to keep. Switching the cleanup on while entries are due asks first.",
                        de = "Vorschau fürs Auto-Aufräumen: Unter \"Erweitert\" zeigt NBK, wie viele Einträge das Aufräumen gerade entfernen würde, und \"Einträge anzeigen\" listet sie auf - heft an, was du behalten willst. Wer das Aufräumen einschaltet, während schon etwas ansteht, wird vorher gefragt.",
                        go = "settings:Advanced",
                    },
                    {
                        en = "Ignore list, \"All characters\": Shift-right-click another character to remove it from the overview (after asking) - handy for characters you deleted. The character you're logged in on shows up there right away.",
                        de = "Ignorieren-Liste, \"Alle Charaktere\": Shift-Rechtsklick auf einen anderen Charakter entfernt ihn aus der Übersicht (nach Rückfrage) - praktisch für gelöschte Charaktere. Der eingeloggte Charakter steht dort sofort.",
                        sub = "_IgnoreManager",
                        go = "list:ignore",
                    },
                },
            },
            {
                kind  = "changed",
                items = {
                    {
                        en = "Questions, the group warning and the link windows are NBK windows now: in your theme, at your window size, with Enter for Yes and Esc for No.",
                        de = "Fragen, die Gruppenwarnung und die Link-Fenster sind jetzt NBK-Fenster: in deinem Design, in deiner Fenstergröße, mit Enter für Ja und Esc für Nein.",
                    },
                    {
                        en = "Presets: a new preset can be up to 32 characters long, so it fits on one button in the add dialog. Longer presets you already have stay as they are.",
                        de = "Vorgaben: Eine neue Vorgabe darf bis zu 32 Zeichen lang sein, damit sie im Dialog auf einen Knopf passt. Längere Vorgaben, die du schon hast, bleiben wie sie sind.",
                        go = "settings:Presets",
                    },
                    {
                        en = "WoW: Forever no longer tells addons the server name since its latest patch. NBK now goes by the name alone there and switches saved players and characters once at login: older blacklist entries are recognized again, and no character shows up twice in the ignore list overview.",
                        de = "WoW: Forever verrät Addons seit dem letzten Patch den Servernamen nicht mehr. NBK geht dort jetzt nur nach dem Namen und stellt gespeicherte Spieler und Charaktere beim Login einmalig um: Ältere Blacklist-Einträge werden wieder erkannt, und kein Charakter steht doppelt in der Übersicht der Ignorieren-Liste.",
                        flavor = "forever",
                    },
                },
            },
            {
                kind  = "fixed",
                items = {
                    {
                        en = "Export, import and sharing showed the names of the lists (Blacklist, Remember Me, Ignore list) in English only - they are translated now.",
                        de = "Export, Import und Teilen zeigten die Namen der Listen (Blacklist, Merken, Ignorieren-Liste) nur auf Englisch - jetzt sind sie übersetzt.",
                    },
                    {
                        en = "Putting someone on the blacklist during a boss fight in a raid could end in a Lua error, and the player wasn't added.",
                        de = "Wer im Raid während eines Bosskampfs jemanden auf die Blacklist setzte, konnte einen Lua-Fehler bekommen, und der Spieler wurde nicht eingetragen.",
                        flavor = "retail",
                    },
                    {
                        en = "Add and edit dialog: with many or long presets the buttons ran over the reason field. Now they wrap inside their area, the dialog grows with them, and a preset too long for one line is cut short - hover it for the full text.",
                        de = "Dialog zum Hinzufügen und Bearbeiten: Bei vielen oder langen Vorgaben liefen die Knöpfe über das Feld für den Grund. Jetzt brechen sie in ihrem Bereich um, der Dialog wächst mit, und eine Vorgabe, die für eine Zeile zu lang ist, wird gekürzt - mit der Maus darüber steht der ganze Text.",
                    },
                    {
                        en = "Ignoring: when the game refused one name, every further ignore in that session failed with \"the ignore list is full\" - even with one name on the list. Now only a really full list counts as full, and a refused name is named in chat.",
                        de = "Ignorieren: Lehnte das Spiel einen Namen ab, scheiterte danach jedes weitere Ignorieren in der Sitzung mit \"die Ignorieren-Liste ist voll\" - auch mit nur einem Namen auf der Liste. Jetzt gilt nur eine wirklich volle Liste als voll, und ein abgelehnter Name wird im Chat genannt.",
                    },
                    {
                        en = "WoW: Forever: \"Ignore everywhere\" and planned ignores sent the name with a server the game doesn't know, so it refused them. NBK sends the name only now.",
                        de = "WoW: Forever: \"Überall ignorieren\" und geplante Ignores schickten den Namen mit einem Server, den das Spiel nicht kennt, deshalb lehnte es sie ab. NBK schickt jetzt nur den Namen.",
                        flavor = "forever",
                        sub = "_IgnoreManager",
                    },
                },
            },
            {
                kind  = "note",
                items = {
                    {
                        en = "WoW: Forever currently forgets the ignore list when you log out - that's a bug in the game itself, not in NBK. Until Blizzard fixes it, put the players on your blacklist (\"Import to NBK\" in the ignore list) or export the list (\"All characters\" > \"Tools\" > \"Export...\"), so you don't lose them.",
                        de = "WoW: Forever vergisst die Ignorieren-Liste zurzeit beim Ausloggen - ein Fehler im Spiel selbst, nicht in NBK. Bis Blizzard ihn behebt: Übernimm die Spieler in deine Blacklist (\"In NBK übernehmen\" in der Ignorieren-Liste) oder exportiere die Liste (\"Alle Charaktere\" > \"Werkzeuge\" > \"Exportieren...\"), damit sie nicht verloren gehen.",
                        flavor = "forever",
                        go = "list:ignore",
                    },
                    {
                        en = "Thanks to everyone who tested the two betas and sent in bugs - on our website nbk.nerzors.com, on Discord, GitHub and CurseForge!",
                        de = "Danke an alle, die die beiden Betas getestet und Fehler gemeldet haben - auf unserer Webseite nbk.nerzors.com, im Discord, auf GitHub und CurseForge!",
                    },
                },
            },
        },
    },
    {
        version   = "2.3.0",
        date      = "2026-11-19",
        highlight = true,
        sections  = {
            {
                kind  = "new",
                items = {
                    {
                        en = "Remember Me now also runs on Classic Era, Classic MoP and WoW: Forever: remember the players you enjoyed playing with - star rating, a note, and a hint in the tooltip when you meet them again. If an earlier version turned it off on this client, NBK asks you once at login whether to turn it back on.",
                        de = "Merken gibt es jetzt auch auf Classic Era, Classic MoP und WoW: Forever: Merke dir die Spieler, mit denen du gern gespielt hast - mit Sternen, Notiz und einem Hinweis im Tooltip, wenn du sie wiedertriffst. Hat eine frühere Version Merken auf diesem Client ausgeschaltet, fragt NBK einmal beim Login, ob es wieder an soll.",
                        sub = "_RememberMe",
                        flavor = "classic",
                        go = "list:remember_me",
                    },
                    {
                        en = "\"Rate group\": a new button in the Remember Me tab rates the players of your current party at any time - no Mythic+ run needed. Also with /nbk rate. Works in a party, not alone or in a raid.",
                        de = "\"Gruppe bewerten\": Ein neuer Knopf im Reiter \"Merken\" bewertet die Spieler deiner aktuellen Gruppe jederzeit - ganz ohne Mythic+-Lauf. Auch mit /nbk rate. Geht in einer Gruppe, nicht allein und nicht im Schlachtzug.",
                        sub = "_RememberMe",
                        go = "list:remember_me",
                    },
                    {
                        en = "Remember Me can ask by itself: three new settings under \"Remember Me\" - \"Ask when I leave a group\", \"Ask when someone leaves the group\" and \"Also in raids\". All off until you turn them on. NBK only asks about players you were with for at least 5 minutes and who aren't in Remember Me or on your blacklist yet, and it waits until combat is over.",
                        de = "Merken kann von selbst fragen: Drei neue Einstellungen unter \"Merken\" - \"Nachfragen, wenn ich eine Gruppe verlasse\", \"Nachfragen, wenn jemand die Gruppe verlässt\" und \"Auch im Schlachtzug\". Alle sind aus, bis du sie einschaltest. NBK fragt nur nach Spielern, mit denen du mindestens 5 Minuten zusammen warst und die noch nicht in Merken oder auf deiner Blacklist stehen, und wartet bis nach dem Kampf.",
                        sub = "_RememberMe",
                        go = "settings:RememberMe",
                    },
                    {
                        en = "New theme \"ModernBlizz\", On a wish from the community: styled like the Classic and modern UI - a gold frame with bevelled corners, gold buttons, column headers and field titles in gold capitals, and lists that let the picture show through. Pick it under \"Display\" > \"Theme\".",
                        de = "Neues Theme \"ModernBlizz\", auf Wunsch aus der Community: im Stil des Classic und modernen UI - Goldrahmen mit abgeschrägten Ecken, goldenen Knöpfen, Spaltenköpfen und Feldtiteln in Gold-Großbuchstaben und Listen, durch die das Bild scheint. Auswählbar unter \"Darstellung\" > \"Design\".",
                        go = "settings:Display",
                    },
                    {
                        en = "Mythic+: put someone on the blacklist during a key or from the window after the run, and the zone says which run it was - for example \"Halls of Atonement +13\". Outside a key the zone stays as before.",
                        de = "Mythic+: Wen du während eines Schlüssels oder aus dem Fenster nach dem Lauf auf die Blacklist setzt, bei dem steht als Zone der Lauf - zum Beispiel \"Das Blendende Tal +13\". Außerhalb eines Schlüssels bleibt die Zone wie bisher.",
                        flavor = "retail",
                    },
                    {
                        en = "Mythic+: Remember Me now keeps the run as well - in its own \"Run\" column and in the tooltip. \"Remember Me\" in the window after the run leaves the note free for your own words. Older entries simply have no run.",
                        de = "Mythic+: Merken hält jetzt auch den Lauf fest - in einer eigenen Spalte \"Lauf\" und im Tooltip. \"Merken\" im Fenster nach dem Lauf lässt die Notiz frei für deine eigenen Worte. Ältere Einträge haben einfach keinen Lauf.",
                        sub = "_RememberMe",
                        flavor = "retail",
                    },
                    {
                        en = "Mythic+: the window after the run also shows the time, for example \"Halls of Atonement +13 - timed (21:09)\".",
                        de = "Mythic+: Das Fenster nach dem Lauf zeigt auch die Zeit, zum Beispiel \"Das Blendende Tal +13 - im Limit (21:09)\".",
                        sub = "_RememberMe",
                        flavor = "retail",
                    },
                    {
                        en = "Group Finder: works with EllesmereUI Group Finder too - a group whose leader is on your blacklist gets a red stripe and a red name in its list as well.",
                        de = "Gruppensuche: klappt jetzt auch mit EllesmereUI Group Finder - eine Gruppe, deren Leiter auf deiner Blacklist steht, bekommt auch in dessen Liste eine rote Leiste und einen roten Namen.",
                        sub = "_GroupFinder",
                        flavor = "retail",
                    },
                    {
                        en = "Group Finder: the tooltip of a group says so when its leader is on your blacklist, with the reason.",
                        de = "Gruppensuche: Der Tooltip einer Gruppe sagt dir, wenn ihr Leiter auf deiner Blacklist steht - mit Grund.",
                        sub = "_GroupFinder",
                        flavor = "retail",
                    },
                },
            },
            {
                kind  = "changed",
                items = {
                    {
                        en = "WoW: Forever: Remember Me shows names as \"First Second\" without the server ID, just like the blacklist, and recognizes the same player everywhere - in the tooltip, the context menu and your group.",
                        de = "WoW: Forever: Merken zeigt Namen als \"Hauptname Zweitname\" ohne Server-Kennung, wie die Blacklist, und erkennt denselben Spieler überall - im Tooltip, im Kontextmenü und in deiner Gruppe.",
                        sub = "_RememberMe",
                        flavor = "forever",
                    },
                    {
                        en = "Switching the theme now also recolours list headers, tabs and the settings sidebar right away - before, they kept the old colours until a reload.",
                        de = "Beim Wechsel des Themes färben sich jetzt auch Listen-Kopfzeilen, Reiter und die Seitenleiste der Einstellungen sofort um - bisher behielten sie bis zu einem Reload die alten Farben.",
                    },
                    {
                        en = "Settings: modules from other authors now have their own group \"External modules\" in the sidebar, with a note on top that they weren't made by the NBK team - so you can tell at a glance what belongs to NBK and where to turn with questions.",
                        de = "Einstellungen: Module anderer Autoren stehen jetzt in einer eigenen Gruppe \"Externe Module\" in der Seitenleiste, oben mit einem Hinweis, dass sie nicht vom NBK-Team sind - so siehst du sofort, was zu NBK gehört und an wen du dich mit Fragen wendest.",
                    },
                    {
                        en = "Settings: the window grows with its sidebar, so every entry fits without scrolling.",
                        de = "Einstellungen: Das Fenster wächst mit seiner Seitenleiste, damit jeder Eintrag ohne Scrollen Platz hat.",
                    },
                    {
                        en = "Blacklist: the \"Zone\" column is as wide as its longest zone, so long zone names fit in every language. The window can't be made quite as narrow as before.",
                        de = "Blacklist: Die Spalte \"Zone\" ist so breit wie ihre längste Zone, damit lange Zonennamen in jeder Sprache passen. Ganz so schmal wie bisher lässt sich das Fenster dafür nicht mehr ziehen.",
                    },
                    {
                        en = "Statistics: \"Top zones\" counts a Mythic+ run for its dungeon - every key level together.",
                        de = "Statistik: \"Top-Zonen\" zählt einen Mythic+-Lauf zu seinem Dungeon - alle Stufen zusammen.",
                        sub = "_Statistics",
                        flavor = "retail",
                    },
                },
            },
            {
                kind  = "fixed",
                items = {
                    {
                        en = "Mythic+: the window after a run sometimes opened right at the start of a key. It now only comes when a run is finished - in time or over time. After an abandoned run, use \"Rate group\".",
                        de = "Mythic+: Das Fenster nach dem Lauf ging manchmal schon beim Start eines Schlüssels auf. Es kommt jetzt nur noch, wenn ein Lauf beendet ist - in der Zeit oder drüber. Nach einem abgebrochenen Lauf nimmst du \"Gruppe bewerten\".",
                        sub = "_RememberMe",
                        flavor = "retail",
                    },
                    {
                        en = "After putting a player on the blacklist as \"Name-Realm\" (slash command or dialog), NBK didn't offer to take them off Remember Me. It does now.",
                        de = "Wer einen Spieler als \"Name-Realm\" auf die Blacklist gesetzt hat (Slash-Befehl oder Dialog), bekam nicht die Frage, ihn aus Merken zu entfernen. Die kommt jetzt.",
                        sub = "_RememberMe",
                    },
                    {
                        en = "Classic: the chat line \"Only available on Retail, so turned off on this client\" could come back at every login.",
                        de = "Classic: Die Chatzeile \"Gibt es nur auf Retail, auf diesem Client deshalb ausgeschaltet\" konnte bei jedem Login wiederkommen.",
                        flavor = "classic",
                    },
                    {
                        en = "Group Finder: the warning before you sign up started with an empty gap - the warning sign is shown properly now.",
                        de = "Gruppensuche: Die Warnung vor dem Anmelden begann mit einer leeren Stelle - das Warnzeichen wird jetzt richtig angezeigt.",
                        sub = "_GroupFinder",
                        flavor = "retail",
                    },
                },
            },
            {
                kind  = "note",
                items = {
                    {
                        en = "Thanks to everyone who tested the four betas and sent in bugs and wishes - on our website nbk.nerzors.com, on Discord, GitHub and CurseForge!",
                        de = "Danke an alle, die die vier Betas getestet und Fehler und Wünsche gemeldet haben - auf unserer Webseite nbk.nerzors.com, im Discord, auf GitHub und CurseForge!",
                    },
                },
            },
        },
    },
    {
        version   = "2.2.0",
        date      = "2026-11-16",
        highlight = true,
        sections  = {
            {
                kind  = "new",
                items = {
                    {
                        en = "Ignore Manager, \"All characters\" rebuilt: the grid of players and characters is gone. On the left you now have your ignored players, on the right the player you clicked with every one of your characters listed below each other - each with a tick box and its state in plain words (\"Ignored\", \"Planned: remove at next login\", ...). No more paging through columns, however many characters you have.",
                        de = "Ignore-Manager, \"Alle Charaktere\" neu aufgebaut: Das Raster aus Spielern und Charakteren ist weg. Links stehen jetzt deine ignorierten Spieler, rechts der angeklickte Spieler mit all deinen Charakteren untereinander - jeweils mit Häkchen und dem Zustand in Worten (\"Ignoriert\", \"Geplant: beim nächsten Login entfernen\", ...). Kein Blättern durch Spalten mehr, egal wie viele Charaktere du hast.",
                        sub = "_IgnoreManager",
                        go = "list:ignore",
                    },
                    {
                        en = "What matters comes first: the characters a player is ignored on (or where a change is planned) are at the top and in colour, the others are dimmed. If a player is ignored on just one character, the list shows that character's name.",
                        de = "Das Wichtige steht oben: Charaktere, auf denen ein Spieler ignoriert ist (oder eine Änderung geplant ist), stehen zuerst und in Farbe, die übrigen sind gedämpft. Ist ein Spieler nur auf einem Charakter ignoriert, zeigt die Liste dessen Namen.",
                        sub = "_IgnoreManager",
                    },
                    {
                        en = "\"Import to NBK\" in \"All characters\": put ignored players on your blacklist from there too - one player in the detail pane, or everyone you ticked.",
                        de = "\"In NBK übernehmen\" in \"Alle Charaktere\": Ignorierte Spieler kommen jetzt auch von dort auf deine Blacklist - ein Spieler im Detailbereich oder alle angehakten.",
                        sub = "_IgnoreManager",
                        go = "list:ignore",
                    },
                    {
                        en = "Ignore Manager, \"All characters\": a new \"Tools\" menu top right. \"Copy list...\" puts the players ignored on one character onto others you tick - with a preview per character (\"+25 new, 12 already there, 3 don't fit\"). It only adds, nothing is removed.",
                        de = "Ignore-Manager, \"Alle Charaktere\": oben rechts ein neues Menü \"Werkzeuge\". \"Liste kopieren...\" setzt die Ignorierten eines Charakters auf andere, die du anhakst - mit Vorschau je Charakter (\"+25 neu, 12 schon da, 3 passen nicht\"). Es wird nur ergänzt, nichts entfernt.",
                        sub = "_IgnoreManager",
                        go = "list:ignore",
                    },
                    {
                        en = "\"Clean up...\": players that no longer exist, players ignored for months whom NBK hasn't seen since, and characters whose list is almost full. Nothing happens on its own - you tick who goes.",
                        de = "\"Aufräumen...\": Spieler, die es nicht mehr gibt, Spieler, die seit Monaten ignoriert sind und die NBK seitdem nicht gesehen hat, und Charaktere mit fast voller Liste. Von selbst passiert nichts - du hakst an, wer geht.",
                        sub = "_IgnoreManager",
                        go = "list:ignore",
                    },
                    {
                        en = "Export and import ignore lists as text: from one character or all of them, onto the characters you pick. An ignore list pasted into the blacklist import opens the right window by itself.",
                        de = "Ignorieren-Listen als Text exportieren und importieren: von einem oder allen Charakteren, auf die Charaktere, die du wählst. Eine Ignorieren-Liste im Blacklist-Import öffnet von selbst das richtige Fenster.",
                        sub = "_IgnoreManager",
                        go = "list:ignore",
                    },
                    {
                        en = "Right-click a row for a menu: edit, pin, mute, ignore, copy name, remove - in the blacklist, the ignore list and \"All characters\". Double-click opens the edit dialog.",
                        de = "Rechtsklick auf eine Zeile öffnet ein Menü: Bearbeiten, Anheften, Stummschalten, Ignorieren, Name kopieren, Entfernen - in der Blacklist, der Ignorieren-Liste und \"Alle Charaktere\". Doppelklick öffnet den Bearbeiten-Dialog.",
                        go = "list:blacklist",
                    },
                    {
                        en = "Search fields get an \"x\" to clear them; Esc clears the search too.",
                        de = "Suchfelder haben ein \"x\" zum Leeren; auch Esc leert die Suche.",
                    },
                    {
                        en = "The add / edit dialog works with the keyboard: the cursor starts in the first empty field, Enter saves, Tab jumps to the next field. Class and role sit side by side.",
                        de = "Der Dialog zum Eintragen und Bearbeiten geht mit der Tastatur: Der Cursor steht im ersten leeren Feld, Enter speichert, Tab springt ins nächste Feld. Klasse und Rolle stehen nebeneinander.",
                    },
                    {
                        en = "Window size: a new slider under \"Display\" makes every NBK window smaller or larger, from 80 to 130 %. Windows stay where they are.",
                        de = "Fenstergröße: Ein neuer Regler unter \"Anzeige\" macht alle NBK-Fenster kleiner oder größer, von 80 bis 130 %. Die Fenster bleiben an ihrem Platz.",
                        go = "settings:Display",
                    },
                    {
                        en = "The sort order is remembered: Blacklist and Remember Me open with the column and direction you picked last, also after a reload or on another character.",
                        de = "Die Sortierung bleibt erhalten: Blacklist und Merken öffnen mit der Spalte und Richtung, die du zuletzt gewählt hast - auch nach einem Reload oder auf einem anderen Charakter.",
                        go = "list:blacklist",
                    },
                    {
                        en = "Empty lists say why: Blacklist, Ignore list and Recents show a hint instead of a blank area when they are empty, and \"No matches\" when a search finds nothing.",
                        de = "Leere Listen sagen, warum: Blacklist, Ignorieren-Liste und Letzte Gruppen zeigen einen Hinweis statt einer leeren Fläche, wenn sie leer sind, und \"Keine Treffer\", wenn die Suche nichts findet.",
                    },
                },
            },
            {
                kind  = "changed",
                items = {
                    {
                        en = "Long lists stay fast: all lists now only draw the rows you can see. Searching, scrolling and \"Select all\" stay smooth with well over a thousand blacklist entries.",
                        de = "Lange Listen bleiben schnell: Alle Listen zeichnen nur noch die sichtbaren Zeilen. Suchen, Scrollen und \"Alle auswählen\" bleiben auch mit weit über tausend Blacklist-Einträgen flüssig.",
                    },
                    {
                        en = "Questions about a single player now name them (\"Ignore Anna-Aldor on all characters?\") instead of \"1 selected players\".",
                        de = "Fragen zu einem einzelnen Spieler nennen ihn jetzt beim Namen (\"Anna-Aldor auf allen Charakteren ignorieren?\") statt \"1 ausgewählte Spieler\".",
                    },
                    {
                        en = "WoW: Forever: the one-time name correction from 2.1.0 stays for good - on the community's wish, so it also helps if you skip a version.",
                        de = "WoW: Forever: Die einmalige Namenskorrektur aus 2.1.0 bleibt dauerhaft enthalten - auf Wunsch der Community, damit sie auch hilft, wenn du eine Version überspringst.",
                        flavor = "forever",
                    },
                },
            },
            {
                kind  = "fixed",
                items = {
                    {
                        en = "Message history: messages from muted players were saved 5 to 20 times each. Every message is now saved once, and the copies already stored are cleaned up at your next login.",
                        de = "Nachrichtenverlauf: Nachrichten stummgeschalteter Spieler wurden jeweils 5- bis 20-mal gespeichert. Jede Nachricht wird jetzt einmal gespeichert, und die schon vorhandenen Kopien werden beim nächsten Login bereinigt.",
                        sub = "_ChatFilters",
                        go = "list:history",
                    },
                },
            },
            {
                kind  = "note",
                items = {
                    {
                        en = "Thanks to everyone who tested the two betas! Please keep reporting anything odd on our website nbk.nerzors.com (report a bug, feedback) - or on Discord, GitHub or CurseForge.",
                        de = "Danke an alle, die die beiden Betas getestet haben! Bitte melde Auffälligkeiten weiter auf unserer Webseite nbk.nerzors.com (Fehler melden, Feedback) - oder im Discord, auf GitHub oder CurseForge.",
                    },
                },
            },
        },
    },
    {
        version   = "2.1.0",
        date      = "2026-11-10",
        highlight = true,
        sections  = {
            {
                kind  = "new",
                items = {
                    {
                        en = "Ignore Manager: This module extends the ignore list in NBK. The new \"All Characters\" view in the \"Ignore List\" tab gives you an overview of the ignore lists across all your characters. See who is ignored on which character and how up to date each list is. Log in with each character at least once to complete the overview.",
                        de = "Ignore-Manager: Dieses Module erweitert die Ignore-List in NBK. Die neue Ansicht \"Alle Charaktere\" im Reiter \"Ignorieren-Liste\" bietet dir eine Übersicht über die Ignorieren-Listen all deiner Charaktere. Sieh auf einen Blick, welcher Spieler auf welchem Charakter ignoriert wird und wie aktuell die jeweiligen Listen sind. Melde dich mit jedem Charakter mindestens einmal an, um die Übersicht zu vervollständigen.",
                        sub = "_IgnoreManager",
                        go  = "list:ignore",
                    },
                    {
                        en = "Manage ignore lists across characters: Add or remove players from another character's ignore list without switching characters. Simply click the corresponding field to schedule a change. The change will be applied the next time that character logs in. You can choose whether NBK asks for confirmation first or applies changes automatically under \"Notifications\".",
                        de = "Charakterübergreifende Verwaltung: Füge Spieler zur Ignorieren-Liste anderer Charaktere hinzu oder entferne sie, ohne den Charakter wechseln zu müssen. Klicke dazu einfach auf das entsprechende Feld. Die Änderung wird beim nächsten Login des betroffenen Charakters übernommen. Unter \"Benachrichtigungen\" kannst du festlegen, ob NBK vorher nachfragen oder die Änderungen automatisch durchführen soll.",
                        sub = "_IgnoreManager",
                        go  = "settings:Notifications",
                    },
                    {
                        en = "\"Ignore Everywhere\" and \"Remove Everywhere\": Select multiple players to add them to or remove them from the ignore lists of all your characters at once. Changes take effect immediately on your current character and on the next login for all other characters.",
                        de = "\"Überall ignorieren\" und \"Überall entfernen\": Wähle mehrere Spieler aus, um sie gleichzeitig auf allen deinen Charakteren zu ignorieren oder von den Ignorieren-Listen zu entfernen. Änderungen werden auf deinem aktuellen Charakter sofort und auf allen anderen beim nächsten Login übernommen.",
                        sub = "_IgnoreManager",
                        go  = "list:ignore",
                    },
                    {
                        en = "Clean up outdated entries: Characters that no longer exist are shown in grey on characters whose ignore lists have not yet been updated. Use \"Clean Up\" to remove these entries from the overview and, optionally, from your blacklist.",
                        de = "Veraltete Einträge bereinigen: Charaktere, die nicht mehr existieren, werden auf Charakteren mit noch nicht aktualisierten Ignorieren-Listen ausgegraut dargestellt. Mit \"Aufräumen\" kannst du diese Einträge aus der Übersicht und auf Wunsch auch aus deiner Blacklist entfernen.",
                        sub = "_IgnoreManager",
                    },
                    {
                        en = "WoW: Forever: names now read \"First Second\" everywhere, without the long server ID behind them. The realm column, the \"name and realm in one column\" setting and the \"Top realms\" card are gone there, and the search no longer matches the server ID.",
                        de = "WoW: Forever: Namen stehen jetzt überall als \"Hauptname Zweitname\" da, ohne die lange Server-Kennung dahinter. Realm-Spalte, die Einstellung \"Name und Realm in einer Spalte\" und die Karte \"Top-Realms\" gibt es dort nicht mehr, und die Suche findet nicht mehr alles über die Server-Kennung.",
                        flavor = "forever",
                    },
                    {
                        en = "WoW: Forever: slash commands take both names - /nbk add First Second reason. Texts that talked about realms are worded for Forever.",
                        de = "WoW: Forever: Slash-Befehle nehmen beide Namen - /nbk add Hauptname Zweitname Grund. Texte, die von Realms sprachen, sind für Forever umformuliert.",
                        flavor = "forever",
                    },
                    {
                        en = "Export only what you ticked: \"Export...\" in the blacklist's selection bar exports just the selected players.",
                        de = "Ausgewählte Spieler exportieren: Über die neue Option \"Exportieren...\" in der Auswahlleiste der Blacklist kannst du gezielt die ausgewählten Spieler exportieren, anstatt die gesamte Liste zu exportieren.",
                        go = "list:blacklist",
                    },
                    {
                        en = "Names with spaces work in slash commands everywhere when you put them in quotes: /nbk add \"Name\" reason.",
                        de = "Namen mit Leerzeichen gehen in Slash-Befehlen überall, wenn sie in Anführungszeichen stehen: /nbk add \"Name\" Grund.",
                    },
                    {
                        en = "If outdated NBK sub-addons (Tooltip, Nameplates) are still enabled, NBK tells you at login and can disable them for you.",
                        de = "Sind noch veraltete NBK-Sub-Addons (Tooltip, Nameplates) aktiviert, weist NBK beim Login darauf hin und kann sie für dich deaktivieren.",
                    },
                    {
                        en = "Group Finder and Remember Me only work on Retail. On other clients NBK now switches them off once, so the AddOn list no longer shows them as enabled.",
                        de = "Gruppensuche und Merken gibt es nur auf Retail. Auf anderen Clients schaltet NBK sie jetzt einmal aus, damit die AddOn-Liste sie nicht mehr als aktiviert zeigt.",
                        flavor = "classic",
                    },
                },
            },
            {
                kind  = "changed",
                items = {
                    {
                        en = "Localized ignore reasons: Built-in reasons such as \"Toxic\" or \"Quitter\" are now displayed in your selected language. This also applies to existing entries and lists shared by other players.",
                        de = "Lokalisierte Ignoriergründe: Vordefinierte Gründe wie \"Toxisch\" oder \"Abbrecher\" werden jetzt in deiner eingestellten Sprache angezeigt. Das gilt auch für bestehende Einträge und Listen, die andere Spieler mit dir teilen.",
                    },
                    {
                        en = "The remove dialog of the \"Ignore list\" tab says how many pinned entries would leave the blacklist too.",
                        de = "Das Entfernen-Fenster im Reiter \"Ignorieren-Liste\" zeigt, wie viele angeheftete Einträge dadurch aus deiner Blacklist entfernt würden.",
                        go = "list:ignore",
                    },
                    {
                        en = "Interface improvements: The main window's minimum width has been increased slightly to ensure all tabs fit in every supported language. The redundant \"Cancel\" button has been removed from the blacklist's selection bar, as \"Done\" serves the same purpose. Button spacing has also been improved to prevent overlapping text in longer translations.",
                        de = "Verbesserungen an der GUI: Die Mindestbreite des Hauptfensters wurde leicht erhöht, damit alle Reiter in jeder unterstützten Sprache ausreichend Platz haben. In der Auswahlleiste der Blacklist wurde die überflüssige Schaltfläche \"Abbrechen\" entfernt, da \"Fertig\" dieselbe Funktion erfüllt. Außerdem wurden die Abstände der Schaltflächen optimiert, damit sich längere Übersetzungen nicht mehr überlappen.",
                    },
                    {
                        en = "Button frames on hover are easier to see in the Nerzors and Midnight themes.",
                        de = "Knopf-Rahmen beim Überfahren mit der Maus sind in den Themes Nerzors und Midnight besser zu sehen.",
                    },
                },
            },
            {
                kind  = "fixed",
                items = {
                    {
                        en = "WoW: Forever: a player picked from the target, the group or a tooltip and the same player from the ignore list or chat were stored as two different players. They are one now, so the tooltip and the group warning recognize them either way. Entries saved the old way are switched once: a window explains it first, lists every entry and lets you export your blacklist before.",
                        de = "WoW: Forever: Ein Spieler über Ziel, Gruppe oder Tooltip und derselbe Spieler aus Ignorieren-Liste oder Chat galten als zwei verschiedene. Jetzt ist es einer, Tooltip und Gruppenwarnung erkennen ihn auf beiden Wegen. Alte Einträge stellt NBK einmalig um: Ein Fenster erklärt es vorher, zeigt jeden Eintrag und bietet an, die Blacklist vorher zu exportieren.",
                        flavor = "forever",
                    },
                    {
                        en = "Fixed an issue where removing players from the ignore list could fail silently if the game returned their names with different capitalization, such as lowercase letters.",
                        de = "Ein Fehler wurde behoben, durch den das Entfernen von Spielern aus der Ignorieren-Liste unbemerkt fehlschlagen konnte, wenn das Spiel deren Namen mit abweichender Groß- und Kleinschreibung zurückgab.",
                    },
                    {
                        en = "After \"Import to NBK\" in the \"Ignore list\" tab, the player now shows up in the blacklist right away.",
                        de = "Nach \"In NBK übernehmen\" im Reiter \"Ignorieren-Liste\" steht der Spieler jetzt sofort in der Blacklist.",
                        go = "list:blacklist",
                    },
                    {
                        en = "Fixed an issue where multi-line tooltips were cut off after the first line instead of displaying their full content.",
                        de = "Ein Fehler wurde behoben, durch den mehrzeilige Tooltips nach der ersten Zeile abgeschnitten wurden, anstatt den vollständigen Inhalt anzuzeigen.",
                    },
                    {
                        en = "Month names in Statistics now follow your game language.",
                        de = "Monatsnamen in der Statistik richten sich jetzt nach deiner Spielsprache.",
                        sub = "_Statistics",
                    },
                    {
                        en = "The hint above the chat filter whitelist was always in English.",
                        de = "Der Hinweis über der Whitelist der Chatfilter war immer auf Englisch.",
                        sub = "_ChatFilters",
                    },
                },
            },
            {
                kind  = "note",
                items = {
                    {
                        en = "Thanks to everyone who tested the two betas! Please keep reporting anything odd on our website nbk.nerzors.com (report a bug, feedback) - or on Discord, GitHub or CurseForge.",
                        de = "Danke an alle, die die beiden Betas getestet haben! Bitte melde Auffälligkeiten weiter auf unserer Webseite nbk.nerzors.com (Fehler melden, Feedback) - oder im Discord, auf GitHub oder CurseForge.",
                    },
                },
            },
        },
    },
    {
        version   = "2.0.0",
        date      = "2026-10-24",
        highlight = true,
        sections  = {
            {
                kind  = "new",
                items = {
                    {
                        en = "NBK now speaks eight languages: on top of English and German it comes in Italian, French, Portuguese (Brazil), Spanish (Latin America and Spain) and Russian. The language follows your game client automatically - nothing to set up.",
                        de = "NBK spricht jetzt acht Sprachen: Zu Englisch und Deutsch kommen Italienisch, Französisch, Portugiesisch (Brasilien), Spanisch (Lateinamerika und Spanien) und Russisch. Die Sprache richtet sich automatisch nach deinem Spiel-Client - einzustellen ist nichts.",
                    },
                    {
                        en = "New \"Ignore list\" tab: see the game's ignore list right in NBK, tick several players and remove them in one go - with the option to take them off your blacklist too. Players that are also blacklisted show their date, reason and note, and the rest can be moved to NBK with one click.",
                        de = "Neuer Reiter \"Ignorieren-Liste\": Die Ignorieren-Liste des Spiels direkt in NBK - mehrere Spieler anhaken und auf einmal entfernen, auf Wunsch auch gleich von der Blacklist. Wer zusätzlich auf der Blacklist steht, zeigt Datum, Grund und Notiz; alle anderen lassen sich mit einem Klick in NBK übernehmen.",
                        go = "list:ignore",
                    },
                    {
                        en = "NBK now notes when a player first shows up on your ignore list (the game itself keeps no date), and tells you when the game removes a character from it because it no longer exists.",
                        de = "NBK merkt sich jetzt, seit wann ein Spieler auf deiner Ignorieren-Liste steht (das Spiel selbst speichert kein Datum), und meldet, wenn das Spiel einen Charakter daraus entfernt, weil es ihn nicht mehr gibt.",
                    },
                    {
                        en = "The \"What's New\" window now features a \"Show me\" option, which takes you directly to the areas that have changed.",
                        de = "Das Fenster „Was ist neu?“ enthält jetzt die Option „Zeig es mir“, die dich direkt zu den geänderten Bereichen führt.",
                    },
                    {
                        en = "Chat messages and slash-command replies (/nbk list, /nbk check, sharing errors and so on) are translated now too - before, they were always in English.",
                        de = "Auch Chat-Meldungen und Antworten auf Slash-Befehle (/nbk list, /nbk check, Fehler beim Teilen usw.) sind jetzt übersetzt - bisher kamen sie immer auf Englisch.",
                    },
                    {
                        en = "WoW: Forever support: the same download now runs there too. Like on Classic, you get everything except Group Finder and Remember Me.",
                        de = "Unterstützung für WoW: Forever: Der gleiche Download läuft jetzt auch dort. Wie auf Classic gibt es alles außer Gruppensuche und Merken.",
                    },
                },
            },
            {
                kind  = "changed",
                items = {
                    {
                        en = "The [Import from ignore list] button has been moved to the \"Advanced\" section of the settings.",
                        de = "Funktion [Aus Ignorierliste importieren] wurde in den Bereich \"Erweitert\" der Einstellungen verschoben.",
                        go = "settings:Advanced",
                    },
                    {
                        en = "The setting \"Also add muted players to the game's ignore list\" remains under \"Notifications\".",
                        de = "Die Einstellung \"Stummgeschaltete Spieler auch zur Ignorieren-Liste des Spiels hinzufügen\" verbleibt unter \"Benachrichtigungen\".",
                        go = "settings:Notifications",
                    },
                    {
                        en = "Dates follow your language: 19/10/2026 on French, Spanish, Italian and Portuguese clients; English, German and Russian keep 19.10.2026.",
                        de = "Datumsangaben richten sich nach deiner Sprache: 19/10/2026 auf französischen, spanischen, italienischen und portugiesischen Clients; Englisch, Deutsch und Russisch bleiben bei 19.10.2026.",
                    },
                    {
                        en = "The \"Sci-Fi\" theme is now \"Forever\": in the style of WoW: Forever. If you were using Sci-Fi, you're switched over automatically.",
                        de = "Das Design \"Sci-Fi\" heißt jetzt \"Forever\": im Stil von WoW: Forever. Wer Sci-Fi genutzt hat, wird automatisch umgestellt.",
                        go = "settings:Display",
                    },
                    {
                        en = "New button look: every theme has its own, calmer button colours, main actions stand out, and you can see a button being pressed.",
                        de = "Neues Knopf-Design: Jedes Theme hat eigene, ruhigere Farben für Knöpfe, Haupt-Aktionen heben sich ab, und man sieht, wenn ein Knopf gedrückt wird.",
                    },
                },
            },
            {
                kind  = "fixed",
                items = {
                    {
                        en = "A few buttons and labels were worded differently depending on which modules you had installed (for example \"Add to Blacklist\"). They now read the same everywhere.",
                        de = "Ein paar Knöpfe und Beschriftungen hießen unterschiedlich, je nachdem, welche Module installiert waren (etwa \"Auf die Sperrliste\"). Sie lauten jetzt überall gleich.",
                        sub = "_Sync",
                    },
                    {
                        en = "Statistics was listed as \"out of date\" on Classic Era clients running 1.15.9.",
                        de = "Statistik wurde auf Classic-Era-Clients mit 1.15.9 als \"veraltet\" geführt.",
                        sub = "_Statistics",
                    },
                    {
                        en = "With an outdated Data folder, Statistics printed a cryptic message instead of asking you to update it.",
                        de = "Auf englischen Clients gab Statistik bei veraltetem Data-Ordner eine kryptische Meldung aus statt eines Update-Hinweises.",
                        sub = "_Statistics",
                    },
                    {
                        en = "Button text was hard to read on hover in some themes, especially Forever - fixed with the new button look. Buttons also grow with longer translations instead of letting the text run over the edge.",
                        de = "Die Schrift auf Knöpfen war beim Überfahren mit der Maus in manchen Themes schwer lesbar, vor allem in Forever - mit dem neuen Knopf-Design behoben. Außerdem wachsen Knöpfe bei längeren Übersetzungen mit, statt den Text über den Rand laufen zu lassen.",
                    },
                },
            },
            {
                kind  = "note",
                items = {
                    {
                        en = "2.0.0 is the first stable release of NBK V2. Version numbers are plain from now on: 2.0.1 for fixes, 2.1.0 for new features - no more \"-dev\".",
                        de = "2.0.0 ist die erste stabile Version von NBK V2. Versionsnummern sind ab jetzt schlicht: 2.0.1 für Fehlerbehebungen, 2.1.0 für neue Funktionen - kein „-dev\" mehr.",
                    },
                    {
                        en = "The new translations are complete, but not all of them have been proofread by native speakers yet. Spotted a clumsy line? Let us know - corrections are very welcome. This \"What's new?\" window stays in English and German.",
                        de = "Die neuen Übersetzungen sind vollständig, aber noch nicht alle von Muttersprachlern gegengelesen. Dir fällt eine holprige Stelle auf? Sag uns Bescheid - Korrekturen sind sehr willkommen. Dieses \"Was ist neu?\"-Fenster bleibt auf Englisch und Deutsch.",
                    },
                },
            },
        },
    },
    {
        version   = "0.46.0",
        date      = "2026-08-25",
        highlight = true,
        sections  = {
            {
                kind  = "new",
                items = {
                    {
                        en = "Data-broker support: NBK now appears on Titan Panel, ElvUI data texts and similar bars as a button - alongside the minimap icon. Left-click opens the list, right-click the settings.",
                        de = "Datenleisten-Unterstützung: NBK erscheint jetzt auch in Titan Panel, ElvUI-Datentexten und ähnlichen Leisten als Knopf - zusätzlich zum Minimap-Icon. Links-Klick öffnet die Liste, Rechts-Klick die Einstellungen.",
                    },
                    {
                        en = "Multi-select on the blacklist: a new \"Select\" button reveals checkboxes so you can mark several entries and delete them together, or mark them shareable/private in one go. Plus \"select all / none\".",
                        de = "Mehrfachauswahl in der Blacklist: ein neuer „Auswählen\"-Knopf blendet Kästchen ein - so kannst du mehrere Einträge markieren und gemeinsam löschen oder auf einen Schlag als teilbar/privat markieren. Dazu „Alle/keine auswählen\".",
                    },
                },
            },
        },
    },
    {
        version   = "0.45.0",
        date      = "2026-08-07",
        highlight = true,
        sections  = {
            {
                kind  = "new",
                items = {
                    {
                        en = "Statistics: a new \"Top realms\" card showing which realms your blacklist spans, alongside the top reasons and zones.",
                        de = "Statistik: eine neue Karte „Top-Realms\", die zeigt, auf welche Realms sich deine Blacklist verteilt - neben den Top-Gründen und -Zonen.",
                        sub = "_Statistics",
                        go = "list:statistics",
                    },
                    {
                        en = "NBK now appears in the game's own settings (Options > AddOns), with a button that opens the addon's settings window - where you'd look first for any addon.",
                        de = "NBK erscheint jetzt in den Spiel-Einstellungen (Optionen > AddOns), mit einem Knopf, der das Einstellungsfenster des Addons öffnet - dort, wo man bei einem Addon zuerst sucht.",
                    },
                },
            },
        },
    },
    {
        version   = "0.44.0",
        date      = "2026-07-28",
        highlight = true,
        sections  = {
            {
                kind  = "fixed",
                items = {
                    {
                        en = "Lua error from the message history in dungeons and raids (\"attempt to perform string conversion on a secret string value\"). The history now receives messages through the normal chat filter instead of reading the protected in-instance chat directly, so it no longer trips over it.",
                        de = "Lua-Fehler des Nachrichtenverlaufs in Dungeons und Schlachtzügen (\"attempt to perform string conversion on a secret string value\"). Der Verlauf bekommt Nachrichten jetzt über den normalen Chat-Filter, statt die geschützten Instanz-Chatdaten direkt abzugreifen - und stolpert nicht mehr darüber.",
                        sub = "_ChatFilters",
                    },
                    {
                        en = "\"What's new?\" showed up in English on non-English clients. Localised text is picked correctly now.",
                        de = "\"Was ist neu?\" wurde auf nicht-englischen Clients auf Englisch angezeigt. Übersetzte Texte werden jetzt korrekt gewählt.",
                    },
                    {
                        en = "A harmless error line at login about the ignore list. The ignore-list integration loads cleanly now.",
                        de = "Eine harmlose Fehlerzeile beim Login zur Ignorieren-Liste. Die Ignorieren-Anbindung lädt jetzt sauber.",
                    },
                },
            },
            {
                kind  = "changed",
                items = {
                    {
                        en = "List columns read better when narrow: the class column (as an icon) and the note column show a small icon instead of a squeezed or cut-off header (\"N...\"), with the full name on hover.",
                        de = "Schmale Listenspalten sind besser lesbar: die Klassen-Spalte (als Icon) und die Notiz-Spalte zeigen ein kleines Symbol statt einer gequetschten oder abgeschnittenen Überschrift (\"N...\"), mit dem vollen Namen beim Überfahren.",
                    },
                    {
                        en = "The \"Saved messages\" window now wraps long messages across several lines instead of cutting them off, so you can read the whole thing.",
                        de = "Das Fenster \"Gespeicherte Nachrichten\" bricht lange Nachrichten jetzt über mehrere Zeilen um, statt sie abzuschneiden - so ist der ganze Text lesbar.",
                        sub = "_ChatFilters",
                    },
                },
            },
        },
    },
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
                        go = "settings:Notifications",
                    },
                    {
                        en = "Import from your ignore list: already ignoring people? Pull them onto your blacklist in one go - you pick who first, nothing happens behind your back.",
                        de = "Import aus der Ignorieren-Liste: Du ignorierst schon Spieler? Hol sie mit einem Klick auf die Blacklist - du wählst vorher aus, wen; es passiert nichts ungefragt.",
                        go = "settings:Advanced",
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
                        go = "list:statistics",
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
                        go = "settings:ChatFilters",
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
}
