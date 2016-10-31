local game = globalGame		-- Get the game object
local act = game.newAct()	-- And use it to create this activity within the game context

local terrain = require("rover2.terrain")



local dynamicGroup, rover
local wheels = {}
local touching = false
local touchX



local function accelerate(percent)
	for i = 1, #wheels do
		wheels[i]:applyTorque(percent * .5)
	end
end

-- Call to go to a different activity
function act:gotoAct(activity, effect, time)
	audio.stop()
	game.gotoAct(activity, {effect = effect or "fade", time = time or 1000})
end

local function touchAnywhere(event)
	touchX = event.x
	touching = not (event.phase == "ended")
end



-- Start the activity
function act:start(event)
	Runtime:addEventListener("touch", touchAnywhere)
	game.stopAmbientSound()
	physics.start()
end	

-- Stop the activity
function act:stop()
	Runtime:removeEventListener("touch", touchAnywhere)
	audio.stop()
	physics.pause()
end



-- Main activity loop
function act:enterFrame(event)
	for i = 1, #wheels do
		wheels[i].angularDamping = math.max(0, math.sqrt(400 - math.abs(wheels[i].angularVelocity) / 10))
	end

	if touching then
		accelerate((touchX - act.xCenter) / (act.width / 2))
	end

	local vx, vy = rover:getLinearVelocity()
	for i = 1, #wheels do
		wheels[i].angularVelocity = 360 * vx / (math.pi * 24)
	end



	dynamicGroup.x = dynamicGroup.x - rover.x + rover.lastX
	dynamicGroup.y = dynamicGroup.y - rover.y + rover.lastY

	rover.lastX, rover.lastY = rover.x, rover.y
end



-- Initialize the activity
function act:init()
	physics.start()
	physics.pause()
	physics.setGravity(0, 30)
	physics.setContinuous(false)



	local bgColor = display.newRect(act.xCenter, act.yCenter, act.width, act.height)
	bgColor:setFillColor(.6, .4, .4)
	act.group:insert(bgColor)
	


	dynamicGroup = display.newGroup()
	act.group:insert(dynamicGroup)



	terrain.create(act, dynamicGroup, 1)



	rover = display.newImageRect("rover2/images/roverRight.png", 119, 63)
	dynamicGroup:insert(rover)
	local roverShape = {-59, -20, 59, -20, 38, 25, -59, 25}
	physics.addBody(rover, {shape = roverShape, friction = 1})

	rover.x, rover.y = act.xCenter, act.yCenter
	rover.lastX, rover.lastY = rover.x, rover.y

	local function addWheel(index, x)
		x = rover.x + x
		local y = rover.y + 28

		local wheel = display.newImageRect("rover2/images/wheel.png", 24, 24)
		wheel.x, wheel.y = x, y
		physics.addBody(wheel, {radius = 12, bounce = 0, friction = 1000000})
		physics.newJoint("pivot", rover, wheel, wheel.x, wheel.y)

		dynamicGroup:insert(wheel)
		wheels[index] = wheel
	end

	addWheel(1, -43)
	addWheel(2, -11)
	addWheel(3, 38)

	physics.start()

	rover.y = rover.y + 50
end



return act.scene
