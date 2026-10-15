-- PushPlanner - Core/UnitMenu.lua
-- "Plan their Mythic+ push" in the right-click menu on players: party and
-- raid frames, your target, chat names, friends and guild. Opens the
-- planner for them (Core/Subjects.lua): from the game when they're in your
-- group or targeted, otherwise by name from the Raider.IO addon's data.

local _, PP = ...

-- Menus that are about one player. A tag this client doesn't have is simply
-- never opened, so listing extra ones is harmless.
local MENU_TAGS = {
    "MENU_UNIT_PLAYER", "MENU_UNIT_FRIEND", "MENU_UNIT_PARTY", "MENU_UNIT_RAID_PLAYER",
    "MENU_UNIT_TARGET", "MENU_UNIT_FOCUS", "MENU_UNIT_BN_FRIEND", "MENU_UNIT_GUILD",
    "MENU_UNIT_COMMUNITIES_GUILD_MEMBER", "MENU_UNIT_COMMUNITIES_MEMBER",
}

local function Secret(value)
    return issecretvalue and value ~= nil and issecretvalue(value)
end

local function SubjectFrom(contextData)
    if not contextData then return nil end
    local unit = contextData.unit
    if unit and not Secret(unit) and UnitExists(unit) and UnitIsPlayer(unit) and not UnitIsUnit(unit, "player") then
        local label = PP.Subjects.UnitLabel(unit)
        if label then
            return { kind = "unit", unit = unit, label = label }
        end
    end
    local name, server = contextData.name, contextData.server
    if not name or name == "" or Secret(name) or (server and Secret(server)) then return nil end
    if UnitName("player") == name and (not server or server == "" or server == GetNormalizedRealmName()) then
        return nil
    end
    local realm = server ~= "" and server or nil
    return { kind = "name", name = name, realm = realm, label = realm and (name .. "-" .. realm) or name }
end

local function AddToMenu(_, rootDescription, contextData)
    local subject = SubjectFrom(contextData)
    if not subject then return end
    rootDescription:CreateDivider()
    rootDescription:CreateButton("Plan their Mythic+ push", function()
        PP.MainWindow:OpenFor(subject)
    end)
end

if Menu and Menu.ModifyMenu then
    for _, tag in ipairs(MENU_TAGS) do
        pcall(Menu.ModifyMenu, tag, AddToMenu)
    end
end
