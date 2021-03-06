-----------------------------------------------------------------------------------------
--
-- Act.lua
--
-- The Act class is a base class for all activities (acts) in the Mars App.
-----------------------------------------------------------------------------------------

-- Get local reference to the game globals
local game = globalGame

-- Required Corona modules
local composer = require( "composer" )

-- The Act class table
local Act = {
    -- Display metrics
    dyTitleBar = 40,     -- height of standard view title bar
}


-- Create a new instance of the Act class
function Act:new()
    local act = {}
	setmetatable( act, self )
	self.__index = self
    return act
end


------------------------- Activity Methods  --------------------------------

-- Make an new imageRect display object with the given filename, and options:
--    parent            -- display group, default is act.group
--    folder            -- subfolder where filename is located, default is media/actName
--    x, y              -- initial position of the center of the object, default is act center
--    anchorX, anchorY  -- anchor location (default 0.5 for center)
--    width, height     -- display object size (default to original size/aspect)
--    allowFail         -- set to true to just return nil if image not found instead of error
-- If only one of width or height is included, the other is calculated to retain the aspect.
function Act:newImage( filename, options )
    -- Check the parameter types
    assert( type( filename ) == "string" )
    assert( not options or (type( options ) == "table") )

    -- Get some default values
    options = options or {}
    local parent = options.parent or self.group
    local folder = options.folder or "media/" .. self.name 
    local width = options.width
    local height = options.height

    -- Determine file path
    local path = folder .. "/".. filename

    -- Do we need to calculate width or height from the original image size?
    if not width or not height then
        -- TODO: Replace this with a more efficient implementation (read PNG/JPG header)
        local image = display.newImage( parent, path, 0, 0, true )
        if image then
            if not width and not height then
                width = image.width
                height = image.height
            elseif not width then
                width = height * image.width / image.height
            else
                assert( not height )
                height = width * image.height / image.width
            end
            image:removeSelf()
        end
    end

    -- Now make the imageRect at the desired size and position
    width = width or self.width
    height = height or self.height
    local image = display.newImageRect( parent, path, width, height )
    if not image then
        if options.allowFail then
            return nil
        end
        error( "Image not found: " .. path, 2 )  -- report runtime error at the calling location
    else
        image.x = options.x or self.xCenter
        image.y = options.y or self.yCenter
        image.anchorX = options.anchorX or 0.5
        image.anchorY = options.anchorY or 0.5
    end
    return image
end

-- Make a new text object in the Act at the given position and font size
-- The font is always system font and the fontSize defaults to 14.
function Act:newText( text, x, y, fontSize )
    return display.newText( self.group, text, x, y, native.systemFont, (fontSize or 14) )
end

-- Make and return a display sub-group with the given parent (default act.group)
function Act:newGroup( parent )
	parent = parent or self.group
	local g = display.newGroup()
	parent:insert( g )
	return g
end 

-- Make and return a solid white background for the act.
function Act:whiteBackground()
    -- Background for the whole view
    local bg = display.newRect( self.group, self.xCenter, self.yCenter, self.width, self.height )
    bg:setFillColor( 1 )  -- white
    return bg
end    

-- Make and return a background with the given grayscale shade (0-1, default 0.7) for the act.
function Act:grayBackground( gray )
    -- Background for the whole view
    local bg = display.newRect( self.group, self.xCenter, self.yCenter, self.width, self.height )
    bg:setFillColor( gray or 0.7 )
    return bg
end    

-- Make a background title bar for a game view with the given title string (default empty).
-- If backListener is passed, include a back button and call backListener when pressed.
-- Return a display group containing all the title bar elements.
function Act:makeTitleBar( title, backListener )
    -- Make a display group to hold all the title bar elements
    local group = self:newGroup()

    -- Colored bar
    local bar = display.newRect( group, self.xMin, self.yMin, self.width, self.dyTitleBar )
    bar.anchorX = 0
    bar.anchorY = 0
    bar:setFillColor( game.themeColor.r, game.themeColor.g, game.themeColor.b )
    bar:addEventListener( "touch", game.eatTouch )  -- eat touches on title bar
    bar:addEventListener( "tap", game.eatTouch )    -- and taps too

    -- Title bar text
    title = title or ""
    self.title = display.newText( group, title, 
                        self.xCenter, self.yMin + self.dyTitleBar / 2, 
                        native.systemFontBold, 18 )
    self.title:setFillColor( 1 )   -- white

    -- Back button if requested
    if backListener then
        local bb = self:newImage( "backArrow.png", { 
            parent = group, 
            folder = "media/game", 
            height = self.dyTitleBar * 0.6 
        } )
        bb.x = self.xMin + 17
        bb.y = self.yMin + self.dyTitleBar / 2
        bb:addEventListener( "tap", backListener )
    end
    return group
end

-- Load and return a sound file with the given filename. 
-- Use the folder if given, else media/actName
function Act:loadSound( filename, folder )
    folder = folder or ("media/" .. self.name)
    return audio.loadSound( folder .. "/" .. filename )
end


------------------------- Game Activity Management  --------------------------------

-- Go to the given scene with transition options (see composer.gotoScene)
function game.gotoScene( scene, options )
    composer.gotoScene( scene, options )
end

-- Go to a given act on the main tab, with transition options (see composer.gotoScene)
function game.gotoAct( act, options )
    game.currentMainAct = act    -- Remember the current act running on the main tab
    composer.gotoScene( act, options )  -- CRASH? If you get 'sceneName' nil here then you
                                         -- forgot to return act.scene from your act file.
end

-- Destroy the given act scene
function game.removeAct( name )
    composer.removeScene( name )
end

-- Return the current act name
function game.currentActName()
    return composer.getSceneName( "current" )
end

-- Call this to create an act object inside the act's source file
function game.newAct()
    -- The act object to return
    local act = Act:new()

    -- Calculate dimentions of act area (full device above the tab bar)
    act.width = game.width 
    act.height = game.height - game.dyTabBar
    act.xMin = game.xMin
    act.xMax = game.xMax
    act.yMin = game.yMin
    act.yMax = game.yMax - game.dyTabBar
    act.xCenter = (act.xMin + act.xMax) / 2
    act.yCenter = (act.yMin + act.yMax) / 2

    -- Create a composer scene for the act and link them together
    local scene = composer.newScene()
    act.scene = scene
    scene.act = act

    -- Add the composer event listeners
    scene:addEventListener( "create", scene )
    scene:addEventListener( "show", scene )
    scene:addEventListener( "hide", scene )
    scene:addEventListener( "destroy", scene )

    -- Set the composer scene creation function
    function scene:create( event )
        local act = self.act
        act.group = scene.view  -- store the scene display group
        act.name = composer.getSceneName( "current" )
        act:init()  -- call the act init function (required)
    end

    -- Set the composer show function
    function scene:show( event )
        -- When the scene is on-screen and ready to go...
        local act = self.act
        if event.phase == "will" then
            -- Make sure game state is current before the new view starts
            game.updateState()

            -- Call the act prepare function, if any
            if act.prepare then 
                act:prepare()
            end            
        elseif event.phase == "did" then
            -- Add an enterFrame listener for the act object
            Runtime:addEventListener( "enterFrame", act )

            -- Call the act start function, if any
            if act.start then 
                act:start()
            end
        end
    end

    -- Set the composer hide function
    function scene:hide( event )
        -- When scene goes inactive...
        local act = self.act
        if event.phase == "will" then
            -- Remove the enterFrame listener for the act object
            Runtime:removeEventListener( "enterFrame", act )

            -- Call the act stop function, if any
            if act.stop then 
                act:stop()
            end
        end
    end

    -- Set the composer destroy function
    function scene:destroy( event )
        -- Call the act destroy function, if any
        local act = self.act
        if act.destroy then 
            act:destroy()
        end
    end

    -- Return the act object
    return act
end

------------------------- End of Methods  --------------------------------

return Act
