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

local buttonTurnLeft   -- button to turn ship left
local buttonTurnRight  -- button to turn ship right
local buttonRollLeft   -- button to Roll ship left
local buttonRollRight  -- button to Roll ship right
local buttonPitchUp    -- button to pitch ship up
local buttonPitchDown  -- button to pitch ship down
local ship             -- ship object
local spaceGroup    -- group for rotating space background
local xDelta, yDelta, rotDelta  -- positional deltas used on each enter frame
local xDeltaInc, yDeltaInc, rotDeltaInc  -- increments for the deltas
local navStatsText     -- text string for nav stats


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



function buttonTurnLeftTouch (event)
	if event.phase == "began" then
		-- print( "Touch even began on: " .. self.id )
		print("Turn Left Button")
		-- spaceGroup:applyAngularImpulse( -10000 )
		xDelta = xDelta + xDeltaInc
	end
	return true
end

function buttonTurnRightTouch (event)
	if event.phase == "began" then
		--transition.to( rect, { rotation=-45, time=500, transition=easing.inOutCubic } )
		print("Turn Right Button, rotation= ", spaceGroup.rotation )
		-- spaceGroup:applyAngularImpulse( 10000 )
		--- spaceGroup:applyTorque( -10000 )
		xDelta = xDelta - xDeltaInc
	end
	return true
end


function buttonRollLeftTouch (event)
	if event.phase == "began" then
		-- print( "Touch even began on: " .. self.id )
		print("Roll Left Button")
		-- spaceGroup:applyAngularImpulse( -10000 )
		rotDelta = rotDelta + rotDeltaInc
	end
	return true
end

function buttonRollRightTouch (event)
	if event.phase == "began" then
		--transition.to( rect, { rotation=-45, time=500, transition=easing.inOutCubic } )
		print("Roll Right Button, rotation= ", spaceGroup.rotation )
		-- spaceGroup:applyAngularImpulse( 10000 )
		--- spaceGroup:applyTorque( -10000 )
		rotDelta = rotDelta - rotDeltaInc
	end
	return true
end

function buttonPitchUpTouch (event)
	if event.phase == "began" then
		-- print( "Touch even began on: " .. self.id )
		print("Pitch Up Button - Rotation = ", spaceGroup.rotation)
		--- if  spaceGroup.rotation > 90  then
		--- else
			--- spaceGroup:applyLinearImpulse(0, -0.1, spaceGroup.x, spaceGroup.y )
		---end
		yDelta = yDelta + yDeltaInc
	end
	return true
end

function buttonPitchDownTouch (event)
	if event.phase == "began" then
		-- print( "Touch even began on: " .. self.id )
		print("Pitch Down Button - Rotation = ", spaceGroup.rotation)
		--- if  spaceGroup.rotation > 90  then
			---spaceGroup:applyLinearImpulse(0, 0.1, spaceGroup.x, spaceGroup.y )
		---else
			-- spaceGroup:applyLinearImpulse(0, -1, spaceGroup.x, spaceGroup.y )
		-- end
		yDelta = yDelta - yDeltaInc
	end
	return true
end



-- Init the act
function act:init()
	-- create group for rotating background space objects
	spaceGroup = act:newGroup()

	-- Create control buttons, background, etc.
	buttonTurnLeft = display.newImageRect(act.group, "media/thrustNav/arrow-button.png",30,30)
	buttonTurnLeft.rotation = -90
	buttonTurnRight = display.newImageRect(act.group, "media/thrustNav/arrow-button.png",30,30)
	buttonTurnRight.rotation = 90
	buttonRollLeft = display.newImageRect(act.group, "media/thrustNav/arrow-button.png",30,30)
	buttonRollRight = display.newImageRect(act.group, "media/thrustNav/arrow-button.png",30,30)
	buttonPitchUp = display.newImageRect(act.group, "media/thrustnav/arrow-button.png",30,30)
	buttonPitchDown = display.newImageRect(act.group, "media/thrustnav/arrow-button.png",30,30)
	buttonPitchDown.rotation = 180

		-- Background image with touch listener
	--- local bg = act.newImage( "starrynight.png", { parent = spaceGroup, x = act.xMin, y = act.yMin, width = 3*act.width } )
	local bg = display.newImageRect( spaceGroup, "media/thrustNav/starrynight.png", 5*act.width, 5*act.height )
	-- bg:addEventListener( "touch", touched )
	print("bg=", bg )

	local yText = act.yMin + 30
	navStatsText = display.newText( act.group, "Hello", act.width / 3, yText, native.systemFont, 14 )
	print( "navStatsText=" , navStatsText )
	-- Touch location text display objects
	-- local yText = act.yMin + 15   -- relative to actual top of screen
	-- xyText = display.newText( act.group, "", act.width / 3, yText, native.systemFont, 14 )
	-- xyCenterText = display.newText( act.group, "", act.width * 2 / 3, yText, native.systemFont, 14 )

	spaceGroup.y = act.height / 2 - 100
	-- act.group.anchorX = 1
    -- act.group.anchorY = 0.5


	ship = display.newImageRect(spaceGroup, "media/thrustNav/shipconcepts.png", 30, 30 )
	
    mars = display.newImageRect( spaceGroup, "media/thrustNav/mars.png", 30, 30 )
    -- mars.x = act.xCenter 
    -- mars.y = act.yMin + 40
    print("act.xMin=",act.xMin, " act.yMin=", act.yMin)
    mars.x = act.xMin
    mars.y = act.yMin +100
    print("Mars is placed at ", mars.x, ",", mars.y , " in spaceGroup before move") 

    earth = display.newImageRect( spaceGroup, "media/thrustNav/earth.png", 20, 20 )
    -- earth = act:ImageRect( "earth.png", 20, 20 )
    earth.x = act.xMin
    earth.y = act.yMax - 100
    print("Earth is placed at ", earth.x, ",", earth.y , " in spaceGroup before move") 
    
  
  	-- Fix anchors to be at cross hairs for start
    spaceGroup.x = act.xCenter 
    spaceGroup.anchorX = spaceGroup.x
    spaceGroup.y = act.yCenter
    spaceGroup.anchorY =spaceGroup.y

	-- physics.start()   --- physics.start()
    -- physics.addBody ( spaceGroup, "dynamic" )
    -- spaceGroup.gravityScale = 0         -- makes object float
	-- spaceGroup:applyAngularImpulse( 100000 )
	-- spaceGroup.isSleepingAllowed = false
	xDelta = 0
	yDelta = 0
	rotDelta = 0
	xDeltaInc = 0.1
	yDeltaInc = 0.1
	rotDeltaInc = 0.01

	-- Could try transition with iterations=-1 for continuous
	--- transition.to(fuseObj, { iterations=-1,rotation=-360,time=250})


    -- Crosshair in the center
	local dy = 200
	local dx = 20
	display.newLine( act.group, act.xCenter, act.yCenter - dy, act.xCenter, act.yCenter + dy )
	display.newLine( act.group, act.xCenter - dx, act.yCenter, act.xCenter + dx, act.yCenter )

	-- place ship at center of lines
	ship.x = act.yCenter
	ship.y = act.xCenter

    -- Set up buttons
	buttonTurnLeft.x = act.xCenter - (act.xMax - act.xMin) / 15
	buttonTurnLeft.y = act.yMax - (act.yMax - act.yMin) / 15
	buttonTurnLeft.isVisible = true

	buttonTurnRight.x = act.xCenter + (act.xMax - act.xMin) / 15
	buttonTurnRight.y = act.yMax - (act.yMax - act.yMin) / 15
	buttonTurnRight.isVisible = true

	buttonRollLeft.x = act.xMax - (act.xMax - act.xMin) / 8
	buttonRollLeft.y = act.yMax - (act.yMax - act.yMin) / 20
	buttonRollLeft.isVisible = true

	buttonRollRight.x = act.xMin + (act.xMax - act.xMin) / 5
	buttonRollRight.y = act.yMax - (act.yMax - act.yMin) / 20
	buttonRollRight.isVisible = true

	buttonPitchUp.x = (act.xMax - act.xMin ) / 2
	buttonPitchUp.y = act.yMax - (act.yMax - act.yMin) / 10 
	buttonPitchUp.isVisible = true

	buttonPitchDown.x = (act.xMax - act.xMin ) / 2
	buttonPitchDown.y = act.yMax - (act.yMax - act.yMin) / 30 
	buttonPitchDown.isVisible = true

	buttonTurnLeft:addEventListener( "touch", buttonTurnLeftTouch )
	buttonTurnRight:addEventListener( "touch", buttonTurnRightTouch )
	buttonRollLeft:addEventListener( "touch", buttonRollLeftTouch )
	buttonRollRight:addEventListener( "touch", buttonRollRightTouch )
	buttonPitchUp:addEventListener( "touch", buttonPitchUpTouch )
	buttonPitchDown:addEventListener( "touch", buttonPitchDownTouch )

end

function updateNavStats()
	local awake
	local xOnTarget = ""
	local yOnTarget = ""

	--- impulses stop working properly if it body falls asleep (ie. not awake)
	-- if spaceGroup.isAwake then 
		-- awake = "true" 
	-- else 
		--- awake="false" 
		--- print("Impulse forces stop working when bodies fall asleep")

	-- end  

	if ( spaceGroup.x > 262 and spaceGroup.x < 286 ) then
		xOnTarget = "ON TARGET"
	end

	if ( spaceGroup.y > 262 and spaceGroup.y < 286 ) then
		yOnTarget = "ON TARGET"
	end

	navStatsText.text = "xDelta=" .. spaceGroup.x .. "yDelta=" .. spaceGroup.y
	navStatsText.text = string.format("%s  %5.1f  %s  %5.1f\n%s  %4.0f  %s  %5.1f\n%s  %5.1f  %5.3f\n",  
		"xDelta=", spaceGroup.x, xOnTarget, spaceGroup.anchorX,
		"yDelta=", spaceGroup.y, yOnTarget, spaceGroup.anchorY,
		"rotation=", spaceGroup.rotation, rotDelta )


end

function updatePosition()
	spaceGroup.x = spaceGroup.x + xDelta
	spaceGroup.y = spaceGroup.y + yDelta
	spaceGroup.rotation = spaceGroup.rotation + rotDelta 
end


-- Handle enterFrame events
function act:enterFrame( event )
	if( navStatsText ) then
		updateNavStats()
	end

	if ( xDelta and yDelta and rotDelta ) then
		updatePosition()
	end

	-- Move UFO to the right and wrap around exactly at screen edges
	-- ufo.x = ufo.x + 1
	--- if ufo.x > act.xMax + ufo.width / 2 then
		--- ufo.x = act.xMin - ufo.width / 2
	-- end

end

------------------------- End of Activity --------------------------------


-- Corona needs the scene object returned from the act file
return act.scene
