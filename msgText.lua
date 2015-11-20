-----------------------------------------------------------------------------------------
--
-- msgText.lua
--
-- The text of all messages sent in the Mars App game.
-----------------------------------------------------------------------------------------

-- Messages have a named index id and a text value.
local msgText = {

	wake1 = "Wake up dude, we need you!",

	wake2 = "We'll explain later, but you need to save the ship right now.",

	spin1 = "You need to stop the ship from spinning.",

	spin2 = "Go to the bridge and use the thrusters to get the ship pointed back directly at Mars.\n" ..
	        "Try to use as little energy as possible, you will need it later.",

	fixPanel1 = "The primary oxygen generator circuit has burned out. Go to the Engineering room " ..
	            "and re-route the power from the backup generator.",

	engCode = "The door code for the Enginneering room is 10 in binary.",

	makeFood1 = "Food supplies are running low. Go to the Greehouse and grow more to have " ..
	            "at least 150 kg on hand for the next phase of the trip.",


	ufo = "Another UFO has been launched!"

}

return msgText
