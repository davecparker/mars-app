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

	setmetatable(act, self)
	self.__index = self

    return act
end


------------------------- Activity Methods  --------------------------------

-- Make an new imageRect display object with the given filename, and options:
--    parent          -- display group, default is act.group
--    folder          -- subfolder where filename is located, default is media/actName
--    x, y            -- initial position of the center of the object, default is act center
--    width, height   -- display object size (default to original size/aspect)
--    allowFail       -- set to true to just return nil if image not found instead of error
-- If only one of width or height is included, the other is calculated to retain the aspect.
function Act:newImage( filename, options )
    -- Check the parameter types
    assert( type( filename ) == "string" )
    assert( not options or (type( options ) == "table") )

    -- Get default values for options
    options = options or {}
    local parent = options.parent or self.group
    local folder = options.folder or "media/" .. self.name 
    local x = options.x or self.xCenter
    local y = options.y or self.yCenter
    local width = options.width
    local height = options.height

    -- Determine file path
    local path = folder .. "/".. filename

    -- Do we need to calculate width or height from the original image size?
    if not width or not height then
        -- TODO: Replace this with a more efficient implementation (read PNG/JPG header)
        local image = display.newImage( parent, path, x, y, true )
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
        image.x = x
        image.y = y
    end
    return image
end

-- Make and return a display sub-group with the given parent (default act.group)
function Act:newGroup( parent )
	parent = parent or self.group
	local g = display.newGroup()
	parent:insert( g )
	return g
end 

-- Make a background title bar for a game view with the given title string (default empty).
-- If backListener is passed, include a back button and call backListener when pressed.
function Act:makeTitleBar( title, backListener )
    -- Background for the whole view
    local bg = display.newRect( self.group, self.xCenter, self.yCenter, self.width, self.height )
    bg:setFillColor( 1 )   -- white

    -- Title bar
    local bar = display.newRect( self.group, self.xMin, self.yMin, self.width, self.dyTitleBar )
    bar.anchorX = 0
    bar.anchorY = 0
    bar:setFillColor( 0.5, 0, 0 )   -- dark red

    -- Title bar text
    title = title or ""
    self.title = display.newText( self.group, title, 
                        self.xCenter, self.yMin + self.dyTitleBar / 2, 
                        native.systemFontBold, 18 )
    self.title:setFillColor( 1 )   -- white

    -- Back button if requested
    if backListener then
        local bb = self:newImage( "back.png", { folder = "media/game", height = self.dyTitleBar * 0.6 } )
        bb.x = self.xMin + 15
        bb.y = self.yMin + self.dyTitleBar / 2
        bb:addEventListener( "tap", backListener )
    end
end

-- Make a map item icon in the group with the given data table containing:
--   t       -- "item", "doc", or "act"
--   name    -- item name (e.g. "H2O"), document name, or act name
--   x, y    -- position relative to the given group
function Act:newMapIcon( group, data )
    -- Create a rotating rectangle with a black frame
    assert( type( data ) == "table" )
    local icon = display.newRect( group, data.x, data.y, 16, 16 )
    icon:setStrokeColor( 0 )   -- black
    icon.strokeWidth = 3
    transition.to( icon, { delta = true, rotation = 360, time = 3000, iterations = 0 })

    -- Store the type and name in the icon
    icon.t = data.t
    icon.name = data.name

    -- Set the fill color based on the icon type
    if icon.t == "act" then
        icon:setFillColor( 1, 0, 0 )  -- red
    elseif icon.t == "doc" then
        icon:setFillColor( 1, 1, 0 )  -- yellow
    else
        icon:setFillColor( 0, 1, 0 )  -- green
    end
    return icon
end


------------------------- Game Activity Management  --------------------------------

-- Go to a given act, with transition options (see composer.gotoScene for parameters)
function game.gotoAct( name, options )
    composer.gotoScene( name, options )  -- CRASH? If you get 'sceneName' nil here then you
                                         -- forgot to return act.scene from your act file.
end

-- Destroy the given act scene
function game.removeAct( name )
    composer.removeScene( name )
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
