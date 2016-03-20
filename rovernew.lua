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

-- Load rover utility functions
local util = require( "roverutil" )

local bodySeparator = require( "bodySeparator" )

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
	data.removalSensor = display.newRect( data.dynamicGrp, data.nextX, data.act.yCenter, 20, data.act.height )
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
function new.square( x, y, s, m )
	local square = display.newRect( data.dynamicGrp, x, y + s/3, s, s )
	square.rotation = math.random( 30, 60 ) + m
	square.isObstacle = true
	physics.addBody( square, "static", { friction = 1.0 } )
	square.collision = onCollision
	square:addEventListener( "collision" )
	return square
end

-- Accepts x, y coordinates and side length; returns rounded square terrain physics object
function new.roundSquare( x, y, s, m )
	local square = display.newRoundedRect( data.dynamicGrp, x, y + s/3, s, s, s/4 )
	square.rotation = math.random( 30, 60 ) + m
	square.isObstacle = true
	physics.addBody( square, "static", { friction = 1.0 } )
	square.collision = onCollision
	square:addEventListener( "collision" )
	return square
end

-- Accepts x, y coordinates of bottom-left vertice, returns trapezoid terrain physics object
function new.polygon( x, y, s, m )
	local l = math.random( 3, 10 )
	local vertices = { x, y, x + s, y - s, x + s + l, y - s, x + 2 * s + l, y }
	local polygon = display.newPolygon( data.dynamicGrp, x, y + 1.5, vertices )
	polygon.rotation = math.random( -20, 20 ) + m
	polygon.isObstacle = true
	physics.addBody( polygon, "static", { friction = 1.0 } )
	polygon.collision = onCollision
	polygon:addEventListener( "collision" )
	return polygon
end

-- Accepts table of parameters: group, objTable, x, y, width, height, anchorX, anchorY, isObstacle, isCrater
-- Returns a rectangular terrain display object
function new.basicTerrainObj( params )
	local rect = display.newRect( params.group, params.x, params.y, params.width, params.height )
	rect:setFillColor( unpack(data.terrainColor) )
	rect.objTable = params.objTable -- table to store rect
	rect.index = #rect.objTable + 1 -- table index of next available element
	rect.x = params.x
	rect.y = params.y
	rect.isObstacle = params.isObstacle
	rect.isCrater = params.isCrater
	rect.objTable[rect.index] = rect -- save into table
	return rect
end

-- Create a new rectangle terrain physics object
function new.basicTerrain( w, h, isObstacle, isCrater )

	params = {
		group = data.dynamicGrp,
		objTable = data.terrain,
		x = data.nextX + w/2,
		y = data.act.yMax - h/2,
		width = w,		
		height = h,
		isObstacle = isObstacle,
		isCrater = isCrater
	}

	local rect = new.basicTerrainObj( params )
	physics.addBody( rect, "static", { friction = 1.0 } )
	rect.collision = onCollision
	rect:addEventListener( "collision" )
	data.nextX = data.nextX + w
end

-- Accepts table of parameters: group, objTable, x, y, width, height, anchorX, anchorY, isObstacle, isCrater
-- Returns a polygon terrain display object
function new.craterTerrainObj( params )
	local polygon = display.newPolygon( params.group, params.x, params.y, params.vertices, params.isObstacle, params.isCrater )
	polygon:setFillColor( unpack(data.terrainColor) )
	polygon.objTable = params.objTable -- table to store the object
	polygon.index = #polygon.objTable + 1 -- table index of next available element
	polygon.x = params.x
	polygon.y = params.y
	polygon.isObstacle = params.isObstacle
	polygon.isCrater = params.isCrater
	polygon.objTable[polygon.index] = polygon -- save into table
	return polygon
end

-- Create a new crater terrain physics object
function new.craterTerrain( isObstacle, isCrater )
	if data.courseHeightIndex == #data.courseHeightMap then
		new.basicTerrain( 1, data.courseHeightMap[data.courseHeightIndex], false, true )
	else
		local vertices = {}
		local minY = data.act.yMax

		for i = 1, 2 do
			vertices[#vertices + 1] = data.nextX
			vertices[#vertices + 1] = data.act.yMax - data.courseHeightMap[data.courseHeightIndex]

			if vertices[#vertices] < minY then
				minY = vertices[#vertices]
			end

			if data.courseHeightIndex == #data.courseHeightMap then
				util.resetCraterData()
				data.nextX = data.nextX - data.craterResolution
				break
			else
				data.nextX = data.nextX + (2-i) * data.craterResolution
				data.courseHeightIndex = data.courseHeightIndex + (2-i) * data.craterResolution
				if data.courseHeightIndex > #data.courseHeightMap then
					data.courseHeightIndex = #data.courseHeightMap
				end
			end
		end

		vertices[#vertices + 1] = vertices[#vertices - 1]
		vertices[#vertices + 1] = data.act.yMax
		vertices[#vertices + 1] = vertices[1]
		vertices[#vertices + 1] = data.act.yMax

		local minX = vertices[1]
		local maxX = vertices[#vertices - 1]
		local maxY = data.act.yMax

		params = {
			group = data.dynamicGrp,
			objTable = data.terrain,
			x = minX + (maxX - minX) / 2,
			y = minY + (maxY - minY) / 2,
			vertices = vertices,
			isObstacle = isObstacle,
			isCrater = isCrater
		}

		local polygon = new.craterTerrainObj( params )
		bodySeparator.addNonConvexBody( polygon, { shape = vertices, bodyType = "static", bounce = 0.2, friction = 1, density = 1 } )
		polygon.collision = onCollision
		polygon:addEventListener( "collision" )
	end
	print(data.rover.x)
end

-- Accepts an optional x-coordinate in lieu of a randomly-generated x-coordinate
-- Returns a randomly selected, sized, rotated obstacle physics object at coincident terrain height
function new.obstacle( newX )
	local maxX = data.rover.x + data.act.width
	local minX = maxX - data.roverPosition
	local x = newX or math.random( minX, maxX )
	local y = util.findTerrainHeight( x )
	local size = math.random( 5, 10 )
	local m = util.findTerrainSlope( x )
	
	-- THIS IS A HACK TO ALIGN OBSTACLE HEIGHT WITH CRATER SLOPES. 
	-- NEED TO UPDATE util.findTerrainHeight AND util.findTerrainSlope TO WORK PROPERLY WITH THE CRATER POLYGONS.
	if m < -1 then
		y = y - m/2 + size/5
	elseif m > 1 then
		y = y + m/2 + size/4
	end

	local obstacle = data.shape[math.random(1, 4)]( x, y, size, m )
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
	data.rover.atShip = true
	data.rover.isAutoNav = false
	data.nextX = data.rover.x - data.act.width + data.basicTerrainObjWidth / 2

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
