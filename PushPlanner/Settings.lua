-- PushPlanner - Settings.lua
-- Custom options panel, built entirely from our own widgets (no Blizzard
-- Interface Options canvas, no StaticPopup).

local _, PP = ...
local Theme = PP.Theme

PP.Settings = {}
local Settings = PP.Settings

local window

local function Build()
    window = PP.Widgets.Window.New({
        name = "PushPlannerSettings",
        title = "PushPlanner Settings",
        width = 320,
        height = 200,
    })

    local content = window.content

    local minimapCheckbox = PP.Widgets.Checkbox.New(content, {
        label = "Show minimap button",
        checked = not PP.db.minimap.hide,
        onChanged = function(checked)
            PP.MinimapButton:SetShown(checked)
        end,
    })
    minimapCheckbox:SetPoint("TOPLEFT", content, "TOPLEFT", 0, 0)

    local rememberCheckbox = PP.Widgets.Checkbox.New(content, {
        label = "Remember planner inputs",
        checked = PP.db.rememberInputs,
        onChanged = function(checked)
            PP.db.rememberInputs = checked
        end,
    })
    rememberCheckbox:SetPoint("TOPLEFT", minimapCheckbox, "BOTTOMLEFT", 0, -10)

    local resetButton = PP.Widgets.Button.New(content, {
        text = "Reset Inputs",
        width = 140,
        onClick = function()
            PP.Confirm("Reset target rating, max level and avoided dungeons?", function()
                PP.db.targetRating = 0
                PP.db.avoidedDungeons = {}
                PP.db.maxKeyLevel = 20
                if PP.MainWindow and PP.MainWindow.RefreshInputs then
                    PP.MainWindow:RefreshInputs()
                end
            end)
        end,
    })
    resetButton:SetPoint("TOPLEFT", rememberCheckbox, "BOTTOMLEFT", 0, -16)

    local versionText = Theme:CreateFontString(content, "sizeSmall", "textDim")
    versionText:SetPoint("BOTTOMLEFT", content, "BOTTOMLEFT", 0, 0)
    versionText:SetText("PushPlanner v" .. PP.version)
end

function Settings:Open()
    if not window then
        Build()
    end
    window:Show()
end
