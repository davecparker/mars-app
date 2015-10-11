-----------------------------------------------------------------------------------------
--
-- thrustNav.lua
--
-- Mini game for:
--  1) Stop spinning ship and navigate toward Mars
--  2) Enter orbit around mars
--  3) Land the ship
-- 
-- Rocket controls act as if they are attached to nose of ship 
-- Things to solve:
--    How to make space continuous for 360 degrees?
--    How to locate mars and put an arrow towards it
--    How to locate earth when it is targetted and say something funny
--    Where to put sun, venus, ..
--    Need little retro rocket image for buttons when pressed

-----------------------------------------------------------------------------------------

-- Get local reference to the game globals
local game = globalGame

-- Create the act object
local act = game.newAct()


-- try image.fill to change images...
--  create a rect then fill with image.fill

------------------------- Start of Activity --------------------------------

-- File local variables
local xyText			-- text display object for touch location 
local xyCenterText		-- text display object for touch location relative to center
local ufo       		-- flying UFO object
local mars           	-- planet mars
local earth         	-- earth
local buttonTurnLeft   	-- button to turn ship left
local buttonTurnRight  	-- button to turn ship right
local buttonRollLeft   	-- button to Roll ship left
local buttonRollRight  	-- button to Roll ship right
local buttonPitchUp    	-- button to pitch ship up
local buttonPitchDown  	-- button to pitch ship down
local ship             	-- ship object
local spaceGroup    	-- group for rotating space background
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

-- Turn left button 
function buttonTurnLeftTouch (event)
	if event.phase == "began" then
		print("Turn Left Button")
		xDelta = xDelta + xDeltaInc
	end
	return true
end

-- Turn Right button 
function buttonTurnRightTouch (event)
	if event.phase == "began" then
		print("Turn Right Button, rotation= ", spaceGroup.rotation )
		xDelta = xDelta - xDeltaInc
	end
	return true
end

--  Roll Left button
function buttonRollLeftTouch (event)
	if event.phase == "began" then
		print("Roll Left Button")
		rotDelta = rotDelta + rotDeltaInc
	end
	return true
end

-- Roll RIght Button
function buttonRollRightTouch (event)
	if event.phase == "began" then
		print("Roll Right Button, rotation= ", spaceGroup.rotation )
		rotDelta = rotDelta - rotDeltaInc
	end
	return true
end

-- Pitch Up Button
function buttonPitchUpTouch (event)
	if event.phase == "began" then
		print("Pitch Up Button - Rotation = ", spaceGroup.rotation)
		yDelta = yDelta + yDeltaInc
	end
	return true
end

-- Pitch Down Button
function buttonPitchDownTouch (event)
	if event.phase == "began" then
		print("Pitch Down Button - Rotation = ", spaceGroup.rotation)
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
	print( "buttonPitchUp=",buttonPitchUp )
	buttonPitchDown = display.newImageRect(act.group, "media/thrustnav/arrow-button.png",30,30)
	print( "buttonPitchDown=",buttonPitchDown )
	buttonPitchDown.rotation = 180

	local bg = display.newImageRect( spaceGroup, "media/thrustNav/starrynight.png", 5*act.width, 5*act.height )
	-- bg:addEventListener( "touch", touched )
	print("bg=", bg )

	local yText = act.yMin + 30
	navStatsText = display.newText( act.group, "Hello", act.width / 3, yText, native.systemFont, 14 )
	print( "navStatsText=" , navStatsText )
	
	spaceGroup.y = act.height / 2 - 100
	
	-- ship = display.newImageRect(spaceGroup, "media/thrustNav/shipconcepts.png", 30, 30 )
	
    mars = display.newImageRect( spaceGroup, "media/thrustNav/mars.png", 30, 30 )
    print("act.xMin=",act.xMin, " act.yMin=", act.yMin)
    mars.x = act.xMin
    mars.y = act.yMin + 100
    print("Mars anchorX=", mars.anchorX, "anchorY=", mars.anchorY )
    print("Mars is placed at ", mars.x, ",", mars.y , " in spaceGroup before move") 

    earth = display.newImageRect( spaceGroup, "media/thrustNav/earth.png", 20, 20 )
    earth.x = act.xMin
    earth.y = act.yMax - 100
    print("Earth anchorX=", earth.anchorX, "anchorY=", earth.anchorY )
    print("Earth is placed at ", earth.x, ",", earth.y , " in spaceGroup before move") 

	-- place ship at center of lines
	-- ship.x = 0
	-- ship.y = 0
  
  	-- Fix anchors to be at cross hairs for start
    spaceGroup.x = act.xCenter 
    spaceGroup.anchorX = spaceGroup.x
    spaceGroup.y = act.yCenter
    spaceGroup.anchorY =spaceGroup.y

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

	if ( spaceGroup.x > 150 and spaceGroup.x < 170 ) then
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

end

------------------------- End of Activity --------------------------------


-- Corona needs the scene object returned from the act file
return act.scene
