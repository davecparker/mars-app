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

local widget = require( "widget" )

------------------------- Start of Activity --------------------------------
local screen = {}
local button = {}
local numPic = {}
local numberCreate = {}
local numberDisplay = {}

local backTapped
local passKey = "1234"
local keyedCorrectly
local numberLocation
local refreshScreen
local clearKeyPad
local keyPressed

local colorNumbers = display.newGroup()

local sound = {}

-- When the Back Button is Pushed
function backTapped()
	game.gotoAct( "mainAct", { effect = "slideRight", time = 800 } )
end

-- Checks to see if the numbers entered match the passKey
function checkKey()
	if table.maxn(numberDisplay) < 4 then
		return false
	else
		local keyEntered = numberDisplay[1]..numberDisplay[2]..numberDisplay[3]..numberDisplay[4]
		if keyEntered == passKey then
			return true
		else
			return false
		end
	end
end

-- Number Spritesheet Options
local options =
{
    width = 25,
    height = 50,
    numFrames = 10,
    sheetContentWidth = 250,
    sheetContentHeight = 50
}

-- Normal, Green, & Red Numbers
local number = graphics.newImageSheet( "media/doorLock/numbers.png", options ) -- Red Number Sheet
local numberR = graphics.newImageSheet( "media/doorLock/numbers.png", options ) -- Red Number Sheet
local numberG = graphics.newImageSheet( "media/doorLock/numbers2.png", options ) -- Green Number Sheet

-- Calls the Blink Function Stored in Each Number Object
function flashTheNumbers()
	for i = 1, #colorNumbers, 1 do
		colorNumbers[i].blink( colorNumbers[i] )
	end
end

-- Destroys the Number Objects
function removeFlashedNumbers()
	for i = #colorNumbers, 1, -1 do
		display.remove( colorNumbers[i] )
		table.remove( colorNumbers[i] )
	end
	clearKeyPad() -- Remove Previously Typed Numbers
end

-- Creates New Number Objects of the Requested Color
function colorToFlash( flashColor )
	for i = 1, #numberDisplay, 1 do
		local newNumber
		if flashColor == "Green" then
			newNumber = display.newImage( colorNumbers, numberG, numberDisplay[i]+1 )
		else
			newNumber = display.newImage( colorNumbers, numberR, numberDisplay[i]+1 )
		end
		newNumber.x = numberLocation( i )
		newNumber.y = screen.y
		newNumber.blink = function( self )
			if self.isVisible then
				self.isVisible = false
			else 
				self.isVisible = true
			end
		end
		table.insert( colorNumbers, newNumber )
	end

	-- Blink the Numbers and then Destroy
	timer.performWithDelay( 200, flashTheNumbers, 6 )
	timer.performWithDelay( 1200, removeFlashedNumbers )
end


-- Returns the X Value for the Display Position 
function numberLocation( idx )
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

-- Refresh the Screen every time the table is affected
function refreshScreen( )

--	Remove All Existing Number Objects
	for i = #numberCreate, 1, -1 do
		display.remove(numberCreate[i])
		table.remove(numberCreate, i)
	end

	if keyedCorrectly == true then 			-- Create Green Numbers if Correct
		keyedCorrectly = nil
		colorToFlash( "Green" )
	elseif keyedCorrectly == false then 	-- Create Red Numbers if Wrong
		keyedCorrectly = nil
		colorToFlash( "Red" )
	else
		if table.maxn(numberDisplay) <= 4 then 									--	Else Create Normal Numbers
			for i = 1, #numberDisplay, 1 do
				local newNumber = display.newImage( act.group, number, numberDisplay[i]+1)
				newNumber.x = numberLocation( i )
				newNumber.y = screen.y
				newNumber.blink = function( self )
					if self.isVisible then
						self.isVisible = false
					else 
						self.isVisible = true
					end
				end
				table.insert( numberCreate, newNumber )
			end
		end
	end
end

-- Clears the Screen
function clearKeyPad()
	for i = #numberDisplay, 1, -1 do
		table.remove( numberDisplay, i )
	end
end

-- The Listener for the Buttons
function keyPressed( event )
	local key = event.target.name
	audio.play( sound.button1 )

	if key == "clr" then
		clearKeyPad()
	end

	if key == "ent" then
		if checkKey() then
			keyedCorrectly = true
			audio.play( sound.beep1 )
		else
			keyedCorrectly = false
			audio.play( sound.beep2 )
		end
	end

	if key ~= "clr" and key ~= "ent" then
		table.insert( numberDisplay, key ) -- Remove else statement if screen should wrap
	end

	if table.maxn(numberDisplay) <=4 then
		refreshScreen()
	end 
end

local function createButton( name, file, x, y )
	local b = widget.newButton {
		defaultFile = file,
		--overFile = file2,
		width = 50,
		height = 50,
		x = x, y = y,
		onRelease = keyPressed
	}
	b.name = name
	return b
end

-- Init the act
function act:init()

	-- Title Bar
	act:makeTitleBar( "Door", backTapped )

	-- Background
	--...

	-- Sound
	sound.button1 = audio.loadSound( "media/doorLock/sounds/button1.wav" )

	sound.beep1 = audio.loadSound( "media/doorLock/sounds/beep1.wav" )
	sound.beep2 = audio.loadSound( "media/doorLock/sounds/beep2.wav" )

	audio.setVolume( 0.6 )

	-- Screen
	screen = act:newImage( "screen.png", { width=200 })
	screen.x = act.xCenter
	screen.y = act.yCenter - 150

	-- Button Panel
	local panel = act:newImage( "panel.png", { width=250 })
	panel.x = act.xCenter
	panel.y = act.yCenter + 50

	button.one = createButton( 1, "media/doorLock/1key.png", panel.x - 60, panel.y - 90 )

	--[[
	button.one = act:newImage( "1key.png", { width=50 } )
	button.one.x = panel.x - 60
	button.one.y = panel.y - 90
	button.one.name = 1
	button.one:addEventListener( "tap", keyPressed )
	--]]

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

	act.group:insert( button.one )
end


------------------------- End of Activity --------------------------------


-- Corona needs the scene object returned from the act file
return act.scene
