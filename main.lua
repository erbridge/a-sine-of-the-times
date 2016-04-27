local wave_json_file = io.open("data/waves.json", "r")
local wave_json = wave_json_file:read("*all")

wave_json_file:close()

local win = am.window{
  title = "A Sine of the Times",
}

win.scene = am.rect(
  -win.pixel_width / 2, -win.pixel_height / 2,
  win.pixel_width / 2, win.pixel_height / 2
)

local level_state = {
  start_time = 0,
  waves = am.parse_json(wave_json)
}

win.scene:action(function(scene)
  local t = am.frame_time - level_state.start_time
  local value = 1

  for i = 1, table.getn(level_state.waves) do
    local wave = level_state.waves[i]

    value = value * math.sin(2 * math.pi * wave.frequency * t + wave.phase)
  end

  if value > 0 then
    scene.hidden = false
  else
    scene.hidden = true
  end
end)
