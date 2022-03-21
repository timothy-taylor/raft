local param_ids = include 'lib/param_ids'

local delay = {}

function delay.setup_globals(active, vibrato)
  froth = metro.init()
  froth.event = function() vibrato() end

  params:add_separator("Raft")
  local cs_DIRRATE = controlspec.new(-2,2,'lin',0.1,1,'')
  params:add{type="control", id="Direction", name="Global Buffer Rate", controlspec=cs_DIRRATE, action=function(x) 
    for n=1,3 do
      softcut.rate(n,x)
    end
  end}

  params:add_group("Ocean & Froth",4)
  local cs_FRATE = controlspec.new(1,400,'exp',1,400,'')
  params:add{type="control", id="FrothRate", controlspec=cs_FRATE,
  action=function(x) froth.time = 1/x end}
  local cs_FAMT = controlspec.new(0,1.0,'lin',0,0,'')
  params:add{type="control", id="FrothAmount", controlspec=cs_FAMT,
  action=function(x)
    for n=1,#active do softcut.rate_slew_time(n,x*2) end 
  end
}
local cs_OA = controlspec.new(0,0.2,'lin',0,0,'')
params:add{type="control", id="OceanAmp", controlspec=cs_OA,
action=function(x) engine.amp(x) end}
params:add{type="number", id="OceanFloor", min=8.0, max=64.0, default=32.0}

froth.time = 1/params:get("FrothRate")
froth:start()
end

function delay.setup_line(voice)
  delay.setup_params(voice)
  delay.setup_softcut_voice(voice)
end

function delay.reset()
  softcut.buffer_clear()
  softcut.rec_level(1, 1)
  softcut.rec_level(2, 0)
  softcut.rec_level(3, 0)
end

function delay.setup_params(n)
  params:add_group("Wave"..n,6)

  local id_FB = param_ids[n][1]
  local cs_FB = controlspec.new(0.0,1.0,'lin',0,0.5,'') 
  params:add{type="control", id=id_FB, controlspec=cs_FB,
  action=function(x) softcut.pre_level(n,x) end}

  local id_TIME = param_ids[n][2]
  local cs_TIME = controlspec.new(0.1,10,'lin',0.01,0.55 + (2 * (n - 1)),'s')
  params:add{type="control", id=id_TIME, controlspec=cs_TIME,
  action=function(x) softcut.loop_end(n,(delay.get_loop_start(n) + x)) end}

  local id_LVL = param_ids[n][3]
  local cs_LVL = controlspec.new(0.0,1.0,'lin',0,0.5,'')
  params:add{type="control", id=id_LVL, controlspec=cs_LVL,
  action=function(x) softcut.level(n,x) end}

  local id_CO = param_ids[n][5]
  params:add{type="control", id=id_CO, controlspec=controlspec.FREQ,
  action=function(x) softcut.pre_filter_fc(n, x) end}

  local id_Q = param_ids[n][6]
  params:add{type="control", id=id_Q, controlspec=controlspec.RQ,
  action=function(x) softcut.pre_filter_rq(n,x) end}

  local id_PAN = param_ids[n][4]
  params:add{type="control", id=id_PAN, controlspec=controlspec.PAN,
  action=function(x) softcut.pan(n,x) end}
end

function delay.setup_softcut_voice(n)
  softcut.enable(n,1)
  softcut.buffer(n,1)

  softcut.level(n,params:get(param_ids[n][3]))
  softcut.rate(n,params:get("Direction"))
  softcut.rate_slew_time(n,(params:get("FrothAmount")*2))

  softcut.loop(n,1)
  softcut.loop_start(n,delay.get_loop_start(n))
  softcut.loop_end(n,delay.get_loop_start(n) + params:get(param_ids[n][2]))
  softcut.position(n,1)

  softcut.rec_level(n,1)
  softcut.pre_level(n,params:get(param_ids[n][1]))

  softcut.pre_filter_dry(n, 0)
  softcut.pre_filter_lp(n, 1.0)
  params:set(param_ids[n][5],8000)

  softcut.level_input_cut(1,n,0.7)
  softcut.level_input_cut(2,n,0.7)

  if n==2 then params:set(param_ids[n][4], -1) end
  if n==3 then params:set(param_ids[n][4], 1) end

  softcut.play(n,1)
  softcut.rec(n,1)
end


function delay.get_loop_start(voice)
  local start = 0
  if voice == 1 then start = voice else start = voice * 60 end
  return start
end

return delay
