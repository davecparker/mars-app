-----------------------------------------------------------------------------------------
--
-- gems.lua
--
-- Data and methods for the gems in the Mars App game.
-----------------------------------------------------------------------------------------

-- Get local reference to the game globals
local game = globalGame


-- The different gem data table formats are:
--    Act link: { x = xCoord, y = yCoord, t = "act", act = actName, param = optionalData }
--    Document: { x = xCoord, y = yCoord, t = "doc", file = fileName }
--    Resource: { x = xCoord, y = yCoord, t = "res", res = "o2"/"h2o"/"kWh"/"food", amount = n }

-- All gems in the game
local gems = {
	-- Gems on the ship
	onShip = {
        -- In Bridge
        fly1 =      { x = 0, y = -230, t = "act", act = "thrustNav", param = 1 },

        -- In Rover Bay
        rover =     { x = -125, y = 125, t = "act", act = "rover" },
        battR1 =    { x = -120, y = 90, t = "res", res = "kWh", amount = 100 },
        battR2 =    { x = -100, y = 90, t = "res", res = "kWh", amount = 100 },
        battR3 =    { x = -80,  y = 90, t = "res", res = "kWh", amount = 100 },

        -- In Lab
        h2oL1 =     { x = 130,  y = 10, t = "res", res = "h2o", amount = 50 },
        o2L1 =      { x = 130,  y = 30, t = "res", res = "o2", amount = 50 },     
        foodL1 =    { x = 130,  y = 50, t = "res", res = "food", amount = 50 },     
        codeDoc1 =  { x = 80, y = 70, t = "doc", file = "Security Announcement" },
        resDoc1 =   { x = 110, y = 70, t = "doc", file = "Resource Management" },
 
		-- In Engineering room 
		panel1 =	{ x = -10, y = 230, t = "act", act = "circuit", param = 1, },
		panel2 =	{ x = -40, y = 230, t = "act", act = "circuit", param = 2, },
		panelDoc = 	{ x = -85, y = 230, t = "doc", file = "Circuit Manual" },
		battE1 = 	{ x = -50, y = 170, t = "res", res = "kWh", amount = 150 },
	},

	-- Gems on Mars
	onMars = {
	},
}

-- Return true if the gem with the given name has been used
function gems.gemIsUsed( name )
	return game.saveState.usedGems[name]
end

-- Grab the gem with the given icon, display it for the user in a message box, 
-- then mark it as used and remove it from the screen.
function gems.grabGemIcon( icon )
    -- Make text for the message box
    local text
    local gem = icon.gem
    if gem.t == "doc" then
        text = gem.file
    elseif gem.t == "res" then
        local res = gem.res
        local format
        if res == "o2" then
            format = "%d liters of Oxygen"
        elseif res == "h2o" then
            format = "%d liters of Water"
        elseif res == "kWh" then
            format = "%d kWh of Energy"
        elseif res == "food" then
            format = "%d kg of food"
        else
            return  -- malformed gem
        end
        text = string.format( format, gem.amount )
    else
        return  -- not a grabable gem
    end

    -- Display message box zooming out from the gem's location
    local x, y = icon:localToContent( 0, 0 )
    game.messageBox( text, { x = x, y = y } )

    -- Use and remove the gem
	game.saveState.usedGems[icon.name] = true
    icon:removeSelf()
end	

-- Make a gem icon in the group with the given gem name and data
function gems.newGemIcon( group, name, gem )
    -- Create a rotating rectangle with a black frame and tap listener
    local icon = display.newRect( group, gem.x, gem.y, 6, 6 )
    icon:setStrokeColor( 0 )   -- black
    icon.strokeWidth = 1
    transition.to( icon, { delta = true, rotation = 360, time = 3000, iterations = 0 })

    -- Set the fill color based on the icon type
    if gem.t == "act" then
        icon:setFillColor( 1, 0, 0 )  -- red
    elseif gem.t == "doc" then
        icon:setFillColor( 1, 1, 0 )  -- yellow
    else
        icon:setFillColor( 0, 1, 0 )  -- green
    end

    -- Store the gem name and data inside the icon
    icon.name = name
	icon.gem = gem
    return icon
end


return gems
