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

-- Constants
local DOCS_DIR = "docs/"  -- subdirectory where docs are stored in project folder

-- Act variables
local dxyMargin = 10    -- margin around text/image area
local scrollView        -- scrolling view area for document content
local loadedDoc         -- document currently loaded into the view or nil if none


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
end

-- Prepare for a plain text document
local function prepareTextDoc()
	-- Make a scroll view that covers the usable act area
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
	local textBox = display.newText{
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

	-- Open the document and load the text into the text box
	textBox.text = ""   -- show empty contents if we fail
	local path = system.pathForFile( DOCS_DIR .. game.openDoc.baseName .. ".txt", 
					system.ResourceDirectory )
	if path then
		local file = io.open( path, "r" )
		if file then
			local str = file:read( "*a" )	-- read entire file as a string
			if str then
				textBox.text = str
				loadedDoc = game.openDoc
			end
			io.close( file )
		else
			print( "*** File not Found: [" .. path .. "]" )
		end	
	end

	-- Set scroll height, or disable scrolling if it all fits
	local scrollHeight = textBox.height + dxyMargin * 2
	scrollView:setScrollHeight( scrollHeight )
	scrollView:setIsLocked( scrollHeight <= scrollView.height )
end

-- Prepare an image document
local function prepareImageDoc( ext )
	-- Make a scroll view that covers the usable act area
	scrollView = widget.newScrollView{
		left = act.xMin,
		top = act.yMin + act.dyTitleBar,
		width = act.width,
		height = act.height - act.dyTitleBar,
		horizontalScrollDisabled = false,    -- images can scroll in 2D
		backgroundColor = { 1, 1, 1 },  -- white
		hideScrollBar = false,
	}
	act.group:insert( scrollView )

	-- Load the image, initially centered in the scroll view
	local path = DOCS_DIR .. game.openDoc.baseName .. "." .. ext
	local img = display.newImage( path, act.xCenter, 
					act.yMin + act.dyTitleBar + scrollView.height / 2 )
	if not img then
		print( "*** File not Found: [" .. path .. "]" )
		return
	end

	-- Position at top/left if image is big enough to scroll
	if img.width > scrollView.width then
		img.anchorX = 0
		img.x = dxyMargin
	end
	if img.height > scrollView.height then
		img.anchorY = 0
		img.y = dxyMargin
	end
	scrollView:insert( img )
	loadedDoc = game.openDoc

	-- Set scroll size, or disable scrolling if it all fits
	scrollView:setScrollWidth( img.width )
	scrollView:setScrollHeight( img.height )
	scrollView:setIsLocked( img.width <= scrollView.width and img.height <= scrollView.height )
end

-- Prepare the act before the show transition
function act:prepare()
	-- If we got here with no document to open then go back to Documents view
	if not game.openDoc then
		game.gotoScene( "documents" )
		return
	end

	-- Set title bar text to base name of document
	act.title.text = game.openDoc.baseName

	-- If the document is already loaded, then do nothing (preserves scroll position)
	if loadedDoc then
		if loadedDoc.baseName == game.openDoc.baseName and loadedDoc.ext == game.openDoc.ext then
			return
		end
	end

	-- Destroy previous scrollView and its contents if any
	if scrollView then 
		scrollView:removeSelf()
		scrollView = nil
		loadedDoc = nil
	end

	-- Determine file type and prepare the view accordingly
	local ext = game.openDoc.ext or "txt"
	if ext == "txt" then
		prepareTextDoc()
	elseif ext == "png" or ext == "jpg" then
		prepareImageDoc( ext )
	else
		print("*** Unrecognized document type: ", game.openDoc.basename, ext )
	end
end

------------------------- End of Activity --------------------------------


-- Corona needs the scene object returned from the act file
return act.scene
