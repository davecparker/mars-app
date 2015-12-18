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

-- Create new background
function new.background()
	-- set sky background
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

-- Create new terrain component rectangle 
-- Accepts x-coord & height, returns rectangle display object
function new.rectangle( x, y, w, h, isCrater )
	local rect = display.newRect( data.dynamicGrp, x, y, w, h )
	rect:setFillColor( unpack(data.terrainColor) )
	rect.anchorX = 0
	rect.anchorY = 0
	physics.addBody( rect, "static", { friction = 1.0 } )
	rect.isCrater = isCrater

	local function onCollision( self, event )
		if event.phase == "began" and event.other.isRemover then
			self:removeSelf()
			self = nil
		end
	end

	rect.collision = onCollision
	rect:addEventListener( "collision" )

	return rect
end

-- Create new circle terrain component
-- Accepts circle x, y coordinates, returns circle display object
function new.circle( x, y, r )
	local yDev = math.random( r * 0.7, r * 0.9 ) -- randomly vary y coord w/radius
	local circle = display.newCircle( data.dynamicGrp, x, y + yDev, r )
	physics.addBody( circle, "static", { friction = 1.0, radius = r } )

	local function onCollision( self, event )
		if event.phase == "began" and event.other.isRemover then
			self:removeSelf()
			self = nil
		end
		-- newObstacle( data.rover.x + data.act.width, data.rover.x + 2 * data.act.width )
	end

	circle.collision = onCollision
	circle:addEventListener( "collision" )

	return circle
end

-- Create new square of random side length
-- Accepts square x, y coordinates, returns square display object
function new.square( x, y, s )
	local square = display.newRect( data.dynamicGrp, x, y + s/3, s, s )
	square.rotation = math.random( 30, 60 ) -- random rotation for variation
	physics.addBody( square, "static", { friction = 1.0 } )

	local function onCollision( self, event )
		if event.phase == "began" and event.other.isRemover then
			self:removeSelf()
			self = nil
		end
		-- newObstacle( data.rover.x + data.act.width, data.rover.x + 2 * data.act.width )
	end

	square.collision = onCollision
	square:addEventListener( "collision" )

	return square
end

-- Create new rounded square of random side length
-- Accepts square x, y coordinates, returns rounded square display object
function new.roundSquare( x, y, s )
	local square = display.newRoundedRect( data.dynamicGrp, x, y + s/3, s, s, s/4 )
	square.rotation = math.random( 30, 60 )
	physics.addBody( square, "static", { friction = 1.0 } )

	local function onCollision( self, event )
		if event.phase == "began" and event.other.isRemover then
			self:removeSelf()
			self = nil
		end
		-- newObstacle( data.rover.x + data.act.width, data.rover.x + 2 * data.act.width )
	end

	square.collision = onCollision
	square:addEventListener( "collision" )

	return square
end

-- Create new trapezoid polygon of random length
-- Accepts x, y coordinates of bottom-left vertice, returns trapezoid display object
function new.poly( x, y, s )
	local l = math.random( 3, 10 )
	local vertices = { x, y, x + s, y - s, x + s + l, y - s, x + 2 * s + l, y }
	local rotation = math.random( -20, 20 )
	local poly = display.newPolygon( data.dynamicGrp, x, y + 1.5, vertices )
	poly.rotation = rotation
	physics.addBody( poly, "static", { friction = 1.0 } )

	local function onCollision( self, event )
		if event.phase == "began" and event.other.isRemover then
			self:removeSelf()
			self = nil
		end
		-- newObstacle( data.rover.x + data.act.width, data.rover.x + 2 * data.act.width )
	end

	poly.collision = onCollision
	poly:addEventListener( "collision" )

	return poly
end

-- Create a new terrain element based upon passed table of parameters
function new.terrainElement( params )
	local rect = display.newRect( params.group, params.x, params.y, params.w, params.h )
	rect:setFillColor( unpack(data.terrainColor) )
	rect.objTable = params.objTable -- table to store rect
	rect.index = #rect.objTable + 1 -- table index of next available element
	rect.x = params.x
	rect.y = params.y
	rect.anchorX = params.anchorX
	rect.anchorY = params.anchorY
	rect.isCrater = isCrater
	rect.objTable[rect.index] = rect -- save into table
		
	return rect
end

-- Create terrain of rectangles
function new.rectTerrain( width, height )

	params = {
		group = data.dynamicGrp,
		objTable = data.terrain,
		x = data.nextX,
		y = data.act.yMax - height,
		w = width,		
		h = height,
		anchorX = 0,
		anchorY = 0,
		isCrater = false
	}

	local rect = new.terrainElement( params )
	physics.addBody( rect, "static", { friction = 1.0 } )

	local function onCollision( self, event )
		if event.phase == "began" and event.other.isRemover then
			self:removeSelf()
			self = nil
		end
	end

	rect.collision = onCollision
	rect:addEventListener( "collision" )

	data.nextX = data.nextX + width
end

-- Create randomly selected, sized, & rotated polygons
function new.obstacle( xMin, xMax, y )
	-- fill data.shape table with terrain obstacle shape functions
	data.shape = { new.circle, new.square, new.roundSquare, new.poly }
	
	local terrainExtent = data.act.width + data.terrainExcess - data.terrainOffset

	-- fill obstacle table with shapes randomly distributed along terrain x-axis extent
	local x = math.random( xMin, xMax )
	local y = y or data.act.yMax - data.defaultElevation
	local size = math.random( 5, 10 )
	local obstacle = data.shape[math.random(1, 4)]( x, y, size )
	obstacle:setFillColor( unpack(data.obstacleColor)  )
	obstacle:toBack()
end

-- Create the rover
function new.rover( roverX, roverY )

	-- tables to hold suspension joints
	local suspension = {}
	local wheelToWheelJoint = {}
	-- local wheelToBodyJoint = {}

	-- create rover
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
	data.rover.atHome = true
	data.rover.isAutoNav = false

	-- rover body physics: low density for minimal sway & increased stability
	physics.addBody( data.rover, "dynamic", { density = 0.2, friction = 0.3, bounce = 0.2 } )

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
	data.map.rover.leftShip = false
	data.map.rover.lastShipDistance = 0
end

return new
