-----------------------------------------------------------------------------------------
--
-- mainAct.lua
--
-- The main activity (map, etc.) for the Mars App
-----------------------------------------------------------------------------------------

-- Get local reference to the game globals
local game = globalGame

-- Create the act object
local act = game.newAct()


------------------------- Start of Activity --------------------------------

-- Init the act
function act:init()
	-- For now, just display sample map image
	act:newImage( "shipPlan.png", { width = act.width } )

	-- Post a new document (TODO: Temporary)
	game.foundDocument( "Security Announcement" )
end


------------------------- End of Activity --------------------------------


-- Corona needs the scene object returned from the act file
return act.scene
