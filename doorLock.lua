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
	game.gotoAct( "mainAct", { effect = "slideRight", time = 800 } )
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
	audio.play( sound.button[r], { channel = sound.button[r] } )

	for i = 1, 4 do
		audio.setVolume( 1.2, { channel = sound.button[r] } )
	end

	-- If Clear Key is Pressed
	if key == "clr" then
		clearKeyPad()
	-- If Enter Key is Pressed
	elseif key == "ent" then
		if checkKey() then
			keyedCorrectly = true
			audio.play( sound.pass, { channel = sound.pass } )
			system.vibrate( )
		else
			keyedCorrectly = false
			audio.play( sound.fail, { channel = sound.fail } )
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

local function createButton( name, x, y, file, file2 )
	local b = widget.newButton {
		defaultFile = file,
		overFile = file2,
		width = 50,
		height = 50,
		x = x, y = y,
		onPress = keyPressed
	}
	b.name = name
	return b
end

-- Initiate the Activity (Create)
function act:init()

	-- Title Bar
	act:makeTitleBar( "Door", backTapped )

	-- Background
	--...

	-- Sound
	sound.button = {
		audio.loadSound( "media/doorLock/sounds/button1.wav" ),
		audio.loadSound( "media/doorLock/sounds/button2.wav" ),
		audio.loadSound( "media/doorLock/sounds/button3.wav" ),
		audio.loadSound( "media/doorLock/sounds/button4.wav" )
	}

	sound.pass = audio.loadSound( "media/doorLock/sounds/pass.wav" )
	sound.fail = audio.loadSound( "media/doorLock/sounds/fail.wav" )

	audio.setVolume( 0.5, { channel = sound.pass } )
	audio.setVolume( 0.5, { channel = sound.fail } )

	-- Screen
	screen = act:newImage( "screen.png", { width=200 })
	screen.x = act.xCenter
	screen.y = act.yCenter - 150

	-- Button Panel
	local panel = act:newImage( "panel.png", { width=250 })
	panel.x = act.xCenter
	panel.y = act.yCenter + 50

	-- Buttons
	button.one = createButton( 1, panel.x - 60, panel.y - 90, 
		"media/doorLock/buttons/1key.png", "media/doorLock/buttons/1key_p.png" )

	button.two = createButton( 2, panel.x, panel.y - 90, 
		"media/doorLock/buttons/2key.png", "media/doorLock/buttons/2key_p.png" )

	button.three = createButton( 3, panel.x + 60, panel.y - 90, 
		"media/doorLock/buttons/3key.png", "media/doorLock/buttons/3key_p.png" )

	button.four = createButton( 4, panel.x - 60, panel.y - 30, 
		"media/doorLock/buttons/4key.png", "media/doorLock/buttons/4key_p.png" )

	button.five = createButton( 5, panel.x, panel.y - 30, 
		"media/doorLock/buttons/5key.png", "media/doorLock/buttons/5key_p.png" )

	button.six = createButton( 6, panel.x + 60, panel.y - 30, 
		"media/doorLock/buttons/6key.png", "media/doorLock/buttons/6key_p.png" )

	button.seven = createButton( 7, panel.x - 60, panel.y + 30, 
		"media/doorLock/buttons/7key.png", "media/doorLock/buttons/7key_p.png" )

	button.eight = createButton( 8, panel.x, panel.y + 30, 
		"media/doorLock/buttons/8key.png", "media/doorLock/buttons/8key_p.png" )

	button.nine = createButton( 9, panel.x + 60, panel.y + 30, 
		"media/doorLock/buttons/9key.png", "media/doorLock/buttons/9key_p.png" )

	button.clear = createButton( "clr", panel.x - 60, panel.y + 90, 
		"media/doorLock/buttons/clear.png", "media/doorLock/buttons/clear_p.png" )

	button.zero = createButton( 0, panel.x, panel.y + 90, 
		"media/doorLock/buttons/0key.png", "media/doorLock/buttons/0key_p.png" )

	button.enter = createButton( "ent", panel.x + 60, panel.y + 90, 
		"media/doorLock/buttons/enter.png", "media/doorLock/buttons/enter_p.png" )

	act.group:insert( button.one )
	act.group:insert( button.two )
	act.group:insert( button.three )
	act.group:insert( button.four )
	act.group:insert( button.five )
	act.group:insert( button.six )
	act.group:insert( button.seven )
	act.group:insert( button.eight )
	act.group:insert( button.nine )
	act.group:insert( button.clear )
	act.group:insert( button.zero )
	act.group:insert( button.enter )

end

------------------------- End of Activity --------------------------------


-- Corona needs the scene object returned from the act file
return act.scene
