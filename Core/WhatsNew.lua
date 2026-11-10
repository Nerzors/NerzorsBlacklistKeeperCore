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
                        en = "Thanks to everyone who tested the two betas! Please keep reporting anything odd on Discord, GitHub or CurseForge.",
                        de = "Danke an alle, die die beiden Betas getestet haben! Bitte melde Auffälligkeiten weiter im Discord, auf GitHub oder CurseForge.",
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
