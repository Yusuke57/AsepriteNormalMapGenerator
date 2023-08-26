----------------------------------------------------------------------
-- Extension to generate normal map from X, Y(, and Z) layer in Aseprite
-- https://github.com/Yusuke57/AsepriteNormalMapGenerator
----------------------------------------------------------------------

local empty = "" -- Because nil cannot be put in the table

local function createNormalImage(frame, layers)
    local pixelColor = app.pixelColor
    local normalImage = Image(app.activeSprite.width, app.activeSprite.height)

    for it in normalImage:pixels() do
        local colorValues = { 255, 255, 255, 0 }
        for i, layer in ipairs(layers) do
            if i >= #colorValues then break end
            if layer == empty then goto continue end

            local cel = layer:cel(frame)
            if cel == nil then goto continue end

            local pos = cel.position
            if it.x < pos.x or it.x >= pos.x + cel.image.width then goto continue end
            if it.y < pos.y or it.y >= pos.y + cel.image.height then goto continue end

            local pixelValue = cel.image:getPixel(it.x - pos.x, it.y - pos.y)
            local grayScaleValue = pixelColor.graya(pixelValue)
            local alpha = pixelColor.rgbaA(pixelValue)
            colorValues[i] = grayScaleValue
            colorValues[#colorValues] = math.max(colorValues[#colorValues], alpha)

            ::continue::
        end

        local color = pixelColor.rgba(colorValues[1], colorValues[2], colorValues[3], colorValues[4])
        normalImage:drawPixel(it.x, it.y, color)
    end

    return normalImage
end

local function getOrCreateNormalMapLayer()
    local normalMapLayerName = "NormalMap"
    for i, layer in ipairs(app.activeSprite.layers) do
        if layer.name == normalMapLayerName then
            return layer
        end
    end

    local normalMapLayer = app.activeSprite:newLayer()
    normalMapLayer.name = normalMapLayerName
    return normalMapLayer
end

local function execute(layers, frames)
    local normalMapLayer = getOrCreateNormalMapLayer()
    for i, frame in ipairs(frames) do
        local normalImage = createNormalImage(frame, layers)
        app.activeSprite:newCel(normalMapLayer, frame, normalImage, 0)
    end
    app.refresh()
end

-- GUI
local none = "None"
local dialogTitle = "Generate Normal Map"
local framesAll = "All Frames"
local framesSelected = "Selected Frames"

local function onClickGenerateButton(dialog)
    local data = dialog.data
    local allLayers = app.activeSprite.layers
    local layers = { allLayers[data.layerX] or empty, allLayers[data.layerY] or empty, allLayers[data.layerZ] or empty }
    local frames = data.frames == framesAll and app.activeSprite.frames or app.range.frames

    app.transaction(dialogTitle, execute(layers, frames))
    dialog:close()
end

local function showDialog()
    local dialog = Dialog(dialogTitle)
    local layerNames = { none }
    local defaultOptions = { x = none, y = none, z = none }
    for i, layer in ipairs(app.activeSprite.layers) do
        table.insert(layerNames, layer.name)
        -- TODO: Show last selected layer as default value
        if layer.name == "X" then defaultOptions.x = layer.name end
        if layer.name == "Y" then defaultOptions.y = layer.name end
        if layer.name == "Z" then defaultOptions.z = layer.name end
    end

    dialog:combobox{ id="layerX", label="Layer X: ", options = layerNames, option = defaultOptions.x }
    dialog:combobox{ id="layerY", label="Layer Y: ", options = layerNames, option = defaultOptions.y }
    dialog:combobox{ id="layerZ", label="Layer Z: ", options = layerNames, option = defaultOptions.z }
    dialog:combobox{ id="frames", label="Frames: ", options = { framesAll, framesSelected } }
    dialog:button{ id="generate", text="Generate", focus=true, onclick=function() onClickGenerateButton(dialog) end }
    dialog:button{ id="cancel", text="Cancel" }

    dialog:show()
end

showDialog()