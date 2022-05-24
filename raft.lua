-- raft; version 0.9
--
-- a scene-setting,
-- softcut-based delay and looper:
-- three delay lines
-- & noise generator
-- & "froth" !        
-- [controls below]
--
-- hold K1 for ALT
-- K2 = previous wave
-- K3 = next wave
-- ALT + K2 = drone reverse
-- ALT + K3 = drone forward
--
-- while on wave 3/3 ->
-- K3 = clears buffers, resets to single wave
--
-- ENCs control individual wave params
-- ALT + ENCs control noise engine

engine.name = 'Ocean'

local wave = include 'lib/wave'
local delay = include 'lib/delay'
local param_ids = include 'lib/param_ids'
local view = include 'lib/view'

local CURRENT = 1
local ACTIVE = {}
local MAX_DELAYS = 3
local ALT = false

function key(id, z) 
  if z == 1 then
    if id == 1 then
      ALT = true
    elseif id == 2 and ALT then
      -- drone in reverse
      params:set(param_ids[CURRENT][1], 1.0)
      softcut.rec_level(CURRENT,0)
      params:set("Direction", -math.abs(params:get("Direction")))
    elseif id == 2 then
      -- index to previous wave
      CURRENT = CURRENT - 1
      if CURRENT < 1 then CURRENT = 1 end
    elseif id == 3 and ALT then
      -- drone forward
      params:set(param_ids[CURRENT][1], 1.0)
      softcut.rec_level(CURRENT,0)
      params:set("Direction", math.abs(params:get("Direction")))
    elseif id == 3 then
      -- index to next wave
      -- reset if on wave 3
      local RESET = false
      CURRENT = CURRENT + 1

      if CURRENT > MAX_DELAYS then 
        CURRENT = MAX_DELAYS
        RESET = true
      end

      if #ACTIVE < CURRENT then 
        table.insert(ACTIVE,CURRENT)
        softcut.rec_level(CURRENT,1)
      end

      if RESET then
        CURRENT = 1 
        ACTIVE = { 1 }
        delay.reset()
        for n=1,3 do
          params:set(param_ids[n][1], 0.5)
          params:set("Direction", 1.0)
        end
      end
    end
  else 
    ALT = false
  end
end

function enc(id, d)
  if ALT and id == 1 then
    params:delta("FrothRate",d)
  elseif id == 1 then
    -- delay feedback
    params:delta(param_ids[CURRENT][1],d)
  elseif ALT and id == 2 then
    params:delta("OceanAmp",d)
  elseif id == 2 then
    -- delay signal amplitude
    params:delta(param_ids[CURRENT][3],d) 
  elseif ALT and id == 3 then
    params:delta("FrothAmount",d)
  elseif id == 3 then
    -- delay time
    params:delta(param_ids[CURRENT][2],d)
  end
end

function redraw()
  screen.clear()

  view.waves(#ACTIVE, wave.counter)

  -- text    
  screen.move(4,view.height - 10 - view.spacer)
  screen.level(params:get("viewBrightness") - 2)
  local string = ""
  if ALT then string = "drone" else string = "wave" end
  screen.text(string)
  screen.stroke()

  screen.move(10,10)
  screen.level(params:get("viewBrightness") - 2)
  screen.text("wave "..CURRENT.."/"..MAX_DELAYS)

  -- fb/frothRate knob
  screen.level(params:get("viewBrightness") - 2)
  screen.move(0,0)
  screen.circle(view.width - (view.width/4), view.knob, view.knob)
  screen.fill()

  screen.level(0)
  screen.move(view.width - (view.width/4), view.knob + view.spacer)
  if ALT then
    screen.text_center(params:get("FrothRate"))
    screen.stroke()
  else
    screen.text_center(params:get(param_ids[CURRENT][1]))
    screen.stroke()
  end

  screen.level(params:get("viewBrightness") - 2)
  screen.move((view.width - (view.width/4) + view.knob + view.spacer), view.knob + view.spacer)
  if ALT then screen.text("rate") else screen.text("fb") end
  screen.stroke()

  -- time/frothAmount knob
  screen.level(params:get("viewBrightness") - 2)
  screen.move(0,0)
  screen.circle(view.width - (view.width/4), view.height - view.knob, view.knob)
  screen.fill()

  screen.level(0)
  screen.move(view.width - (view.width/4), view.height - view.knob + view.spacer)
  if ALT then 
    screen.text_center(params:get("FrothAmount"))
    screen.stroke()
  else
    screen.text_center(params:get(param_ids[CURRENT][2]))
    screen.stroke()
  end

  screen.level(params:get("viewBrightness") - 2)
  screen.move((view.width - (view.width/4) + view.knob + view.spacer), view.height - view.knob + view.spacer)
  local string = ""
  if ALT then string = "dpth" else string = "sec" end
  screen.text(string)
  screen.stroke()

  -- vol/ocean knob
  screen.level(params:get("viewBrightness") - 2)
  screen.move(0,0)
  screen.circle(view.width/2, view.height - view.knob, view.knob)
  screen.fill()

  screen.level(0)
  screen.move(view.width/2, view.height - view.knob + view.spacer)
  if ALT then
    screen.text_center(params:get("OceanAmp"))
    screen.stroke()
  else
    screen.text_center(params:get(param_ids[CURRENT][3]))
    screen.stroke()
  end

  screen.level(params:get("viewBrightness") - 2)
  screen.move((view.width/2) - view.knob - 2, view.height - view.knob + view.spacer)
  if ALT then
    screen.text_right("ocn")
    screen.stroke()
  else
    screen.text_right("out")
    screen.stroke()
  end

  -- forward/backwards
  local r = 9

  screen.level(params:get("viewBrightness") - 2)
  if ALT then
    screen.circle(8,view.height-10/2,10/2)
  else
    screen.rect(3,view.height-r,r,r)
  end
  screen.fill()

  screen.level(0)
  screen.move(4, view.height - 2.5)
  screen.text("<-")
  screen.stroke()

  screen.level(params:get("viewBrightness") - 2)
  if ALT then
    screen.circle(22,view.height-10/2,10/2)
  else
    screen.rect(18,view.height-r,r,r)
  end
  screen.fill()

  screen.level(0)
  screen.move(17 + r/4, view.height - 2.5)
  screen.text("->")
  screen.stroke()

  screen.update()
end


function setup_gui_metro()
  gui = metro.init()
  gui.time = 1/15
  gui.event= function() 
    view.increment_frame()
    redraw() 
  end
  gui:start()  
end

function setup_ocean_metro()
  timing = metro.init()
  timing.time = 1
  timing.event = function() 
    wave.increment()
    wave.randomize(params:get("OceanFloor"));
    engine.lfo(wave.spd)
  end
  timing:start()
end


function init()
  do
    local toggle = true

    function vibrato()
      local amt = params:get("FrothAmount")
      local rate = params:get("Direction")

      if toggle then
        for n = 1,#ACTIVE do 
          softcut.rate(n,rate - amt)
        end
        toggle = false
      else
        for n = 1,#ACTIVE do 
          softcut.rate(n,rate + amt)
        end
        toggle = true
      end
    end
  end

  params:add_separator("Raft")
  params:add{type="number", id="viewBrightness", name="Brightness", min=3, max=15, default=15}

  delay.setup_globals(ACTIVE, vibrato) 
  for n=1,3 do
    delay.setup_line(n)
  end

  ACTIVE = { 1 }
  delay.reset()

  setup_gui_metro() 
  setup_ocean_metro()

  engine.amp(0.0)
  audio.level_adc_cut(1)
  audio.level_eng_cut(.7)
end
