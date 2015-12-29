-----------------------------------------------------------------------------------------
--
-- resources.lua
--
-- The resources view for the Mars App.
-----------------------------------------------------------------------------------------

-- This view is currently unused
--[[

-- Get local reference to the game globals
local game = globalGame

-- Create the act object
local act = game.newAct()


------------------------- Start of Activity --------------------------------

-- File local variables
local h2oLabel
local kWhLabel
local foodLabel


-- Create a text label at the given y location and initally empty text
local function makeLabel( y )
	local t = display.newText( act.group, "", act.xCenter, y, native.systemFontBold, 24 )
	t:setFillColor( 0 )   -- black text
	return t
end

-- Init the act
function act:init()
	-- Background and title bar for the view
	act:whiteBackground()
	act:makeTitleBar( "Resources" )

	-- Make simple text labels for now
	local dySpacing = 50
	local yStart = act.yMin + act.dyTitleBar
	h2oLabel = makeLabel( yStart + dySpacing * 2 )
	kWhLabel = makeLabel( yStart + dySpacing * 3 )
	foodLabel = makeLabel( yStart + dySpacing * 4 )
end

-- Refresh the labels to read current values
function act:prepare()
	h2oLabel.text = string.format( "Water: %d liters", game.water() )
	kWhLabel.text = string.format( "Energy: %d kWh", game.energy() )
	foodLabel.text = string.format( "Food: %d kg", game.food() )
end


------------------------- End of Activity --------------------------------


-- Corona needs the scene object returned from the act file
return act.scene

--]]
