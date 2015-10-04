-----------------------------------------------------------------------------------------
--
-- mapZoom.lua
--
-- The zoomed map view (e.g. single room) for the Mars App
-----------------------------------------------------------------------------------------

-- Get local reference to the game globals
local game = globalGame

-- Create the act object
local act = game.newAct()


------------------------- Start of Activity --------------------------------

-- Handle tap on the back button
local function backTapped()
	-- Go back to overall map view
	game.mapZoom = false
	game.gotoAct( "mainAct", { effect = "crossFade", time = 250 } )
end

-- Init the act
function act:init()
	-- Title bar
	act:makeTitleBar( "Captain's Cabin", backTapped )

		-- Background image
	local bg = act:newImage( "sampleRoom.png", { width = act.width } )
	bg.x = act.xCenter
	bg.y = act.yCenter + act.dyTitleBar / 2
end


------------------------- End of Activity --------------------------------


-- Corona needs the scene object returned from the act file
return act.scene
