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
    cheatMode = false,    -- true if cheat mode is on
    actParam = nil,       -- act parameter data from a gem
    actGemName = nil,     -- gem name that triggered the act
    openDoc = nil,        -- name of the currently open doc in Documents view or nil if none
    lockedRoom = nil,     -- locked room that user is trying to enter or nil if none
    doorCode = nil,       -- door code for locked room or nil if none
    doorUnlocked = nil,   -- set to true when a locked door is successfully unlocked
    panelFixed = nil,     -- set to true when a circuit panel is successfully fixed

    -- Game state tracking
    stateStartTime = 0,   -- value of system.getTimer() when current game state started

    -- The saveState table is saved to a file between runs
    saveState = {
    	-- Game options settings
    	soundOn = false,    -- true to enable sounds
    	fxVolume = 1,       -- sound effects volume (0-1)
    	ambientVolume = 1,  -- ambient sound volume (0-1)

        -- Game sequence state
        onMars = false,     -- true when we make it to Mars
        shipState = 1,      -- ship sequence state number

        -- Gem state
        usedGems = {},  -- set of gem names that have been used
    
        -- The user's current resource levels (and starting values)
        resources = {
            o2 = 100,     -- oxygen in liters
            h2o = 100,    -- water in liters
            kWh = 100,    -- energy in kWh
            food = 100,   -- food in kg
        },

        -- rover map coordinates
        rover = {
            x1 = 0,     -- current position x coordinate
            y1 = 0,     -- current position y coordinate
            x2 = 0,     -- course x coordinate
            y2 = 0      -- course y coordinate
        },

        -- array of tables containing crater coordinates and radii
        crater = {
            { x = 15, y = -15, r = 5 },
            { x = 15, y = 15, r = 30 },
            { x = -15, y = -15, r = 20 },
            { x = -15, y = 15, r = 10 },
        },

        thrustNav = {
            onTarget = false,
            latestXTargetDelta = 100,
            latestYTargetDelta = 100,
            timesPlayed = 0
        },
            
        -- List of document filenames that user has found
        docs = {},
    },     
}

-- Shortcuts to access parts of the game data in this module
local ss = game.saveState
local res = ss.resources


-- File local variables
local messageBox           -- currently displayed message box or nil if none
local ambientSound = {
	handle = nil,    -- sound handle of sound loaded or nil if none
	name = nil,      -- filename of sound loaded or nil if none
	channel = nil,   -- sound channel number if playing or nil if not
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

-- Remove the given display object
function game.removeObj( obj )
    obj:removeSelf()
end

-- Do nothing
function game.emptyFunction()
end

-------------------------- Resource use   ---------------------------------

-- Accessors for resource amounts
function game.oxygen()  return res.o2    end
function game.water()   return res.h2o   end
function game.energy()  return res.kWh   end
function game.food()    return res.food  end

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

-- Display hint text for the user in a popup window.
-- The title is optional, defaults to "Hint".
-- If the onDismiss function is included, it is called when the user dismisses the popup.
function game.showHint( text, title, onDismiss )
	-- TODO: Make something better looking than a native alert?
	native.showAlert( title or "Hint", text, { "OK" }, onDismiss or game.emptyFunction )
end

-- Make floating message text that moves up from x, y then fades and disappears
function game.floatMessage( text, x, y )
    local text = display.newText( text, x, y, native.systemFontBold, 18 )
    text:setFillColor( 1, 1, 0 )   -- yellow
    transition.to( text, { x = x + 50, y = y - 100, xScale = 2, yScale = 2, time = 1000 } ) 
    transition.to( text, { alpha = 0, time = 1000, transition = easing.inQuad, 
            onComplete = game.removeObj } )
end

-- Destroy an active message box shown by game.messageBox, if any.
function game.endMessageBox()
    if messageBox then
        messageBox:removeSelf()
        messageBox = nil
    end
end

-- Touch handler for screen when a message box is shown
local function touchMessageBox( event )
    if event.phase == "began" then
        game.endMessageBox()
        return true
    end
end

-- Display a message box with the given text, centered on the screen.
-- Touching the screen anywhere will dismiss it.
-- The optional options table can include:
--     x, y       -- screen position to zoom box out from, default screen center
--     width      -- multi-line text wrapped to width, default single line
--     fontSize   -- font size, default 20
function game.messageBox( text, options )
    -- Dismiss existing message box if any, and make new group
    options = options or {}
    game.endMessageBox()
    messageBox = display.newGroup()    -- in global group
    messageBox.x = game.xCenter      -- centered on screen
    messageBox.y = game.yCenter

    -- Make a hit area to cover the screen to capture touch anywhere to dismiss
    local r = display.newRect( messageBox, 0, 0, game.width, game.height)
    r.isVisible = false
    r.isHitTestable = true
    r:addEventListener( "touch", touchMessageBox )

    -- Make a group for the visible part of the message box in the center of the screen
    local boxGroup = display.newGroup()
    messageBox:insert( boxGroup )

    -- Create a text object for the message text
    local text = display.newText{
        text = text,
        x = 0,
        y = 0,
        width = options.width,
        height = 0,
        font = native.systemFontBold,
        fontSize = options.fontSize or 20,
        align = "center",
    }
    text:setFillColor( 0 )  -- black

    -- Make a rounded rect for the message box with height sized for the text if necessary
    local dxyMarginText = 20     -- margin around text
    local radius = 10   -- corner radius
    local rr = display.newRoundedRect( text.x, text.y,
                    text.width + dxyMarginText * 2, text.height + dxyMarginText * 2, radius )
    rr:setFillColor( 1, 1, 0.4 )   -- pale yellow
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

    -- Make the box zoom in from the given point
    transition.from( boxGroup, { xScale = 0.2, yScale = 0.2, time = 350,
            x = (options.x or game.xCenter) - game.xCenter,
            y = (options.y or game.yCenter) - game.yCenter,
            transition = easing.outQuad } )
end


------------------------------ Sound  --------------------------------------

-- Play the sound if game sound is on
function game.playSound( sound, options )
	if ss.soundOn then
		return audio.play( sound, options )
	end
	return nil
end

-- Play the ambient sound with the given filename, or stop if filename is nil
function game.playAmbientSound( filename ) 
	-- Is the requested sound different from the previous one?
	if filename ~= ambientSound.name then
		-- Stop and discard previous sound.
		game.stopAmbientSound()
		if ambientSound.handle then 
			audio.dispose( ambientSound.handle )
			ambientSound.handle = nil
		end

		-- Load new sound, if any
		if filename then
			ambientSound.handle = audio.loadStream( "media/game/music/" .. filename )
		end
		ambientSound.name = filename
	end

	-- Play requested sound if not already playing
	if ss.soundOn and ambientSound.handle and not ambientSound.channel then
		ambientSound.channel = audio.play( ambientSound.handle, { loops = -1 } )
	end
end

-- Stop the current ambient sound if any
function game.stopAmbientSound()
	if ambientSound.channel then
		-- Stop sound but keep it loaded in case we restart the same sound.
		audio.stop( ambientSound.channel )
		ambientSound.channel = nil
	end
end


------------------------- Game management  --------------------------------

-- Init the game object
local function initGameObject()
    -- Hide device status bar
    display.setStatusBar( display.HiddenStatusBar )

    -- Get overall device screen metrics
    game.width = display.actualContentWidth
    game.height = display.actualContentHeight
    game.xMin = display.screenOriginX
    game.yMin = display.screenOriginY
    game.xMax = game.xMin + game.width
    game.yMax = game.yMin + game.height
    game.xCenter = (game.xMin + game.xMax) / 2
    game.yCenter = (game.yMin + game.yMax) / 2

    -- Set game UI element metrics
    game.dyTabBar = 40     -- Height of UI tab bar on all screens
end


-- Init and return the game object
initGameObject()
return game