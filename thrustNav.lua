-----------------------------------------------------------------------------------------
--
-- mainAct.lua
--
-- The main activity (map, etc.) the Mars App
-----------------------------------------------------------------------------------------

-- Get local reference to the game globals
local game = globalGame

-- Create the act object
local act = game.newAct()


-- try image.fill to change images...
--  create a rect then fill with image

------------------------- Start of Activity --------------------------------

-- File local variables
local xyText		-- text display object for touch location 
local xyCenterText	-- text display object for touch location relative to center
local ufo       	-- flying UFO object
local mars           -- planet mars
local earth         -- earth
-- works: local buttonTurnRight = display.newImageRect( "media/thrustNav/arrow-button.png", 30, 30 )
-- fails: local buttonTurnRight = display.newImageRect( act.group, "media/thrustNav/arrow-button.png", 30, 30 )

 -- button on left side that when pressed turns ship right
local buttonTurnLeft   -- button on right side that when pressed turns ship left
local buttonForward  -- button in center that when pressed thrusts forward
local spaceGroup    -- group for rotating space background

-- Make a small red circle centered at the given location
local function makeRedCircle( x, y )
	local c = display.newCircle( act.group, x, y, 20 )
	c:setFillColor(1, 0, 0)
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
	-- create group for rotating background space objects
	spaceGroup = act:newGroup()
	--- local buttonTurnRight = act:newImage( "arrow-button.png" )
	
	-- Create control buttons, background, etc.
	-- Button for left arrow rocket that turns ship right
	-- buttonTurnRight = act:newImage( "media/thrustNav/arrow-button.png", { width = 30, height = 30 } )
	-- buttonTurnRight = display.newImageRect( "arrow-button.png", 30, 30 )
    local buttonTurnRight = display.newImageRect( act.group, "media/thrustNav/arrow-button.png", 30, 30 )
	if (buttonTurnRight == nil ) then
		print("Problems for buttonTurnRight")
	end

	-- Button for right arrow rocket that turns ship left
	buttonTurnLeft = display.newImageRect( act.group, "media/thrustNav/arrow-button.png", 30, 30)
	-- Button for forward ship motion
	buttonForward = display.newImageRect( act.group, "media/thrustnav/arrow-button.png", 30, 30)  
	
		-- Background image with touch listener
	local bg = act.newImage( "starrynight.png", { parent = spaceGroup, x = act.xMin, y = act.yMin, width = 3*act.width } )
	bg:addEventListener( "touch", touched )
	print("bg=" .. bg )

	
	-- Small red circles at the corners
	-- makeRedCircle( act.xMin, act.yMin )
	-- makeRedCircle( act.xMin, act.yMax )
	--  makeRedCircle( act.xMax, act.yMin )
	-- makeRedCircle( act.xMax, act.yMax )

	-- Touch location text display objects
	--local yText = act.yMin + 15   -- relative to actual top of screen
	--xyText = display.newText( act.group, "", act.width / 3, yText, native.systemFont, 14 )
	--xyCenterText = display.newText( act.group, "", act.width * 2 / 3, yText, native.systemFont, 14 )

	-- Flying UFO
	-- local xStart = act.xMin - 100       -- start off screen to the left
	-- local yStart = act.yCenter - 142    -- height from center is consistent relative to background image
	-- ufo = act:newImage( "ufo.png", { x = xStart, y = yStart, height = 25 } )
    
    --act.group.x = act.width / 2
    spaceGroup.y = act.height / 2 - 100
	-- act.group.anchorX = 1
    -- act.group.anchorY = 0.5

    mars = display.newImageRect( spaceGroup, "media/thrustNav/mars.png", 30, 30 )
    -- mars.x = act.xCenter 
    -- mars.y = act.yMin + 40
    mars.x = act.xMin
    mars.y = -act.yMin +100 

    earth = display.newImageRect( spaceGroup, "media/thrustNav/earth.png", 20, 20 )
    -- earth = act:ImageRect( "earth.png", 20, 20 )
    earth.x = act.xMin
    earth.y = act.yMin - 200

  
    spaceGroup.x = act.width / 2 
    -- act.group.anchorX = 500

    --- physics.start()
    
    -- physics.addBody ( act.group, "dynamic" )
    --- act.group.gravityScale = 0         -- makes object float
	-- act.group:applyAngularImpulse ( 1000 )
    -- act.group.angularvelocity = 500
    
    -- Crosshair in the center
	local dy = 200
	local dx = 20
	display.newLine( act.xCenter, act.yCenter - dy, act.xCenter, act.yCenter + dy )
	display.newLine( act.xCenter - dx, act.yCenter, act.xCenter + dx, act.yCenter )
	
    -- Set up buttons

	buttonTurnLeft.x = act.xMin + (act.xMax - act.xMin) / 5
	buttonTurnLeft.y = act.yMax - (act.yMax - act.yMin) / 20
	buttonTurnLeft.isVisible = true

	buttonTurnRight.x = act.xMax - (act.xMax - act.xMin) / 5
	buttonTurnRight.y = act.yMax - (act.yMax - act.yMin) / 20
	buttonTurnRight.isVisible = true

	buttonForward.x = (act.xMax - act.xMin ) / 2
	buttonForward.y = act.yMax - (act.yMax - act.yMin) / 10 
	buttonForward.isVisible = true
	
	buttonTurnRight:addEventListener( "touch", buttonTurnRight )
	buttonTurnLeft:addEventListener( "touch", buttonTurnLeft )
	buttonForward:addEventListener( "touch", buttonForward )
end

function buttonTurnRight:touch (event)
	if event.phase == "began" then
		-- print( "Touch even began on: " .. self.id )
		print("Turn Right Button")
		-- act.group:applyAngularImpulse( -100 )
	end
	return true
end

function buttonTurnLeft:touch (event)
	if event.phase == "began" then
		-- print( "Touch even began on: " .. self.id )
		print("Turn Left Button")
		spaceGroup:applyAngularImpulse( 100 )
	end
	return true
end

function buttonForward:touch (event)
	if event.phase == "began" then
		-- print( "Touch even began on: " .. self.id )
		print("Forward Button - Rotation = " .. spaceGroup.rotation)
		if  spaceGroup.rotation > 90  then
			spaceGroup:applyLinearImpulse(0, 0.1, spaceGroup.x, spaceGroup.y )
		else
			spaceGroup:applyLinearImpulse(0, -0.1, spaceGroup.x, spaceGroup.y )
		end
	end
	return true
end

-- Handle enterFrame events
function act:enterFrame( event )
	-- Move UFO to the right and wrap around exactly at screen edges
	-- ufo.x = ufo.x + 1
	--- if ufo.x > act.xMax + ufo.width / 2 then
		--- ufo.x = act.xMin - ufo.width / 2
	-- end

end

------------------------- End of Activity --------------------------------


-- Corona needs the scene object returned from the act file
return act.scene
