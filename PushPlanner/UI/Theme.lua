-- PushPlanner - UI/Theme.lua
-- Single source of truth for colours, fonts, insets and backdrops.
-- Flat panels are built from a 1x1 white texture (Interface\Buttons\WHITE8x8)
-- tinted with SetBackdropColor / SetBackdropBorderColor, so no custom art
-- assets are required for the base look.

local _, PP = ...

local WHITE8X8 = "Interface\\Buttons\\WHITE8x8"

PP.Theme = {
    colors = {
        bg = { 0.05, 0.05, 0.06, 0.92 },
        panel = { 0.09, 0.09, 0.11, 0.95 },
        panelAlt = { 0.12, 0.12, 0.14, 0.95 },
        border = { 0.20, 0.20, 0.24, 1 },
        borderAccent = { 0.65, 0.55, 0.25, 1 },
        text = { 0.92, 0.92, 0.94, 1 },
        textDim = { 0.60, 0.60, 0.65, 1 },
        textTitle = { 0.85, 0.72, 0.35, 1 },
        good = { 0.25, 0.80, 0.35, 1 },
        bad = { 0.85, 0.25, 0.25, 1 },
        warn = { 0.90, 0.70, 0.20, 1 },
        accentDefault = { 0.4, 0.4, 0.45, 1 },
        hover = { 0.18, 0.18, 0.21, 1 },
        pressed = { 0.06, 0.06, 0.07, 1 },

        -- Solid fill for primary/accent buttons (e.g. Calculate).
        accentFill = { 0.72, 0.58, 0.22, 1 },
        accentFillHover = { 0.80, 0.65, 0.28, 1 },
        accentFillPressed = { 0.58, 0.46, 0.16, 1 },
        textOnAccent = { 0.12, 0.10, 0.05, 1 },
    },

    font = {
        normal = "Fonts\\FRIZQT__.TTF",
        size = 12,
        sizeSmall = 10,
        sizeLarge = 16,
        sizeTitle = 14,
        -- Result rows: a step up from size/sizeSmall so the run details read at a glance.
        sizeRow = 13,
        sizeRowSub = 11,
    },

    insets = {
        panel = 8,
        row = 6,
        gap = 6,
    },

    texture = {
        white = WHITE8X8,
    },
}

function PP.Theme:GetFont()
    local override = PP.db and PP.db.fontOverride
    return override or self.font.normal
end

-- Applies a flat colour backdrop with a thin border to any frame that was
-- created with the "BackdropTemplate" template (or inherits one).
-- Solid colour fill via SetBackdrop, but the border is drawn as four
-- explicit 1px textures rather than a backdrop edgeFile. A generic solid
-- texture used as edgeFile tiles unreliably at 1px (it can drop an edge
-- entirely). Pixel-grid snapping is also disabled on each hairline, since
-- a snapped 1px texture can round away to 0px on whichever edge lands on
-- a fractional pixel at the current UI scale (any edge, not just one).
local function NoSnap(tex)
    if tex.SetSnapToPixelGrid then
        tex:SetSnapToPixelGrid(false)
    end
    if tex.SetTexelSnappingBias then
        tex:SetTexelSnappingBias(0)
    end
end

-- Builds the four 1px hairline textures around a frame's edges (top,
-- bottom, left, right) and returns them as a table. Reused by SkinPanel
-- and by anything (like the minimap button) that needs the same ring
-- without the backdrop fill.
function PP.Theme:CreateBorder(frame, layer)
    local borders = {}

    borders.top = frame:CreateTexture(nil, layer)
    borders.top:SetTexture(self.texture.white)
    borders.top:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    borders.top:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    borders.top:SetHeight(1)

    borders.bottom = frame:CreateTexture(nil, layer)
    borders.bottom:SetTexture(self.texture.white)
    borders.bottom:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
    borders.bottom:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    borders.bottom:SetHeight(1)

    borders.left = frame:CreateTexture(nil, layer)
    borders.left:SetTexture(self.texture.white)
    borders.left:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    borders.left:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
    borders.left:SetWidth(1)

    borders.right = frame:CreateTexture(nil, layer)
    borders.right:SetTexture(self.texture.white)
    borders.right:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    borders.right:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    borders.right:SetWidth(1)

    for _, tex in pairs(borders) do
        NoSnap(tex)
    end

    return borders
end

function PP.Theme:SetBorderColor(borders, colorKey)
    local color = self.colors[colorKey or "border"]
    for _, tex in pairs(borders) do
        tex:SetVertexColor(unpack(color))
    end
end

-- Solid colour fill via SetBackdrop, but the border is drawn as four
-- explicit 1px textures rather than a backdrop edgeFile. A generic solid
-- texture used as edgeFile tiles unreliably at 1px (it can drop an edge
-- entirely).
function PP.Theme:SkinPanel(frame, colorKey, borderKey)
    local bg = self.colors[colorKey or "panel"]

    frame:SetBackdrop({ bgFile = self.texture.white })
    frame:SetBackdropColor(unpack(bg))

    if not frame.ppBorders then
        frame.ppBorders = self:CreateBorder(frame, "BORDER")
    end

    self:SetBorderColor(frame.ppBorders, borderKey)
end

function PP.Theme:CreateFontString(parent, sizeKey, colorKey, layer)
    local fs = parent:CreateFontString(nil, layer or "OVERLAY")
    local size = self.font[sizeKey] or self.font.size
    fs:SetFont(self:GetFont(), size, "")
    local c = self.colors[colorKey or "text"]
    fs:SetTextColor(unpack(c))
    -- Soft drop shadow lifts text off the darker panel fills.
    fs:SetShadowColor(0, 0, 0, 0.9)
    fs:SetShadowOffset(1, -1)
    return fs
end
