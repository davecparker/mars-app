
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
local wireCutVersion = 1 -- this is the version of wire cut to be used
local wireImage
local wire1, wire2, wire3, wire4, wire5, wire6, wire7, wire8, wire9, wire10, wire11  -- wires
local orTL, orTR, orBL                -- or gates
local andTop, andBottom               -- and gates
local ledTop, ledMid, ledBottom       -- LEDs
local toolbox
local backButton
local toolWindow
local toolIcon 							-- the tool selected icon
local tapeSelected = false
local wireCutterSelected = false
local manual  
local manualPage						-- what page of the manual you are on
local gameOver = false
local timeLeft							-- amount of seconds left
local gameTimer 						-- if this timer runs out you lose
local gameTimerDisplay					-- text that displays how much time is left
local outOfTime = false 				-- bollean that says whether you've run out of time
local countDownReset
local resetBtn
local actGroup
-- audio
local cutSFX
local tapeSFX
local toolboxSFX
local panelSFX

------------------------- Functions -------------------------------------------------------

-- function to send you back when you press the back button
local function backButtonPress ( event )
	game.gotoAct ( "mainAct" )
end

-- function to remove everything when the toolbox closes
local function toolBoxClose ()
	toolWindow.wrenchButton:removeSelf()
	toolWindow.wrenchButton = nil
	toolWindow.wireCutterhButton:removeSelf()
	toolWindow.wireCutterhButton = nil
	toolWindow.tapeButton:removeSelf()
	toolWindow.tapeButton = nil
	toolWindow.manualButton:removeSelf()
	toolWindow.manualButton = nil
	toolWindow:removeSelf()
	toolWindow = nil

	timer.resume(gameTimer)
end

-- sets the icon over the toolbox
local function setToolIcon ( tool)
	if toolIcon then
		toolIcon:setFrame( tool )
	else
		-- toolbox selection icon
		local toolboxIconOptions = { width = 100, height = 100, numFrames = 3 } 
		local toolboxIconSequence = { name = "icon", start = 1, count = 3 }
		local toolboxIconImageSheet = graphics.newImageSheet( "media/circuit/toolBoxIcon.png", toolboxIconOptions ) 
		toolIcon = display.newSprite( act.group, toolboxIconImageSheet, toolboxIconSequence )
		toolIcon:setFrame( tool )
		toolIcon.x = act.xMax - 30
		toolIcon.y = act.yMin + 30
		toolIcon:scale( 0.5, 0.5 )
		toolbox.alpha = 0.2
	end
	toolBoxClose()
end

-- got to the next page in the manual
local function nextPage ( event )
	--local manual = event.target
	if event.phase == "ended" then
		manualPage = manualPage + 1
		if manualPage > 3 then
			manual:removeSelf( ) 
			manual = nil
		else
			manual:setFrame( manualPage )
		end
	end
	return true
end

-- controls what happnes when you touch the manual
local function manualTouch ( event )
	if event.phase == "ended" then
		-- manual image sheets to be used, set to 1 for debug mode
		local param = 1
		local manualVersion = {"manual.png", "manual2.png", "manual3.png", "manual4.png"}
		if game.actParam then
			param = game.actParam
		end
		local manualOptions = { width = 440, height = 600, numFrames = 3 }
		local manualSequence = { name = manual, start = 1, count = 3 }
		local manualImageSheet = graphics.newImageSheet( "media/circuit/" .. manualVersion[param], manualOptions )
		manual = display.newSprite( act.group, manualImageSheet, manualSequence )
		manual.x = act.xCenter
		manual.y = act.yCenter
		manual:scale( 0.7, 0.7 )
		manualPage = 1
		manual:addEventListener( "touch", nextPage )
		toolBoxClose()
	end 
	return true
end

-- wire cutter is touched
local function wireCutterTouch ( event )
	if event.phase == "ended" then
		local toolIcon = setToolIcon(3)
		wireCutterSelected = true
		tapeSelected = false
	end
end

-- tape is touched
local function tapeTouch ( event )
	if event.phase == "ended" then
		local toolIcon = setToolIcon(2)
		wireCutterSelected = false
		tapeSelected = true
	end
end

-- wrench is touched
local function wrenchTouch ( event )
	if event.phase == "ended" then
		local toolIcon = setToolIcon(1)
		wireCutterSelected = false
		tapeSelected = false
	end
end

-- function for the toolbox touch
local function toolboxTouch (event) 
	if event.phase == "began" then
		game.playSound (toolboxSFX)
		if toolWindow == nil then
			if manual then     -- remove the manual if its up
				manual:removeSelf( )
				manual = nil
			end
			toolWindow = act:newImage ( "toolboxInside.png", { width = 300, folder = "media/circuit" } )
			toolWindow.x = act.xCenter
			toolWindow.y = act.yCenter
			-- wrench button
			toolWindow.wrenchButton = widget.newButton { width = 100, height = 120, onEvent = wrenchTouch }
			toolWindow.wrenchButton.x = act.xCenter - 80
			toolWindow.wrenchButton.y = act.yCenter - 80
			toolWindow.wrenchButton.isVisible = false
			toolWindow.wrenchButton.isHitTestable = true
			-- wire cutter button
			toolWindow.wireCutterhButton = widget.newButton { width = 100, height = 120, onEvent = wireCutterTouch }
			toolWindow.wireCutterhButton.x = act.xCenter + 55
			toolWindow.wireCutterhButton.y = act.yCenter - 80
			toolWindow.wireCutterhButton.isVisible = false
			toolWindow.wireCutterhButton.isHitTestable = true
			-- tape button
			toolWindow.tapeButton = widget.newButton { width = 100, height = 120, onEvent = tapeTouch }
			toolWindow.tapeButton.x = act.xCenter - 80
			toolWindow.tapeButton.y = act.yCenter + 60
			toolWindow.tapeButton.isVisible = false
			toolWindow.tapeButton.isHitTestable = true
			-- manual button
			toolWindow.manualButton = widget.newButton { width = 80, height = 110, onEvent = manualTouch }
			toolWindow.manualButton.x = act.xCenter + 60
			toolWindow.manualButton.y = act.yCenter + 60
			toolWindow.manualButton.isVisible = false
			toolWindow.manualButton.isHitTestable = true

			-- pause the timer
			timer.pause(gameTimer)
		end
	end
	return true
end

-- fade out to next part of game
local function endFade ()
	--game.playSound(panelSFX)
	game.panelFixed = true
	game.gotoAct ( "mainAct", { effect = "fade", time = 100 } )
end

-- play the sound effect for the panel after a delay
local function panelSound ()
	timer.performWithDelay( 900, 
				function () 
					game.playSound(panelSFX) 
				end )
end

-- end of act function
local function endAct()
	gameOver = true
	local panel = act:newImage( "panel.png", { width = 440, folder = "media/circuit" } )
	panel.x = act.xMax + 450
	panel.y = act.yCenter - 15
	backButton:removeSelf( )
	backButton = nil
	toolbox:removeSelf( )
	toolbox = nil
	toolIcon:removeSelf( )
	toolIcon = nil
	transition.to( panel, { time = 1000, transition = easing.outSine, x = act.xCenter - 3, delay = 500, onStart = panelSound } )
	transition.scaleBy( act.group, { xScale = -0.5, yScale = -0.5, time = 2000 } )
	transition.to( act.group, { time = 2002, x = game.xCenter / 2, y = game.yCenter / 2 - 20, onComplete = endFade } )
	timer.cancel(gameTimer)
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
	-- vicotory condition version 1
	if ledTop.frame == 2 and ledMid.frame == 2 and ledBottom.frame == 1 and game.actParam == 1 then
		endAct()
	end
	-- vicotory condition version 2
	if ledTop.frame == 1 and ledMid.frame == 2 and ledBottom.frame == 2 and game.actParam == 2 then
		endAct()
	end
	-- vicotory condition version 3
	if ledTop.frame == 1 and ledMid.frame == 1 and ledBottom.frame == 2 and game.actParam == 3 then
		endAct()
	end
	-- vicotory condition version 4
	if ledTop.frame == 1 and ledMid.frame == 2 and ledBottom.frame == 1 and game.actParam == 4 then
		endAct()
	end
	-- vicotory condition version debug version
	if ledTop.frame == 2 and ledMid.frame == 2 and ledBottom.frame == 1 and game.actParam == nil then
		endAct()
	end
end

-- function for cutting the wire
local function wireTouch ( event )
	if gameOver then
		-- if game over is true disable this funciton
	else
		local w = event.target
		if event.phase == "ended" then
			if w.wire.isCut == false and wireCutterSelected == true then-- ========================================================================================
				w.wire:setFrame( 2 )
				w.wire.isCut = true
				game.playSound (cutSFX)
			elseif w.wire.isCut == true and tapeSelected == true then
				w.wire:setFrame( 1 )
				w.wire.isCut = false
				game.playSound (tapeSFX)
			end
		end
		checkState ()  -- check the state of the game
	end
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

-- function for the uncutable wires
local function wireNoCut ( x, y )
	local w = act:newImage ( "NoCutWire.png", { width = 251 / 3 } )
	w.x = act.xCenter + x
	w.y = act.yCenter + y
	return w
end

-- function for closing the toolbox by touching the screen
local function bgTouch (event) 
	if event.phase == "began" then
		if toolWindow then
			toolBoxClose()
		end
		if manual then     -- remove the manual if its up
			manual:removeSelf( )
			manual = nil
		end
	end
end

-- function that ticks the seconds left
local function timeTick()
	timeLeft = timeLeft - 1
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
	local wireCutBG = act:newImage ( "wireCutBG2.jpg", { width = 320} )
	wireCutBG:addEventListener( "touch", bgTouch )
	wireCutBG.y = act.yCenter + 20
	wireCutBG.x = act.xCenter
	--wireCutBG:addEventListener( "touch", touched )--====================================================================================

	-- wire1 image sheet---------------------------------------------------------------------------------------------------------------
	local wire1Options = { width = 110, height = 404, numFrames = 2 }
	local wire1Sequence = { start = 1, count = 2 }
	local wire1ImageSheet = graphics.newImageSheet( "media/wireCut/WHITEwire01.png", wire1Options )
	wire1 = display.newSprite( act.group, wire1ImageSheet, wire1Sequence )
		wire1:setFillColor(0.2,0.9,0.2)
	wireSet ( wire1, -65, -150 )

	-- wire cutting buttons 
	wire1.button1 = wireButtonCreator ( wire1, act.xCenter - 66, act.yCenter - 144, 30, 100)

	-- wire2 image sheet---------------------------------------------------------------------------------------------------------------
	local wire2Options = { width = 630, height = 253, numFrames = 2 }
	local wire2Sequence = { start = 1, count = 2 }
	local wire2ImageSheet = graphics.newImageSheet( "media/wireCut/WHITEwire02.png", wire2Options )
	wire2 = display.newSprite( act.group, wire2ImageSheet, wire2Sequence )
		wire2:setFillColor(0.2,0.9,0.2)
	wireSet ( wire2, -57, -130 )

	-- wire cutting buttons 
	wire2.button1 = wireButtonCreator ( wire2, act.xCenter - 65, act.yCenter - 146, 185, 20)
	wire2.button1 = wireButtonCreator ( wire2, act.xCenter + 32, act.yCenter - 123, 30, 50)

	-- wire3 image sheet---------------------------------------------------------------------------------------------------------------
	local wire3Options = { width = 290, height = 155, numFrames = 2 }
	local wire3Sequence = { name = wire3, start = 1, count = 2 }
	local wire3ImageSheet = graphics.newImageSheet( "media/wireCut/WHITEwire03.png", wire3Options )
	wire3 = display.newSprite( act.group, wire3ImageSheet, wire3Sequence )
		wire3:setFillColor(0.2,0.9,0.2)
	wireSet ( wire3, -120, -73 )

	-- wire cutting buttons 
	wire3.button1 = wireButtonCreator ( wire3, act.xCenter - 124, act.yCenter - 70, 80, 20)

	-- wire4 image sheet---------------------------------------------------------------------------------------------------------------
	local wire4Options = { width = 535, height = 508, numFrames = 2 }
	local wire4Sequence = { name = wire4, start = 1, count = 2 }
	local wire4ImageSheet = graphics.newImageSheet( "media/wireCut/WHITEwire04.png", wire4Options )
	wire4 = display.newSprite( act.group, wire4ImageSheet, wire4Sequence )
		wire4:setFillColor(0.2,0.9,0.2)
	wireSet ( wire4, -70, 14 )
	
	-- wire cutting buttons 
	wire4.button1 = wireButtonCreator ( wire4, act.xCenter - 110, act.yCenter + 25, 100, 20)
	wire4.button1 = wireButtonCreator ( wire4, act.xCenter - 67, act.yCenter + 55, 30, 60)
	wire4.button1 = wireButtonCreator ( wire4, act.xCenter - 49, act.yCenter + 15, 30, 20)
	wire4.button1 = wireButtonCreator ( wire4, act.xCenter - 14, act.yCenter - 30, 40, 100)

	-- wire5 image sheet---------------------------------------------------------------------------------------------------------------
	local wire5Options = { width = 236, height = 538, numFrames = 2 }
	local wire5Sequence = { name = wire5, start = 1, count = 2 }
	local wire5ImageSheet = graphics.newImageSheet( "media/wireCut/WHITEwire05.png", wire5Options )
	wire5 = display.newSprite( act.group, wire5ImageSheet, wire5Sequence )
		wire5:setFillColor(0.9,0.2,0.2)
	wireSet ( wire5, -91, 34 )

	--wire cutting buttons 
	wire5.button1 = wireButtonCreator ( wire5, act.xCenter - 62, act.yCenter - 20, 20, 40)
	wire5.button2 = wireButtonCreator ( wire5, act.xCenter - 68, act.yCenter + 3, 20, 20)
	wire5.button3 = wireButtonCreator ( wire5, act.xCenter - 78, act.yCenter + 18, 20, 20)
	wire5.button4 = wireButtonCreator ( wire5, act.xCenter - 88, act.yCenter + 29, 20, 20)
	wire5.button5 = wireButtonCreator ( wire5, act.xCenter - 100, act.yCenter + 36, 20, 20)
	wire5.button6 = wireButtonCreator ( wire5, act.xCenter - 119, act.yCenter + 74, 20, 80)
	wire5.button7 = wireButtonCreator ( wire5, act.xCenter - 98, act.yCenter + 109, 40, 20)
	
	-- wire6 image sheet---------------------------------------------------------------------------------------------------------------
	local wire6Options = { width = 570, height = 261, numFrames = 2 }
	local wire6Sequence = { name = wire6, start = 1, count = 2 }
	local wire6ImageSheet = graphics.newImageSheet( "media/wireCut/WHITEwire06.png", wire6Options )
	wire6 = display.newSprite( act.group, wire6ImageSheet, wire6Sequence )
		wire6:setFillColor(0.2,0.9,0.2)
	wireSet ( wire6, -69, 68 )

	-- wire cutting buttons 
	wire6.button1 = wireButtonCreator ( wire6, act.xCenter - 90, act.yCenter + 69, 135, 20)
	wire6.button1 = wireButtonCreator ( wire6, act.xCenter - 3, act.yCenter + 65, 40, 80)

	-- wire7 image sheet---------------------------------------------------------------------------------------------------------------
	local wire7Options = { width = 159, height = 247, numFrames = 2 }
	local wire7Sequence = { name = wire7, start = 1, count = 2 }
	local wire7ImageSheet = graphics.newImageSheet( "media/wireCut/WHITEwire07.png", wire7Options )
	wire7 = display.newSprite( act.group, wire7ImageSheet, wire7Sequence )
		wire7:setFillColor(0.9,0.2,0.2)
	wireSet ( wire7, 24, -20 )

	-- wire cutting buttons 
	wire7.button1 = wireButtonCreator ( wire7, act.xCenter + 10, act.yCenter - 10, 20, 40)
	wire7.button1 = wireButtonCreator ( wire7, act.xCenter + 32, act.yCenter - 32, 30, 30)

	-- wire8 image sheet---------------------------------------------------------------------------------------------------------------
	local wire8Options = { width = 275, height = 194, numFrames = 2 }
	local wire8Sequence = { name = wire8, start = 1, count = 2 }
	local wire8ImageSheet = graphics.newImageSheet( "media/wireCut/WHITEwire08.png", wire8Options )
	wire8 = display.newSprite( act.group, wire8ImageSheet, wire8Sequence )
		wire8:setFillColor(0.9,0.2,0.2)
	wireSet ( wire8, -20, 151 )

	-- wire cutting buttons 
	wire8.button1 = wireButtonCreator ( wire8, act.xCenter - 21, act.yCenter + 148, 90, 50)

	-- The uncutable wires---------------------------------------------------------------------------------------------------------------
	local wire9 = wireNoCut ( 85, -68 )
	local wire10 = wireNoCut ( 85, 22 )
	local wire11 = wireNoCut ( 85, 112 )

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
	ledTop = ledMaker ( -31, -70 )
	ledMid = ledMaker ( -31, 20 )
	ledBottom = ledMaker ( -31, 110 )

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
	orTL = orMaker ( -60, -70 )
	orTR = orMaker ( 40, -70 )
	orBL = orMaker ( -60, 110 )

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
	andTop = andMaker( 40, 20 )
	andBottom = andMaker ( 40, 110 )

	-- background mask
	local wireCutBGMask = act:newImage ( "wireCutBGMask2.png", { width = 640 } )
	wireCutBGMask.y = act.yCenter + 20
	wireCutBGMask.x = act.xCenter

	-- back button
	backButton = act:newImage( "backButton.png", { width = 50, folder = "media/circuit"} )
	backButton.x = act.xMin + 30
	backButton.y = act.yMin + 30
	backButton:addEventListener( "tap", backButtonPress )

	-- toolbox icon
	toolbox = act:newImage ( "toolbox2.png", { width = 45, folder = "media/circuit" } )
	toolbox.x = act.xMax - 30
	toolbox.y = act.yMin + 30
	toolbox:addEventListener( "touch", toolboxTouch )

	-- load the sounds
	cutSFX = act:loadSound ("Cut2.wav")
	tapeSFX = act:loadSound ("Tape7.wav")
	toolboxSFX = act:loadSound ("ToolboxOpen.wav")
	panelSFX = act:loadSound ("Panel.wav")

	-- start the timer
	timeLeft = 72 -- set the amount of seconds
	gameTimer = timer.performWithDelay(1000, timeTick,0)
	gameTimerDisplay = display.newText(act.group, " ", act.xMin+12, act.yMax-22, native.systemFont, 18)
	gameTimerDisplay.anchorX = 0
	gameTimerDisplay:setFillColor(0.2,0.2,0.2)
	countDownReset = 10

	print(game.actParam)

	-- Touch location text display objects==============================================================================================
	--local yText = act.yMin + 15   -- relative to actual top of screen
	--xyText = display.newText( act.group, "", act.width / 3, yText, native.systemFont, 14 )
	--xyCenterText = display.newText( act.group, "", act.width * 2 / 3, yText, native.systemFont, 14 )

end

-- If you define act:start() it will be called when the activity starts/resumes.
function act:start()
	if gameTimer then
		timer.resume(gameTimer)
	else
		timeLeft = 72
		gameTimer = timer.performWithDelay(1000, timeTick, 0)
	end
end

-- If you define act:stop() it will be called when the activity suspends/ends.
function act:stop()
	if gameTimer then
		timer.pause(gameTimer)
	end
end

-- function that handles what happens when you lose
local function onReset()
	--reset all the wires 
	wireCutterSelected = false
	tapeSelected = false

	local w = wire1
	w:setFrame( 1 )
	w.isCut = false
	w = wire2
	w:setFrame( 1 )
	w.isCut = false
	w = wire3
	w:setFrame( 1 )
	w.isCut = false
	w = wire4
	w:setFrame( 1 )
	w.isCut = false
	w = wire5
	w:setFrame( 1 )
	w.isCut = false
	w = wire6
	w:setFrame( 1 )
	w.isCut = false
	w = wire7
	w:setFrame( 1 )
	w.isCut = false
	w = wire8
	w:setFrame( 1 )
	w.isCut = false

	--reset timer
	timeLeft = 72
	timer.resume(gameTimer)
	checkState()
	if not countDownReset then
		countDownReset = 10
	end
end

-- If you define act:enterFrame() it will be called before every animation frame.

local youLostText
function act:enterFrame()
	-- update the timer display
	gameTimerDisplay.text = ""..timeLeft
	if (timeLeft < 11) then
		gameTimerDisplay:setFillColor(0.7,0,0)
	elseif (timeLeft < 31) then
		gameTimerDisplay:setFillColor(0.7,0.7,0)
	else
		gameTimerDisplay:setFillColor(0.4,0.4,0.4)
	end

	if outOfTime == true then
		youLostText.text = "   Out of Time! \n Restarting in "..countDownReset
	end

	if timeLeft <= 0 and outOfTime == false then
		outOfTime = true
		countDownReset = 10
		timeLeft = timeLeft + 1
		timer.pause(gameTimer)
		-- show lose screen
		local bg = display.newRect(act.group, act.xCenter, act.yCenter, act.width, act.height)
		bg:setFillColor(.6)
		bg.alpha = 0.6
		transition.to(bg, {time = 9900, alpha = 1})
		youLostText = display.newText(act.group, "   Out of Time! \nRestarting in "..countDownReset, act.xCenter, act.yCenter, native.systemFont, 15)
		local blah = timer.performWithDelay( 1000, 
				function() 
					countDownReset = countDownReset-1
				end, 10)
		local function onTimeUp()
			bg:removeSelf()
			youLostText:removeSelf()
			onReset()
			outOfTime = false
			resetBtn.isVisible = false
			timer.cancel( blah )
		end
		-- make the reset btn
		resetBtn = widget.newButton({x = act.xCenter, y = act.yCenter + 36, onPress = onTimeUp,
			label = "RESET", textOnly = true})
			act.group:insert(resetBtn)
			resetBtn.isVisible = false
		timer.performWithDelay(11001, function() resetBtn.isVisible = true; end)
	end
end

------------------------- End of Activity --------------------------------------------------------

-- Corona needs the scene object returned from the act file
return act.scene