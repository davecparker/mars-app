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
--    Need little retro rocket image for buttons when pressed
--    Need sound effect for on target

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
--   3) detect and stop vertical up/down with equal reverse thrust

-- fix text to be clean(horz/vert degrees and velocity) with columns and no "getting close" messages
-- eliminate text impulses line
-- add print of list of children to Act.lua in scene:show did area
-- add texture memory info to debug screen
-- fix close - ontarget to be just on-target
-- remove vertical and horizontal white lines 
-- fix target orbit circle disappearing when spin 360


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
local buttonTurnRightFlame, buttonTurnLeftFlame  -- Rocket Flames for button press
local buttonPitchUpFlame, buttonPitchDownFlame  -- Rocket Flames for button press
local ship             	-- ship object
local spaceGroup    	-- group for rotating space background
local xVelocity, yVelocity, rotVelocity  -- positional deltas used on each enter frame
local xVelocityInc, yVelocityInc, rotVelocityInc  -- increments for the deltas
local xTargetDelta, yTargetDelta  -- delta from Target
local navStatsText1, navStatsText2, navStatsText3 -- text strings for nav stats
local stabilityWarning  -- true when vertical stability warning is showing
local targetRect       -- Rectangle target area
local arrow        		-- directional arrow toward mars
local totalRocketImpulses = 0  -- number of rocket impulses used
local bgLeft, bgRight          -- background images
local thrusterSound     -- thrust sound
local leftAccelerate, rightAccelerate, upAccelerate, downAccelerate
local accelerateFrameCount
local onTargetX, onTargetY, onTargetXY -- graphics that become visible when on target
local circle -- represents target orbit in round 2 of thrustNav
local earthHasCollided = false -- flag for taunts to show one time only
local sunHasCollided = false   -- flag for taunts to show one time only

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

	-- saved for use in messages
	game.saveState.thrustNav.lastXTargetDelta = xTargetDelta
	game.saveState.thrustNav.lastYTargetDelta = yTargetDelta
	
	game.endMessageBox()  -- remove existing message box if any
	if( ( math.abs( yTargetDelta ) < 3 ) and 
		( math.abs( xTargetDelta ) < 3 ) and 
		( math.abs( xVelocity ) < 0.00001 ) and 
		( math.abs( yVelocity ) < 0.00001 ) ) then
		game.saveState.thrustNav.onTarget = true
		-- game.showHint( "Nicely Done!", "Navigation", goMainAct )
		game.messageBox( "Nicely Done!", { onDismiss = goMainAct } )
	else
		if ( ( math.abs( xVelocity ) > 0.00001 ) or 
			( math.abs( yVelocity )  > 0.00001) ) then
			-- game.showHint( "Still Spinning!", "Navigation", goMainAct )
			-- game.messageBox( "Still Spinning!", { onDismiss = goMainAct } )
			game.messageBox( "Still Spinning!" )
			game.gotoAct ( "mainAct" )
		elseif ( ( math.abs( yTargetDelta ) >= 3 ) or 
			( math.abs( xTargetDelta ) >= 3 ) ) then
			-- game.showHint( "Still Off Target!", "Navigation", goMainAct )
			-- game.messageBox( "Still Off Target!", { onDismiss = goMainAct } )
			game.messageBox( "Still Off Target!" )
			game.gotoAct ( "mainAct" )
		end
	end
	return true
end

-- Update energy consumed
function updateEnergy()
	totalRocketImpulses = totalRocketImpulses + 1
	-- also update energy to main resources
	-- game.saveState.resources.kWh = game.saveState.resources.kWh - 0.1
end

-- Turn left button 
function buttonTurnLeftTouch (event)
	if event.phase == "began" and game.saveState.thrustNav.state % 2 == 0 then
		game.playSound( thrusterSound ) 
		print("Turn Left Button ", game.saveState.thrustNav.state )
		accelerateFrameCount = 0
		xVelocity = xVelocity + xVelocityInc
		leftAccelerate = true
		buttonTurnLeftFlame.isVisible = true
		-- printPositions()
		updateEnergy()
		display.getCurrentStage():setFocus( event.target )  -- helps when fingers move
	elseif event.phase == "ended" or event.phase == "cancelled" then
		leftAccelerate = false
		buttonTurnLeftFlame.isVisible = false
		display.getCurrentStage():setFocus(nil)
	end
	return true
end

-- Turn Right button 
function buttonTurnRightTouch (event)
	if event.phase == "began" and game.saveState.thrustNav.state % 2 == 0 then
		game.playSound( thrusterSound )
		print("Turn Right Button, rotation= ", spaceGroup.rotation )
		accelerateFrameCount = 0
		xVelocity = xVelocity - xVelocityInc
		-- xVelocity = xVelocity - xVelocityInc
		-- printPositions()
		rightAccelerate = true
		buttonTurnRightFlame.isVisible = true
		updateEnergy()
		display.getCurrentStage():setFocus( event.target )  -- helps when fingers move
	elseif event.phase == "ended" or event.phase == "cancelled" then
		rightAccelerate = false
		buttonTurnRightFlame.isVisible = false
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
	if event.phase == "began" and game.saveState.thrustNav.state % 2 == 0 then
		game.playSound( thrusterSound )
		print("Pitch Up Button - Rotation = ", spaceGroup.rotation)
		yVelocity = yVelocity + yVelocityInc
		accelerateFrameCount = 0
		upAccelerate = true
		buttonPitchUpFlame.isVisible = true
		-- printPositions()
		updateEnergy()
		display.getCurrentStage():setFocus( event.target )  -- helps when fingers move
	elseif event.phase == "ended" or event.phase == "cancelled" then
		upAccelerate = false
		buttonPitchUpFlame.isVisible = false
		display.getCurrentStage():setFocus(nil)
	end
	return true
end

-- Pitch Down Button
function buttonPitchDownTouch(event)
	if event.phase == "began" and game.saveState.thrustNav.state % 2 == 0 then
		game.playSound( thrusterSound )
		print("Pitch Down Button - Rotation = ", spaceGroup.rotation)
		yVelocity = yVelocity - yVelocityInc
		accelerateFrameCount = 0
		downAccelerate = true
		buttonPitchDownFlame.isVisible = true
		-- printPositions()
		updateEnergy()
		display.getCurrentStage():setFocus( event.target )  -- helps when fingers move
	elseif event.phase == "ended" or event.phase == "cancelled" then
		downAccelerate = false
		buttonPitchDownFlame.isVisible = false
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

-- Act prepare is called after act:init and also when game is played again
function act:prepare()
	print("thrustNav:act:prepare", game.saveState.thrustNav.state )
	game.saveState.thrustNav.onTarget = false
	if( game.saveState.thrustNav.state < 1 ) then  -- start of first time played
		if( game.cheatMode ) then
			-- move spaceGroup to final position
			xVelocity = 0
			yVelocity = 0
			print( "act.width=", act.width, "act.height=", act.height )
			spaceGroup.x = act.width * 0.34375  -- 110 works for iPhone5
    		spaceGroup.y = act.height * 0.4128    -- 165 works for iPhone5
    	end
    elseif( game.saveState.thrustNav.state == 1  ) then  -- start of round 2
		-- move and resize marsffor orbit entry
		game.saveState.thrustNav.state = game.saveState.thrustNav.state + 1
		print( "playing second round of thrustNav", game.saveState.thrustNav.state )
		-- mars.width = mars.width * 8
   		-- mars.height = mars.height * 8
   		xVelocityInc = 0.05
   		yVelocityInc = 0.05
   		mars:scale( 8, 8 )
   		totalRocketImpulses = 0
		xVelocity = 0
		printPositions()
    	-- put a circle around big Mars
   		-- local xCenter = mars.x
		-- local yCenter = mars.y
		-- circle:scale( 8, 8 )
		-- circle = display.newCircle( spaceGroup, xCenter, yCenter, ( mars.width * 4 ) +  mars.width / 1.6 )
		print( "xCenter=", circle.x,"  yCenter=", circle.y )
		print( "mars.width= ", mars.width )
		print( "xmin=", mars.contentBounds.xMin, " xMax=", mars.contentBounds.xMax, 
			" yMin=", mars.contentBounds.yMin, " yMax=", mars.contentBounds.yMax )
		circle.strokeWidth = 2
		circle:setStrokeColor( 0, 1, 0 ) 
		circle:setFillColor( 0, 0, 0, 0.2 )
		circle.isVisible = true
    	if( game.cheatMode ) then		-- move spaceGroup to final position	
			spaceGroup.x = act.width * ( -0.09375 )  --   -30 works for iphone5
    		spaceGroup.y = act.height * 0.4128 -- 165 works for iphone 5
    		yVelocity = 0
		else
    		spaceGroup.x = spaceGroup.x - ( mars.width * 3 ) 
    		spaceGroup.y = spaceGroup.y - ( mars.height * 5 )
    		yVelocity = 0.1
		end
    	-- printPositions()
    	print( "xCenter=", xCenter,"  yCenter=", yCenter )
    	-- if( game.cheatMode ) then
    	--	c.x = (mars.contentBounds.xMax + mars.contentBounds.xMin) / 2 + 30
    	--	c.y = (mars.contentBounds.yMax + mars.contentBounds.yMin) / 2 - act.height / 3.3
    	-- else
    	--	c.x = (mars.contentBounds.xMax + mars.contentBounds.xMin) / 2 - 14
    	--	c.y = (mars.contentBounds.yMax + mars.contentBounds.yMin) / 2 + act.height / 7.4
    	-- end
	elseif( game.saveState.thrustNav.state > 2 ) then
    	game.messageBox( "You are Already in orbit!", { onDismiss = goMainAct } )
		-- game.showHint( "You are Already in orbit!", "Ship Navigation", goMainAct )
	end
end

-- Start the act
function act:start()
	game.playAmbientSound( "Ship Ambience.mp3" )
end

-- Init the act
function act:init()
	-- Load sound effects in Init so that if scene gets destroyed later and then restarted
	-- the sound will be reloaded by init when it is run again
	thrusterSound = act:loadSound( "ignite3.wav" )
	
	-- create group for rotating background space objects
	spaceGroup = act:newGroup()

	-- create the console image
	-- consoleImage = act:newImage( "console.png", { width = act.width - 20 } )
	-- consoleImage.y = act.yMax - 60

	-- Create control buttons, background, etc.
	buttonTurnLeft = act:newImage( "arrowbutton.png", { width = 50, height = 50 } )
	buttonTurnLeft.rotation = -90
	buttonTurnLeftFlame = act:newImage( "rocketfire.png", { width = 17, height = 50 } )
	buttonTurnLeftFlame.rotation = 90
	buttonTurnRight = act:newImage( "arrowbutton.png", { width = 50, height = 50 } )
	buttonTurnRight.rotation = 90
	buttonTurnRightFlame = act:newImage( "rocketfire.png", { width = 17, height = 50 } )
	buttonTurnRightFlame.rotation = -90
--	buttonRollLeft = act:newImage( "arrowbutton.png", { width = 30, height = 30 } )
--	buttonRollRight = act:newImage( "arrowbutton.png", { width = 30, height = 30 } )
	buttonPitchUp = act:newImage( "arrowbutton.png", { width = 50, height = 50 } )
	buttonPitchUpFlame = act:newImage( "rocketfire.png", { width = 17, height = 50 } )
	buttonPitchUpFlame.rotation = 180
	print( "buttonPitchUp=",buttonPitchUp )
	buttonPitchDown = act:newImage( "arrowbutton.png" , { width = 50, height = 50 } )
	buttonPitchDownFlame = act:newImage( "rocketfire.png", { width = 17, height = 50 } )
	print( "buttonPitchDown=",buttonPitchDown )
	buttonPitchDown.rotation = 180

	bgLeft = display.newImageRect( spaceGroup, "media/thrustNav/starrynight.png", 2*act.width, 2*act.height )
	bgLeft.x = act.xCenter
	bgLeft.y = act.yCenter
	bgRight = display.newImageRect( spaceGroup, "media/thrustNav/starrynight.png", 2*act.width, 2*act.height )
	bgRight.x = act.xCenter * 5
	bgRight.y = act.yCenter

	-- print("bg=", bg )

	-- Create position information text for top of screen
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
	
    -- create planets in spaceGroup
    mars = display.newImageRect( spaceGroup, "media/thrustNav/mars.png", 30, 30 )
    print("act.xMin=",act.xMin, " act.yMin=", act.yMin)
    mars.x = act.xMin + act.width * 0.15625
    mars.y = act.yMin + act.height * 0.08803
    print("Mars anchorX=", mars.anchorX, "anchorY=", mars.anchorY )
    print("Mars is placed at ", mars.x, ",", mars.y , " in spaceGroup before move") 

	-- create circle for target orbit and hide it
	circle = display.newCircle( spaceGroup, mars.x, mars.y, ( mars.width * 4 ) +  mars.width / 1.6 )
	circle.isVisible = false

    earth = display.newImageRect( spaceGroup, "media/thrustNav/earth.png", 30, 30 )
    earth.x = mars.x + ( 2 * act.width )
    earth.y = mars.y - 10
    print("Earth anchorX=", earth.anchorX, "anchorY=", earth.anchorY )
    print("Earth is placed at ", earth.x, ",", earth.y , " in spaceGroup before move") 

    sun = display.newImageRect( spaceGroup, "media/thrustNav/sun.png", 60, 60 )
    sun.x = mars.x + ( 1.3 * act.width )
    sun.y = act.yCenter 

  
    -- Set values for moving background
	xVelocity = 2.1 -- 3.5
	yVelocity = 0.1
	rotVelocity = 0
	xVelocityInc = 0.1
	yVelocityInc = 0.1
	rotVelocityInc = 0.01

    -- Crosshair in the center
	-- local dy = 200
	-- local dx = 20
	-- display.newLine( act.group, act.xCenter, act.yCenter - dy, act.xCenter, act.yCenter + dy )
	-- display.newLine( act.group, act.xCenter - dx, act.yCenter, act.xCenter + dx, act.yCenter )
	--targetRect = display.newRect( act.group, act.xCenter, act.yCenter, 15, 15 )
	targetRect = act:newImage( "ship.png", {width = 30})

	-- On Target Indicators
	onTargetX = act:newImage( "targetx.png", { height = act.width/2, width = act.width/2 } )
	onTargetX.isVisible = false
	onTargetY = act:newImage( "targety.png", { height = act.width/2, width = act.width/2 } )
	onTargetY.isVisible = false
	onTargetXY = act:newImage( "targetxy.png", { height = act.width/2, width = act.width/2 } )
	onTargetXY.isVisible = false

    -- Set up buttons
	buttonTurnLeft.x = act.xMin + act.width / 6
	buttonTurnLeft.y = act.yMax - act.height / 12
	buttonTurnLeft.isVisible = true
	buttonTurnLeftFlame.x = buttonTurnLeft.x + buttonTurnLeft.width / 2 + buttonTurnLeftFlame.height / 2
	buttonTurnLeftFlame.y = buttonTurnLeft.y
	buttonTurnLeftFlame.isVisible = false 

	buttonTurnRight.x = act.xMax - act.width / 6
	buttonTurnRight.y = act.yMax - act.height / 12
	buttonTurnRight.isVisible = true
	buttonTurnRightFlame.rotation = -90
	print("width=", buttonTurnRightFlame.width)
	buttonTurnRightFlame.x = buttonTurnRight.x - buttonTurnRight.width / 2 - buttonTurnRightFlame.height / 2
	buttonTurnRightFlame.y = buttonTurnRight.y
	buttonTurnRightFlame.isVisible = false 

	--- buttonRollLeft.x = act.xMax - (act.xMax - act.xMin) / 8
	--- buttonRollLeft.y = act.yMax - (act.yMax - act.yMin) / 20
	--- buttonRollLeft.isVisible = true

	-- Use act.width and act.height
	--- buttonRollRight.x = act.xMin + (act.xMax - act.xMin) / 5
	--- buttonRollRight.y = act.yMax - (act.yMax - act.yMin) / 20
	--- buttonRollRight.isVisible = true

	buttonPitchUp.x = act.xCenter
	buttonPitchUp.y = act.yMax - act.height / 6
	buttonPitchUp.isVisible = true
	buttonPitchUpFlame.x = buttonPitchUp.x 
	buttonPitchUpFlame.y = buttonPitchUp.y + buttonPitchUp.width / 4 + buttonPitchUpFlame.height / 2
	buttonPitchUpFlame.isVisible = false 


	buttonPitchDown.x = act.xCenter
	buttonPitchDown.y = act.yMax - act.height / 18 
	buttonPitchDown.isVisible = true
	buttonPitchDownFlame.x = buttonPitchDown.x 
	buttonPitchDownFlame.y = buttonPitchDown.y - buttonPitchDown.width / 4 - buttonPitchDownFlame.height / 2
	buttonPitchDownFlame.isVisible = false 

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

	-- print("spaceGroup.x= ",spaceGroup.x )
end

-- draw arrow toward mars or orbit target
function updateArrow()
	
	local marsCenterX = (mars.contentBounds.xMax + mars.contentBounds.xMin)/2 
	local marsCenterY = (mars.contentBounds.yMax + mars.contentBounds.yMin)/2 
	local marsRightEdge = mars.contentBounds.xMax + 20 
	if ( arrow ~= nil) then
		arrow:removeSelf()
		arrow = nil
	end
	if( game.saveState.thrustNav.state < 2 ) then  -- start of first play
		arrow = display.newLine( act.group, act.xCenter, act.yCenter, marsCenterX, marsCenterY )
	else
		arrow = display.newLine( act.group, act.xCenter, act.yCenter, marsRightEdge, marsCenterY )
	end
	-- print("xc=", marsCenterX, "  yc=", marsCenterY )
end
	
-- function definition to use in showHint call
function goMainAct()
	game.gotoAct ( "mainAct" )
end
	

-- Update on navigation stats for users reference
function updateNavStats()
	local xStr = ""
	local yStr = ""
	local rotStr = ""

	if( game.saveState.thrustNav.state < 1 ) then	-- start of first play
		xTargetDelta = ( mars.contentBounds.xMax + mars.contentBounds.xMin ) / 2 - act.xCenter  
		yTargetDelta = ( mars.contentBounds.yMax + mars.contentBounds.yMin ) / 2 - act.yCenter  
	elseif ( game.saveState.thrustNav.state == 2 ) then	-- start of second play
		xTargetDelta = ( mars.contentBounds.xMax + 20 ) - act.xCenter  
		yTargetDelta = ( mars.contentBounds.yMax + mars.contentBounds.yMin ) / 2 - act.yCenter 
	end		

	if( math.abs( xTargetDelta ) < 3  ) then 
		xStr = xStr .. " On Target" 
		onTargetX.isVisible = true
	else
		onTargetX.isVisible = false
		onTargetXY.isVisible = false
	end
	if( math.abs( yTargetDelta ) < 3  ) then 
		yStr = yStr .. " On Target" 
		onTargetY.isVisible = true
	else
		onTargetY.isVisible = false
		onTargetXY.isVisible = false
	end
	if( math.abs( yTargetDelta ) < 3 and math.abs( xTargetDelta ) < 3 ) then
		onTargetXY.isVisible = true
	else
		onTargetXY.isVisible = false
	end

	if( onTargetXY.isVisible == true and math.abs( xVelocity ) < 0.00001 and math.abs( yVelocity ) < 0.00001 
			and game.saveState.thrustNav.state < 1 ) then   -- start of first play
		printPositions()
		-- game.messageBox( "Nicely Done!!", { width = act.width * 4, fontSize = 200 })
		game.saveState.thrustNav.state = game.saveState.thrustNav.state + 1
		-- game.showHint( "Nicely Done!  You are On Target!", "Ship Navigation", goMainAct )
		game.messageBox( "Nicely Done!  You are On Target!", { onDismiss = goMainAct } )
		game.saveState.thrustNav.onTarget = true
	elseif( onTargetXY.isVisible == true and math.abs( xVelocity ) < 0.00001 and math.abs( yVelocity ) < 0.00001 
			and game.saveState.thrustNav.state == 2 ) then
		-- game.messageBox( "Nicely Done!!", { width = act.width * 4, fontSize = 200 })
		printPositions()
		print("state=", game.saveState.thrustNav.state )
		game.saveState.thrustNav.state = game.saveState.thrustNav.state + 1
		-- game.showHint( "Nicely Done!  You are now in Orbit!", "Ship Navigation", goMainAct )
		game.messageBox( "Nicely Done!  You are in Orbit!", { onDismiss = goMainAct } )
		game.saveState.thrustNav.onTarget = true
	end

	if( hasCollided( earth, targetRect )  and earthHasCollided == false ) then
		game.messageBox( "Are you going Home!?!" )
		-- navStatsText1.text = "Where are you going?  Home?"	
		earthHasCollided = true
	elseif( hasCollided( sun, targetRect ) and sunHasCollided == false ) then
		-- navStatsText1.text = "That will be VERY HOT!"
		game.messageBox( "That will be VERY HOT!!"  )	
		sunHasCollided = true
	else
		navStatsText1.text = string.format( "                       %+6s %+5s", "Angle", "Vel"  )
		navStatsText2.text = string.format( "%+12s  %+8.1f %+7.2f", "Horizontal=", xTargetDelta * 90 / act.width , xVelocity )
		navStatsText3.text = string.format( "%+12s  %+8.1f %+7.2f", " Vertical    =", yTargetDelta * 90 / act.height , yVelocity )
	end
end

--  Move and update space background 
function updatePosition()
	spaceGroup.x = spaceGroup.x + xVelocity
	spaceGroup.y = spaceGroup.y + yVelocity
	-- spaceGroup.rotation = spaceGroup.rotation + rotVelocity

	-- check for button holds
	if( leftAccelerate == true and game.saveState.thrustNav.state % 2 == 0 ) then
		accelerateFrameCount = accelerateFrameCount + 1
		if( accelerateFrameCount % 10 == 0 ) then
			xVelocity = xVelocity + xVelocityInc
			updateEnergy()
		end
		if( accelerateFrameCount > 10 ) then
			game.playSound( thrusterSound )
			accelerateFrameCount = 0
		end
	elseif( rightAccelerate == true and game.saveState.thrustNav.state % 2 == 0 ) then
		accelerateFrameCount = accelerateFrameCount + 1
		if( accelerateFrameCount % 10 == 0 ) then
			xVelocity = xVelocity - xVelocityInc
			updateEnergy()
		end
		if( accelerateFrameCount > 10 ) then
			game.playSound( thrusterSound )
			accelerateFrameCount = 0
		end
	elseif( upAccelerate == true and game.saveState.thrustNav.state % 2 == 0 ) then
		accelerateFrameCount = accelerateFrameCount + 1
		if( accelerateFrameCount % 10 == 0 ) then
			yVelocity = yVelocity + yVelocityInc
			updateEnergy()
		end
		if( accelerateFrameCount > 10 ) then
			game.playSound( thrusterSound )
			accelerateFrameCount = 0
		end
	elseif( downAccelerate == true and game.saveState.thrustNav.state % 2 == 0 ) then
		accelerateFrameCount = accelerateFrameCount + 1
		if( accelerateFrameCount % 10 == 0 ) then
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
			circle.x = circle.x - ( 4 * act.width )  -- move circle with mars
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
			circle.x = circle.x + ( 4 * act.width )  -- move circle with mars
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
		-- print( "msg about computer assisted vertical stabilization") 
		yVelocity = 0
		if not stabilityWarning then
			stabilityWarning = true
			game.messageBox( "Vertical Stability Activated", { onDismiss = 
					function ()
						stabilityWarning = false
					end })
		end
		print( string.format("yVelocity = %5.3f", yVelocity) )
	end
end

-- print debug positon information to console
function printPositions()
	print("Mars  x=", mars.x, "  y=", mars.y, "  ax=", mars.anchorX, "  ay=", mars.anchorY )
	print("Circle  x=", circle.x, "  y=", circle.y, "  ax=", circle.anchorX, "  ay=", circle.anchorY )
	print("Mars  contentBounds.xMin=", mars.contentBounds.xMin, "  Mars cb.xMax=", mars.contentBounds.xMax )
	print("Mars  contentBounds.yMin=", mars.contentBounds.yMin, "  Mars cb.yMax=", mars.contentBounds.yMax )
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
