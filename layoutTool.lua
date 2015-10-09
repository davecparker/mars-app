-----------------------------------------------------------------------------------------
--
-- layoutTool.lua
--
-- This is a developer tool for the Mars app that allows you to graphically author
-- the contents of zoomed map views (place resources, activity icons, etc.)
-----------------------------------------------------------------------------------------

-- Get local reference to the game globals
local game = globalGame

-- Load Corona modules needed
local widget = require( "widget" )

-- Create the act object
local act = game.newAct()


------------------------- Start of Activity --------------------------------

-- Constants
local SELECT = "^"    -- label for the select tool
local DELETE = "X"   -- label for the delete tool

-- File local variables
local toolbar     -- toolbar to hold the controls on the bottom of the screen
local segControl  -- segmented control in the toolbar
local doneBtn     -- Load/Done button in the top bar
local textEdit    -- native text edit control in the top bar
local map         -- table for current map being edited or nil if none
local mapName     -- name of map being edited or nil if none
local mapImage    -- image object for map background or nil if none loaded
local mapData     -- data table for the current map or nil if none loaded
local icons       -- display group for map icons
local iconSel     -- currently selectec map icon or nil if none


-- Select the icon, which can be nil for no selection
local function selectIcon( icon )
	-- Deselect previous icon, if any
	if iconSel then
		iconSel:setStrokeColor( 0 )  -- black
		textEdit.text = ""
	end

	-- Select and highlight new icon
	iconSel = icon
	if icon then
		icon:setStrokeColor( 0.25, 0.5, 1 )  -- blue
		textEdit.text = icon.name  -- put icon name in the text edit control
	end
end

-- Handle touches on a map icon
local function touchedIcon( icon, event )
	-- Icons are positioned with respect to the act center
	local x = event.x - act.xCenter
	local y = event.y - act.yCenter

	if event.phase == "began" then
		-- If delete tool is selected then delete the icon
		if segControl.segmentLabel == DELETE then
			selectIcon( nil )
			icon:removeSelf()
			segControl:setActiveSegment( 1 )  -- select
		else
			-- Start dragging an icon to move it
			selectIcon( icon )
			display.getCurrentStage():setFocus( icon )
		end
	elseif event.phase == "moved" then
		-- Drag icon to new location
		icon.x = x
		icon.y = y
	else
		-- End drag (leave it selected)
		display.getCurrentStage():setFocus( nil )
	end
	return true
end

	-- Handle touches on the map background image
local function touchedMap( event )
	-- Icons are positioned with respect to the act center
	local x = event.x - act.xCenter
	local y = event.y - act.yCenter

	if event.phase == "began" then
		local tool = segControl.segmentLabel
		if tool == SELECT then
			-- Clicked on background, so deselect any current icon
			selectIcon( nil )
		elseif tool ~= DELETE then
			-- A placement tool is selected so start placing a new map icon
			local icon = act:newMapIcon( icons, { type = tool, name = "", x = x, y = y } )
			if icon then
				selectIcon( icon )
				icon.touch = touchedIcon
				icon:addEventListener( "touch", icon )
				display.getCurrentStage():setFocus( icon )
				segControl:setActiveSegment( 1 )  -- select
			end
		end
	end
	return true
end

-- Attempt to load the map with the given name (name is without extension).
-- Return true if successfully loaded.
local function loadMap( name )
	-- Try to load the map image as png, else jpg, else fail if not found
	assert( mapImage == nil )
	local imageOptions = 
	{
			folder = "media/mapZoom", 
			allowFail = true, 
			width = act.width,
			x = act.xCenter,
			y =  act.yCenter + act.dyTitleBar / 2, 
	}
	mapImage = act:newImage( name .. ".png", imageOptions)
	if not mapImage then
		mapImage = act:newImage( name .. ".jpg", imageOptions)
	end
	if not mapImage then
		return false
	end
	mapImage:toBack()
	mapName = name
	mapImage:addEventListener( "touch", touchedMap )

	-- Create display group for map icons centered on the view
	icons = act:newGroup()
	icons.x = act.xCenter
	icons.y = act.yCenter

	-- Try to load data file for this map
	-- TODO
	return true
end

-- Handle press on the Load/Done button
local function doneButton()
	if mapName then
		-- Done: Close and save the loaded map
		if mapImage then
			mapImage:removeSelf()
			mapImage = nil
		end
		if icons then
			icons:removeSelf()
			icons = nil
		end
		mapName = nil
		mapData = nil

		-- The text edit can now load a new map
		textEdit.text = "" 
		textEdit.placeholder = "Map filename"
		doneBtn:setLabel( "Load" )  
	else
		-- Load: load the map named in the edit control
		if loadMap( textEdit.text ) then
			doneBtn:setLabel( "Done" )  -- Change button to Done to close and finish
			textEdit.text = ""
			textEdit.placeholder = nil
		end
	end
end

-- Handle changes to the text edit
function textEditListener( event )
	if event.phase == "editing" then
		-- If an icon is selected then modify its name 
		if iconSel then
			iconSel.name = event.text
		end
	end
end

-- Init the act
function act:init()
	-- Create the tool bar on the bottom of the screen.
	-- This will cover most of the tab bar, but still allow access to the menu.
	toolbar = display.newGroup()   -- in the global group so on top of tab bar
	toolbar.isVisible = false   -- shown on act start
	local bg = display.newRect( toolbar, act.xMin, act.yMax + 2, 
					act.width * 0.8, act.dyTitleBar )
	bg.anchorX = 0
	bg.anchorY = 0
	segControl = widget.newSegmentedControl
	{
	    left = act.xMin + 5,
	    top = act.yMax + 7,
	    segmentWidth = 45,
	    segments = { SELECT, "item", "doc", "act", DELETE  },
	    defaultSegment = 1,
	}
	toolbar:insert( segControl )

	-- Create the topBar for text edit and a Done button in the title bar area
	local topBar = act:newGroup()
	local bg = display.newRect( topBar, act.xCenter, act.yMin + act.dyTitleBar / 2, 
					act.width, act.dyTitleBar )
	bg:setFillColor( 0.25 )  -- dark gray
	doneBtn = widget.newButton
	{
	    x = act.xMax - 30,
	    y = bg.y,
	    label = "Load",        -- button initially used for loading map file
	    onRelease = doneButton,
	}
	topBar:insert( doneBtn )
end

-- Start the act
function act:start()
	toolbar.isVisible = true   -- toolbar is in the global group so must show/hide
	toolbar:toFront()

	-- Create the text edit and use the load placeholder 
	textEdit = native.newTextField( 130, act.yMin + act.dyTitleBar / 2, 
					250, act.dyTitleBar * 0.75 )
	textEdit.placeholder = "Map filename"
	textEdit:addEventListener( "userInput", textEditListener )
end

-- Stop the act
function act:stop()
	toolbar.isVisible = false  -- toolbar is in the global group so must show/hide
	textEdit:removeSelf()
	textEdit = nil
end

------------------------- End of Activity --------------------------------


-- Corona needs the scene object returned from the act file
return act.scene
