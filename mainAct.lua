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
local spaceBgs         -- space background (array of 2 images)
local marsBg           -- Mars background image
local shipGroup        -- display group centered on ship
local iconGroup        -- display group for map icons, within shipGroup
local dot              -- user's position dot on map
local roomInside       -- room the user is inside or nil if none
local titleBar         -- title bar used when map is zoomed
local yTitleBar        -- y position of title bar when visible
local shipOutside      -- Outside of ship Image
local map              -- the map image

-- Main Ship coordinates
local ship = {
	-- Vertical hallway
	vHall = { left = -10, top = -155, right = 12, bottom = 172 },

	-- Top Horizontal hallway
	thHall = { left = -45, top = -145, right = 45, bottom = -130},

	-- Bottom Horizontal hallway
	bhHall = { left = -133, top = -11, right = 132, bottom = 0 },

	-- Rooms: name, rectangle bounds, zoom factor,
	--        x, y position just outside the door, delta to inside
	rooms = {
		{ 
			name = "Bridge", 
			left = -48, top = -248, right = 49, bottom = -168, zoom = 3,
			x = -1, y = -160, dy = -30, 
		},
		{
			name = "Greenhouse",
			left = -139, top = -190, right = -52, bottom = -83, zoom = 3,
			x = -44, y = -141, dx = -30, sound = "Light Mood.mp3",
		},
		{ 
			name = "Lounge", 
			left = 49, top = -188, right = 137, bottom = -85, zoom = 3,
			x = 46, y = -140, dx = 30, 
		},
		{
			name = "Jordan",
			left = -80, top = -58, right = -21, bottom = -18, zoom = 4,
			x = -51, y = -7, dy = -30, doorCode = "2439",
		},
		{
			name = "Maxwell",
			left = 20, top = -58, right = 77, bottom = -19, zoom = 4,
			x = 46, y = -7, dy = -30,
		},
		{
			name = "Graham",
			left = -141, top = -58, right = -82, bottom = -19, zoom = 4,
			x = -111, y = -7, dy = -30, 
		},
		{
			name = "Moore",
			left = 81, top = -58, right = 138, bottom = -19, zoom = 4,
			x = 110, y = -7, dy = -30, 
		},
		{
			name = "Ellis",
			left = -141, top = 5, right = -81, bottom = 45, zoom = 4,
			x = -113, y = -7, dy = 30, 
		},
		{
			name = "Shaw",
			left = -79, top = 6, right = -22, bottom = 45, zoom = 4,
			x = -50, y = -7, dy = 30, 
		},
		{
			name = "Webb",
			left = 20, top = 5, right = 76, bottom = 45, zoom = 4,
			x = 49, y = -7, dy = 30, 
		},
		{
			name = "Your Quarters",
			left = 81, top = 5, right = 138, bottom = 45, zoom = 4,
			x = 109, y = -7, dy = 30, 
		},
		{
			name = "Rover Bay",
			left = -142, top = 88, right = -22, bottom = 184, zoom = 2,
			x = -15, y = 134, dx = -30, 
		},
		{ 
			name = "Lab", 
			left = 20, top = 86, right = 141, bottom = 183, zoom = 2,
			x = 15, y = 134, dx = 30, 
		},
		{
			name = "Engineering",
			left = -77, top = 187, right = 74, bottom = 257, zoom = 2,
			x = 0, y = 174, dy = 30, doorCode = "1010", sound = "Engine Hum.mp3",
		},
	},
}


-- Return the name of the room the user is in, or nil if none
function game.roomName()
	if roomInside then
		return roomInside.name
	end
end

-- Return true if the user has entered the given room name
function game.roomEntered( roomName )
	for _, room in ipairs( ship.rooms ) do
		if room.name == roomName and room.entered then
			return true
		end
	end
	return false
end

-- Return the x, y destination constrained to the hallways of the ship,
-- taking into account the current position of the dot.
local function constrainToHalls( x, y )
	-- Test to see if dot is currently in bhHall, vHall, or both (intersection)
	local inVHall = game.xyInRect( dot.x, dot.y, ship.vHall )
	local inHHall = game.xyInRect( dot.x, dot.y, ship.bhHall )
	local inTHHall = game.xyInRect( dot.x, dot.y, ship.thHall)

	-- If dot is currently in the intersection of both the vertical and bottom horizontal hall, 
	-- determine which direction is closer to the destination.
	if inHHall and inVHall then
		if math.abs( x - dot.x) > math.abs( y - dot.y ) then
			inVHall = false   -- will prefer horizontal movement
		else
			inHHall = false   -- will prefer vertical movement
		end
	end

	-- If dot is currently in the intersection of both the vertical and top horizontal hall, 
	-- determine which direction is closer to the destination.	
	if inTHHall and inVHall then
		if math.abs( x - dot.x) > math.abs( y - dot.y ) then
			inVHall = false   -- will prefer horizontal movement
		else
			inTHHall = false   -- will prefer vertical movement
		end
	end

	-- If dot is currently in the bhHall, then prefer horizontal movement,
	-- else prefer vertical movement
	if inHHall then
		-- Constrain to the horizontal hall
		x = game.pinValue( x, ship.bhHall.left, ship.bhHall.right )
		y = game.pinValue( y, ship.bhHall.top, ship.bhHall.bottom )
	elseif inTHHall then
		-- Constrain to the top horizontal hall
		x = game.pinValue( x, ship.thHall.left, ship.thHall.right )
		y = game.pinValue( y, ship.thHall.top, ship.thHall.bottom )
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

	-- Count total moves
	game.moves = game.moves + 1
	
	-- Use a little food and water
	game.addWater( -0.5 )
	game.addFood( -0.5 )
	--print( "Water = " .. game.water() .. ", food = " .. game.food() )
end

-- Handle touch on a map gem icon
local function gemTouched( event )
	if event.phase == "began" then
		local icon = event.target
		local gem = icon.gem
		if gem.t == "act" then
			-- Run the linked activity
			game.actGemName = icon.name
			game.actParam = gem.param
			game.gotoAct( gem.act, { effect = "crossFade", time = 500 }  )
		elseif gem.t == "doc" then
			-- Get the document
			game.foundDocument( gem.file )
			gems.grabGemIcon( icon )
		elseif gem.t == "res" then
			-- Add the resource
			local r = game.saveState.resources
			if r[gem.res] then
				r[gem.res] = r[gem.res] + gem.amount
			end
			gems.grabGemIcon( icon )
		end
	end
	return true
end

-- Update the ambient sound depending on the room
local function updateAmbientSound()
	if roomInside and roomInside.sound then
		game.playAmbientSound( roomInside.sound )
	else
		game.playAmbientSound( "Ship Ambience.mp3" )
	end
end

-- Make and return a display group of the active icons for the given room
local function makeIconGroup( room )
	-- Find all active gems that are in the bounds of the room
	local group = act:newGroup( shipGroup )   -- icons are centered on the ship
	for name, gem in pairs( gems.onShip ) do
		if gems.shipGemIsActive( name ) and game.xyInRect( gem.x, gem.y, room ) then
			local icon = gems.newGemIcon( group, name, gem )
			icon.xScale = 1 / room.zoom   -- icon size does not zoom
			icon.yScale = icon.xScale
			icon:addEventListener( "touch", gemTouched )
		end
	end
	return group
end	

-- Change to the zoomed view for the given room
local function zoomToRoom( room )
	-- Fade in icons for gems in the room
	assert( iconGroup == nil )
	iconGroup = makeIconGroup( room )
	iconGroup.alpha = 0   -- will be faded in
	transition.fadeIn( iconGroup, { time = zoomTime, transition = easing.inCubic } )

	-- Animate the dot walking into the room
	local x = room.x + (room.dx or 0)
	local y = room.y + (room.dy or 0)
	walkTo( x, y, zoomTime )
	roomInside = room
	room.entered = true

	-- Zoom the map in, centered at the room's center
	local scale = room.zoom
	local x = act.xCenter - scale * (room.left + room.right) / 2
	local y = act.yCenter - scale * (room.top + room.bottom) / 2
	transition.to( shipGroup, { x = x, y = y, xScale = scale, yScale = scale, 
				time = zoomTime, onComplete = zoomDone } )
	transition.to( dot, { xScale = 1/scale, yScale = 1/scale; time = zoomTime } ) -- keep dot original size

	-- Show the title bar with this room name
	act.title.text = room.name
	titleBar.isVisible = true
	transition.to( titleBar, { y = yTitleBar, time = zoomTime } )

	-- Update the ambient sound when we enter the room
	timer.performWithDelay( zoomTime, updateAmbientSound )
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

		-- Remove any active message box
		game.endMessageBox()
		
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

		-- Update the ambient sound when we exit the room
		timer.performWithDelay( zoomTime, updateAmbientSound )
	end
end

-- Handle touch event on the map
local function touchMap( event )
	if event.phase == "began" then
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
				if game.xyInRect( x, y, room ) then
					-- Is this room locked?
					if room.doorCode then
						-- Use the doorLock act
						game.lockedRoom = room
						game.doorCode = room.doorCode
						game.gotoAct( "doorLock", { effect = "slideLeft", time = 500 } )
					else
						-- Not locked, just go inside
						zoomToRoom( room )
					end
					return true
				end
			end
		end

		-- If the touch is inside a room then walk to just outside the door
		for i = 1, #ship.rooms do
			local room = ship.rooms[i]
			if game.xyInRect( x, y, room ) then
				x, y = room.x, room.y
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

-- Handle new frame events
function act:enterFrame()
	-- Continuous scroll of the endless space background
	for i = 1, 2 do
		local bg = spaceBgs[i]
		bg.y = bg.y + 0.5
		if bg.y > act.yMax then
			bg.y = act.yMin - act.height
		end
	end
end

-- Make map background with touch listener and remove ship outside image
local function  removeShipOutside ()
	transition.to( shipOutside, { alpha = 0, onComplete = removeImage } )
	function removeImage ()
		shipOutside:removeSelf( )
		shipOutside = nil
	end
	map.isVisible = true
end

-- Init the act
function act:init()
	-- Space background images (2 for continuous scrolling)
	spaceBgs = {
		act:newImage( "space.jpg", { y = act.yMin, anchorY = 0, height = act.height }  ),
	 	act:newImage( "space.jpg", { y = act.yMin - act.height, anchorY = 0, height = act.height }  ),
	 }

	-- Mars background image
	marsBg = act:newImage( "mars.jpg", { height = act.height } )
	
	-- Display group for ship elements (centered on ship)
	shipGroup = act:newGroup()
	shipGroup.x = act.xCenter
	shipGroup.y = act.yCenter

	-- Start outside of the ship and zooms into it
	shipOutside = act:newImage( "shipOutside.png", {width = act.width - 10 } )
	local perams = {
		delay = 1000, 
		time = 1500, 
		xScale = 1.9, 
		yScale = 1.9, 
		y = 220,
		transition = easing.inOutSine,
		onComplete = removeShipOutside
	}
	transition.to( shipOutside, perams )

	-- Map background with touch listener
	map = act:newImage( "shipPlan2.png", { parent = shipGroup, width = act.width, x = 0, y = 0 } )
	map:addEventListener( "touch", touchMap )
	map.isVisible = false

	--[[ Display rectangles in the walkable parts of the hallways (testing only)
	local r = display.newRect( shipGroup, ship.vHall.left, ship.vHall.top, 
					ship.vHall.right - ship.vHall.left, ship.vHall.bottom - ship.vHall.top )
	r.anchorX = 0
	r.anchorY = 0
	r:setFillColor( 0.5 )
	r.alpha = 0.5
	r = display.newRect( shipGroup, ship.bhHall.left, ship.bhHall.top, 
					ship.bhHall.right - ship.bhHall.left, ship.bhHall.bottom - ship.bhHall.top )
	r.anchorX = 0
	r.anchorY = 0
	r:setFillColor( 0.3 )
	r.alpha = 0.5
	r = display.newRect( shipGroup, ship.thHall.left, ship.thHall.top, 
					ship.thHall.right - ship.thHall.left, ship.thHall.bottom - ship.thHall.top )
	r.anchorX = 0
	r.anchorY = 0
	r:setFillColor( 0.3 )
	r.alpha = 0.5
	--]]

	--[[ Display room bounds and door locations (testing only)
	for _, room in pairs(ship.rooms) do 
		local r = display.newRect( shipGroup, room.left, room.top, 
						room.right - room.left, room.bottom - room.top )
		r.anchorX = 0
		r.anchorY = 0
		r:setFillColor( 0.5, 0.5, 0 )
		r.alpha = 0.5
		local c = display.newCircle( shipGroup, room.x, room.y, 5 )
		c:setFillColor( 1, 0, 0 )
		c.alpha = 0.5
	end
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
end

-- Select the proper background image
local function selectBackground()
	local onMars = game.saveState.onMars
	spaceBgs[1].isVisible = not onMars
	spaceBgs[2].isVisible = not onMars
	marsBg.isVisible = onMars
end

-- Land the ship and update ship state as necessary
function game.landShip()
	game.saveState.onMars = true
	gems.enableShipGem( "rover" )
	gems.enableShipGem( "plants" )
	selectBackground()
end

-- Prepare the view before it shows
function act:prepare()
	selectBackground()  -- Select correct background image

	-- Are we zoomed inside a room?
	if roomInside then
		-- Reload the room's icons in case the enabled state of any changed
		if iconGroup then
			iconGroup:removeSelf()
			iconGroup = makeIconGroup( roomInside )
		end
	else
		-- If we just unlocked a door (coming back from doorLock act) then go in
		if game.lockedRoom and game.doorUnlocked then
			zoomToRoom( game.lockedRoom )
		end
		-- Reset for next door
		game.lockedRoom = nil
		game.doorCode = nil
		game.doorUnlocked = nil
	end
end

-- Start the act
function act:start()
	game.paused = false
	updateAmbientSound()
end

-- Stop the act
function act:stop()
	game.endMessageBox()
end


------------------------- End of Activity --------------------------------


-- Corona needs the scene object returned from the act file
return act.scene
