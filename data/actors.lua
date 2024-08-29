local actors = {}

local interacted_objects_blacklist = {}

-- Tabela para definir diferentes tipos de atores e suas configurações
local actor_types = {
    shrine = {
        pattern = "Shrine",
        move_threshold = 40,
        interact_threshold = 2.5,
        interact_function = function(obj) 
            -- Lógica específica para interagir com shrines
            interact_object(obj)
        end
    },
    goblin = {
        pattern = "Goblin",
        move_threshold = 40,
        interact_threshold = 3,
        interact_function = function(obj)
            -- Lógica específica para interagir com goblins
            -- Por exemplo, atacar ou fugir
            attack_or_flee(obj)
        end
    }
    -- Adicione mais tipos de atores conforme necessário
}

local function is_actor_of_type(skin_name, actor_type)
    return skin_name:match(actor_types[actor_type].pattern)
end

local function should_interact_with_actor(actor_position, player_position, actor_type)
    local distance_threshold = actor_types[actor_type].interact_threshold
    return actor_position:dist_to(player_position) < distance_threshold
end

local function move_to_actor(actor_position, player_position, actor_type)
    local move_threshold = actor_types[actor_type].move_threshold
    local distance = actor_position:dist_to(player_position)
    
    if distance <= move_threshold then
        pathfinder.request_move(actor_position)
        console.print("Detectado " .. actor_type .. " a " .. distance .. " unidades. Movendo-se em direção.")
        return true
    end
    
    return false
end

function actors.update()
    local local_player = get_local_player()
    if not local_player then
        return
    end

    local player_pos = local_player:get_position()
    local objects = actors_manager.get_ally_actors()

    if #interacted_objects_blacklist > 200 then
        interacted_objects_blacklist = {}
    end

    for _, obj in ipairs(objects) do
        if obj then
            local obj_id = obj:get_id()
            if not interacted_objects_blacklist[obj_id] then
                local position = obj:get_position()
                local skin_name = obj:get_skin_name()

                for actor_type, config in pairs(actor_types) do
                    if skin_name and is_actor_of_type(skin_name, actor_type) and not obj:can_not_interact() then
                        local distance = position:dist_to(player_pos)
                        if distance <= config.move_threshold then
                            if move_to_actor(position, player_pos, actor_type) then
                                console.print("Movendo-se em direção ao " .. actor_type .. ": " .. skin_name)
                                if should_interact_with_actor(position, player_pos, actor_type) then
                                    config.interact_function(obj)
                                    interacted_objects_blacklist[obj_id] = true
                                    console.print("Interagiu com o " .. actor_type .. ": " .. skin_name)
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

return actors