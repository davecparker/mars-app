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

-- File local variables
local stateStartMoves = 0      -- number of times dot had moved at start of current state
local foodOutSent = false      -- true when out of food message has been sent


-- Ship state sequence data. Entries are indexed by state number and contain:
--     delay (optional)  = delay before start of action in seconds
--     moves (optional)  = number of times user must move on map before start of action
--     action (required) = function that returns next state, true for next, or nil to stay
local shipStateData = {
	{ delay = 5, action =  -- Send awaken messsages
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
	{ moves = 3, action =  -- Data retrieval notification
					function ()
	        			game.sendMessage( "data1" )
        				return true
        			end },
	{ moves = 3, action = 
					function ()
	 					gems.enableShipGem( "shaw1" )
	        			game.sendMessage( "fileS1" )
        				return true
        			end },
	{ moves = 3, action = 
					function ()
	        			game.sendMessage( "fileJ1" )
 						gems.enableShipGem( "jordan1" )
       					return true
        			end },
	{ moves = 3, action =  -- Wait for user to enter Shaw's room
					function ()
						if game.roomEntered( "Shaw" ) then
        					return true
        				end
        			end },
	{ moves = 3, action =  -- Reveal Engineering door code
					function ()
	        			game.sendMessage( "codes" )
        				return true
        			end },
    { delay = 5, action =  -- Notify to fix panel #1 (Engineering)
					function ()
						game.sendMessage( "panel1" )
						gems.enableShipGem( "panel1" )
						game.panelFixed = false
						return true
        			end },
	{ action =  -- Fix panel #1
					function ()
						if game.panelFixed and game.currentActName() == "mainAct" then
							gems.enableShipGem( "panel1", false )
							game.removeAct( "circuit" )
							game.removeAct( "wireCut" )
							return true
						end
        			end },
	{ moves = 3, action = 
					function ()
	 					gems.enableShipGem( "graham1" )
        				game.sendMessages( "antFail", "mcSignal" )
 	 					gems.enableShipGem( "moore" )
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
						if game.food() >= 150 then
							game.messageBox( "Food level restored!" )
							return true
						end
        			end },
	{ moves = 3, action = 
					function ()
	        			game.sendMessage( "podStatus" )
        				return true
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
						if game.panelFixed and game.currentActName() == "mainAct" then
							gems.enableShipGem( "panel2", false )
							game.removeAct( "circuit" )
							game.removeAct( "wireCut" )
							return true
						end        			end },
	{ moves = 3, action =  -- Send course correction #2 messages
					function ()
	 					gems.enableShipGem( "graham2" )
						gems.enableShipGem( "msgHist" )
	        			game.sendMessage( "correct2" )
	        			ss.thrustNav.onTarget = false
 						gems.enableShipGem( "fly1" )
       					return true
        			end },
	{ action =  -- Course correction #2
					function ()
						if ss.thrustNav.onTarget then
							gems.enableShipGem( "fly1", false )
        					return true
        				end
        			end },
	{ delay = 5, action =  -- Send land message
					function ()
 	        			game.sendMessage( "docs" )
						gems.enableShipGem( "jordan2" )
 						gems.enableShipGem( "webb" )
 						gems.enableShipGem( "shaw2" )
	 					gems.enableShipGem( "ellis" )
	 					gems.enableShipGem( "maxwell" )
						gems.enableShipGem( "cDevice" )
						gems.enableShipGem( "cEnergy" )
	        			game.sendMessage( "land" )
        				return true
        			end },
	{ moves = 3, action =  -- Notify to fix panel #3
					function ()
						game.sendMessage( "panel3" )
						gems.enableShipGem( "panel3" )
						game.panelFixed = false
						return true
        			end },
	{ action =  -- Fix panel #3
					function ()
						if game.panelFixed and game.currentActName() == "mainAct" then
							gems.enableShipGem( "panel3", false )
							game.removeAct( "circuit" )
							game.removeAct( "wireCut" )
							return true
						end        			
					end },
					---
					-- TODO: shipLanding act here
					---
	{ delay = 2, action =  -- Landed
					function ()
						game.landShip()
	        			game.sendMessages( "landed", "mars1" )
        			end },
    ----- Ship State Table ends when ship has landed on Mars -----
} 

-- Update the game state sequence when on the ship. The current state number
-- is passed, and the new state number is returned.
local function updateShipState( state )
	-- Calculate number of seconds and moves since current state started
	local sec = (system.getTimer() - game.stateStartTime) / 1000
	local moves = game.moves - stateStartMoves

	-- Get state data for this state and execute
	local stateData = shipStateData[state]
	if stateData then
		-- Make sure the required number of moves and delay time has occurred
		if not stateData.moves or moves >= stateData.moves then
			if not stateData.delay or sec >= stateData.delay then
				-- Execute the state action
				local nextState = stateData.action()
				if nextState then
					if nextState == true then 
						nextState = state + 1
					end
					return nextState
				end
			end
		end
	end
    return state  -- no state change
end

-- Update the game state when on Mars.
local function updateMarsState()
	-- Is emergency stasis needed?
	gems.enableShipGem( "stasis", ss.stasis )
	if ss.stasis then
		-- Rover disabled when stasis needed
		gems.enableShipGem( "rover", false )
	else
		-- Use a little food and water over time
		game.addFood( -0.5 )
		game.addWater( -0.25 )

		-- Need food to take the rover out
		local hasFood = (game.food() > 0)
		gems.enableShipGem( "rover", hasFood )

		-- If on the ship (not out in the rover), check notifications
		if game.currentActName() == "mainAct" then
			if hasFood then
				foodOutSent = false  -- ready to notify if food runs out (again)
			else
				-- Out of food. Send messsage if not already sent.
				if not foodOutSent then
					game.sendMessage( "foodOut" )
					foodOutSent = true
				end

				-- Check water level
				if game.water() <= 0 then
					-- Out of both food and water. Emergency stasis.
					game.sendMessage( "resOut" )
					ss.stasis = true
					game.updateState()
				end
			end
		end
	end
end

-- Set the ship state to the given state number
function game.setShipState( state )
	ss.shipState = state
	game.stateStartTime = system.getTimer()
	stateStartMoves = game.moves
	print( "Ship state " .. state )
end

-- This function is called every second while the game is running, but it 
-- can also be called whenever an immediate game state update is desired. 
function game.updateState()
	-- If game is paused then just reset timer and do nothing
	if game.paused then
		game.stateStartTime = system.getTimer()
	end

	-- Are we on Mars yet?
	if ss.onMars then
		updateMarsState()
	else
		-- Not on Mars yet. Game state proceeds in a sequence.
		local newState = updateShipState( ss.shipState )
		if newState ~= ss.shipState then
			game.setShipState( newState )
		end
	end
end

