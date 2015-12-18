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

-- Act Requisites
local widget = require( "widget" )

------------------------- Start of Activity --------------------------------
local screen = {}
local button = {}
local numPic = {}
local numberCreate = {}
local numberDisplay = {}

local backTapped
local defaultPassKey = "1234"
local keyedCorrectly
local numberLocation
local refreshScreen
local clearKeyPad
local keyPressed

local colorNumbers = display.newGroup()

local sound = {}

-- When the Back Button is Pushed
function backTapped()
	if game.cheatMode then
		game.doorUnlocked = true
	end
	game.gotoAct( "mainAct", { effect = "slideRight", time = 500 } )
end

-- Checks to see if the numbers entered match the lock code
function checkKey()
	local passKey = game.doorCode or defaultPassKey
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
    width = 27,
    height = 50,
    numFrames = 10,
    sheetContentWidth = 270,
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

	-- If door unlocked successfully then go back to mainAct to enter the room
	if game.doorUnlocked then
		game.gotoAct( "mainAct", { effect = "crossFade", time = 500 } )
	end
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

--  Flash Green if Correct, Flash Red if Incorrect, or Add a New Number to the Display
	if keyedCorrectly == true then 			-- Create Green Numbers if Correct
		game.doorUnlocked = true            -- Tell mainAct that we unlocked the door
		keyedCorrectly = nil
		colorToFlash( "Green" )
	elseif keyedCorrectly == false then 	-- Create Red Numbers if Wrong
		keyedCorrectly = nil
		colorToFlash( "Red" )
	else
		if table.maxn(numberDisplay) <= 4 then 		--	Else Create Normal Red Numbers
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
	print("Clearing Key Pad")
end

-- The Listener for the Buttons
function keyPressed( event )
	local key = event.target.name

	local r = math.random( 1, 4 )
	game.playSound( sound.button[r] )

	-- If Clear Key is Pressed
	if key == "clr" then
		clearKeyPad()
	-- If Enter Key is Pressed
	elseif key == "ent" then
		if checkKey() then
			keyedCorrectly = true
			game.playSound( sound.pass )
			if game.saveState.soundOn then
				system.vibrate( )
			end
		else
			keyedCorrectly = false
			game.playSound( sound.fail )
		end
	-- If Any Other Key is Pressed
	elseif key ~= "clr" and key ~= "ent" then
		if table.maxn(numberDisplay) < 4 then
			table.insert( numberDisplay, key )
		end
	end

	if table.maxn(numberDisplay) <= 4 then
		refreshScreen()
	end 
end
-- Convenience Function 
local function createButton( scene, name, x, y, file, file2 )
	local b = widget.newButton {
		defaultFile = file,
		overFile = file2,
		width = 50,
		height = 50,
		x = x, y = y,
		onPress = keyPressed
	}
	scene:insert(b)
	b.name = name
	return b
end

-- Initiate the Activity (Create)
function act:init()
	-- Background
	local bg = display.newRect( act.group, act.xCenter, act.yCenter, act.width, act.height )
	bg:setFillColor( 0.3 )  -- dark gray 

	-- Title Bar
	act:makeTitleBar( "", backTapped )   -- title set in act:prepare()

	-- Sound
	sound.button = {
		act:loadSound( "sounds/button1.wav" ),
		act:loadSound( "sounds/button2.wav" ),
		act:loadSound( "sounds/button3.wav" ),
		act:loadSound( "sounds/button4.wav" )
	}
	sound.pass = act:loadSound( "sounds/pass.wav" )
	sound.fail = act:loadSound( "sounds/fail.wav" )

	-- Screen
	screen = act:newImage( "screen.png", { width=200 })
	screen.x = act.xCenter
	screen.y = act.yCenter - 150

	-- Button Panel
	local panel = act:newImage( "panel.png", { width=250 })
	panel.x = act.xCenter
	panel.y = act.yCenter + 50

	-- Buttons
	button.one = createButton( act.group, 1, panel.x - 60, panel.y - 90, 
		"media/doorLock/buttons/1key.png", "media/doorLock/buttons/1key_p.png" )

	button.two = createButton( act.group, 2, panel.x, panel.y - 90, 
		"media/doorLock/buttons/2key.png", "media/doorLock/buttons/2key_p.png" )

	button.three = createButton( act.group, 3, panel.x + 60, panel.y - 90, 
		"media/doorLock/buttons/3key.png", "media/doorLock/buttons/3key_p.png" )

	button.four = createButton( act.group, 4, panel.x - 60, panel.y - 30, 
		"media/doorLock/buttons/4key.png", "media/doorLock/buttons/4key_p.png" )

	button.five = createButton( act.group, 5, panel.x, panel.y - 30, 
		"media/doorLock/buttons/5key.png", "media/doorLock/buttons/5key_p.png" )

	button.six = createButton( act.group, 6, panel.x + 60, panel.y - 30, 
		"media/doorLock/buttons/6key.png", "media/doorLock/buttons/6key_p.png" )

	button.seven = createButton( act.group, 7, panel.x - 60, panel.y + 30, 
		"media/doorLock/buttons/7key.png", "media/doorLock/buttons/7key_p.png" )

	button.eight = createButton( act.group, 8, panel.x, panel.y + 30, 
		"media/doorLock/buttons/8key.png", "media/doorLock/buttons/8key_p.png" )

	button.nine = createButton( act.group, 9, panel.x + 60, panel.y + 30, 
		"media/doorLock/buttons/9key.png", "media/doorLock/buttons/9key_p.png" )

	button.clear = createButton( act.group, "clr", panel.x - 60, panel.y + 90, 
		"media/doorLock/buttons/clear.png", "media/doorLock/buttons/clear_p.png" )

	button.zero = createButton( act.group, 0, panel.x, panel.y + 90, 
		"media/doorLock/buttons/0key.png", "media/doorLock/buttons/0key_p.png" )

	button.enter = createButton( act.group, "ent", panel.x + 60, panel.y + 90, 
		"media/doorLock/buttons/enter.png", "media/doorLock/buttons/enter_p.png" )

end

-- Prepare the act
function act:prepare()
	-- Set title bar text to the name of the room
	if game.lockedRoom then
		act.title.text = game.lockedRoom.name
	else
		act.title.text = "Locked Door"
	end
end

------------------------- End of Activity --------------------------------


-- Corona needs the scene object returned from the act file
return act.scene
