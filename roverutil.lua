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

-- Calculate the distance between two cartesian coordinates
function util.calcDistance( x1, y1, x2, y2 )
	return math.sqrt((x2 - x1) * (x2 - x1) + (y2 - y1) * (y2 - y1))
end

-- Create a new map course and course arrow
function util.newCourse( group, x1, y1, x2, y2 )
	local course = display.newLine( group, x1, y1, x2, y2 )
	course:setStrokeColor( 1, 1, 1 )
	course.strokeWidth = 1.5
	return course
end

-- Create new course arrow aligned with course direction
function util.newArrow( act, group, x1, y1, x2, y2, vX, vY )
	local arrowData = { 
		parent = group, 
		x = x2 + 2 * vX, 
		y = y2 + 2 * vY, 
		height = 7
	} 
	local arrow = act:newImage( "arrow.png", arrowData )
	arrow.anchorY = 0
	arrow.rotation = math.deg( math.atan2( y2 - y1, x2 - x1 )) + 90
	return arrow
end

-- Replace current course with a new course
function util.replaceCourse( act, group, x1, y1, x2, y2, vX, vY )
	display.remove( data.map.course )
	display.remove( data.map.courseArrow )
	data.map.course = util.newCourse( group, x1, y1, x2, y2 )
	data.map.courseArrow = util.newArrow( act, group, x1, y1, x2, y2, vX, vY )
	data.map.rover:toFront()
	data.map.courseLength = util.calcDistance( x1, y1, x2, y2 )
end

-- Calculate unit vectors
function util.calcUnitVectors( x1, y1, x2, y2, length )
	vX = (x2 - x1)/length
	vY = (y2 - y1)/length
	return vX, vY
end

-- Calculate the course coordinates that intersect the current map boundary
function util.calcCourseCoords( group, x1, y1, x2, y2 )
	data.map.courseLength = util.calcDistance( x1, y1, x2, y2 )
	if data.map.courseLength > 0 then
		data.map.courseVX, data.map.courseVY = util.calcUnitVectors( x1, y1, x2, y2, data.map.courseLength )
		while game.xyInRect( x2, y2, group ) do
			x2 = x2 + data.map.courseVX
			y2 = y2 + data.map.courseVY
		end
		x2 = x2 - 2 * data.map.courseVX
		y2 = y2 - 2 * data.map.courseVY
	else
		data.map.courseVX = 0
		data.map.courseVY = 0
	end

	-- Set global variables to new destination coordinates
	game.saveState.rover.x2 = x2
	game.saveState.rover.y2 = y2

	-- Calculate the length of the new course
	data.map.courseLength = util.calcDistance( x1, y1, x2, y2 )

	return x2, y2
end

-- Calculate a y-coordinate for an x-coordinate
function util.calcPtY( x1, y1, x2, y2, x3 )
	local m = (y2 - y1)/(x2 - x1)
	local b = y1 - m * x1
	return m * x3 + b
end


function util.testPrint()
	print( string.format("%s %.2f %s %.2f %s %.2f %s %.2f %s %.2f %s %s %s %s %s %s %s %.2f %s %.2f %s %.2f %s %.2f %s %.2f %s %.2f",
						"mapZoomGrp.x: ", mapZoomGrp.x,
						"map.rover.x: ", map.rover.x,
						"mapZoomGrp.y: ", mapZoomGrp.y,
						"map.rover.y: ", map.rover.y,
						"map.courseLength: ", map.courseLength,
						"rover.isActive: ", tostring(rover.isActive),
						"rover.leftShip: ", tostring(map.rover.leftShip)
						"rover.inCrater: ", tostring(rover.inCrater),
						"craterIndex: ", craterIndex,
						"nextX: ", nextX + dynamicGrp.x,
						"craterEndX: ", craterEndX,
						"craterEndX+dynamicGrp.x: ", craterEndX+dynamicGrp.x,
						"#courseHeightMap: ", #courseHeightMap,
						"Crater distance: ", calcDistance( map.rover.x, map.rover.y, game.saveState.craters[craterIndex].x, game.saveState.craters[craterIndex].y )
						))
end 

return util
