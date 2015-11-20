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
	"layoutTool",
	"sampleAct",
	"blankAct",
	"circuit",
	"doorLock",
	"wireCut",
	"thrustNav",
	"drillScan",
	"drill",
	"rover",
<<<<<<< Updated upstream
	"greenhouse",
=======
	"shipLanding",
>>>>>>> Stashed changes
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
		-- Run the selected activity module and remember it for next startup
		local actName = debugActs[event.target.index]
		game.selectGameTab( 1 )  -- Debug acts run off the main tab
		game.gotoAct( actName )  
	end
end

-- Handle event for the act cheat switch
local function cheatSwitch( event )
	game.cheatMode = event.target.isOn
	print( "Cheat mode = " .. tostring(game.cheatMode) )
end

-- Handle press of the back button
local function onBackButton()
	game.gotoAct( "menu" )
end

-- Init the act
function act:init()
	-- Background and title bar for the view
	act:grayBackground()
	act:makeTitleBar( "Debug Menu", onBackButton )

	-- Cheat mode switch and label
	local ySwitch = act.yMin + act.dyTitleBar * 1.5
	local label = display.newText( act.group, "Cheat Mode", act.xCenter, ySwitch, 
						native.systemFont, 18 )
	label:setFillColor( 0 )
	local switch = widget.newSwitch{
		x = act.xMax - 50,
		y = ySwitch,
		onRelease = cheatSwitch,
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
