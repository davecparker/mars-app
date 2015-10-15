
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
local xyText		-- text display object for touch location =======================================================================

------------------------- Functions -------------------------------------------------------

-- function to send you back when you press the back button
local function backButtonPress ( event )
	game.gotoAct ( "mainAct" )
end

-- function for cutting the wire
local function wireTouch ( event )
	if event.phase == "began" then
		print ("touched")
	end
end

-- function to setup common stuff in the wires
local function wireSetup (wire)
	wire:scale ( 0.35, 0.35 )
	wire.isCut = false
end

-- Handle touches on the background by updating the text displays=============================================================
local function touched( event )
	-- Get touch location but pin to the act bounds
	local x = game.pinValue( event.x, act.xMin, act.xMax )
	local y = game.pinValue( event.y, act.yMin, act.yMax )

	-- Update the absolute and center-relative coordinate displays
	xyText.text = string.format( "(%d, %d)", x, y )
	xyCenterText.text = string.format( "Center + (%d, %d)", x - act.xCenter, y - act.yCenter )
end


------------------------- Start of Activity ----------------------------------------------------

-- Init the act
function act:init()

	-- background image
	local wireCutBG = act:newImage ( "wireCutBG.jpg", { width = 320} )
	wireCutBG.y = act.yCenter + 10
	wireCutBG.x = act.xCenter - 4
	wireCutBG:addEventListener( "touch", touched )--====================================================================================

	-- wire1 image sheet---------------------------------------------------------------------------------------------------------------
	local wire1Options =
	{
		width = 110,
		height = 404,
		numFrames = 2,
	}
	local wire1Sequence =
	{
		name = wire1,
		start = 1,
		count = 2,
	}
	local wire1ImageSheet = graphics.newImageSheet( "media/wireCut/wire1sheet.png", wire1Options )
	local wire1 = display.newSprite( act.group, wire1ImageSheet, wire1Sequence )
	wire1:setSequence( "wire1" )
	wireSetup(wire1)
	wire1.x = act.xCenter - 65
	wire1.y = act.yCenter - 160

	-- wire1 cutting buttons 
	local wire1Button = widget.newButton
	{
	    x = wire1.x,
	    y = wire1.y,
	    --shape = "rect",
		--fillColor = { default={ 1, 0.2, 0.5, 0.7 }, over={ 1, 0.2, 0.5, 1 } },
		width = wire1.width * 0.28,
		height = wire1.height * 0.28,
	    onEvent = wireTouch
	}

	-- wire2 image sheet---------------------------------------------------------------------------------------------------------------
	local wire2Options =
	{
		width = 630,
		height = 253,
		numFrames = 2,
	}
	local wire2Sequence =
	{
		name = wire2,
		start = 1,
		count = 2,
	}
	local wire2ImageSheet = graphics.newImageSheet( "media/wireCut/wire2sheet.png", wire2Options )
	local wire2 = display.newSprite( act.group, wire2ImageSheet, wire2Sequence )
	wire2:setSequence( "wire2" )
	wire2:scale ( 0.35, 0.35 )
	wire2.x = act.xCenter - 57
	wire2.y = act.yCenter - 150

	local wire2Button = widget.newButton
	{
	    x = wire2.x,
	    y = wire2.y,
	    shape = "polygon",
		fillColor = { default={ 0, 0, 0, 0.01 }, over={ 0, 0, 0, 0.01 } },
		vertices = { -158, -179, 13, -175, 43, -157, 52, -117, 33, -117, 5, -157, -158, -160 },
	    onEvent = wireTouch
	}

	-- wire3 image sheet---------------------------------------------------------------------------------------------------------------
	local wire3Options =
	{
		width = 290,
		height = 155,
		numFrames = 2,
	}
	local wire3Sequence =
	{
		name = wire3,
		start = 1,
		count = 2,
	}
	local wire3ImageSheet = graphics.newImageSheet( "media/wireCut/wire3sheet.png", wire3Options )
	local wire3 = display.newSprite( act.group, wire3ImageSheet, wire3Sequence )
	wire3:setSequence( "wire3" )
	wire3:scale ( 0.35, 0.35 )
	wire3.x = act.xCenter - 120
	wire3.y = act.yCenter - 93

	-- wire4 image sheet---------------------------------------------------------------------------------------------------------------
	local wire4Options =
	{
		width = 535,
		height = 508,
		numFrames = 2,
	}
	local wire4Sequence =
	{
		name = wire4,
		start = 1,
		count = 2,
	}
	local wire4ImageSheet = graphics.newImageSheet( "media/wireCut/wire4sheet.png", wire4Options )
	local wire4 = display.newSprite( act.group, wire4ImageSheet, wire4Sequence )
	wire4:setSequence( "wire4" )
	wire4:scale ( 0.35, 0.35 )
	wire4.x = act.xCenter - 70
	wire4.y = act.yCenter - 6

	-- wire5 image sheet---------------------------------------------------------------------------------------------------------------
	local wire5Options =
	{
		width = 236,
		height = 538,
		numFrames = 2,
	}
	local wire5Sequence =
	{
		name = wire5,
		start = 1,
		count = 2,
	}
	local wire5ImageSheet = graphics.newImageSheet( "media/wireCut/wire5sheet.png", wire5Options )
	local wire5 = display.newSprite( act.group, wire5ImageSheet, wire5Sequence )
	wire5:setSequence( "wire5" )
	wire5:scale ( 0.35, 0.35 )
	wire5.x = act.xCenter - 91
	wire5.y = act.yCenter + 14

	-- wire6 image sheet---------------------------------------------------------------------------------------------------------------
	local wire6Options =
	{
		width = 570,
		height = 261,
		numFrames = 2,
	}
	local wire6Sequence =
	{
		name = wire6,
		start = 1,
		count = 2,
	}
	local wire6ImageSheet = graphics.newImageSheet( "media/wireCut/wire6sheet.png", wire6Options )
	local wire6 = display.newSprite( act.group, wire6ImageSheet, wire6Sequence )
	wire6:setSequence( "wire6" )
	wire6:scale ( 0.35, 0.35 )
	wire6.x = act.xCenter - 69
	wire6.y = act.yCenter + 48

	-- wire7 image sheet---------------------------------------------------------------------------------------------------------------
	local wire7Options =
	{
		width = 159,
		height = 247,
		numFrames = 2,
	}
	local wire7Sequence =
	{
		name = wire7,
		start = 1,
		count = 2,
	}
	local wire7ImageSheet = graphics.newImageSheet( "media/wireCut/wire7sheet.png", wire7Options )
	local wire7 = display.newSprite( act.group, wire7ImageSheet, wire7Sequence )
	wire7:setSequence( "wire7" )
	wire7:scale ( 0.35, 0.35 )
	wire7.x = act.xCenter + 24
	wire7.y = act.yCenter - 40

	-- wire8 image sheet---------------------------------------------------------------------------------------------------------------
	local wire8Options =
	{
		width = 275,
		height = 194,
		numFrames = 2,
	}
	local wire8Sequence =
	{
		name = wire8,
		start = 1,
		count = 2,
	}
	local wire8ImageSheet = graphics.newImageSheet( "media/wireCut/wire8sheet.png", wire8Options )
	local wire8 = display.newSprite( act.group, wire8ImageSheet, wire8Sequence )
	wire8:setSequence( "wire8" )
	wire8:scale ( 0.35, 0.35 )
	wire8.x = act.xCenter - 20
	wire8.y = act.yCenter + 131

	-- wire9 image sheet---------------------------------------------------------------------------------------------------------------
	local wire9Options =
	{
		width = 248,
		height = 121,
		numFrames = 2,
	}
	local wire9Sequence =
	{
		name = wire9,
		start = 1,
		count = 2,
	}
	local wire9ImageSheet = graphics.newImageSheet( "media/wireCut/wire9sheet.png", wire9Options )
	local wire9 = display.newSprite( act.group, wire9ImageSheet, wire9Sequence )
	wire9:setSequence( "wire9" )
	wire9:scale ( 0.35, 0.35 )
	wire9.x = act.xCenter + 85
	wire9.y = act.yCenter - 91

	-- wire10 image sheet---------------------------------------------------------------------------------------------------------------
	local wire10Options =
	{
		width = 253,
		height = 126,
		numFrames = 2,
	}
	local wire10Sequence =
	{
		name = wire10,
		start = 1,
		count = 2,
	}
	local wire10ImageSheet = graphics.newImageSheet( "media/wireCut/wire10sheet.png", wire10Options )
	local wire10 = display.newSprite( act.group, wire10ImageSheet, wire10Sequence )
	wire10:setSequence( "wire10" )
	wire10:scale ( 0.35, 0.35 )
	wire10.x = act.xCenter + 85
	wire10.y = act.yCenter - 1

	-- wire11 image sheet---------------------------------------------------------------------------------------------------------------
	local wire11Options =
	{
		width = 256,
		height = 128,
		numFrames = 2,
	}
	local wire11Sequence =
	{
		name = wire11,
		start = 1,
		count = 2,
	}
	local wire11ImageSheet = graphics.newImageSheet( "media/wireCut/wire11sheet.png", wire11Options )
	local wire11 = display.newSprite( act.group, wire11ImageSheet, wire11Sequence )
	wire11:setSequence( "wire11" )
	wire11:scale ( 0.35, 0.35 )
	wire11.x = act.xCenter + 85
	wire11.y = act.yCenter + 90

	-- led image sheet-------------------------------------------------------------------------------------------------------------------
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

	-- or gate image sheet -------------------------------------------------------------------------------------------------------
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

	local orBL = display.newSprite( act.group, orGateImageSheet, orGateSequence )
	orBL:setSequence( "orGate" )
	orBL:scale(0.3, 0.3)
	orBL.x = act.xCenter - 60
	orBL.y = act.yCenter + 90

	-- and gate image sheet -----------------------------------------------------------------------------------------------------------------
	local andGateOptions =
	{
	    width = 125,
	    height = 130,
	    numFrames = 4,
	}
	local andGateSequence = 
	{
		name = andGate,
		start = 1,
		count = 4,
	}
	local andGateImageSheet = graphics.newImageSheet( "media/wireCut/andGateSheet.png", andGateOptions )

	local andTop = display.newSprite( act.group, andGateImageSheet, andGateSequence )
	andTop:setSequence( "andGate" )
	andTop:scale( 0.5, 0.5 )
	andTop.x = act.xCenter + 40
	andTop.y = act.yCenter

	local andBottom = display.newSprite( act.group, andGateImageSheet, andGateSequence )
	andBottom:setSequence( "andGate" )
	andBottom:scale( 0.5, 0.5 )
	andBottom.x = act.xCenter + 40
	andBottom.y = act.yCenter + 90

	-- background mask
	local wireCutBGMask = act:newImage ( "wireCutBGMask.png", { width = 320 } )
	wireCutBGMask.y = act.yCenter + 10
	wireCutBGMask.x = act.xCenter - 4

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

	-- Touch location text display objects==============================================================================================
	local yText = act.yMin + 15   -- relative to actual top of screen
	xyText = display.newText( act.group, "", act.width / 3, yText, native.systemFont, 14 )
	xyCenterText = display.newText( act.group, "", act.width * 2 / 3, yText, native.systemFont, 14 )

end

------------------------- End of Activity --------------------------------------------------------

-- Corona needs the scene object returned from the act file
return act.scene