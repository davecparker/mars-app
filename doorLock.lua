-----------------------------------------------------------------------------------------
--
-- doorLock.lua
--
-- Door unlocking activity by Ryan Bains-Jordan
-----------------------------------------------------------------------------------------

-- Get local reference to the game globals
local game = globalGame

-- Create the act object
local act = game.newAct()


------------------------- Start of Activity --------------------------------
local screen = {}
local button = {}
local numPic = {}
local numberCreate = {}
local numberDisplay = {}

	-- Numbers
	local options =
	{
	    width = 25,
	    height = 50,
	    numFrames = 10,
	    sheetContentWidth = 250,  --width of original 1x size of entire sheet
	    sheetContentHeight = 50  --height of original 1x size of entire sheet
	}
	local number = graphics.newImageSheet( "media/doorLock/numbers.png", options )

local function backTapped()
	game.gotoAct( "mainAct", { effect = "slideUp", time = 800 } )
end

-- Returns the X Position of Each Number Location
local function numberLocation( idx )
	if idx == 1 then
		return screen.x - 60
	elseif idx ==  2 then
		return screen.x - 20
	elseif idx == 3 then
		return screen.x + 20
	else
		return screen.x + 60
	end
end


local function refreshScreen( )
--	Remove All Exiting Number Objects
	for i = #numberCreate, 1, -1 do
		display.remove(numberCreate[i])
		table.remove(numberCreate, i)
	end

--	Create Brand New Numbers from the outputDisplay Table
	for i = 1, #numberDisplay, 1 do
		local newNumber = display.newImage(act.group, number, numberDisplay[i])
		newNumber.x = numberLocation( i )
		newNumber.y = screen.y
		table.insert( numberCreate, newNumber )
	end
end


local function keyPressed( event )
	print(event.target.name)
	if #numberDisplay >= 4 then
		table.remove( numberDisplay, 1 )
	end

	table.insert( numberDisplay, event.target.name + 1 )
	refreshScreen()
end

-- Init the act
function act:init()

	-- Title Bar
	act:makeTitleBar( "Door", backTapped )

	-- Background
	local background = display.newRect( act.group, act.xCenter, act.yCenter+20, act.width, act.height-40 )
	background:setFillColor( 0, 0, 0 )

	-- -- Numbers
	-- local options =
	-- {
	--     width = 25,
	--     height = 50,
	--     numFrames = 10,
	--     sheetContentWidth = 250,  --width of original 1x size of entire sheet
	--     sheetContentHeight = 50  --height of original 1x size of entire sheet
	-- }
	-- local number = graphics.newImageSheet( "media/doorLock/numbers.png", options )

	-- Screen
	screen = act:newImage( "screen.png", { width=200 })
	screen.x = act.xCenter
	screen.y = act.yCenter - 150

	-- Button Panel
	local panel = act:newImage( "panel.png", { width=250 })
	panel.x = act.xCenter
	panel.y = act.yCenter + 50

	button.one = act:newImage( "1key.png", { width=50 } )
	button.one.x = panel.x - 60
	button.one.y = panel.y - 90
	button.one.name = 1
	button.one:addEventListener( "tap", keyPressed )

	button.two = act:newImage( "2key.png", { width=50 } )
	button.two.x = panel.x
	button.two.y = panel.y - 90
	button.two.name = 2
	button.two:addEventListener( "tap", keyPressed )

	button.three = act:newImage( "3key.png", { width=50 } )
	button.three.x = panel.x + 60
	button.three.y = panel.y - 90
	button.three.name = 3
	button.three:addEventListener( "tap", keyPressed )

	button.four = act:newImage( "4key.png", { width=50 } )
	button.four.x = panel.x - 60
	button.four.y = panel.y - 30
	button.four.name = 4
	button.four:addEventListener( "tap", keyPressed )

	button.five = act:newImage( "5key.png", { width=50 } )
	button.five.x = panel.x
	button.five.y = panel.y - 30
	button.five.name = 5
	button.five:addEventListener( "tap", keyPressed )

	button.six = act:newImage( "6key.png", { width=50 } )
	button.six.x = panel.x + 60
	button.six.y = panel.y - 30
	button.six.name = 6
	button.six:addEventListener( "tap", keyPressed )

	button.seven = act:newImage( "7key.png", { width=50 } )
	button.seven.x = panel.x - 60
	button.seven.y = panel.y + 30
	button.seven.name = 7
	button.seven:addEventListener( "tap", keyPressed )

	button.eight = act:newImage( "8key.png", { width=50 } )
	button.eight.x = panel.x
	button.eight.y = panel.y + 30
	button.eight.name = 8
	button.eight:addEventListener( "tap", keyPressed )

	button.nine = act:newImage( "9key.png", { width=50 } )
	button.nine.x = panel.x + 60
	button.nine.y = panel.y + 30
	button.nine.name = 9
	button.nine:addEventListener( "tap", keyPressed )

	button.clear = act:newImage( "clear.png", { width=50 } )
	button.clear.x = panel.x - 60
	button.clear.y = panel.y + 90
	button.clear.name = "clr"
	button.clear:addEventListener( "tap", keyPressed )

	button.zero = act:newImage( "0key.png", { width=50 } )
	button.zero.x = panel.x
	button.zero.y = panel.y + 90
	button.zero.name = 0
	button.zero:addEventListener( "tap", keyPressed )

	button.enter = act:newImage( "enter.png", { width=50 } )
	button.enter.x = panel.x + 60
	button.enter.y = panel.y + 90
	button.enter.name = "ent"
	button.enter:addEventListener( "tap", keyPressed )
end


------------------------- End of Activity --------------------------------


-- Corona needs the scene object returned from the act file
return act.scene
