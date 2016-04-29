local LEVELS = nil
local WAVES = nil

function load_json(filename)
  local json_file = io.open(filename, "r")
  local json = json_file:read("*all")

  json_file:close()

  return am.parse_json(json)
end

function setup_scene()
  local window = am.window{
    title = "SINE-O-TRON 3000",
    borderless = true,
  }

  window.scene = am.rect(
    -window.pixel_width / 2, -window.pixel_height / 2,
    window.pixel_width / 2, window.pixel_height / 2
  )

  return window
end

function load_level(index)
  if LEVELS == nil then
    LEVELS = load_json("data/levels.json")
  end

  if index > table.getn(LEVELS) then
    return nil
  end

  local level_data = LEVELS[index]

  local level = {
    index = index,
    solution = level_data.solution,
    waves = {},
  }

  if WAVES == nil then
    WAVES = load_json("data/waves.json")
  end

  for i = 1, table.getn(level_data.waves) do
    local wave_index = level_data.waves[i]
    local wave = WAVES[wave_index]

    level.waves[i] = {
      index = wave_index,
      frequency = wave.frequency,
      phase = wave.phase,
    }
  end

  return level
end

function end_game(window)
  window.scene.hidden = true
end

function transition_to_level(window, index, success)
  local duration = 1
  local base_hidden_count = 1

  if success then
    base_hidden_count = 5
  end

  local hidden_count = base_hidden_count

  local hidden = true
  local end_time = am.frame_time + duration

  window.scene:action(function(scene)
    scene.hidden = hidden

    hidden_count = hidden_count - 1

    if hidden_count < 1 then
      hidden = not hidden

      hidden_count = base_hidden_count
    end

    if am.frame_time > end_time then
      local level = load_level(index)

      if level then
        start_level(window, level)
      else
        end_game(window)
      end

      return true
    end
  end)
end

function calculate_wave_amplitude(wave, t)
  local phase = wave.phase * math.pi / 180

  return math.sin(2 * math.pi * wave.frequency * t + phase)
end

function start_level(window, level)
  log("level "..level.index..": starting")

  local start_time = am.frame_time
  local solution_index = 1
  local solution_length = string.len(level.solution)

  local last_solution_key = nil
  local solution_key = string.sub(
    level.solution, solution_index, solution_index
  )

  window.scene:action(function(scene)
    local t = am.frame_time - start_time

    local amplitude = 1
    local keys_down_count = table.getn(window:keys_down())

    for i = 1, table.getn(level.waves) do
      local wave = level.waves[i]

      if window:key_down(wave.index) then
        keys_down_count = keys_down_count - 1
      else
        amplitude = amplitude * calculate_wave_amplitude(wave, t)
      end
    end

    if amplitude > 0 then
      scene.hidden = false
    else
      scene.hidden = true
    end

    local solution_key = string.sub(
      level.solution, solution_index, solution_index
    )

    local err = false

    if keys_down_count > 1 then
      err = true
    elseif window:key_pressed(solution_key) then
      solution_index = solution_index + 1
      last_solution_key = solution_key
      solution_key = string.sub(
        level.solution, solution_index, solution_index
      )
    elseif keys_down_count == 1 and not window:key_down(last_solution_key) then
      err = true
    end

    if err then
      log("level "..level.index..": failed")

      transition_to_level(window, level.index, false)

      return true
    elseif solution_index > solution_length then
      log("level "..level.index..": complete")

      transition_to_level(window, level.index + 1, true)

      return true
    end
  end)
end

function start_game()
  local window = setup_scene()
  local level = load_level(1)

  start_level(window, level)
end

start_game()
