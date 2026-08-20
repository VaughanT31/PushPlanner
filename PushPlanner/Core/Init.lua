-- PushPlanner - Core/Init.lua
-- Boot: namespace table, saved variable defaults, slash commands.

local ADDON_NAME, PP = ...
_G.PP = PP

PP.name = "PushPlanner"
PP.version = "0.1.0"

PP.Widgets = PP.Widgets or {}
PP.L = PP.L or {}

local DB_DEFAULTS = {
    targetRating = 0,
    avoidedDungeons = {},
    maxKeyLevel = 20,
    rememberInputs = true,
    minimap = {
        hide = false,
        angle = 200,
    },
    window = {
        point = "CENTER",
        x = 0,
        y = 0,
    },
    fontOverride = nil,
}

local function CopyDefaults(src, dst)
    for k, v in pairs(src) do
        if type(v) == "table" then
            if type(dst[k]) ~= "table" then
                dst[k] = {}
            end
            CopyDefaults(v, dst[k])
        elseif dst[k] == nil then
            dst[k] = v
        end
    end
    return dst
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:RegisterEvent("PLAYER_LOGIN")
loader:SetScript("OnEvent", function(_, event, addonName)
    if event == "ADDON_LOADED" and addonName == ADDON_NAME then
        PushPlannerDB = CopyDefaults(DB_DEFAULTS, PushPlannerDB or {})
        PP.db = PushPlannerDB
    elseif event == "PLAYER_LOGIN" then
        if PP.MinimapButton then
            PP.MinimapButton:Init()
        end
    end
end)

local function ToggleWindow()
    if PP.MainWindow then
        PP.MainWindow:Toggle()
    end
end

local function OpenSettings()
    if PP.Settings then
        PP.Settings:Open()
    end
end

SLASH_PUSHPLANNER1 = "/pp"
SLASH_PUSHPLANNER2 = "/pushplanner"
SlashCmdList["PUSHPLANNER"] = function(msg)
    msg = (msg or ""):lower():match("^%s*(.-)%s*$")
    if msg == "config" or msg == "settings" or msg == "options" then
        OpenSettings()
    elseif msg == "reset" then
        PP.db.targetRating = 0
        PP.db.avoidedDungeons = {}
        PP.db.maxKeyLevel = DB_DEFAULTS.maxKeyLevel
        if PP.MainWindow and PP.MainWindow.RefreshInputs then
            PP.MainWindow:RefreshInputs()
        end
        print("|cff33cc99PushPlanner:|r inputs reset.")
    else
        ToggleWindow()
    end
end
