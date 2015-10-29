-----------------------------------------------------------------------------------------
--
-- game.lua
--
-- The game object holds game global functions and data.
-----------------------------------------------------------------------------------------


---------------------------- Game Data  ------------------------------------

-- The game object where game global data and functions are stored
local game = {
    -- Data for the current act to use
    actParam = nil,       -- act parameter data from a gem
    actGemName = nil,     -- gem name that triggered the act
    openDoc = nil,        -- name of the currently open doc in Documents view or nil if none

    -- The saveState table is saved to a file between runs
    saveState = {
        usedGems = {},  -- set of gem names that have been used
        docs = {},      -- list of document filenames that user has found

        -- The user's current resource levels (and starting values)
        resources = {
            o2 = 100,     -- oxygen in liters
            h2o = 100,    -- water in liters
            kWh = 100,    -- energy in kWh
            food = 100,   -- food in kg
        },
    },     
}

-- Shortcuts to access parts of the game data in this module
local res = game.saveState.resources

-- File local variables
local messageBox       -- currently displayed message box or nil if none


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


------------------------- User interface  ---------------------------------

-- Immediately end and destroy the active message box (no end animation)
-- that was shown by game.messageBox() if any
function game.endMessageBox()
    if messageBox then
        print("Dismiss")
        messageBox:removeSelf()
        messageBox = nil
    end
end

-- Display a message box with the given text.
-- Touching the screen anywhere will dismiss it.
function game.messageBox( text )
    -- Dismiss existing message box if any, and make new group
    game.endMessageBox()
    messageBox = display.newGroup()    -- in global group
    messageBox.x = game.xCenter      -- centered on screen
    messageBox.y = game.yCenter

   -- Make a hit area to cover the screen to capture touch anywhere to dismiss
    local r = display.newRect( messageBox, 0, 0, game.width, game.height)
    r:setFillColor( 0 )
    r.alpha = 0.25    -- darkens screen slightly
    r:addEventListener( "touch", game.endMessageBox )

    -- Make a group for the visible part of the message box in the center of the screen
    local boxGroup = display.newGroup()
    messageBox:insert( boxGroup )

    -- Create a text object for the message text
    local text = display.newText{
        text = text,
        x = 0,
        y = 0,
        -- width = game.width * 0.7,     -- TODO: Support multi-line
        -- height = 0,  -- auto-size the height
        font = native.systemFontBold,
        fontSize = 20,
        align = "center",
    }
    text:setFillColor( 1 )  -- white

    -- Make a rounded rect for the message box with height sized for the text if necessary
    local dxyMarginText = 20     -- margin around text
    local radius = 10   -- corner radius
    local rr = display.newRoundedRect( text.x, text.y,
                    text.width + dxyMarginText * 2, text.height + dxyMarginText * 2, radius )
    rr:setFillColor( 0.5, 0, 0 )   -- dark red
    rr:setStrokeColor( 0 )   -- black
    rr.strokeWidth = 2

    -- Make another rounded rect as a shadow
    local dxyOffset = 5
    local shadow = display.newRoundedRect( rr.x + 5, rr.y + 5, rr.width, rr.height, radius )
    shadow:setFillColor( 0 )   -- black
    shadow.alpha = 0.5

    -- Stack the parts in the right order
    boxGroup:insert( shadow )
    boxGroup:insert( rr )
    boxGroup:insert( text )

    -- Make the box zoom in
    transition.from( boxGroup, { xScale = 0.2, yScale = 0.2, time = 200, 
            transition = easing.outCubic } )
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