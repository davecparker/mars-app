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
local widget = require( "widget" )  -- need to make buttons
local nutsRemoved = 0    -- the number of nuts that have been removed
local panel
local adjustment = 0   -- used for rotation of the wrench

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
			toolWindow = display.newRect( act.group, act.xCenter, act.yCenter, 300, 300 )
			wrench = act:newImage( "wrench.png",  { width = 100 } )
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
	--print (nut.TL.rotation)
end

-- function for turning wrench
-- as the player moves the finger around the bolt the wrench follows
local function turnWrench ( event )
	if event.phase == "began" then
		local dx = event.x - wrench.x
		local dy = event.y - wrench.y
		adjustment = math.atan2(dy, dx) * 180 / math.pi - wrench.rotation
	end
	if event.phase == "moved" then
		local dx = event.x - wrench.x
		local dy = event.y - wrench.y
		wrench.rotation = (math.atan2(dy, dx) * 180 / math.pi) - adjustment
		nutRotate(event.x, event.y)
		wrenchTurns = wrenchTurns + 1
	end
	-- if the wrench turns a bit then remove the nut
	if wrenchTurns > 200 then
		wrench:removeEventListener( "touch", turnWrench )
		activeNut:removeSelf()
		activeNut = nil
		nutsRemoved = nutsRemoved + 1
		print(nutsRemoved)
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
	if event.phase == "began" then
		-- remove any  wrench that is on the screen
		if wrench then
			wrench:removeSelf()
			wrench = nil
		end
		-- create a wrench on the selected nut and reset the wrenchturns
		if wrenchSelected then
			wrench = act:newImage( "wrench.png",  { width = 130 } )
			wrench.anchorX = 0.2
			wrench.anchorY = 0.2
			wrench.x = event.target.x  -- refrences the targets x that was touched
			wrench.y = event.target.y  -- same thing buy y cord
			wrench:addEventListener( "touch", turnWrench )
			wrenchTurns = 0
		end
	end
end

-- function to remove the panel when all the nuts are removed
local function removePanel ( event )
	if nutsRemoved == 4 then
		if event.phase == "began" then
			panelLoose = true
		end
		if (event.phase == "moved") and (panelLoose == true ) then
			panel.x = event.x
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
	local bg = act:newImage ( "background.png", { width = 400 } )
	bg.x = act.xCenter
	bg.y = act.yCenter + 25
	bg:addEventListener( "touch", bgTouch )

	-- toolbox icon
	local toolbox = act:newImage ( "toolbox.png", { width = 40 } )
	toolbox.x = act.xMax - 30
	toolbox.y = act.yMin + 30
	toolbox:addEventListener( "touch", toolboxTouch )

	-- panel
	local panelLoose = false
	panel = act:newImage( "panel.png", { width = 280 } )
	panel.x = act.xCenter
	panel.y = act.yCenter + 20
	panel:addEventListener( "touch", removePanel )

	-- nuts
	local nut = {}
	-- top left
	nut.TL = act:newImage( "nut.png", { width = 30 } )
	nut.TL.x = act.xCenter - 110
	nut.TL.y = act.yCenter - 135
	nut.TL:addEventListener( "touch", nutTouch )
	-- top right
	nut.TR = act:newImage( "nut.png", { width = 30 } )
	nut.TR.x = act.xCenter + 110
	nut.TR.y = act.yCenter - 135
	nut.TR:addEventListener( "touch", nutTouch )
	-- bottom left
	nut.BL = act:newImage( "nut.png", { width = 30 } )
	nut.BL.x = act.xCenter - 110
	nut.BL.y = act.yCenter + 170
	nut.BL:addEventListener( "touch", nutTouch )
	-- bottom right
	nut.BR = act:newImage( "nut.png", { width = 30 } )
	nut.BR.x = act.xCenter + 110
	nut.BR.y = act.yCenter + 170
	nut.BR:addEventListener( "touch", nutTouch )

end

------------------------- End of Activity --------------------------------

-- Corona needs the scene object returned from the act file
return act.scene
