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
local numAttempts

local possPasswords
local NUM_OF_PASSWORDS = 7
local PASS_LEN = 7
local MAX_NUM_ATTEMPTS = 4

-- Set the random generator seed
math.randomseed( os.time() )


------------------------- Start of Activity --------------------------------

-- Check how many letters in each string are the same
local function compareStrings(str1, str2)

	-- Initialize the number of same letters to zero
	local numSame = 0

	-- Check and make sure the strings have the same length
	if(#str1 == #str2) then

		-- For the length of the strings
		for i=1,#str1 do

			-- Extract each character from each string and place
			-- them into local variables
			local c1 = str1:sub(i,i)
			local c2 = str2:sub(i,i)

			-- Check if the characters match
			if(c1 == c2) then

				-- Increment the variable that records how many
				-- characters of each string are identical and
				-- in identical positions
				numSame = numSame + 1
			end
		end
	end

	-- Return the number of characters that are the same and
	-- in the same positions for each string
	return numSame
end

-- Listener called when user pressed a button for a password
local function passListener(event)

	-- Identify which button has been pressed
	local target = event.target

	-- Check to make sure the passwords buttons array exists
	-- and that the user still has attempts left
	if(passBtns ~= nil and numAttempts > 0) then

		-- For the number of passwords
		for i=1,NUM_OF_PASSWORDS do

			-- Check if the target was a particular button in
			-- the array
			if(target == passBtns[i]) then

				-- Set a local variable to record how many letters of the
				-- selected password are the same and in the same positions
				-- as the password
				local numCorrect = compareStrings(passBtns[i].word, password)
				if(numCorrect < string.len(password)) then
					numAttempts = numAttempts - 1
					terminalText[3].text = numAttempts .. " ATTEMPTS LEFT"
					terminalText[4].text = compareStrings(passBtns[i].word, password) .. " LETTER(S) IS/ARE CORRECT"
					passBtns[i]:setLabel(numCorrect)
					passBtns[i]:setEnabled(false)

				elseif(numCorrect >= string.len(password)) then
					terminalText[2].text = ""
					terminalText[3].text = "CORRECT PASSWORD"
					terminalText[4].text = string.upper(password)
					for j=1,7 do
						passBtns[j]:removeSelf()
						passBtns[j] = nil
						terminalText[j+4].text = ""
					end
					passBtns = nil
					break
				end
			end
		end
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

-- Function to generate a real password randomly for a given length
local function generateRealPassword(length)
	local pass = ""
	for i=1,length do
		pass = pass .. string.char(math.random(97, 97 + 25))
	end
	return pass
end

-- Function to generate a fake password based on a real password
-- and the number of letters that need to be the same
local function generateFakePassword(realPass, numSame)
	
	-- Array to mark selected letter positions from the real password
	local selectPos = {}

	-- Array of characters for building a fake password
	local fakePassArray = {}

	for i=1,string.len(realPass) do

		-- Populate an array to mark which letters have been picked already
		-- based on position in the word
		table.insert(selectPos, false)

		-- Populate an array to build an array of fake characters to
		-- construct into the fake password later
		table.insert(fakePassArray, "")
	end

	-- Variable to hold the fake password
	local fakePass = ""

	-- For the number of letters that need to be the same
	for i=1,numSame do

		--Select a letter position randomly
		local n = math.random(1,string.len(realPass))

		-- Keep randomly selecting letters until the selected position
		-- hasn't been chosen before
		while(selectPos[n] == true) do
			n = math.random(1,string.len(realPass))
		end

		-- Extract the character that was randomly selected
		local c = realPass:sub(n,n)

		-- Mark the selected position as having been picked
		selectPos[n] = true

		-- Add it to the fake pass array at the given index
		fakePassArray[n] = c
	end

	-- After building the fake password with parts of the real
	-- password, finish furnishing the fake password with bogus
	-- letters until its the same length as the real password

	-- Add a letter, then check if it already exists in the real
	-- password. If it does, repeat until it doesn't

	for i=1,(string.len(realPass) - numSame) do

		local r

		local isSame = true

		while(isSame) do

			-- Select a letter randomly in the alphabet (using lowercase ASCII)
			r = math.random(97, 97+25)

			-- Set isSame bool to false until letter checking is done
			isSame = false

			-- Cycle through the real password and check the randomly chosen
			-- letter against each letter in the real password
			-- If the letter doesn't exist in the real password, append it
			-- to the fake password. If it does, throw it out and retry

			for i=1, string.len(realPass) do

				-- Check the selected letter against each letter of the real
				-- password (using lowercase ASCII)

				local c = string.byte(realPass:sub(i,i))
				
				if(r == c) then
					isSame = true
					break
				end

			end

		end

		r = string.char(r)

		-- Insert the bogus letter in the first free position
		for i=1,string.len(realPass) do
			if(fakePassArray[i] == "") then
				fakePassArray[i] = r
				break
			end
		end
	end

	-- Create the fake password from the fake pass array
	for i=1,string.len(realPass) do
		fakePass = fakePass .. fakePassArray[i]
	end

	return fakePass

	--print("Real password is " .. realPass)
	--print("Fake password is " .. fakePass)
	--print("# of same letters is " .. numSame)
end

-- Init the act
function act:init()
	-- Remember to put all display objects in act.group

	-- Create image for the terminal display
	local terminalDisplay = display.newRect(act.group, act.xCenter, act.yCenter, act.width, act.height)
	terminalDisplay:setFillColor(0,0,0)
	terminalDisplay.stroke = {0.5, 0.5, 0.5}
	terminalDisplay.strokeWidth = 28

	-- Create buttons for inputting passwords
	passBtns = {}
	for i=1,NUM_OF_PASSWORDS do
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

	-- Initialize the array of possible passwords
	possPasswords = {}
	
	-- Initialize the real password with n characters
	password = generateRealPassword(PASS_LEN)

	-- Randomly insert the real password into the pool of possible passwords
	possPasswords[math.random(1, NUM_OF_PASSWORDS)] = password

	-- Fill the remaining password slots with fake passwords
	for i=1,NUM_OF_PASSWORDS do
		if(possPasswords[i] == nil) then
			possPasswords[i] = generateFakePassword(password, math.random(1,PASS_LEN / 2))
		end
	end

	-- Set the possible password for each button randomly
	for i=1,NUM_OF_PASSWORDS do
		passBtns[i].word = table.remove(possPasswords, math.random(#possPasswords)) 
	end

	-- Create the text display 
	terminalText = {}
	for i=1,11 do
		terminalText[i] = display.newText(act.group, "test", act.xMin + act.xCenter, act.yMin + 30 * i, native.systemFont)
		if(i>=5) then
			terminalText[i].x = act.xMin + 90
			terminalText[i].y = 60 + (i-4) * 55 --passBtns[i-3].y
		end
		terminalText[i]:setFillColor(0,1,0)
	end

	-- Initialize the number of attempts left
	numAttempts = MAX_NUM_ATTEMPTS

	-- Set text for each line
	local terminalTexts = {
		"SIERRA TERMLINK PROTOCOL",
		"ENTER PASSWORD NOW",
		numAttempts .. " ATTEMPTS LEFT",
		"SELECT A PASSWORD:"
	}

	for i=1,4 do
		terminalText[i].text = terminalTexts[i]
	end

	for i=1,NUM_OF_PASSWORDS do
		terminalText[i+4].text = string.upper(passBtns[i].word)
	end
end


------------------------- End of Activity --------------------------------


-- Corona needs the scene object returned from the act file
return act.scene