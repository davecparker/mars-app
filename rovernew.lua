-----------------------------------------------------------------------------------------
--
-- rovernew.lua
--
-- Contains functions that create new display objects for the rover activity of the Mars App
--
-----------------------------------------------------------------------------------------

-- Get local reference to the game globals
local game = globalGame

-- Load rover data table
local data = require( "roverdata" )

local new = {}

local onCollision

-- Create new sky background
function new.background()
	local skyData = { 
		parent = data.staticBgGrp, 
		x = data.act.xMin, 
		y = data.act.yMin, 
		width = data.act.width, 
		height = data.act.height 
	} 
	local sky = data.act:newImage( "sky.jpg", skyData )
	sky.x = data.act.xCenter
	sky.y = data.act.yCenter
end

-- Create sensor body for display object removal
function new.RemovalSensor()
	local width = 20
	local x = data.minTerrainX - width/2
	data.removalSensor = display.newRect( data.dynamicGrp, x, data.act.yCenter, width, data.act.height )
	data.removalSensor.anchorX = 1
	data.removalSensor.isRemover = true
	physics.addBody( data.removalSensor, "dynamic", { isSensor = true } )
	data.removalSensor.gravityScale = 0
end

-- Accepts x, y coordinates and radius; returns circle terrain physics object
function new.circle( x, y, r )
	local yDev = math.random( r * 0.7, r * 0.9 ) -- randomly vary y coord w/radius
	local circle = display.newCircle( data.dynamicGrp, x, y + yDev, r )
	circle.isObstacle = true
	physics.addBody( circle, "static", { friction = 1.0, radius = r } )
	circle.collision = onCollision
	circle:addEventListener( "collision" )
	return circle
end

-- Accepts x, y coordinates and side length; returns square terrain physics object
function new.square( x, y, s )
	local square = display.newRect( data.dynamicGrp, x, y + s/3, s, s )
	square.rotation = math.random( 30, 60 ) -- random rotation for variation
	square.isObstacle = true
	physics.addBody( square, "static", { friction = 1.0 } )
	square.collision = onCollision
	square:addEventListener( "collision" )
	return square
end

-- Accepts x, y coordinates and side length; returns rounded square terrain physics object
function new.roundSquare( x, y, s )
	local square = display.newRoundedRect( data.dynamicGrp, x, y + s/3, s, s, s/4 )
	square.rotation = math.random( 30, 60 )
	square.isObstacle = true
	physics.addBody( square, "static", { friction = 1.0 } )
	square.collision = onCollision
	square:addEventListener( "collision" )
	return square
end

-- Accepts x, y coordinates of bottom-left vertice, returns trapezoid terrain physics object
function new.poly( x, y, s )
	local l = math.random( 3, 10 )
	local vertices = { x, y, x + s, y - s, x + s + l, y - s, x + 2 * s + l, y }
	local poly = display.newPolygon( data.dynamicGrp, x, y + 1.5, vertices )
	poly.rotation = math.random( -20, 20 )
	poly.isObstacle = true
	physics.addBody( poly, "static", { friction = 1.0 } )
	poly.collision = onCollision
	poly:addEventListener( "collision" )
	return poly
end

-- Accepts table of parameters: group, objTable, x, y, width, height, anchorX, anchorY, isObstacle, isCrater
-- Returns a rectangular terrain display object
function new.rectTerrainElement( params )
	local rect = display.newRect( params.group, params.x, params.y, params.width, params.height )
	rect:setFillColor( unpack(data.terrainColor) )
	rect.objTable = params.objTable -- table to store rect
	rect.index = #rect.objTable + 1 -- table index of next available element
	rect.x = params.x
	rect.y = params.y
	rect.anchorX = params.anchorX
	rect.anchorY = params.anchorY
	rect.isObstacle = params.isObstacle
	rect.isCrater = params.isCrater
	rect.objTable[rect.index] = rect -- save into table
	return rect
end

-- Create a new rectangle terrain physics object
function new.rectTerrain( w, h, isCrater )

	params = {
		group = data.dynamicGrp,
		objTable = data.terrain,
		x = data.nextX,
		y = data.act.yMax - h,
		width = w,		
		height = h,
		anchorX = 0,
		anchorY = 0,
		isObstacle = false,
		isCrater = isCrater
	}

	local rect = new.rectTerrainElement( params )
	physics.addBody( rect, "static", { friction = 1.0 } )
	rect.collision = onCollision
	rect:addEventListener( "collision" )
	data.nextX = data.nextX + w
end

-- Accepts an optional x-coordinate in lieu of a randomly-generated x-coordinate
-- Returns a randomly selected, sized, rotated obstacle physics object at coincident terrain height
function new.obstacle( newX )
	local minX = data.rover.x + data.act.width - data.roverPosition
	local maxX = data.rover.x + data.act.width
	local x = newX or math.random( minX, maxX )
	local y = data.terrain[#data.terrain].y

	-- Find the y-coordinate of the basic terrain object that contains this object's x-coordinate
	local i = #data.terrain
	while data.terrain[i].x > x do
		i = i - 1
		y = data.terrain[i].y
	end 

	local size = math.random( 5, 10 )
	local obstacle = data.shape[math.random(1, 4)]( x, y, size )
	obstacle:setFillColor( unpack(data.obstacleColor)  )
	obstacle:toBack()
end

-- Remove display object with delay upon collision with the removal object
function onCollision( self, event )
	if event.phase == "began" and event.other.isRemover then
		if self.isObstacle then
			timer.performWithDelay( 50, function() new.obstacle(); end )
		end
		self:removeSelf()
		self = nil
	end
end

-- Create the rover
function new.rover( roverX, roverY )

	-- Tables to hold suspension joints
	local suspension = {}
	local wheelToWheelJoint = {}

	-- Create rover
	local roverData = { 
		parent = data.dynamicGrp, 
		x = roverX, 
		y = roverY, 
		width = 65, 
		height = 50 
	} 
	
	data.rover = data.act:newImage( "rover_body.png", roverData )
	data.rover.anchorY = 1.0
	data.rover.angularV = 0
	data.rover.distOldX = data.rover.x -- previous x for distance traveled calculation
	data.rover.speedOldX = data.rover.x -- previous x for speed (kph) calculation
	data.rover.kph = 0 
	data.rover.accelerate = false
	data.rover.brake = false
	data.rover.isActive = true
	data.rover.inCrater = false
	data.rover.atShip = true
	data.rover.isAutoNav = false
	data.nextObstacle = data.rover.x + data.act.width
	data.minTerrainX = data.rover.x - data.act.width
	data.maxTerrainX = data.rover.x + data.act.width

	-- Rover body physics: low density for minimal sway & increased stability
	physics.addBody( data.rover, "dynamic", { density = 0.2, friction = 0.3, bounce = 0.2 } )

	-- Create an image sheet for rover wheel sprites
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
		data.wheelSprite[i] = display.newSprite( data.dynamicGrp, wheelSheet, sequenceData )
		data.wheelSprite[i].x = data.rover.x - 27 + (i - 1) * 27
		data.wheelSprite[i].y = data.rover.y + 4
		data.wheelSprite[i]:scale( 0.12, 0.12 )

		-- wheel physics
		-- higher density increases translation & stability; 0.5-1.5 gives best results.
		-- higher friction increases acceleration and decreases stability.
		local wheelPhysicsData = {
			density = 1.0, 
			friction = 1.0, 
			bounce = 0.2, 
			radius = 9.25
		}

		physics.addBody( data.wheelSprite[i], "dynamic", wheelPhysicsData )

		-- x-axis & y-axis values affect wheel translation in combination with wheel-to-wheel joints
		-- per x-axis, a higher y-axis value decreases translation; 25-50 y-axis gives best results
		suspension[i] = physics.newJoint( "wheel", data.rover, data.wheelSprite[i], 
		data.wheelSprite[i].x, data.wheelSprite[i].y, 1, 30 )

		-- load sound effects
		data.rover.engineSound = data.act:loadSound( "rover_engine.wav" )
		data.rover.startSound = data.act:loadSound( "rover_start.wav" )
		data.rover.stage1Sound = data.act:loadSound( "rover_stage_1.wav" )
		data.rover.stage2Sound = data.act:loadSound( "rover_stage_2.wav" )
		data.rover.stopSound = data.act:loadSound( "rover_stop.wav" )	
	end

	-- wheel-to-wheel distance joints to limit lateral wheel translation 
	for i = 1, 2 do
		wheelToWheelJoint[i] = physics.newJoint( "distance", data.wheelSprite[i], data.wheelSprite[i+1],
		data.wheelSprite[i].x, data.wheelSprite[i].y, data.wheelSprite[i+1].x, data.wheelSprite[i+1].y )
	end
end

-- Create new rover map location tracking dot
function new.mapDot()
	local dotData = { 
		parent = data.mapGrp, 
		x = 0,
		y = 0,
		width = 6, 
		height = 6
	} 

	data.map.rover = data.act:newImage( "tracking_dot.png", dotData )
	data.map.rover.x = game.saveState.rover.x1
	data.map.rover.y = game.saveState.rover.y1
	data.map.rover.lastShipDistance = 0
end

return new
