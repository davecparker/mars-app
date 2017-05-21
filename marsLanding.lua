-----------------------------------------------------------------------------------------
--
-- blankAct.lua
--
-- An empty (template) activity
-----------------------------------------------------------------------------------------

-- Get local reference to the game globals
local game = globalGame

-- Create the act object
local act = game.newAct()


------------------------- Start of Activity --------------------------------
local widget = require("widget")
-------------------------- Local Variables ---------------------------------
local height = 100000
--velocity is given in x(left/Right), y(Forward/Reverse), z(Up/Down). All together,
--These forces can be used to calculate total magnitude
local velocity = {0, 0, 0}
local group
local group1
local group2
local escapeVelocity = 1200
local thrusting = false
local thrustingUp = false
local thrustingDown = false
local thrustingRight = false
local thrustingLeft = false
local autopilot1 = false
local autopilot2 = false
local autopilot3 = false
-- Init the act
local heightText
-------------------------- Local Functions ---------------------------------
local function onBack()
	game.gotoAct( "mainAct", { effect = "zoomOutIn", time = 500 } )
end

local function flyTo( shipHeight ) 
 	if height < shipHeight and velocity[3] < 50 then
 		velocity[3] = velocity[3] + 3.711/5
 	elseif height < shipHeight then
 		velocity[3] = 50
 	else
 		autopilot1 = false
 		autopilot2 = false
 		autopilot3 = false
 	end
end

local function autoPilot()
	if height < 10000 and velocity[3] < -50 then
		autopilot1 = true
	elseif height < 20000 and velocity[3] < -100 then
		autopilot2 = true
	elseif height < 50000 and velocity[3] < -190 then
		autopilot3 = true
	end
end

local function thrust( event )
	if event.phase == "began" then
		thrusting = true
	elseif event.phase == "ended" then
		thrusting = false
	end
end
local function createSideThrustButton( scene, x, y, vertices, listener )
	local b = widget.newButton {
		x = x, y = y,
		shape = "polygon",
		vertices = vertices,
		fillColor = { default = { game.themeColor.r, game.themeColor.g, game.themeColor.b }, 
			over = { game.themeHighlightColor.r, game.themeHighlightColor.g, game.themeHighlightColor.b } },
	    labelColor = { default={ 1, 1, 1 } },
		onEvent = listener
	}
	scene:insert(b)
	return b
end

local function thrustUp( event )
	if event.phase == "began" then
		thrustingUp = true
	elseif event.phase == "ended" then
		thrustingUp = false
	end
end

local function thrustDown( event )
	if event.phase == "began" then
		thrustingDown = true
	elseif event.phase == "ended" then
		thrustingDown = false
	end
end

local function thrustLeft( event )
	if event.phase == "began" then
		thrustingLeft = true
	elseif event.phase == "ended" then
		thrustingLeft = false
	end
end

local function thrustRight( event )
	if event.phase == "began" then
		thrustingRight = true
	elseif event.phase == "ended" then
		thrustingRight = false
	end
end

local function gravity()
	--print (velocity[1], velocity[2], velocity[3])
	if (not thrusting) then
			velocity[3] = velocity[3] - 3.711/5
			if (velocity[3] < -200) then
				velocity[3] = -200
			end
	else
		velocity[3] = velocity [3] + 3.711/5
	end
	height = height + velocity[3]

	--heightText.text = "Height: " .. math.floor(height) .. "\nX Velocity: " .. math.floor(velocity[1]) .. "\nY Velocity: " .. math.floor(velocity[2]) .. "\nZ Velocity: " .. math.floor(velocity[3]) 
	heightText.text = "Height: " .. math.floor(height) .. "\nZ Velocity: " .. math.floor(velocity[3])
end

local function moving()
	if (thrustingUp) then
		velocity[2] = velocity[2] + 2/10
	elseif(thrustingDown) then
		velocity[2] = velocity[2] - 2/10
	end

	if (thrustingLeft) then
		velocity[1] = velocity[1] - 2/10
	elseif (thrustingRight) then
		velocity[1] = velocity[1] + 2/10
	end
end

local function friction()
	if (velocity[1] > 0) then
		velocity[1] = velocity[1] - 2/45
	elseif(velocity[1] < 0) then
		velocity[1] = velocity[1] + 2/45
	end
	
	if (velocity[2] > 0) then
		velocity[2] = velocity[2] - 2/45
	elseif(velocity[2] < 0) then
		velocity[2] = velocity[2] + 2/45
	end
end

local function moveShip()
	group1.x = group1.x + velocity[1]
	group1.y = group1.y + velocity[2]
	--print(group1.x, group1.y)
	if height > 100 then
		group1.xScale = 100 / (500 * (height/100000))
		group1.yScale = 100 / (500 * (height/100000))
		--print(group1.xScale, group1.yScale)
	end
end
------------------------ EnterFrame Loop ---------------------------------------
function act:enterFrame()
	gravity()
	moving()
	friction()
	autoPilot()
	if autopilot1 == true then
		flyTo(15000)
	elseif autopilot2 == true then
		flyTo(25000)
	elseif autopilot3 == true then
		flyTo(75000)
	end
	moveShip()
end
--------------------------- Init Game ------------------------------------------
function act:init()
	-- Remember to put all display objects in act.group
	group = display.newGroup( )
	act.group:insert(group)
	group1 = display.newGroup( )
	group1.x = act.xCenter
	group1.y = act.yCenter
	act.group:insert(group1)

	for i = -1, 1 do
		for j = -1, 1 do
			display.newCircle(group1, 500*j, 1000*i, 30)
		end
	end

	group2 = display.newGroup( )
	act.group:insert(group)
	local back = {}
	back[1] = display.newRect(act.group, act.xCenter, act.yMin + 50, act.width, 100)
	back[2] = display.newRect(act.group, act.xMin + 20, act.yCenter, 40, act.height)
	back[3] = display.newRect(act.group, act.xCenter, act.yMax - 50, act.width, 100)
	back[4] = display.newRect(act.group, act.xMax - 20, act.yCenter, 40, act.height)
	for i = 1, #back do
		back[i]:setFillColor(.5)
	end
	local heightTextOptions = 
	{
		text = "Height: " .. height,
		x = act.xMin + 5,
		y = act.yMin + 50,
		fontSize = 20,
		font = native.systemFontBold,
	}
	heightText = display.newText(heightTextOptions)
	heightText.anchorX = 0
	heightText.anchorY = 0
	act.group:insert(heightText)

	local backBtn = widget.newButton {
		label = "Back",
		x = act.xMin + 40, y = act.yMin + 30,
		shape = "roundedRect",
		width = 60, height = 40,
		fillColor = { default = { game.themeColor.r, game.themeColor.g, game.themeColor.b }, 
			over = { game.themeHighlightColor.r, game.themeHighlightColor.g, game.themeHighlightColor.b } },
	    labelColor = { default={ 1, 1, 1 } },
	    onRelease = onBack
	}
	act.group:insert( backBtn )
	--Creating the buttons
	local thrustRightBtn = createSideThrustButton( act.group, act.xMax - 110, act.yMax - 65, 
		{ 0, -20, -25, 0, 0, 20 }, thrustRight )
	local thrustLeftBtn = createSideThrustButton( act.group, act.xMax - 30, act.yMax - 65, 
		{ 0,-20, 25,0, 0,20 }, thrustLeft )
	local thrustUpBtn = createSideThrustButton( act.group, act.xMax - 70, act.yMax - 105, 
		{ 0,-25, -20,0, 20,0 }, thrustUp )
	local thrustDownBtn = createSideThrustButton( act.group, act.xMax - 70, act.yMax - 25, 
		{ 0,25, -20,0, 20,0 }, thrustDown )

	local thrustBtn = widget.newButton {
		label = "Thrust",
		x = act.xMin + 55, y = act.yMax - 50,
		shape = "circle",
		radius = 35,
		fillColor = { default = { game.themeColor.r, game.themeColor.g, game.themeColor.b }, 
			over = { game.themeHighlightColor.r, game.themeHighlightColor.g, game.themeHighlightColor.b } },
	    labelColor = { default={ 1, 1, 1 } },
	    onEvent = thrust
	}
	act.group:insert( thrustBtn )
end

---------------------------- Listeners -----------------------------------
------------------------- End of Activity --------------------------------


-- Corona needs the scene object returned from the act file
return act.scene
