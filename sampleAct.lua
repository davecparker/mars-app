-----------------------------------------------------------------------------------------
--
-- sampleAct.lua
--
-- A sample activity (map, etc.) the Mars App
-----------------------------------------------------------------------------------------

-- Get local reference to the game globals
local game = globalGame

-- Create the act object
local act = game.newAct()


------------------------- Start of Activity --------------------------------

-- File local variables
local xyText		-- text display object for touch location 
local xyCenterText	-- text display object for touch location relative to center
local ufo       	-- flying UFO object


-- Make a small green circle centered at the given location
local function makeGreenCircle( x, y )
	local c = display.newCircle( act.group, x, y, 20 )
	c:setFillColor( 0, 0, 1 )  -- blue
	return c
end

-- Handle touches on the background by updating the text displays
local function touched( event )
	-- Get touch location but pin to the act bounds
	local x = game.pinValue( event.x, act.xMin, act.xMax )
	local y = game.pinValue( event.y, act.yMin, act.yMax )

	-- Update the absolute and center-relative coordinate displays
	xyText.text = string.format( "(%d, %d)", x, y )
	xyCenterText.text = string.format( "Center + (%d, %d)", x - act.xCenter, y - act.yCenter )
end

-- Init the act
function act:init()
	-- Background image with touch listener
	local bg = act:newImage( "Canyon480x800.jpg", { width = act.width } )
	bg:addEventListener( "touch", touched )

	-- Crosshair in the center
	local dxy = 20
	display.newLine( act.group, act.xCenter - dxy, act.yCenter, act.xCenter + dxy, act.yCenter )
	display.newLine( act.group, act.xCenter, act.yCenter - dxy, act.xCenter, act.yCenter + dxy )
	
	-- Small green circles at the corners
	makeGreenCircle( act.xMin, act.yMin )
	makeGreenCircle( act.xMin, act.yMax )
	makeGreenCircle( act.xMax, act.yMin )
	makeGreenCircle( act.xMax, act.yMax )

	-- Touch location text display objects
	local yText = act.yMin + 15   -- relative to actual top of screen
	xyText = display.newText( act.group, "", act.width / 3, yText, native.systemFont, 14 )
	xyCenterText = display.newText( act.group, "", act.width * 2 / 3, yText, native.systemFont, 14 )

	-- Flying UFO
	local xStart = act.xMin - 100       -- start off screen to the left
	local yStart = act.yCenter - 142    -- height from center is consistent relative to background image
	ufo = act:newImage( "ufo.png", { x = xStart, y = yStart, height = 25 } )

	-- Post a new document (TODO: Temporary)
	game.foundDocument( "UFO Sighting Protocol" )
end

-- Handle enterFrame events
function act:enterFrame( event )
	-- Move UFO to the right and wrap around exactly at screen edges
	ufo.x = ufo.x + 3
	if ufo.x > act.xMax + ufo.width / 2 then
		ufo.x = act.xMin - ufo.width / 2

		-- Use some energy for each UFO pass
		game.addEnergy( -5 )

		game.sendMessage( "ufo" )  -- TODO: Temporary
	end
end

------------------------- End of Activity --------------------------------


-- Corona needs the scene object returned from the act file
return act.scene
