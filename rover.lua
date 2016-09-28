---------------------------------------------------------------------------------------------------
--
-- rover.lua
--
-- The rover activity of the Mars App
--
-- Author: Mike Friebel
-- 
---------------------------------------------------------------------------------------------------
-- Overview
---------------------------------------------------------------------------------------------------
--
-- This activity portrays a rover traversing the Sinai Planum of Mars. It features a physics-based,
-- side-scrolling view and an accompanying overhead view. The side-scrolling movement is generated
-- by directly rotating the rover's wheels and letting Corona's physics engine generate the
-- resulting friction-based displacement, which yields a more realistic motion. The overhead view 
-- depicts the rover's current location on the Sinai Planum and is interactive, allowing the user  
-- to zoom in or out and to generate a new rover course at any time by touching any point of the 
-- overhead image. The overhead view does not automatically follow the rover's movement. It instead
-- remains static until the user zooms in or out, at which point it will pan towards the rover's 
-- current position to the extent allowed by the Sinai Planum image bounds.
--
---------------------------------------------------------------------------------------------------
-- The Terrain
---------------------------------------------------------------------------------------------------
-- 
-- The default side view terrain is generic with randomly generated physics objects to simulate 
-- rocks and is not based on any specific actual terrain. However, the major craters viewable in 
-- the overhead Sinai Planum image are generated as terrain in the side view when approached by 
-- the rover.
--
-- The crater terrain generated is based on a rough estimation of the profiles of actual craters 
-- in reference to their radii. They could be much more accurately modeled by a Chebyshev 
-- polynomial function and this may be something to consider adding in the future. The scale of the
-- craters relative to each other is roughly accurate, however, their scale relative to the rover 
-- is much smaller than actual for the sake of playability. Furthermore, although overall crater 
-- scale has been decreased, crater height has been independently increased for playability while 
-- also being capped to ensure all terrain remains sufficiently within view. This arrangement was 
-- developed in an attempt to adapt realistic crater profiles to the side view's limited dimensions
-- while keeping them recognizable and exciting. Unscaled craters would often exceed the viewing 
-- area while simply decreasing the scale of all craters would make the smaller craters 
-- insignificant.
--
-- One solution to representing larger terrain features in the side view might be to scale the 
-- entire contents of the side view as needed, in a zoom-out effect. This may work for any of the 
-- features in the sedate Sinai Planum but it would likely not work for the even larger features 
-- found elsewhere on Mars. Another solution might be to scroll vertically as well as horizontally 
-- while including an inset that would provide a macroscopic view of the rover's location relative 
-- to the terrain feature being traversed. An indication of elevation could also be provided. Some 
-- combination of these could probably be used.
--
---------------------------------------------------------------------------------------------------
-- Important Terrain Variables
---------------------------------------------------------------------------------------------------
--
-- data.marsToMapScale: actual Mars scale relative to the scale of the overhead view. The current 
-- value is calculated by dividing the estimated actual length of the area depicted in the Sinai 
-- Planum image in meters by the length of the image itself in corona units. This value affects the
-- scale of the crater features generated in the side view. 
--
-- data.mapScaleFactor: scales the terrain features generated in the side view. The scale of the 
-- terrain will be realistic (in accordance with data.marsToMapScale) if this value is 1.
--
-- data.craterHeightScale: scales the height of the crater terrain generated in the side view. 
--
---------------------------------------------------------------------------------------------------
-- Rover Speed
---------------------------------------------------------------------------------------------------
--
-- The speed of the rover in the side view is based on an actual rover length of 5.39 meters. The
-- speed of the rover in the overhead view is much greater than that of the side view relative to
-- the actual dimensions of the area depicted in the Sinai Planum image. This was done for 
-- playability. If the speed relationship was one-to-one, it would take several hours for the rover 
-- to traverse the overhead image. A slower speed would be preferable if the density of interesting
-- terrain features to be encountered in the overhead view and generated in the side view were 
-- greater.
--
---------------------------------------------------------------------------------------------------
-- Important Rover Speed Variables
---------------------------------------------------------------------------------------------------
--
-- data.sideToMarsScale: scale of the side view relative to actual Mars scale. The current value is
-- calculated by dividing the representative length of the side view based on a rover length of 
-- 5.39 meters by the estimated actual length of the area depicted in the Sinai Planum image in 
-- meters. This value affects the speed of the tracking dot in the overhead view.
--
-- data.mapSpeedFactor: scales the speed of the tracking dot across the overhead view. The tracking
-- dot's speed will be realistic (in accordance with data.sideToMarsScale) if this value is 1.
--
---------------------------------------------------------------------------------------------------
-- Overhead View Scaling and Panning
---------------------------------------------------------------------------------------------------
--
-- The overhead map image belongs to data.mapZoomGrp while the course and tracking dot display
-- objects belong to the data.mapGrp container. This allows the map to be scaled and panned without
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
--         To apply scaling/panning and convert to data.mapZoomGrp:
--
--             newX = oldX * data.mapZoomGrp.xScale + data.mapZoomGrp.x
--
--         To remove map scaling/panning and convert to data.mapGrp:
--
--             newX = (oldX - data.mapZoomGrp.x) / data.mapZoomGrp.xScale
--
---------------------------------------------------------------------------------------------------
-- Known issues
---------------------------------------------------------------------------------------------------
--
-- There is a slight and momentary irregularity in the distance-from-ship calculation during the 
-- simultaneous map scaling and tracking dot movement transitions that occur when the map is both 
-- scaled and panned. It affects return-to-ship functionality when the rover is located 2.000-2.015
-- corona units from the ship and the user zooms to the original map scale, or when the rover is 
-- located 1.985-2.000 corona units from the ship and the user zooms from the original map scale. 
-- This is likely due to the dependency on simultaneous transitions. The easiest fix is probably to
-- avoid performing the calculation during the transitions. 
--
-- There is jitter in the course pointer along its parallel that appeared with changes made in 
-- pull request #187. It is likely due to the calculation in util.calcCourseCoords that ensures 
-- the pointer doesn't exceed the map's boundaries.
--
-- The vertical placement of obstacles on crater terrain is often inconsistent, with some obstacles
-- placed too low and others too high relative to the base terrain's height. This is due to a 
-- temporary hack in new.obstacle() pending the changes needed in util.findTerrainHeight() and 
-- util.findTerrainSlope() to properly handle crater terrain polygons.
--
-- Terrain is incorrectly generated in the side view when a new course is selected while the 
-- rover is located within a crater. The entire crater is generated rather than the fraction 
-- required for display. Only the portion of the crater that lies within rover.x +/- act.width 
-- should be generated. See mapTouched() and newCourseHeightMap() in rover.lua.
--
-- The rover in the side view is too stable and will usually land upright after flipping. This
-- is due to the physics parameters used for the rover body and rover wheels. Stability may be
-- decreased by increasing the density of the body and/or decreasing the density of the wheels.
-- Increasing wheel friction will also decrease stability. The rover also tends to roll too easily
-- over its body when overturned. Decreasing body friction and/or bounce may reduce this. If this 
-- is insufficient, then a procedure to orchestrate a digging-in or sliding stop in the soft 
-- Martian soil when overturned would be necessary. 
--
-- The recover function is currently broken. It sometimes results in a runtime error or the failure 
-- to generate terrain following recovery. This issue appeared following the latest changes made to
-- terrain generation. Check onRecoverPress(), new.Rover(), and moveTerrain().
--
---------------------------------------------------------------------------------------------------
-- Ideas for Additional Features
---------------------------------------------------------------------------------------------------
--
-- Things to see and do while exploring Mars
-- Side view foreground and background elements
-- A greater number of terrain features
-- Larger terrain features
-- Irregular terrain features
-- Pitch-modulated rover sound
-- Additional sound effects (tires, sand, thumps, bangs, etc)
-- Rover track generation on overhead view image
-- Ability for the rover to sustain damage
-- Dust effects generated by the rover's wheels
-- Subversive Martians
-- 
---------------------------------------------------------------------------------------------------

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

-- Load rover utility functions and new display object functions
local util = require( "roverutil" )
local new = require( "rovernew" )

------------------------------- Start of Activity -------------------------------

-- Create new crater height map by filling data.craterHeightMap[] with crater height values
-- Requires a data.cratersOnCourse index. Calculations are based on the following approximations: 
-- Peak-to-floor of 4/3r, slope horizontal extent of 0.3r, floor diameter of 0.6r, rim peak of 0.1r
-- (data.marsToMapScale * data.mapScaleFactor) SHOULD BE MOVED TO roverdata.lua TO AVOID RECALCULATION
local function newCraterHeightMap( craterIndex )
	local craterRadius = data.cratersOnCourse[craterIndex].r * data.marsToMapScale * data.mapScaleFactor
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
	local craterR = data.cratersOnCourse[craterIndex].r * data.marsToMapScale * data.mapScaleFactor
	local craterD = math.round(util.calcDistance( currentX, currentY, craterX, craterY ) * data.marsToMapScale * data.mapScaleFactor)

	-- Correct distance-from-crater-center in the case that it is rounded to exceed craterR
	if craterD > craterR then
		craterD = #data.craterHeightMap
	end

	local i = 1
	while craterD <= craterR do

		-- Avoid indexing by 0
		if craterD == 0 then
			craterD = 1
		end

		-- Get height for the current distance from crater center, then get the distance for the next point along the course
		data.courseHeightMap[i] = data.craterHeightMap[craterD]
		currentX = currentX + data.map.courseVX / (data.marsToMapScale * data.mapScaleFactor)
		currentY = currentY + data.map.courseVY / (data.marsToMapScale * data.mapScaleFactor)
		craterD = math.round(util.calcDistance( currentX, currentY, craterX, craterY ) * data.marsToMapScale * data.mapScaleFactor)
		i = i + 1
	end 
end

-- Check the craters on course for crater intercept
local function checkCraters()
	local roverX = data.map.rover.x
	local roverY = data.map.rover.y 
	local cratersToRemove = {}

	for i = 1, #data.cratersOnCourse do

		-- Convert crater coordinates to data.mapZoomGrp, then get crater distance and scaled radius
		local craterX, craterY
		craterX, craterY = util.calcZoomCoords( data.cratersOnCourse[i].x, data.cratersOnCourse[i].y )
		local craterR = data.cratersOnCourse[i].r * data.mapZoomGrp.xScale
		local craterD = util.calcDistance( roverX, roverY, craterX, craterY )

		-- If rover has intercepted a crater: get course height map, flag for drawing, and remove from data.cratersOnCourse
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

	-- If map touch is initiated or moved, then draw a new course
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
	-- If touch ended, get craters on course, check for intercept, and redraw side view terrain, if necessary
	-- CRATER REDERAW NEEDS WORK! 
	elseif event.phase == "ended" then
		data.nextX = data.rover.x - 100
		util.findCratersOnCourse()
		checkCraters()

		if data.drawingCrater then  -- ADD CRATER REDRAW FUNCTIONALITY

			local x = data.rover.x
			local y = data.rover.y - 20  -- DETERMINE TERRAIN HEIGHT INSTEAD

			-- Replace the rover
			data.rover:removeSelf()
			data.rover = nil

			for i = 1, #data.wheelSprite do
				data.wheelSprite[i]:removeSelf()
				data.wheelSprite[i] = nil
			end

			new.rover( x, y )

			-- Replace the terrain
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

			data.courseHeightIndex = data.courseHeightIndex + 1
			data.drawingCrater = false
		end

		-- Record rover position and enable rover
		data.rover.distOldX = data.rover.x
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
-- NEED TO BREAK UP INTO MULTIPLE FUNCTIONS AND MOVE TO rovernew.lua
local function newMap()

	-- Create map background
	local mapX = act.xMin + act.height/6 + 5
	local mapY = act.yMin + act.height/6 + 5 
	local mapBgRect = {}
	for i = 1, 5 do
		mapBgRect[i] = display.newRect( data.displayPanelGrp, mapX, mapY, data.mapLength + 6 - i, data.mapLength + 6 - i )
		mapBgRect[i]:setFillColor( 0.5 - i/10, 0.5 - i/10, 0.5 - i/10 )
	end

	-- Create map display container
	data.mapGrp = display.newContainer( data.displayPanelGrp, data.mapLength, data.mapLength )
	data.mapGrp:translate( mapX, mapY )

	-- Initialize rover map starting coordinates to map center
	game.saveState.rover.x1 = 0
	game.saveState.rover.y1 = 0

	data.mapZoomGrp = act:newGroup( data.mapGrp )

	-- Create map
	local mapData = { 
		parent = data.mapZoomGrp, 
		x = 0, 
		y = 0, 
		width = data.mapLength,
		height = data.mapLength
	} 

	data.map = act:newImage( "sinai_planum.png", mapData )
	data.map.scale = 1

	data.mapGrp.left = -data.map.width/2
	data.mapGrp.right = data.map.width/2
	data.mapGrp.top = -data.map.width/2
	data.mapGrp.bottom = data.map.width/2

	-- Add touch event listener to map image
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
	
	-- Add pseudorandomly-generated initial course
	local x1 = data.map.rover.x
	local y1 = data.map.rover.y
	local x2 = x1
	local y2 = y1

	while x2 == x1 and y2 == y1 do
		x2 = math.random(-data.map.width/2, data.map.width/2)
		y2 = math.random(-data.map.width/2, data.map.width/2)
	end

	util.calcUnitVectors( x1, y1, x2, y2 )
	x2, y2 = util.calcCourseCoords( data.mapGrp, x1, y1, x2, y2 )
	game.saveState.rover.x2 = x2
	game.saveState.rover.y2 = y2

	util.findCratersOnCourse()

	data.map.course = util.newCourse( data.mapGrp, x1, y1, x2, y2 )
	data.map.courseArrow = util.newArrow( act, data.mapGrp, x1, y1, x2 - 2 * data.map.courseVX, y2 - 2 * data.map.courseVY )
	data.map.rover:toFront()	

	-- Record the current x-axis position of the side scrolling rover
	data.rover.distOldX = data.rover.x
end

-- Create new battery indicator. Accepts coordinate pair.
-- MOVE TO rovernew.lua
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
		y = y + 25.5,
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
-- BREAK UP AND MOVE TO rovernew.lua
local function newEnergyGauge( x, y )

	-- Options table for energy gauge image sheet 
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
	local spacing = 1.25

	-- Create an energy gauge background with attempt to create some shading for apparent recessed depth
	local energyGaugeBg = {}
	for i = 1, length + 5 do
		for j = 1, 6 do
			energyGaugeBg[i] = {}
			-- This adapts the function that produces the gauge's foreground curve to the background (see gauge sprite creation below)
			local width = options.width * math.pow( 2, (i*(nElements/(length + 5))*i*(nElements/(length + 5))/3000)) - (33 - i/100) - j
			energyGaugeBg[i][j] = display.newRect( data.displayPanelGrp, act.xCenter, act.yCenter, width, 1 )
			energyGaugeBg[i][j].anchorX = 1
			energyGaugeBg[i][j].anchorY = 1
			energyGaugeBg[i][j].x = x + 5 - (j - 1)/2
			energyGaugeBg[i][j].y = y - (i - 1)
			energyGaugeBg[i][j]:setFillColor( 0.6 - j/10, 0.6 - j/10, 0.6 - j/10 )
		end
	end

	-- Create top background border with attempt to create some shading for apparent recessed depth
	local energyGaugeBgTopBorder = {}
	for i = 1, 6 do
		energyGaugeBgTopBorder[i] = {}
		-- This fits each background element to the top gauge element width using the function the produces the gauge curve.
		local width = options.width * math.pow( 2, (50-(i-1)/2*50/(length + 5))*(50-(i-1)/2*50/(length + 5))/3000 ) - 33 - i
		energyGaugeBgTopBorder[i] = display.newRect( data.displayPanelGrp, act.xCenter, act.yCenter, width, 1 )
		energyGaugeBgTopBorder[i].anchorX = 1
		energyGaugeBgTopBorder[i].anchorY = 1
		energyGaugeBgTopBorder[i].x = x + 5 - (i - 1)/2
		energyGaugeBgTopBorder[i].y = y - (length + 4) + (i - 1)/2
		energyGaugeBgTopBorder[i]:setFillColor( 0.4 - i/15, 0.4 - i/15, 0.4 - i/15 )
	end

	-- Create bottom background border with attempt to create some shading for apparent recessed depth
	local energyGaugeBgBtmBorder = {}
	for i = 1, 6 do
		energyGaugeBgBtmBorder[i] = {}
		-- This fits each background element to the bottom gauge element width using the function the produces the gauge curve.
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
		-- This is a hack to produce the gauge curve. The exponential function produces the curve while '0.7' adjusts element width
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

-- Create the display panel
-- BREAK UP AND MOVE TO rovernew.lua
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

-- Set energy gauge color based on energy quintile
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

-- Reset energy gauge IAW current energy level
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
	else -- If game.energy() has diminished from even to odd, set top gauge element visibility & color, update index
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

-- Accelerate the rover up to an angular velocity of 8000 with higher initial acceleration
local function accelRover()
	if data.rover.angularV <= 150 then
		data.rover.angularV = data.rover.angularV + 50 
	elseif data.rover.isAutoNav and data.rover.angularV + 20 > 2000 then
		data.rover.angularV = 2000
	elseif data.rover.angularV + 20 > 8000 then
		data.rover.angularV = 8000 -- top speed
	else
		data.rover.angularV = data.rover.angularV + 20 -- typical acceleration
	end

	-- Apply energy use
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

-- Let the rover coast, with increased deceleration during high angle-of-attack instances for stability
local function coastRover()
	if (data.rover.rotation % 360 > 260 and data.rover.rotation % 360 < 300) then -- If high AOA
		data.wheelSprite[1].linearDampening = 1000
		if data.rover.kph < 10 then
			data.rover.angularV = 0
		else
			data.rover.angularV = data.rover.angularV * 0.9 
		end
	elseif data.rover.angularV > 100 then
		data.rover.angularV = data.rover.angularV * 0.99 -- Normal deceleration
	elseif data.rover.angularV - 1 > 0 then
		data.rover.angularV = data.rover.angularV - 1 -- Final deceleration to 0
	else
		data.rover.angularV = 0
	end
end

-- Decelerate rover
local function decelerate()

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

-- Engage auto navigation back to the ship (mandatory course, governed speed, hidden water scan button)
-- NEED TO ADD UNZOOMING OF MAP
local function engageAutoNav()
	game.saveState.rover.x2 = 0
	game.saveState.rover.y2 = 0
	data.rover.isAutoNav = true
	data.ctrlPanelGrp.waterButton.isVisible = false

	-- Remove map touch listener to prevent course changes
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

-- Update the rover's position on the overhead view
-- SHOULD BREAK UP
local function updatePosition()
	if data.rover.isActive then 

		updateCoordinates()
		checkIfRoverAtShip() -- NEED TO NOT DO THIS DURING THE ZOOMING TRANSITIONS
		checkCraters()

		local roverX = data.map.rover.x 
		local roverY = data.map.rover.y 
		local courseX = game.saveState.rover.x2 * data.mapZoomGrp.xScale + data.mapZoomGrp.x
		local courseY = game.saveState.rover.y2 * data.mapZoomGrp.yScale + data.mapZoomGrp.y

		-- If autonav not engaged, then calculate course coords in case of map panning & engage autonav if needed
		if not data.rover.isAutoNav then -- CONSIDER USING A DIFFERENT VARIABLE NAME
			courseX, courseY = util.calcCourseCoords( data.mapGrp, roverX, roverY, courseX, courseY ) -- MAKE THIS ONLY RUN DURING PANNING
			if ( game.energy() <= 0 or game.food() <= 0 ) then
				engageAutoNav()
			end
		end

		-- If the rover is within the map's boundaries, replace the course, else deactivate the rover
		if game.xyInRect( roverX, roverY, data.mapGrp ) and data.map.courseLength > 0 then	-- ARE BOTH CONDITIONS NECESSARY?
			util.replaceCourse( act, data.mapGrp, roverX, roverY, courseX, courseY )	
		else
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
-- BREAK UP INTO MULTIPLE FUNCTIONS
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

	-- Apply wheel angular velocity to the wheel sprites with the rear wheel at half speed for stability
	data.wheelSprite[1].angularVelocity = data.rover.angularV/2
	for i = 2, 3 do
		data.wheelSprite[i].angularVelocity = data.rover.angularV
	end

	updatePosition()

	-- Determine and set wheel sprite frame
	local wheelFrame
	if data.rover.angularV > 700 then 
		wheelFrame = 7
	elseif data.rover.angularV < 200 then 
		wheelFrame = 1
	else
		wheelFrame = math.floor( data.rover.angularV/100 )
	end

	for i = 1, 3 do
		data.wheelSprite[i]:setFrame( wheelFrame )
	end

	-- If the rover has stopped overturned, then replace the accelerate button with the recover button after some delay
	-- Otherwise, if the rover has stopped upright, then display the water scan button
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

		-- If accelerator touch began, then set accelerator image, set flag for acceleration, & play appropriate sound
		if ( event.phase == "began" ) then

			data.ctrlPanelGrp.accelButton:setFrame( 2 ) 
			data.rover.accelerate = true
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

			-- Play start sound, then stage1 sound, then stage2 sound, depending on wheel angular velocity
			if data.rover.angularV > 3500 then
				data.rover.stage2Channel = game.playSound(data.rover.stage2Sound, options3)
			elseif data.rover.angularV > 1750 then
				data.rover.stage1Channel = game.playSound(data.rover.stage1Sound, options2)
			else
				data.rover.startChannel = game.playSound(data.rover.startSound, options1)
			end

		elseif ( (event.phase == "ended" or event.phase == "cancelled") and data.rover.accelerate == true ) then
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

-- Water scan button event handler: initiate braking, stop all audio, then go to drillScan act.
local function onWaterRelease( event )
	data.rover.brake = true
	audio.stop()
	game.gotoAct ( "drillScan", { effect = "zoomInOutFade", time = 1000 } )
	return true
end

-- Reset button event handler
local function onRecoverPress( event )

	local x = data.rover.x
	local y = data.rover.y

	-- Replace side view rover
	data.rover:removeSelf()
	data.rover = nil
	for i = 1, #data.wheelSprite do
		data.wheelSprite[i]:removeSelf()
		data.wheelSprite[i] = nil
	end
	new.rover( x, y )

	-- Reset speed display
	data.rover.speedOldX = data.rover.x
	data.speedText.text = string.format( data.speedText.format, 0, "kph" )

	-- Replace recover button with accelerator button
	data.ctrlPanelGrp.accelButton.isVisible = true
	data.ctrlPanelGrp.waterButton.isVisible = true
	data.ctrlPanelGrp.recoverButton.isVisible = false

	-- Deduct energy cost
	game.addEnergy( -5.0 )
	updateEnergyDisplay()

	return true
end

-- Handle accelerator button slide-off
local function handleSlideOff( event )
	if ( event.phase == "moved" and data.rover.accelerate == true ) then
		decelerate()
	end
	return true
end

-- Create control panel. BREAK UP AND MOVE TO rovernew.lua
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

	-- Create the accelerator button sprite
	local options = {
		width = 128,
		height = 128,
		numFrames = 2
	}
	local accelButtonSheet = graphics.newImageSheet( 'media/rover/accel_button.png', options )

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

	-- Create the stop button
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

	-- Create the water scan button
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

	-- Create the reset button
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
	local kmPerCoronaUnit = 0.00006838462 -- based on estimated rover length of 4.66 meters
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

-- Initiate the act
function act:init()
	local physics = require "physics"
	physics.start()
	physics.setGravity( 0, 3.3 )
	-- physics.setDrawMode( "hybrid" )
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

-------------------------------- End of Activity --------------------------------

-- Corona needs the scene object returned from the act file
return act.scene
