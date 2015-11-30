-----------------------------------------------------------------------------------------
--
-- debugMenu.lua
--
-- The debug menu view for the Mars App.
-----------------------------------------------------------------------------------------

-- Get local reference to the game globals
local game = globalGame

-- Corona modules needed
local widget = require( "widget" )

-- Create the act object
local act = game.newAct()


------------------------- Debug Data --------------------------------

-- List of activities that can be run directly from the debug menu
local debugActs = {
	"mainAct",
	"thrustNav",
	"doorLock",
	"circuit",
	"wireCut",
	"greenhouse",
	"drillScan",
	"drill",
	"rover",
	"shipLanding",
	"blankAct",
	"layoutTool",
	"sampleAct",
}

------------------------- Start of Activity --------------------------------

-- Act data
local tableView     -- the tableView widget


-- Draw a row in the tableView
local function onRowRender( event )
    -- Get row info
    local row = event.row
    local dxRow = row.contentWidth
    local dyRow = row.contentHeight

    -- Display the text
    local rowTitle = display.newText( row, debugActs[row.index], 0, 0, native.systemFontBold, 18 )
    rowTitle:setFillColor( 0 )     -- black text
    rowTitle.anchorX = 0           -- left aligned
    rowTitle.x = 15
    rowTitle.y = dyRow * 0.5       -- vertically centered
end

-- Handle touch on a row
function onRowTouch( event )
	if event.phase == "tap" or event.phase == "release" then
		-- Run the selected activity module on the main tab
		game.gotoAct( debugActs[event.target.index] )  
	end
end

-- Handle press of the back button
local function onBackButton()
	game.gotoScene( "menu" )
end

-- Init the act
function act:init()
	-- Background and title bar for the view
	act:grayBackground()
	act:makeTitleBar( "Debug Menu", onBackButton )

	-- Cheat mode switch and label
	local ySwitch = act.yMin + act.dyTitleBar * 1.5
	local label = display.newText( act.group, "Cheat", act.xCenter + 60 , ySwitch, 
						native.systemFont, 18 )
	label:setFillColor( 0 )
	local switch = widget.newSwitch{
		x = act.xMax - 35,
		y = ySwitch,
		onRelease = 
			function ( event )
				game.cheatMode = event.target.isOn
			end
	}
	act.group:insert( switch )

	-- All Gems mode switch and label
	local ySwitch = act.yMin + act.dyTitleBar * 1.5
	local label = display.newText( act.group, "All Gems", act.xMin + 50 , ySwitch, 
						native.systemFont, 18 )
	label:setFillColor( 0 )
	local switch = widget.newSwitch{
		x = act.xCenter - 40,
		y = ySwitch,
		onRelease = 
			function ( event )
				game.allGems = event.target.isOn
			end
	}
	act.group:insert( switch )

	-- Create the tableView widget to list the debug activities
	local tableView = widget.newTableView
	{
	    left = act.xMin,
	    top = act.yMin + act.dyTitleBar * 2,
	    height = act.height - act.dyTitleBar * 2,
	    width = act.width,
	    onRowRender = onRowRender,
	    onRowTouch = onRowTouch,
	}
	act.group:insert( tableView )

	-- Insert the rows
	for i = 1, #debugActs do
	    tableView:insertRow{}
	end
end


------------------------- End of Activity --------------------------------


-- Corona needs the scene object returned from the act file
return act.scene
