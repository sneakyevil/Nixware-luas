-- Netvars
local m_bBombTicking        = se.get_netvar("DT_PlantedC4", "m_bBombTicking")
local m_flC4Blow            = se.get_netvar("DT_PlantedC4", "m_flC4Blow")
local m_flTimerLength       = se.get_netvar("DT_PlantedC4", "m_flTimerLength")
local m_flDefuseCountDown   = se.get_netvar("DT_PlantedC4", "m_flDefuseCountDown")
local m_flDefuseLength      = se.get_netvar("DT_PlantedC4", "m_flDefuseLength")
local m_hBombDefuser        = se.get_netvar("DT_PlantedC4", "m_hBombDefuser")

local function GetPlantedBomb()
    local entities = entitylist.get_entities_by_class_id(129)
    for i = 1, #entities do
        if entities[i]:get_prop_bool(m_bBombTicking) then
            return entities[i]
        end
    end


    return nil
end

local m_FontSize    = 15
local m_Font        = renderer.setup_font("C:/windows/fonts/segoeui.ttf", m_FontSize, 0)

local function CenterShadowText(pos, text)
    pos.x = pos.x - (renderer.get_text_size(m_Font, m_FontSize, text).x * 0.5)

    renderer.text(text, m_Font, vec2_t.new(pos.x + 1, pos.y + 1), m_FontSize, color_t.new(0, 0, 0, 255))
    renderer.text(text, m_Font, pos, m_FontSize, color_t.new(255, 255, 255, 255))
end

local plant_end     = 0.0
local plant_length  = 3.25

client.register_callback("bomb_beginplant", function(event)
    plant_end = globalvars.get_current_time() + plant_length
end)

client.register_callback("bomb_abortplant", function(event)
    plant_end = 0.0
end)

local m_ScreenSize = engine.get_screen_size()

client.register_callback("paint", function()
    local bomb = GetPlantedBomb()
    if (bomb == nil) then

        local plant_time         = plant_end - globalvars.get_current_time()
        local plant_percentage   = plant_time / plant_length
        if (0.0 > plant_time) then return end

        plant_percentage = 1.0 - plant_percentage
        renderer.rect_filled(vec2_t.new(0, 0), vec2_t.new(m_ScreenSize.x * plant_percentage, 14), color_t.new(200, 100, 0, 100))
        CenterShadowText(vec2_t.new(m_ScreenSize.x * plant_percentage, -2), string.format("%.1f", plant_time))
        return
    end

    plant_end = 0.0
   
    local bomb_time         = bomb:get_prop_float(m_flC4Blow) - globalvars.get_current_time()
    local bomb_percentage   = bomb_time / bomb:get_prop_float(m_flTimerLength)
    if (0.0 > bomb_time) then return end

    renderer.rect_filled(vec2_t.new(0, 0), vec2_t.new(m_ScreenSize.x * bomb_percentage, 14), color_t.new(0, 200, 0, 100))
    CenterShadowText(vec2_t.new(m_ScreenSize.x * bomb_percentage, -2), string.format("%.1f", bomb_time))

    -- Defuse Timer
    if (bomb:get_prop_int(m_hBombDefuser) == -1) then return end

    local defuse_time           = bomb:get_prop_float(m_flDefuseCountDown) - globalvars.get_current_time()
    local defuse_percentage     = (defuse_time / bomb:get_prop_float(m_flDefuseLength)) * (bomb:get_prop_float(m_flDefuseLength) / bomb:get_prop_float(m_flTimerLength))
    if (0.0 > defuse_time) then return end

    renderer.rect_filled(vec2_t.new(0, 14), vec2_t.new(m_ScreenSize.x * defuse_percentage, 28), (defuse_time > bomb_time and color_t.new(200, 0, 0, 100) or color_t.new(0, 0, 200, 100)))
    CenterShadowText(vec2_t.new(m_ScreenSize.x * defuse_percentage, 12), string.format("%.1f", defuse_time))
end)
