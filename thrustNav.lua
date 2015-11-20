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
--    How to move Mars with background when we go 360 around
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
local sun         		-- sun
local buttonTurnLeft   	-- button to turn ship left
local buttonTurnRight  	-- button to turn ship right
local buttonRollLeft   	-- button to Roll ship left
local buttonRollRight  	-- button to Roll ship right
local buttonPitchUp    	-- button to pitch ship up
local buttonPitchDown  	-- button to pitch ship down
local ship             	-- ship object
local spaceGroup    	-- group for rotating space background
local xVelocity, yVelocity, rotVelocity  -- positional deltas used on each enter frame
local xVelocityInc, yVelocityInc, rotVelocityInc  -- increments for the deltas
local xTargetDelta, yTargetDelta  -- delta from Target
local navStatsText1, navStatsText2, navStatsText3 -- text strings for nav stats
local targetRect       -- Rectangle target area
local arrow        		-- directional arrow toward mars
local totalRocketImpulses = 0    -- number of rocket impulses used
local bgLeft, bgRight          -- background images
local thrusterSound     -- thrust sound
local leftAccelerate, rightAccelerate, upAccelerate, downAccelerate
local accelerateFrameCount
local onTargetX, onTargetY, onTargetXY -- graphics that become visible when on target

-- Make a small red circle centered at the given location
local function makeStar( x, y )
	local c = display.newCircle( act.group, x, y, 1 )
	c:setFillColor(1, 1, 1)
	return c
end

-- function to send you back when you press the back button
local function backButtonPress ( event )
	print ( xVelocity, yVelocity ) 

	-- Cheat mode to succeed immediately
	if game.cheatMode then
		xTargetDelta = 0
		yTargetDelta = 0
		xVelocity = 0
		yVelocity = 0
	end
	
	if( ( math.abs( yTargetDelta ) < 2 ) and 
		( math.abs( xTargetDelta ) < 2 ) and 
		( math.abs( xVelocity ) < 0.00001 ) and 
		( math.abs( yVelocity ) < 0.00001 ) ) then
		game.saveState.thrustNav.onTarget = true
		game.endMessageBox()  -- clear message box
		-- game.messageBox( "Nicely Done!")
		-- game.showHint( "Nicely Done!", "On Target")
	else
		if ( ( math.abs( xVelocity ) > 0.00001 ) or 
			( math.abs( yVelocity )  > 0.00001) ) then
			game.messageBox( "Still Spinning!")
		elseif ( ( math.abs( yTargetDelta ) >= 2 ) or 
			( math.abs( xTargetDelta ) >= 2 ) ) then
			game.messageBox( "Still Off Target!")
		end
	end
	-- if ( math.abs( xVelocity ) < 0.00001 ) then
	-- 	game.saveState.thrustNav.shipSpinning = false
	-- end

	-- saved for use in messages
	game.saveState.thrustNav.lastXTargetDelta = xTargetDelta
	game.saveState.thrustNav.lastYTargetDelta = yTargetDelta
	
	game.gotoAct ( "mainAct" )
	return true
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
	game.saveState.resources.kWh = game.saveState.resources.kWh - 0.1
end

-- Turn left button 
function buttonTurnLeftTouch (event)
	if event.phase == "began" then
		game.playSound( thrusterSound ) 
		print("Turn Left Button")
		accelerateFrameCount = 0
		xVelocity = xVelocity + xVelocityInc
		leftAccelerate = true
		-- printPositions()
		updateEnergy()
		display.getCurrentStage():setFocus( event.target )  -- helps when fingers move
	elseif event.phase == "ended" or event.phase == "cancelled" then
		leftAccelerate = false
		display.getCurrentStage():setFocus(nil)
	end
	return true
end

-- Turn Right button 
function buttonTurnRightTouch (event)
	if event.phase == "began" then
		game.playSound( thrusterSound )
		print("Turn Right Button, rotation= ", spaceGroup.rotation )
		accelerateFrameCount = 0
		xVelocity = xVelocity - xVelocityInc
		-- xVelocity = xVelocity - xVelocityInc
		-- printPositions()
		rightAccelerate = true
		updateEnergy()
		display.getCurrentStage():setFocus( event.target )  -- helps when fingers move
	elseif event.phase == "ended" or event.phase == "cancelled" then
		rightAccelerate = false
		display.getCurrentStage():setFocus(nil)
	end
	return true
end

--  Roll Left button
function buttonRollLeftTouch (event)
	if event.phase == "began" or event.phase == "moved" then
		game.playSound( thrusterSound )
		print("Roll Left Button")
		rotVelocity = rotVelocity + rotVelocityInc
		printPositions()
		updateEnergy()
	end
	return true
end

-- Roll RIght Button
function buttonRollRightTouch (event)
	if event.phase == "began" or event.phase == "moved" then
		game.playSound( thrusterSound )
		print("Roll Right Button, rotation= ", spaceGroup.rotation )
		rotVelocity = rotVelocity - rotVelocityInc
		printPositions()
		updateEnergy()
	end
	return true
end

-- Pitch Up Button
function buttonPitchUpTouch (event)
	if event.phase == "began" then
		game.playSound( thrusterSound )
		print("Pitch Up Button - Rotation = ", spaceGroup.rotation)
		yVelocity = yVelocity + yVelocityInc
		accelerateFrameCount = 0
		upAccelerate = true
		-- printPositions()
		updateEnergy()
		display.getCurrentStage():setFocus( event.target )  -- helps when fingers move
	elseif event.phase == "ended" or event.phase == "cancelled" then
		upAccelerate = false
		display.getCurrentStage():setFocus(nil)
	end
	return true
end

-- Pitch Down Button
function buttonPitchDownTouch(event)
	if event.phase == "began"  then
		game.playSound( thrusterSound )
		print("Pitch Down Button - Rotation = ", spaceGroup.rotation)
		yVelocity = yVelocity - yVelocityInc
		accelerateFrameCount = 0
		downAccelerate = true
		-- printPositions()
		updateEnergy()
		display.getCurrentStage():setFocus( event.target )  -- helps when fingers move
	elseif event.phase == "ended" or event.phase == "cancelled" then
		downAccelerate = false
		display.getCurrentStage():setFocus(nil)
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
	-- Load sound effects
	thrusterSound = act:loadSound( "ignite3.wav" )
	
	-- create group for rotating background space objects
	spaceGroup = act:newGroup()

	-- tried and didn't wrap as desired
	-- display.setDefault("textureWrapX", "mirrorRepeat" )
	-- display.setDefault("textureWrapY", "mirrorRepeat")

	-- Create control buttons, background, etc.
	buttonTurnLeft = act:newImage( "arrowbutton.png", { width = 50, height = 50 } )
	buttonTurnLeft.rotation = -90
	buttonTurnRight = act:newImage( "arrowbutton.png", { width = 50, height = 50 } )
	buttonTurnRight.rotation = 90
--	buttonRollLeft = act:newImage( "arrowbutton.png", { width = 30, height = 30 } )
--	buttonRollRight = act:newImage( "arrowbutton.png", { width = 30, height = 30 } )
	buttonPitchUp = act:newImage( "arrowbutton.png", { width = 50, height = 50 } )
	print( "buttonPitchUp=",buttonPitchUp )
	buttonPitchDown = act:newImage( "arrowbutton.png" , { width = 50, height = 50 } )
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
	navStatsText1 = display.newText( act.group, "Hello1", (act.xCenter-act.xMin) / 2, yText, native.systemFont, 14 )
	navStatsText1.anchorX = 0
	navStatsText1.anchorY = 0
	navStatsText2 = display.newText( act.group, "Hello2", (act.xCenter-act.xMin) / 2, yText + 16, native.systemFont, 14 )
	navStatsText2.anchorX = 0
	navStatsText2.anchorY = 0
	navStatsText3 = display.newText( act.group, "Hello3", (act.xCenter-act.xMin) / 2, yText + 32, native.systemFont, 14 )
	navStatsText3.anchorX = 0
	navStatsText3.anchorY = 0
	print( "navStatsText1=" , navStatsText1 )
	
	-- spaceGroup.y = act.height / 2 - 100
	
	-- ship = display.newImageRect(spaceGroup, "media/thrustNav/shipconcepts.png", 30, 30 )
	
    mars = display.newImageRect( spaceGroup, "media/thrustNav/mars.png", 30, 30 )
    print("act.xMin=",act.xMin, " act.yMin=", act.yMin)
    mars.x = act.xMin + 50
    mars.y = act.yMin + 100
    print("Mars anchorX=", mars.anchorX, "anchorY=", mars.anchorY )
    print("Mars is placed at ", mars.x, ",", mars.y , " in spaceGroup before move") 

    earth = display.newImageRect( spaceGroup, "media/thrustNav/earth.png", 30, 30 )
    earth.x = mars.x + ( 2 * act.width )
    earth.y = mars.y - 10
    print("Earth anchorX=", earth.anchorX, "anchorY=", earth.anchorY )
    print("Earth is placed at ", earth.x, ",", earth.y , " in spaceGroup before move") 

    sun = display.newImageRect( spaceGroup, "media/thrustNav/sun.png", 60, 60 )
    sun.x = mars.x + ( 1.3 * act.width )
    sun.y = act.yCenter 

	-- place ship at center of lines
	-- ship.x = 0
	-- ship.y = 0
  
  	-- Fix anchors to be at cross hairs for start
    -- spaceGroup.x = act.xCenter 
    -- spaceGroup.anchorX = spaceGroup.x
    -- spaceGroup.y = act.yCenter
    -- spaceGroup.anchorY =spaceGroup.y
    -- spaceGroup.rotation = 10

	xVelocity = 2.1 -- 3.5
	yVelocity = 0.1
	rotVelocity = 0
	xVelocityInc = 0.1
	yVelocityInc = 0.1
	rotVelocityInc = 0.01

	-- Could try transition with iterations=-1 for continuous
	--- transition.to(fuseObj, { iterations=-1,rotation=-360,time=250})

    -- Crosshair in the center
	local dy = 200
	local dx = 20
	display.newLine( act.group, act.xCenter, act.yCenter - dy, act.xCenter, act.yCenter + dy )
	display.newLine( act.group, act.xCenter - dx, act.yCenter, act.xCenter + dx, act.yCenter )
	targetRect = display.newRect( act.group, act.xCenter, act.yCenter, 15, 15 )

	-- On Target Indicators
	onTargetX = act:newImage( "targetx.png", { height = act.width/2, width = act.width/2 } )
	onTargetX.isVisible = false
	onTargetY = act:newImage( "targety.png", { height = act.width/2, width = act.width/2 } )
	onTargetY.isVisible = false
	onTargetXY = act:newImage( "targetxy.png", { height = act.width/2, width = act.width/2 } )
	onTargetXY.isVisible = false

    -- Set up buttons
	buttonTurnLeft.x = act.xMin + act.width / 8
	buttonTurnLeft.y = act.yMax - act.height / 12
	buttonTurnLeft.isVisible = true

	buttonTurnRight.x = act.xMax - act.width / 8
	buttonTurnRight.y = act.yMax - act.height / 12
	buttonTurnRight.isVisible = true

	--- buttonRollLeft.x = act.xMax - (act.xMax - act.xMin) / 8
	--- buttonRollLeft.y = act.yMax - (act.yMax - act.yMin) / 20
	--- buttonRollLeft.isVisible = true

	-- Use act.width and act.height
	--- buttonRollRight.x = act.xMin + (act.xMax - act.xMin) / 5
	--- buttonRollRight.y = act.yMax - (act.yMax - act.yMin) / 20
	--- buttonRollRight.isVisible = true

	buttonPitchUp.x = act.xCenter
	buttonPitchUp.y = act.yMax - act.height / 8 
	buttonPitchUp.isVisible = true

	buttonPitchDown.x = act.xCenter
	buttonPitchDown.y = act.yMax - act.height / 30 
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
	backButton:addEventListener( "tap", backButtonPress )
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
	
	xTargetDelta = ( mars.contentBounds.xMax + mars.contentBounds.xMin ) / 2 - act.xCenter
	yTargetDelta = ( mars.contentBounds.yMax + mars.contentBounds.yMin ) / 2 - act.yCenter 

	if( math.abs( xTargetDelta ) < 2  ) then 
		xStr = xStr .. " On Target" 
		onTargetX.isVisible = true
	elseif( math.abs( xTargetDelta ) < 5  ) then 
		xStr = xStr .. " Getting close" 
		onTargetX.isVisible = true
	else
		onTargetX.isVisible = false
		onTargetXY.isVisible = false
	end
	if( math.abs( yTargetDelta ) < 2  ) then 
		yStr = yStr .. " On Target" 
		onTargetY.isVisible = true
	elseif( math.abs( yTargetDelta ) < 5  ) then 
		yStr = yStr .. " Getting close" 
		onTargetY.isVisible = true
	else
		onTargetY.isVisible = false
		onTargetXY.isVisible = false
	end
	if( math.abs( yTargetDelta ) < 2 and math.abs( xTargetDelta ) < 2 ) then
		onTargetXY.isVisible = true
	else
		onTargetXY.isVisible = false
	end

	if( onTargetXY.isVisible == true and math.abs( xVelocity ) < 0.00001 and math.abs( yVelocity ) < 0.00001 ) then
		-- game.messageBox( "Nicely Done!!", { width = act.width * 4, fontSize = 200 })
		game.showHint( "Nicely Done!", "On Target", 
				function ()
					game.saveState.thrustNav.onTarget = true
					game.gotoAct ( "mainAct" )
				end )
	end		

	if( hasCollided( earth, targetRect ) ) then
		navStatsText1.text = "Where are you going?  Home?"	
	elseif( hasCollided( sun, targetRect ) ) then
		navStatsText1.text = "That will be VERY HOT!"	
	else
		navStatsText1.text = string.format( "%s  %3d %5.1f   %s", "xDelta=", xTargetDelta , xVelocity, xStr)
		navStatsText2.text = string.format( "%s  %3d %5.1f   %s", "yDelta=", yTargetDelta , yVelocity, yStr)
		navStatsText3.text = string.format( "%s %3d", "totalImpulses= ", totalRocketImpulses )
	end
end

--  Move and update space background 
function updatePosition()
	spaceGroup.x = spaceGroup.x + xVelocity
	spaceGroup.y = spaceGroup.y + yVelocity
	spaceGroup.rotation = spaceGroup.rotation + rotVelocity

	-- check for button holds
	if( leftAccelerate == true ) then
		accelerateFrameCount = accelerateFrameCount + 1
		if( accelerateFrameCount % 5 == 0 ) then
			xVelocity = xVelocity + xVelocityInc
			updateEnergy()
		end
		if( accelerateFrameCount > 10 ) then
			game.playSound( thrusterSound )
			accelerateFrameCount = 0
		end
	elseif( rightAccelerate == true ) then
		accelerateFrameCount = accelerateFrameCount + 1
		if( accelerateFrameCount % 5 == 0 ) then
			xVelocity = xVelocity - xVelocityInc
			updateEnergy()
		end
		if( accelerateFrameCount > 10 ) then
			game.playSound( thrusterSound )
			accelerateFrameCount = 0
		end
	elseif( upAccelerate == true ) then
		accelerateFrameCount = accelerateFrameCount + 1
		if( accelerateFrameCount % 5 == 0 ) then
			yVelocity = yVelocity + yVelocityInc
			updateEnergy()
		end
		if( accelerateFrameCount > 10 ) then
			game.playSound( thrusterSound )
			accelerateFrameCount = 0
		end
	elseif( downAccelerate == true ) then
		accelerateFrameCount = accelerateFrameCount + 1
		if( accelerateFrameCount % 5 == 0 ) then
			yVelocity = yVelocity - yVelocityInc
			updateEnergy()
		end
		if( accelerateFrameCount > 10 ) then
			game.playSound( thrusterSound )
			accelerateFrameCount = 0
		end
	end
		
	-- check on back ground image bounds
	local bgTemp
	if( bgLeft.contentBounds.xMin > act.xMin - 10 ) then
		print( "Move right tile to left" )
		if( hasCollided( bgRight, mars ) ) then   -- move mars as needed
			print( "move mars with right tile to left")
			mars.x = mars.x - ( 4 * act.width )
		end
		if( hasCollided( bgRight, earth ) ) then   -- move earth as needed
			print( "move Earth with right tile to left")
			earth.x = earth.x - ( 4 * act.width )
		end
		if( hasCollided( bgRight, sun ) ) then   -- move sun as needed
			print( "move Sun with right tile to left")
			sun.x = sun.x - ( 4 * act.width )
		end
		bgRight.x = bgRight.x - ( 4 * act.width )
		bgTemp = bgRight
		bgRight = bgLeft
		bgLeft = bgTemp
	elseif ( bgRight.contentBounds.xMax < act.xMax + 10 ) then
		print( "Move left tile to right" )
		if( hasCollided( bgLeft, mars ) ) then  -- move mars as needed
			print( "Move Mars with left tile to right")
			mars.x = mars.x + ( 4 * act.width )
		end
		if( hasCollided( bgLeft, earth ) ) then  -- move earth as needed
			print( "Move Earth with left tile to right")
			earth.x = earth.x + ( 4 * act.width )
		end
		if( hasCollided( bgLeft, sun ) ) then  -- move Sun as needed
			print( "Move Sun with left tile to right")
			sun.x = sun.x + ( 4 * act.width )
		end
		bgLeft.x = bgLeft.x + ( 4 * act.width )
		bgTemp = bgRight
		bgRight = bgLeft
		bgLeft = bgTemp
	end
	--- Vertical stability override
	if( ( ( bgLeft.contentBounds.yMin > act.yMin - 10 ) and ( yVelocity > 0 ) )
	or ( ( bgLeft.contentBounds.yMax < act.yMax + 10 ) and ( yVelocity < 0 ) ) ) then
		print( "msg about computer assisted vertical stabilization") 
		yVelocity = 0
		game.messageBox( "Vertical Stability Activated")
		print( string.format("yVelocity = %5.3f", yVelocity) )
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
	if( navStatsText1 ) then
		updateNavStats()
	end

	if ( xVelocity and yVelocity and rotVelocity ) then
		updatePosition()
	end
	updateArrow()

end

------------------------- End of Activity --------------------------------


-- Corona needs the scene object returned from the act file
return act.scene
