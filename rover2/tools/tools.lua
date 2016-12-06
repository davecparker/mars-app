--Lots of random useful functions



local tools = {}



local randomswitch



local function init()
	tools.screenLeft, tools.screenTop, tools.screenWidth, tools.screenHeight = display.screenOriginX, display.screenOriginY, math.floor(display.actualContentWidth), math.floor(display.actualContentHeight)
	tools.screenRight, tools.screenBottom, tools.screenCenterX, tools.screenCenterY = tools.screenLeft + tools.screenWidth, tools.screenTop + tools.screenHeight, tools.screenLeft + tools.screenWidth / 2, tools.screenTop + tools.screenHeight / 2

	randomswitch = 0 --Used to determine which RNG alteration to use
end
init()



function tools.distance(x1, y1, x2, y2) --Returns the distance between two points
	local x, y = x2 - x1, y2 - y1
	return math.sqrt(x * x + y * y)
end

function tools.random(amount) --Randomized their built-in random() function, because it seemed to have poor distribution from what I saw
	local r

	if randomswitch == 0 then --Return math.random()...
		randomswitch = 1
		r = math.random()
	elseif randomswitch == 1 then --...or return 1 - math.random()...
		randomswitch = 2
		r = 1 - math.random()
	else
		randomswitch = 0
		r = (math.random() + .5) % 1 --...or return math.random() + .5 (and kept within the proper range of 0->1 with a modulo)
	end

	if amount then
		return r * amount
	else
		return r
	end
end

function tools.moveToward(object, xDest, yDest, speed) --Moves the object toward the point by the given amount
	if speed == 0 or (xDest == object.x and yDest == object.y) then --Make sure speed > 0 and we're not already at the point
		return
	end

	local xFactor, yFactor = xDest - object.x, yDest - object.y --The total x and y distances from the object to the point

	object.x = object.x + speed * xFactor / (math.abs(xFactor) + math.abs(yFactor)) --Add a portion of the total distances to object's coordinates based on speed and distance
	object.y = object.y + speed * yFactor / (math.abs(xFactor) + math.abs(yFactor))

	if (xFactor > 0 and object.x > xDest) or (xFactor < 0 and object.x < xDest) then --And make sure we stop at the point if we reach it (and don't overshoot)
		object.x = xDest
	end
	if (yFactor > 0 and object.y > yDest) or (yFactor < 0 and object.y < yDest) then
		object.y = yDest
	end
end



--Only because math.sin(math.pi) does not return 0 (they didn't handle special cases)
--Which in turn would make usage in vectorToCoords function and other functions slower (in that case, and maybe on the other axis')
function tools.sin(radians)
	if radians == 0 or radians == math.pi then --Lua has short circuit evaluation, so this is efficient when radians == 0
		return 0
	elseif radians == math.pi / 2 then
		return 1
	elseif radians == math.pi * 3 / 2 then
		return -1
	else
		return math.sin(radians)
	end
end
function tools.cos(radians)
	if radians == math.pi / 2 or radians == math.pi * 3 / 2 then
		return 0
	elseif radians == 0 then
		return 1
	elseif radians == math.pi then
		return -1
	else
		return math.cos(radians)
	end
end

--Haven't seen the source for math.atan(s,c)...it will prob either be the same or less efficient than this
--Returns {nil, 0} for a 0 length vector
--Uses standard programming coords (-x is left, -y is up) by default
--Vector direction is in radians
function tools.coordsToVector(x, y, positiveYUpwards)
	if not positiveYUpwards then
		y = -y
	end

	local result = {}

	result[2] = math.sqrt(x * x + y * y) --Distance calc will be done anyway for any diagonals, might as well return vector instead of just atan

    if x > 0 then
        if y > 0 then --Quad 1
            if x > y then
            	result[1] = math.asin(y / result[2])
            else
            	result[1] = math.acos(x / result[2])
            end
        elseif y < 0 then --Quad 4
            if x > -y then
            	result[1] = math.pi * 2 + math.asin(y / result[2])
            else
            	result[1] = math.pi * 2 -math.acos(x / result[2])
            end
        else
        	result[1] = 0
        end
    elseif x < 0 then
        if y > 0 then --Quad 2
            if -x > y then
            	result[1] = math.pi - math.asin(y / result[2])
            else
            	result[1] = math.acos(x / result[2])
            end
        elseif y < 0 then --Quad 3
            if x < y then
            	result[1] = math.pi - math.asin(y / result[2])
            else
            	result[1] = math.pi * 2 - math.acos(x / result[2])
            end
        else
        	result[1] = math.pi
        end
    else
        if y > 0 then
        	result[1] = math.pi / 2
        elseif y < 0 then
        	result[1] = math.pi * 3 / 2
        else
        	result[1] = nil
        end
    end

    return result
end

--Uses radians
--Uses standard programming coords (-x is left, -y is up) by default
function tools.vectorToCoords(direction, magnitude, positiveYUpwards)
	local result = {}

	if magnitude == 0 then
		result[1] = 0
		result[2] = 0
	else
		result[1] = magnitude * tools.cos(direction)
		result[2] = magnitude * -tools.sin(direction)
	end

	if positiveYUpwards then
		result[2] = -result[2]
	end

	return result
end



--Overloaded! Actual calls are...
--...getRotatedBounds(object) (meant for display objects; uses built-in rotation variable)
--...getRotatedBounds(rotation, left, right, top, bottom) (uses degrees)
function tools.getRotatedBounds(objectOrRotation, left, right, top, bottom)
	--Setup for getRotatedBounds(rotation, left, right, top bottom)
	local object = objectOrRotation
	local rotation = objectOrRotation
	--These are the distances from the objects origin to its given sides (right, top, left, bottom) when it is NOT rotated
	local r = right
	local t = top
	local l = left
	local b = bottom

	if not left then --If we only were passed one argument (object), so use its local variables
		--Overloaded setup for getRotatedBounds(object)
		rotation = -object.rotation--Negative rotation because their built-in rotation variable is clockwise...*sigh*...
		--These are the distances from the objects origin to its given sides (right, top, left, bottom) when it is NOT rotated
		r = (-object.width * object.anchorX + object.width) * object.xScale
		t = -object.height * object.anchorY * object.yScale
		l = -object.width * object.anchorX * object.xScale
		b = (-object.height * object.anchorY + object.height) * object.yScale
	end

	while rotation < 0 do
		rotation = rotation + 360
	end
	while rotation >= 360 do
		rotation = rotation - 360
	end

	rotation = math.rad(rotation)

	--And this section changes them to the actual bounds of the image/object after factoring in any rotation it may have
	local xFactor, yFactor = nil, nil
	if rotation == 0 then
		--Do nothing for this section
	elseif rotation == math.pi / 2 then
		local lastB = b
		b = -l
		l = t
		t = -r
		r = lastB
	elseif rotation == math.pi then
		local lastL, lastT = l, t
		l = -r
		r = -lastL
		t = -b
		b = -lastT
	elseif rotation == math.pi * 3 / 2 then
		local lastR = r
		r = -t
		t = l
		l = -b
		b = lastR
	else
		local vecRB = tools.coordsToVector(r, b)
		local vecRT = tools.coordsToVector(r, t)
		local vecLT = tools.coordsToVector(l, t)
		local vecLB = tools.coordsToVector(l, b)

		if rotation < math.pi / 2 then
			r = vecRB[2] * tools.cos(vecRB[1] + rotation)
			t = vecRT[2] * -tools.sin(vecRT[1] + rotation)
			l = vecLT[2] * tools.cos(vecLT[1] + rotation)
			b = vecLB[2] * -tools.sin(vecLB[1] + rotation)
		elseif rotation < math.pi then
			r = vecLB[2] * tools.cos(vecLB[1] + rotation)
			t = vecRB[2] * -tools.sin(vecRB[1] + rotation)
			l = vecRT[2] * tools.cos(vecRT[1] + rotation)
			b = vecLT[2] * -tools.sin(vecLT[1] + rotation)
		elseif rotation < math.pi * 3 / 2 then
			r = vecLT[2] * tools.cos(vecLT[1] + rotation)
			t = vecLB[2] * -tools.sin(vecLB[1] + rotation)
			l = vecRB[2] * tools.cos(vecRB[1] + rotation)
			b = vecRT[2] * -tools.sin(vecRT[1] + rotation)
		else --rotation >= math.pi * 3 / 2
			r = vecRT[2] * tools.cos(vecRT[1] + rotation)
			t = vecLT[2] * -tools.sin(vecLT[1] + rotation)
			l = vecLB[2] * tools.cos(vecLB[1] + rotation)
			b = vecRB[2] * -tools.sin(vecRB[1] + rotation)
		end
	end

	if not left then --If we only were passed one argument (object), so add object's coords in
		l = l + object.x
		r = r + object.x
		t = t + object.y
		b = b + object.y
	end

	return {l, r, t, b}
end

--True if ENTIRE object is inside bounds
--Exclusive
--Overloaded!
--If using inside(array, left, right, top, bottom) array is {left-most, right-most, top-most, bottom-most} points we want to see if are inside the boundary
function tools.inside(objectOrArray, left, right, top, bottom)
	if objectOrArray.rotation then --It's currently an object
		objectOrArray = tools.getRotatedBounds(objectOrArray)
	end

	local l, r, t, b = objectOrArray[1], objectOrArray[2], objectOrArray[3], objectOrArray[4]
	return (l > left
		and r < right
		and t > top
		and b < bottom)
end

--True if ENTIRE object is outside bounds
--Exclusive
--Overloaded!
--If using outside(array, left, right, top, bottom) array is {left-most, right-most, top-most, bottom-most} points we want to see if are outside the boundary
function tools.outside(objectOrArray, left, right, top, bottom)
	if objectOrArray.rotation then --It's currently an object
		objectOrArray = tools.getRotatedBounds(objectOrArray)
	end

	local l, r, t, b = objectOrArray[1], objectOrArray[2], objectOrArray[3], objectOrArray[4]

	return (r < left
		or l > right
		or b < top
		or t > bottom)
end

function tools.keepInBounds(object, left, right, top, bottom) --Convenience function for keeping something in a bounded area
	local array = tools.getRotatedBounds(object)

	local l, r, t, b = array[1], array[2], array[3], array[4]
	if l < left then
		object.x = object.x + left - l
	end
	if r > right then
		object.x = object.x + right - r
	end
	if t < top then
		object.y = object.y + top - t
	end
	if b > bottom then
		object.y = object.y + bottom - b
	end
end



--Lets you stare into the abyss (see variables/tables within corona's built-in modules)
--Or just print out the values in your own tables...I guess...
function tools.printTable(table)
	print("=========================================")
	for k, v in pairs(table) do
		print(k, "", v)
	end
	print("=========================================")
end

return tools
