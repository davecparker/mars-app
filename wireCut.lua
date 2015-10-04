
-----------------------------------------------------------------------------------------
--
-- wireCut.lua
--
-- Second Part to the circut activity 
-- Joe Cracchiolo
-----------------------------------------------------------------------------------------

-- Get local reference to the game globals
local game = globalGame

-- Create the act object
local act = game.newAct()


------------------------- Start of Activity --------------------------------

-- Init the act
function act:init()
	
	local wireCutBG = act:newImage ( "wireCutBG.jpg", { width = 320} )
	wireCutBG.y = act.yCenter + 10
	local wirePlaceholder = act:newImage ( "wiresPlaceholder.png", { width = 320} )
	wirePlaceholder.y = act.yCenter + 10

end


------------------------- End of Activity --------------------------------


-- Corona needs the scene object returned from the act file
return act.scene