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
local shipGroup      -- display group centered on ship
local walkSpeed = 0.1  -- user's walking speed factor
local dot            -- user's position dot on map

-- Main Ship coordinates
local ship = {
	-- Horizontal hallway
	vHall = { left = -10, top = -115, right = 12, bottom = 152 },

	-- Vertical hallway
	hHall = { left = -112, top = -11, right = 12, bottom = 14 },

	-- Rooms (name, rectangle bounds, position just outside the door, delta to inside)
	rooms = {
		{ 
			name = "Lab", 
			left = 23, top = 5, right = 136, bottom = 78, 
			x = 12, y = 40, dx = 30 
		},
		{
			name = "Captain's Cabin",
			left = 23, top = -125, right = 136, bottom = -85, 
			x = 12, y = -92, dx = 30 
		},
	},
}


-- Return the x, y destination constrained to the hallways of the ship,
-- taking into account the current position of the dot.
local function constrainToHalls( x, y )
	-- Test to see if dot is currently in hHall, vHall, or both (intersection)
	local inVHall = game.xyInRect( dot.x, dot.y, ship.vHall )
	local inHHall = game.xyInRect( dot.x, dot.y, ship.hHall )

	-- If dot is currently in the intersection of both halls, determine
	-- which direction is closer to the destination.
	if inHHall and inVHall then
		if math.abs( x - dot.x) > math.abs( y - dot.y ) then
			inVHall = false   -- will prefer horizontal movement
		else
			inHHall = false   -- will prefer vertical movement
		end
	end

	-- If dot is currently in the hHall, then prefer horizontal movement,
	-- else prefer vertical movement
	if inHHall then
		-- Constrain to the horizontal hall
		x = game.pinValue( x, ship.hHall.left, ship.hHall.right )
		y = game.pinValue( y, ship.hHall.top, ship.hHall.bottom )
	else
		-- Constrain to the vertical hall
		x = game.pinValue( x, ship.vHall.left, ship.vHall.right )
		y = game.pinValue( y, ship.vHall.top, ship.vHall.bottom )
	end

	return x, y
end

-- Handle touch event on the map
local function touchMap( event )
	if event.phase == "began" then
		-- Get tap position in shipGroup coords
		local x, y = shipGroup:contentToLocal( event.x, event.y )

		-- If dot is near a door and touch is inside that room then go inside
		for i = 1, #ship.rooms do
			local room = ship.rooms[i]
			if game.xyHitTest( dot.x, dot.y, room.x, room.y, 10 ) then
				-- print( "Near door: " .. room.name )
				if game.xyInRect( x, y, room ) then
					-- Go into zoomed view for the room
					game.mapZoomName = room.name
					game.gotoAct( "mapZoom", { effect = "crossFade", time = 250 } )
				end
			end
		end

		-- Constrain position to walkable portion of the ship
		x, y = constrainToHalls( x, y )

		-- Compute distance from current location to destination
		local d = math.sqrt((x - dot.x)^2 + (y - dot.y)^2)

		-- Move dot to destination with time proportional to distance (approx constant speed)
		transition.cancel( dot )  -- stop previous movement if any
		transition.to( dot, { x = x, y = y, time = d / walkSpeed, transition = easing.inOutSin } )

		-- Use a little o2, h2o, and food proportional to the walking distance
		game.addOxygen( -0.02 * d )
		game.addWater( -0.001 * d )
		game.addFood( -0.0002 * d )
	end
	return true
end

-- Init the act
function act:init()
	-- Map background with touch listener
	local map = act:newImage( "shipPlan.png", { width = act.width } )
	map:addEventListener( "touch", touchMap )

	-- Display group for ship elements (centered on ship)
	shipGroup = act:newGroup()
	shipGroup.x = act.xCenter
	shipGroup.y = act.yCenter

	--[[ Display rectangles in the walkable parts of the hallways (testing only)
	local r = display.newRect( shipGroup, ship.vHall.left, ship.vHall.top, 
					ship.vHall.right - ship.vHall.left, ship.vHall.bottom - ship.vHall.top )
	r.anchorX = 0
	r.anchorY = 0
	r:setFillColor( 0.5 )
	r = display.newRect( shipGroup, ship.hHall.left, ship.hHall.top, 
					ship.hHall.right - ship.hHall.left, ship.hHall.bottom - ship.hHall.top )
	r.anchorX = 0
	r.anchorY = 0
	r:setFillColor( 0.3 )
	--]]

	-- Blue position dot, starting just outside the lab
	dot = act:newImage( "blueDot.png", { parent = shipGroup } )
	local lab = ship.rooms[1]
	dot.x = lab.x
	dot.y = lab.y

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
