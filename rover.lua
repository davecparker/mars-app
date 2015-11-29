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

-- load the Corona widget module
local widget = require "widget" 

-- File local variables
local staticBgGrp 		-- display group for static background objects
local staticFgGrp 		-- display group for static foreground objects
local displayPanelGrp 	-- display group for the display panel
local ctrlPanelGrp		-- display group for the control panel
local mapGrp 			-- display group for map elements
local mapZoomGrp		-- display group for the maps elements subject to zooming
local dynamicGrp 		-- display group for dynamic objects (rover & terrain elements)
local terrain = {} 		-- basic terrain
local obstacle = {} 	-- terrain obstacles
local shape = {} 		-- possible terrain obstacles
local wheelSprite = {} 	-- rover wheels
local rover 			-- the rover
local map 				-- the map
local bg 				-- background
local recoverButton
local zoomInButton
local zoomOutButton
local speedText
local elevation = 100 -- terrain elevation
local terrainExcess = 100 -- off display terrain amount
local terrainOffset = -80 -- terrain offset
local terrainColor = { 0.8, 0.35, 0.25 }
local obstacleColor = { 0.3, 0.1, 0.1 }

-- Create new background
local function newBackground()
	-- set sky background
	local skyData = { 
		parent = staticBgGrp, 
		x = act.xMin, 
		y = act.yMin, 
		width = act.width, 
		height = act.height 
	} 

	sky = act:newImage( "sky.jpg", skyData )
	sky.x = act.xCenter
	sky.y = act.yCenter
end

-- Create new 1-corona unit wide terrain component rectangle 
-- Accepts x-coord & height, returns rectangle display object
local function newRectangle( x, h )
	local rect = display.newRect( dynamicGrp, x, act.yMax, act.width + terrainExcess - terrainOffset, h )
	rect:setFillColor( unpack(terrainColor) )
	rect.anchorX = 0
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

-- Create new crater
local function newCrater( cX, cY, cR )
	rX = game.saveState.rover.x1
	rY = game.saveState.rover.y1
	rD = math.sqrt((rX - cX)*(rX - cX) + (rY - cY)*(rY - cY))
end

-- Create terrain of rectangles and randomly selected, sized, & rotated polygons
local function newTerrain( nObstacles)
	-- fill shape table with terrain obstacle shape functions
	shape = { randCircle, randSquare, randRoundSquare, randPoly }
	
	local terrainExtent = act.width + terrainExcess - terrainOffset

	-- fill obstacle table with shapes randomly distributed along terrain x-axis extent
	-- obsolete: local zoneLength = math.floor( (act.width + terrainExcess)/nObstacles )
	for i = 1, nObstacles do
		-- obsolete: local x = math.random( (i - 1) * zoneLength, i * zoneLength ) + terrainOffset
		local x = math.random( (i - 1) + terrainOffset, terrainExtent )
		local y = act.yMax - elevation
		local size = math.random( 5, 10 )
		obstacle[i] = shape[math.random(1, 4)]( x, y, size )
		obstacle[i]:setFillColor( unpack(obstacleColor)  )
	end

	--for 1, #craters do
	--	rD = math.sqrt((rX - cX)*(rX - cX) + (rY - cY)*(rY - cY))
	--end

	-- fill terrain with rectangles to span display width plus terrainExcess
	for i = 1, 2 do
		terrain[i] = newRectangle( act.xMin + terrainOffset + (i - 1) * terrainExtent, elevation )
	end
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
	rover.speedOldX = rover.x -- previous x for speed (kph) calculation
	rover.kph = 0 
	rover.accelerate = false
	rover.brake = false
	rover.isActive = true

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

		-- load sound effects
		rover.engineSound = act:loadSound( "rover_engine.wav" )
		rover.startSound = act:loadSound( "rover_start.wav" )
		rover.stage1Sound = act:loadSound( "rover_stage_1.wav" )
		rover.stage2Sound = act:loadSound( "rover_stage_2.wav" )
		rover.stopSound = act:loadSound( "rover_stop.wav" )	
	end

	-- wheel-to-wheel distance joints to limit lateral wheel translation 
	for i = 1, 2 do
		wheelToWheelJoint[i] = physics.newJoint( "distance", wheelSprite[i], wheelSprite[i+1],
		wheelSprite[i].x, wheelSprite[i].y, wheelSprite[i+1].x, wheelSprite[i+1].y )
	end
end

-- Create new rover map location tracking dot
local function newMapDot()
	local dotData = { 
		parent = mapGrp, 
		x = 0,
		y = 0,
		width = 6, 
		height = 6
	} 

	map.rover = act:newImage( "tracking_dot.png", dotData )
	map.rover.x = (game.saveState.rover.x1 - mapGrp.x) * mapZoomGrp.xScale
	map.rover.y = (game.saveState.rover.y1 - mapGrp.y) * mapZoomGrp.yScale
	map.rover.leftShip = false
	map.rover.lastShipDistance = 0
end

-- Draw a new rover course on map
local function drawCourse( x1, y1, x2, y2 )

	-- remove old course, draw new course
	display.remove( map.course )
	display.remove( map.courseArrow )
	map.course = display.newLine( mapGrp, x1, y1, x2, y2 )
	map.course:setStrokeColor( 1, 1, 1 )
	map.course.strokeWidth = 1.5

	-- create course arrow and rotate according to course direction
	local arrowData = { 
		parent = mapGrp, 
		x = x2 + 2 * map.courseVX, 
		y = y2 + 2 * map.courseVY, 
		height = 7
	} 
	
	map.courseArrow = act:newImage( "arrow.png", arrowData )
	map.courseArrow.anchorY = 0
	map.courseArrow.rotation = math.deg(math.atan2(y2 - y1, x2 - x1)) + 90
	map.rover:toFront()	
end

-- Calculate course coordinates
local function calcCourseCoords( x2, y2 )
	map.courseVX = (x2 - map.rover.x)/map.courseLength
	map.courseVY = (y2 - map.rover.y)/map.courseLength

	while game.xyInRect( x2, y2, mapGrp ) do
		x2 = x2 + map.courseVX
		y2 = y2 + map.courseVY
	end

	game.saveState.rover.x2 = x2 - 2 * map.courseVX + mapGrp.x
	game.saveState.rover.y2 = y2 - 2 * map.courseVY + mapGrp.y
end

-- Map touch event handler
local function mapTouched( event )
	if event.phase == "began" then

		local x1 = map.rover.x
		local y1 = map.rover.y
		local x2 = event.x - mapGrp.x
		local y2 = event.y - mapGrp.y

		map.courseLength = math.sqrt((x2 - x1)*(x2 - x1) + (y2 - y1)*(y2 - y1))

		-- if course exists, calculate unit vectors & find map zoomBoundary intersection point
		if map.courseLength > 0 then
			calcCourseCoords( x2, y2 )
		else
			map.courseVX = 0
			map.courseVY = 0
		end

		-- set global variables to new destination coordinates
		x2 = game.saveState.rover.x2 - mapGrp.x
		y2 = game.saveState.rover.y2 - mapGrp.y

		-- calculate new course length
		map.courseLength = math.sqrt((x2 - x1)*(x2 - x1) + (y2 - y1)*(y2 - y1))

		-- replace old course with new course
		drawCourse( x1, y1, x2, y2 )

		-- record the current x-axis position of the side scrolling rover
		rover.distOldX = rover.x

		-- Make rover active to allow for position updating and to enable the accelerator
		rover.isActive = true
	end

	return true
end

-- Zoom and pan the map according to the value of map.scale and tracking dot (map.rover) position 
local function mapZoom( event )

	-- Convert the tracking dot position into zoom point coordinates 
	local roverX = ((game.saveState.rover.x1 - mapGrp.x) - mapZoomGrp.x/mapZoomGrp.xScale) * map.scale  
	local roverY = ((game.saveState.rover.y1 - mapGrp.y) - mapZoomGrp.y/mapZoomGrp.yScale) * map.scale  

	-- Calculate the boundary coordinates beyond which the map will pan beyond its container
	local zoomBoundary = (map.width * map.scale - map.width)/2

	-- Apply the boundary coordinates to determine the actual zoom point coordinates
	local zoomX = -game.pinValue( roverX, -zoomBoundary, zoomBoundary )
	local zoomY = -game.pinValue( roverY, -zoomBoundary, zoomBoundary )

	-- Calculate the coordinates to which to transition the tracking dot given the selected zoom point
	roverX = roverX + zoomX
	roverY = roverY + zoomY

	-- Zoom the map to zoomX, zoomY
	local zoomData = {
		x = zoomX,
		y = zoomY,
		xScale = map.scale,
		yScale = map.scale,
		time = 1000,
	}
	transition.to( mapZoomGrp, zoomData )

	-- Transition the tracking dot to roverX, roverY
	-- On completion, update game.saveState and re-enable zoom button
	local dotMoveData = {
		x = roverX,
		y = roverY,
		time = 1000,
		onComplete = function() event.target:setEnabled( true );
								game.saveState.rover.x1 = map.rover.x/mapZoomGrp.xScale + mapGrp.x; 
								game.saveState.rover.y1 = map.rover.y/mapZoomGrp.yScale + mapGrp.y;
						end 
	}
	transition.moveTo( map.rover, dotMoveData )
end

-- Zoom-in button handler
local function onZoomInRelease( event )
	if map.scale < 3 then
		map.scale = map.scale * 1.5
		zoomInButton:setEnabled( false )
		mapZoom( event )
	end
end

-- Zoom-out button handler
local function onZoomOutRelease( event )
	if map.scale > 1 then
		map.scale = map.scale / 1.5
		zoomOutButton:setEnabled( false )
		mapZoom( event )
	end
end

-- Create new map
local function newMap()

	-- temporary variables for map dimensions and position
	local mapLength = act.height/3
	local mapX = act.xMin + act.height/6 + 5
	local mapY = act.yMin + act.height/6 + 5 

	-- create map background
	mapBgRect = {}
	for i = 1, 5 do
		mapBgRect[i] = display.newRect( displayPanelGrp, mapX, mapY, mapLength + 6 - i, mapLength + 6 - i )
		mapBgRect[i]:setFillColor( 0.5 - i/10, 0.5 - i/10, 0.5 - i/10 )
	end

	-- create map display container
	mapGrp = display.newContainer( displayPanelGrp, mapLength, mapLength )
	mapGrp:translate( mapX, mapY )

	-- initialize rover map starting coordinates to map center
	game.saveState.rover.x1 = mapGrp.x
	game.saveState.rover.y1 = mapGrp.y

	mapZoomGrp = act:newGroup( mapGrp )

	-- create map
	local mapData = { 
		parent = mapZoomGrp, 
		x = 0, 
		y = 0, 
		width = mapLength,
		height = mapLength
	} 

	-- Create map image
	map = act:newImage( "valles_marineris.png", mapData )
	map.course = nil
	map.courseArrow = nil
	map.courseVX = 0
	map.courseVY = 0
	map.scale = 1

	mapGrp.left = -map.width/2
	mapGrp.right = map.width/2
	mapGrp.top = -map.width/2
	mapGrp.bottom = map.width/2

	-- Add touch event listener to background image
	map:addEventListener( "touch", mapTouched )

	-- Create spaceship
	local spaceshipData = { 
		parent = mapZoomGrp, 
		x = 0, 
		y = 0, 
		width = 5, 
		height = 5 
	} 
	
	spaceship = act:newImage( "spaceship.png", spaceshipData )	

	-- Add tracking dot to the map
	newMapDot()
	
	local x1 = (game.saveState.rover.x1 - mapGrp.x) * mapZoomGrp.xScale
	local y1 = (game.saveState.rover.y1 - mapGrp.y) * mapZoomGrp.yScale
	local x2 = math.random(-map.width/2, map.width/2)
	local y2 = math.random(-map.width/2, map.width/2)
	game.saveState.rover.x2 = x2 
	game.saveState.rover.y2 = y2

	-- Calculate new course length
	map.courseLength = math.sqrt((x2 - x1)*(x2 - x1) + (y2 - y1)*(y2 - y1))

	-- if course exists, calculate unit vectors & find map zoomBoundary intersection point
	if map.courseLength > 0 then
		calcCourseCoords( x2, y2 )
	else
		map.courseVX = 0
		map.courseVY = 0
	end

	-- set global variables to new destination coordinates
	x2 = game.saveState.rover.x2 - mapGrp.x
	y2 = game.saveState.rover.y2 - mapGrp.y

	-- Calculate new course length
	map.courseLength = math.sqrt((x2 - x1)*(x2 - x1) + (y2 - y1)*(y2 - y1))

	-- Draw the initial course
	drawCourse( x1, y1, x2, y2 )

	-- Record the current x-axis position of the side scrolling rover
	rover.distOldX = rover.x
end

-- Create the speed display text
local function newDisplayPanel()

	-- Create display panel background image
	local dispPanelData = { 
		parent = displayPanelGrp, 
		x = act.xCenter, 
		y = act.yMin + act.height/6 + 5, 
		width = act.width, 
		height = act.height/3 + 10 ,
	} 

	displayPanel = act:newImage( "panel.png", dispPanelData )

	-- Create map
	newMap()

	-- Create zoom-in button
	zoomInButton = widget.newButton
	{
	    id = "zoomInButton",
	    left = act.xMin + map.width + 10, 
	    top = mapGrp.y - 20, 
	    width = 40, 
	    height = 40,
	    defaultFile = "media/rover/zoom_in_unpressed.png",
		overFile = "media/rover/zoom_in_pressed.png",
	    onRelease = onZoomInRelease
	}

	-- Create zoom-out button
	zoomOutButton = widget.newButton
	{
	    id = "zoomOutButton",
	    left = act.xMin + map.width + 10, 
	    top = mapGrp.y + 20, 
	    width = 40, 
	    height = 40,
	    defaultFile = "media/rover/zoom_out_unpressed.png",
		overFile = "media/rover/zoom_out_pressed.png",
	    onRelease = onZoomOutRelease
	}

	-- Create background border for the speed display
	speedBgRect = {}
	for i = 1, 5 do
		speedBgRect[i] = display.newRect( displayPanelGrp, act.xCenter, act.yCenter, 86 - i, 26 - i )
		speedBgRect[i].x = act.xMin + map.width + 53
		speedBgRect[i].y = act.yMin + map.width - 5
		speedBgRect[i]:setFillColor( 0.5 - i/10, 0.5 - i/10, 0.5 - i/10 )
	end

	speedBgRect[6] = display.newRect( displayPanelGrp, act.xCenter, act.yCenter, 80, 20 )
	speedBgRect[6].x = act.xMin + map.width + 53
	speedBgRect[6].y = act.yMin + map.width - 5
	speedBgRect[6]:setFillColor( 0.25, 0.25, 0.25 )

	-- Create speed display text object
	local format = "%4d %s"
	local options = 
	{
		parent = displayPanelGrp,
		text = string.format( format, 0, "kph" ),
		x = act.xMax - 10,
		y = 20,
		font = native.systemFontBold,
		fontSize = 18,
	}

	speedText = display.newText( options )
	speedText:setFillColor( 0.0, 1.0, 0.0 )
	speedText.anchorX = 1
	speedText.anchorY = 1
	speedText.x = speedBgRect[6].x + 37
	speedText.y = speedBgRect[6].y + 10
	speedText.format = format

	staticFgGrp:insert( zoomInButton )
	staticFgGrp:insert( zoomOutButton )
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
		rover.angularV = rover.angularV * rover.kph/400
	end
end

-- Let the rover coast, with increased deceleration during high AOA (wheelie) instances
local function coastRover()
	-- if high angle-of-attack, then greater deceleration for stability
	if (rover.rotation % 360 > 260 and rover.rotation % 360 < 300) then
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

local function updatePosition()

	-- Calculate distance rover has moved in the scrolling view
	local distMoved = ( rover.x - rover.distOldX )/400
	rover.distOldX = rover.x

	-- Update the unscaled rover coordinates
	game.saveState.rover.x1 = map.rover.x/mapZoomGrp.xScale + mapGrp.x + distMoved * map.courseVX; 
	game.saveState.rover.y1 = map.rover.y/mapZoomGrp.yScale + mapGrp.y + distMoved * map.courseVY;

	-- Update the scaled rover coordinates
	map.rover.x = (game.saveState.rover.x1 - mapGrp.x) * mapZoomGrp.xScale
	map.rover.y = (game.saveState.rover.y1 - mapGrp.y) * mapZoomGrp.yScale

	local x1 = map.rover.x 
	local y1 = map.rover.y 
	local x2 = mapZoomGrp.x/map.xScale
	local y2 = mapZoomGrp.y/map.yScale

	-- Calculate the rover's distance from the ship
	local distanceFromShip = math.sqrt((x1*x1) + (y1*y1)) + math.sqrt((x2*x2) + (y2*y2)) 

	x2 = game.saveState.rover.x2 - mapGrp.x
	y2 = game.saveState.rover.y2 - mapGrp.y

	-- If the rover has returned to the ship, then go to mainAct
	if distanceFromShip <= 6 and map.rover.leftShip then
		map.rover.leftShip = false
		audio.stop()
		game.gotoAct ( "mainAct" )
	elseif not map.rover.leftShip and distanceFromShip > 6 then
		map.rover.leftShip = true
	end

	-- Calculate new course length
	map.courseLength = map.courseLength - distMoved

	-- If the rover has not reached the edge of the map
	if game.xyInRect( x1, y1, mapGrp ) and map.courseLength > 0 then	

		-- Replace old course with new course
		drawCourse( map.rover.x, map.rover.y, x2, y2 )

	else -- If map edge has been reached

		-- Deactivate rover to brake side-scroller and discontinue tracking dot position updating
		rover.isActive = false

		-- Cease acceleration and initiate braking
		rover.accelerate = false
		rover.brake = true

		-- Play the rover stop sound followed by engine sound, first halting any other sounds
		if audio.isChannelPlaying( 4 ) then
		audio.stop( 4 )
		end
		
		if audio.isChannelPlaying( 3 ) then
			audio.stop( 3 )
		end

		if audio.isChannelPlaying( 2 ) then
			audio.stop( 2 )
		end

		if not audio.isChannelPlaying( 5 ) 
			and not audio.isChannelPlaying( 1 ) then

			local options2 = {
				channel = 1,
				loops = -1,
			}

			local options1 = {
				channel = 5,
				loops = 0,
				-- Play engine sound indefinitely upon completion
				onComplete = function() if not rover.accelerate then 
											rover.engineChannel = game.playSound(rover.engineSound, options2); 
										end
									end
			}

			rover.stopChannel = game.playSound(rover.stopSound, options1)
		end

		map.courseLength = 0

		-- ensure the tracking dot is within map bounds
		if math.abs(map.rover.x) > map.width/2 then
			map.rover.x = math.abs(map.rover.x) / map.rover.x * map.width/2 * 0.99
		end

		if math.abs(map.rover.y) > map.width/2 then
			map.rover.y = math.abs(map.rover.y) / map.rover.y * map.width/2 * 0.99
		end
		
		-- Update saveState coordinates
		game.saveState.rover.x1 = map.rover.x / mapZoomGrp.xScale + mapGrp.x
		game.saveState.rover.y1 = map.rover.y / mapZoomGrp.yScale + mapGrp.y
		game.saveState.rover.x2 = map.rover.x + mapGrp.x
		game.saveState.rover.y2 = map.rover.y + mapGrp.y

		-- Remove map course objects
		display.remove( map.course )
		display.remove( map.courseArrow )
	end	
end

-- Adjust and apply rover wheel angular velocity
local function moveRover()

	if not audio.isChannelPlaying( 1 ) 
		and not audio.isChannelPlaying( 2 )
		and not audio.isChannelPlaying( 3 )
		and not audio.isChannelPlaying( 4 )
		and not audio.isChannelPlaying( 5 )
	then
		rover.engineChannel = game.playSound(rover.engineSound, { channel = 1, loops = -1 } )
	end

	-- Accelerate, brake, or coast rover
	if rover.accelerate then
		accelRover()
	elseif rover.brake then
		brakeRover()
	else
		coastRover()
	end

	-- Apply wheel angular velocity & sprite frame to the wheel sprites
	-- Rear wheel at half speed for stability
	wheelSprite[1].angularVelocity = rover.angularV/2

	for i = 2, 3 do
		wheelSprite[i].angularVelocity = rover.angularV
	end

	-- Update map position
	if rover.isActive then updatePosition() end

	-- Determine wheel sprite frame
	local wheelFrame

	if rover.angularV > 700 then 
		wheelFrame = 7
	elseif rover.angularV < 200 then 
		wheelFrame = 1
	else
		wheelFrame = math.floor( rover.angularV/100 )
	end

	-- Set wheel sprite frame
	for i = 1, 3 do
		wheelSprite[i]:setFrame( wheelFrame )
	end

	-- If rover is upturned, then reveal the reset button
	if (rover.rotation % 360 > 90 and rover.rotation % 360 < 270) and rover.kph == 0 then

		function displayRecoverButton()
			if (rover.rotation % 360 > 80 and rover.rotation % 360 < 280) and rover.kph == 0 then
				recoverButton.isVisible = true
				ctrlPanelGrp.accelButton.isVisible = false
				rover.accelerate = false
			end
		end

		timer.performWithDelay( 2000, displayRecoverButton() )
	end
end

-- Scroll the terrain to the left
local function moveTerrain()
	local terrainExtent = act.width + terrainExcess - terrainOffset

	-- recycle terrain rectangle if sufficiently offscreen
    for i = 1, #terrain do
		if terrain[i].contentBounds.xMax < act.xMin + terrainOffset then
			terrain[i].x = terrain[i].x + 2 * terrainExtent
		end
	end

	-- remove obstacle if sufficiently offscreen x left
	-- create new random obstacle of random size at random offscreen x right
	for i = 1, #obstacle do
		if obstacle[i].contentBounds.xMax < act.xMin + terrainOffset then
			local x = math.random( 
				obstacle[i].x + terrainExtent, obstacle[i].x + 2 * terrainExtent )
			local size = math.random( 5, 10 )
			display.remove( obstacle[i] )
			obstacle[i] = shape[math.random(1, 4)]( x, act.yMax - elevation, size )
			obstacle[i]:setFillColor( unpack(obstacleColor)  )
			obstacle[i]:toBack()
			physics.addBody( obstacle[i], "static", { friction = 1.0 } )
		end
	end
end

-- Acceleration touch event handler
local function onAccelPress( event )

	if rover.isActive then
		rover.accelerate = true

		-- Halt engine or stop sounds and play start sound, then stage1 sound, then stage2 sound
		if audio.isChannelPlaying( 1 ) then
			audio.stop( 1 )
		elseif audio.isChannelPlaying( 5 ) then
			audio.stop( 5 )
		end

		local options3 = {
			channel = 4,
			loops = -1,
		}

		local options2 = {
			channel = 3,
			loops = 0,
			-- Play stage2 sound indefinitely upon completion
			onComplete = function() if rover.accelerate then 
										rover.stage2Channel = game.playSound(rover.stage2Sound, options3); 
									end
								end
		}

		local options1 = {
			channel = 2,
			loops = 0,
			-- Play stage1 sound upon completion
			onComplete = function() if rover.accelerate then 
										rover.stage1Channel = game.playSound(rover.stage1Sound, options2); 
									end
								end
		}
		rover.startChannel = game.playSound(rover.startSound, options1)
	end
end

-- Acceleration touch event handler
local function onAccelRelease( event )

	if rover.isActive then

		rover.accelerate = false

		-- Play the rover stop sound followed by rover engine sound, first halting any other sounds
		if audio.isChannelPlaying( 4 ) then
			audio.stop( 4 )
		end
		
		if audio.isChannelPlaying( 3 ) then
			audio.stop( 3 )
		end

		if audio.isChannelPlaying( 2 ) then
			audio.stop( 2 )
		end

		if not audio.isChannelPlaying( 5 ) 
			and not audio.isChannelPlaying( 1 ) then

			local options2 = {
				channel = 1,
				loops = -1,
			}

			local options1 = {
				channel = 5,
				loops = 0,
				-- Play the rover engine sound indefinitely upon completion
				onComplete = function() if not rover.accelerate then 
											rover.engineChannel = game.playSound(rover.engineSound, options2); 
										end
									end
			}

			rover.stopChannel = game.playSound(rover.stopSound, options1)
		end
	end
end

-- Brake button event handler
local function onBrakePress( event )
	rover.brake = true
end

-- Brake button event handler
local function onBrakeRelease( event )
	if rover.isActive then
		rover.brake = false
	end
end

-- Water scan button event handler
local function onWaterRelease( event )
	-- Cease acceleration and initiate braking
	rover.accelerate = false
	rover.brake = true

	-- leave the game and go to drillScan; allow time for rover to decelerate and sound to complete
	local function goToDrillScan( event )
		audio.stop()
		game.gotoAct ( "drillScan", { effect = "zoomInOutFade", time = 1000 } )
	end

	if rover.kph < 20 then
		timer.performWithDelay( 3500, goToDrillScan )	
	else
		timer.performWithDelay( 5000, goToDrillScan )	
	end
end

-- Reset button event handler
local function onRecoverPress( event )
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

	-- create new rover
	newRover( act.yMax - 111 )

	-- reset speed display
	rover.speedOldX = rover.x
	speedText.text = string.format( speedText.format, 0, "kph" )

	-- display accelerator, hide recover button
	ctrlPanelGrp.accelButton.isVisible = true
	recoverButton.isVisible = false
end

local function newControlPanel()

	-- set panel backgroud image
	local ctrlPanelData = { 
		parent = ctrlPanelGrp, 
		x = act.xCenter, 
		y = act.yMax + act.height/12, 
		width = act.width, 
		height = act.height/3 + 10,
	} 

	displayPanel = act:newImage( "panel.png", ctrlPanelData )

	-- create the accelerator
	ctrlPanelGrp.accelButton = widget.newButton
	{
		x = act.xCenter + 35,
		y = act.yMax - 24,
		width = 40,
		height = 40,
		defaultFile = "media/rover/accel_unpressed.png",
		overFile = "media/rover/accel_pressed.png",
		onPress = onAccelPress,
		onRelease = onAccelRelease
	}

	-- create the stop button
	local brakeButton = widget.newButton
	{
		x = act.xCenter - 35,
		y = act.yMax - 24,
		width = 40,
		height = 40,
		defaultFile = "media/rover/brake_unpressed.png",
		overFile = "media/rover/brake_pressed.png",
		onPress = onBrakePress,
		onRelease = onBrakeRelease
	}

	-- create the water scan button
	local waterButton = widget.newButton
	{
		x = act.xMax - 28,
		y = act.yMax - 24,
		width = 40,
		height = 40,
		defaultFile = "media/rover/water_unpressed.png",
		overFile = "media/rover/water_pressed.png",
		onRelease = onWaterRelease
	}

	-- create the reset button
	recoverButton = widget.newButton
	{
		x = act.xCenter + 35,
		y = act.yMax - 23.5,
		width = 48,
		height = 48,
		defaultFile = "media/rover/reset_unpressed.png",
		overFile = "media/rover/reset_pressed.png",
		onPress = onRecoverPress
	}
	recoverButton.isVisible = false

	ctrlPanelGrp:insert( ctrlPanelGrp.accelButton )
	ctrlPanelGrp:insert( brakeButton )
	ctrlPanelGrp:insert( waterButton )
	ctrlPanelGrp:insert( recoverButton )
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

local function testPrint()
	print( string.format("%s %.2f %s %.2f %s %.2f %s %.2f %s %.2f %s %s %s %s",
						"mapZoomGrp.x: ", mapZoomGrp.x,
						"map.rover.x: ", map.rover.x,
						"mapZoomGrp.y: ", mapZoomGrp.y,
						"map.rover.y: ", map.rover.y,
						"map.courseLength: ", map.courseLength,
						"rover.isActive: ", tostring(rover.isActive),
						"rover.leftShip: ", tostring(map.rover.leftShip)
						))
end 

-- Init the act
function act:init()
	-- include Corona's physics and widget libraries
	local physics = require "physics"
	
	-- start physics, set gravity 
	physics.start()
	physics.setGravity( 0, 3.3 )
	physics.setContinuous( true )
	--physics.setDrawMode( "hybrid" )

	-- seed math.random()
	math.randomseed( os.time() )

	-- create display groups
	staticBgGrp = act:newGroup()
	staticFgGrp = act:newGroup()
	dynamicGrp = act:newGroup()	
	ctrlPanelGrp = act:newGroup( staticFgGrp )
	displayPanelGrp = act:newGroup( staticFgGrp )

	-- create background
	newBackground()

	-- create the terrain and the rover
	newTerrain( 20 )
	newRover( act.yMax - 112 )

	-- create rover display panel and control panel
	newDisplayPanel()
	newControlPanel()

	timer.performWithDelay( 500, updateDisplay, 0 )
end

-- Handle enterFrame events
function act:enterFrame( event )

	-- adjust and apply rover wheel angular velocity
	moveRover() 

	-- move dynamicGrp along the x-axis the distance the rover has moved
	dynamicGrp.x = act.xMin + 100 - rover.x

	-- recycle and generate the terrain
	moveTerrain()

	-- move the static group to the foreground
	staticBgGrp:toBack()
	staticFgGrp:toFront()

	testPrint()
end

------------------------- End of Activity --------------------------------


-- Corona needs the scene object returned from the act file
return act.scene
