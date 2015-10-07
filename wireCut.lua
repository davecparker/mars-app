
-----------------------------------------------------------------------------------------
--
-- wireCut.lua
--
-- Second Part to the circut activity 
-- Joe Cracchiolo
-----------------------------------------------------------------------------------------
------------------------- OverHead ---------------------------------------------------------

-- Get local reference to the game globals
local game = globalGame

-- Create the act object
local act = game.newAct()
local widget = require( "widget" )  -- need to make buttons
-------------------------- Variables ------------------------------------------------------

------------------------- Functions -------------------------------------------------------

-- function to send you back when you press the back button
local function backButtonPress ( event )
	game.gotoAct ( "mainAct" )
end

------------------------- Start of Activity ----------------------------------------------------

-- Init the act
function act:init()
	
	local wireCutBG = act:newImage ( "wireCutBG.jpg", { width = 320} )
	wireCutBG.y = act.yCenter + 10
	local wirePlaceholder = act:newImage ( "wiresPlaceholder.png", { width = 320} )
	wirePlaceholder.y = act.yCenter + 10

		-- back button
	local backButton = act:newImage( "backButton.png", { width = 40 } )
	backButton.x = act.xMin + 30
	backButton.y = act.yMin + 30
	backButton.button = widget.newButton 
	{
		 x = act.xMin + 30,
		 y = act.yMin + 30,
		 width = 50, 
		 height = 50,
		 onPress = backButtonPress 
	}

end

------------------------- End of Activity --------------------------------------------------------

-- Corona needs the scene object returned from the act file
return act.scene