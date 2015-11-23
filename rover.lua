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
local controlPanelGrp	-- display group for the control panel
local mapGrp 			-- display group for the map
local dynamicGrp 		-- display group for dynamic objects
local terrain = {} 		-- basic terrain
local obstacle = {} 	-- terrain obstacles
local shape = {} 		-- possible terrain obstacles
local wheelSprite = {} 	-- rover wheels
local rover 			-- the rover
local map 				-- the map
local bg 				-- background
local resetButton
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

	sky = act:newImage( "sky2.jpg", skyData )
	sky.x = act.xCenter
	sky.y = act.yCenter
end

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

	--for 1, #craters do
	--	rD = math.sqrt((rX - cX)*(rX - cX) + (rY - cY)*(rY - cY))
	--end

	-- fill terrain with rectangles to span display width plus terrainExcess
	for i = 1, act.width + terrainExcess do
		terrain[i] = newRectangle( i - 1 + terrainOffset, elevation )
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
	rover.speedOldX = rover.x -- previous x for speed calculation
	rover.kph = 0 
	rover.accelerate = false
	rover.brake = false
	rover.active = false

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
			map.courseVX = (x2 - x1)/map.courseLength
			map.courseVY = (y2 - y1)/map.courseLength

			while game.xyInRect( x2, y2, mapGrp ) do
				x2 = x2 + map.courseVX
				y2 = y2 + map.courseVY
			end

			x2 = x2 - 2 * map.courseVX
			y2 = y2 - 2 * map.courseVY
		else
			map.courseVX = 0
			map.courseVY = 0
		end

		-- set global variables to new destination coordinates
		game.saveState.rover.x2 = x2 + mapGrp.x
		game.saveState.rover.y2 = y2 + mapGrp.y

		-- calculate new course length
		map.courseLength = math.sqrt((x2 - x1)*(x2 - x1) + (y2 - y1)*(y2 - y1))

		-- replace old course with new course
		drawCourse( x1, y1, x2, y2 )

		-- record the current x-axis position of the side scrolling rover
		rover.distOldX = rover.x

		-- Make rover active to allow for position updating
		rover.active = true
	end

	return true
end

-- Zoom and pan the map according to the value of map.scale and tracking dot (map.rover) position 
local function mapZoom( event )

	-- Convert the tracking dot position into zoom point coordinates 
	local roverX = ((game.saveState.rover.x1 - mapGrp.x) - map.x/map.xScale) * map.scale  
	local roverY = ((game.saveState.rover.y1 - mapGrp.y) - map.y/map.yScale) * map.scale  

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
	transition.to( map, zoomData )

	-- Transition the tracking dot to roverX, roverY
	-- On completion, update game.saveState and re-enable zoom button
	local dotMoveData = {
		x = roverX,
		y = roverY,
		time = 1000,
		onComplete = function() event.target:setEnabled( true );
								game.saveState.rover.x1 = map.rover.x/map.xScale + mapGrp.x; 
								game.saveState.rover.y1 = map.rover.y/map.yScale + mapGrp.y;
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

-- Create new rover map location tracking dot
local function newMapDot()
	local dotData = { 
		parent = mapGrp, 
		x = 0,
		y = 0,
		width = 6, 
		height = 6
	} 

	map.rover = act:newImage( "tracking_dot1.png", dotData )
	map.rover.x = (game.saveState.rover.x1 - mapGrp.x) * map.xScale
	map.rover.y = (game.saveState.rover.y1 - mapGrp.y) * map.yScale
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

	-- create map
	local mapData = { 
		parent = mapGrp, 
		x = 0, 
		y = 0, 
		width = mapLength,
		height = mapLength
	} 

	-- create map image
	map = act:newImage( "valles_marineris1.jpg", mapData )
	map.course = nil
	map.courseArrow = nil
	map.courseLength = 0
	map.courseVX = 0
	map.courseVY = 0
	map.scale = 1

	mapGrp.left = -map.width/2
	mapGrp.right = map.width/2
	mapGrp.top = -map.width/2
	mapGrp.bottom = map.width/2

	-- add touch event listener to background image
	map:addEventListener( "touch", mapTouched )

	-- add tracking dot to the map
	newMapDot()
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

	displayPanel = act:newImage( "panel8.png", dispPanelData )

	-- Create map
	newMap()

	-- Create zoom-in button
	zoomInButton = widget.newButton
	{
	    id = "zoomInButton",
	    left = act.xMin + map.width + 10, 
	    top = mapGrp.y - 20, 
	    width = 20, 
	    height = 20,
	    label = "+",
	    font = native.systemFontBold,
	    onRelease = onZoomInRelease
	}

	-- Create zoom-out button
	zoomOutButton = widget.newButton
	{
	    id = "zoomOutButton",
	    left = act.xMin + map.width + 10, 
	    top = mapGrp.y, 
	    width = 20, 
	    height = 20,
	    label = "-",
	    font = native.systemFontBold,
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
		rover.angularV = rover.angularV * rover.kph/500
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

	-- Calculate distance rover has moved
	local distMoved = ( rover.x - rover.distOldX )/100
	rover.distOldX = rover.x

	-- Update the unscaled rover coordinates
	game.saveState.rover.x1 = map.rover.x/map.xScale + mapGrp.x + distMoved * map.courseVX; 
	game.saveState.rover.y1 = map.rover.y/map.yScale + mapGrp.y + distMoved * map.courseVY;

	-- Update the scaled rover coordinates
	map.rover.x = (game.saveState.rover.x1 - mapGrp.x) * map.xScale
	map.rover.y = (game.saveState.rover.y1 - mapGrp.y) * map.yScale

	local x1 = map.rover.x
	local y1 = map.rover.y
	local x2 = game.saveState.rover.x2 - mapGrp.x
	local y2 = game.saveState.rover.y2 - mapGrp.y

	-- Calculate new course length
	map.courseLength = map.courseLength - distMoved

	-- If the rover has not reached the edge of the map
	if game.xyInRect( x1, y1, mapGrp ) and map.courseLength > 0 then	

		-- Replace old course with new course
		drawCourse( map.rover.x, map.rover.y, x2, y2 )

	else -- If map edge has been reached

		-- deactivate rover to brake side-scroller and discontinue tracking dot position updating
		rover.active = false
		map.courseLength = 0

		-- ensure the tracking dot is within map bounds
		if math.abs(map.rover.x) > map.width/2 then
			map.rover.x = math.abs(map.rover.x) / map.rover.x * map.width/2 * 0.99
		end

		if math.abs(map.rover.y) > map.width/2 then
			map.rover.y = math.abs(map.rover.y) / map.rover.y * map.width/2 * 0.99
		end
		
		-- Update saveState coordinates
		game.saveState.rover.x1 = map.rover.x / map.xScale + mapGrp.x
		game.saveState.rover.y1 = map.rover.y / map.yScale + mapGrp.y
		game.saveState.rover.x2 = map.rover.x + mapGrp.x
		game.saveState.rover.y2 = map.rover.y + mapGrp.y

		-- Remove map course objects
		display.remove( map.course )
		display.remove( map.courseArrow )
	end	
end

-- Adjust and apply rover wheel angular velocity
local function moveRover()

	if rover.active then

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
		updatePosition()
	else 
		brakeRover()
	end

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
		resetButton.isVisible = true
	end
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

-- Acceleration touch event handler
local function onAccelPress( event )
	rover.accelerate = true
end

-- Acceleration touch event handler
local function onAccelRelease( event )
	rover.accelerate = false
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

	-- create new rover
	newRover( act.yMax - 111 )

	-- reset speed display
	rover.speedOldX = rover.x
	speedText.text = string.format( speedText.format, 0, "kph" )

	resetButton.isVisible = false
end

local function newControlPanel()

	-- set panel backgroud image
	local ctrlPanelData = { 
		parent = controlPanelGrp, 
		x = act.xCenter, 
		y = act.yMax + act.height/12, 
		width = act.width, 
		height = act.height/3 + 10,
	} 

	displayPanel = act:newImage( "panel8.png", ctrlPanelData )

	-- create the accelerator
	local accelButton = widget.newButton
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
	local stopButton = widget.newButton
	{
		x = act.xCenter - 35,
		y = act.yMax - 24,
		width = 40,
		height = 40,
		defaultFile = "media/rover/stop_unpressed.png",
		overFile = "media/rover/stop_pressed.png",
		onPress = onStopPress,
		onRelease = onStopRelease
	}

	-- create the reset button
	resetButton = widget.newButton
	{
		x = act.xCenter,
		y = act.yMax - 35,
		width = 30,
		height = 30,
		defaultFile = "media/rover/reset_unpressed.png",
		overFile = "media/rover/reset_pressed.png",
		onPress = onResetPress
	}

	resetButton.isVisible = false

	controlPanelGrp:insert( accelButton )
	controlPanelGrp:insert( stopButton )
	controlPanelGrp:insert( resetButton )
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
	controlPanelGrp = act:newGroup( staticFgGrp )
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
end

------------------------- End of Activity --------------------------------


-- Corona needs the scene object returned from the act file
return act.scene
