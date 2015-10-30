-----------------------------------------------------------------------------------------
--
-- game.lua
--
-- The game object holds game global functions and data.
-----------------------------------------------------------------------------------------


---------------------------- Game Data  ------------------------------------

-- The game object where game global data and functions are stored
local game = {
    mapZoomName = nil,    -- name of currently zoomed map view or nil if not zoomed
    openDoc = nil,        -- name of the currently open doc in Documents view or nil if none

    -- The saveState table is saved to a file between runs
    saveState = {
        -- The user's current resource levels (and starting values)
        resources = {
            o2 = 100,     -- oxygen in liters
            h2o = 100,    -- water in liters
            kWh = 100,    -- energy in kWh
            food = 100,   -- food in kg
        },

        roverCoord = {
            x1 = 0,
            y1 = 0,
            x2 = 0,
            y2 = 0
        },

        -- List of document filenames that user has found
        docs = {},
    },     
}

-- Shortcuts to access parts of the game data in this module
local res = game.saveState.resources


------------------------- Utility Functions  --------------------------------

-- Return the value constrained to the range from min to max
function game.pinValue( value, min, max )
    if value < min then 
        return min
    elseif value > max then
        return max
    end
    return value
end

-- Return true if (x, y) is inside the rect (left, top, right, bottom)
function game.xyInRect( x, y, rect )
    return x >= rect.left and x <= rect.right and y >= rect.top and y <= rect.bottom
end

-- Return true if two pairs of x, y coords are close within dxy
function game.xyHitTest( x1, y1, x2, y2, dxy )
    return math.abs( x1 - x2 ) <= dxy and math.abs( y1 - y2 ) <= dxy
end

-- Return true to eat a touch or tap event
function game.eatTouch()
    return true
end


-------------------------- Resource use   ---------------------------------

-- Add to or subtract from the oxygen supply by the given amount in liters
function game.addOxygen( liters )
    res.o2 = res.o2 + liters
    if res.o2 < 0 then
        res.o2 = 0    -- TODO: Initiate emergency statis or something
    end
end

-- Add to or subtract from the water supply by the given amount in liters
function game.addWater( liters )
    res.h2o = res.h2o + liters
    if res.h2o < 0 then
        res.h2o = 0   -- TODO: Initiate emergency statis or something
    end
end

-- Add to or subtract from the energy supply by the given amount in kWh
function game.addEnergy( kWh )
    res.kWh = res.kWh + kWh
    if res.kWh < 0 then
        res.kWh = 0   -- TODO: Initiate emergency statis or something
    end
end

-- Add to or subtract from the food supply by the given amount in kg
function game.addFood( kg )
    res.food = res.food + kg
    if res.food < 0 then
        res.food = 0   -- TODO: Initiate emergency statis or something
    end
end


------------------------- Game management  --------------------------------

-- Init the game
local function initGame()
    -- Hide device status bar
    display.setStatusBar( display.HiddenStatusBar )

    -- Get device and content metrics
    local dxContent = display.contentWidth
    local dyContent = display.contentHeight
    local dxDevice = display.actualContentWidth
    local dyDevice = display.actualContentHeight
    local dxBleed = (dxDevice - dxContent) / 2   -- TODO: Force this to 0?
    local dyBleed = (dyDevice - dyContent) / 2

    -- Set overall game screen metrics
    game.width = dxDevice 
    game.height = dyDevice
    game.xMin = -dxBleed
    game.xMax = dxContent + dxBleed
    game.yMin = -dyBleed
    game.yMax = dyContent + dyBleed
    game.xCenter = (game.xMin + game.xMax) / 2
    game.yCenter = (game.yMin + game.yMax) / 2

    -- Set game UI element metrics
    game.dyTabBar = 40     -- Height of UI tab bar on all screens
end


-- Init and return the game object
initGame()
return game