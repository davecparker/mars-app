-----------------------------------------------------------------------------------------
--
-- resources.lua
--
-- The resources view for the Mars App.
-----------------------------------------------------------------------------------------

-- Get local reference to the game globals
local game = globalGame

-- Create the act object
local act = game.newAct()


------------------------- Start of Activity --------------------------------

-- Init the act
function act:init()
	-- Title bar for the view
	act:makeTitleBar( "Resources" )

	-- Post a new document (TODO: Temporary)
	game.foundDocument( "Resource Management" )
end


------------------------- End of Activity --------------------------------


-- Corona needs the scene object returned from the act file
return act.scene
