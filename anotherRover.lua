-----------------------------------------------------------------------------------------
--
-- anotherRover.lua
--
-- Another failed attempt at a rover game
-----------------------------------------------------------------------------------------

-- Get local reference to the game globals
local game = globalGame

-- Create the act object
local act = game.newAct()

local json = require( "json" )

------------------------- Start of Activity --------------------------------

-- Init the act
function act:init()
	-- Remember to put all display objects in act.group
	-- loads data from media/anotherRover/level1.txt
	-- ALL SHAPES MUST HAVE THE X and Y Coordinates filped, and the x inverted while drawing because of the orientation change
	local level = system.pathForFile( "media/anotherRover/level1.txt", system.ResourceDirectory )
	local objs = json.decodeFile( level )

	-- loops through the loaded level and draws the objects	
	for i = 1, #objs do
		local  obj = objs[i]
		if obj.shape == "square" then
			local o = display.newRect( act.group, act.width - obj.y, obj.x, 50, 50 )
		else
			print( "idk how to draw: " .. obj.shape )
		end
	end

end


------------------------- End of Activity --------------------------------


-- Corona needs the scene object returned from the act file
return act.scene
