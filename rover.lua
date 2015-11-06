-----------------------------------------------------------------------------------------
--
-- rover.lua
--
-- The rover activity of the Mars App
-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------
--
-- Functions in the (global) game table you can use (see game.lua for details):
--    game.pinValue( value, min, max )      -- Constrain a value to a range
--
-- Variables in the act table you can use:
--    act.width    -- width of the activiy area 
--    act.height   -- height of the activity area 
--    act.xMin     -- left edge of the activity area
--    act.xMax     -- right edge of the activity area
--    act.yMin     -- top edge of the activity area
--    act.yMax     -- bottom edge of the activity area
--    act.xCenter  -- x center of the activity area 
--    act.yCenter  -- y center of the activity area
--    act.group    -- display group for the act (parent of all display objects)
--    act.scene    -- composer scene associated with the act
--
-- Methods in the act table you can use (see Act.lua for details):
--    act:newImage( filename, options )    -- make a new imageRect display object

-- How to define an activity:
--    * For now, use mainAct.lua for your activity source file.
--    * Create your display objects in act:init() and put them all in act.group.
--    * If you define act:start() it will be called when the activity starts/resumes.
--    * If you define act:stop() it will be called when the activity suspends/ends.
--    * If you define act:destroy() it will be called when the activity is destroyed.
--    * If you define act:enterFrame() it will be called before every animation frame.
--
-- Some activity rules and hints:
--    * Do not add Runtime enterFrame listeners. Define act:enterFrame() instead. 
--    * Do not use Runtime tap/touch listeners. Attach them to display objects.
--    * Do not use global variables. Use (file) local myVar, game.myVar, or act.myVar.
-----------------------------------------------------------------------------------------
-- Get local reference to the game globals
local game = globalGame

-- Create the act object
local act = game.newAct()

------------------------- Start of Activity --------------------------------
-- File local variables
local staticGrp -- display group for foreground static objects
local dynamicGrp -- display group for dynamic objects
local terrain = {} -- basic terrain
local obstacle = {} -- terrain obstacles
local shape = {} -- possible terrain obstacles
local wheelSprite = {} -- rover wheels
local rover -- the rover
local map -- the map
local bg -- background
local speedText
local elevation = 100 -- terrain elevation
local terrainExcess = 100 -- off display terrain amount
local terrainOffset = -80 -- terrain offset
local terrainColor = { 0.8, 0.35, 0.25 }
local obstacleColor = { 0.3, 0.1, 0.1 }

-- Create new 1-corona unit wide terrain component rectangle 
-- Accepts x-coord & height, returns rectangle display object
local function newRectangle( x, h )
	local rect = display.newRect( dynamicGrp, x, act.yMax, 1, h )
	rect:setFillColor( unpack(terrainColor) )
	rect.anchorY = 1
	physics.addBody( rect, "static", { friction = 1.0 } )
	return rect
end

-- Create new circle terrain component
-- Accepts circle x, y coordinates, returns circle display object
local function randCircle( x, y, r )
	local yDev = math.random( r * 0.7, r * 0.9 ) -- randomly vary y coord w/radius
	local circle = display.newCircle( dynamicGrp, x, y + yDev, r )
	physics.addBody( circle, "static", { friction = 1.0, radius = r } )
	return circle
end

-- Create new square of random side length
-- Accepts square x, y coordinates, returns square display object
local function randSquare( x, y, s )
	local square = display.newRect( dynamicGrp, x, y + s/3, s, s )
	square.rotation = math.random( 30, 60 ) -- random rotation for variation
	physics.addBody( square, "static", { friction = 1.0 } )
	return square
end

-- Create new rounded square of random side length
-- Accepts square x, y coordinates, returns rounded square display object
local function randRoundSquare( x, y, s )
	local square = display.newRoundedRect( dynamicGrp, x, y + s/3, s, s, s/4 )
	square.rotation = math.random( 30, 60 )
	physics.addBody( square, "static", { friction = 1.0 } )
	return square
end

-- Create new trapezoid polygon of random length
-- Accepts x, y coordinates of bottom-left vertice, returns trapezoid display object
local function randPoly( x, y, s )
	local l = math.random( 3, 10 )
	local vertices = { x, y, x + s, y - s, x + s + l, y - s, x + 2 * s + l, y }
	local rotation = math.random( -20, 20 )
	local poly = display.newPolygon( dynamicGrp, x, y + 1.5, vertices )
	poly.rotation = rotation
	physics.addBody( poly, "static", { friction = 1.0 } )
	return poly
end

-- Create terrain of rectangles and randomly selected, sized, & rotated polygons
local function newTerrain( nObstacles)
	-- fill shape table with terrain obstacle shape functions
	shape = { randCircle, randSquare, randRoundSquare, randPoly }
	
	-- fill obstacle table with shapes randomly distributed along terrain x-axis extent
	-- obsolete: local zoneLength = math.floor( (act.width + terrainExcess)/nObstacles )	
	for i = 1, nObstacles do
		-- obsolete: local x = math.random( (i - 1) * zoneLength, i * zoneLength ) + terrainOffset
		local x = math.random( (i - 1) + terrainOffset, act.width + terrainExcess + terrainOffset )
		local y = act.yMax - elevation
		local size = math.random( 5, 10 )
		obstacle[i] = shape[math.random(1, 4)]( x, y, size )
		obstacle[i]:setFillColor( unpack(obstacleColor)  )
	end

	-- fill terrain with rectangles to span display width plus terrainExcess
	for i = 1, act.width + terrainExcess do
		terrain[i] = newRectangle( i - 1 + terrainOffset, elevation )
	end
end

-- create new rover map location tracking dot
local function newMapDot()
	local dotData = { 
		parent = staticGrp, 
		x = game.saveState.roverCoord.x1, 
		y = game.saveState.roverCoord.y1, 
		width = 6, 
		height = 6 
	} 

	map.rover = act:newImage( "tracking_dot1.png", dotData )
	map.rover.x = game.saveState.roverCoord.x1 
	map.rover.y = game.saveState.roverCoord.y1 
end

-- Create the rover
local function newRover( roverY )

	-- tables to hold suspension joints
	local suspension = {}
	local wheelToWheelJoint = {}
	-- local wheelToBodyJoint = {}

	-- create rover
	local roverData = { 
		parent = dynamicGrp, 
		x = act.xMin + 100, 
		y = roverY, 
		width = 65, 
		height = 50 
	} 
	
	rover = act:newImage( "rover_body.png", roverData )
	rover.anchorY = 1.0
	rover.angularV = 0
	rover.distOldX = rover.x -- previous x for distance traveled calculation
	rover.speedOldX = rover.x -- previous x for speed calculation
	rover.kph = 0 
	rover.accelerate = false
	rover.brake = false

	-- rover body physics: low density for minimal sway & increased stability
	physics.addBody( rover, "dynamic", { density = 0.2, friction = 0.3, bounce = 0.2 } )

	-- create an image sheet for rover wheel sprites
	local options = {
		width = 175,
		height = 175,
		numFrames = 7
	}

	local wheelSheet = graphics.newImageSheet( 'media/rover/tonka_wheel_sheet.png', options )

	-- create 4 wheel sprites situated along rover body
	local sequenceData = {
		name = "wheelSequence",
		start = 1,
		count = 7,
	}

	for i = 1, 3 do
		wheelSprite[i] = display.newSprite( dynamicGrp, wheelSheet, sequenceData )
		wheelSprite[i].x = rover.x - 27 + (i - 1) * 27
		wheelSprite[i].y = rover.y + 4
		wheelSprite[i]:scale( 0.12, 0.12 )

		-- wheel physics
		-- higher density increases translation & stability; 0.5-1.5 gives best results.
		-- higher friction increases acceleration and decreases stability.
		local wheelPhysicsData = {
			density = 1.0, 
			friction = 1.0, 
			bounce = 0.2, 
			radius = 9.25
		}

		physics.addBody( wheelSprite[i], "dynamic", wheelPhysicsData )

		-- x-axis & y-axis values affect wheel translation in combination with wheel-to-wheel joints
		-- per x-axis, a higher y-axis value decreases translation; 25-50 y-axis gives best results
		suspension[i] = physics.newJoint( "wheel", rover, wheelSprite[i], 
			wheelSprite[i].x, wheelSprite[i].y, 1, 30 )
	end

	-- wheel-to-wheel distance joints to limit lateral wheel translation 
	for i = 1, 2 do
		wheelToWheelJoint[i] = physics.newJoint( "distance", wheelSprite[i], wheelSprite[i+1],
			wheelSprite[i].x, wheelSprite[i].y, wheelSprite[i+1].x, wheelSprite[i+1].y )
	end

--[[
	-- wheel-to-body distance joints to reduce wheel translation
	-- seems ineffective and decreases stability 
	for i = 1, 4 do
		wheelToBodyJoint[i] = physics.newJoint( 'distance', wheel[i], rover,
			wheel[i].x, wheel[i].y, rover.x - 27 + (i - 1) * 18 , rover.y - 25)
		wheelToBodyJoint[1].dampingRatio = 0.5
		wheelToBodyJoint[1].frequency = 0.5
	end
--]]
	newMapDot()
end

-- Accelerate the rover up to angular velocity of 8000 w/higher initial acceleration
local function accelRover()
	if rover.angularV <= 150 then -- higher initial acceleration
		rover.angularV = rover.angularV + 50 
	--elseif rover.angularV > 700 and rover.angularV < 2000 then
	--	rover.angularV = rover.angularV + 100
	elseif rover.angularV + 20 > 8000 then -- top speed
		rover.angularV = 8000
	else
		rover.angularV = rover.angularV + 20 -- typical acceleration
	end
end

-- Decelerate the rover; deceleration varies inversely with speed for stability
local function brakeRover()
	if rover.kph < 20 then
		rover.angularV = 0
	else 
		rover.angularV = rover.angularV * rover.kph/500
	end
end

-- Let the rover coast, with increased deceleration during high AOA (wheelie) instances
local function coastRover()
	local aoa = rover.rotation % 360

	-- if high angle-of-attack, then greater deceleration for stability
	if (aoa > -100 and aoa < -60) or (aoa > 260 and aoa < 300) then
		wheelSprite[1].linearDampening = 1000
		if rover.kph < 10 then
			rover.angularV = 0
		else
			rover.angularV = rover.angularV * 0.9 
		end
	elseif rover.angularV > 100 then
		rover.angularV = rover.angularV * 0.99 -- normal deceleration
	elseif rover.angularV - 1 > 0 then
		rover.angularV = rover.angularV - 1 -- final deceleration to 0
	else
		rover.angularV = 0
	end
end

-- Acceleration touch event handler
local function bgTouched( event )
	if event.phase == "began" then
		rover.accelerate = true
	elseif event.phase == "ended" or event.phase == "cancelled" then
		rover.accelerate = false
	end
end

-- Map touch event handler
local function mapTouched( event )
	if event.phase == "began" then
		local x1 = game.saveState.roverCoord.x1
		local y1 = game.saveState.roverCoord.y1
		local x2 = event.x
		local y2 = event.y

		map.courseLength = math.sqrt((x2 - x1)*(x2 - x1) + (y2 - y1)*(y2 - y1))

		-- if course exists, calculate unit vectors & find map boundary intersection point
		if map.courseLength > 0 then
			map.courseVX = (x2 - x1)/map.courseLength
			map.courseVY = (y2 - y1)/map.courseLength

			for i = 1, math.max(map.width, map.height) do
				if game.xyInRect(x2 + map.courseVX, y2 + map.courseVY, map) then
					x2 = x2 + map.courseVX
					y2 = y2 + map.courseVY
				else
					x2 = x2 - 2 * map.courseVX
					y2 = y2 - 2 * map.courseVY
					break
				end
			end
		else
			map.courseVX = 0
			map.courseVY = 0
		end

		-- set global variables to new destination coordinates
		game.saveState.roverCoord.x2 = x2
		game.saveState.roverCoord.y2 = y2

		-- remove old course, draw new course
		display.remove( map.course )
		display.remove( map.courseArrow )
		map.course = display.newLine( staticGrp, x1, y1, x2, y2 )
		map.course:setStrokeColor( 1, 1, 1 )
		map.course.strokeWidth = 2

		-- create course arrow and rotate according to course direction
		local arrowData = { 
			parent = staticGrp, 
			x = x2 + 2 * map.courseVX, 
			y = y2 + 2 * map.courseVY, 
			height = 10 
		} 
		
		map.courseArrow = act:newImage( "arrow.png", arrowData )
		map.courseArrow.anchorY = 0
		map.courseArrow.rotation = math.deg(math.atan2(y2 - y1, x2 - x1)) + 90
		map.rover:toFront()	
	end
	return true
end

-- Adjust and apply rover wheel angular velocity
local function moveRover()

	if map.courseLength > 0 then
		-- accelerate, brake, or coast rover
		if rover.accelerate then
			accelRover()
		elseif rover.brake then
			brakeRover()
		else
			coastRover()
		end

		-- determine wheel sprite frame
		local wheelFrame
		if rover.angularV > 700 then 
			wheelFrame = 7
		elseif rover.angularV < 200 then 
			wheelFrame = 1
		else
			wheelFrame = math.floor( rover.angularV/100 )
		end

		-- apply wheel angular velocity & sprite frame to the wheel sprites
		-- rear wheel at half speed for stability
		wheelSprite[1].angularVelocity = rover.angularV/2
		wheelSprite[1]:setFrame( wheelFrame )

		for i = 2, 3 do
			wheelSprite[i].angularVelocity = rover.angularV
			wheelSprite[i]:setFrame( wheelFrame )
		end

		-- calculate distance rover has moved and new course length
		local distMoved = ( rover.x - rover.distOldX )/100
		map.courseLength = map.courseLength - distMoved

		-- if the rover has moved and still has a course (has not reached its destination)
		if map.courseLength > 0 and distMoved ~= 0 then

			-- calculate new current position coordinates
			local x1 = game.saveState.roverCoord.x1 + distMoved * map.courseVX
			local y1 = game.saveState.roverCoord.y1 + distMoved * map.courseVY
			local x2 = game.saveState.roverCoord.x2
			local y2 = game.saveState.roverCoord.y2
			game.saveState.roverCoord.x1 = x1
			game.saveState.roverCoord.y1 = y1

			-- replace old course with new course
			display.remove( map.course )
			display.remove( map.courseArrow )
			map.course = display.newLine( staticGrp, x1, y1, x2, y2 )
			map.course:setStrokeColor( 1, 1, 1 )
			map.course.strokeWidth = 2

			-- create course arrow
			local arrowData = { 
				parent = staticGrp, 
				x = x2 + 2 * map.courseVX, 
				y = y2 + 2 * map.courseVY, 
				height = 10 
			} 
			
			map.courseArrow = act:newImage( "arrow.png", arrowData )
			map.courseArrow.anchorY = 0
			map.courseArrow.rotation = math.deg(math.atan2(y2 - y1, x2 - x1)) + 90
			map.rover:toFront()	

			map.rover.x = game.saveState.roverCoord.x1
			map.rover.y = game.saveState.roverCoord.y1
		-- if rover has reached destination, then stop & set coords to destination coords
		elseif map.courseLength <= 0 then
			game.saveState.roverCoord.x1 = game.saveState.roverCoord.x2
			game.saveState.roverCoord.y1 = game.saveState.roverCoord.y2
			map.rover.x = game.saveState.roverCoord.x1
			map.rover.y = game.saveState.roverCoord.y1
			display.remove( map.course )
			display.remove( map.courseArrow )
			rover.angularV = 0
		end
	end

	rover.distOldX = rover.x	
end

-- Scroll the terrain to the left
local function moveTerrain()
	-- recycle terrain rectangle if sufficiently offscreen
    for i = 1, #terrain do
		if terrain[i].contentBounds.xMax < act.xMin + terrainOffset then
			terrain[i].x = terrain[i].x + act.width + terrainExcess
		end
	end

	-- remove obstacle if sufficiently offscreen x left
	-- create new random obstacle of random size at random offscreen x right
	for i = 1, #obstacle do
		if obstacle[i].contentBounds.xMax < act.xMin + terrainOffset then
			local x = math.random( 
				obstacle[i].x + act.width + terrainExcess, 
				obstacle[i].x + 2 * ( act.width + terrainExcess ) )
			local size = math.random( 5, 10 )
			display.remove( obstacle[i] )
			obstacle[i] = shape[math.random(1, 4)]( x, act.yMax - elevation, size )
			obstacle[i]:setFillColor( unpack(obstacleColor)  )
			obstacle[i]:toBack()
			physics.addBody( obstacle[i], "static", { friction = 1.0 } )
		end
	end
end

-- Stop button event handler
local function onStopPress( event )
	rover.brake = true
end

-- Stop button event handler
local function onStopRelease( event )
	rover.brake = false
end

-- Reset button event handler
local function onResetPress( event )
	-- reposition terrain
	for i = 1, #terrain do
		terrain[i].x = terrain[i].x - rover.x + 100
	end

	-- reposition obstacles
	for i = 1, #obstacle do
		obstacle[i].x = obstacle[i].x - rover.x + 100
	end

	-- remove rover body
	rover:removeSelf()
	rover = nil

	-- remove rover wheels
	for i = 1, #wheelSprite do
		wheelSprite[i]:removeSelf()
		wheelSprite[i] = nil
	end

	-- remove map tracking dot
	map.rover:removeSelf()
	map.rover = nil

	-- create new rover
	newRover( act.yMax - 111 )

	-- reset speed display
	rover.speedOldX = rover.x
	speedText.text = string.format( speedText.format, 0, "kph" )
end

-- Create the speed display text
local function newDisplay()
	local format = "%4d %s"
	local options = 
	{
		parent = staticGrp,
		text = string.format( format, 0, "kph" ),
		x = act.xMax - 10,
		y = 20,
		font = native.systemFontBold,
		fontSize = 18,
	}

	speedText = display.newText( options )
	speedText:setFillColor( 0.0, 1.0, 0.0 )
	speedText.anchorX = 1
	speedText.anchorY = 0
	speedText.x = act.xMax - 10
	speedText.y = act.yMin + 10
	speedText.format = format
end

-- Update the speed display
local function updateDisplay()
	local kmPerCoronaUnit = 0.00006838462 -- based on estimated rover length
	local elapsedTimePerHr = 7200 -- every 0.5 seconds
	rover.kph = ( rover.x - rover.speedOldX ) * kmPerCoronaUnit * elapsedTimePerHr

	if rover.kph < 0 then 
		rover.kph = 0 
	end

	speedText.text = string.format( speedText.format, rover.kph, "kph" )
	rover.speedOldX = rover.x
end

-- Init the act
function act:init()
		-- include Corona's "physics" library
	local physics = require "physics"

	-- load widget module
	local widget = require( "widget" )

	-- start physics, set gravity 
	physics.start()
	physics.setGravity( 0, 3.3 )
	physics.setContinuous( true )
	--physics.setDrawMode( "hybrid" )

	math.randomseed( os.time() )

	-- create display groups for dynamic objects & static foreground objects
	staticGrp = act:newGroup()
	dynamicGrp = act:newGroup()

	-- initialize rover map starting coordinates to map center
	game.saveState.roverCoord.x1 = act.xCenter
	game.saveState.roverCoord.y1 = act.yMin + act.height/6

	-- set sky background
	local skyData = { 
		parent = dynamicGrp, 
		x = act.xMin, 
		y = act.yMin, 
		width = act.width, 
		height = act.height 
	} 

	sky = act:newImage( "sky2.jpg", skyData )
	sky.x = act.xCenter
	sky.y = act.yCenter

	-- add touch event listener to background image
	sky:addEventListener( "touch", bgTouched )
	timer.performWithDelay( 500, updateDisplay, 0 )

	-- create map
	local mapData = { 
		parent = staticGrp, 
		x = act.xCenter, 
		y = act.yMin, 
		height = act.height/3
	} 

	map = act:newImage( "valles_marineris1.jpg", mapData )
	map.anchorY = 0
	map.x = act.xCenter
	map.y = act.yMin
	map.left = act.xCenter - map.width/2
	map.right = map.left + map.width
	map.top = act.yMin
	map.bottom = map.top + map.height
	map.course = nil
	map.courseArrow = nil
	map.courseLength = 0
	map.courseVX = 0
	map.courseVY = 0

	-- add touch event listener to background image
	map:addEventListener( "touch", mapTouched )

	-- create the stop button
	local stopButton = widget.newButton
	{
		x = act.xMax - 30,
		y = act.yMax - 60,
		width = 40,
		height = 40,
		defaultFile = "media/rover/stop_unpressed.png",
		overFile = "media/rover/stop_pressed.png",
		onPress = onStopPress,
		onRelease = onStopRelease
	}

	-- create the reset button
	local resetButton = widget.newButton
	{
		x = act.xMax - 30,
		y = act.yMax - 20,
		width = 30,
		height = 30,
		defaultFile = "media/rover/reset_unpressed.png",
		overFile = "media/rover/reset_pressed.png",
		onPress = onResetPress
	}

	-- create the terrain and the rover
	newTerrain( 20 )
	newRover( act.yMax - 112 )
	newDisplay()
	staticGrp:insert( stopButton )
	staticGrp:insert( resetButton )
end

-- Handle enterFrame events
function act:enterFrame( event )
	-- adjust and apply rover wheel angular velocity
	moveRover() 

	-- move dynamicGrp along the x-axis the distance the rover has moved
	dynamicGrp.x = act.xMin + 100 - rover.x

	-- recycle and generate the terrain
	moveTerrain()
	
	-- move the background along the x-axis the distance the rover has moved
	sky.x = act.xCenter + rover.x - 100

	-- move the static group to the foreground
	sky:toBack()
	staticGrp:toFront()
end

------------------------- End of Activity --------------------------------


-- Corona needs the scene object returned from the act file
return act.scene
