-----------------------------------------------------------------------------------------
--
-- game.lua
--
-- The game object holds game global functions and data.
-----------------------------------------------------------------------------------------


---------------------------- Game Data  ------------------------------------

-- The game object where game global data and functions are stored
local game = {
    -- Misc constants
    themeColor = { r = 0.58, g = 0, b = 0 },            -- dark red
    themeHighlightColor = { r = 0.78, g = 0, b = 0 },    -- light red

    -- Data for the current act to use
    cheatMode = false,    -- true if cheat mode is on (debug)
    allGems = false,      -- true to always show all gems (debug)
    actParam = nil,       -- act parameter data from a gem
    actGemName = nil,     -- gem name that triggered the act
    openDoc = nil,        -- name of the currently open doc in Documents view or nil if none
    lockedRoom = nil,     -- locked room that user is trying to enter or nil if none
    doorCode = nil,       -- door code for locked room or nil if none
    doorUnlocked = nil,   -- set to true when a locked door is successfully unlocked
    panelFixed = nil,     -- set to true when a circuit panel is successfully fixed
    shipLanded = nil,     -- set to true when landing game succeeds

    -- Game state tracking
    paused = false,         -- true when the game is paused
    currentMainAct = nil,   -- name of act currently running on the main tab
    stateStartTime = 0,     -- value of system.getTimer() when current game state started
    moves = 0,              -- number of times dot has moved since game start

    -- The saveState table is saved to a file between runs
    saveState = {
    	-- Game options settings
    	soundOn = true,    -- true to enable sounds
    	fxVolume = 0.7,       -- sound effects volume (0-1)
    	ambientVolume = 0.7,  -- ambient sound volume (0-1)

        -- Game sequence state
        onMars = false,     -- true when we make it to Mars
        shipState = 1,      -- ship sequence state number
        stasis = false,     -- true when emergency stasis is needed

        -- Gem state
        usedGems = {},  -- set of gem names that have been used
    
        -- The user's current resource levels (and starting values)
        resources = {
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

        -- array of tables containing crater coordinates and radius
        craters = {
            { x = 61.70370864868, y = 60.601856708525, r = 4 },
            { x = 5.7847226858137, y = 54.266208052634, r = 4 },
            { x = -78.782413721082, y = -0.5509259700775, r = 4 },
            { x = 49.032411336898, y = 26.44444656372, r = 3.3 },
            { x = 81.53704357147, y = 70.51852416992, r = 3 },
            { x = 78.506950736044, y = -49.307874321936, r = 3 },
            { x = 77.680561780928, y = -71.344913125036, r = 3 },
            { x = 72.72222805023, y = -19.006945967674, r = 2.5 },
            { x = 41.87037372589, y = -57.29630088806, r = 1.8 },
            { x = 84.842599391935, y = -62.254634618757, r = 1.8 },
            { x = -51.236115217207, y = -62.254634618757, r = 1.5 },
            { x = -81.53704357147, y = -62.805560588835, r = 1.5 },
            { x = 18.731482982635, y = 12.120371341705, r = 1.5 },
            { x = 60.050930738447, y = 35.25926208496, r = 1.5 },
            { x = -64.733801484106, y = 9.916667461395, r = 1.5 },
            { x = -77.12963581085, y = -5.509259700775, r = 1.3 },
            { x = -76.578709840773, y = 40.217595815658, r = 1.3 },
            { x = -54.541671037673, y = -50.134263277052, r = 1.3 },
            { x = 18.456019997596, y = -39.115743875503, r = 1 },
            { x = 26.719909548759, y = 52.337967157363, r = 1 },
            { x = 41.87037372589, y = 62.805560588835, r = 1 },
            { x = 8.81481552124, y = 42.972225666045, r = 1 },
            { x = 60.050930738447, y = -49.583337306975, r = 1 },
            { x = 18.180557012558, y = -35.25926208496, r = 1 },
            { x = -25.893520593642, y = -15.976853132247, r = 1 },
            { x = -32.504632234572, y = -13.773149251937, r = 1 },
            { x = -9.916667461395, y = -7.1620376110075, r = 1 },
            { x = -18.180557012558, y = 14.324075222015, r = 1 },
            { x = 18.180557012558, y = -17.078705072402, r = 0.8 },
            { x = 20.384260892868, y = -14.599538207054, r = 0.8 },
            { x = -28.097224473953, y = 19.83333492279, r = 0.8 },
            { x = 37.738428950309, y = 24.24074268341, r = 0.8 },
            { x = -30.85185432434, y = -1.3773149251937, r = 0.6 },
            { x = -33.331021189689, y = 1.3773149251937, r = 0.6 },
            { x = -17.078705072402, y = 4.6828707456587, r = 0.6 },
            { x = 1.6527779102325, y = 36.361114025115, r = 0.6 },
            { x = 29.199076414107, y = 25.342594623565, r = 0.6 },
            { x = 13.22222328186, y = 13.22222328186, r = 0.6 },
            { x = 11.569445371627, y = 2.20370388031, r = 0.6 },
            { x = 42.145836710929, y = 30.300928354262, r = 0.6 },
            { x = 46.002318501471, y = 36.912039995193, r = 0.6 },
            { x = 23.689816713333, y = 33.606484174727, r = 0.5 },
            { x = 24.24074268341, y = 36.912039995193, r = 0.4 },
            { x = 39.391206860541, y = 2.20370388031, r = 0.4 },
            { x = 1.101851940155, y = 22.587964773178, r = 0.4 },
            { x = -33.05555820465, y = -18.731482982635, r = 0.3 },
            { x = 7.4375005960462, y = -19.557871937751, r = 0.3 },
            { x = -22.312501788139, y = -1.101851940155, r = 0.3 },
            { x = -30.576391339301, y = 20.935186862945, r = 0.3 },
            { x = -20.384260892868, y = 1.101851940155, r = 0.3 },
            { x = -21.210649847984, y = -10.192130446434, r = 0.3 },
            { x = -22.587964773178, y = -10.467593431472, r = 0.3 },
            { x = -23.689816713333, y = -11.01851940155, r = 0.3 },
            { x = -17.62963104248, y = 2.4791668653487, r = 0.3 },
            { x = -30.85185432434, y = 17.078705072402, r = 0.3 },
            { x = -20.108797907829, y = 42.145836710929, r = 0.3 },
            { x = 4.6828707456587, y = -19.557871937751, r = 0.3 },
            { x = -1.6527779102325, y = 2.7546298503875, r = 0.2 },
            { x = 1.6527779102325, y = 3.5810188055037, r = 0.2 },
            { x = 8.2638895511625, y = 0.82638895511624, r = 0.2 },
            { x = 12.946760296821, y = 0.82638895511624, r = 0.2 },
            { x = 13.22222328186, y = 2.20370388031, r = 0.2 },
            { x = 15.150464177131, y = 8.81481552124, r = 0.2 },
            { x = -1.101851940155, y = 11.844908356666, r = 0.2 },
            { x = -11.01851940155, y = -3.8564817905425, r = 0.2 },
            { x = 2.7546298503875, y = -5.2337967157362, r = 0.2 },
            { x = 4.40740776062, y = -7.9884265661237, r = 0.2 },
            { x = 0.27546298503874, y = -8.81481552124, r = 0.2 },
            { x = 10.467593431472, y = -6.3356486558912, r = 0.2 },
            { x = 15.42592716217, y = -7.712963581085, r = 0.2 },
            { x = 8.81481552124, y = -15.701390147209, r = 0.2 },
            { x = 6.3356486558912, y = -20.935186862945, r = 0.2 },
            { x = 2.7546298503875, y = 25.618057608604, r = 0.2 },
            { x = -2.4791668653487, y = 31.127317309379, r = 0.2 },
            { x = -7.1620376110075, y = 29.199076414107, r = 0.2 },
            { x = -7.9884265661237, y = 28.372687458991, r = 0.2 },
            { x = -13.22222328186, y = 17.62963104248, r = 0.2 },
            { x = -19.006945967674, y = 23.414353728294, r = 0.2 },
            { x = -36.912039995193, y = 28.372687458991, r = 0.2 },
            { x = -31.127317309379, y = 32.229169249534, r = 0.2 },
            { x = -30.576391339301, y = 12.395834326744, r = 0.2 },
            { x = -38.564817905425, y = 14.324075222015, r = 0.2 },
            { x = -35.810188055038, y = 14.048612236976, r = 0.2 },
            { x = -38.013891935348, y = 12.946760296821, r = 0.2 },
            { x = -39.115743875503, y = 11.844908356666, r = 0.2 },
            { x = -34.157410144805, y = 4.9583337306975, r = 0.2 },
            { x = -19.83333492279, y = 7.4375005960462, r = 0.2 },
            { x = -15.150464177131, y = -6.8865746259687, r = 0.2 },
            { x = -37.738428950309, y = -3.8564817905425, r = 0.2 },
            { x = -17.078705072402, y = 36.361114025115, r = 0.2 },
            { x = -20.935186862945, y = 2.20370388031, r = 0.2 },
            { x = -17.62963104248, y = -11.293982386589, r = 0.2 },
            { x = -11.569445371627, y = -22.587964773178, r = 0.2 },
            { x = -10.743056416511, y = -23.689816713333, r = 0.2 },
            { x = 25.618057608604, y = -13.497686266899, r = 0.2 },
            { x = 36.912039995193, y = -14.048612236976, r = 0.2 },
            { x = 40.493058800696, y = -19.282408952713, r = 0.2 },
            { x = 46.553244471549, y = -12.395834326744, r = 0.2 },
            { x = 38.840280890464, y = -9.3657414913175, r = 0.2 },
            { x = 37.738428950309, y = -3.305555820465, r = 0.2 },
            { x = 43.523151636123, y = 7.9884265661237, r = 0.2 },
            { x = 19.557871937751, y = 28.372687458991, r = 0.2 },
            { x = 43.247688651084, y = 40.217595815658, r = 0.2 },
            { x = 37.46296596527, y = -11.293982386589, r = 0.2 },
            { x = 27.821761488914, y = -12.395834326744, r = 0.2 },
            { x = 50.960652232169, y = -28.097224473953, r = 0.2 },
            { x = 13.22222328186, y = 15.150464177131, r = 0.2 },
            { x = -20.659723877906, y = -21.210649847984, r = 0.2 },
            { x = -19.006945967674, y = -23.965279698371, r = 0.2 },
            { x = -10.192130446434, y = 7.4375005960462, r = 0.2 },
            { x = 34.432873129844, y = -27.546298503875, r = 0.2 },
            { x = 54.266208052634, y = 17.62963104248, r = 0.2 },
            { x = 26.44444656372, y = 0, r = 0.2 },
            { x = -34.708336114882, y = -26.995372533798, r = 0.2 },
            { x = -38.840280890464, y = -17.354168057441, r = 0.2 },
            { x = 42.421299695968, y = 43.247688651084, r = 0.2 },
            { x = 48.756948351859, y = -19.557871937751, r = 0.2 },
            { x = 20.935186862945, y = 15.42592716217, r = 0.2 },
            { x = 26.995372533797, y = 16.252316117286, r = 0.2 },
            { x = 31.402780294417, y = 15.976853132247, r = 0.2 },
        },

        thrustNav = {
            onTarget = false,
            latestXTargetDelta = 100,
            latestYTargetDelta = 100,
            state = 0  -- 0=start of first play
            --            1=finished first play
            --            2=start of second play
            --            3=finished second play
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
function game.water()   return res.h2o   end
function game.energy()  return res.kWh   end
function game.food()    return res.food  end

-- Add to or subtract from the water supply by the given amount in liters
function game.addWater( liters )
    res.h2o = res.h2o + liters
    if res.h2o < 0 then
        res.h2o = 0
    end
end

-- Add to or subtract from the energy supply by the given amount in kWh
function game.addEnergy( kWh )
    res.kWh = game.pinValue( res.kWh + kWh, 0, 100 )
end

-- Add to or subtract from the food supply by the given amount in kg
function game.addFood( kg )
    res.food = res.food + kg
    if res.food < 0 then
        res.food = 0
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

-- Dismiss an active message box shown by game.messageBox, if any.
function game.endMessageBox()
    if messageBox then
        transition.cancel( messageBox )   -- cancel auto fade out
        local onDismiss = messageBox.onDismiss
        messageBox:removeSelf()
        messageBox = nil
        if onDismiss then
            onDismiss()
        end
    end
end

-- Display a message box with the given text.
-- The box will automatically dismiss after a time delay.
-- The optional options table can include:
--     x, y       -- screen position to zoom box out from, default screen center
--     time       -- milliseconds to leave on screen, default 3000
--     width      -- multi-line text wrapped to width, default single line
--     fontSize   -- font size, default 18
--     onTouch    -- function to call if message is touched
--     onDismiss  -- function to call when message is dismissed
function game.messageBox( text, options )
    -- Dismiss existing message box if any, and make new group
    options = options or {}
    game.endMessageBox()
    messageBox = display.newGroup()    -- in global group
    messageBox.x = game.xCenter
    messageBox.y = game.yMin + game.height * 0.2   -- in upper part of screen
    messageBox.onDismiss = options.onDismiss

     -- Create a text object for the message text
    local text = display.newText{
        text = text,
        x = 0,
        y = 0,
        width = options.width,
        height = 0,
        font = native.systemFontBold,
        fontSize = options.fontSize or 18,
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
    rr:addEventListener( "touch", options.onTouch or game.eatTouch )

    -- Make another rounded rect as a shadow
    local dxyOffset = 5
    local shadow = display.newRoundedRect( rr.x + 5, rr.y + 5, rr.width, rr.height, radius )
    shadow:setFillColor( 0 )   -- black
    shadow.alpha = 0.5

    -- Stack the parts in the right order
    messageBox:insert( shadow )
    messageBox:insert( rr )
    messageBox:insert( text )

    -- Make the box zoom in from the given point
    transition.from( messageBox, { xScale = 0.2, yScale = 0.2, time = 350,
            x = (options.x or game.xCenter),
            y = (options.y or game.yCenter),
            transition = easing.outQuad } )

    -- Set to fade out then dismiss after time delay
    transition.to( messageBox, { alpha = 0, 
            delay = (options.time or 3000), time = 250, 
            onComplete = game.endMessageBox } )
end


------------------------------ Sound  --------------------------------------

-- Play the sound if game sound is on. See audio.play for options.
-- Return the channel number used or nil if not played.
function game.playSound( sound, options )
	if ss.soundOn then
		local ch = audio.play( sound, options )
        if ch and ch > 0 then
            audio.setVolume( ss.fxVolume, { channel = ch } ) 
            return ch
        end
	end
	return nil
end

-- Stop the sound effect playing on the given channel
function game.stopSound( channel )
    if channel and channel > 0 then
        return audio.stop( channel )
    end
end

-- Dispose of the sound if it is non nil (careful: the sound must not be playing)
function game.disposeSound( sound )
    if sound then
        audio.dispose( sound )
    end
end

-- Play the ambient sound with the given filename, or restart last sound if filename is nil.
-- In either case, the volume is adjusted to the user's current selected level.
function game.playAmbientSound( filename )
	-- Restart previous sound if filename is nil
	if not filename then
		filename = ambientSound.name
	end

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

	-- Play requested sound if not already playing, and adjust volume
	if ss.soundOn and ambientSound.handle then
		if not ambientSound.channel then
			ambientSound.channel = audio.play( ambientSound.handle, { loops = -1 } )
			if ambientSound.channel <= 0 then 
				ambientSound.channel = nil   -- failed to play sound
			end
		end
		if ambientSound.channel then
        	audio.setVolume( ss.ambientVolume, { channel = ambientSound.channel } ) 
        end
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

    -- Get overall device screen metrics and then use width 320 if wider (e.g. iPad)
    local dxBar = (display.actualContentWidth - 320) / 2
    if dxBar > 0 then
        game.width = 320
        game.xMin = 0
    else
        game.width = display.actualContentWidth
        game.xMin = display.screenOriginX
    end
    game.height = display.actualContentHeight
    game.yMin = display.screenOriginY
    game.xMax = game.xMin + game.width
    game.yMax = game.yMin + game.height
    game.xCenter = (game.xMin + game.xMax) / 2
    game.yCenter = (game.yMin + game.yMax) / 2

    -- Add side bars to cover any extra width
    if dxBar > 0 then
        print(dxBar)
        game.sideBars = display.newGroup()
        local bar = display.newRect( game.sideBars, game.xMin - dxBar / 2, game.yCenter, 
                        dxBar + 1, game.height )
        bar:setFillColor( game.themeColor.r, game.themeColor.g, game.themeColor.b )
        bar = display.newRect( game.sideBars, game.xMax + dxBar / 2, game.yCenter,
                        dxBar + 1, game.height )
        bar:setFillColor( game.themeColor.r, game.themeColor.g, game.themeColor.b )
    end

    -- Set game UI element metrics
    game.dyTabBar = 40     -- Height of UI tab bar on all screens
end


-- Init and return the game object
initGameObject()
return game