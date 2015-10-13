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

local nutsRemoved = 0    -- the number of nuts that have been removed
local panel
local largeBG
local wrenchTurns = 0
local lastAngle -- saves the last angle the wrench was at
local wrenchRotation = 0 -- the actual angle of the wrench
local offset = 0         -- saves an offset value for moving the panel

------------------------- Functions -------------------------------------------------------

-- function to remove everything when the toolbox closes
local function toolBoxClose ()
	wrench.button:removeSelf()
	wrench.button = nil
	wrench:removeSelf()
	wrench = nil
	toolWindow:removeSelf()
	toolWindow = nil
end

-- function for selecting the wrench from the toolbox window
local function wrenchTouch ( event )
	if event.phase == "ended" then
		-- want to change the icon of the toolbox, maybe find a better way here
		local toolboxWrench = act:newImage ("wrenchSmall.png",  { width = 40 } )
		toolboxWrench.x = act.xMax - 30
		toolboxWrench.y = act.yMin + 30
		wrenchSelected = true
		toolBoxClose()
	end
	--return true
end

-- function for the toolbox touch
local function toolboxTouch (event) 
	if event.phase == "began" then
		if toolWindow == nil then
			if wrench then      --- remove the wrech if there is already one on screen
				wrench:removeSelf()
				wrench = nil
			end
			toolWindow = display.newRect( act.group, act.xCenter, act.yCenter, 300, 300 )
			wrench = act:newImage( "wrench.png",  { width = 120 } )
			wrench.rotation = 45
			wrench.x = act.xCenter - 80
			wrench.y = act.yCenter - 80
			wrench.button = widget.newButton { width = 100, height = 100, onEvent = wrenchTouch }
			wrench.button.x = act.xCenter - 80
			wrench.button.y = act.yCenter - 80
		end
	end
	return true
end

local function nutRotate (fx, fy)
	local dx = fx - activeNut.x
	local dy = fy - activeNut.y
	activeNut.rotation = (math.atan2(dy, dx) * 180 / math.pi)
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
	print (lastAngle .. "  " .. wrenchRotation)
	-- adds 1 to turn wrech upon a 360 degree rotation
	if math.floor(lastAngle) < 20 then
		lastAngle = 360
		wrenchTurns = wrenchTurns + 1
	end
	-- back the wrench up if its moving in the wrong direction otherwise let it move counterclockwise
	if wrenchRotation + 20  < lastAngle then
		wrench.rotation = lastAngle
	elseif wrenchRotation > lastAngle + 5 then
		wrench.rotation = lastAngle
	else
		lastAngle = wrenchRotation
		nutRotate(event.x, event.y)  -- rotate the nut too
	end
	-- if the wrench turns a certin amount then remove the nut
	if wrenchTurns > 2 then
		wrench:removeEventListener( "touch", turnWrench )
		activeNut:removeSelf()
		activeNut = nil
		nutsRemoved = nutsRemoved + 1
		-- if all the nuts have been removed remove the wrench as well
		if nutsRemoved == 4 then
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
			wrench = act:newImage( "wrench.png",  { width = 130 } )
			wrench.anchorX = 0.13
			wrench.x = event.target.x  -- refrences the targets x that was touched
			wrench.y = event.target.y  -- same thing buy y cord
			wrench:rotate (activeNut.angle)
			wrench:addEventListener( "touch", turnWrench )
			wrenchTurns = 0
		end
	end
end

-- function to remove the panel when all the nuts are removed
local function removePanel ( event )
	
	if nutsRemoved == 4 then
		if event.phase == "began" then
			offset = panel.x - event.x
			panelLoose = true
		end
		if (event.phase == "moved") and (panelLoose == true ) then
			
			panel.x = event.x + offset
			if panel.x < act.xMin or panel.x > act.xMax then
				-- move panel off screen and transition to the next part of the game
				transition.to( panel, { time = 500, x = 500, onComplete = game.gotoAct( "wireCut", "fade" ) } )
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
	game.gotoAct ( "mainAct" )
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
	local toolbox = act:newImage ( "toolbox.png", { width = 40 } )
	toolbox.x = act.xMax - 30
	toolbox.y = act.yMin + 30
	toolbox:addEventListener( "touch", toolboxTouch )

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
	

	-- Draws the large background (NEEDS TO BE LAST THING DRAWN)
	largeBG = act:newImage ( "backgroundLarge.jpg", { width = 480 / 1.5} )

	largeBG:addEventListener( "touch", removeBG )    -- added a touch event if the player wants to skip the zoom in
	transition.scaleBy( largeBG, { xScale = 0.5, yScale = 0.5, time = 2000 } )  -- this is the zoom in time controls how long this sequence is (2000 = 2 seconds)
	timer.performWithDelay( 2500, removeBG )  -- 2500 (2.5 seconds)  is the delay amount. Needs to be equal or greater to the transistion time
end

------------------------- End of Activity ----------------------------------------------------------------------------------------

-- Corona needs the scene object returned from the act file
return act.scene
