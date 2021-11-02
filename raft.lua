-- raft; version 0.8
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
-- drone = fb: 100; rec: 0
--
-- while on wave 3/3 ->
-- K3 = clear buffers
-- & reset feedback
-- & re-enable record
--
-- ENCs control individual wave params
-- ALT + ENCs control global ocean params

engine.name = 'Ocean'

local viewport = { width = 128, height = 64, frame = 1 }
local wave = { counter = 1, spd = 8 }
local knob = 11
local spacer = 1.5
local vib = { b = true }
local p_ids = {{"waveOneFeedback", "waveOneTime", "waveOneLevel"},
               {"waveTwoFeedback", "waveTwoTime", "waveTwoLevel"},
               {"waveThreeFeedback", "waveThreeTime", "waveThreeLevel"}}

CURRENT = 1
ACTIVE = {}
MAX_DELAYS = 3
ALT = false

function key(id, z) 
    if z == 1 then
        if id == 1 then
            ALT = true
        elseif id == 2 and ALT then
            params:set(p_ids[CURRENT][1], 1.0)
            softcut.rec_level(CURRENT,0)
            params:set("Direction", -1.0)
        elseif id == 2 then
            CURRENT = CURRENT - 1
            if CURRENT < 1 then CURRENT = 1 end
        elseif id == 3 and ALT then
            params:set(p_ids[CURRENT][1], 1.0)
            softcut.rec_level(CURRENT,0)
            params:set("Direction", 1.0)
        elseif id == 3 then
            local RESET = false
            CURRENT = CURRENT + 1
            
            if CURRENT > MAX_DELAYS then 
                CURRENT = MAX_DELAYS
                RESET = true
            end
            
            if #ACTIVE < CURRENT then 
                setup_new_delay_line(CURRENT)
                params:delta(p_ids[CURRENT][2],CURRENT)
            end
            
            if RESET then
                CURRENT = 1 
                softcut.buffer_clear()
                
                for n=1,3 do
                    params:set(p_ids[n][1], 0.5)
                    softcut.rec_level(n, 1)
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
        params:delta(p_ids[CURRENT][1],d)
    elseif ALT and id == 2 then
        params:delta("OceanAmp",d)
    elseif id == 2 then
        params:delta(p_ids[CURRENT][3],d) 
    elseif ALT and id == 3 then
        params:delta("FrothAmount",d)
    elseif id == 3 then
        params:delta(p_ids[CURRENT][2],d)
    end
end

function setup_delay_params(n)
    local string = "Wave"..n
    params:add_separator(string)
    
    local id_FB = p_ids[n][1]
    local cs_FB = controlspec.new(0.0,1.0,'lin',0,0.5,'') 
    params:add{type="control", id=id_FB, controlspec=cs_FB,
        action=function(x) softcut.pre_level(n,x) end}

    local id_TIME = p_ids[n][2]
    local cs_TIME = controlspec.new(0.1,30,'lin',0.01,0.55,'s')
    params:add{type="control", id=id_TIME, controlspec=cs_TIME,
        action=function(x) softcut.loop_end(n,(get_loop_start(n) + x)) end}

   local id_LVL = p_ids[n][3]
   local cs_LVL = controlspec.new(0.0,1.0,'lin',0,1.0,'')
   params:add{type="control", id=id_LVL, controlspec=cs_LVL,
       action=function(x) softcut.level(n,x) end}
end

function setup_softcut_voice(n)
    softcut.enable(n,1)
    softcut.buffer(n,1)
    
    softcut.level(n,params:get(p_ids[n][3]))
    softcut.rate(n,params:get("Direction"))
    softcut.rate_slew_time(n,(params:get("FrothAmount")*2))
    
    softcut.loop(n,1)
    softcut.loop_start(n,get_loop_start(n))
    softcut.loop_end(n,get_loop_start(n) + params:get(p_ids[n][3]))
    softcut.position(n,1)
   
    softcut.rec_level(n,1)
    softcut.pre_level(n,params:get(p_ids[n][1]))
    
    softcut.pre_filter_dry(n, 0)
    softcut.pre_filter_lp(n, 1.0)
    softcut.pre_filter_fc(n, 8000)
   
    softcut.level_input_cut(1,n,0.7)
    softcut.level_input_cut(2,n,0.7)
    
    softcut.play(n,1)
    softcut.rec(n,1)
end

function vib_logic()
    local amt = params:get("FrothAmount")
    local rate = params:get("Direction")
    
    if vib.b then
        for n = 1,#ACTIVE do 
            softcut.rate(n,rate - amt)
        end
        vib.b = false
    else
        for n = 1,#ACTIVE do 
            softcut.rate(n,rate + amt)
        end
        vib.b = true
    end
end

function get_loop_start(voice)
    local start = 0
    if voice == 1 then start = voice else start = voice * 60 end
    return start
end

function setup_new_delay_line(voice)
    table.insert(ACTIVE,voice)
    setup_delay_params(voice)
    setup_softcut_voice(voice)
end

function waves(f)
    local half = viewport.height/2
    
    screen.level(3) 
    for j = 1,viewport.width do 
        screen.pixel(j,half - math.random(-1,1)) 
    end
    screen.fill()
    
    screen.level(4)
    for i = 1,#ACTIVE do
        local n = i * 10
        
        if wave.counter == 1 then
            screen.pixel(f - n, half - 3 + i) 
        elseif wave.h_count == 2 then 
            screen.pixel(f - n, half - 4 + i) 
            screen.pixel(f + 1 - n, half - 3 + i)
            screen.pixel(f - 1 - n, half - 3 + i)
        elseif wave.counter == 3 then
            screen.pixel(f - n, half - 5 + i) 
            screen.pixel(f + 1 - n, half - 4 + i)
            screen.pixel(f - 1 - n, half - 4 + i)
            screen.pixel(f + 2 - n, half - 3 + i)
            screen.pixel(f - 2 - n, half - 3 + i)
        elseif wave.counter == 4 then
            screen.pixel(f - n, half - 6 + i) 
            screen.pixel(f + 1 - n, half - 5 + i)
            screen.pixel(f - 1 - n, half - 5 + i)
            screen.pixel(f + 2 - n, half - 4 + i)
            screen.pixel(f - 2 - n, half - 4 + i)
            screen.pixel(f + 3 - n, half - 3 + i)
            screen.pixel(f - 3 - n, half - 3 + i)
        end
    end

    screen.fill()
end

function redraw()
    screen.clear()
    
    waves(viewport.frame)
    
    -- text    
    screen.move(4,viewport.height - 10 - spacer)
    screen.level(2)
    local string = ""
    if ALT then string = "drone" else string = "wave" end
    screen.text(string)
    screen.stroke()
    
    screen.move(10,10)
    screen.level(2)
    screen.text("wave "..CURRENT.."/"..MAX_DELAYS)
    
    -- fb/frothRate knob
    screen.level(2)
    screen.move(0,0)
    screen.circle(viewport.width - (viewport.width/4), knob, knob)
    screen.fill()

    screen.level(0)
    screen.move(viewport.width - (viewport.width/4), knob + spacer)
    if ALT then
        screen.text_center(params:get("FrothRate"))
        screen.stroke()
    else
        screen.text_center(params:get(p_ids[CURRENT][1]))
        screen.stroke()
    end

    screen.level(2)
    screen.move((viewport.width - (viewport.width/4) + knob + spacer), knob + spacer)
    if ALT then screen.text("frth") else screen.text("fb") end
    screen.stroke()
    
    -- time/frothAmount knob
    screen.level(2)
    screen.move(0,0)
    screen.circle(viewport.width - (viewport.width/4), viewport.height - knob, knob)
    screen.fill()
    
    screen.level(0)
    screen.move(viewport.width - (viewport.width/4), viewport.height - knob + spacer)
    if ALT then 
        screen.text_center(params:get("FrothAmount"))
        screen.stroke()
    else
        screen.text_center(params:get(p_ids[CURRENT][2]))
        screen.stroke()
    end
    
    screen.level(2)
    screen.move((viewport.width - (viewport.width/4) + knob + spacer), viewport.height - knob + spacer)
    local string = ""
    if ALT then string = "frth" else string = "sec" end
    screen.text(string)
    screen.stroke()
    
    -- vol/ocean knob
    screen.level(2)
    screen.move(0,0)
    screen.circle(viewport.width/2, viewport.height - knob, knob)
    screen.fill()

    screen.level(0)
    screen.move(viewport.width/2, viewport.height - knob + spacer)
    if ALT then
        screen.text_center(params:get("OceanAmp"))
        screen.stroke()
    else
        screen.text_center(params:get(p_ids[CURRENT][3]))
        screen.stroke()
    end

    screen.level(2)
    screen.move((viewport.width/2) - knob - 2, viewport.height - knob + spacer)
    if ALT then
        screen.text_right("ocn")
        screen.stroke()
    else
        screen.text_right("out")
        screen.stroke()
    end
    
    -- forward/backwards
    local r = 9
    
    screen.level(2)
    if ALT then
        screen.circle(8,viewport.height-10/2,10/2)
    else
        screen.rect(3,viewport.height-r,r,r)
    end
    screen.fill()
    
    screen.level(0)
    screen.move(4, viewport.height - 2.5)
    screen.text("<-")
    screen.stroke()

    screen.level(2)
    if ALT then
        screen.circle(22,viewport.height-10/2,10/2)
    else
        screen.rect(18,viewport.height-r,r,r)
    end
    screen.fill()
    
    screen.level(0)
    screen.move(17 + r/4, viewport.height - 2.5)
    screen.text("->")
    screen.stroke()
    
    screen.update()
end

function setup_delay_globals()
    froth = metro.init()
    
    params:add_separator("Global")
    params:add{type="number", id="Direction", min=-1.0, max=1.0, default=1.0}
    local cs_FRATE = controlspec.new(1,400,'lin',1,400,'')
    params:add{type="control", id="FrothRate", controlspec=cs_FRATE,
        action=function(x) froth.time = 1/x end}
    local cs_FAMT = controlspec.new(0,0.4,'lin',0,0.08,'')
    params:add{type="control", id="FrothAmount", controlspec=cs_FAMT,
        action=function(x)
            for n=1,#ACTIVE do softcut.rate_slew_time(n,x*2) end end}
    local cs_OA = controlspec.new(0,0.2,'lin',0,0.05,'')
    params:add{type="control", id="OceanAmp", controlspec=cs_OA,
        action=function(x) engine.amp(x) end}
    
    froth.time = 1/params:get("FrothRate")
    froth.event= function() vib_logic() end
    froth:start()
end

function setup_gui_metro()
    gui = metro.init()
    gui.time = 1/15
    gui.event= function() 
        viewport.frame = (viewport.frame + 1) % viewport.width
        redraw() 
    end
    gui:start()  
end

function setup_ocean_metro()
    timing = metro.init()
    timing.time = 1
    timing.event = function() 
        wave.counter = (wave.counter + 1) % 5
    	wave.spd = math.random(6,8)
    	engine.lfo(wave.spd)
    end
    timing:start()
end

function init()
    softcut.buffer_clear()
    
    setup_delay_globals() 
    setup_new_delay_line(CURRENT)
    setup_gui_metro() 
    setup_ocean_metro()
   
    engine.amp(0.07)
    audio.level_adc_cut(1)
    audio.level_eng_cut(.7)
end
