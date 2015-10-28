-----------------------------------------------------------------------------------------
--
-- mainAct.lua
--
-- The main activity (map, etc.) for the Mars App
-----------------------------------------------------------------------------------------

-- Get local reference to the game globals
local game = globalGame

-- Load ship gem data
local gems = require( "gems" )

-- Create the act object
local act = game.newAct()


------------------------- Start of Activity --------------------------------

-- Constants
local zoomTime = 500   -- time for zoom in/out transition (ms)
local walkSpeed = 0.1  -- user's walking speed factor

-- Act variables
local shipGroup        -- display group centered on ship
local iconGroup        -- display group for map icons, within shipGroup
local dot              -- user's position dot on map
local roomInside       -- room the user is inside or nil if none
local titleBar         -- title bar used when map is zoomed
local yTitleBar        -- y position of title bar when visible
local clickWav		   -- click sound

-- Main Ship coordinates
local ship = {
	-- Horizontal hallway
	vHall = { left = -10, top = -115, right = 12, bottom = 152 },

	-- Vertical hallway
	hHall = { left = -112, top = -11, right = 12, bottom = 14 },

	-- Rooms (name, rectangle bounds, position just outside the door, delta to inside)
	rooms = {
		{ 
			name = "Bridge", 
			left = -45, top = -236, right = 45, bottom = -142, 
			x = 1, y = -116, dy = -30, 
		},
		{ 
			name = "Lab", 
			left = 23, top = 5, right = 136, bottom = 78, 
			x = 12, y = 40, dx = 30, 
		},
		{
			name = "Captain's Cabin",
			left = 23, top = -125, right = 136, bottom = -85, 
			x = 12, y = -92, dx = 30, 
		},
		{
			name = "First Officer's Cabin",
			left = -136, top = -125, right = -20, bottom = -85, 
			x = -8, y = -92, dx = -30, 
		},
		{
			name = "Doctor's Cabin",
			left = -55, top = -76, right = -21, bottom = -24, 
			x = -26, y = -5, dy = -30, 
		},
		{
			name = "Rover Bay",
			left = -145, top = 86, right = -20, bottom = 158, 
			x = -7, y = 94, dx = -30, 
		},
		{
			name = "Greenhouse",
			left = 25, top = 85, right = 140, bottom = 235, 
			x = 10, y = 94, dx = 30, 
		},
		{
			name = "Engineering",
			left = -94, top = 166, right = 19, bottom = 236, 
			x = 0, y = 153, dy = 30,
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

-- Walk the dot to the given position on the map.
-- If the time is not given, use a default walking speed (time proportional to distance)
local function walkTo( x, y, time )
	-- Compute time from distance from current location to destination, if needed
	if not time then
		local d = math.sqrt( (x - dot.x)^2 + (y - dot.y)^2 )
		time = d / walkSpeed
	end

	-- Move dot to destination
	transition.cancel( dot )  -- stop previous movement if any
	transition.to( dot, { x = x, y = y, time = time, transition = easing.inOutSin } )

	-- Use a little o2, h2o, and food proportional to the walking time
	game.addOxygen( -0.02 * time )
	game.addWater( -0.001 * time )
	game.addFood( -0.0002 * time )
end

-- Use a gem icon
local function useGemIcon( icon )
	gems.useGem( icon.name )   -- so it won't be displayed again
	icon:removeSelf()          -- remove gem from screen
end

-- Handle tap on a map gem icon
local function gemTapped( event )
	local icon = event.target
	local gem = icon.gem
	if gem.t == "act" then
		-- Run the linked activity
		game.actGemName = icon.name
		game.actParam = gem.param
		game.gotoAct( gem.act )
	elseif gem.t == "doc" then
		-- Get the document
		game.foundDocument( gem.file )
		useGemIcon( icon )
	elseif gem.t == "res" then
		-- Add the resource
		local r = game.saveState.resources
		if r[gem.res] then
			r[gem.res] = r[gem.res] + gem.amount
		end
		useGemIcon( icon )
	end
end

-- Change to the zoomed view for the given room
local function zoomToRoom( room )
	-- Fade in icons for gems in the room
	iconGroup = act:newGroup( shipGroup )   -- icons are centered on the ship
	iconGroup.alpha = 0   -- will be faded in

	-- Find all unused gems that are in the bounds of the zoomed room
	for name, gem in pairs( gems.onShip ) do
		if not gems.gemIsUsed( name ) and game.xyInRect( gem.x, gem.y, room ) then
			local icon = gems.newGemIcon( iconGroup, name, gem )
			icon:addEventListener( "tap", gemTapped )
		end
	end
	transition.fadeIn( iconGroup, { time = zoomTime, transition = easing.inCubic } )

	-- Animate the dot walking into the room
	local x = room.x + (room.dx or 0)
	local y = room.y + (room.dy or 0)
	walkTo( x, y, zoomTime )
	roomInside = room

	-- Zoom the map in, centered at the room's center
	local scale = 2
	local x = act.xCenter - scale * (room.left + room.right) / 2
	local y = act.yCenter - scale * (room.top + room.bottom) / 2
	transition.to( shipGroup, { x = x, y = y, xScale = scale, yScale = scale, 
				time = zoomTime, onComplete = zoomDone } )
	transition.to( dot, { xScale = 1/scale, yScale = 1/scale; time = zoomTime } ) -- keep dot original size

	-- Show the title bar with this room name
	act.title.text = room.name
	titleBar.isVisible = true
	transition.to( titleBar, { y = yTitleBar, time = zoomTime })
end

-- Called when a zoom out of a room is complete
local function zoomOutDone()
	-- Remove gem icons (they are done fading out)
	if iconGroup then
		iconGroup:removeSelf()
		iconGroup = nil
	end
end

-- Hide the title bar
local function hideTitleBar()
	titleBar.isVisible = false
end

-- Exit the currently zoomed room
local function exitRoom()
	if roomInside then
		-- Walk to just outside the door of the room we are in
		walkTo( roomInside.x, roomInside.y, zoomTime ) 
		roomInside = nil

		-- Fade out then delete any gem icons
		if iconGroup then
			transition.fadeOut( iconGroup, { time = zoomTime, transition = easing.outCubic, 
					onComplete = zoomOutDone } )
		end

		-- Zoom the map out
		transition.to( shipGroup, { x = act.xCenter, y = act.yCenter, xScale = 1, yScale = 1; time = zoomTime })
		transition.to( dot, { xScale = 1, yScale = 1; time = zoomTime } )

		-- Hide the title bar
		transition.to( titleBar, { y = yTitleBar - act.dyTitleBar, time = zoomTime, onComplete = hideTitleBar })
	end
end

-- Handle touch event on the map
local function touchMap( event )
	if event.phase == "began" then
		-- Temp click sound (TODO)
		audio.play( clickWav )

		-- Get tap position in shipGroup coords
		local x, y = shipGroup:contentToLocal( event.x, event.y )

		-- Are we currently zoomed inside a room?
		if roomInside then
			-- If the click is outside the room, go outside, else ignore it
			if not game.xyInRect( x, y, roomInside ) then
				exitRoom()
			end
			return true
		end

		-- If dot is near a door and the touch is inside that room then go inside
		for i = 1, #ship.rooms do
			local room = ship.rooms[i]
			if game.xyHitTest( dot.x, dot.y, room.x, room.y, 10 ) then
				-- print( "Near door: " .. room.name )
				if game.xyInRect( x, y, room ) then
					zoomToRoom( room )
					return true
				end
			end
		end

		-- Constrain position to walkable portion of the ship and walk there
		x, y = constrainToHalls( x, y )
		walkTo( x, y )
	end
	return true
end

-- Handle tap on the back button in the title bar (when zoomed)
local function backTapped()
	exitRoom()
	return true
end

-- Init the act
function act:init()
	-- Load temp click sound (TODO)
	clickWav = act:loadSound( "Click6.wav" )

	-- Display group for ship elements (centered on ship)
	shipGroup = act:newGroup()
	shipGroup.x = act.xCenter
	shipGroup.y = act.yCenter

	-- Map background with touch listener
	local map = act:newImage( "shipPlan.png", { parent = shipGroup, width = act.width, x = 0, y = 0 } )
	map:addEventListener( "touch", touchMap )

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
	dot.x = 10   -- outside the Lab
	dot.y = 40

	-- Title bar to use when map is zoomed, invisible and off screen when unzoomed
	titleBar = act:makeTitleBar( "", backTapped )
	yTitleBar = titleBar.y  -- remember normal (visible) position
	titleBar.y = titleBar.y - act.dyTitleBar   -- move off screen upwards
	titleBar.isVisible = false

	-- Post a new document (TODO: Temporary)
	game.foundDocument( "Security Announcement" )
end

-- Prepare the view before it shows
function act:prepare()
	-- TODO: Go to current activity if any
end

------------------------- End of Activity --------------------------------


-- Corona needs the scene object returned from the act file
return act.scene
