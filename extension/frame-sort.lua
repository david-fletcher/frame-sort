-- MIT License

-- Copyright (c) 2021 David Fletcher

-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:

-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.

-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.

prefs = ...
if (prefs == nil) then
    prefs = {}
    prefs.values = {}
end

local filename = nil

-----------------------------------
-- DEEPCOPY FUNCTION (from http://lua-users.org/wiki/CopyTable)
-----------------------------------
-- param: orig - any Lua value (table or otherwise) that should be copied and returned
-- returns: an exact copy of the original value
-----------------------------------
-- This function is extremely useful if you need to stage edits to a table, but
-- roll them back if there was an error or if the user cancelled the action.
-- Create a copy of the table you want to edit, edit the copy, and then do nothing
-- if the changes should be ignored; but if the changes should be saved, deep copy the
-- edited copy again, and set that equal to the original value you were trying to edit.
-----------------------------------
local function deepcopy(orig)
    -- http://lua-users.org/wiki/CopyTable
    local orig_type = type(orig)
    local copy

    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end

        setmetatable(copy, deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end

    return copy
end

local function sortLargeToSmall(array)
    for i=1,#array-1 do
        local maxidx = i
        for j=i+1,#array do
            if (array[j] > array[maxidx]) then
                maxidx = j
            end
        end
        array[maxidx], array[i] = array[i], array[maxidx]
    end
end

local function getLayerGroups(sprite)
    local result = {}

    for _,layer in ipairs(sprite.layers) do
        if (layer.isGroup) then
            table.insert(result, layer.name)
        end
    end

    return result
end

local function getFrameInfo(sprite, frameNum)
    local result = {
        from=frameNum,
        layers={}
    }

    for idx,layer in ipairs(sprite.layers) do
        local cel = layer:cel(frameNum)
        if (cel ~= nil) then 
            result.layers[idx] = {
                ["image"] = cel.image,
                ["position"] = cel.position
            }
        end
    end

    return result
end

local function writeFrameInfo(sprite, orderList, frameData)
    -- create the rightmost frames first in the timeline, then work towards the left
    for idx=1,#orderList do
        -- create the new frame
        local frame = sprite:newEmptyFrame(orderList[idx])
        for i,data in ipairs(frameData[tostring(orderList[idx])].layers) do
            -- write the layer data
            sprite:newCel(sprite.layers[i], frame, data.image, data.position)
        end
    end
end

local function deleteFramesInOrder(sprite, orderList)
    for idx=1,#orderList do
        sprite:deleteFrame(sprite.frames[orderList[idx]])
    end
end

local function deleteAllHiddenLayers(sprite)
    for _,layer in ipairs(sprite.layers) do
        if (not layer.isVisible) then
            sprite:deleteLayer(layer)
        end
    end
end

local function getListOfFrames()
    local result = {}

    for idx=1,#app.activeSprite.frames+1 do
        table.insert(result, tostring(idx))
    end

    return result
end

local function mainWindow(settings)
    local dialog = Dialog("Sort Frames...")

    local frameList = getListOfFrames()

    if (settings == {}) or (settings == nil) then
        settings = {
            ["from_one"] = 1,
            ["from_two"] = 1,
            ["from_three"] = 1,
            ["to_one"] = 1,
            ["to_two"] = 1,
            ["to_three"] = 1
        }
    end

    dialog:separator {
        id="frame_sep",
        text="Frames"
    }

    dialog:label {
        id="from_label",
        text="From:"
    }

    dialog:label {
        id="to_label",
        text="To:"
    }

    dialog:newrow()

    dialog:combobox {
        id="from_one",
        option=settings["from_one"],
        options=frameList
    }

    dialog:combobox {
        id="to_one",
        option=settings["to_one"],
        options=frameList
    }

    dialog:newrow()

    dialog:combobox {
        id="from_two",
        option=settings["from_two"],
        options=frameList
    }

    dialog:combobox {
        id="to_two",
        option=settings["to_two"],
        options=frameList
    }

    dialog:newrow()

    dialog:combobox {
        id="from_three",
        option=settings["from_three"],
        options=frameList
    }

    dialog:combobox {
        id="to_three",
        option=settings["to_three"],
        options=frameList
    }

    dialog:newrow()

    dialog:combobox {
        id="layer_group",
        options=getLayerGroups(app.activeSprite)
    }

    dialog:separator {
        id="action_sep",
        text="Actions"
    }

    dialog:button {
        id="cancel",
        text="Cancel"
    }

    dialog:button {
        id="confirm",
        text="Confirm"
    }

    ------ modify to ensure changes
    dialog:modify {
        id="from_one",
        option=settings["from_one"]
    }

    dialog:modify {
        id="to_one",
        option=settings["to_one"]
    }
    dialog:modify {
        id="from_two",
        option=settings["from_two"]
    }

    dialog:modify {
        id="to_two",
        option=settings["to_two"]
    }
    dialog:modify {
        id="from_three",
        option=settings["from_three"]
    }

    dialog:modify {
        id="to_three",
        option=settings["to_three"]
    }

    return dialog
end

local mainWindow = mainWindow(prefs.values)
mainWindow:show{ wait=true }

-- they wish to continue with their changes
if (mainWindow.data.confirm) then
    
    -- set up local variables
    local sprite = app.activeSprite
    local dialogData = mainWindow.data
    local from1, from2, from3, to1, to2, to3 = dialogData.from_one, dialogData.from_two, dialogData.from_three, dialogData.to_one, dialogData.to_two, dialogData.to_three
    -- save off values into preferences for next time
    prefs.values = {
        ["from_one"] = from1,
        ["from_two"] = from2,
        ["from_three"] = from3,
        ["to_one"] = to1,
        ["to_two"] = to2,
        ["to_three"] = to3
    }

    -- create arrays necessary for transformation
    local fromArray = { 
        from1, 
        from2, 
        from3 
    }
    local toArray = { 
        to1, 
        to2, 
        to3 
    }

    -- sort
    sortLargeToSmall(fromArray)
    sortLargeToSmall(toArray)

    -- create a new file
    local tempSprite = Sprite(sprite)
    deleteAllHiddenLayers(tempSprite)
    tempSprite:flatten()

    -- read in the frames selected (we need to remember which image is associated with which layer)
    local frameData = {
        [tostring(to1)] = getFrameInfo(tempSprite, from1),
        [tostring(to2)] = getFrameInfo(tempSprite, from2),
        [tostring(to3)] = getFrameInfo(tempSprite, from3)
    }

    -- write the frames selected into their destination
    -- 1) write the frame data in REVERSE numerical order (sort largest > smallest)
    writeFrameInfo(tempSprite, toArray, frameData)

    -- 2) delete the former frames in REVERSE numerical order (sort largest > smallest)
    deleteFramesInOrder(tempSprite, fromArray)

    -- filename handling
    if (mainWindow.data.layer_group ~= nil) and (mainWindow.data.layer_group ~= "") then
        filename = app.fs.joinPath(app.fs.filePath(sprite.filename), mainWindow.data.layer_group..".png")
    else
        filename = tempSprite.filename
    end

    -- export to spritesheet
    app.command.ExportSpriteSheet {
        ui=true,
        askOverwrite=true,
        type=SpriteSheetType.ROWS,
        columns=4,
        textureFilename=filename
    }

    tempSprite:close()
end