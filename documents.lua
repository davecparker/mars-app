-----------------------------------------------------------------------------------------
--
-- documents.lua
--
-- The documents view for the Mars App.
-----------------------------------------------------------------------------------------

-- Get local reference to the game globals
local game = globalGame

-- Corona modules needed
local widget = require( "widget" )

-- Create the act object
local act = game.newAct()


------------------------- Start of Activity --------------------------------


-- Draw a row in the tableView
local function onRowRender( event )
    -- Get row info
    local row = event.row
    local dxRow = row.contentWidth
    local dyRow = row.contentHeight

    -- Display the text
	local docs = game.saveState.docs
    local rowTitle = display.newText( row, docs[row.index], 0, 0, native.systemFont, 18 )
    rowTitle:setFillColor( 0 )     -- black text
    rowTitle.anchorX = 0           -- left aligned
    rowTitle.x = 15
    rowTitle.y = dyRow * 0.5       -- vertically centered
end

-- Handle touch on a row
function onRowTouch( event )
	if event.phase == "tap" or event.phase == "release" then
		-- TODO: Open selected doc
	end
end

-- Init the act
function act:init()
	-- Title bar for the view
	act:makeTitleBar( "Documents" )

	-- A tableView widget to list the documents
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
	local docs = game.saveState.docs
	for i = 1, #docs do
	    tableView:insertRow{}
	end
end


------------------------- End of Activity --------------------------------


-- Corona needs the scene object returned from the act file
return act.scene
