-----------------------------------------------------------------------------------------
--
-- rover.lua
--
-- The rover activity of the Mars App
--
-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------
-- 
-- The overhead map belongs to data.mapZoomGrp while the course and tracking dot display objects
-- belong to the data.mapGrp container. This allows the map to be scaled and panned without 
-- affecting the appearance of the tracking dot or the course. data.mapZoomGrp scales and pans via
-- a transition and the tracking dot is coordinated with data.mapZoomGrp via its own transition. 
-- data.mapGrp remains static. When determining spatial relationships, the features of interest
-- must be in reference to the same coordinate system. Coordinates may be converted between the
-- systems by applying or removing data.mapZoomGrp scaling and panning as appropriate. A distance
-- may be converted by applying or removing data.mapZoomGrp scaling as appropriate. data.mapZoomGrp
-- scaling is contained by the data.mapZoomGrp.xScale and data.mapZoomGrp.yScale fields. Their 
-- values are always identical as currently implemented. data.mapZoomGrp panning is contained by
-- the data.mapZoomGrp.x and data.mapZoomGrp.y fields, which are also inherently scaled. Touch 
-- events are of the data.mapZoomGrp coordinate system. Coordinates may be converted by applying or
-- removing scaling and panning as follows:
--
-- 		To apply scaling/panning and convert to data.mapZoomGrp: 	
--
-- 			newX = oldX * data.mapZoomGrp.xScale + data.mapZoomGrp.x 
--
-- 		To remove map scaling/panning and convert to data.mapGrp: 	
--
-- 			newX = (oldX - data.mapZoomGrp.x) / data.mapZoomGrp.xScale
--
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

-- Create new crater height map by filling data.craterHeightMap[] with crater height values
-- Requires a data.cratersOnCourse index. Calculations are based on the following approximations: 
-- Peak-to-floor of 4/3r, slope horizontal extent of 0.3r, floor diameter of 0.6r, rim peak of 0.1r
local function newCraterHeightMap( craterIndex )
	local craterRadius = data.cratersOnCourse[craterIndex].r * data.mapToMarsScale * data.mapScaleFactor
	local totalHeight = 4/3 * craterRadius * data.craterHeightScale

	if totalHeight > data.maxCraterHeight then
		totalHeight = data.maxCraterHeight
	end

	local floorHeight = act.height/11 + (data.maxCraterHeight - totalHeight) * data.elevationFactor
	local rimHeight = floorHeight + totalHeight
	local innerSlopeStep = totalHeight / (0.3 * craterRadius)
	local outerSlopeStep = (data.defaultElevation - rimHeight) / (0.3 * craterRadius)

	-- Set floor values
	for d = #data.craterHeightMap + 1, 0.3 * craterRadius do
		data.craterHeightMap[d] = floorHeight
	end

	-- Set inside slope values
	for d = #data.craterHeightMap + 1, 0.6 * craterRadius do
		data.craterHeightMap[d] = data.craterHeightMap[d - 1] + innerSlopeStep
	end

	-- Set inside peak values
	local nPoints = 0.05 * craterRadius
	local peakSlopeStep = innerSlopeStep/nPoints
	local firstPoint = #data.craterHeightMap + 1
	for d = #data.craterHeightMap + 1, 0.65 * craterRadius do
		data.craterHeightMap[d] = data.craterHeightMap[d - 1] + (innerSlopeStep - (d - firstPoint) * peakSlopeStep)
	end

	-- Set outside peak values by copying inside peak values in reverse for a mirror image
	firstPoint = #data.craterHeightMap
	for d = #data.craterHeightMap + 1, 0.7 * craterRadius do
		data.craterHeightMap[d] = data.craterHeightMap[firstPoint + (firstPoint + 1 - d)]
	end

	-- Set outside slope values
	for d = #data.craterHeightMap + 1, craterRadius do
		data.craterHeightMap[d] = data.craterHeightMap[d - 1] + outerSlopeStep
	end
end

-- Fill data.courseHeightMap[] with course-crater intercept height values by indexing data.craterHeightMap
-- with distances from crater center measured along the current course through the crater's extent
local function newCourseHeightMap( craterIndex )
	local craterX = data.cratersOnCourse[craterIndex].x
	local craterY = data.cratersOnCourse[craterIndex].y
	local currentX = data.cratersOnCourse[craterIndex].interceptX
	local currentY = data.cratersOnCourse[craterIndex].interceptY
	local craterR = data.cratersOnCourse[craterIndex].r * data.mapToMarsScale * data.mapScaleFactor
	local craterD = math.round(util.calcDistance( currentX, currentY, craterX, craterY ) * data.mapToMarsScale * data.mapScaleFactor)

	-- Correct distance-from-crater-center in the case that it is rounded to exceed craterR
	if craterD > craterR then
		craterD = #data.craterHeightMap
	end

	local i = 1
	while craterD <= craterR do
		if craterD == 0 then
			craterD = 1
		end
		data.courseHeightMap[i] = data.craterHeightMap[craterD]
		currentX = currentX + data.map.courseVX / (data.mapToMarsScale * data.mapScaleFactor)
		currentY = currentY + data.map.courseVY / (data.mapToMarsScale * data.mapScaleFactor)
		craterD = math.round(util.calcDistance( currentX, currentY, craterX, craterY ) * data.mapToMarsScale * data.mapScaleFactor)
		i = i + 1
	end 
end

-- Check the craters on course for crater intercept
local function checkCraters()
	local roverX = data.map.rover.x
	local roverY = data.map.rover.y 
	local cratersToRemove = {}

	for i = 1, #data.cratersOnCourse do
		local craterX, craterY
		craterX, craterY = util.calcZoomCoords( data.cratersOnCourse[i].x, data.cratersOnCourse[i].y )
		local craterR = data.cratersOnCourse[i].r * data.mapZoomGrp.xScale
		local craterD = util.calcDistance( roverX, roverY, craterX, craterY )

		if craterD <= craterR then
			util.calcCraterIntercept( i )
			newCraterHeightMap( i )
			newCourseHeightMap( i )	
			data.drawingCrater = true	
			cratersToRemove[#cratersToRemove + 1] = i
		end
	end

	for i = 1, #cratersToRemove do
		table.remove( data.cratersOnCourse, cratersToRemove[i] )
	end
end

-- Map touch event handler
local function mapTouched( event )

	if event.phase == "began" or event.phase == "moved" then
		local roverX = data.map.rover.x
		local roverY = data.map.rover.y
		local courseX = event.x - data.mapGrp.x 
		local courseY = event.y - data.mapGrp.y

		if courseX ~= roverX or courseY ~= roverY then  -- If course length is non-zero
			util.calcUnitVectors( roverX, roverY, courseX, courseY )
			courseX, courseY = util.calcCourseCoords( data.mapGrp, roverX, roverY, courseX, courseY )

			-- updatePosition() applies scaling/panning to the course coordinates so remove prior to saving
			game.saveState.rover.x2 = (courseX - data.mapZoomGrp.x) / data.mapZoomGrp.xScale
			game.saveState.rover.y2 = (courseY - data.mapZoomGrp.y) / data.mapZoomGrp.yScale
		end
	elseif event.phase == "ended" then
		data.nextX = data.rover.x - 100
		util.findCratersOnCourse()
		checkCraters()

		if data.drawingCrater then  -- ADD CRATER REDRAW FUNCTIONALITY

			local x = data.rover.x
			local y = data.rover.y - 20  -- DETERMINE TERRAIN HEIGHT INSTEAD

			-- Remove rover body
			data.rover:removeSelf()
			data.rover = nil

			-- Remove rover wheels
			for i = 1, #data.wheelSprite do
				data.wheelSprite[i]:removeSelf()
				data.wheelSprite[i] = nil
			end

			-- Create new rover
			new.rover( x, y )

			for i = 1, #data.terrain do
				if data.terrain[i] then
					display.remove(data.terrain[i])
					data.terrain[i] = nil
				end
			end

			for i = 1, #data.courseHeightMap do
				new.basicTerrain( 2, data.courseHeightMap[i], false, true )
				data.courseHeightIndex = i
			end

			data.craterEndX = data.nextX + 200
			data.courseHeightIndex = data.courseHeightIndex + 1
			data.drawingCrater = false
		end

		-- Record the current x-axis position of the side scrolling rover
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

	-- variables for map position
	local mapX = act.xMin + act.height/6 + 5
	local mapY = act.yMin + act.height/6 + 5 

	-- create map background
	local mapBgRect = {}
	for i = 1, 5 do
		mapBgRect[i] = display.newRect( data.displayPanelGrp, mapX, mapY, data.mapLength + 6 - i, data.mapLength + 6 - i )
		mapBgRect[i]:setFillColor( 0.5 - i/10, 0.5 - i/10, 0.5 - i/10 )
	end

	-- create map display container
	data.mapGrp = display.newContainer( data.displayPanelGrp, data.mapLength, data.mapLength )
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
		width = data.mapLength,
		height = data.mapLength
	} 

	-- Create map image
	data.map = act:newImage( "sinai_planum.png", mapData )
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
	
	spaceship = act:newImage( "spaceship.png", spaceshipData )	-- UPDATE IMAGE AND DECREASE SIZE

	-- Add tracking dot to the map
	new.mapDot()
	
	local x1 = data.map.rover.x
	local y1 = data.map.rover.y
	local x2 = x1
	local y2 = y1

	while x2 == x1 and y2 == y1 do
		x2 = math.random(-data.map.width/2, data.map.width/2)
		y2 = math.random(-data.map.width/2, data.map.width/2)
	end

	-- Calculate course coordinates
	util.calcUnitVectors( x1, y1, x2, y2 )
	x2, y2 = util.calcCourseCoords( data.mapGrp, x1, y1, x2, y2 )
	game.saveState.rover.x2 = x2
	game.saveState.rover.y2 = y2

	-- Find the craters that lie on the course
	util.findCratersOnCourse()

	-- Draw the initial course
	data.map.course = util.newCourse( data.mapGrp, x1, y1, x2, y2 )
	data.map.courseArrow = util.newArrow( act, data.mapGrp, x1, y1, x2 - 2 * data.map.courseVX, y2 - 2 * data.map.courseVY )
	data.map.rover:toFront()	

	-- Record the current x-axis position of the side scrolling rover
	data.rover.distOldX = data.rover.x
end

-- Create new battery indicator. Accepts x,y coordinates.
local function newBattIndicator( x, y )

	-- Create new battery indicator display object
	local batteryData = { 
		parent = data.displayPanelGrp, 
		x = x + 5,
		y = y + 27, 
		width = 26, 
		height = 13, 
	} 

	local battery = act:newImage( "battery.png", batteryData )
	battery.anchorX = 1
	battery.anchorY = 1

	-- Create battery indicator display text object
	local format = "%3d%s"
	local options = 
	{
		parent = data.displayPanelGrp,
		text = string.format( format, game.energy(), "%" ),
		x = x + 2,
		y = y + 25.5, --act.yMin + data.mapLength + 5.5,
		font = native.systemFontBold,
		fontSize = 8,
	}

	data.energyText = display.newText( options )
	data.energyText:setFillColor( 0.0, 1.0, 0.0 )
	data.energyText.anchorX = 1
	data.energyText.anchorY = 1
	data.energyText.format = format
end

-- Create new energy gauge
local function newEnergyGauge( x, y )

	-- Create an energy gauge image sheet 
	local options = {
		width = 60,
		height = 2,
		numFrames = 8,
		sheetContentWidth = 60,
		sheetContentHeight = 16,
	}

	-- Energy gauge variables
	local length = math.round( data.mapLength ) - 16
	local nElements = 50
	local hScale = 1.0
	local height = options.height
	local spacing = 1.25 --math.round(10 * (length - nElements * height * hScale) / (nElements)) / 10

	-- Create an energy gauge background
	local energyGaugeBg = {}
	for i = 1, length + 5 do
		for j = 1, 6 do
			energyGaugeBg[i] = {}
			local width = options.width * math.pow( 2, (i*(nElements/(length + 5))*i*(nElements/(length + 5))/3000)) - (33 - i/100) - j
			energyGaugeBg[i][j] = display.newRect( data.displayPanelGrp, act.xCenter, act.yCenter, width, 1 )
			energyGaugeBg[i][j].anchorX = 1
			energyGaugeBg[i][j].anchorY = 1
			energyGaugeBg[i][j].x = x + 5 - (j - 1)/2
			energyGaugeBg[i][j].y = y - (i - 1)
			energyGaugeBg[i][j]:setFillColor( 0.6 - j/10, 0.6 - j/10, 0.6 - j/10 )
		end
	end

	-- Create top background border
	local energyGaugeBgTopBorder = {}
	for i = 1, 6 do
		energyGaugeBgTopBorder[i] = {}
		local width = options.width * math.pow( 2, (50-(i-1)/2*50/(length + 5))*(50-(i-1)/2*50/(length + 5))/3000 ) - 33 - i
		energyGaugeBgTopBorder[i] = display.newRect( data.displayPanelGrp, act.xCenter, act.yCenter, width, 1 )
		energyGaugeBgTopBorder[i].anchorX = 1
		energyGaugeBgTopBorder[i].anchorY = 1
		energyGaugeBgTopBorder[i].x = x + 5 - (i - 1)/2
		energyGaugeBgTopBorder[i].y = y - (length + 4) + (i - 1)/2
		energyGaugeBgTopBorder[i]:setFillColor( 0.4 - i/15, 0.4 - i/15, 0.4 - i/15 )
	end

	-- Create bottom background border
	local energyGaugeBgBtmBorder = {}
	for i = 1, 6 do
		energyGaugeBgBtmBorder[i] = {}
		local width = options.width * math.pow( 2, (1*(nElements/(length + 5))*1*(nElements/(length + 5))/3000)) - 33 - i
		energyGaugeBgBtmBorder[i] = display.newRect( data.displayPanelGrp, act.xCenter, act.yCenter, width, 1 )
		energyGaugeBgBtmBorder[i].anchorX = 1
		energyGaugeBgBtmBorder[i].anchorY = 1
		energyGaugeBgBtmBorder[i].x = x + 5 - (i - 1)/2
		energyGaugeBgBtmBorder[i].y = y - (i - 1)/2 + 1
		energyGaugeBgBtmBorder[i]:setFillColor( 0.4 - i/15, 0.4 - i/15, 0.4 - i/15 )
	end

	local gaugeSheet = graphics.newImageSheet( 'media/rover/gauge_sheet.png', options )

	local sequenceData = {
		name = "energySequence",
		start = 1,
		count = 8,
	}

	-- Create energy gauge sprites
	for i = 1, nElements do
		data.energyGaugeSprite[i] = display.newSprite( data.displayPanelGrp, gaugeSheet, sequenceData )
		data.energyGaugeSprite[i].anchorX = 1
		data.energyGaugeSprite[i].anchorY = 1
		data.energyGaugeSprite[i].x = x + 1
		data.energyGaugeSprite[i].y = y - (height * hScale + spacing) * (i - 1) - 1.51
		-- This is a hack to produce an attractive gauge curve. The exponential function produces the curve while '0.7' 
		-- reduces the width of each gauge element for aesthetics. Each gauge background block above employs this as well.
		data.energyGaugeSprite[i]:scale( math.pow( 2, i*i/3000 ) - 0.7, hScale )
		data.energyGaugeSprite[i]:setFrame( 5 )
		data.energyGaugeSprite[i].bright = true
	end
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
		height = act.height/3 + 10
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
	speedBgRect[6]:setFillColor( 0.2, 0.2, 0.2 )

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

	data.staticFgGrp:insert( data.zoomInButton )
	data.staticFgGrp:insert( data.zoomOutButton )

	-- Create battery indicator and energy gauge display
	newEnergyGauge( act.xMax - 6, speedBgRect[1].y + speedBgRect[1].height/2 - 16  )
	newBattIndicator( act.xMax - 6, speedBgRect[1].y + speedBgRect[1].height/2 - 27 )
end

-- Set energy gauge color
local function setEnergyGaugeColor()
	local spriteFrame
	if game.energy() > 80 then
		spriteFrame = 5
	elseif game.energy() > 60 then
		spriteFrame = 4
	elseif game.energy() > 40 then
		spriteFrame = 3
	elseif game.energy() > 20 then
		spriteFrame = 2
	else
		spriteFrame = 1
	end

	for i = 1, data.energyGaugeIndex do
		if data.energyGaugeSprite[i].frame ~= spriteFrame then
			data.energyGaugeSprite[i]:setFrame( spriteFrame )
		end
	end
end

-- Reset energy gauge
local function resetEnergyGauge()
	setEnergyGaugeColor()

	for i = 1, data.energyGaugeIndex do
		data.energyGaugeSprite[i]:setFillColor( 1 )
		data.energyGaugeSprite[i].isVisible = true
	end

	for i = data.energyGaugeIndex + 1, 50 do
		data.energyGaugeSprite[i].isVisible = false
		data.energyGaugeSprite[i]:setFillColor( 1 )
	end
end

-- Update the battery indicator and energy gauge
local function updateEnergyDisplay()
	-- Update energy text
	data.energyText.text = string.format( data.energyText.format, game.energy() , "%")

	-- If the truncated game.energy() integer has diminished from odd to even then dim the top gauge element
	if math.floor( game.energy() ) % 2 == 0 then
		if data.energyGaugeIndex - math.floor( game.energy() )/2 == 1 then
			if data.energyGaugeSprite[data.energyGaugeIndex].bright then
				data.energyGaugeSprite[data.energyGaugeIndex]:setFillColor( 0.5 )
				data.energyGaugeSprite[data.energyGaugeIndex].bright = false
			end
		else -- Reset the energy gauge because game.energy() has changed in an unpredictable manner
			data.energyGaugeIndex = math.floor( game.energy() )/2
			setEnergyGaugeColor()
			resetEnergyGauge()
		end
	else -- If game.energy() integer has diminished from even to odd then set top gauge element visibility and color, update index
		if data.energyGaugeIndex - math.ceil( game.energy()/2 ) == 1 then
			data.energyGaugeSprite[data.energyGaugeIndex].isVisible = false
			data.energyGaugeIndex = math.ceil( game.energy()/2 ) -- Could simply decrement the index?
			if data.energyGaugeIndex % 10 == 0 then
				setEnergyGaugeColor()
			end
		-- Reset the energy gauge because game.energy() has changed in an unpredictable manner
		elseif data.energyGaugeIndex - math.ceil( game.energy()/2 ) ~= 0 then
			data.energyGaugeIndex = math.ceil( game.energy()/2 ) 
			setEnergyGaugeColor()
			resetEnergyGauge()
		end
	end
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

-- Update the rover's map position with the scaled distance the rover moved in the scrolling view
local function updateCoordinates()
	local distMoved = ( data.rover.x - data.rover.distOldX ) * data.sideToMarsScale * data.mapSpeedFactor
	data.rover.distOldX = data.rover.x
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
	local distanceFromShip = util.calcDistance( x1, y1, x2, y2 )

	-- If the rover has returned to the ship, then go to mainAct
	if distanceFromShip <= 2 * data.mapZoomGrp.xScale then
		if not data.rover.atShip then
			data.rover.atShip = true
			game.gotoAct( "mainAct" )
		end
	elseif data.rover.atShip then
		data.rover.atShip = false	
	end
end

-- Engage auto navigation back to the ship (mandatory course, governed speed, disabled water scan) --ADD UNZOOMING
local function engageAutoNav()
	game.saveState.rover.x2 = 0
	game.saveState.rover.y2 = 0

	-- Set auto navigation flag
	data.rover.isAutoNav = true

	-- Hide the water button and set the course to the ship
	data.ctrlPanelGrp.waterButton.isVisible = false

	-- Remover map touch listener to prevent course changes
	data.map:removeEventListener( "touch", mapTouched )

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

		updateCoordinates()
		checkIfRoverAtShip() -- DISALLOW THIS DURING THE ZOOMING TRANSITIONS
		checkCraters()

		local roverX = data.map.rover.x 
		local roverY = data.map.rover.y 
		local courseX = game.saveState.rover.x2 * data.mapZoomGrp.xScale + data.mapZoomGrp.x
		local courseY = game.saveState.rover.y2 * data.mapZoomGrp.yScale + data.mapZoomGrp.y

		if not data.rover.isAutoNav then -- CONSIDER USING A DIFFERENT VARIABLE
			-- Calculate course coordinates
			courseX, courseY = util.calcCourseCoords( data.mapGrp, roverX, roverY, courseX, courseY ) -- MAKE THIS ONLY RUN DURING PANNING
			-- If the rover has just run out of food or energy then mandate course back to ship
			if ( game.energy() <= 0 or game.food() <= 0 ) then
				engageAutoNav()
			end
		end

		-- If the rover is within the map's boundaries
		if game.xyInRect( roverX, roverY, data.mapGrp ) and data.map.courseLength > 0 then	-- ARE BOTH CONDITIONS NECESSARY?
			util.replaceCourse( act, data.mapGrp, roverX, roverY, courseX, courseY )	
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
				data.map.rover.x = math.abs(data.map.rover.x) / data.map.rover.x * data.map.width/2 * 0.99  -- USE UNIT VECTORS HERE INSTEAD
			end

			if math.abs(data.map.rover.y) > data.map.width/2 then
				data.map.rover.y = math.abs(data.map.rover.y) / data.map.rover.y * data.map.width/2 * 0.99  -- USE UNIT VECTORS HERE INSTEAD
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

		local function displayRecoverButton( event )
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

-- Generate basic or crater terrain if new terrain is needed
local function moveTerrain()
	if data.terrain[#data.terrain].x + data.terrain[#data.terrain].width <= data.rover.x + act.width then
		if data.drawingCrater then
			new.craterTerrain( false, true )
		else
			new.basicTerrain( data.basicTerrainObjWidth, data.defaultElevation, false, false )
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
	return true
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
		height = act.height/3,
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
	data.ctrlPanelGrp.accelButton.y = act.yMax - 22
	data.ctrlPanelGrp.accelButton:scale( act.height/1707, act.height/1707 )
	data.ctrlPanelGrp.accelButton:addEventListener( "touch", handleAccelButton )

	-- create the stop button
	local brakeButton = widget.newButton
	{
		x = act.xCenter - 35,
		y = act.yMax - 22,
		width = act.height/13.33,
		height = act.height/13.33,
		defaultFile = "media/rover/brake_unpressed.png",
		overFile = "media/rover/brake_pressed.png",
		onPress = onBrakePress,
		onRelease = onBrakeRelease
	}

	-- create the water scan button
	data.ctrlPanelGrp.waterButton = widget.newButton
	{
		x = act.xMax - 28,
		y = act.yMax - 22,
		width = act.height/13.33,
		height = act.height/13.33,
		defaultFile = "media/rover/water_unpressed.png",
		overFile = "media/rover/water_pressed.png",
		onRelease = onWaterRelease
	}

	-- create the reset button
	data.ctrlPanelGrp.recoverButton = widget.newButton
	{
		x = act.xCenter + 35,
		y = act.yMax - 21.5,
		width = act.height/12,
		height = act.height/12,
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
	physics.pause()
end

-- Init the act
function act:init()
	-- Include Corona's physics library
	local physics = require "physics"
	
	-- Start physics and set gravity 
	physics.start()
	physics.setGravity( 0, 3.3 )
	-- physics.setDrawMode( "hybrid" )

	-- Seed math.random()
	math.randomseed( os.time() )

	-- Fill data.shape table with terrain obstacle shape functions
	data.shape = { new.circle, new.square, new.roundSquare, new.polygon }

	-- Create display groups
	data.staticBgGrp = act:newGroup()
	data.staticFgGrp = act:newGroup()
	data.dynamicGrp = act:newGroup()	
	data.ctrlPanelGrp = act:newGroup( data.staticFgGrp )
	data.displayPanelGrp = act:newGroup( data.staticFgGrp )

	-- Initialize act-dependent variables
	data.roverPosition = act.xMin + 100
	data.scrollViewTop = act.yMin + act.height/3
	data.scrollViewBtm = act.yMax - act.height/11
	data.defaultElevation = act.height/11 + (data.scrollViewBtm - data.scrollViewTop) * data.elevationFactor
	data.maxCraterHeight = data.scrollViewBtm - data.scrollViewTop - 75
	data.mapLength = act.height/3
	data.energyGaugeIndex = math.ceil( game.energy()/2 )

	-- Create rover, background, object removal sensor, display panel, and control panel
	new.rover( data.roverPosition, act.yMax - data.defaultElevation - 14 )
	new.background()
	new.RemovalSensor()
	newDisplayPanel()
	newControlPanel()
	resetEnergyGauge()
	updateEnergyDisplay()

	-- Create initial terrain
	while data.nextX < data.rover.x + act.width do
		new.basicTerrain( data.basicTerrainObjWidth, data.defaultElevation, false, false )
	end

	for i = 1, data.nObstacles do
		new.obstacle( math.random( data.removalSensor.x, data.rover.x + data.act.width ) )
	end

	-- Start rover speed display updating
	timer.performWithDelay( 500, updateSpeedDisplay, 0 )

	-- For testing purposes
	-- util.setRoverPosition( 5, 50 )
	-- util.markCraters()
end

-- Handle enterFrame events
function act:enterFrame( event )

	-- Set and apply rover wheel angular velocity
	moveRover() 

	-- Move data.dynamicGrp and removal sensor along the x-axis the distance the rover has moved
	data.dynamicGrp.x = data.roverPosition - data.rover.x
	data.removalSensor.x = data.rover.x - act.width

	-- Remove and generate terrain
	moveTerrain()

	-- Set static group stack order
	data.staticBgGrp:toBack()
	data.staticFgGrp:toFront()
end

------------------------- End of Activity --------------------------------


-- Corona needs the scene object returned from the act file
return act.scene
