--Automatically organizes your draw order every frame based on the z values you set to objects
--Extremely useful for games where the z values of objects change constantly



local zBuffer = {}


local function init()
	zBuffer.items = {}
	zBuffer.zvalues = {}
	zBuffer.size = 0
	
	local function loop()
		for i = 1, zBuffer.size do
			zBuffer.items[i]:toFront()
		end
	end
	Runtime:addEventListener("enterFrame", loop)
end
init()



local function swap(i1, i2)
	local temp = zBuffer.items[i1]
	zBuffer.items[i1] = zBuffer.items[i2]
	zBuffer.items[i2] = temp

	temp = zBuffer.zvalues[i1]
	zBuffer.zvalues[i1] = zBuffer.zvalues[i2]
	zBuffer.zvalues[i2] = temp
end

local function sortUpward(start)
	for i = start, 2, -1 do
		if zBuffer.zvalues[i] > zBuffer.zvalues[i - 1] then
			swap(i, i - 1)
		else
			break
		end
	end
end

local function sortDownward(start)
	for i = start, zBuffer.size - 1 do
		if zBuffer.zvalues[i] < zBuffer.zvalues[i + 1] then
			swap(i, i + 1)
		else
			break
		end
	end
end



function zBuffer.indexOf(object)
	for i = 1, zBuffer.size do
		if zBuffer.items[i] == object then
			return i
		end
	end
end

function zBuffer.add(object, z)
	zBuffer.size = zBuffer.size + 1
	zBuffer.items[zBuffer.size] = object
	zBuffer.zvalues[zBuffer.size] = z
	sortUpward(zBuffer.size)
	return zBuffer.size
end

function zBuffer.addArray(objects, size, z)
	for i = 1, size do
		zBuffer.add(objects[i], z)
	end
end

function zBuffer.set(index, object, z)
	if index <= zBuffer.size and index >= 1 then
		zBuffer.items[index] = object
		zBuffer.zvalues[index] = z
		sortUpward(index)
		sortDownward(index) --If sortUpward moved the item, this index no longer points to the right object, but it also won't matter because if that's the case, this won't do anything anyway
	end
end

function zBuffer.setZ(object, z)
	local i = zBuffer.indexOf(object)
	if i then
		zBuffer.zvalues[i] = z
		sortUpward(i)
		sortDownward(i) --If sortUpward moved the item, this i no longer points to the right object, but it also won't matter because if that's the case, this won't do anything anyway
	end
end

function zBuffer.remove(object)
	for i = zBuffer.indexOf(object), zBuffer.size - 1 do
		swap(i, i + 1)
	end
	zBuffer.items[zBuffer.size], zBuffer.zvalues[zBuffer.size] = nil, nil
	zBuffer.size = zBuffer.size - 1
end

function zBuffer.printAll()
	print("==============================================================================")
	for i = 1, zBuffer.size do
		print(i, zBuffer.zvalues[i], zBuffer.items[i].x, zBuffer.items[i].y, zBuffer.items[i], zBuffer.items[i].objType)
	end
	print("==============================================================================")
end

return zBuffer
