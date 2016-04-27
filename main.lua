function load_json(filename)
  local json_file = io.open(filename, "r")
  local json = json_file:read("*all")

  json_file:close()

  return am.parse_json(json)
end

function setup_scene()
  local window = am.window{
    title = "A Sine of the Times",
  }

  window.scene = am.rect(
    -window.pixel_width / 2, -window.pixel_height / 2,
    window.pixel_width / 2, window.pixel_height / 2
  )

  return window
end

function load_level(index)
  local waves = load_json("data/waves.json")
  local levels = load_json("data/levels.json")

  local level = {
    index = index,
  }

  local level_waves = levels[level.index].waves

  level.waves = {}

  for i = 1, table.getn(level_waves) do
    level.waves[i] = waves[level_waves[i]]
  end

  return level
end

function start_level(window, level, start_time)
  window.scene:action(function(scene)
    local t = am.frame_time - start_time
    local value = 1

    for i = 1, table.getn(level.waves) do
      local wave = level.waves[i]

      value = value * math.sin(2 * math.pi * wave.frequency * t + wave.phase)
    end

    if value > 0 then
      scene.hidden = false
    else
      scene.hidden = true
    end
  end)
end

local window = setup_scene()
local level = load_level(1)

start_level(window, level, am.frame_time)
