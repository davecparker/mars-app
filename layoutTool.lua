-----------------------------------------------------------------------------------------
--
-- layoutTool.lua
--
-- This is a developer tool for the Mars app that just displays the (x, y) coordinates
-- of touch locations within the shipPlan map image.
-----------------------------------------------------------------------------------------

-- Get local reference to the game globals
local game = globalGame

-- Create the act object
local act = game.newAct()


------------------------- Start of Activity --------------------------------

-- Act variables
local shipGroup        -- display group centered on ship
local coordText        -- display object for coordinate display


-- Handle touch event on the map
local function touchMap( event )
	-- Get tap position in shipGroup coords and display in coordText
	local x, y = shipGroup:contentToLocal( event.x, event.y )
	coordText.text = string.format( "(%d, %d)", x, y )
	return true
end

-- Init the act
function act:init()
	-- Display group for ship elements (centered on ship)
	shipGroup = act:newGroup()
	shipGroup.x = act.xCenter
	shipGroup.y = act.yCenter

	-- Map background with touch listener
	local map = act:newImage( "shipPlan.png", { folder = "media/mainAct", parent = shipGroup, width = act.width, x = 0, y = 0 } )
	map:addEventListener( "touch", touchMap )

	-- Text display for coordinates
	coordText = display.newText( act.group, "", act.xMin + 2, act.yMin + 15, native.systemFont, 16 )
	coordText.anchorX = 0
	coordText.anchorY = 0
	coordText:setFillColor( 0 )  -- black
end


------------------------- End of Activity --------------------------------


-- Corona needs the scene object returned from the act file
return act.scene
