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

	ufo = "Another UFO has been launched!",

	-------------------------------------------------------

	antFail = "SAS - Antenna array status report\n" .. 
			  "Critical antenna array failure. Communication with Mission Control terminated.",

	correct1 = "SAS - Approaching Mars. Manual trajectory alignment required. Report to the bridge immediately.",
	
	data1 = "SAS - Data corruption, multiple files. Data retrieval in progress. Stand by.",

	green1 = "SAS - Report to the Greenhouse. Irrigation system down. Manual irrigation required. Urgent.",

	land = "SAS - Mars orbit achieved. Commence Sierra landing procedure.",

	landed = "SAS - Landing target achieved. Congratulations Sierra crew, " ..
	         "you've just established the first settlement on Mars!",	

	panelEng = "SAS - Panel 22A repair required. Report to engineering.",

	panelGraham = "SAS - Panel 57C repair required. Report to Graham's quarters.",

	panelJordan = "SAS - Panel 65A repair required. Report to Commander Jordan's quarters.",

	podStatus = "SAS - Stasis pod status report\n" ..
				"Pod 1, Jordan, empty\n" ..
				"Pod 2, Maxwell, empty\n" ..
				"Pod 3, Shaw, damaged, occupant deceased\n" ..
				"Pod 4, Ellis, damaged, occupant deceased\n" ..
				"Pod 5, Graham, empty\n" ..
				"Pod 6, yours, empty\n" ..
				"Pod 7, Webb, damaged, occupant deceased\n" ..
				"Pod 8, Moore, empty",

	stasis1 = "SAS - You have been brought out of stasis. Automated systems compromised. " ..
	          "Manual course correction required. Report to the bridge immediately.",	  

}

return msgText
