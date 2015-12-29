-----------------------------------------------------------------------------------------
--
-- rover.lua
--
-- The rover activity of the Mars App
--
-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------
--
-- Variables in the act table you can use:
--    act.group    -- display group for the act (parent of all display objects)
--    act.scene    -- composer scene associated with the act
--
--    * If you define act:start() it will be called when the activity starts/resumes.
--    * If you define act:stop() it will be called when the activity suspends/ends.
--    * If you define act:destroy() it will be called when the activity is destroyed.
--    * If you define act:enterFrame() it will be called before every animation frame.
-----------------------------------------------------------------------------------------
-- Load the Corona widget module
local widget = require "widget" 

-- Get local reference to the game globals
local game = globalGame

-- Create the act object
local act = game.newAct()

-- Load rover data table
local data = require( "roverdata" )

-- Assign reference in roverdata.lua to act object
data.act = act

-- Load rover utility functions
local util = require( "roverutil" )

-- Load rover new display object functions
local new = require( "rovernew" )

------------------------- Start of Activity --------------------------------

-- Create crater height map; fill data.craterHeightMap table
local function newCraterHeightMap( xScale )
	local yScale = 150
	local r = game.saveState.craters[data.craterIndex].r * xScale
	data.floorY = data.defaultElevation - r/100
	local rimY = data.defaultElevation + r/100
	local inSlope = (rimY - data.floorY) / (0.6 * r - 0.3 * r) / yScale
	local outSlope = (data.defaultElevation - rimY) / (0.4 * r) / yScale

	-- Set floor values
	for d = #data.craterHeightMap + 1, 0.3 * r do
		data.craterHeightMap[d] = data.floorY
	end

	-- Set inside slope values
	for d = #data.craterHeightMap + 1, 0.6 * r do
		data.craterHeightMap[d] = (data.craterHeightMap[d - 1] + inSlope * d)
	end

	-- Set inside peak values
	local nPoints = 0.05 * r
	local slopeStep = inSlope/nPoints
	local firstPoint = #data.craterHeightMap + 1
	for d = #data.craterHeightMap + 1, 0.65 * r do
		data.craterHeightMap[d] = (data.craterHeightMap[d - 1] + (inSlope - (d - firstPoint) * slopeStep) * d)
	end

	-- Set outside peak values
	firstPoint = #data.craterHeightMap
	for d = #data.craterHeightMap + 1, 0.7 * r do
		data.craterHeightMap[d] = (data.craterHeightMap[firstPoint + (firstPoint + 1 - d)])
	end

	-- Set outside slope values
	for d = #data.craterHeightMap + 1, r do
		data.craterHeightMap[d] = (data.craterHeightMap[d - 1] + outSlope * d)
	end

	local offset = data.defaultElevation - data.craterHeightMap[#data.craterHeightMap] 
	for i = 1, #data.craterHeightMap do
		data.craterHeightMap[i] = data.craterHeightMap[i] + offset
	end
end

-- Fill data.courseHeightMap[] with the height values for each crater intercept point for the current course
local function newCourseHeightMap( xScale )
	local craterX = game.saveState.craters[data.craterIndex].x
	local craterY = game.saveState.craters[data.craterIndex].y
	local craterDistance = util.calcDistance( data.map.rover.x, data.map.rover.y, craterX, craterY ) * xScale
	local nextX = data.map.rover.x
	local nextY = data.map.rover.y
	local i = 1
	-- Get height values for each point along course by indexing the height map with distance from crater center 
	while craterDistance <= game.saveState.craters[data.craterIndex].r * xScale do
		data.courseHeightMap[i] = data.craterHeightMap[math.ceil(craterDistance)] -- Round to ceiling to avoid indexing by zero
		nextX = nextX + nextX/math.abs(nextX)*1/xScale -- Use absolute value to get coordinate sign
		-- Calculate next y-coordinate
		nextY = util.calcPtY( data.map.rover.x, data.map.rover.y, game.saveState.rover.x2, game.saveState.rover.y2, nextX )
		craterDistance = util.calcDistance( nextX, nextY, craterX, craterY ) * xScale  -- Calculate coordinate pair distance
		i = i + 1
	end
end

-- Create crater display object and add to craterTerrain[]
-- local function newCraterTerrain( objWidth )
-- 	craterCount = craterCount + 1
-- 	local x = craterStartX + craterCount * objWidth
-- 	local y = act.yMax - data.courseHeightMap[craterCount]
-- 	local w = 1 * objWidth
-- 	local h = data.courseHeightMap[craterCount]

-- 	-- If the next height is of the same height, extend display object width
-- 	if data.courseHeightMap[craterCount] == data.courseHeightMap[craterCount+1] then
		
-- 		-- Find number of consecutive elements of the same height and accumulate as object width
-- 		local i = craterCount
-- 		local rectW = 1
-- 		while data.courseHeightMap[i] == data.courseHeightMap[i+1] and i < #data.courseHeightMap do
-- 			rectW = rectW + 1
-- 			i = i + 1
-- 		end
-- 		craterCount = i
-- 		craterTerrain[#craterTerrain + 1] = new.rectangle( x, y, rectW * objWidth, h, true )
-- 	else
-- 		craterTerrain[craterCount] = new.rectangle( x, y, w, h, true )
-- 	end

-- 	if craterCount == #data.courseHeightMap then
-- 		data.drawingCrater = false
-- 	end
-- end

-- Check whether the rover has reached a crater
local function checkCraters()
	if not data.rover.inCrater then
		for i = 1, #game.saveState.craters do
			local craterX = game.saveState.craters[i].x
			local craterY = game.saveState.craters[i].y
			local craterDistance = util.calcDistance( data.map.rover.x, data.map.rover.y, craterX, craterY )
			if craterDistance <= game.saveState.craters[i].r then
				data.craterIndex = i
				newCraterHeightMap( 365 )	-- Create crater height map
				newCourseHeightMap( 365 )	-- Create course height map based on current course & craterHeightMap	
				data.rover.inCrater = true
				data.drawingCrater = true
				break
			end
		end
	end
end

-- Map touch event handler
local function mapTouched( event )

	if event.phase == "began" or event.phase == "moved" then

		local x1 = data.map.rover.x
		local y1 = data.map.rover.y
		local x2 = event.x - data.mapGrp.x
		local y2 = event.y - data.mapGrp.y

		-- Calculate course coordinates
		x2, y2 = util.calcCourseCoords( data.mapGrp, x1, y1, x2, y2 )

		-- replace old course with new course
		display.remove( data.map.course )
		display.remove( data.map.courseArrow )
		data.map.course = util.newCourse( data.mapGrp, x1, y1, x2, y2 )
		data.map.courseArrow = util.newArrow( act, data.mapGrp, x1, y1, x2, y2, data.map.courseVX, data.map.courseVY )
		data.map.rover:toFront()	

		-- Check for crater to generate new crater display objects and add them to terrain
		data.rover.inCrater = false
		data.nextX = data.rover.x - 100
		checkCraters()

		if data.rover.inCrater and data.drawingCrater then

			local x = data.rover.x
			local y = data.rover.y - 20

			-- remove rover body
			data.rover:removeSelf()
			data.rover = nil

			-- remove rover wheels
			for i = 1, #data.wheelSprite do
				data.wheelSprite[i]:removeSelf()
				data.wheelSprite[i] = nil
			end

			-- create new rover
			new.rover( x, y )

			for i = 1, #data.terrain do
				if data.terrain[i] then
					display.remove(data.terrain[i])
					data.terrain[i] = nil
				end
			end

			for i = 1, #data.courseHeightMap do
				new.rectTerrain( 2, data.courseHeightMap[i] )
				data.craterHeightIndex = i
			end

			data.craterEndX = data.nextX + 200
			data.craterHeightIndex = data.craterHeightIndex + 1
			data.drawingCrater = false
		end

		-- record the current x-axis position of the side scrolling rover
		data.rover.distOldX = data.rover.x

		-- Make rover active to allow for position updating and to enable the accelerator
		data.rover.isActive = true
	end

	return true
end

-- Pan and zoom the map according to data.map.scale and the position of the map tracking dot 
local function mapZoom( event )

	-- Convert the tracking dot position into zoom point coordinates 
	local fullZoomX = (data.map.rover.x - data.mapZoomGrp.x) / data.mapZoomGrp.xScale * data.map.scale  
	local fullZoomY = (data.map.rover.y - data.mapZoomGrp.y) / data.mapZoomGrp.yScale * data.map.scale  

	-- Calculate the coordinate value beyond which the map will leave its container's edges
	local zoomBoundary = (data.map.width * data.map.scale - data.map.width)/2

	-- Limit the zoom point coordinates to zoomBoundary
	local zoomX = -game.pinValue( fullZoomX, -zoomBoundary, zoomBoundary )
	local zoomY = -game.pinValue( fullZoomY, -zoomBoundary, zoomBoundary )

	-- Calculate tracking dot's new coordinates, which will be zero unless fullZoomX or fullZoomY exceeds zoomBoundary
	local roverX = fullZoomX + zoomX
	local roverY = fullZoomY + zoomY

	-- Zoom the map to (zoomX, zoomY)
	local zoomData = {
		x = zoomX,
		y = zoomY,
		xScale = data.map.scale,
		yScale = data.map.scale,
		time = 1000,
	}
	transition.to( data.mapZoomGrp, zoomData )

	-- Move the map tracking dot to (roverX, roverY) and re-enable zoom button on completion
	local dotMoveData = {
		x = roverX,
		y = roverY,
		time = 1000,
		onComplete = function() event.target:setEnabled( true ); end 
	}
	transition.moveTo( data.map.rover, dotMoveData )
end

-- Create new map
local function newMap()

	-- temporary variables for map dimensions and position
	local mapLength = act.height/3
	local mapX = act.xMin + act.height/6 + 5
	local mapY = act.yMin + act.height/6 + 5 

	-- create map background
	local mapBgRect = {}
	for i = 1, 5 do
		mapBgRect[i] = display.newRect( data.displayPanelGrp, mapX, mapY, mapLength + 6 - i, mapLength + 6 - i )
		mapBgRect[i]:setFillColor( 0.5 - i/10, 0.5 - i/10, 0.5 - i/10 )
	end

	-- create map display container
	data.mapGrp = display.newContainer( data.displayPanelGrp, mapLength, mapLength )
	data.mapGrp:translate( mapX, mapY )

	-- initialize rover map starting coordinates to map center
	game.saveState.rover.x1 = 0
	game.saveState.rover.y1 = 0

	data.mapZoomGrp = act:newGroup( data.mapGrp )

	-- create map
	local mapData = { 
		parent = data.mapZoomGrp, 
		x = 0, 
		y = 0, 
		width = mapLength,
		height = mapLength
	} 

	-- Create map image
	data.map = act:newImage( "valles_marineris.png", mapData )
	data.map.scale = 1

	data.mapGrp.left = -data.map.width/2
	data.mapGrp.right = data.map.width/2
	data.mapGrp.top = -data.map.width/2
	data.mapGrp.bottom = data.map.width/2

	-- Add touch event listener to background image
	data.map:addEventListener( "touch", mapTouched )

	-- Create spaceship
	local spaceshipData = { 
		parent = data.mapZoomGrp, 
		x = 0, 
		y = 0, 
		width = 5, 
		height = 5 
	} 
	
	spaceship = act:newImage( "spaceship.png", spaceshipData )	

	-- Add tracking dot to the map
	new.mapDot()
	
	local x1 = data.map.rover.x
	local y1 = data.map.rover.y
	local x2 = math.random(-data.map.width/2, data.map.width/2)
	local y2 = math.random(-data.map.width/2, data.map.width/2)

	-- Calculate course coordinates
	x2, y2 = util.calcCourseCoords( data.mapGrp, x1, y1, x2, y2 )

	-- Draw the initial course
	data.map.course = util.newCourse( data.mapGrp, x1, y1, x2, y2 )
	data.map.courseArrow = util.newArrow( act, data.mapGrp, x1, y1, x2, y2, data.map.courseVX, data.map.courseVY )
	data.map.rover:toFront()	

	-- Record the current x-axis position of the side scrolling rover
	data.rover.distOldX = data.rover.x
end

local function newGaugeElement( newX, newY, w, h, xScale )

	-- set sky background
	local energyData = { 
		parent = data.displayPanelGrp, 
		x = newX, 
		y = newY, 
		width = w * xScale, 
		height = h 
	} 

	energyGauge = act:newImage( "gauge_element.png", energyData )

-- 	-- create an image sheet for the energy gauge
-- 	local options = {
-- 		width = 63,
-- 		height = 33,
-- 		numFrames = 8,
-- 		border = 1
-- 	}

-- 	local gaugeSheet = graphics.newImageSheet( 'media/rover/gauge_sheet2.png', options )

-- 	local sequenceData = {
-- 		name = "energySequence",
-- 		start = 5,
-- 		count = 5,
-- 	}

	-- 	for i = 1, 50 do
	-- 		gaugeSprite[i] = display.newSprite( data.displayPanelGrp, gaugeSheet, sequenceData )
	-- 		gaugeSprite[i]:scale( 0.12, 0.12 )
	end

-- Zoom-in button handler
local function onZoomInRelease( event )
	if data.map.scale < 3 then
		data.map.scale = data.map.scale * 1.5
		data.zoomInButton:setEnabled( false )
		mapZoom( event )
	end
end

-- Zoom-out button handler
local function onZoomOutRelease( event )
	if data.map.scale > 1 then
		data.map.scale = data.map.scale / 1.5
		data.zoomOutButton:setEnabled( false )
		mapZoom( event )
	end
end

	-- Create the speed display text
local function newDisplayPanel()

	-- Create display panel background image
	local dispPanelData = { 
		parent = data.displayPanelGrp, 
		x = act.xCenter, 
		y = act.yMin + act.height/6 + 5, 
		width = act.width, 
		height = act.height/3 + 10 ,
	} 

	displayPanel = act:newImage( "panel.png", dispPanelData )

	-- Create map
	newMap()

	-- Create zoom-in button
	data.zoomInButton = widget.newButton
	{
	    id = "data.zoomInButton",
	    left = act.xMin + data.map.width + 10, 
	    top = data.mapGrp.y - 20, 
	    width = 40, 
	    height = 40,
	    defaultFile = "media/rover/zoom_in_unpressed.png",
		overFile = "media/rover/zoom_in_pressed.png",
	    onRelease = onZoomInRelease
	}

	-- Create zoom-out button
	data.zoomOutButton = widget.newButton
	{
	    id = "data.zoomOutButton",
	    left = act.xMin + data.map.width + 10, 
	    top = data.mapGrp.y + 20, 
	    width = 40, 
	    height = 40,
	    defaultFile = "media/rover/zoom_out_unpressed.png",
		overFile = "media/rover/zoom_out_pressed.png",
	    onRelease = onZoomOutRelease
	}

	-- Create background border for the speed display
	speedBgRect = {}
	for i = 1, 5 do
		speedBgRect[i] = display.newRect( data.displayPanelGrp, act.xCenter, act.yCenter, 86 - i, 26 - i )
		speedBgRect[i].x = act.xMin + data.map.width + 53
		speedBgRect[i].y = act.yMin + data.map.width - 5
		speedBgRect[i]:setFillColor( 0.5 - i/10, 0.5 - i/10, 0.5 - i/10 )
	end

	speedBgRect[6] = display.newRect( data.displayPanelGrp, act.xCenter, act.yCenter, 80, 20 )
	speedBgRect[6].x = act.xMin + data.map.width + 53
	speedBgRect[6].y = act.yMin + data.map.width - 5
	speedBgRect[6]:setFillColor( 0.25, 0.25, 0.25 )

	-- Create speed display text object
	local format = "%4d %s"
	local options = 
	{
		parent = data.displayPanelGrp,
		text = string.format( format, 0, "kph" ),
		x = act.xMax - 10,
		y = 20,
		font = native.systemFontBold,
		fontSize = 18,
	}

	data.speedText = display.newText( options )
	data.speedText:setFillColor( 0.0, 1.0, 0.0 )
	data.speedText.anchorX = 1
	data.speedText.anchorY = 1
	data.speedText.x = speedBgRect[6].x + 37
	data.speedText.y = speedBgRect[6].y + 10
	data.speedText.format = format

	-- Create new energy display object
	local batteryData = { 
		parent = data.displayPanelGrp, 
		x = act.xMax - 26,
		y = act.yMin + 12, 
		width = 44, 
		height = 17 
	} 

	local battery = act:newImage( "battery.png", batteryData )

	-- Create energy display text object
	local format = "%3d%s"
	local options = 
	{
		parent = data.displayPanelGrp,
		text = string.format( format, game.energy(), "%" ),
		x = act.xMax - 11,
		y = act.yMin + 5,
		font = native.systemFontBold,
		fontSize = 12,
	}

	data.energyText = display.newText( options )
	data.energyText:setFillColor( 0.0, 1.0, 0.0 )
	data.energyText.anchorX = 1
	data.energyText.anchorY = 0
	data.energyText.format = format

	data.staticFgGrp:insert( data.zoomInButton )
	data.staticFgGrp:insert( data.zoomOutButton )

	-- for i = 1, 50 do
	-- 	newGaugeElement( data.mapGrp.x + 90, data.mapGrp.y + 90, 20, 3, 1)--, i*i*0.001)
	-- end
end

-- Update the energy display
local function updateEnergyDisplay()
	data.energyText.text = string.format( data.energyText.format, game.energy() , "%")
end

-- Accelerate the rover up to angular velocity of 8000 w/higher initial acceleration
local function accelRover()
	if data.rover.angularV <= 150 then -- higher initial acceleration
		data.rover.angularV = data.rover.angularV + 50 
	--elseif data.rover.angularV > 700 and data.rover.angularV < 2000 then
	--	data.rover.angularV = data.rover.angularV + 100
	elseif data.rover.isAutoNav and data.rover.angularV + 20 > 2000 then
		data.rover.angularV = 2000
	elseif data.rover.angularV + 20 > 8000 then -- top speed
		data.rover.angularV = 8000
	else
		data.rover.angularV = data.rover.angularV + 20 -- typical acceleration
	end

	game.addEnergy( -0.001 )
	updateEnergyDisplay()
end

-- Decelerate the rover; deceleration varies inversely with speed for stability
local function brakeRover()
	if data.rover.kph < 20 then
		data.rover.angularV = 0
	else 
		data.rover.angularV = data.rover.angularV * data.rover.kph/400
	end
end

-- Let the rover coast, with increased deceleration during high AOA (wheelie) instances
local function coastRover()
	-- if high angle-of-attack, then greater deceleration for stability
	if (data.rover.rotation % 360 > 260 and data.rover.rotation % 360 < 300) then
		data.wheelSprite[1].linearDampening = 1000
		if data.rover.kph < 10 then
			data.rover.angularV = 0
		else
			data.rover.angularV = data.rover.angularV * 0.9 
		end
	elseif data.rover.angularV > 100 then
		data.rover.angularV = data.rover.angularV * 0.99 -- normal deceleration
	elseif data.rover.angularV - 1 > 0 then
		data.rover.angularV = data.rover.angularV - 1 -- final deceleration to 0
	else
		data.rover.angularV = 0
	end
end

-- Decelerate rover
local function decelerate()

	-- Set button image
	data.ctrlPanelGrp.accelButton:setFrame( 1 ) 

	data.rover.accelerate = false

	-- Play rover deceleration sound followed by idle engine sound, first halting any other sounds
	game.stopSound( data.rover.stage2Channel )
	game.stopSound( data.rover.stage1Channel )
	game.stopSound( data.rover.startChannel )

	local options2 = {
		channel = 1,
		loops = -1,
	}

	local function playEngineSound()
		if ( not data.rover.accelerate and game.currentActName() == "rover" ) then 
			data.rover.engineChannel = game.playSound(data.rover.engineSound, options2); 
		end
	end

	local options1 = {
		channel = 5,
		loops = 0,
		-- Play the rover engine sound indefinitely upon completion
		onComplete = playEngineSound
	}

	data.rover.stopChannel = game.playSound(data.rover.stopSound, options1)
end

-- Update map rover coordinates based on scroll-view movement
local function updateCoordinates()
	-- Calculate distance rover has moved in the scrolling view and scale to map
	local distMoved = ( data.rover.x - data.rover.distOldX ) / data.sideToMapScale
	data.rover.distOldX = data.rover.x

	-- Update rover coordinates
	data.map.rover.x = data.map.rover.x + (distMoved * data.map.courseVX) * data.mapZoomGrp.xScale
	data.map.rover.y = data.map.rover.y + (distMoved * data.map.courseVY) * data.mapZoomGrp.yScale
end

-- Return to mainAct if the rover has returned to the ship
local function checkIfRoverAtShip()

	local x1 = data.mapZoomGrp.x
	local y1 = data.mapZoomGrp.y
	local x2 = data.map.rover.x
	local y2 = data.map.rover.y

	-- Calculate the distance from the rover (in mapGrp) to the ship (at mapZoomGrp origin)
	local distanceFromShip = util.calcDistance( x1, y1, x2, y2 ) / data.mapZoomGrp.xScale

	-- If the rover has returned to the ship, then go to mainAct
	if distanceFromShip <= 2 then
		if data.map.rover.leftShip then
			data.map.rover.leftShip = false
			game.gotoAct( "mainAct" )
		end
	elseif not data.map.rover.leftShip then
		data.map.rover.leftShip = true	
	end
end

-- Engage auto navigation back to the ship (mandatory course, governed speed, disabled water scan)
local function engageAutoNav()

	local x1 = data.map.rover.x 
	local y1 = data.map.rover.y 
	local x2 = game.saveState.rover.x2
	local y2 = game.saveState.rover.y2
	local vX = data.map.courseVX
	local vY = data.map.courseVY

	-- Set auto navigation flag
	data.rover.isAutoNav = true

	-- Hide the water button and set the course to the ship
	data.ctrlPanelGrp.waterButton.isVisible = false
	util.replaceCourse( act, data.mapGrp, x1, y1, 0, 0, vX, vY )	

	-- Remover map touch listener to prevent course changes
	data.map:removeEventListener( "touch", mapTouched )

	-- Set course variables
	x2 = 0
	y2 = 0
	game.saveState.rover.x2 = 0
	game.saveState.rover.y2 = 0
	data.map.courseLength = util.calcDistance( x1, y1, x2, y2 )
	data.map.courseVX, data.map.courseVY = util.calcUnitVectors( x1, y1, x2, y2, data.map.courseLength )

	-- Display message to user 
	local options = { 
		x = act.xMax - 26,
		y = act.yMin + 12,
		time = 3000,
		width = 220
	}

	game.messageBox( "ON RESERVE POWER!\n\nAuto navigation engaged.", options )
end

local function updatePosition()

	if data.rover.isActive then 

		local x1 = data.map.rover.x 
		local y1 = data.map.rover.y 
		local x2 = game.saveState.rover.x2
		local y2 = game.saveState.rover.y2
		local vX = data.map.courseVX
		local vY = data.map.courseVY

		updateCoordinates()
		checkIfRoverAtShip()
		checkCraters()

		-- If the rover has just run out of food or energy then mandate course back to ship
		if ( game.energy() <= 0 or game.food() <= 0 ) and not data.rover.isAutoNav then
			engageAutoNav()
		end

		-- If the rover is within the map's boundaries
		if game.xyInRect( x1, y1, data.mapGrp ) and data.map.courseLength > 0 then	-- ARE BOTH CONDITIONS NECESSARY?
			util.replaceCourse( act, data.mapGrp, x1, y1, x2, y2, vX, vY )	
		else -- If map boundary has been reached

			-- Deactivate rover, cease acceleration, and initiate braking
			data.rover.isActive = false
			data.rover.accelerate = false
			data.rover.brake = true

			-- Remove map course objects
			display.remove( data.map.course )
			display.remove( data.map.courseArrow )
			data.map.courseLength = 0

			if not audio.isChannelPlaying( 5 ) then		
				decelerate()
			end

			-- Ensure the tracking dot remains within map boundaries
			if math.abs(data.map.rover.x) > data.map.width/2 then
				data.map.rover.x = math.abs(data.map.rover.x) / data.map.rover.x * data.map.width/2 * 0.99
			end

			if math.abs(data.map.rover.y) > data.map.width/2 then
				data.map.rover.y = math.abs(data.map.rover.y) / data.map.rover.y * data.map.width/2 * 0.99
			end
		end		
	end
end

-- Adjust and apply rover wheel angular velocity
local function moveRover()

	-- Accelerate, brake, or coast rover
	if data.rover.accelerate then
		accelRover()
		data.ctrlPanelGrp.waterButton.isVisible = false
	elseif data.rover.brake then
		brakeRover()
	else
		coastRover()
	end

	-- Apply wheel angular velocity & sprite frame to the wheel sprites
	-- Rear wheel at half speed for stability
	data.wheelSprite[1].angularVelocity = data.rover.angularV/2

	for i = 2, 3 do
		data.wheelSprite[i].angularVelocity = data.rover.angularV
	end

	-- Update map position
	updatePosition()

	-- Determine wheel sprite frame
	local wheelFrame

	if data.rover.angularV > 700 then 
		wheelFrame = 7
	elseif data.rover.angularV < 200 then 
		wheelFrame = 1
	else
		wheelFrame = math.floor( data.rover.angularV/100 )
	end

	-- Set wheel sprite frame
	for i = 1, 3 do
		data.wheelSprite[i]:setFrame( wheelFrame )
	end

	-- If rover is upturned, then reveal the reset button
	if (data.rover.rotation % 360 > 80 and data.rover.rotation % 360 < 270) and data.rover.kph == 0 then

		data.ctrlPanelGrp.waterButton.isVisible = false

		local function displayRecoverButton()
			if (data.rover.rotation % 360 > 80 and data.rover.rotation % 360 < 270) and data.rover.kph == 0 then
				data.ctrlPanelGrp.recoverButton.isVisible = true
				data.ctrlPanelGrp.accelButton.isVisible = false
				data.ctrlPanelGrp.waterButton.isVisible = false
				data.rover.accelerate = false
			end
		end

		timer.performWithDelay( 2000, displayRecoverButton )
	elseif data.rover.kph == 0 then
		data.ctrlPanelGrp.waterButton.isVisible = true
	end
end

-- Scroll the terrain to the left
local function moveTerrain()
	
	-- Create new obstacle
	if data.nextObstacle < data.rover.x + act.width then
		if data.rover.inCrater then
			new.obstacle( data.nextObstacle, data.nextObstacle + 20, act.yMax - data.floorY*0.73 )
		else
			new.obstacle( data.nextObstacle, data.nextObstacle + 20)
		end
		data.nextObstacle = data.nextObstacle + 20
	end

	-- If new terrain needed
	if data.nextX + data.dynamicGrp.x <= act.xMax then
		new.rectTerrain( (act.width - data.terrainOffset)/data.nTerrainRects, data.defaultElevation )

		-- If crater has been reached but not created, then create crater display objects
		if data.drawingCrater then
			for i = 1, #data.courseHeightMap do
				new.rectTerrain( 2, data.courseHeightMap[i] )
				data.craterHeightIndex = i
			end
			data.craterEndX = data.nextX + 200
			data.craterHeightIndex = data.craterHeightIndex + 1
			data.drawingCrater = false

		-- If crater has been past
		elseif data.rover.inCrater then
			if data.craterHeightIndex > #data.courseHeightMap and data.craterEndX + data.dynamicGrp.x + act.width <= act.xMin + data.terrainOffset then
				data.rover.inCrater = false
				data.craterIndex = 1
				data.craterHeightIndex = 1

				-- Empty data.craterHeightMap[] and data.courseHeightMap[] tables
				for i = #data.craterHeightMap, 1, -1 do
						data.craterHeightMap[i] = nil
				end

				for i = #data.courseHeightMap, 1, -1 do
						data.courseHeightMap[i] = nil
				end
			end
		end
	end
end

-- Acceleration button touch event handler
local function handleAccelButton( event )

	if data.rover.isActive then	

		if ( event.phase == "began" ) then

			-- Set button image
			data.ctrlPanelGrp.accelButton:setFrame( 2 ) 

			-- Accelerate rover
			data.rover.accelerate = true

			-- Halt engine or stop sounds
			game.stopSound( data.rover.engineChannel )
			game.stopSound( data.rover.stopChannel )

			local options3 = {
				channel = 4,
				loops = -1,
			}

			-- Play stage2 sound indefinitely if rover is accelerating
			local function playStage2Sound()
				if data.rover.accelerate then 
					data.rover.stage2Channel = game.playSound(data.rover.stage2Sound, options3); 
				end
			end

			local options2 = {
				channel = 3,
				loops = 0,
				onComplete = playStage2Sound
			}

			-- Play stage1 sound indefinitely if rover is accelerating
			local function playStage1Sound()
				if data.rover.accelerate then 
					data.rover.stage1Channel = game.playSound(data.rover.stage1Sound, options2); 
				end
			end

			local options1 = {
				channel = 2,
				loops = 0,
				onComplete = playStage1Sound
			}

			-- Play start sound, then stage1 sound, then stage2 sound, in order, based on wheel angular velocity
			if data.rover.angularV > 3500 then
				data.rover.stage2Channel = game.playSound(data.rover.stage2Sound, options3)
			elseif data.rover.angularV > 1750 then
				data.rover.stage1Channel = game.playSound(data.rover.stage1Sound, options2)
			else
				data.rover.startChannel = game.playSound(data.rover.startSound, options1)
			end

		elseif ( (event.phase == "ended" or event.phase == "cancelled") and data.rover.accelerate == true ) then

			-- Decelerate rover. Allow to coast and play deceration sound
			decelerate()
		end 
	end

	return true
end

-- Brake button event handler
local function onBrakePress( event )
	data.rover.accelerate = false
	data.rover.brake = true
	return true
end

-- Brake button event handler
local function onBrakeRelease( event )
	data.rover.brake = false

end

-- Water scan button event handler
local function onWaterRelease( event )
	-- Initiate braking
	data.rover.brake = true

	-- Stop all audio
	audio.stop()
	game.gotoAct ( "drillScan", { effect = "zoomInOutFade", time = 1000 } )

	return true
end

-- Reset button event handler
local function onRecoverPress( event )

	local x = data.rover.x
	local y = data.rover.y

	-- remove rover body
	data.rover:removeSelf()
	data.rover = nil

	-- remove rover wheels
	for i = 1, #data.wheelSprite do
		data.wheelSprite[i]:removeSelf()
		data.wheelSprite[i] = nil
	end

	-- create new rover
	new.rover( x, y )

	-- reset speed display
	data.rover.speedOldX = data.rover.x
	data.speedText.text = string.format( data.speedText.format, 0, "kph" )

	-- display accelerator, hide recover button
	data.ctrlPanelGrp.accelButton.isVisible = true
	data.ctrlPanelGrp.waterButton.isVisible = true
	data.ctrlPanelGrp.recoverButton.isVisible = false

	-- deduct energy cost
	game.addEnergy( -5.0 )
	updateEnergyDisplay()

	return true
end

-- Handle accelerator button slide-off
local function handleSlideOff( event )

	if ( event.phase == "moved" and data.rover.accelerate == true ) then

		-- discontinue acceleration
		decelerate()
	end

	return true
end

-- Create control panel
local function newControlPanel()

	-- Set panel backgroud image
	local ctrlPanelData = { 
		parent = data.ctrlPanelGrp, 
		x = act.xCenter, 
		y = act.yMax + act.height/12, 
		width = act.width, 
		height = act.height/3 + 10,
	} 

	displayPanel = act:newImage( "panel.png", ctrlPanelData )

	-- Create invisible circle object as slide-off sensor for the accelerator button
	local slideOffSensor = display.newCircle( data.ctrlPanelGrp, act.xCenter + 35, act.yMax - 24, 60 )
	slideOffSensor.isVisible = false
	slideOffSensor.isHitTestable = true
	slideOffSensor:addEventListener( "touch", handleSlideOff )

	-- Create an image sheet for accelerator button
	local options = {
		width = 128,
		height = 128,
		numFrames = 2
	}

	local accelButtonSheet = graphics.newImageSheet( 'media/rover/accel_button.png', options )

	-- Create accelerator button sprite
	local sequenceData = {
		name = "accelButtoonSequence",
		start = 1,
		count = 2,
	}

	data.ctrlPanelGrp.accelButton = display.newSprite( data.ctrlPanelGrp, accelButtonSheet, sequenceData )
	data.ctrlPanelGrp.accelButton.x = act.xCenter + 35
	data.ctrlPanelGrp.accelButton.y = act.yMax - 24
	data.ctrlPanelGrp.accelButton:scale( 40/128, 40/128 )
	data.ctrlPanelGrp.accelButton:addEventListener( "touch", handleAccelButton )

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
	data.ctrlPanelGrp.waterButton = widget.newButton
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
	data.ctrlPanelGrp.recoverButton = widget.newButton
	{
		x = act.xCenter + 35,
		y = act.yMax - 23.5,
		width = 48,
		height = 48,
		defaultFile = "media/rover/reset_unpressed.png",
		overFile = "media/rover/reset_pressed.png",
		onPress = onRecoverPress
	}
	data.ctrlPanelGrp.recoverButton.isVisible = false

	data.ctrlPanelGrp:insert( brakeButton )
	data.ctrlPanelGrp:insert( data.ctrlPanelGrp.waterButton )
	data.ctrlPanelGrp:insert( data.ctrlPanelGrp.recoverButton )
end

-- Update the speed display
local function updateSpeedDisplay()
	local kmPerCoronaUnit = 0.00006838462 -- based on estimated rover length
	local elapsedTimePerHr = 7200 -- every 0.5 seconds
	data.rover.kph = ( data.rover.x - data.rover.speedOldX ) * kmPerCoronaUnit * elapsedTimePerHr
		
	if data.rover.kph < 0 then 
		data.rover.kph = 0 
	end

	data.speedText.text = string.format( data.speedText.format, data.rover.kph, "kph" )
	data.rover.speedOldX = data.rover.x
end

-- Start the act
function act:start()
	game.stopAmbientSound()
	data.rover.engineChannel = game.playSound(data.rover.engineSound, { channel = 1, loops = -1 } )
	physics.start()
end	

-- Stop the act
function act:stop()
	game.saveState.rover.x1 = data.map.rover.x
	game.saveState.rover.y1 = data.map.rover.y
	audio.stop()	-- Stop all audio
	physics.stop()
end

-- Init the act
function act:init()
	-- include Corona's physics and widget libraries
	local physics = require "physics"
	
	-- start physics, set gravity 
	physics.start()
	physics.setGravity( 0, 3.3 )
	-- physics.setContinuous( true )
	-- physics.setDrawMode( "hybrid" )

	-- seed math.random()
	math.randomseed( os.time() )

	data.nextX = act.xMin + data.terrainOffset

	-- create display groups
	data.staticBgGrp = act:newGroup()
	data.staticFgGrp = act:newGroup()
	data.dynamicGrp = act:newGroup()	
	data.ctrlPanelGrp = act:newGroup( data.staticFgGrp )
	data.displayPanelGrp = act:newGroup( data.staticFgGrp )

	-- Create sensor body for object removal
	local width = 20
	local x = act.xMin + data.terrainOffset - width
	data.removalSensorRect = display.newRect( data.dynamicGrp, x, act.yCenter, width, act.height )
	data.removalSensorRect.isVisible = true
	data.removalSensorRect.isHitTestable = true
	-- data.removalSensorRect.type = "removalSensor"
	data.removalSensorRect.isRemover = true
	physics.addBody( data.removalSensorRect, "dynamic", { isSensor = true } )
	data.removalSensorRect.gravityScale = 0

	-- create background
	new.background()

	while data.nextX < act.xMax do
		new.rectTerrain( (act.width - data.terrainOffset + data.terrainExcess)/data.nTerrainRects, data.defaultElevation )
	end

	new.rover( act.xMin + 100, act.yMax - 112 )

	-- create the terrain and the rover
	for i = 1, 20 do
		new.obstacle( act.xMin, act.xMax )
	end

	data.nextObstacle = data.rover.x + act.width

	-- create rover display panel and control panel
	newDisplayPanel()
	newControlPanel()

	timer.performWithDelay( 500, updateSpeedDisplay, 0 )
end

-- Handle enterFrame events
function act:enterFrame( event )

	-- Set and apply rover wheel angular velocity
	moveRover() 

	-- Move data.dynamicGrp and removal sensor along the x-axis the distance the rover has moved
	data.dynamicGrp.x = act.xMin + 100 - data.rover.x
	data.removalSensorRect.x = data.rover.x - 200

	-- Remove and generate terrain
	moveTerrain()

	-- Set static group stack order
	data.staticBgGrp:toBack()
	data.staticFgGrp:toFront()

	-- testPrint()
end

------------------------- End of Activity --------------------------------


-- Corona needs the scene object returned from the act file
return act.scene
