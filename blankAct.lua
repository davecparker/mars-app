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

-- Init the act
function act:init()
	-- Remember to put all display objects in act.group
end


------------------------- End of Activity --------------------------------


-- Corona needs the scene object returned from the act file
return act.scene
