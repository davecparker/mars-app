-----------------------------------------------------------------------------------------
--
-- resources.lua
--
-- The resources view for the Mars App.
-----------------------------------------------------------------------------------------

-- Get local reference to the game globals
local game = globalGame

-- Create the act object
local act = game.newAct()


------------------------- Start of Activity --------------------------------

-- File local variables
local o2Label
local h2oLabel
local kWhLabel
local foodLabel


-- Create a text label at the given y location and initally empty text
local function makeLabel( y )
	local t = display.newText( act.group, "Hey", act.xCenter, y, native.systemFontBold, 24 )
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
	o2Label = makeLabel( yStart + dySpacing )
	h2oLabel = makeLabel( yStart + dySpacing * 2 )
	kWhLabel = makeLabel( yStart + dySpacing * 3 )
	foodLabel = makeLabel( yStart + dySpacing * 4 )

	-- Post a new document (TODO: Temporary)
	game.foundDocument( "Resource Management" )
end

-- Refresh the labels to read current values
function act:prepare()
	local r = game.saveState.resources
	o2Label.text = string.format( "Oxygen: %d liters",  r.o2)
	h2oLabel.text = string.format( "Water: %d liters", r.h2o )
	kWhLabel.text = string.format( "Energy: %d kWh", r.kWh )
	foodLabel.text = string.format( "Food: %d kg", r.food )
end


------------------------- End of Activity --------------------------------


-- Corona needs the scene object returned from the act file
return act.scene
