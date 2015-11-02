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
local widget = require( "widget" )  -- need to make buttons

-- try image.fill to change images...
--  create a rect then fill with image.fill

-- To change to limitted vertical space we:
--   1) elimiate roll
--   2) use two space images (one with Mars, one with Earth) for left and right
--   3) detect and stop vertical up/down with equal revers thrust

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
local xTargetDelta, yTargetDelta  -- delta from Target
local navStatsText     -- text string for nav stats
local targetRect       -- Rectangle target area
local arrow        		-- directional arrow toward mars
local totalRocketImpulses = 0    -- number of rocket impulses used
local bgLeft, bgRight          -- background images

-- Make a small red circle centered at the given location
local function makeStar( x, y )
	local c = display.newCircle( act.group, x, y, 1 )
	c:setFillColor(1, 1, 1)
	return c
end

-- function to send you back when you press the back button
local function backButtonPress ( event )
	game.gotoAct ( "mainAct" )
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

-- Update energy consumed
function updateEnergy()
	totalRocketImpulses = totalRocketImpulses + 1
	-- also update energy to main resources
end

-- Turn left button 
function buttonTurnLeftTouch (event)
	if event.phase == "began" then
		print("Turn Left Button")
		xDelta = xDelta + xDeltaInc
		printPositions()
		updateEnergy()
	end
	return true
end

-- Turn Right button 
function buttonTurnRightTouch (event)
	if event.phase == "began" then
		print("Turn Right Button, rotation= ", spaceGroup.rotation )
		xDelta = xDelta - xDeltaInc
		printPositions()
		updateEnergy()
	end
	return true
end

--  Roll Left button
function buttonRollLeftTouch (event)
	if event.phase == "began" then
		print("Roll Left Button")
		rotDelta = rotDelta + rotDeltaInc
		printPositions()
		updateEnergy()
	end
	return true
end

-- Roll RIght Button
function buttonRollRightTouch (event)
	if event.phase == "began" then
		print("Roll Right Button, rotation= ", spaceGroup.rotation )
		rotDelta = rotDelta - rotDeltaInc
		printPositions()
		updateEnergy()
	end
	return true
end

-- Pitch Up Button
function buttonPitchUpTouch (event)
	if event.phase == "began" then
		print("Pitch Up Button - Rotation = ", spaceGroup.rotation)
		yDelta = yDelta + yDeltaInc
		printPositions()
		updateEnergy()
	end
	return true
end

-- Pitch Down Button
function buttonPitchDownTouch (event)
	if event.phase == "began" then
		print("Pitch Down Button - Rotation = ", spaceGroup.rotation)
		yDelta = yDelta - yDeltaInc
		printPositions()
		updateEnergy()
	end
	return true
end

-- Could use math.abs(bird.y-food.y) < slop to achieve similar result
--rectangle-based collision detection (found in doc)
local function hasCollided( obj1, obj2 )
	-- -- print ("In hasCollided")
   if ( obj1 == nil ) then  --make sure the first object exists
      return false
   end
   if ( obj2 == nil ) then  --make sure the other object exists
      return false
   end

   local left = obj1.contentBounds.xMin <= obj2.contentBounds.xMin and obj1.contentBounds.xMax >= obj2.contentBounds.xMin
   local right = obj1.contentBounds.xMin >= obj2.contentBounds.xMin and obj1.contentBounds.xMin <= obj2.contentBounds.xMax
   local up = obj1.contentBounds.yMin <= obj2.contentBounds.yMin and obj1.contentBounds.yMax >= obj2.contentBounds.yMin
   local down = obj1.contentBounds.yMin >= obj2.contentBounds.yMin and obj1.contentBounds.yMin <= obj2.contentBounds.yMax

   return (left or right) and (up or down)
end

-- Init the act
function act:init()
	-- create group for rotating background space objects
	spaceGroup = act:newGroup()

	-- tried and didn't wrap as desired
	-- display.setDefault("textureWrapX", "mirrorRepeat" )
	-- display.setDefault("textureWrapY", "mirrorRepeat")

	-- Create control buttons, background, etc.
	buttonTurnLeft = act:newImage( "arrowbutton.png", { width = 30, height = 30 } )
	buttonTurnLeft.rotation = -90
	buttonTurnRight = act:newImage( "arrowbutton.png", { width = 30, height = 30 } )
	buttonTurnRight.rotation = 90
--	buttonRollLeft = act:newImage( "arrowbutton.png", { width = 30, height = 30 } )
--	buttonRollRight = act:newImage( "arrowbutton.png", { width = 30, height = 30 } )
	buttonPitchUp = act:newImage( "arrowbutton.png", { width = 30, height = 30 } )
	print( "buttonPitchUp=",buttonPitchUp )
	buttonPitchDown = act:newImage( "arrowbutton.png" , { width = 30, height = 30 } )
	print( "buttonPitchDown=",buttonPitchDown )
	buttonPitchDown.rotation = 180

	bgLeft = display.newImageRect( spaceGroup, "media/thrustNav/starrynight.png", 2*act.width, 2*act.height )
	bgLeft.x = act.xCenter
	bgLeft.y = act.yCenter
	bgRight = display.newImageRect( spaceGroup, "media/thrustNav/starrynight2.png", 2*act.width, 2*act.height )
	bgRight.x = act.xCenter * 5
	bgRight.y = act.yCenter

 	-- transition.to( bgLeft, { time = 12000, x = 0, iterations = 0 } )
	-- transition.to( bgRight, { time = 12000, x = act.xCenter, iterations = 0 } )

	print("transitions launched")
		-- local paint = { 
	-- 		type = "image", 
	--		filename = "media/thrustNav/starrynight.png"
	-- 	}
	-- local bg = display.newRect( spaceGroup, 0, 0, 5*act.width, 5*act.height  )
	-- bg.fill = paint  -- obj.fill is Pro version of Corona only

	-- bg:addEventListener( "touch", touched )
	print("bg=", bg )

	local yText = act.yMin + 10
	navStatsText = display.newText( act.group, "Hello", act.xCenter+10, yText, native.systemFont, 14 )
	navStatsText.anchorX = 0
	navStatsText.anchorY = 0
	print( "navStatsText=" , navStatsText )
	
	-- spaceGroup.y = act.height / 2 - 100
	
	-- ship = display.newImageRect(spaceGroup, "media/thrustNav/shipconcepts.png", 30, 30 )
	
    mars = display.newImageRect( spaceGroup, "media/thrustNav/mars.png", 30, 30 )
    print("act.xMin=",act.xMin, " act.yMin=", act.yMin)
    mars.x = act.xMin + 50
    mars.y = act.yMin + 100
    print("Mars anchorX=", mars.anchorX, "anchorY=", mars.anchorY )
    print("Mars is placed at ", mars.x, ",", mars.y , " in spaceGroup before move") 

    earth = display.newImageRect( spaceGroup, "media/thrustNav/earth.png", 20, 20 )
    earth.x = act.xMin + 2*act.width
    earth.y = act.yMax - 100
    print("Earth anchorX=", earth.anchorX, "anchorY=", earth.anchorY )
    print("Earth is placed at ", earth.x, ",", earth.y , " in spaceGroup before move") 

	-- place ship at center of lines
	-- ship.x = 0
	-- ship.y = 0
  
  	-- Fix anchors to be at cross hairs for start
    -- spaceGroup.x = act.xCenter 
    -- spaceGroup.anchorX = spaceGroup.x
    -- spaceGroup.y = act.yCenter
    -- spaceGroup.anchorY =spaceGroup.y
    -- spaceGroup.rotation = 10

	xDelta = 0.1
	yDelta = 0
	-- rotDelta = 0.02
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
	targetRect = display.newRect( act.group, act.xCenter, act.yCenter, 15, 15 )

    -- Set up buttons
	buttonTurnLeft.x = act.xCenter - (act.xMax - act.xMin) / 8
	buttonTurnLeft.y = act.yMax - (act.yMax - act.yMin) / 15
	buttonTurnLeft.isVisible = true

	buttonTurnRight.x = act.xCenter + (act.xMax - act.xMin) / 8
	buttonTurnRight.y = act.yMax - (act.yMax - act.yMin) / 15
	buttonTurnRight.isVisible = true

	--- buttonRollLeft.x = act.xMax - (act.xMax - act.xMin) / 8
	--- buttonRollLeft.y = act.yMax - (act.yMax - act.yMin) / 20
	--- buttonRollLeft.isVisible = true

	-- Use act.width and act.height
	--- buttonRollRight.x = act.xMin + (act.xMax - act.xMin) / 5
	--- buttonRollRight.y = act.yMax - (act.yMax - act.yMin) / 20
	--- buttonRollRight.isVisible = true

	buttonPitchUp.x = (act.xMax - act.xMin ) / 2
	buttonPitchUp.y = act.yMax - (act.yMax - act.yMin) / 10 
	buttonPitchUp.isVisible = true

	buttonPitchDown.x = (act.xMax - act.xMin ) / 2
	buttonPitchDown.y = act.yMax - (act.yMax - act.yMin) / 30 
	buttonPitchDown.isVisible = true

	buttonTurnLeft:addEventListener( "touch", buttonTurnLeftTouch )
	buttonTurnRight:addEventListener( "touch", buttonTurnRightTouch )
	-- buttonRollLeft:addEventListener( "touch", buttonRollLeftTouch )
	-- buttonRollRight:addEventListener( "touch", buttonRollRightTouch )
	buttonPitchUp:addEventListener( "touch", buttonPitchUpTouch )
	buttonPitchDown:addEventListener( "touch", buttonPitchDownTouch )

	-- back button
	local backButton = act:newImage( "backButton.png", { width = 40 } )
	backButton.x = act.xMin + 30
	backButton.y = act.yMin + 30
	backButton.button = widget.newButton 
	{
		 x = act.xMin + 30,
		 y = act.yMin + 30,
		 width = 50, 
		 height = 50,
		 onPress = backButtonPress 
	}
end

-- draw arrow toward mars
function updateArrow()
	local marsCenterX = (mars.contentBounds.xMax + mars.contentBounds.xMin)/2 
	local marsCenterY = (mars.contentBounds.yMax + mars.contentBounds.yMin)/2 
	if ( arrow ~= nil) then
		arrow:removeSelf()
		arrow = nil
	end
	arrow = display.newLine( act.group, act.xCenter, act.yCenter, marsCenterX, marsCenterY )
	-- print("xc=", marsCenterX, "  yc=", marsCenterY )
end


-- Update on screen stats for users reference
function updateNavStats()
	local xStr = ""
	local yStr = ""
	local rotStr = ""
	local xScore = 0
	local yScore = 0
	local rotScore = 0
	local totalScore = 0

	xTargetDelta = ( mars.contentBounds.xMax + mars.contentBounds.xMin ) / 2 - act.xCenter
	yTargetDelta = ( mars.contentBounds.yMax + mars.contentBounds.yMin ) / 2 - act.yCenter 
	

	xScore = 100 - math.abs( xTargetDelta )
	yScore = 100 - math.abs( yTargetDelta )
	-- special treatment for mars
   	if( hasCollided( mars, targetRect ) ) then
   		xStr = "ON TARGET"
		yStr = "ON TARGET"
	end
	if( xTargetDelta < 5  and xTargetDelta > -5 ) then xStr = xStr .. " Getting close" end

	rotScore = 100 * (1 - math.abs( rotDelta ) ) 
	if( rotDelta == 0 ) then
		rotStr = string.format( "Spin Stopped   %3d", rotScore )
	else
		rotStr = string.format( "               %3d", rotScore )
	end
	energyScore = 100 - totalRocketImpulses
	totalScore = ( xScore + yScore + rotScore + energyScore ) / 4

	if( hasCollided( earth, targetRect ) ) then
		navStatsText.text = "Where are you going?  Home?"	
	else
		navStatsText.text = string.format("%s  %3d %5.1f   %s\n%s  %3d %5.1f  %s\n%s %3d",  
		"xDelta=", xTargetDelta , xDelta, xStr,
		"yDelta=", yTargetDelta , yDelta, yStr,
		--- "rotation=", spaceGroup.rotation % 360, rotDelta, rotStr,
		"totalImpulses= ", totalRocketImpulses )
	end
end

--  Move and update space background 
function updatePosition()
	spaceGroup.x = spaceGroup.x + xDelta
	spaceGroup.y = spaceGroup.y + yDelta
	spaceGroup.rotation = spaceGroup.rotation + rotDelta

	-- check on back ground image bounds
	local bgTemp
	if( bgLeft.contentBounds.xMin > act.xMin - 10 ) then
		print( "Move right tile to left" )
		bgRight.x = bgRight.x - (4*act.width)
		bgTemp = bgRight
		bgRight = bgLeft
		bgLeft = bgTemp
	elseif ( bgRight.contentBounds.xMax < act.xMax + 10 ) then
		print( "Move left tile to right" )
		bgLeft.x = bgLeft.x + (4*act.width)
		bgTemp = bgRight
		bgRight = bgLeft
		bgLeft = bgTemp
	end
	--- Vertical stability override
	if( ( ( bgLeft.contentBounds.yMin > act.yMin - 10 ) and ( yDelta > 0 ) )
	or ( ( bgLeft.contentBounds.yMax < act.yMax + 10 ) and ( yDelta < 0 ) ) ) then
		print( "msg about computer assisted vertical stabilization") 
		yDelta = 0
		game.messageBox( "Vertical Stability Activated")
		print( string.format("yDelta = %5.3f", yDelta) )
	end

	
end

-- print debug positon information to console
function printPositions()
	print("Mars  x=", mars.x, "  y=", mars.y, "  ax=", mars.anchorX, "  ay=", mars.anchorY )
	print("Mars  contentBounds.xMin=", mars.contentBounds.xMin )
	print("Space x=", spaceGroup.x, "  y=", spaceGroup.y, "  ax=", spaceGroup.anchorX, "  ay=", spaceGroup.anchorY )
	print("Earth x=", earth.x, "  y=", earth.y, "  ax=", earth.anchorX, "  ay=", earth.anchorY )
	print("SG minX=", spaceGroup.contentBounds.xMin, "  SG maxX=", spaceGroup.contentBounds.xMax )
end

-- Handle enterFrame events
function act:enterFrame( event )
	if( navStatsText ) then
		updateNavStats()
	end

	if ( xDelta and yDelta and rotDelta ) then
		updatePosition()
	end
	updateArrow()

end

------------------------- End of Activity --------------------------------


-- Corona needs the scene object returned from the act file
return act.scene
