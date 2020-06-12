local tool_form = [[
    size[7,3]
    item_image[0,0;1,1;%s]
    field[1,1.5;6,1;target;Enter Itemstring;%s]
]]

local function get_metadata(toolstack)
    local m = minetest.deserialize(toolstack:get_metadata()) or {}
    if not m.target then m.target = "" end
    return m
end

minetest.register_tool("ist:tool", {
    description = "IST tool",
    inventory_image = "ist_tool.png",
    on_use = function(toolstack, user, pointed_thing)
        if not user or not user:is_player() or user.is_fake_player then return end
        local player_name = user:get_player_name()
        local toolmeta = get_metadata(toolstack)
        local target = toolmeta.target
        local pos = minetest.get_pointed_thing_position(pointed_thing)
        local start = vector.subtract(pos, 5)
        local stop = vector.add(pos, 5)
        local found = false
        for x = start.x, stop.x do
            for y = start.y, stop.y do
                for z = start.z, stop.z do
                    local node_meta = minetest.get_meta({x=x, y=y, z=z})
                    local node_inv = node_meta:get_inventory()
                    for list, _ in pairs(node_inv:get_lists()) do
                        if node_inv:contains_item(list, target, false) then
                            minetest.chat_send_player(player_name, ("found @ (%s, %s, %s)"):format(x, y, z))
                            found = true
                        end
                    end
                end
            end
        end
        if not found then
            minetest.chat_send_player(player_name, "not found: " .. toolmeta.target)
        end
    end,
    on_place = function(toolstack, user, pointed_thing)
        if not user or not user:is_player() or user.is_fake_player then return end
        local player_name = user:get_player_name()
        local toolmeta = get_metadata(toolstack)
        minetest.show_formspec(player_name, "ist:tool_control", tool_form:format(
            toolstack:get_name(), -- item_image
            toolmeta.target  -- field
        ))
    end,
})

minetest.register_on_player_receive_fields(function(user, formname, fields)
    if formname ~= "ist:tool_control" then return end
    if not user or not user:is_player() or user.is_fake_player then return end
    local toolstack = user:get_wielded_item()
    if toolstack:get_name() ~= "ist:tool" then return true end

    local toolmeta = get_metadata(toolstack)

    toolmeta.target = fields["target"] or toolmeta.target

    toolstack:set_metadata(minetest.serialize(toolmeta))
    user:set_wielded_item(toolstack)
    return true
end)
