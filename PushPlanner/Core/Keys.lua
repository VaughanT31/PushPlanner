-- PushPlanner - Core/Keys.lua
-- The keystones your group holds. The game can't show another player's
-- keystone, so group members tell each other with hidden addon messages:
--   * Push Planner's own messages, between group members who run Push
--     Planner (prefix "PushPlanner": "R" asks, "K:level:mapID:rating"
--     answers and announces a changed key).
--   * LibKeystone, when another addon you run has loaded it (BigWigs does).
--     It isn't part of Push Planner and isn't needed: when it's there, the
--     group members who run any addon with it answer too.
-- Nothing is stored between sessions; keys are asked for again when the
-- window opens and when the group changes.
--
-- PP.Keys.list() -> { { name, level, mapID, rating, me }, ... } for the
-- group, you first, then by key level.

local _, PP = ...

PP.Keys = {}
local Keys = PP.Keys

local PREFIX = "PushPlanner"
local REQUEST_EVERY = 5          -- seconds between requests, so opening and closing can't flood
local byName = {}                -- short name -> { level, mapID, rating, at }
local lastRequest = 0
local listeners = {}

local function Short(name)
    if not name then return nil end
    return Ambiguate and Ambiguate(name, "short") or (name:match("^[^%-]+") or name)
end

local function MyKey()
    if not C_MythicPlus then return nil end
    local level = C_MythicPlus.GetOwnedKeystoneLevel and C_MythicPlus.GetOwnedKeystoneLevel()
    local mapID = C_MythicPlus.GetOwnedKeystoneChallengeMapID and C_MythicPlus.GetOwnedKeystoneChallengeMapID()
    if not level or level == 0 or not mapID then return nil end
    return level, mapID
end

local function MyRating()
    local score = PP.Data.GetOverallRating and PP.Data.GetOverallRating() or 0
    return math.floor((score or 0) + 0.5)
end

local function Changed()
    for _, fn in ipairs(listeners) do pcall(fn) end
end

function Keys.OnChange(fn)
    listeners[#listeners + 1] = fn
end

local function InGroup()
    return IsInGroup() and not IsInRaid()
end

local function Channel()
    return IsInGroup(LE_PARTY_CATEGORY_INSTANCE) and "INSTANCE_CHAT" or "PARTY"
end

local function Send(text)
    if not InGroup() or not C_ChatInfo then return end
    pcall(C_ChatInfo.SendAddonMessage, PREFIX, text, Channel())
end

local lastAnnounce = 0
local function SendMine()
    -- Group changes come in bursts; one announcement covers them.
    if GetTime() - lastAnnounce < 1 then return end
    lastAnnounce = GetTime()
    local level, mapID = MyKey()
    Send(("K:%d:%d:%d"):format(level or 0, mapID or 0, MyRating()))
end

local function Note(name, level, mapID, rating)
    name = Short(name)
    if not name or name == Short(UnitName("player")) then return end
    level, mapID = tonumber(level) or 0, tonumber(mapID) or 0
    byName[name] = { level = level, mapID = mapID, rating = tonumber(rating), at = GetTime() }
    Changed()
end

-- Asks the group (both ways) for their keys.
function Keys.Request()
    if not InGroup() or GetTime() - lastRequest < REQUEST_EVERY then return end
    lastRequest = GetTime()
    Send("R")
    local lib = LibStub and LibStub("LibKeystone", true)
    if lib and lib.Request then pcall(lib.Request, "PARTY") end
end

-- Only the people still in the group.
local function Prune()
    local here = {}
    for i = 1, GetNumSubgroupMembers() do
        local name = UnitName("party" .. i)
        if name then here[Short(name)] = true end
    end
    for name in pairs(byName) do
        if not here[name] then byName[name] = nil end
    end
end

function Keys.List()
    local list = {}
    local level, mapID = MyKey()
    list[1] = { name = Short(UnitName("player")), level = level or 0, mapID = mapID or 0, rating = MyRating(), me = true, known = true }
    for i = 1, GetNumSubgroupMembers() do
        local unit = "party" .. i
        local name = Short(UnitName(unit))
        if name then
            local key = byName[name]
            list[#list + 1] = {
                name = name, unit = unit, level = key and key.level or 0, mapID = key and key.mapID or 0,
                rating = key and key.rating, known = key ~= nil,
            }
        end
    end
    table.sort(list, function(a, b)
        if a.me ~= b.me then return a.me == true end
        return (a.level or 0) > (b.level or 0)
    end)
    return list
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("CHAT_MSG_ADDON")
frame:RegisterEvent("GROUP_ROSTER_UPDATE")
frame:RegisterEvent("CHALLENGE_MODE_COMPLETED")
frame:RegisterEvent("ITEM_CHANGED")

local lastSent
frame:SetScript("OnEvent", function(_, event, ...)
    if event == "PLAYER_LOGIN" then
        if C_ChatInfo then C_ChatInfo.RegisterAddonMessagePrefix(PREFIX) end
        -- When another addon loaded LibKeystone, its answers come here too.
        local lib = LibStub and LibStub("LibKeystone", true)
        if lib and lib.Register then
            pcall(lib.Register, Keys, function(level, mapID, rating, name)
                Note(name, level, mapID, rating)
            end)
        end
    elseif event == "CHAT_MSG_ADDON" then
        local prefix, text, _, sender = ...
        if prefix ~= PREFIX or type(text) ~= "string" then return end
        if issecretvalue and (issecretvalue(text) or issecretvalue(sender)) then return end
        if Short(sender) == Short(UnitName("player")) then return end
        if text == "R" then
            SendMine()
        else
            local level, mapID, rating = text:match("^K:(%d+):(%d+):(%d+)$")
            if level then Note(sender, level, mapID, rating) end
        end
    elseif event == "GROUP_ROSTER_UPDATE" then
        Prune()
        Changed()
        -- Someone joined: tell them, and ask for theirs.
        if InGroup() then
            C_Timer.After(2, function()
                SendMine()
                Keys.Request()
            end)
        end
    else
        -- A run finished or the keystone changed: tell the group if it's different.
        C_Timer.After(1, function()
            local level, mapID = MyKey()
            local now = (level or 0) .. ":" .. (mapID or 0)
            if now ~= lastSent then
                lastSent = now
                SendMine()
                Changed()
            end
        end)
    end
end)
