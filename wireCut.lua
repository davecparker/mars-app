
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
	
	-- background image
	local wireCutBG = act:newImage ( "wireCutBG.jpg", { width = 320} )
	wireCutBG.y = act.yCenter + 10

	-- led image sheet-----------------------------------------------
	local ledOptions =
	{
	    width = 249,
	    height = 252,
	    numFrames = 2,
	}
	local ledSequence = 
	{
		name = leds,
		start = 1,
		count = 2,
	}
	local ledImageSheet = graphics.newImageSheet( "media/wireCut/ledSheet.png", ledOptions )

	-- create top led sprite
	local ledTop = display.newSprite( act.group, ledImageSheet, ledSequence )
	ledTop:setSequence( "leds" )
	ledTop:scale (0.3, 0.3)
	ledTop.x = act.xMax - 31
	ledTop.y = act.yCenter - 90
	--ledTop:setFrame( 2 ) -- sets the image sheet frame to show

	-- create middle led sprite
	local ledMid = display.newSprite( act.group, ledImageSheet, ledSequence )
	ledMid:setSequence( "leds" )
	ledMid:scale (0.3, 0.3)
	ledMid.x = act.xMax - 31
	ledMid.y = act.yCenter

	-- create middle led sprite
	local ledBottom = display.newSprite( act.group, ledImageSheet, ledSequence )
	ledBottom:setSequence( "leds" )
	ledBottom:scale (0.3, 0.3)
	ledBottom.x = act.xMax - 31
	ledBottom.y = act.yCenter + 90

	-- or gate image sheet --------------------------------------
	local orGateOptions =
	{
	    width = 258,
	    height = 238,
	    numFrames = 2,
	}
	local orGateSequence = 
	{
		name = orGate,
		start = 1,
		count = 2,
	}
	local orGateImageSheet = graphics.newImageSheet( "media/wireCut/orGateSheet.png", orGateOptions )

	-- create the or gates
	local orTL = display.newSprite( act.group, orGateImageSheet, orGateSequence )
	orTL:setSequence( "orGate" )
	orTL:scale(0.3, 0.3)
	orTL.x = act.xCenter - 60
	orTL.y = act.yCenter - 90

	local orTR = display.newSprite( act.group, orGateImageSheet, orGateSequence )
	orTR:setSequence( "orGate" )
	orTR:scale(0.3, 0.3)
	orTR.x = act.xCenter + 40
	orTR.y = act.yCenter - 90

	-- placeholder
	--local wirePlaceholder = act:newImage ( "wiresPlaceholder.png", { width = 320} )
	--wirePlaceholder.y = act.yCenter + 10

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