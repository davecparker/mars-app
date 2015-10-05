-----------------------------------------------------------------------------------------
--
-- game.lua
--
-- The game object holds game global functions and data.
-----------------------------------------------------------------------------------------


---------------------------- Game Data  ------------------------------------

-- The game object where game global data and functions are stored
local game = {
    mapZoom = false,  -- currently just true if map view is zoomed
    openDoc = nil,    -- name of the currently open doc in Documents view or nil if none

    -- The saveState table is saved to a file between runs
    saveState = {
        docs = {},    -- list of document filenames that user had found
    },     
}


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