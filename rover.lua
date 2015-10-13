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
-- include Corona's "physics" library
local physics = require "physics"

-- start physics, set gravity 
physics.start()
physics.setGravity( 0, 3.3 )
physics.setContinuous( true )

-- File local variables
local terrain = {} -- basic terrain
local obstacles = {} -- terrain obstacles
local shapes = {} -- possible terrain obstacles
local wheel = {} -- rover wheels
local bg
local rover
local angularV = 0
local baseHeight = 100
local terrainColor = { 1.0, 0.2, 0.2 }

-- create new 1-corona unit wide terrain component rectangle 
-- accepts x-coord & height, returns rectangle display object
local function newRectangle( x, h )
	local rect = display.newRect( act.group, x, act.yMax, 1, h )
	rect:setFillColor( unpack(terrainColor) )
	rect.anchorY = 1
	physics.addBody( rect, "static", { friction = 1.0 } )
	return rect
end

-- create new circle terrain component
-- accepts circle x, y coordinates, returns circle display object
local function randCircle( x, y )
	local radius = math.random( 3, 10 ) -- random radius
	local yDev = math.random( radius/2, radius*0.6 ) -- randomly vary y coord w/radius
	local circle = display.newCircle( act.group, x, y + 0.5*radius, radius )
	circle:setFillColor( unpack(terrainColor)  )
	physics.addBody( circle, "static", { friction = 1.0 } )
	return circle
end

-- create new square of random side length
-- accepts square x, y coordinates, returns square display object
local function randSquare( x, y )
	local side = math.random( 5, 10 )
	local square = display.newRect( act.group, x, y + 1, side, side )
	square.rotation = math.random( 30, 60 ) -- random rotation for variation
	square:setFillColor( unpack(terrainColor)  )
	physics.addBody( square, "static", { friction = 1.0 } )
	return square
end

-- create new rounded square of random side length
-- accepts square x, y coordinates, returns rounded square display object
local function randRoundSquare( x, y )
	local side = math.random( 5, 10 )
	local square = display.newRoundedRect( act.group, x, y + 1, side, side, side/4 )
	square.rotation = math.random( 30, 60 )
	square:setFillColor( unpack(terrainColor)  )
	physics.addBody( square, "static", { friction = 1.0 } )
	return square
end

-- create new trapezoid polygon of random length
-- accepts x, y coordinates of bottom-left vertice, returns trapezoid display object
local function randPoly( x, y )
	local s = math.random( 4, 10 )
	local vertices = { x, y, x + s, y - s, x + 2 * s, y - s, x + 3 * s, y }
	local poly = display.newPolygon( act.group, 0, 0, vertices )
	poly.x = x
	poly.y = y - 1
	poly:setFillColor( unpack(terrainColor)  )
	physics.addBody( poly, "static", { friction = 1.0 } )
	return poly
end

-- function to create terrain of rectangles and randomly selected polygons
function NewTerrain( excess, offset, nObstacles)

	-- fill terrain with rectangles to span display width plus excess
	for i = act.xMin, act.xMax + excess do
		terrain[i] = newRectangle( i + offset, baseHeight )
	end

	-- fill shapes table with terrain shape functions
	shapes = { randCircle, randSquare, randRoundSquare, randPoly }
	
	-- divide terrain into x-axis zones for even obstacle distribution
	-- fill obstacles table with one randomly selected shape per zone
	local zoneLength = math.floor( (act.width + excess)/nObstacles )	
	for i = 1, nObstacles do
		local x = math.random( (i - 1) * zoneLength, i * zoneLength ) + offset
		obstacles[i] = shapes[math.random(1, 4)]( x, act.yMax - baseHeight )
	end
end

-- function to create the rover
function NewRover()

	local suspension = {}
	local wheelToWheelJoint = {}
	local wheelToBodyJoint = {}

	rover = act:newImage( "rover_body.png", 
		{ x = act.xMin + 100, y = act.yMax - 112, width = 65, height = 50 } )
	rover.anchorY = 1.0

	-- rover body physics: low density for minimal sway & increased stability
	physics.addBody( rover, "dynamic", { density = 0.2, friction = 0.3, 
		bounce = 0.2, isSensor = false } )

	-- create 4 wheels
	for i = 1, 4 do
		wheel[i] = act:newImage( "tonka_wheel.png", 
			{ x = rover.x - 27 + (i - 1) * 18 , y = rover.y + 5, width = 15, height = 15 } )

		-- wheel physics: lower density decreases translation in violent events but also
		-- decreases stability & increases acceleration response. 0.5-1.5 seems to give the
		-- best results. Increased friction also increases acceleration response. 
		physics.addBody( wheel[i], "dynamic", { density = 1.0, friction = 0.5, 
			bounce = 0.2, isSensor = false, radius = 7.5 } )

		-- xAxis & yAxis values influence wheel translation; 25-50 y-axis gives best results
		suspension[i] = physics.newJoint( "wheel", rover, wheel[i], 
			wheel[i].x, wheel[i].y, 1, 30 )
	end

	-- wheel-to-wheel distance joints to moderate wheel translation 
	for i = 1, 3 do
		wheelToWheelJoint[i] = physics.newJoint( 'distance', wheel[i], wheel[i+1],
			wheel[i].x, wheel[i].y, wheel[i+1].x, wheel[i+1].y )
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
end

-- function to adjust wheel angular velocity
function MoveRover()
	if angularV < 800 then -- increase initial acceleration
		angularV = angularV + 500 
	elseif angularV > 8000 then -- limit angular velocity (i.e. top speed)
		angularV = 8000
	else
		angularV = angularV + 20 -- typical acceleration
	end
end

-- function to scroll the ground to the left
function MoveTerrain( excess, offset )

    -- recycle terrain rectangle if sufficiently offscreen
    for i = act.xMin, #terrain do
		if terrain[i].contentBounds.xMax < act.xMin + offset then
			terrain[i].x = terrain[i].x + act.width + excess
		end
	end

	-- remove obstacle if sufficiently offscreen x left
	-- create new obstacle at random offscreen x right
	for i = 1, #obstacles do
		if obstacles[i].contentBounds.xMax < act.xMin + offset then
			local zoneLength = math.floor( (act.width + excess)/#obstacles )	
			local x = math.random( 
				obstacles[i].x + act.width - offset + 1, 
				obstacles[i].x + act.width - offset + zoneLength + 1 )
			display.remove( obstacles[i] )
			obstacles[i] = shapes[math.random(1, 4)]( x, act.yMax - baseHeight )
		end
	end
end

-- Handle touch events
local function touched( event )
	if event.phase == "began" then
		MoveRover()
	elseif event.phase == "ended" or event.phase == "cancelled" then
		angularV = 0
	end
end

-- Init the act
function act:init()
	--physics.setDrawMode( "hybrid" )
	math.randomseed( os.time() )

	bg = display.newRect( act.group, act.xMin, act.yMin, act.width, act.height )
	bg.x = act.xCenter
	bg.y = act.yCenter
	bg:setFillColor( 0.5, 0.5, 0.5 )

	-- add touch event listener to background image
	bg:addEventListener( "touch", touched )

	-- create the terrain and the rover
	NewTerrain( 100, -50, 5 )
	NewRover()
end

-- Handle enterFrame events
function act:enterFrame( event )

	-- move the display group along the x-axis the distance the rover has moved
	act.group.x = act.xMin + 100 - rover.x

	-- recycle and regenerate the terrain
	MoveTerrain( 100, -50 )
	
	-- move the background (not sure why it's not moving with act.group)
	bg.x = act.xCenter + rover.x - 100

	-- rotate the rover's wheels
	for i = 1, 4 do
		wheel[i].angularVelocity = angularV * 10
	end
end

------------------------- End of Activity --------------------------------


-- Corona needs the scene object returned from the act file
return act.scene
