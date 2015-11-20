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

	-- Function to Rotate Ship Clockwise
	local function rotate()	
		transition.to( ship.group, {time = 5000, rotation = 360, delta = true, onComplete = rotate } )
	end

	-- Function to Rotate Ship CounterClockwise
	local function rotate_c()
		transition.to( ship.group, {time = 5000, rotation = -360, delta = true, onComplete = rotate_c } )
	end

	-- Rotate when right side of screen is touched
	if event.x > act.xCenter then
		if event.phase == "began" then
			rotate()
			ship.flameL.isVisible = true
			audio.play( sound.thrust )
		elseif event.phase == "ended" then
			transition.cancel( square )
			ship.flameL.isVisible = false
		end
	-- Rotate when left side of screen is touched
	elseif event.x < act.xCenter then
		if event.phase == "began" then
			rotate_c()
			ship.flameR.isVisible = true
			audio.play( sound.thrust )
		elseif event.phase == "ended" then
			transition.cancel( square )
			ship.flameR.isVisible = false
		end
	end

	return true
end

local function shipTouch( event )
	if event.phase == "began" then
		ship.flame.isVisible = true
		myChannel = audio.play( sound.thrust, { loops = -1 } )

	elseif event.phase == "ended" then
		ship.flame.isVisible = false
		audio.stop( myChannel )
	end

	return true
end

-- Init the act
function act:init()

	sound.thrust = audio.loadSound( "media/shipLanding/sounds/ignite.wav" )

	local bg = display.newRect( act.group, act.xCenter, act.yCenter, act.width, act.height )
	bg:setFillColor( 0 )
	bg:addEventListener( "touch", bgTouch )
	
	ship.group = act:newGroup( )
	ship.group.x = act.xCenter
	ship.group.y = act.yCenter

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


------------------------- End of Activity --------------------------------


-- Corona needs the scene object returned from the act file
return act.scene