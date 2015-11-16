-----------------------------------------------------------------------------------------
--
-- gems.lua
--
-- Data and methods for the gems in the Mars App game.
-----------------------------------------------------------------------------------------

-- Get local reference to the game globals
local game = globalGame


-- The gem data table formats all include: 
--    { x = xCoord, y = yCoord, enabled = true/nil }
-- plus additional data depending on the type of the gem:
--    Act link: { t = "act", act = actName, param = optionalData }
--    Document: { t = "doc", file = fileName }
--    Resource: { t = "res", res = "o2"/"h2o"/"kWh"/"food", amount = n }

-- All gems in the game
local gems = {
	-- Gems on the ship
	onShip = {
        -- In Bridge
        fly1 =      { x = 0, y = -230, t = "act", act = "thrustNav", param = 1, enabled = true },

        -- In Rover Bay
        rover =     { x = -125, y = 125, t = "act", act = "rover", enabled = true },
        battR1 =    { x = -120, y = 90, t = "res", res = "kWh", amount = 100, enabled = true  },
        battR2 =    { x = -100, y = 90, t = "res", res = "kWh", amount = 100, enabled = true  },
        battR3 =    { x = -80,  y = 90, t = "res", res = "kWh", amount = 100, enabled = true  },

        -- In Lab
        h2oL1 =     { x = 130,  y = 10, t = "res", res = "h2o", amount = 50, enabled = true  },
        o2L1 =      { x = 130,  y = 30, t = "res", res = "o2", amount = 50, enabled = true  },     
        foodL1 =    { x = 130,  y = 50, t = "res", res = "food", amount = 50, enabled = true  },     
        codeDoc1 =  { x = 80, y = 70, t = "doc", file = "Security Announcement" },
        resDoc1 =   { x = 110, y = 70, t = "doc", file = "Resource Management", enabled = true  },

        -- In Greenhouse
        h2oG1 =     { x = 30,  y = 120, t = "res", res = "h2o", amount = 20, enabled = true  },
        h2oG2 =     { x = 30,  y = 150, t = "res", res = "h2o", amount = 20, enabled = true  },
        h2oG3 =     { x = 30,  y = 180, t = "res", res = "h2o", amount = 20, enabled = true  },
        plants =    { x = 80,  y = 130, t = "act", act = "greenhouse", enabled = true },
 
		-- In Engineering room 
		panel1 =	{ x = -10, y = 230, t = "act", act = "circuit", param = 1, enabled = true },
		panel2 =	{ x = -40, y = 230, t = "act", act = "circuit", param = 2, enabled = true  },
		panelDoc = 	{ x = -85, y = 230, t = "doc", file = "Circuit Manual", enabled = true  },
		battE1 = 	{ x = -50, y = 170, t = "res", res = "kWh", amount = 150, enabled = true  },
	},

	-- Gems on Mars
	onMars = {
	},
}


-- Return true if the ship gem with the given name is active (enabled and not used)
function gems.shipGemIsActive( name )
    return gems.onShip[name].enabled and not game.saveState.usedGems[name]
end

-- Enable or disable (default enable) the ship gem with the given name
function gems.enableShipGem( name, enable )
    gems.onShip[name].enabled = enable or true
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
