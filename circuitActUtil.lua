-----------------------------------------------------------------------------------------
--
-- circuitActUtil.lua
--
-- A utility file for common functions in the circuit act
--
-- Joe Cracchiolo
-----------------------------------------------------------------------------------------
------------------------- OverHead ---------------------------------------------------------

-- Get local reference to the game globals
local game = globalGame
--local act = game.newAct()
local util = {}

------------------------- Variables ---------------------------------------------------------

------------------------- Functions ---------------------------------------------------------
-- create the toolbox
function util.makeToolbox (act)
	local toolbox = act:newImage ( "toolbox2.png", { width = 45, folder = "media/circuitActUtil" } )
	toolbox.x = act.xMax - 30
	toolbox.y = act.yMin + 30
	transition.blink ( toolbox, { time = 2000 } )
	return toolbox
end

-- function for the toolbox touch
function util:toolboxTouch (event) 
	if event.phase == "began" then
		if toolWindow == nil then
			if wrench then      --- remove the wrech if there is already one on screen
				wrench:removeSelf()
				wrench = nil
			end
			transition.cancel( toolbox ) -- kill the blinking
			toolbox.alpha = 1   -- set the alpha of the toolbox back to 1
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

function util:printThis ()
	print ("test")
end

return util