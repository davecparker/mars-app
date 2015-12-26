-----------------------------------------------------------------------------------------
--
-- shipLanding.lua
--
-- Ship Landing Activity by Ryan Bains-Jordan
-----------------------------------------------------------------------------------------

-- Get local reference to the game globals
local game = globalGame

-- Create the act object
local act = game.newAct()

-- Act Requisites
local physics = require( "physics" )
local widget = require( "widget" )

------------------------- Start of Activity --------------------------------

-- Display Groups
local map
local ship
local endGame

-- Sound
local sound = {}
local soundChannel = {}
local musicChannel = {}

-- Boolean Variables that may loop in newFrame
local thrustOn = false
local isEnded = false
local isRotateC = false
local isRotateCC = false
local gameEnded = false

-- Numberic Variables and Constants
local MAPXMIN, MAPXMAX = 20, 660		-- Playable area of the map
local LANDXMIN, LANDXMAX = 350, 550		-- Borders of the successful land area					
local LANDDETECTOR = 3520				-- Height of the landing detector
local CRASHDETECTOR = 3500				-- Height of the crash detector
local LANDHEIGHT = 3600					-- Height of the physical land
local SHIPSTARTX, SHIPSTARTY			-- Start position of the ship

-- Scales
local verticalScale, horizontalScale

--------------------
-- Listener Functions
--------------------

-- Listener for Back Button
local function back()
	game.shipLanded = true  -- TODO: Temporary
	game.gotoAct( "mainAct", { effect = "zoomOutIn", time = 500 } )
end

-- Listener for Thrust Button 
local function thrust( event )
	if event.phase == "began" then
		thrustOn = true

		ship.leftThrust.isVisible = true
		ship.midLeftThrust.isVisible = true
		ship.midRightThrust.isVisible = true
		ship.rightThrust.isVisible = true

		soundChannel.ignite = game.playSound( sound.ignite )
		soundChannel.thrust = game.playSound( sound.thrust, { loops = -1 } )
	elseif event.phase == "ended" then
		thrustOn = false

		ship.leftThrust.isVisible = false
		ship.midLeftThrust.isVisible = false
		ship.midRightThrust.isVisible = false
		ship.rightThrust.isVisible = false
		
		game.stopSound( soundChannel.thrust )
	end
	return true
end

-- Listener for clockwise rotation button
local function rotateC( event )
	if event.phase == "began" then
		isRotateC = true
		ship.rightThrust.isVisible = true

		soundChannel.ignite = game.playSound( sound.ignite )
		soundChannel.thrust = game.playSound( sound.thrust, { loops = -1 } )
	else
		isRotateC = false
		ship.rightThrust.isVisible = false

		game.stopSound( soundChannel.thrust )
	end
	return true
end

-- Listener for counter-clockwise rotation button
local function rotateCC( event )
	if event.phase == "began" then
		isRotateCC = true
		ship.leftThrust.isVisible = true

		soundChannel.ignite = game.playSound( sound.ignite )
		soundChannel.thrust = game.playSound( sound.thrust, { loops = -1 } )
	else
		isRotateCC = false
		ship.leftThrust.isVisible = false

		game.stopSound( soundChannel.thrust )
	end
	return true
end

-- Function to Correct Landing
local function autopilot( event )
	ship.autopilot = true
	physics.removeBody( ship )

	local autoPilotOff = function( obj )
		physics.addBody( ship, { density = 0.6 } )

		ship.leftThrust.isVisible, ship.midLeftThrust.isVisible = false, false
		ship.rightThrust.isVisible, ship.midRightThrust.isVisible = false, false
		
		game.stopSound( soundChannel.thrust )

		ship.autopilot = false
	end

	transition.to( ship, { y = ship.y - 1000, rotation = 0, time = 3000, onComplete = autoPilotOff } )

	ship.leftThrust.isVisible, ship.midLeftThrust.isVisible = true, true
	ship.rightThrust.isVisible, ship.midRightThrust.isVisible = true, true

	soundChannel.ignite = game.playSound( sound.ignite )
	soundChannel.thrust = game.playSound( sound.thrust, { loops = -1 } )	
end

-- Function for Ending the Game
local function endTheGame( )
	endGame.isVisible = true
	physics.pause( )
	gameEnded = true
end

--------------------
-- Looped Functions
--------------------

local function moveCamera()
	if ( ship.y > 200 and ship.y < 3355 ) then --3275
		map.y = -ship.y + 200 
	end
	if ( ship.x > 200 and ship.x < 540 ) then
		map.x = -ship.x + 200
	end
end

local function testLanding()

	if ship.y > LANDDETECTOR then
		local xv, yv = ship:getLinearVelocity( )

		-- Successful Landing
		if ship.x > LANDXMIN and ship.x < LANDXMAX	-- Is the ship in the x landing range
			and math.abs( ship.rotation ) < 10		-- Is the ship rotation somewhat flat
			and math.abs( xv ) < 30				-- Is the ships xVelocity less than 30
			--and math.abs( yv ) < 20				-- Is the ships yVelocity less than 20
			then
			--print("successful landing")
			if gameEnded == false then
				endTheGame()
			end

		-- Unsuccessful Landing
		else
			ship.autopilot = true
		end
	end
end

local function testWillCrash()

	-- If the ship has passed the CRASHDETECTOR and is about to crash
	if ship.y > CRASHDETECTOR then
		local xv, yv = ship:getLinearVelocity( )
		print( yv )
		if yv > 75 then
			print( yv )
			return true
		end	
	end
	-- If the ship has passed the CRASHDETECTOR but is not about to crash
	return false

end

--------------------
-- Convenience Functions
--------------------

-- Convenience Function for creating Rotation buttons
local function createSideThrustButton( scene, x, y, vertices, listener )
	local b = widget.newButton {
		x = x, y = y,
		shape = "polygon",
		vertices = vertices,
		fillColor = { default = { game.themeColor.r, game.themeColor.g, game.themeColor.b }, 
			over = { game.themeHighlightColor.r, game.themeHighlightColor.g, game.themeHighlightColor.b } },
	    labelColor = { default={ 1, 1, 1 } },
		onEvent = listener
	}
	scene:insert(b)
	return b
end

-----------------------------------------------------------------------------------------
-- Init Game
-----------------------------------------------------------------------------------------

function act:init( )

	SHIPSTARTX, SHIPSTARTY = act.xCenter, 80 

	-- Scale used to determine altitude of ship
	verticalScale = act:newGroup( )
	verticalScale.top = act.yMin + 40
	verticalScale.bottom = act.yMax - 100

	-- Scale used to determine linear location of ship
	horizontalScale = act:newGroup( )
	horizontalScale.left = act.xMin + 100
	horizontalScale.right = act.xMax - 40

	physics.start( )
	physics.pause( )
	physics.setScale( 10 )

	sound.ignite = act:loadSound( "ignite.wav" )
	sound.thrust = act:loadSound( "thrust.wav" )

	-- Background
	map = act:newGroup( )
	local background = act:newImage( "background.png", { parent = map } )
	background.anchorX, background.anchorY = 0, 0
	background.x, background.y = -20, -40

	-- Ground Object
	local ground = display.newRect( map, 0, LANDHEIGHT, MAPXMAX, 50 )
	ground.anchorX = 0
	ground.anchorY = 1
	ground:setFillColor( 1, 1, 1, 0 )
	physics.addBody( ground, "static" )

	-- Ship
	ship = act:newGroup( map )
	ship.x, ship.y = SHIPSTARTX, SHIPSTARTY
	ship.image = act:newImage( "ship.png", { parent = ship, width = 150 } )
	ship.image.x, ship.image.y = 0, 0

	ship.leftThrust = act:newImage( "rocketfire.png", { parent = ship } )
	ship.leftThrust.x, ship.leftThrust.y, ship.leftThrust.rotation = -55, 15, 45
	ship.midLeftThrust = act:newImage( "rocketfire.png", { parent = ship } )
	ship.midLeftThrust.x, ship.midLeftThrust.y = 4, 20
	ship.midRightThrust = act:newImage( "rocketfire.png", { parent = ship } )
	ship.midRightThrust.x, ship.midRightThrust.y = 22, 20
	ship.rightThrust = act:newImage( "rocketfire.png", { parent = ship } )
	ship.rightThrust.x, ship.rightThrust.y, ship.rightThrust.rotation = 65, 15, -45
	
	physics.addBody( ship, { density = 0.6 } )

	ship.leftThrust.isVisible = false
	ship.midLeftThrust.isVisible = false
	ship.midRightThrust.isVisible = false
	ship.rightThrust.isVisible = false

	ship.autopilot = false

	-- Torches
	local torch1 = act:newImage( "torch.png", { parent = map, width = 25 } )
	local torch2 = act:newImage( "torch.png", { parent = map, width = 25 } )
	torch1.x, torch1.y = LANDXMIN, LANDHEIGHT - 50
	torch2.x, torch2.y = LANDXMAX, LANDHEIGHT - 50

	-- End Game
	endGame = act:newGroup( )
	endGame.header = display.newText( endGame, "Successful Landing", act.xCenter, act.yCenter, native.systemFontBold, 30 )
	endGame.header:setFillColor( 0 )
	endGame.isVisible = false

	--------------------
	-- Scales
	--------------------

	-- Vertical Scale Line
	local vsty, vsby = verticalScale.top, verticalScale.bottom
	verticalScale.x = act.xMax - 20
	verticalScale.mainLine = display.newLine( verticalScale, 0, vsty, 0, vsby )				-- The large line on the side of the screen
	verticalScale.topLine = display.newLine( verticalScale, -10, vsty, 10, vsty )			-- The top barrier for the line
	verticalScale.bottomLine = display.newLine( verticalScale, -10, vsby, 10, vsby )		-- The bottom barrier for the line
	verticalScale.positionLine = display.newLine( verticalScale, -10, vsty, 10, vsty )		-- The moving altitude line
	act.group:insert( verticalScale )

	-- Horizontal Scale Line
	local hslx, hsrx = horizontalScale.left, horizontalScale.right
	horizontalScale.y = act.yMin + 20
	horizontalScale.mainLine = display.newLine( horizontalScale, hslx, 0, hsrx, 0 )			-- The large line at the top of the screen
	horizontalScale.leftLine = display.newLine( horizontalScale, hslx, -10, hslx, 10 )		-- The left most barrier for the line
	horizontalScale.rightLine = display.newLine( horizontalScale, hsrx, -10, hsrx, 10 )		-- The right most barrier for the line
	horizontalScale.positionLine = display.newLine( horizontalScale, hslx, -10, hslx, 10 )	-- The moving linear distance line
	act.group:insert( horizontalScale )

	--display.newLine( map, 0, LANDDETECTOR, 700, LANDDETECTOR )
	--display.newLine( map, 0, CRASHDETECTOR, 700, CRASHDETECTOR )

	--------------------
	-- Buttons
	--------------------
--[[
	-- Back Button
	local backBtn = widget.newButton {
		label = "Back",
		x = act.xMin + 40, y = act.yMin + 30,
		shape = "roundedRect",
		width = 60, height = 40,
		fillColor = { default = { game.themeColor.r, game.themeColor.g, game.themeColor.b }, 
			over = { game.themeHighlightColor.r, game.themeHighlightColor.g, game.themeHighlightColor.b } },
	    labelColor = { default={ 1, 1, 1 } },
	    onEvent = back
	}
	act.group:insert( backBtn )

	-- Thrust Button
	local thrustBtn = widget.newButton {
		--label = "Thrust",
		x = act.xMin + 40, y = act.yMax, -- yMax - 35
		shape = "circle",
		radius = 30,
		fillColor = { default = { game.themeColor.r, game.themeColor.g, game.themeColor.b }, 
			over = { game.themeHighlightColor.r, game.themeHighlightColor.g, game.themeHighlightColor.b } },
	    labelColor = { default={ 1, 1, 1 } },
	    onEvent = thrust
	}
	act.group:insert( thrustBtn )

	-- Rotation Buttons
	local rotateCBtn = createSideThrustButton( act.group, act.xMax - 80, act.yMax - 35, 
		{ 0, -30, -40, 0, 0, 30 }, rotateC )
	local rotateCCBtn = createSideThrustButton( act.group, act.xMax - 30, act.yMax - 35, 
		{ 0, -30, 40, 0, 0, 30 }, rotateCC )

	--physics.setDrawMode( "hybrid" )
--]]
end

-----------------------------------------------------------------------------------------
-- EnterFrame Loop
-----------------------------------------------------------------------------------------

function act:enterFrame()
	
	-- When the user is about to crash
	if ship.autopilot == true then
		moveCamera()
		
		--TODO: Find a better way to adjust the scales (Function not working)
		-- Vertical Scale
		verticalScale.positionLine:removeSelf( )
		verticalScale.distance = LANDHEIGHT - ship.y
		verticalScale.ratio = verticalScale.distance / ( LANDHEIGHT - SHIPSTARTY )
		verticalScale.size = verticalScale.bottom - verticalScale.top
		verticalScale.indicator = verticalScale.bottom - ( verticalScale.ratio * verticalScale.size )
		verticalScale.positionLine = display.newLine( verticalScale, -10, verticalScale.indicator, 10, verticalScale.indicator )

		-- Horizontal Scale
		horizontalScale.positionLine:removeSelf( )
		horizontalScale.distance = MAPXMAX - ship.x
		horizontalScale.ratio = horizontalScale.distance / ( MAPXMAX - MAPXMIN )
		horizontalScale.size = horizontalScale.right - horizontalScale.left
		horizontalScale.indicator = horizontalScale.right - ( horizontalScale.ratio * horizontalScale.size )
		horizontalScale.positionLine = display.newLine( horizontalScale, horizontalScale.indicator, -10, horizontalScale.indicator, 10 )

	-- When the user is not about to crash
	else
		if thrustOn then
			local a = ship.rotation * math.pi / 180
			local xf = math.sin(a) * 1000
			local yf = math.cos(a) * -1000
			ship:applyForce( xf, yf, ship.x, ship.y)
		end

		if isRotateC then
			ship:rotate(-1)
		elseif isRotateCC then
			ship:rotate(1)
		end

		-- Stop the ship from flying past boundries
		if ship.x > MAPXMAX then
			ship.x = MAPXMAX
			local xv, yv = ship:getLinearVelocity( )
			ship:setLinearVelocity( 0, xy )
		elseif ship.x < MAPXMIN then
			ship.x = MAPXMIN
			local xv, yv = ship:getLinearVelocity( )
			ship:setLinearVelocity( 0, xy )
		elseif ship.y < SHIPSTARTY then
			ship.y = SHIPSTARTY
			local xv, yv = ship:getLinearVelocity( )
			ship:setLinearVelocity( xv, 0 )
		end

			if testWillCrash() then
			autopilot()
		end

		--------------------
		-- Scales
		--------------------

		-- Vertical Scale
		verticalScale.positionLine:removeSelf( )
		verticalScale.distance = LANDHEIGHT - ship.y
		verticalScale.ratio = verticalScale.distance / ( LANDHEIGHT - SHIPSTARTY )
		verticalScale.size = verticalScale.bottom - verticalScale.top
		verticalScale.indicator = verticalScale.bottom - ( verticalScale.ratio * verticalScale.size )
		verticalScale.positionLine = display.newLine( verticalScale, -10, verticalScale.indicator, 10, verticalScale.indicator )

		-- Horizontal Scale
		horizontalScale.positionLine:removeSelf( )
		horizontalScale.distance = MAPXMAX - ship.x
		horizontalScale.ratio = horizontalScale.distance / ( MAPXMAX - MAPXMIN )
		horizontalScale.size = horizontalScale.right - horizontalScale.left
		horizontalScale.indicator = horizontalScale.right - ( horizontalScale.ratio * horizontalScale.size )
		horizontalScale.positionLine = display.newLine( horizontalScale, horizontalScale.indicator, -10, horizontalScale.indicator, 10 )

		--------------------
		-- Looped Functions
		--------------------

		moveCamera()
		testLanding()
		
	end
end

-----------------------------------------------------------------------------------------
-- Scene Control
-----------------------------------------------------------------------------------------

function act:prepare( )
	musicChannel = game.playAmbientSound( "Tension.mp3" )
	physics.start( )
end

function act:stop( )
	game.stopAmbientSound( musicChannel )
	physics.pause( )
end

------------------------- End of Activity --------------------------------


-- Corona needs the scene object returned from the act file
return act.scene