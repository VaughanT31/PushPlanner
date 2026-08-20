-- PushPlanner - UI/Widgets/Window.lua
-- PP.Widgets.Window: the outer panel with a titlebar and a custom close
-- button. Draggable, closable, remembers its position via a savedPosition
-- table (point/x/y) that the caller owns.

local _, PP = ...
local Theme = PP.Theme

PP.Widgets.Window = {}
local Window = PP.Widgets.Window

local TITLEBAR_HEIGHT = 28

function Window.New(opts)
    opts = opts or {}
    local width = opts.width or 480
    local height = opts.height or 420
    local savedPosition = opts.savedPosition

    local frame = CreateFrame("Frame", opts.name, UIParent, "BackdropTemplate")
    frame:SetSize(width, height)
    frame:SetFrameStrata("HIGH")
    Theme:SkinPanel(frame, "bg", "border")

    if savedPosition and savedPosition.point then
        frame:SetPoint(savedPosition.point, UIParent, savedPosition.point, savedPosition.x or 0, savedPosition.y or 0)
    else
        frame:SetPoint("CENTER")
    end

    -- Titlebar
    local titlebar = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    titlebar:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    titlebar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    titlebar:SetHeight(TITLEBAR_HEIGHT)
    Theme:SkinPanel(titlebar, "panelAlt", "border")

    local title = Theme:CreateFontString(titlebar, "sizeTitle", "textTitle")
    title:SetPoint("LEFT", titlebar, "LEFT", 10, 0)
    title:SetText(opts.title or "")

    local close = CreateFrame("Button", nil, titlebar)
    close:SetSize(18, 18)
    close:SetPoint("RIGHT", titlebar, "RIGHT", -6, 0)
    local closeText = Theme:CreateFontString(close, "size", "textDim")
    closeText:SetPoint("CENTER")
    closeText:SetText("X")
    close:SetScript("OnEnter", function() closeText:SetTextColor(unpack(Theme.colors.bad)) end)
    close:SetScript("OnLeave", function() closeText:SetTextColor(unpack(Theme.colors.textDim)) end)
    close:SetScript("OnClick", function() frame:Hide() end)

    titlebar:EnableMouse(true)
    titlebar:RegisterForDrag("LeftButton")
    titlebar:SetScript("OnDragStart", function() frame:StartMoving() end)
    titlebar:SetScript("OnDragStop", function()
        frame:StopMovingOrSizing()
        if savedPosition then
            local point, _, _, x, y = frame:GetPoint()
            savedPosition.point = point
            savedPosition.x = x
            savedPosition.y = y
        end
    end)
    frame:SetMovable(true)

    -- Content area, below the titlebar, inset by theme padding.
    local content = CreateFrame("Frame", nil, frame)
    local pad = Theme.insets.panel
    content:SetPoint("TOPLEFT", frame, "TOPLEFT", pad, -(TITLEBAR_HEIGHT + pad))
    content:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -pad, pad)

    frame.titlebar = titlebar
    frame.titleText = title
    frame.closeButton = close
    frame.content = content

    frame:Hide()
    return frame
end
