-----------------------------------------------------------------------------------------
--
-- roverdata.lua
--
-- Contains a table of common data for the rover activity of the Mars App
--
-----------------------------------------------------------------------------------------

local data = {}

data.act = nil

-----------------------------------------------------------------------------------------
-- Display groups
-----------------------------------------------------------------------------------------
data.staticBgGrp = nil			-- display group for static background display objects
data.staticFgGrp = nil			-- display group for static foreground display objects
data.displayPanelGrp = nil		-- display group for the display panel
data.ctrlPanelGrp = nil			-- display group for the control panel
data.mapGrp = nil 				-- display group for map display objects
data.mapZoomGrp = nil			-- display group for map objects subject to zooming/panning
data.dynamicGrp = nil 			-- display group for dynamic scroll-view objects

-----------------------------------------------------------------------------------------
-- Terrain variables
-----------------------------------------------------------------------------------------
data.terrain = {} 				-- basic terrain objects
data.shape = {} 				-- terrain obstacle shapes
data.craterHeightMap = {}		-- crater height values
data.courseHeightMap = {}		-- course height values
data.defaultElevation = 100 	-- terrain elevation
data.minTerrainX = -220
data.maxTerrainX = 420
data.terrainExcess = 100 		-- off-display terrain amount
data.terrainOffset = -100 		-- terrain offset
data.terrainExtent = data.maxTerrainX - data.minTerrainX
data.nTerrainRects = 10			-- number of basic terrain objects
data.nObstacles = 25
data.craterIndex = 1			-- crater array index
data.craterEndX = 0				-- x-coordinate at which the current crater ends
data.craterHeightIndex = 1				-- crater height array index
data.floorY = data.defaultElevation		-- current crater floor height
data.nextX = data.minTerrainX 			-- x-coordinate for the next basic terrain object
data.terrainColor = { 0.8, 0.35, 0.25 }		-- terrain color
data.obstacleColor = { 0.3, 0.1, 0.1 }		-- obstace color
data.removalSensorRect = nil				-- terrain removal sensor display object

-----------------------------------------------------------------------------------------
-- Rover variables
-----------------------------------------------------------------------------------------
data.rover = nil 			-- rover display object
data.wheelSprite = {} 		-- rover wheel display objects
data.roverPosition = 100
data.sideToMapScale = 400	-- distance scale between scroll view and overhead view

-----------------------------------------------------------------------------------------
-- Control panel variables
-----------------------------------------------------------------------------------------
data.accelButton = nil
data.recoverButton = nil
data.waterButton = nil

-----------------------------------------------------------------------------------------
-- Display panel variables
-----------------------------------------------------------------------------------------
data.map = nil				-- the map display object
data.zoomInButton = nil
data.zoomOutButton = nil
data.speedText = nil		-- speed display object

-----------------------------------------------------------------------------------------
-- Other variables
-----------------------------------------------------------------------------------------			
data.drawingCrater = false		-- state variable: is true when a crater is to be drawn

return data
