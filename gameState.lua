-----------------------------------------------------------------------------------------
--
-- gameState.lua
--
-- Data and functions to manage the game state sequence and logic.
-----------------------------------------------------------------------------------------

local game = globalGame
local gems = require( "gems" )

-- Shortcut access to game's saved state
local ss = game.saveState


-- Ship state sequence data. Entries are indexed by state number and contain:
--     delay (optional)  = delay before start of action in seconds
--     action (required) = function that returns next state, true for next, or nil to stay
local shipStateData = {
	{ delay = 2, action =  -- Send awaken messsages
					function ()
			        	game.sendMessages( "sas1", "stasis1" )
        				return true
        			end },
	{ action =  -- Wait for user to be in the Bridge
					function ()
						if game.roomName() == "Bridge" then
        					return true
        				end
        			end },
	{ delay = 1, action =  -- Send course correction #1 message
					function ()
	        			game.sendMessage( "correct1" )
        				return true
        			end },
	{ action =  -- Course correction #1
					function ()
						if ss.thrustNav.onTarget then
							gems.enableShipGem( "fly1", false )
        					return true
        				end
        			end },
	{ delay = 2, action = 
					function ()
	        			game.sendMessage( "data1" )
        				return true
        			end },
	{ delay = 2, action = 
					function ()
	        			game.sendMessage( "antFail" )
        				return true
        			end },
    { delay = 5, action =  -- Notify to fix panel #1
					function ()
						game.sendMessages( "panel1" )
						gems.enableShipGem( "panel1" )
						game.panelFixed = false
						return true
        			end },
	{ action =  -- Fix panel #1
					function ()
						if game.panelFixed then
							return true
						end
        			end },
	{ delay = 2, action = 
					function ()
	        			game.sendMessage( "podStatus" )
        				return true
        			end },
	{ delay = 5, action =  -- Notify to tend greenhouse
					function ()
						game.sendMessage( "green1" )
						gems.enableShipGem( "plants" )
						return true
        			end },
	{ action =  -- Greenhouse to get more food
					function ()
						if game.food() > 150 then
							return true
						end
        			end },

	{ delay = 2, action =  -- Notify to fix panel #2
					function ()
						game.sendMessage( "panel2" )
						gems.enableShipGem( "panel2" )
						game.panelFixed = false
						return true
        			end },
	{ action =  -- Fix panel #2
					function ()
						if game.panelFixed then
							return true
						end
        			end },
	{ delay = 3, action =  -- Send course correction #2 messages
					function ()
	        			game.sendMessages( "correct2" )
	        			ss.thrustNav.onTarget = false
 						gems.enableShipGem( "fly1" )
       				return true
        			end },
	{ action =  -- Course correction #2
					function ()
						if ss.thrustNav.onTarget then
        					return true
        				end
        			end },
	{ delay = 2, action =  -- Notify to fix panel #3
					function ()
						game.sendMessage( "panel3" )
						gems.enableShipGem( "panel3" )
						game.panelFixed = false
						return true
        			end },
	{ action =  -- Fix panel #3
					function ()
						if game.panelFixed then
							return true
						end
        			end },
	{ delay = 3, action =  -- Send course correction #2 messages
					function ()
	        			game.sendMessage( "land" )
        				return true
        			end },
	{ delay = 2, action =  -- Landed
					function ()
	        			game.sendMessage( "landed" )
						ss.onMars = true
						gems.enableShipGem( "rover" )
        			end },
} 

-- Update the game state sequence when on the ship. The current state number
-- is passed, and the new state number is returned.
local function updateShipState( state )
	-- Calculate number of seconds since current state started
	local sec = (system.getTimer() - game.stateStartTime) / 1000

	-- Get state data for this state and execute
	local stateData = shipStateData[state]
	if stateData then
		if not stateData.delay or sec >= stateData.delay then
			local nextState = stateData.action()
			if nextState then
				if nextState == true then 
					nextState = state + 1
				end
				return nextState
			end
		end
	end
    return state  -- no state change
end

-- Update the game state when on Mars.
local function updateMarsState()
	-- TODO
end

-- This function is called every second while the game is running, but it 
-- can also be called whenever an immediate game state update is desired. 
function game.updateState()
	if ss.onMars then
		-- On Mars
		updateMarsState()
	else
		-- Not on Mars yet. Game state proceeds in a sequence.
		local newState = updateShipState( ss.shipState )
		if newState ~= ss.shipState then
			ss.shipState = newState
			game.stateStartTime = system.getTimer()
			print( "Ship state " .. newState )
		end
	end
end
