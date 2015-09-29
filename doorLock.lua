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

-- Init the act
function act:init()
	-- Remember to put all display objects in act.group

	local screen = {}
	local button = {}

	screen.monitor = act:newImage ( "screen.png", { width=200 })
	screen.monitor.x = act.xCenter
	screen.monitor.y = act.yCenter - 150

	local panel = act:newImage ( "panel.png", { width=250 })
	panel.x = act.xCenter
	panel.y = act.yCenter + 50

	button.one = act:newImage ( "1key.png", { width=50 } )
	button.one.x = panel.x - 60
	button.one.y = panel.y - 90

	button.two = act:newImage ( "2key.png", { width=50 } )
	button.two.x = panel.x
	button.two.y = panel.y - 90

	button.three = act:newImage ( "3key.png", { width=50 } )
	button.three.x = panel.x + 60
	button.three.y = panel.y - 90

	button.four = act:newImage ( "4key.png", { width=50 } )
	button.four.x = panel.x - 60
	button.four.y = panel.y - 30

	button.five = act:newImage ( "5key.png", { width=50 } )
	button.five.x = panel.x
	button.five.y = panel.y - 30

	button.six = act:newImage ( "6key.png", { width=50 } )
	button.six.x = panel.x + 60
	button.six.y = panel.y - 30

	button.seven = act:newImage ( "7key.png", { width=50 } )
	button.seven.x = panel.x - 60
	button.seven.y = panel.y + 30

	button.eight = act:newImage ( "8key.png", { width=50 } )
	button.eight.x = panel.x
	button.eight.y = panel.y + 30

	button.nine = act:newImage ( "9key.png", { width=50 } )
	button.nine.x = panel.x + 60
	button.nine.y = panel.y + 30

	button.clear = act:newImage ( "clear.png", { width=50 } )
	button.clear.x = panel.x - 60
	button.clear.y = panel.y + 90

	button.zero = act:newImage ( "0key.png", { width=50 } )
	button.zero.x = panel.x
	button.zero.y = panel.y + 90

	button.enter = act:newImage ( "enter.png", { width=50 } )
	button.enter.x = panel.x + 60
	button.enter.y = panel.y + 90

end


------------------------- End of Activity --------------------------------


-- Corona needs the scene object returned from the act file
return act.scene
