-----------------------------------------------------------------------------------------
--
-- menu.lua
--
-- The menu view for the Mars App.
-----------------------------------------------------------------------------------------

-- Get local reference to the game globals
local game = globalGame

-- Corona modules needed
local widget = require( "widget" )

-- Create the act object
local act = game.newAct()


------------------------- Start of Activity --------------------------------

-- Init the act
function act:init()
	-- Blank for now
end

-- Start the act
function act:start()
	-- For now, just run the debug menu
	game.gotoAct( "debugMenu" )
end

------------------------- End of Activity --------------------------------


-- Corona needs the scene object returned from the act file
return act.scene
