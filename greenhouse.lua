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
local plants           -- group for all the plants
local timerID          -- repeating timer
local waterHintShown   -- true when the hint to water plants has been shown
local nPlantsDied = 0  -- total number of plants that have died
local nWaterings = 0   -- total number of times user has watered any plant
local waterText        -- water readout label
local foodText         -- food readout label
local waterLight       -- water status light
local foodLight        -- food status light


-- Update a resource light's color based on its value, warning level, and low level
local function setResLightColor( light, value, low, warning )
	if value < low then
		light:setFillColor( 1, 0, 0 )  -- red for low
	elseif value < warning then
		light:setFillColor( 1, 1, 0 )  -- yellow for warning
	else
		light:setFillColor( 0, 1, 0 )  -- green
	end
end

-- Update food and water level display
local function updateResDisplay()
	waterText.text = string.format( "Water: %d liters", game.water() )
	foodText.text = string.format( "Food: %d kg", game.food() )
	setResLightColor( waterLight, game.water(), 50, 100 )
	setResLightColor( foodLight, game.food(), 50, 150 )
end

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
	updateResDisplay()

	-- Animate the drops falling with sound effect
	game.playSound( act.wateringSound )
	transition.to( drops, { y = plant.y - 20, xScale = 2, yScale = 2,
			time = 500, onComplete = dropsDone } )
end

-- Touch handler for plants
local function touchPlant( event )
	if event.phase == "began" then
		local plant = event.target

		-- Process plant based on its state
		if plant.health <= 0 then
			-- Remove dead plant
			if not plant.beingRemoved then
				plant.beingRemoved = true
				game.playSound( act.plantingSound )
				transition.to( plant, { xScale = 1, yScale = 1, alpha = 0, 
						time = 500, onComplete = game.removeObj })
			end
		elseif plant.flowers then
			-- Harvest mature plant
			if not plant.beingHarvested then 
				plant.beingHarvested = true
				game.playSound( act.plantingSound )
				transition.fadeOut( plant, { time = 500, onComplete = game.removeObj } )
				game.addFood( 10 )
				updateResDisplay()
				game.floatMessage( "10 kg food", event.x, event.y )
			end
		else
			-- Water the plant
			if game.water() <= 0 then
				game.messageBox( "Out of water!" )
			else
				waterPlant( plant )
				nWaterings = nWaterings + 1
			end
		end
	end
	return true
end

-- Make a new plant at the given location
local function makePlant( x, y )
	local size = 40
	local plant = act:newGroup( plants )
	plant.x = x
	plant.y = y + size / 2
	local leaves = act:newImage( "potatoPlant.png", { parent = plant, height = size, x = 0, y = 0 } )
	leaves.anchorY = 1   -- grow from bottom up
	leaves:setFillColor( 0, 0.6, 0 )
	plant.leaves = leaves
	plant.health = maxHealth
	plant:addEventListener( "touch", touchPlant )
end

-- Touch handler for the dirt background
local function touchDirt( event )
	if event.phase == "began" then
		makePlant( event.x, event.y )
		game.playSound( act.plantingSound )
	end
	return true
end

-- Show the water hint if necessary
function checkWaterHint()
	if not waterHintShown and nPlantsDied > nWaterings then
		game.showHint( "Tap plants to water them.")
		waterHintShown = true
	end
end

-- Set a plant's color based on its health
local function adjustPlantColor( plant )
	if plant.health <= 0 then
		-- Color dead plants dark brown and remove flowers
		if not plant.dead then
			plant.dead = true
			plant.leaves:setFillColor( 0.5, 0.25, 0 )
			if plant.flowers then
				plant.flowers:removeSelf()
			end
			nPlantsDied = nPlantsDied + 1
			checkWaterHint()
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
		plant.leaves:setFillColor( r, g, b )
		-- TODO: wither flowers  
	end
end

-- Add flowers to the plant if it doesn't already have them
local function addFlowers( plant )
	if not plant.flowers then
		local flowers = act:newGroup( plant )
		local size = 8   -- in unscaled plant units
		act:newImage( "flower.png", { parent = flowers, width = size, x = 0, y = -20 } )
		act:newImage( "flower.png", { parent = flowers, width = size, x = 7, y = -15} )
		act:newImage( "flower.png", { parent = flowers, width = size, x = -5, y = -10 } )
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
	-- Cheat mode adds 150 food immediately
	if game.cheatMode then
		game.addFood( 150 )
	end
	
	game.gotoAct ( "mainAct", { effect = "crossFade", time = 500 } )
	return true
end

-- Create a resource label at the given y location and initally empty text
local function makeResLabel( y )
	local t = display.newText( act.group, "", act.xCenter, y, native.systemFont, 16 )
	t.anchorX = 0
	t:setFillColor( 0 )   -- black text
	return t
end

-- Make a resource status light
local function makeResLight( x, y )
	return act:newImage( "roundLight.png", { x = x, y = y, height = 16 } )
end

-- Init the act
function act:init()
	-- Dirt background
	local dirt = act:newImage( "dirt.jpg", { height = act.height } )
	dirt:addEventListener( "touch", touchDirt )

	-- Group for plants
	plants = act:newGroup()

	-- UI/Display area
	local uiHeight = 60
	local area = act:newImage( "bamboo.png", { x = act.xCenter, y = act.yMin + uiHeight / 2, 
					width = act.width, height = uiHeight } )
	waterText = makeResLabel( act.yMin + uiHeight * 0.3 )
	foodText = makeResLabel( act.yMin + uiHeight * 0.7 )
	waterLight = makeResLight( act.xMax - 20, waterText.y )
	foodLight = makeResLight( waterLight.x, foodText.y )

	-- back button
	local backButton = act:newImage( "backButton.png", { width = 50 } )
	backButton.x = act.xMin + uiHeight / 2
	backButton.y = act.yMin + uiHeight / 2
	backButton:addEventListener( "tap", backButtonPress )
	backButton:addEventListener( "touch", game.eatTouch )

	-- Load sound effects
 	act.plantingSound = act:loadSound( "Planting.wav" )
 	act.wateringSound = act:loadSound( "Pour4.wav" )
end

-- Prepare the act
function act:prepare()
	-- Start a repeating timer for time action
	assert( timerID == nil )
	timerID = timer.performWithDelay( msTimer, timerTick, 0 )
	updateResDisplay()
end

-- Start the act
function act:start()
	game.playAmbientSound( "Light Mood.mp3" )
end

-- Stop the act
function act:stop()
	game.endMessageBox()
	if timerID then
		timer.cancel( timerID )
		timerID = nil
	end
end

-- Destroy the act
function act:destroy()
	game.disposeSound( act.plantingSound )
	game.disposeSound( act.wateringSound )
end


-- Corona needs the scene object returned from the act file
return act.scene
