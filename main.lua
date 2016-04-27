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
  -- TODO: Only load this once.
  local levels = load_json("data/levels.json")

  if index > table.getn(levels) then
    return nil
  end

  local level = {
    index = index,
  }

  local level_waves = levels[level.index].waves

  -- TODO: Only load this once.
  local waves = load_json("data/waves.json")

  level.waves = {}

  for i = 1, table.getn(level_waves) do
    level.waves[i] = waves[level_waves[i]]
  end

  return level
end

function transition_to_level(window, index, duration)
  local hidden = true
  local end_time = am.frame_time + duration

  window.scene:action(function(scene)
    scene.hidden = hidden

    hidden = not hidden

    if am.frame_time > end_time then
      local level = load_level(index)

      if level then
        start_level(window, level)
      else
        -- TODO: Cycle the levels? Give some sort of reward?
        window:close()
      end

      return true
    end
  end)
end

function calculate_wave_amplitude(wave, t)
  return math.sin(2 * math.pi * wave.frequency * t + wave.phase)
end

function start_level(window, level)
  log("level "..level.index..": starting")

  local start_time = am.frame_time
  local hold_start_time = nil

  window.scene:action(function(scene)
    local t = am.frame_time - start_time

    local amplitude = 1

    local wave_keys_held = true
    local held_keys_remaining = table.getn(window:keys_down())

    for i = 1, table.getn(level.waves) do
      local wave = level.waves[i]

      if window:key_down(wave.key) then
        held_keys_remaining = held_keys_remaining - 1
      else
        amplitude = amplitude * calculate_wave_amplitude(wave, t)

        wave_keys_held = false
      end
    end

    if amplitude > 0 then
      scene.hidden = false
    else
      scene.hidden = true
    end

    if wave_keys_held and held_keys_remaining < 1 then
      if hold_start_time == nil then
        hold_start_time = t
      end
    else
      hold_start_time = nil
    end

    if hold_start_time ~= nil and t - hold_start_time > 1 then
      log("level "..level.index..": complete")

      transition_to_level(window, level.index + 1, 1)

      return true
    end
  end)
end

local window = setup_scene()
local level = load_level(1)

start_level(window, level)
