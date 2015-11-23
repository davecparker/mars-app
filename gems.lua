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
        sierra =    { x = 26, y = -145, t = "doc", file = "The Sierra", enabled = true },
        crew =      { x = 38, y = -160, t = "doc", file = "Crew Manifest", enabled = true },

        -- In Rover Bay
        rover =     { x = -125, y = 125, t = "act", act = "rover" },
        battR1 =    { x = -120, y = 90, t = "res", res = "kWh", amount = 100 },
        battR2 =    { x = -100, y = 90, t = "res", res = "kWh", amount = 100 },
        battR3 =    { x = -80,  y = 90, t = "res", res = "kWh", amount = 100 },

        -- In Lab
        h2oL1 =     { x = 130,  y = 10, t = "res", res = "h2o", amount = 50, enabled = true  },
        o2L1 =      { x = 130,  y = 30, t = "res", res = "o2", amount = 50, enabled = true  },     
        foodL1 =    { x = 130,  y = 50, t = "res", res = "food", amount = 50, enabled = true  },     
        panel2 =    { x = 130, y = 70, t = "act", act = "circuit", param = 2  },
        msgHist =   { x = 105, y = 70, t = "doc", file = "Message History" },

        -- In Lounge
        panel3 =    { x = 50, y = -70, t = "act", act = "circuit", param = 3  },

        -- In Greenhouse
        h2oG1 =     { x = 30,  y = 120, t = "res", res = "h2o", amount = 20, enabled = true  },
        h2oG2 =     { x = 30,  y = 150, t = "res", res = "h2o", amount = 20, enabled = true  },
        h2oG3 =     { x = 30,  y = 180, t = "res", res = "h2o", amount = 20, enabled = true  },
        plants =    { x = 80,  y = 130, t = "act", act = "greenhouse" },
 
		-- In Engineering room 
		panel1 =	{ x = -10, y = 230, t = "act", act = "circuit", param = 1 },
		battE1 = 	{ x = -50, y = 170, t = "res", res = "kWh", amount = 150, enabled = true  },

        -- In Captain's Quarters
        jordan1 =   { x = 130, y = -90, t = "doc", file = "Jordan - personal log" },
        jordan2 =   { x = 110, y = -90, t = "doc", file = "Jordan - personal log 2" },
        cDevice =   { x = 90, y = -90, t = "doc", file = "Classified - device" },
        cEnergy =   { x = 70, y = -90, t = "doc", file = "Classified - energy source" },

        -- In Crew Quarters
        graham1 =   { x = -24, y = -73, t = "doc", file = "Graham - personal log" },
        graham2 =   { x = -24, y = -60, t = "doc", file = "Graham - personal log 2" },
        moore =     { x = -64, y = -73, t = "doc", file = "Moore - personal log" },
        ellis =     { x = -106, y = -73, t = "doc", file = "Ellis - personal log" },
        shaw1 =     { x = -24, y = 72, t = "doc", file = "Shaw - personal log" },
        shaw2 =     { x = -24, y = 60, t = "doc", file = "Shaw - personal log 2" },
        webb =      { x = -64, y = 72, t = "doc", file = "Webb - personal log" },
        maxwell =   { x = -130, y = -100, t = "doc", file = "Maxwell - personal log" },
	},

	-- Gems on Mars
	onMars = {
	},
}


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

-- Handle touch on a document gem message box
local function touchDocGemMessageBox( event )
    if event.phase == "began" then
        -- Go to Documents view
        game.endMessageBox()
        game.openDoc = nil
        game.selectGameTab( 3, true )
    end
    return true
end

-- Grab the gem with the given icon, display it for the user in a message box, 
-- then mark it as used and remove it from the screen.
function gems.grabGemIcon( icon )
    -- Make text for the message box
    local text
    local gem = icon.gem
    local onTouch = nil
    if gem.t == "doc" then
        text = "File: " .. gem.file
        onTouch = touchDocGemMessageBox
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
    game.messageBox( text, { x = x, y = y, onTouch = onTouch } )

    -- Use and remove the gem
	game.saveState.usedGems[icon.name] = true
    icon:removeSelf()
end	

-- Make a gem icon in the group with the given gem name and data
function gems.newGemIcon( group, name, gem )
    -- Select image based on the icon type
    local image
    local size = 10
    if gem.t == "act" then
        image = "gemStar.png"
        size = 12
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
