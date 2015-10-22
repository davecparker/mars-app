
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
--local xyText		-- text display object for touch location =======================================================================
local wireImage
local wire1, wire2, wire3, wire4, wire5, wire6, wire7, wire8, wire9, wire10, wire11  -- wires
local orTL, orTR, orBL                -- or gates
local andTop, andBottom              -- and gates
local ledTop, ledMid, ledBottom      -- LEDs
------------------------- Functions -------------------------------------------------------

-- function to send you back when you press the back button
local function backButtonPress ( event )
	game.gotoAct ( "mainAct" )
end

-- checks the state of the game and what wires have been cut
local function checkState ()
	-- orGateTL logic
	if wire1.isCut == true and wire3.isCut == true and wire4.isCut == true then
		orTL:setFrame( 2 )
	else
		orTL:setFrame( 1 )
	end
	-- orGateTR
	if wire2.isCut == true and wire4.isCut == true then
		orTR:setFrame( 2 )
		ledTop:setFrame ( 2 )
		print( ledTop.frame )
	else
		orTR:setFrame( 1 )
		ledTop:setFrame ( 1 )
	end
	-- orGateBL
	if (wire5.isCut == true or orTL.frame == 2) and wire4.isCut == true then
		orBL:setFrame( 2 )
	else
		orBL:setFrame( 1 )
	end
	-- andTop
	if (orTR.frame == 2 or wire7.isCut == true) and wire6.isCut == true then
		andTop:setFrame( 4 )
		ledMid:setFrame( 2 )
	elseif wire6.isCut == true then
		andTop:setFrame( 2 )
		ledMid:setFrame( 1 )
	elseif orTR.frame == 2 or wire7.isCut == true then 
		andTop:setFrame( 3 )
		ledMid:setFrame( 1 )
	else
		andTop:setFrame( 1 )
		ledMid:setFrame( 1 )
	end
	-- andBottom
	if wire6.isCut == true and (wire8.isCut == true or orBL.frame == 2) then
		andBottom:setFrame( 4 )
		ledBottom:setFrame( 2 )
	elseif wire6.isCut == true then
		andBottom:setFrame( 3 )
		ledBottom:setFrame( 1 )
	elseif wire8.isCut == true or orBL.frame == 2 then
		andBottom:setFrame( 2 )
		ledBottom:setFrame( 1 )
	else
		andBottom:setFrame( 1 )
		ledBottom:setFrame( 1 )
	end

end

-- function for cutting the wire
local function wireTouch ( event )
	local w = event.target
	if event.phase == "began" then
		if w.wire.isCut == false then
			w.wire:setFrame( 2 )
			w.wire.isCut = true
		else
			w.wire:setFrame( 1 )
			w.wire.isCut = false
		end
	end
	checkState ()  -- check the state of the game
	return true
end

-- wire button creator
local function wireButtonCreator ( obj, xPos, yPos, xSize, ySize )
	local w = display.newRect( act.group, xPos, yPos, xSize, ySize )
	w.alpha = 0.01
	w:addEventListener( "touch", wireTouch )
	w.wire = obj
	return w

end

-- function for common wire creatation code
local function wireSet (w, x, y)
	w:scale ( 0.35, 0.35 )
	w.x = act.xCenter + x
	w.y = act.yCenter + y
	w.isCut = false
	return w
end




-- Handle touches on the background by updating the text displays=============================================================
--local function touched( event )
--	-- Get touch location but pin to the act bounds
--	local x = game.pinValue( event.x, act.xMin, act.xMax )
--	local y = game.pinValue( event.y, act.yMin, act.yMax )

	-- Update the absolute and center-relative coordinate displays
--	xyText.text = string.format( "(%d, %d)", x, y )
--	xyCenterText.text = string.format( "Center + (%d, %d)", x - act.xCenter, y - act.yCenter )
--end


------------------------- Start of Activity ----------------------------------------------------

-- Init the act
function act:init()

	-- background image
	local wireCutBG = act:newImage ( "wireCutBG.jpg", { width = 320} )
	wireCutBG.y = act.yCenter + 10
	wireCutBG.x = act.xCenter - 4
	--wireCutBG:addEventListener( "touch", touched )--====================================================================================

	-- wire1 image sheet---------------------------------------------------------------------------------------------------------------
	local wire1Options = { width = 110, height = 404, numFrames = 2 }
	local wire1Sequence = { start = 1, count = 2 }
	local wire1ImageSheet = graphics.newImageSheet( "media/wireCut/wire1sheet.png", wire1Options )
	wire1 = display.newSprite( act.group, wire1ImageSheet, wire1Sequence )
	wireSet ( wire1, -65, -160 )

	-- wire cutting buttons 
	wire1.button1 = wireButtonCreator ( wire1, act.xCenter - 66, act.yCenter - 164, 30, 100)

	-- wire2 image sheet---------------------------------------------------------------------------------------------------------------
	local wire2Options = { width = 630, height = 253, numFrames = 2 }
	local wire2Sequence = { start = 1, count = 2 }
	local wire2ImageSheet = graphics.newImageSheet( "media/wireCut/wire2sheet.png", wire2Options )
	wire2 = display.newSprite( act.group, wire2ImageSheet, wire2Sequence )
	wireSet ( wire2, -57, -150 )

	-- wire cutting buttons 
	wire2.button1 = wireButtonCreator ( wire2, act.xCenter - 65, act.yCenter - 166, 185, 20)
	wire2.button1 = wireButtonCreator ( wire2, act.xCenter + 32, act.yCenter - 143, 30, 50)

	-- wire3 image sheet---------------------------------------------------------------------------------------------------------------
	local wire3Options = { width = 290, height = 155, numFrames = 2 }
	local wire3Sequence = { name = wire3, start = 1, count = 2 }
	local wire3ImageSheet = graphics.newImageSheet( "media/wireCut/wire3sheet.png", wire3Options )
	wire3 = display.newSprite( act.group, wire3ImageSheet, wire3Sequence )
	wireSet ( wire3, -120, -93 )

	-- wire cutting buttons 
	wire3.button1 = wireButtonCreator ( wire3, act.xCenter - 124, act.yCenter - 90, 80, 20)

	-- wire4 image sheet---------------------------------------------------------------------------------------------------------------
	local wire4Options = { width = 535, height = 508, numFrames = 2 }
	local wire4Sequence = { name = wire4, start = 1, count = 2 }
	local wire4ImageSheet = graphics.newImageSheet( "media/wireCut/wire4sheet.png", wire4Options )
	wire4 = display.newSprite( act.group, wire4ImageSheet, wire4Sequence )
	wireSet ( wire4, -70, -6 )
	
	-- wire cutting buttons 
	wire4.button1 = wireButtonCreator ( wire4, act.xCenter - 110, act.yCenter + 5, 100, 20)
	wire4.button1 = wireButtonCreator ( wire4, act.xCenter - 67, act.yCenter + 35, 30, 60)
	wire4.button1 = wireButtonCreator ( wire4, act.xCenter - 49, act.yCenter - 5, 30, 20)
	wire4.button1 = wireButtonCreator ( wire4, act.xCenter - 14, act.yCenter - 50, 40, 100)

	-- wire5 image sheet---------------------------------------------------------------------------------------------------------------
	local wire5Options = { width = 236, height = 538, numFrames = 2 }
	local wire5Sequence = { name = wire5, start = 1, count = 2 }
	local wire5ImageSheet = graphics.newImageSheet( "media/wireCut/wire5sheet.png", wire5Options )
	wire5 = display.newSprite( act.group, wire5ImageSheet, wire5Sequence )
	wireSet ( wire5, -91, 14 )

	--wire cutting buttons 
	wire5.button1 = wireButtonCreator ( wire5, act.xCenter - 62, act.yCenter - 40, 20, 40)
	wire5.button2 = wireButtonCreator ( wire5, act.xCenter - 68, act.yCenter - 17, 20, 20)
	wire5.button3 = wireButtonCreator ( wire5, act.xCenter - 78, act.yCenter - 2, 20, 20)
	wire5.button4 = wireButtonCreator ( wire5, act.xCenter - 88, act.yCenter + 9, 20, 20)
	wire5.button5 = wireButtonCreator ( wire5, act.xCenter - 100, act.yCenter + 16, 20, 20)
	wire5.button6 = wireButtonCreator ( wire5, act.xCenter - 119, act.yCenter + 54, 20, 80)
	wire5.button7 = wireButtonCreator ( wire5, act.xCenter - 98, act.yCenter + 89, 40, 20)
	
	-- wire6 image sheet---------------------------------------------------------------------------------------------------------------
	local wire6Options = { width = 570, height = 261, numFrames = 2 }
	local wire6Sequence = { name = wire6, start = 1, count = 2 }
	local wire6ImageSheet = graphics.newImageSheet( "media/wireCut/wire6sheet.png", wire6Options )
	wire6 = display.newSprite( act.group, wire6ImageSheet, wire6Sequence )
	wireSet ( wire6, -69, 48 )

	-- wire cutting buttons 
	wire6.button1 = wireButtonCreator ( wire6, act.xCenter - 90, act.yCenter + 49, 135, 20)
	wire6.button1 = wireButtonCreator ( wire6, act.xCenter - 3, act.yCenter + 45, 40, 80)

	-- wire7 image sheet---------------------------------------------------------------------------------------------------------------
	local wire7Options = { width = 159, height = 247, numFrames = 2 }
	local wire7Sequence = { name = wire7, start = 1, count = 2 }
	local wire7ImageSheet = graphics.newImageSheet( "media/wireCut/wire7sheet.png", wire7Options )
	wire7 = display.newSprite( act.group, wire7ImageSheet, wire7Sequence )
	wireSet ( wire7, 24, -40 )

	-- wire cutting buttons 
	wire7.button1 = wireButtonCreator ( wire7, act.xCenter + 10, act.yCenter - 30, 20, 40)
	wire7.button1 = wireButtonCreator ( wire7, act.xCenter + 32, act.yCenter - 52, 30, 30)

	-- wire8 image sheet---------------------------------------------------------------------------------------------------------------
	local wire8Options = { width = 275, height = 194, numFrames = 2 }
	local wire8Sequence = { name = wire8, start = 1, count = 2 }
	local wire8ImageSheet = graphics.newImageSheet( "media/wireCut/wire8sheet.png", wire8Options )
	wire8 = display.newSprite( act.group, wire8ImageSheet, wire8Sequence )
	wireSet ( wire8, -20, 131 )

	-- wire cutting buttons 
	wire8.button1 = wireButtonCreator ( wire8, act.xCenter - 21, act.yCenter + 128, 90, 50)

	-- wire9 image sheet---------------------------------------------------------------------------------------------------------------
	local wire9Options = { width = 248, height = 121, numFrames = 2 }
	local wire9Sequence = { name = wire9, start = 1, count = 2 }
	local wire9ImageSheet = graphics.newImageSheet( "media/wireCut/wire9sheet.png", wire9Options )
	wire9 = display.newSprite( act.group, wire9ImageSheet, wire9Sequence )
	wireSet ( wire9, 85, -91 )

	-- wire10 image sheet---------------------------------------------------------------------------------------------------------------
	local wire10Options = { width = 253, height = 126, numFrames = 2 }
	local wire10Sequence = { name = wire10, start = 1, count = 2 }
	local wire10ImageSheet = graphics.newImageSheet( "media/wireCut/wire10sheet.png", wire10Options )
	wire10 = display.newSprite( act.group, wire10ImageSheet, wire10Sequence )
	wireSet ( wire10, 85, -1 )

	-- wire11 image sheet---------------------------------------------------------------------------------------------------------------
	local wire11Options = { width = 256, height = 128, numFrames = 2 }
	local wire11Sequence = { name = wire11, start = 1, count = 2 }
	local wire11ImageSheet = graphics.newImageSheet( "media/wireCut/wire11sheet.png", wire11Options )
	wire11 = display.newSprite( act.group, wire11ImageSheet, wire11Sequence )
	wireSet ( wire11, 85, 90 )

	-- led image sheet-------------------------------------------------------------------------------------------------------------------
	local ledOptions = { width = 249, height = 252, numFrames = 2 }
	local ledSequence = { start = 1, count = 2 }
	local ledImageSheet = graphics.newImageSheet( "media/wireCut/ledSheet.png", ledOptions )

	-- function to make the and gates
	local function ledMaker( x, y )
		local l = display.newSprite( act.group, ledImageSheet, ledSequence )
		l:scale( 0.3, 0.3 )
		l.x = act.xMax + x
		l.y = act.yCenter + y
		return l
	end

	-- create top led sprites
	ledTop = ledMaker ( -31, -90 )
	ledMid = ledMaker ( -31, 0 )
	ledBottom = ledMaker ( -31, 90 )

	-- or gate image sheet -------------------------------------------------------------------------------------------------------
	local orGateOptions = { width = 258, height = 238, numFrames = 2 }
	local orGateSequence = { start = 1, count = 2 }
	local orGateImageSheet = graphics.newImageSheet( "media/wireCut/orGateSheet.png", orGateOptions )

	-- function to make the or gates
	local function orMaker( x, y )
		local o = display.newSprite( act.group, orGateImageSheet, orGateSequence )
		o:scale( 0.3, 0.3 )
		o.x = act.xCenter + x
		o.y = act.yCenter + y
		return o
	end

	-- create the or gates
	orTL = orMaker ( -60, -90 )
	orTR = orMaker ( 40, -90 )
	orBL = orMaker ( -60, 90 )

	-- and gate image sheet -----------------------------------------------------------------------------------------------------------------
	local andGateOptions = { width = 125, height = 130, numFrames = 4 }
	local andGateSequence = { start = 1, count = 4 }
	local andGateImageSheet = graphics.newImageSheet( "media/wireCut/andGateSheet.png", andGateOptions )

	-- function to make the and gates
	local function andMaker( x, y )
		local a = display.newSprite( act.group, andGateImageSheet, andGateSequence )
		a:scale( 0.5, 0.5 )
		a.x = act.xCenter + x
		a.y = act.yCenter + y
		return a
	end

	-- make the and gates
	andTop = andMaker( 40, 0 )
	andBottom = andMaker ( 40, 90 )

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
	--local yText = act.yMin + 15   -- relative to actual top of screen
	--xyText = display.newText( act.group, "", act.width / 3, yText, native.systemFont, 14 )
	--xyCenterText = display.newText( act.group, "", act.width * 2 / 3, yText, native.systemFont, 14 )

end

------------------------- End of Activity --------------------------------------------------------

-- Corona needs the scene object returned from the act file
return act.scene