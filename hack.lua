-----------------------------------------------------------------------------------------
--
-- hack.lua
--
-- An activity where the player has to hack a terminal
-----------------------------------------------------------------------------------------

-- Get local reference to the game globals
local game = globalGame

-- Create the act object
local act = game.newAct()

local widget = require("widget")

local passBtns
local password
local terminalText


------------------------- Start of Activity --------------------------------

local function passListener(event)
	local target = event.target

	if(target == passBtns[1]) then
		print("2 letters are correct")
	elseif(target == passBtns[2]) then
		print("1 letter is correct")
	elseif(target == passBtns[3]) then
		print("3 letters are correct")
	elseif(target == passBtns[4]) then
		print("All letters are correct")
	elseif(target == passBtns[5]) then
		print("2 letters are correct")
	elseif(target == passBtns[6]) then
		print("0 letters are correct")
	elseif(target == passBtns[7]) then
		print("3 letters are correct")
	end
end

local function encryptString(decryText)

	-- Declare an array to hold an ascii table and characters for the encrypted string
	-- a=97, b=98, c=99, ..., x=120, y=121, z=122
	local encryArr = {}

	-- Declare a variable to receive the encrypted text string
	local encryText = ""

	-- For each character in the encrypted string
	for i=1, #decryText do
		

		-- Convert each character into its ascii equivalent
		encryArr[i] = string.byte(decryText, i)

		-- Make sure ascii character is not a space
		if(encryArr[i] ~= 32) then

			-- Subtract 97 from each ascii value (so a=0, b=1, etc.)
			encryArr[i] = encryArr[i] - 97

			-- Add 13 to each value and apply a modulo 26 to the sum (so that rot 13 is achieved)

			encryArr[i] = (encryArr[i] + 13) % 26

			-- Add 97 to each value so that a new ascii table is created
			encryArr[i] = encryArr[i] + 97
		end

		-- Convert the new ascii values to characters
		encryArr[i] = string.char(encryArr[i])

		-- Concatanate the new encrypted characters into a string
		encryText = encryText .. encryArr[i]
	end

	return encryText
end

-- Init the act
function act:init()
	-- Remember to put all display objects in act.group

	-- Create document (image) for encrypted message

	-- Create image for the terminal display
	local terminalDisplay = display.newRect(act.group, act.xCenter, act.yCenter, act.width, act.height)
	terminalDisplay:setFillColor(0,0,0)
	terminalDisplay.stroke = {0.5, 0.5, 0.5}
	terminalDisplay.strokeWidth = 28

	-- Create buttons for inputting passwords
	passBtns = {}
	for i=1,7 do
		passBtns[i] = widget.newButton(
		{
			x = 230,
			y = 60 + i * 55,
			shape = "rect",
			fillColor = { default={ 0.5, 0.5, 0.5 }, over={ 1, 0, 0 } },
			label = "Enter",
			width = 80,
			height = 35,
			labelColor = { default={ 0, 0, 0 } },
			onRelease = passListener
		})
		act.group:insert(passBtns[i])
	end

	-- Create text 
	terminalText = {}
	for i=1,11 do
		terminalText[i] = display.newText(act.group, "test", act.xMin + act.xCenter, act.yMin + 30 * i, native.systemFont)
		if(i>=5) then
			terminalText[i].x = act.xMin + 90
			terminalText[i].y = 60 + (i-4) * 55 --passBtns[i-3].y
		end
		terminalText[i]:setFillColor(0,1,0)
	end

	-- Set text for each line
	terminalText[1].text = "SIERRA TERMLINK PROTOCOL"
	terminalText[2].text = "ENTER PASSWORD NOW"
	terminalText[3].text = "4 ATTEMPTS LEFT"
	terminalText[4].text = "SELECT A PASSWORD:"
	terminalText[5].text = "0xF610 PLANE"
	terminalText[6].text = "0xF614 CRANE"
	terminalText[7].text = "0xF618 PLANT"
	terminalText[8].text = "0xF61C BLUNT"
	terminalText[9].text = "0xF620 PLUMP"
	terminalText[10].text = "0xF624 DRAIN"
	terminalText[11].text = "0xF628 FLINT"


	-- Start with console
	-- Create an encrypted message example using a string and an encryption method (Rot 13)
	--[[local decryptedText = "sample text"
	local encryptedText = encryptString(decryptedText)
	print("Sample decrypted text is " .. decryptedText)
	print("Sample encrypted text is " .. encryptedText)]]

end


------------------------- End of Activity --------------------------------


-- Corona needs the scene object returned from the act file
return act.scene