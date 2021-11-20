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

local function showList(array)
    app.alert(array[1]..","..array[2]..","..array[3])
end

local function getFrameInfo(sprite, frameNum)
    local result = {
        from=frameNum,
        layers={}
    }

    for _,layer in ipairs(sprite.layers) do
        local cel = layer:cel(frameNum)
        table.insert(result.layers, {
            ["image"] = cel.image,
            ["position"] = cel.position
        })
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

local function getListOfFrames()
    local result = {}

    for idx=1,#app.activeSprite.frames do
        table.insert(result, tostring(idx))
    end

    return result
end


local function mainWindow()
    local dialog = Dialog("Sort Frames...")

    local frameList = getListOfFrames()

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
        option=1,
        options=frameList
    }

    dialog:combobox {
        id="to_one",
        option=1,
        options=frameList
    }

    dialog:newrow()

    dialog:combobox {
        id="from_two",
        option=1,
        options=frameList
    }

    dialog:combobox {
        id="to_two",
        option=1,
        options=frameList
    }

    dialog:newrow()

    dialog:combobox {
        id="from_three",
        option=1,
        options=frameList
    }

    dialog:combobox {
        id="to_three",
        option=1,
        options=frameList
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

    return dialog
end

local mainWindow = mainWindow()
mainWindow:show{ wait=true }

-- they wish to continue with their changes
if (mainWindow.data.confirm) then
    app.transaction(function() 
        -- set up local variables
        local sprite = app.activeSprite
        local dialogData = mainWindow.data
        local from1, from2, from3, to1, to2, to3 = dialogData.from_one, dialogData.from_two, dialogData.from_three, dialogData.to_one, dialogData.to_two, dialogData.to_three

        -- read in the frames selected (we need to remember which image is associated with which layer)
        local frameData = {
            [tostring(to1)] = getFrameInfo(sprite, from1),
            [tostring(to2)] = getFrameInfo(sprite, from2),
            [tostring(to3)] = getFrameInfo(sprite, from3)
        }

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

        sortLargeToSmall(fromArray)
        sortLargeToSmall(toArray)

        -- write the frames selected into their destination
        -- 1) write the frame data in REVERSE numerical order (sort largest > smallest)
        writeFrameInfo(sprite, toArray, frameData)

        -- 2) delete the former frames in REVERSE numerical order (sort largest > smallest)
        deleteFramesInOrder(sprite, fromArray)

    end)
end