-----------------------------------------------------------------------------------------
--
-- mainAct.lua
--
-- The main activity (map, etc.) for the Mars App
-----------------------------------------------------------------------------------------

-- Get local reference to the game globals
local game = globalGame

-- Create the act object
local act = game.newAct()


------------------------- Start of Activity --------------------------------

-- Act variables
local walkSpeed = 5  -- user's walking speed factor
local dot            -- user's position dot on map


-- Handle touch event on the map
local function touchMap( event )
	if event.phase == "began" then
		-- Compute distance from dot to touch location
		local d = math.sqrt((event.x - dot.x)^2 + (event.y - dot.y)^2)

		-- Move dot to touch position with time proportional to distance (approx constant speed)
		transition.to( dot, { x = event.x, y = event.y, 
				time = d * walkSpeed, transition = easing.inOutSin } )
	end
	return true
end

-- Handle touch event on the position dot
local function touchDot( event )
	if event.phase == "began" then
		-- Zoom map
		game.mapZoomName = "sampleRoom"
		game.gotoAct( "mapZoom", { effect = "crossFade", time = 250 } )
	end
	return true
end

-- Init the act
function act:init()
	-- Map background with touch listener
	local map = act:newImage( "shipPlan.png", { width = act.width } )
	map:addEventListener( "touch", touchMap )

	-- Blue position dot with touch listener
	dot = act:newImage( "blueDot.png" )
	dot:addEventListener( "touch", touchDot )

	-- Post a new document (TODO: Temporary)
	game.foundDocument( "Security Announcement" )
end

-- Prepare the view before it shows
function act:prepare()
	-- If map is currently zoomed then go to zoomed view
	if game.mapZoomName then 
		game.gotoAct( "mapZoom" )
		return
	end
end

------------------------- End of Activity --------------------------------


-- Corona needs the scene object returned from the act file
return act.scene
