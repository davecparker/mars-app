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
	"sampleAct",
	"blankAct",
	"circuit",
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
	--if event.phase == "tap" or event.phase == "release" then
		-- Run the selected activity module and remember it for next startup
		local actName = debugActs[event.target.index]
		game.saveState.startAct = actName
		game.selectGameTab( 1 )  -- Misc activities run off of the Main tab
		game.gotoAct( actName )  
	--end
end

-- Init the act
function act:init()
	-- Title bar for the view
	act:makeTitleBar( "Debug Menu" )

	-- Create the tableView widget to list the debug activities
	local tableView = widget.newTableView
	{
	    left = act.xMin,
	    top = act.yMin + act.dyTitleBar,
	    height = act.height - act.dyTitleBar,
	    width = act.width - 12,   -- try to visually balance the widget's left margin
	    onRowRender = onRowRender,
	    onRowTouch = onRowTouch,
	}
	act.group:insert(tableView)

	-- Insert the rows
	for i = 1, #debugActs do
	    tableView:insertRow{}
	end
end


------------------------- End of Activity --------------------------------


-- Corona needs the scene object returned from the act file
return act.scene
