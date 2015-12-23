-----------------------------------------------------------------------------------------
--
-- startScreen.lua
--
-- Joe Cracchiolo
-- Splash screen the player sees when the game is first started

-----------------------------------------------------------------------------------------
------ Overhead -------------------------------------------------------------------------
-- Get local reference to the game globals
local game = globalGame
-- Create the act object
local act = game.newAct()
local widget = require( "widget" )

----- Variables -------------------------------------------------------------------------

----- Functions --------------------------------------------------------------------------
-- Move to the start of the game
local function startGame ( event )
	game.gotoAct( "mainAct", "fade" ) 
end

-- Move to the options screen
local function gotoOptions ( event )
	game.gotoAct( "debugMenu", "fade" ) 
end

-- Handle new frame events
function act:enterFrame()
	-- Continuous scroll of the endless space background
	for i = 1, 2 do
		local bg = marsBgs[i]
		bg.y = bg.y + 0.1
		if bg.y > act.yMax then
			bg.y = act.yMin - act.height*2
		end
	end
end

------------------------- Start of Activity ----------------------------------------------

-- Init the act
function act:init()
	-- Space background images (2 for continuous scrolling)
	marsBgs = {
		act:newImage( "titleMars.jpg", { y = act.yMin, anchorY = 0, height = act.height*2 }  ),
	 	act:newImage( "titleMars.jpg", { y = act.yMin - act.height*2, anchorY = 0, height = act.height*2 }  ),
	 }
	local imageMask = act:newImage( "titleScreenMask.png", { width = act.width } )
	local title = display.newText( act.group, "Mars App", act.xCenter, act.yMin + 40, native.systemFontBold, 60 )
	local startBtn = widget.newButton 
	{ 
		label = "Start", 
		fontSize = 30,
		x = act.xCenter, 
		y = act.yMax - 120, 
		onRelease = startGame 
	}
	act.group:insert( startBtn )
	local optionsBtn = widget.newButton 
	{ 
		label = "Options", 
		fontSize = 30,
		x = act.xCenter, 
		y = act.yMax - 70, 
		onRelease = gotoOptions 
	}
	act.group:insert( optionsBtn )
end

------------------------- End of Activity ---------------------------------------------------

-- Corona needs the scene object returned from the act file
return act.scene
