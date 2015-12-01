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
--    Resource: { t = "res", res = "h2o"/"kWh"/"food", amount = n }

-- All gems in the game
local gems = {
	-- Gems on the ship
	onShip = {
        -- In Bridge
        fly1 =      { x = 0, y = -230, t = "act", act = "thrustNav", param = 1, enabled = true },
        sierra =    { x = -27, y = -226, t = "doc", file = "The Sierra", enabled = true },
        crew =      { x = 25, y = -226, t = "doc", file = "Crew Manifest", enabled = true },

        -- In Rover Bay
        rover =     { x = -90, y = 140, t = "act", act = "rover" },
        battR1 =    { x = -120, y = 100, t = "res", res = "kWh", amount = 100 },
        battR2 =    { x = -100, y = 100, t = "res", res = "kWh", amount = 100 },
        battR3 =    { x = -80,  y = 100, t = "res", res = "kWh", amount = 100 },

        -- In Lab
        h2oL1 =     { x = 124,  y = 106, t = "res", res = "h2o", amount = 50, enabled = true  },
        foodL1 =    { x = 124,  y = 123, t = "res", res = "food", amount = 50, enabled = true  },     
        panel2 =    { x = 124, y = 164, t = "act", act = "circuit", param = 2  },
        msgHist =   { x = 42, y = 103, t = "doc", file = "Message History" },

        -- In Lounge
        panel3 =    { x = 121, y = -103, t = "act", act = "circuit", param = 3  },

        -- In Greenhouse
        h2oG1 =     { x = -65,  y = -120, t = "res", res = "h2o", amount = 20, enabled = true  },
        h2oG2 =     { x = -65,  y = -103, t = "res", res = "h2o", amount = 20, enabled = true  },
        plants =    { x = -87,  y = -141, t = "act", act = "greenhouse" },
 
		-- In Engineering room 
		panel1 =	{ x = 38, y = 243, t = "act", act = "circuit", param = 1 },
		battE1 = 	{ x = -53, y = 200, t = "res", res = "kWh", amount = 150, enabled = true  },

        -- In Captain Jordan's Quarters
        jordan1 =   { x = -69, y = -44, t = "doc", file = "Jordan - personal log" },
        jordan2 =   { x = -69, y = -31, t = "doc", file = "Jordan - personal log 2" },
        cDevice =   { x = -32, y = -44, t = "doc", file = "Classified - device" },
        cEnergy =   { x = -32, y = -31, t = "doc", file = "Classified - energy source" },

        -- In Crew Quarters
        graham1 =   { x = -128, y = -44, t = "doc", file = "Graham - personal log" },
        graham2 =   { x = -128, y = -31, t = "doc", file = "Graham - personal log 2" },
        moore =     { x = 128, y = -44, t = "doc", file = "Moore - personal log" },
        ellis =     { x = -130, y = 35, t = "doc", file = "Ellis - personal log" },
        shaw1 =     { x = -68, y = 18, t = "doc", file = "Shaw - personal log" },
        shaw2 =     { x = -68, y = 35, t = "doc", file = "Shaw - personal log 2" },
        webb =      { x = 65, y = 35, t = "doc", file = "Webb - personal log" },
        maxwell =   { x = 67, y = -44, t = "doc", file = "Maxwell - personal log" },
	},

	-- Gems on Mars
	onMars = {
	},
}

-- File local variables
local gemGrabbed       -- the most recent gem grabbed by the user


-- Return true if the ship gem with the given name is active (enabled and not used)
function gems.shipGemIsActive( name )
    return game.allGems or (gems.onShip[name].enabled and not game.saveState.usedGems[name])
end

-- Enable or disable (default enable) the ship gem with the given name
function gems.enableShipGem( name, enable )
    if enable == nil then
        enable = true
    end
    gems.onShip[name].enabled = enable
end

-- Handle touch on a gem message box
local function touchGemMessageBox( event )
    if event.phase == "began" then
        game.endMessageBox()

        -- Do action associated with the gem message, if any
        if gemGrabbed then
            if gemGrabbed.t == "doc" then
                -- Open the gem's document 
                game.openDoc = gemGrabbed.file
                game.gotoTab( "documents" )
            elseif gemGrabbed.t == "res" then
                -- Go to Resources view
                game.gotoTab( "resources" )
            end
        end
    end
    return true
end

-- Grab the gem with the given icon, display it for the user in a message box, 
-- then mark it as used and remove it from the screen.
function gems.grabGemIcon( icon )
    gemGrabbed = icon.gem

    -- Make text for the message box
    local text
    if gemGrabbed.t == "doc" then
        text = "File: " .. gemGrabbed.file
    elseif gemGrabbed.t == "res" then
        local res = gemGrabbed.res
        local format
        if res == "h2o" then
            format = "%d liters of Water"
        elseif res == "kWh" then
            format = "%d kWh of Energy"
        elseif res == "food" then
            format = "%d kg of food"
        else
            return  -- malformed gem
        end
        text = string.format( format, gemGrabbed.amount )
    else
        return  -- not a grabable gem
    end

    -- Display message box zooming out from the gem's location
    local x, y = icon:localToContent( 0, 0 )
    game.messageBox( text, { x = x, y = y, onTouch = touchGemMessageBox } )

    -- Use and remove the gem
	game.saveState.usedGems[icon.name] = true
    icon:removeSelf()
end	

-- Make a gem icon in the group with the given gem name and data
function gems.newGemIcon( group, name, gem )
    -- Select image based on the icon type
    local image
    local size = 20
    if gem.t == "act" then
        image = "gemStar.png"
        size = 24
    elseif gem.t == "doc" then
        image = "gemDoc.png"
    else
        image = "gemRes.png"
    end

    -- Create a rotating image
    local icon = display.newImageRect( group, "media/game/" .. image, size, size )
    icon.x = gem.x
    icon.y = gem.y
    transition.to( icon, { delta = true, rotation = 360, time = 3000, iterations = 0 })

    -- Store the gem name and data inside the icon
    icon.name = name
	icon.gem = gem
    return icon
end


return gems
