-----------------------------------------------------------------------------------------
--
-- circuit.lua
--
-- Joe Cracchiolo
-----------------------------------------------------------------------------------------
------------------------- OverHead ---------------------------------------------------------

-- Get local reference to the game globals
local game = globalGame

-- Create the act object
local act = game.newAct()
local widget = require( "widget" )  -- need to make buttons

------------------------- Variables ---------------------------------------------------------

local panelDone = false
local nutsRemoved = 0    -- the number of nuts that have been removed
local panel
local largeBG
local wrenchTurns = 0
local lastAngle          -- saves the last angle the wrench was at
local wrenchRotation = 0 -- the actual angle of the wrench
local offset = 0         -- saves an offset value for moving the panel
local toolWindow
local toolbox   
local toolIcon           -- the tool selected icon
local manual  
local manualPage         -- what page of the manual you are on
-- audio
local toolboxSFX

------------------------- Functions -------------------------------------------------------

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
end

-- sets the icon over the toolbox
local function setToolIcon ( tool)
	if toolIcon then
		toolIcon:setFrame( tool )
	else
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

-- function for selecting the wrench from the toolbox window
local function wrenchTouch ( event )
	if event.phase == "ended" then
		setToolIcon(1)
		wrenchSelected = true
	end
	return true
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
		-- manual image sheet
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
		wrenchSelected = false
	end
end

-- tape is touched
local function tapeTouch ( event )
	if event.phase == "ended" then
		local toolIcon = setToolIcon(2)
		wrenchSelected = false
	end
end

-- function for the toolbox touch
local function toolboxTouch (event) 
	if event.phase == "began" then
		game.playSound (toolboxSFX)
		if toolWindow == nil then
			if wrench then      --- remove the wrech if there is already one on screen
				wrench:removeSelf()
				wrench = nil
			end
			if manual then     -- remove the manual if its up
				manual:removeSelf( )
				manual = nil
			end
			toolWindow = act:newImage ( "toolboxInside.png", { width = 300 } )
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
		end
	end
	return true
end

-- remove the nut
local function removeNut ()
	activeNut:removeSelf()
	activeNut = nil
end

-- function for turning wrench
-- as the player moves the finger around the bolt the wrench follows
local function turnWrench ( event )
	if event.phase == "began" then
		local dx = event.x - wrench.x
		local dy = event.y - wrench.y
		display.getCurrentStage():setFocus( event.wrench )
	end
	if event.phase == "moved" then
		local dx = event.x - wrench.x
		local dy = event.y - wrench.y
		wrench.rotation = (math.atan2(dy, dx) * 180 / math.pi)

	elseif event.phase == "ended" or event.phase == "cancelled" then
		display.getCurrentStage():setFocus(nil)
	end

	-- saves the angle of the wrench
	if wrench.rotation > 0 then
		wrenchRotation = math.floor(wrench.rotation)
	else
		wrenchRotation = math.floor(wrench.rotation + 360)
	end

	-- back the wrench up if its moving in the wrong direction otherwise let it move counterclockwise
	if wrenchRotation + 30 < lastAngle then
		wrench.rotation = lastAngle

	elseif wrenchRotation > lastAngle then
		wrench.rotation = lastAngle	
	else
		lastAngle = wrenchRotation
		activeNut.rotation = wrench.rotation - 25
	end

	-- adds 1 to turn wrech upon a 360 degree rotation
	if math.floor(lastAngle) < 20 then
		lastAngle = 360
		wrenchTurns = wrenchTurns + 1
	end
	
	-- if the wrench turns a certin amount then remove the nut and wrench
	if wrenchTurns > 2 then
		if (wrenchRotation > activeNut.angle - 5) and (wrenchRotation < activeNut.angle + 5) then
			wrench:removeEventListener( "touch", turnWrench )
			transition.to( activeNut, { time = 500, y = activeNut.y + 300, transition = easing.inSine, onComplete = removeNut } )
			nutsRemoved = nutsRemoved + 1
			wrench:removeSelf()
			wrench = nil
		end
	end
	return true
end

-- function for touching the nuts (lol)
local function nutTouch ( event )
	activeNut = event.target
	lastAngle = activeNut.angle
	if event.phase == "began" then
		-- remove any  wrench that is on the screen
		if wrench then
			wrench:removeSelf()
			wrench = nil
		end
		-- create a wrench on the selected nut and reset the wrenchturns
		if wrenchSelected then
			wrench = act:newImage( "wrench.png",  { width = 150 } )
			wrench.anchorX = 0.13
			wrench.x = event.target.x  -- refrences the targets x that was touched
			wrench.y = event.target.y  -- same thing but y cord
			wrench:rotate (activeNut.angle)
			wrench:addEventListener( "touch", turnWrench )
			wrenchTurns = 0
		end
	end
end

-- function to remove the panel when all the nuts are removed
local function removePanel ( event )
	
	if nutsRemoved == 4 then
		transition.to ( panel, { time = 1000, x = panel.x + 10, transition = easing.inOutBack } )
		if event.phase == "began" then
			offset = panel.x - event.x
			panelLoose = true
		end
		if (event.phase == "moved") and (panelLoose == true ) then
			
			panel.x = event.x + offset
			if panel.x > act.xMax then
				-- move panel off screen and transition to the next part of the game
				transition.to( panel, { time = 500, x = 500, onComplete = game.gotoAct( "wireCut", "fade" ) } )
				panelDone = true
			end
			if panel.x < act.xMin then
				-- move panel off screen and transition to the next part of the game
				transition.to( panel, { time = 500, x = -220, onComplete = game.gotoAct( "wireCut", "fade" ) } )
				panelDone = true
			end
		end
		return true
	end
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

-- function to remove the Large background after the zoom
local function removeBG ( event )
	if largeBG then   -- make sure that it is still there
		largeBG:removeSelf( )  -- remove it
		largeBG = nil
	end
	return true -- prevents other things in the image from being touched
end

-- function to send you back when you press the back button
local function backButtonPress ( event )
	if game.cheatMode then
		game.panelFixed = true
	end
	game.gotoAct ( "mainAct" )
	return true
end

------------------------- Start of Activity ----------------------------------------------------

-- Init the act
function act:init()
	
	local wrenchTurns -- number of turns the wrench is making
	local activeNut   -- curent nut selected
	local adjustment = 0   -- used for rotation
	local toolWindow
	local wrench
	local wrenchSelected = false
	local button       -- invisible button for selecting some things

	local wires = act:newImage ( "wires.png", { width = 270 } )
	wires.x = act.xCenter + 5
	wires.y = act.yCenter + 15

	-- background
	local bg = act:newImage ( "background.jpg", { width = 480 / 1.5 } )
	bg:addEventListener( "touch", bgTouch )

	-- toolbox icon
	toolbox = act:newImage ( "toolbox2.png", { width = 45 } )
	toolbox.x = act.xMax - 30
	toolbox.y = act.yMin + 30
	toolbox:addEventListener( "touch", toolboxTouch )

	-- back button
	local backButton = act:newImage( "backButton.png", { width = 50 } )
	backButton.x = act.xMin + 30
	backButton.y = act.yMin + 30
	backButton:addEventListener( "tap", backButtonPress )

	-- panel
	local panelLoose = false
	panel = act:newImage( "panel.png", { width = 480 / 1.5 } )
	panel:addEventListener( "touch", removePanel )

	-- nuts
	local nut = {}
	-- top left
	nut.TL = act:newImage( "nut.png", { width = 20 } )
	nut.TL.x = act.xCenter - 94
	nut.TL.y = act.yCenter - 122
	nut.TL:addEventListener( "touch", nutTouch )
	nut.TL.angle = 45
	-- top right
	nut.TR = act:newImage( "nut.png", { width = 20 } )
	nut.TR.x = act.xCenter + 101
	nut.TR.y = act.yCenter - 124
	nut.TR:addEventListener( "touch", nutTouch )
	nut.TR.angle = 135
	-- bottom left
	nut.BL = act:newImage( "nut.png", { width = 20 } )
	nut.BL.x = act.xCenter - 95
	nut.BL.y = act.yCenter + 159
	nut.BL:addEventListener( "touch", nutTouch )
	nut.BL.angle = 315
	-- bottom right
	nut.BR = act:newImage( "nut.png", { width = 20 } )
	nut.BR.x = act.xCenter + 102
	nut.BR.y = act.yCenter + 158
	nut.BR:addEventListener( "touch", nutTouch )
	nut.BR.angle = 225

	-- load the sound
	toolboxSFX = act:loadSound ("ToolboxOpen.wav", "media/wireCut")
	
	-- Draws the large background (NEEDS TO BE LAST THING DRAWN)
	largeBG = act:newImage ( "backgroundLarge.jpg", { width = 480 / 1.5} )

	largeBG:addEventListener( "touch", removeBG )    -- added a touch event if the player wants to skip the zoom in
	transition.scaleBy( largeBG, { xScale = 0.5, yScale = 0.5, time = 2000 } )  -- this is the zoom in time controls how long this sequence is (2000 = 2 seconds)
	timer.performWithDelay( 2500, removeBG )  -- 2500 (2.5 seconds)  is the delay amount. Needs to be equal or greater to the transistion time
end

-- if this part is done then go to the next part of th game
function  act:prepare ()
	if panelDone == true then
		game.gotoAct( "wireCut" )
	end
end

------------------------- End of Activity ----------------------------------------------------------------------------------------

-- Corona needs the scene object returned from the act file
return act.scene
