-----------------------------------------------------------------------------------------
--
-- cipher.lua
--
-- An empty (template) activity
-----------------------------------------------------------------------------------------

-- Get local reference to the game globals
local game = globalGame

-- Create the act object
local act = game.newAct()

local widget = require("widget")

local codeBtns
local codeDisplays
local instructPage
local instructTextTitle
local instructTextBody
local instructBtn


------------------------- Start of Activity --------------------------------

local function dirListener(event)
	target = event.target
	for i=1,4 do
		if(target == codeBtns[i]) then
			if(codeSymbols[i].text == "A") then
				codeSymbols[i].text = "B"
			elseif(codeSymbols[i].text == "B") then
				codeSymbols[i].text = "C"
			elseif(codeSymbols[i].text == "C") then
				codeSymbols[i].text = "D"
			elseif(codeSymbols[i].text == "D") then
				codeSymbols[i].text = "A"
			end
		end
	end

	for i=5,8 do
		if(target == codeBtns[i]) then
			if(codeSymbols[i-4].text == "A") then
				codeSymbols[i-4].text = "D"
			elseif(codeSymbols[i-4].text == "B") then
				codeSymbols[i-4].text = "A"
			elseif(codeSymbols[i-4].text == "C") then
				codeSymbols[i-4].text = "B"
			elseif(codeSymbols[i-4].text == "D") then
				codeSymbols[i-4].text = "C"
			end
		end
	end

	if(codeSymbols[1].text == "D" and codeSymbols[2].text == "B" 
		and codeSymbols[3].text == "A" and codeSymbols[4].text == "C") then
		print("You input the correct code")
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

local function instructListener(event)
	instructPage.alpha = 1
	instructTextTitle.alpha = 1
	instructTextBody.alpha = 1
	for i=1,8 do
		codeBtns[i]:setEnabled(false)
	end
end

local function closeInstListener(event)
	instructPage.alpha = 0
	instructTextTitle.alpha = 0
	instructTextBody.alpha = 0
	for i=1,8 do
		codeBtns[i]:setEnabled(true)
	end
end

local function createBtn(x, y, label)
	local b
	b = widget.newButton(
	{
		x = x,
		y = y,
		shape = "rect",
		fillColor = { default={ 1, 1, 1 }, over={ 1, 0, 0 } },
		label = label,
		width = 60,
		height = 60,
		labelColor = { default={ 0, 0, 0 } },
		onRelease = dirListener
	})
	return b
end

-- Init the act
function act:init()
	-- Remember to put all display objects in act.group

	-- Create button interface for inputting code
	codeBtns = {}
	for i=1,4 do
		codeBtns[i] = createBtn(act.xMin + 60 + 70 * (i-1), act.yCenter - 80, "Up")
		act.group:insert(codeBtns[i])
	end
	for i=5,8 do
		codeBtns[i] = createBtn(act.xMin + 60 + 70 * (i-5), act.yCenter + 80, "Down")
		act.group:insert(codeBtns[i])
	end

	-- Create code display for each symbol in the code
	codeDisplays = {}
	for i=1,4 do
		codeDisplays[i] = display.newRect(act.group, act.xMin + 60 + 70 * (i-1), act.yCenter, 60, 60)
		codeDisplays[i].fill = {0, 0, 0}
		codeDisplays[i].stroke = {0, 1, 0}
		codeDisplays[i].strokeWidth = 4
	end

	-- Create code symbol for the display
	codeSymbols = {}
	for i=1,4 do
		--codeSymbols[i] = display.newRect(act.group, act.xMin + 60 + 70 * (i-1), act.yCenter, 40, 40)
		codeSymbols[i] = display.newText(act.group, "A", act.xMin + 60 + 70 * (i-1), act.yCenter, native.SystemFont, 24)
		codeSymbols[i].fill = {0, 1, 1}
	end


	-- Create document (image) for instructions (logic puzzle)
	instructPage = display.newRect(act.group, act.xCenter, act.yCenter, act.width - 30, act.height - 100)
	instructTextTitle = display.newText(act.group, "INSTRUCTIONS", act.xCenter, act.yMin + 60, native.systemFont)

	instructTextBody = display.newText(act.group, "", act.xMin + 140, act.yMin + 200, 240, 0,  native.systemFont)
	--The key is D B A C
	instructTextBody.text = [[
	The code is four letters long.
	Each letter is between A and D.
	Each letter appears only once.

	Hints:
	D comes before C
	B comes after D
	A is two away from D
	A comes after B
	]]
	instructTextTitle:setFillColor(0, 0, 0)
	instructTextBody:setFillColor(0, 0, 0)

	-- Set instruction document to alpha zero
	instructPage.alpha = 0
	instructTextTitle.alpha = 0
	instructTextBody.alpha = 0

	-- Create button to pull up instructions
	instructBtn = widget.newButton(
		{
			left = act.xMax - 48,
			top = act.yMin,
			shape = "rect",
			fillColor = { default={ 1, 0.2, 0.5, 0.7 }, over={ 1, 0.2, 0.5, 1 } },
			label = "Inst",
			width = 48,
			height = 48,
			onRelease = instructListener
		}
	)

	instructPage:addEventListener( "tap", closeInstListener)

	
	
	act.group:insert(instructBtn)


	

	-- Create document (image) for encrypted message

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