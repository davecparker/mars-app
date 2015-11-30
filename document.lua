-----------------------------------------------------------------------------------------
--
-- document.lua
--
-- The view for an open document (within the Documents view) for the Mars App.
-----------------------------------------------------------------------------------------

-- Get local reference to the game globals
local game = globalGame

-- Corona modules needed
local widget = require( "widget" )

-- Create the act object
local act = game.newAct()


------------------------- Start of Activity --------------------------------

-- Act variables
local dxyMargin = 10    -- margin around text area
local scrollView
local textBox


-- Handle tap on the back button
local function backTapped()
	-- "Close" the document being viewed, and go back to the documents list view
	game.openDoc = nil
	game.gotoScene( "documents", { effect = "slideRight", time = 300 } )
	return true
end

-- Init the act
function act:init()
	-- Background and title bar for the view with back button
	act:whiteBackground()
	act:makeTitleBar( "", backTapped )

	-- Make a scroll view that covers the rest of the act area
	scrollView = widget.newScrollView{
		left = act.xMin,
		top = act.yMin + act.dyTitleBar,
		width = act.width,
		height = act.height - act.dyTitleBar,
		horizontalScrollDisabled = true,
		backgroundColor = { 1, 1, 1 },  -- white
		hideScrollBar = false,
	}
	act.group:insert( scrollView )

	-- Text box inside the scroll view
	textBox = display.newText{
		text = "",   -- set in act:prepare()
		x = dxyMargin,
		y = dxyMargin,
		width = act.width - dxyMargin * 2,
		height = 0,   -- autosize
		font = native.systemFont,
		fontSize = 14,
		align = "left",
	}
	textBox:setFillColor( 0 )  -- black text
	textBox.anchorX = 0
	textBox.anchorY = 0	
	scrollView:insert( textBox )
end

-- Prepare the act before the show transition
function act:prepare()
	-- If we got here with no document to open then go back to Documents view
	if not game.openDoc then
		game.gotoScene( "documents" )
		return
	end

	-- Set title bar text to name of document
	act.title.text = game.openDoc

	-- Open the document and load the text into the text box
	textBox.text = ""   -- show empty contents if we fail
	local path = system.pathForFile( "docs/" .. game.openDoc .. ".txt", system.ResourceDirectory )
	if path then
		local file = io.open( path, "r" )
		if file then
			local str = file:read( "*a" )	-- read entire file as a string
			if str then
				textBox.text = str
			end
			io.close( file )
		else
			print( "File not Found: [" .. path .. "]" )
		end	
	end

	-- Set scroll height or disable scrolling if it all fits
	local scrollHeight = textBox.height + dxyMargin * 2
	scrollView:setScrollHeight( scrollHeight )
	scrollView:setIsLocked( scrollHeight <= scrollView.height )
end

------------------------- End of Activity --------------------------------


-- Corona needs the scene object returned from the act file
return act.scene
