-----------------------------------------------------------------------------------------
--
-- roverutil.lua
--
-- Contains common utility functions for the rover activity of the Mars App
--
-----------------------------------------------------------------------------------------

-- Get local reference to the game globals
local game = globalGame

-- Load rover data table
local data = require( "roverdata" )

local util = {}

-- Calculate the distance between two cartesian coordinates. Accepts two coordinate pairs, returns distance.
function util.calcDistance( x1, y1, x2, y2 )
	return math.sqrt((x2 - x1) * (x2 - x1) + (y2 - y1) * (y2 - y1))
end

-- Create new map course. Accepts group and 2 course coordinate pairs, returns course reference.
function util.newCourse( group, x1, y1, x2, y2 )
	local course = display.newLine( group, x1, y1, x2, y2 )
	course:setStrokeColor( 1, 1, 1 )
	course.strokeWidth = 1.5
	return course
end

-- Create new course arrow. Accepts act, group, & 2 course coordinate pairs, returns course arrow reference.
function util.newArrow( act, group, x1, y1, x2, y2 )
	local arrowData = { 
		parent = group, 
		x = x2 + 2 * data.map.courseVX, 
		y = y2 + 2 * data.map.courseVY, 
		height = 7
	} 
	local arrow = act:newImage( "arrow.png", arrowData )
	arrow.anchorY = 0
	arrow.rotation = math.deg( math.atan2( y2 - y1, x2 - x1 )) + 90
	return arrow
end

-- Replace current course with a new course. Accepts act, group, and 2 course coordinate pairs.
function util.replaceCourse( act, group, x1, y1, x2, y2 )
	display.remove( data.map.course )
	display.remove( data.map.courseArrow )
	data.map.course = util.newCourse( group, x1, y1, x2, y2 )
	data.map.courseArrow = util.newArrow( act, group, x1, y1, x2 - data.map.courseVX, y2 - data.map.courseVY )
	data.map.rover:toFront()
end

-- Calculate course unit vectors. Accepts 2 coordinate pairs, returns the unit vectors.
function util.calcUnitVectors( x1, y1, x2, y2 )
	local courseLength = util.calcDistance( x1, y1, x2, y2 )
	data.map.courseVX = (x2 - x1)/courseLength
	data.map.courseVY = (y2 - y1)/courseLength
	return data.map.courseVX, data.map.courseVY
end

-- Calculate the coordinates of the intersection between the course and the mapGrp boundary. 
-- Accepts group & 2 course coordinate pairs, returns the intersection coordinates.
function util.calcCourseCoords( group, x1, y1, x2, y2 )

	-- Ensure the starting course coordinates are within mapGrp  
	if not game.xyInRect( x2, y2, group ) then
		x2 = x1 + data.map.courseVX * data.map.courseLength / data.mapZoomGrp.xScale
		y2 = y1 + data.map.courseVY * data.map.courseLength / data.mapZoomGrp.yScale
	end

	-- Find the coordinates that lie just within the mapGrp boundary
	while game.xyInRect( x2, y2, group ) do
		x2 = x2 + data.map.courseVX
		y2 = y2 + data.map.courseVY
	end
	x2 = x2 - data.map.courseVX -- REFERENCING THE MAPGRP BOUNDARY HERE SHOULD PREVENT COURSE POINTER JITTER
	y2 = y2 - data.map.courseVY

	data.map.courseLength = util.calcDistance( x1, y1, x2, y2 )

	return x2, y2
end

-- Determine whether a table contains a particular value. Accepts a table and a value, returns a boolean.
function util.tableContains( table, value )
	for i = 1, #table do
		if table[i].id == value then
			return true
		end
	end
	return false
end

-- Empty a table of its contents. Accepts table.
function util.emptyTable( table )
	for i = #table, 1, -1 do
		table[i] = nil
	end
end

-- Reset crater data variables and tables
function util.resetCraterData()
	data.drawingCrater = false
	data.courseHeightIndex = 1
	util.emptyTable( data.craterHeightMap )
	util.emptyTable( data.courseHeightMap )
end

-- Load data.cratersOnCourse table with the craters that lie on the current rover course
function util.findCratersOnCourse()
	util.emptyTable( data.cratersOnCourse )

	-- Remove scaling/panning from rover position
	local roverX = (data.map.rover.x - data.mapZoomGrp.x) / data.mapZoomGrp.xScale
	local roverY = (data.map.rover.y - data.mapZoomGrp.y) / data.mapZoomGrp.yScale

	-- Reduce unit vector magnitude to increase crater detection resolution
	local vX = data.map.courseVX / 100
	local vY = data.map.courseVY / 100

	-- Increment along the course checking for and recording any intercepted craters not already recorded
	while game.xyInRect( roverX, roverY, data.mapGrp ) do
		for i = 1, #game.saveState.craters do
			if not util.tableContains( data.cratersOnCourse, i ) then
				local craterX = game.saveState.craters[i].x
				local craterY = game.saveState.craters[i].y
				local distance = util.calcDistance( roverX, roverY, craterX, craterY )
				local craterR = game.saveState.craters[i].r
				if distance <= craterR then
					data.cratersOnCourse[#data.cratersOnCourse + 1] = {
						id = i, 
						x = craterX, 
						y = craterY, 
						r = craterR, 
					}
				end
			end
		end
		roverX = roverX + vX
		roverY = roverY + vY
	end
end

-- Calculate the crater intercept point upon occurrence of a course/crater intercept. Accepts crater index.
function util.calcCraterIntercept( craterIndex )
	local interceptX = (data.map.rover.x - data.mapZoomGrp.x) / data.mapZoomGrp.xScale
	local interceptY = (data.map.rover.y - data.mapZoomGrp.y) / data.mapZoomGrp.yScale
	local craterX = data.cratersOnCourse[craterIndex].x
	local craterY = data.cratersOnCourse[craterIndex].y
	local craterR = data.cratersOnCourse[craterIndex].r
	-- Use negative course unit vectors because the intercept has already occurred
	local xStep = -data.map.courseVX / 1000
	local yStep = -data.map.courseVY / 1000
	local i = 1
	local interceptDistance = util.calcDistance( interceptX, interceptY, craterX, craterY )
	while interceptDistance <= craterR do
		interceptX = interceptX + xStep
		interceptY = interceptY + yStep
		interceptDistance = util.calcDistance( interceptX, interceptY, craterX, craterY )
	end

	data.cratersOnCourse[craterIndex].interceptX = interceptX - xStep
	data.cratersOnCourse[craterIndex].interceptY = interceptY - yStep
end

-- Find the terrain height for a given x-coordinate. Accepts x-coordinate, returns terrain surface y-coordinate.
function util.findTerrainHeight( x )
	local i = #data.terrain
	while x < data.terrain[i].x - data.terrain[i].width/2 do
		i = i - 1
	end 
	return data.terrain[i].y - data.terrain[i].height/2
end

-- Find the terrain slope for a given x-coordinate. Accepts x-ccordinate, returns slope in degrees.
function util.findTerrainSlope( x )
	if x < data.rover.x + data.act.width - data.roverPosition then
		return 0
	else
		local i = #data.terrain
		while x < data.terrain[i].x - data.terrain[i].width/2 do
			i = i - 1
		end 
		return math.deg(math.atan(
			(data.terrain[i].y - data.terrain[i - 2].y) / (data.terrain[i].x - data.terrain[i - 2].x)))
	end
end

-- Scale and pan coordinates. Accepts a coordinate pair, returns a scaled and panned coordinate pair.
function util.calcZoomCoords( x, y )
	local zoomX = x * data.mapZoomGrp.xScale + data.mapZoomGrp.x
	local zoomY = y * data.mapZoomGrp.yScale + data.mapZoomGrp.y
	return zoomX, zoomY
end

-- Set rover position. Accepts coordinate pair.
function util.setRoverPosition( x, y )
	data.map.rover.x = x
	data.map.rover.y = y
end

-- Mark the craters recorded in game.saveState on the overhead view image for testing purposes.
function util.markCraters()
	for i = 1, #game.saveState.craters do
		data.craterMarkers[i] = display.newCircle( 
			data.mapZoomGrp, game.saveState.craters[i].x, game.saveState.craters[i].y, game.saveState.craters[i].r )
	end
end

return util
