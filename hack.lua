--------------------------------------------------------------------------------
--
-- hack.lua
--
-- An activity where the player has to hack a terminal. The gameplay of this
-- game is essentially the board game Mastermind but a bit simplified.
-- https://en.wikipedia.org/wiki/Mastermind_(board_game)
--
-- This gem appears after going into Shaw's room and moving a few times. The
-- message comes up after the first navigation game, after the player is alerted
-- to the documents on Jordan's terminal and Shaw's terminal.
--
-- For this game, the player is given several passwords to choose from using 
-- selection buttons. The player is also informed of how many selections s/he
-- has remaining before the system will superficially kick them out (essentially 
-- they will have to restart the activity.) After each selection is made, the
-- player will be informed of how many letters in his/her choice were correct
-- and how many attempts s/he has left. The game is won when the player selects
-- the correct password.
--
-- For each run of the game, a real password is randomly generated and the fake 
-- passwords are also randomly generated with a certain number of their letters 
-- being the same as the real password. This allows the player to try to  
-- logically deduce which password is the real one given the number of correct
-- letters that each guess yields.
--
-- After the game is won, the player will be able to access the engineering room.
--------------------------------------------------------------------------------


-- Get local reference to the game globals
local game = globalGame

-- Create the act object
local act = game.newAct()

-- Load the widget library
local widget = require("widget")

-- Variables

local passBtns     -- Buttons for each password
local password     -- The real password
local terminalText -- Text on the terminal
local numAttempts  -- Number of attempts the user has remaining

-- Array of all possible passwords that the user can select from
local possPasswords

-- Sound effects
local buttonSound  -- Sound when button is pressed
local failSound    -- Sound when game is lost
local successSound -- Sound when game is won

--Constants

local NUM_OF_PASSWORDS = 12 -- Number of possible passwords
local PASS_LEN = 6		   -- Length of password
local MAX_NUM_ATTEMPTS = 5 -- Number of password attempts the user gets

-- Set the random generator seed
math.randomseed( os.time() )


------------------------- Start of Activity --------------------------------


-- Function to exit the act
local function exitAct()
	game.removeAct( "hack" )
	game.gotoAct ( "mainAct" )
end

-- Check how many letters in each string are the same
local function compareStrings(str1, str2)

	-- Initialize the number of same letters to zero
	local numSame = 0

	-- Check and make sure the strings have the same length
	if(#str1 == #str2) then

		-- For the length of the strings
		for i=1,#str1 do

			-- Extract each character from each string and place them into
			-- local variables
			local c1 = str1:sub(i,i)
			local c2 = str2:sub(i,i)

			-- Check if the characters match
			if(c1 == c2) then

				-- Increment the variable that records how many characters of
				-- each string are identical and in identical positions
				numSame = numSame + 1
			end
		end
	end

	-- Return the number of characters that are the same and in the same
	-- positions for each string
	return numSame
end

-- Function for ending the game (called after getting the right password or
-- having cheats enabled)
local function endGame()
	-- Clear the second text box
	terminalText[2].text = ""

	-- Inform the player in the third text box that s/he has
	-- selected the correct password
	terminalText[3].text = "CORRECT PASSWORD"

	-- Show the player the password they have selected
	terminalText[4].text = "ACCESS GRANTED"
	

	-- For each password
	for j=1,NUM_OF_PASSWORDS do

		-- Remove the password button and set it to nil
		passBtns[j]:removeSelf()
		passBtns[j] = nil

		-- Clear the text for the passwords
		terminalText[j+4].text = ""
	end

	-- Set the password button array to nil
	passBtns = nil

	-- Play a win sound
	game.playSound( successSound )

	-- After the player has won, they will be able to move on
	-- to the engineering room
	game.terminalHacked = true
	timer.performWithDelay(3000, exitAct)
end

-- Listener called when user pressed a button for a password
local function passListener(event)

	-- Play a sound
	if(numAttempts > 1) then
		game.playSound( buttonSound )
	end

	-- Identify which button has been pressed
	local target = event.target

	-- Check to make sure the passwords buttons array exists and that the user
	-- still has attempts left
	if(passBtns ~= nil and numAttempts > 0) then

		-- For the number of passwords
		for i=1,NUM_OF_PASSWORDS do

			-- Check if the target was a particular button in the array
			if(target == passBtns[i]) then

				-- Set a local variable to record how many letters of the
				-- selected password are the same and in the same positions
				-- as the password
				local numCorrect = compareStrings(passBtns[i].word, password)

				-- If the number of letters that are correct are less than the
				-- length of the password (i.e. the passwords don't match)
				if(numCorrect < string.len(password)) then

					-- Decrement the number of attempts remaining
					numAttempts = numAttempts - 1

					-- Update the text with the number of attempts remaining
					terminalText[3].text = numAttempts .. " ATTEMPTS LEFT"

					-- Update the text with how many letters are the same and 
					-- in the same positions
					terminalText[4].text = compareStrings(passBtns[i].word, 
						password) .. " LETTER(S) IS/ARE CORRECT"

					-- Update the button label with how many letters were
					-- correct
					passBtns[i]:setLabel(numCorrect)

					-- Prevent the player from being able to select the same 
					-- password twice
					passBtns[i]:setEnabled(false)

				-- If the passwords have the same number of correct letters 
				-- (i.e. they are identical, meaning the player has picked the
				-- correct password)
				elseif(numCorrect == string.len(password)) then

					-- End the game
					endGame()
					break
				end
			end
		end
	end

	-- If the player runs out of tries, boot them out of the game
	if(numAttempts <= 0) then

		-- Play a sound
		game.playSound( failSound )

		-- Exit the act after a short delay
		timer.performWithDelay(3000, exitAct)
	end
end

-- Function to generate a real password randomly for a given length
local function generateRealPassword(length)

	-- Initialize the real password
	local pass = ""

	-- For each character in the password
	for i=1,length do

		-- Increment the password with a randomly generated letter (using
		-- lowercase ASCII conversions)
		pass = pass .. string.char(math.random(97, 97 + 25))
	end

	-- Return the generated password
	return pass
end

-- Function to generate a fake password based on a real password and the number
-- of letters that need to be the same
local function generateFakePassword(realPass, numSame)
	
	-- Array to mark selected letter positions from the real password
	local selectPos = {}

	-- Array of characters for building a fake password
	local fakePassArray = {}

	-- For each letter in the real password
	for i=1,string.len(realPass) do

		-- Populate an array to mark which letters have been picked already
		-- based on position in the word
		table.insert(selectPos, false)

		-- Populate an array to build an array of fake characters to construct
		-- into the fake password later
		table.insert(fakePassArray, "")
	end

	-- Variable to hold the fake password
	local fakePass = ""

	-- For the number of letters that need to be the same
	for i=1,numSame do

		--Select a letter position randomly
		local n = math.random(1,string.len(realPass))

		-- Keep randomly selecting letters until the selected position hasn't
		-- been chosen before
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

	-- After building the fake password with parts of the real password, finish
	-- furnishing the fake password with bogus letters until its the same length
	-- as the real password

	for i=1,(string.len(realPass) - numSame) do

		-- Define a variable for holding a randomly generated character
		local r

		-- Define a boolean that checks whether the chosen character exists
		-- in the same spot in the real password already
		local isSame = true

		-- Keep looping for random letters until the selected letter is
		-- different
		while(isSame) do

			-- Select a letter randomly in the alphabet (using lowercase ASCII)
			r = math.random(97, 97+25)

			-- Mark the selected letter as not the same until proven otherwise
			isSame = false

			-- Cycle through the real password and check the randomly chosen
			-- letter against each letter in the real password
			-- If the letter doesn't exist in the real password, append it
			-- to the fake password. If it does, throw it out and retry

			for i=1, string.len(realPass) do

				-- Check the selected letter against each letter of the real
				-- password (using lowercase ASCII)

				local c = string.byte(realPass:sub(i,i))
				
				-- If the characters are the same and in the same spot
				if(r == c) then

					-- Mark that the characters are the same
					isSame = true
					break
				end

			end

		end

		-- Get the character from the randomly generated ascii number
		r = string.char(r)

		-- Insert the bogus letter in the first free position
		for i=1,string.len(realPass) do

			-- If there is a free space in the fake password array
			if(fakePassArray[i] == "") then

				-- Set the free space with the random character
				fakePassArray[i] = r
				break
			end
		end
	end

	-- Create the fake password from the fake pass array
	for i=1,string.len(realPass) do
		fakePass = fakePass .. fakePassArray[i]
	end

	-- Return the fake password
	return fakePass
end

-- Initialize the act
function act:init()
	-- Remember to put all display objects in act.group

	-- Load sounds
	buttonSound = act:loadSound( "sounds/button1.wav" )
	failSound = act:loadSound( "sounds/fail.wav" )
	successSound = act:loadSound( "sounds/pass.wav" )

	-- Create buttons for inputting passwords
	passBtns = {}
	for i=1,NUM_OF_PASSWORDS / 2 do
		passBtns[i] = widget.newButton(
		{
			x = act.xMin + 115,
			y = act.yMin + 90 + i * 55,
			shape = "rect",
			fillColor = { default={ 0, 0, 0 }, over={ 0, 0, 0 } },
			label = "Select",
			width = act.width * 0.1875,
			height = act.width * 0.109375,
			strokeColor = { default={ 0, 1, 0 }, over={ 1, 0, 0 } },
			strokeWidth = 4,
			labelColor = { default={ 0, 1, 0 }, over={ 1, 0, 0 } },
			onRelease = passListener
		})
		act.group:insert(passBtns[i])
	end
	for i=NUM_OF_PASSWORDS / 2 + 1,NUM_OF_PASSWORDS do
		passBtns[i] = widget.newButton(
		{
			x = act.xMax - 0.109375*act.width,
			y = act.yMin + 90 + (i-NUM_OF_PASSWORDS / 2) * 55,
			shape = "rect",
			fillColor = { default={ 0, 0, 0 }, over={ 0, 0, 0 } },
			label = "Select",
			width = act.width * 0.1875,
			height = act.width * 0.109375,
			strokeColor = { default={ 0, 1, 0 }, over={ 1, 0, 0 } },
			strokeWidth = 4,
			labelColor = { default={ 0, 1, 0 }, over={ 1, 0, 0 } },
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
			possPasswords[i] = generateFakePassword(password, 
				math.random(1,PASS_LEN / 2 + 1))
		end
	end

	-- Set the possible password for each button randomly
	for i=1,NUM_OF_PASSWORDS do
		passBtns[i].word = table.remove(possPasswords, 
			math.random(#possPasswords)) 
	end

	-- Initialize the terminal text array 
	terminalText = {}
	
	-- For each line of terminal text
	for i=1,NUM_OF_PASSWORDS+4 do

		-- Set the terminal text
		if(i < 5) then
			terminalText[i] = display.newText( 
				{
					parent = act.group,
					x = act.xMin + act.xCenter,
					y = act.yMin + act.height * 2 / 44 * i,
					text = "test",
					font = native.systemFont,
					align = "left",
					width = 15/16*act.width,
					fontSize = 16,
				} 
			)
		end
		-- Set the positions of the password text
		if(i>=5 and i < 5+NUM_OF_PASSWORDS/2) then
			terminalText[i] = display.newText( 
				{
					parent = act.group,
					x = act.xMin + 0.1875 * act.width,
					y = passBtns[i-4].y,
					text = "test",
					font = native.systemFont,
					align = "left",
					width = 5/16*act.width,
					fontSize = 16,
				} 
			)
		end
		if(i>=5+NUM_OF_PASSWORDS/2) then
			terminalText[i] = display.newText( 
				{
					parent = act.group,
					x = act.xMin + 0.6875 * act.width,
					y = passBtns[i-4].y,
					text = "test",
					font = native.systemFont,
					align = "left",
					width = 5/16*act.width,
					fontSize = 16,
				} 
			)
		end

		-- Set text color to green
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

	-- Set the terminal text for each of the first four lines
	for i=1,4 do
		terminalText[i].text = terminalTexts[i]
	end

	-- For each line of password text, set the password
	for i=1,NUM_OF_PASSWORDS do
		terminalText[i+4].text = string.upper(passBtns[i].word)
	end

	-- If cheat is set, immediately end the game
	if game.cheatMode then
		endGame()
	end
end


------------------------------- End of Activity --------------------------------


-- Corona needs the scene object returned from the act file
return act.scene