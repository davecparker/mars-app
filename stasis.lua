-----------------------------------------------------------------------------------------
--
-- stasis.lua
--
-- The stasis activity for the Mars app. 
-- The user is forced to wait while water is generated.
-----------------------------------------------------------------------------------------

-- Get local reference to the game globals
local game = globalGame

-- Load Corona modules
local widget = require( "widget" )

-- Create the act object
local act = game.newAct()


-- File local variables
local progressBar     	-- the progress bar widget
local waterGoal = 20    -- goal for water generation (liters)


-- Init the act
function act:init()
	-- White background
	act:whiteBackground()

	-- The progress bar
	progressBar = widget.newProgressView{
	    x = act.xCenter,
	    y = act.yMax - 100,
	    width = act.width * 0.75,
	}
	act.group:insert( progressBar )

	-- Progress bar label
	display.newText( act.group, "Water generation progress:", act.xCenter, progressBar.y - 20,
			native.systemFont, 16 ):setFillColor( 0 )
end

-- Prepare the act
function act:prepare()
	-- Make sure we are starting with 0 water
	game.addWater( -game.water() )
	progressBar:setProgress( 0 )
end

-- Handle enterFrame events
function act:enterFrame()
	-- Add a little water
	game.addWater( 0.1 )  -- TODO: make slower
	progressBar:setProgress( game.water() / waterGoal )

	-- Automatically exit when we reach the goal
	if game.water() >= waterGoal then
		game.saveState.stasis = false
		game.updateState()
		game.sendMessage( "regenerated", 2000 )
		game.gotoAct( "mainAct", { effect = "slideRight", time = 500 } )
	end
end


-- Corona needs the scene object returned from the act file
return act.scene
