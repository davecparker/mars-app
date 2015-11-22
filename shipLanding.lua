-----------------------------------------------------------------------------------------
--
-- shipLanding.lua
--
-- Ship Landing Activity by Ryan Bains-Jordan
-----------------------------------------------------------------------------------------

-- Get local reference to the game globals
local game = globalGame

-- Create the act object
local act = game.newAct()

-- Act Requisites
local physics = require( "physics" )

------------------------- Start of Activity --------------------------------

local ship = {}
local sound = {}

local function bgTouch( event )

	-- Rotate when right side of screen is touched
	if event.x > act.xCenter then
		if event.phase == "began" then
			ship.flameL.isVisible = true
			sound.channel = game.playSound( sound.thrust, { loops = -1 } )
		elseif event.phase == "ended" then
			ship.flameL.isVisible = false
			audio.stop( sound.channel )
		end
	-- Rotate when left side of screen is touched
	elseif event.x < act.xCenter then
		if event.phase == "began" then
			ship.flameR.isVisible = true
			sound.channel = game.playSound( sound.thrust, { loops = -1 } )
		elseif event.phase == "ended" then
			ship.flameR.isVisible = false
			audio.stop( sound.channel )
		end
	end

	return true
end

local function shipTouch( event )
	if event.phase == "began" then
		ship.flame.isVisible = true
		sound.channel = game.playSound( sound.thrust, { loops = -1 } )
	elseif event.phase == "ended" then
		ship.flame.isVisible = false
		audio.stop( sound.channel )
	end

	return true
end

-- Thrusting
--ship.dy = ship.dy - s 


-- Init the act
function act:init()

	sound.thrust = act:loadSound( "sounds/thrust.wav" )

	local bg = display.newRect( act.group, act.xCenter, act.yCenter, act.width, act.height )
	bg:setFillColor( 0 )
	bg:addEventListener( "touch", bgTouch )

	local thrustLeft
	
	ship.group = act:newGroup( )
	ship.group.x = act.xMin + 20
	ship.group.y = act.yMin + 20
	ship.group.dy = 0.5

	ship.square = display.newRect( ship.group, 0, 0, 30, 30 )
	ship.square:addEventListener( "touch", shipTouch )

	ship.flame = act:newImage( "flame.png", { parent = ship.group, x = 0, y = 50 } )
	ship.flame.isVisible = false

	ship.flameL = act:newImage( "flame.png", { parent = ship.group, x = -25, y = 30, width = 15 } )
	ship.flameL.rotation = 45
	ship.flameL.isVisible = false

	ship.flameR = act:newImage( "flame.png", { parent = ship.group, x = 30, y = 30, width = 15 } )
	ship.flameR.rotation = -45
	ship.flameR.isVisible = false
end

function act:enterFrame( event )
	ship.group.y = ship.group.y + ship.group.dy
end


------------------------- End of Activity --------------------------------


-- Corona needs the scene object returned from the act file
return act.scene