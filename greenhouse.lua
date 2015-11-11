-----------------------------------------------------------------------------------------
--
-- greenhouse.lua
--
-- The greenhouse game for the Mars App
-- The user can plant, water, and harvest vegetables for food.
-----------------------------------------------------------------------------------------

-- Get local reference to the game globals
local game = globalGame

-- Create the act object
local act = game.newAct()


-- Constants
local msTimer = 100    -- timer interval
local maxHealth = 100  -- plant health ranges from 0 to 100

-- File local variables
local plants   -- group for all the plants
local timerID  -- repeating timer


-- Called when the drops are done animating
local function dropsDone( drops )
	-- Water increases the plant's health
	drops.plant.health = game.pinValue( drops.plant.health + 25, 0, maxHealth )
	drops:removeSelf()
end

-- Water the plant
local function waterPlant( plant )
	-- Make a group of 3 drops
	local drops = act:newGroup()
	drops.x = plant.x
	drops.y = plant.y - 60  -- will animate down to the touch point
	local dropSize = 12
	act:newImage( "drop.png", { parent = drops, x = 3, y = -4, width = dropSize } )
	act:newImage( "drop.png", { parent = drops, x = -3, y = -8, width = dropSize } )
	act:newImage( "drop.png", { parent = drops, x = 0, y = 0, width = dropSize } )
	drops.plant = plant
	game.addWater( -1 )

	-- Animate the drops falling
	transition.to( drops, { y = plant.y - 20, xScale = 2, yScale = 2,
			time = 500, onComplete = dropsDone } )
end

-- Remove the plant
local function removePlant( plant )
	if plant.flowers then
		plant.flowers:removeSelf()
	end
	plant:removeSelf()
end

-- Touch handler for plants
local function touchPlant( event )
	if event.phase == "began" then
		local plant = event.target

		-- Process plant based on its state
		if plant.health <= 0 then
			removePlant( plant )    -- Remove dead plant
		elseif plant.flowers then
			-- Harvest this plant
			removePlant( plant )
			game.addFood( 10 )
			game.messageBox( "10 kg of food")
		elseif game.water() <= 0 then
			game.messageBox( "Out of water!" )
		else
			waterPlant( plant )
		end
	end
	return true
end

-- Make a new plant at the given location
local function makePlant( x, y )
	local size = 40
	local plant = act:newImage( "plant.png", { parent = plants, height = size } )
	plant.x = x
	plant.y = y + size / 2
	plant.anchorY = 1   -- grow from bottom up
	plant:setFillColor( 0, 0.6, 0 )
	plant.health = maxHealth
	plant:addEventListener( "touch", touchPlant )
end

-- Touch handler for the dirt background
local function touchDirt( event )
	if event.phase == "began" then
		makePlant( event.x, event.y )
	end
	return true
end

-- Set a plant's color based on its health
local function adjustPlantColor( plant )
	if plant.health <= 0 then
		-- Color dead plants dark brown and remove flowers
		plant:setFillColor( 0.5, 0.25, 0 )
		if plant.flowers then
			plant.flowers:removeSelf()
		end
	else
		-- Interpolate plant color based on health
		local deadColor = { r = 0.5, g = 0.4, b = 0.0 }   -- brown
		local goodColor = { r = 0.0, g = 0.6, b = 0.0 }   -- green
		local hf = plant.health / 100
		local ihf = 1 - hf
		local r = ihf * deadColor.r + hf * goodColor.r 
		local g = ihf * deadColor.g + hf * goodColor.g 
		local b = ihf * deadColor.b + hf * goodColor.b 
		plant:setFillColor( r, g, b )
		-- TODO: wither flowers  
	end
end

-- Add flowers to the plant if it doesn't already have them
local function addFlowers( plant )
	if not plant.flowers then
		local flowers = act:newGroup()
		flowers.x = plant.x
		flowers.y = plant.y
		local size = 25
		act:newImage( "flower.png", { parent = flowers, width = size, x = 0, y = -50 } )
		act:newImage( "flower.png", { parent = flowers, width = size, x = 20, y = -30} )
		act:newImage( "flower.png", { parent = flowers, width = size, x = -10, y = -20 } )
		plant.flowers = flowers
	end
end

-- Called for each timer tick
local function timerTick()
	-- Grow/adjust all the plants
	for i = 1, plants.numChildren do
		-- Time decreases plant health due to need for more water
		local plant = plants[i]
		plant.health = game.pinValue( plant.health - 1, 0, maxHealth )
		adjustPlantColor( plant )

		if plant.xScale >= 3 and plant.health >= 70 then
			-- Large, healthy plants make flowers and are ready to pick for food
			addFlowers( plant )
		elseif plant.xScale < 3 and plant.health > 80 then
			-- Healthy plants grow (up to a certain size)
			local newScale = plant.xScale * 1.02
			transition.cancel( plant )
			transition.to( plant, { xScale = newScale, yScale = newScale, time = msTimer } )
		end
	end
end

-- Handle tap on the back button
local function backButtonPress ( event )
	game.gotoAct ( "mainAct" )
	return true
end

-- Init the act
function act:init()
	-- Dirt background
	local dirt = act:newImage( "dirt.jpg", { height = act.height } )
	dirt:addEventListener( "touch", touchDirt )

	-- Group for plants
	plants = act:newGroup()

	-- back button
	local backButton = act:newImage( "backButton.png", { width = 50 } )
	backButton.x = act.xMin + 30
	backButton.y = act.yMin + 30
	backButton:addEventListener( "tap", backButtonPress )
	backButton:addEventListener( "touch", game.eatTouch )
end

-- Prepare the act
function act:prepare()
	-- Start a repeating timer for time action
	timerID = timer.performWithDelay( msTimer, timerTick, 0 )
end

-- Stop the act
function act:stop()
	-- TODO: Keep timer running when act is not active?
	if timerID then
		timer.cancel( timerID )
		timerID = nil
	end
end


-- Corona needs the scene object returned from the act file
return act.scene
