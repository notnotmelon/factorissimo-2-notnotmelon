-- This file adds quality information to factoriopedia.

local nonhidden_quality_count = 0
for _, quality in pairs(data.raw.quality) do
    if not quality.hidden then
        nonhidden_quality_count = nonhidden_quality_count + 1
    end
end
if nonhidden_quality_count <= 1 then return end

data.raw["storage-tank"]["factory-1"].localised_description = {"entity-description.factory-1-quality"}
data.raw["storage-tank"]["factory-2"].localised_description = {"entity-description.factory-2-quality"}
data.raw["storage-tank"]["factory-3"].localised_description = {"entity-description.factory-3-quality"}

local FACTORY_PUMPING_SPEED = 12000 -- per second

-- returns the default buff amount per quality level in vanilla
local function get_quality_buff(quality_level)
	return 1 + quality_level * 0.3
end

local function add_quality_factoriopedia_info(entity, factoriopedia_info)
    local factoriopedia_description = entity.factoriopedia_description

    for _, factoriopedia_info in pairs(factoriopedia_info or {}) do
        local header, factoriopedia_function = unpack(factoriopedia_info)
        local localised_string = {"", "[font=default-semibold]", header, "[/font]"}
        for _, quality in pairs(data.raw.quality) do
            local quality_level = quality.level
            if quality.hidden then goto continue end

            local quality_buff = factoriopedia_function(entity, quality_level)
            if type(quality_buff) ~= "table" then quality_buff = tostring(quality_buff) end
            table.insert(localised_string, {"", "\n[img=quality." .. quality.name .. "] ", {"quality-name." .. quality.name}, ": [font=default-semibold]", quality_buff, "[/font]"})
            ::continue::
        end

        if factoriopedia_description then
            factoriopedia_description = {"", factoriopedia_description, "\n\n", localised_string}
        else
            factoriopedia_description = localised_string
        end
    end

    entity.factoriopedia_description = factoriopedia_description
end

add_quality_factoriopedia_info(data.raw["storage-tank"]["factory-1"], {
    {{"quality-tooltip.connections"}, function(entity, quality_level)
        local connection_count
        if quality_level <= 0 then
            connection_count = 16
        elseif quality_level == 1 then
            connection_count = 18
        elseif quality_level == 2 then
            connection_count = 20
        elseif quality_level == 3 then
            connection_count = 22
        elseif quality_level == 4 then
            connection_count = 24
        else
            connection_count = 26
        end
        return connection_count
    end},
    {{"quality-tooltip.fluid-transfer-speed"}, function(entity, quality_level) return tostring(FACTORY_PUMPING_SPEED * get_quality_buff(quality_level)) .. "/s" end}
})

add_quality_factoriopedia_info(data.raw["storage-tank"]["factory-2"], {
    {{"quality-tooltip.connections"}, function(entity, quality_level)
        local connection_count
        if quality_level <= 0 then
            connection_count = 24
        elseif quality_level == 1 then
            connection_count = 26
        elseif quality_level == 2 then
            connection_count = 28
        elseif quality_level == 3 then
            connection_count = 30
        elseif quality_level == 4 then
            connection_count = 32
        else
            connection_count = 34
        end
        return connection_count
    end},
    {{"quality-tooltip.fluid-transfer-speed"}, function(entity, quality_level) return tostring(FACTORY_PUMPING_SPEED * get_quality_buff(quality_level)) .. "/s" end}
})

add_quality_factoriopedia_info(data.raw["storage-tank"]["factory-3"], {
    {{"quality-tooltip.connections"}, function(entity, quality_level)
        local connection_count
        if quality_level <= 0 then
            connection_count = 32
        elseif quality_level == 1 then
            connection_count = 34
        elseif quality_level == 2 then
            connection_count = 38
        elseif quality_level == 3 then
            connection_count = 42
        elseif quality_level == 4 then
            connection_count = 44
        else
            connection_count = 46
        end
        return connection_count
    end},
    {{"quality-tooltip.fluid-transfer-speed"}, function(entity, quality_level) return tostring(FACTORY_PUMPING_SPEED * get_quality_buff(quality_level)) .. "/s" end}
})
