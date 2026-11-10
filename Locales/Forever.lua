local _, NBK = ...

local function forever(locale, strings)
    NBK:RegisterFlavorStrings("forever", locale, strings)
end

forever("enUS", {
    ["Search name, realm, reason..."] = "Search name, reason...",
    ["name[-realm]"] = "First and second name",
})
forever("deDE", {
    ["Search name, realm, reason..."] = "Name, Grund suchen...",
    ["name[-realm]"] = "Haupt- und Zweitname",
})
forever("itIT", {
    ["Search name, realm, reason..."] = "Cerca nome, motivo...",
    ["name[-realm]"] = "Nome principale e secondo nome",
})
forever("frFR", {
    ["Search name, realm, reason..."] = "Rechercher nom, raison...",
    ["name[-realm]"] = "Nom principal et second nom",
})
forever("ptBR", {
    ["Search name, realm, reason..."] = "Buscar nome, motivo...",
    ["name[-realm]"] = "Nome principal e segundo nome",
})
forever("esMX", {
    ["Search name, realm, reason..."] = "Buscar nombre, motivo...",
    ["name[-realm]"] = "Nombre principal y segundo nombre",
})
forever("ruRU", {
    ["Search name, realm, reason..."] = "Поиск: имя, причина...",
    ["name[-realm]"] = "Основное и второе имя",
})
