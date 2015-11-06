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
function dropsDone( drops )
	drops:removeSelf()
end

-- Touch handler for plants
function touchPlant( event )
	if event.phase == "began" then
		local plant = event.target

		-- Tapping on a plant with fruit harvests it
		if plant.fruit then
			plant.fruit:removeSelf()
			plant.fruit = nil
			plant.health = 0   -- plant is taken for food
			game.addFood( 10 )
		end

		-- Tapping on a dead plant removes it
		if plant.health <= 0 then
			plant:removeSelf()
			return true
		end

		-- Water improves the plant's health
		plant.health = game.pinValue( plant.health + 20, 0, maxHealth )

		-- Make a group of 3 drops
		local drops = act:newGroup()
		drops.x = event.x
		drops.y = event.y - 40  -- will animate down to the touch point
		local dropSize = 12
		act:newImage( "drop.png", { parent = drops, x = 3, y = -4, width = dropSize } )
		act:newImage( "drop.png", { parent = drops, x = -3, y = -8, width = dropSize } )
		act:newImage( "drop.png", { parent = drops, x = 0, y = 0, width = dropSize } )

		-- Animate the drops falling
		transition.to( drops, { y = event.y, xScale = 2, yScale = 2,
				time = 500, onComplete = dropsDone } )
	end
	return true
end

-- Touch handler for the dirt background
function touchDirt( event )
	if event.phase == "began" then
		local plant = act:newImage( "plant.png", { parent = plants, width = 40 } )
		plant.x = event.x
		plant.y = event.y
		plant:setFillColor( 0, 0.6, 0 )
		plant.health = maxHealth
		plant.age = 0
		plant:addEventListener( "touch", touchPlant )
	end
	return true
end

-- Called for each timer tick
function timerTick()
	-- Grow/age all the plants
	for i = 1, plants.numChildren do
		local plant = plants[i]
		plant.age = plant.age + 1
		plant.health = game.pinValue( plant.health - 1, 0, maxHealth )

		-- Interpolate plant color based on health
		local deadColor = { r = 0.5, g = 0.4, b = 0.2 }  -- brown
		local goodColor = { r = 0.0, g = 0.6, b = 0.0 }  -- green
		local hf = plant.health / 100
		local ihf = 1 - hf
		local r = ihf * deadColor.r + hf * goodColor.r 
		local g = ihf * deadColor.g + hf * goodColor.g 
		local b = ihf * deadColor.b + hf * goodColor.b 
		plant:setFillColor( r, g, b )  

		-- Mature healthy plants make fruit
		if plant.age > 120 and plant.health > 70 then
			if not plant.fruit then
				plant.fruit = act:newImage( "fruit.png", { width = 40,
									x = plant.x, y = plant.y + 20 } )
			end
		end

		-- Healthy plants grow (up to a certain age)
		if plant.age < 100 and plant.health > 50 then
			local newScale = plant.xScale * 1.01
			transition.cancel( plant )
			transition.to( plant, { xScale = newScale, yScale = newScale, time = msTimer } )
		end
	end
end

-- Init the act
function act:init()
	-- Dirt background
	local dirt = act:newImage( "dirt.jpg", { height = act.height } )
	dirt:addEventListener( "touch", touchDirt )

	-- Group for plants
	plants = act:newGroup()

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
