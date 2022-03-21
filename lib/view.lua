local view = {} 

view.width = 128
view.height = 64
view.frame = 1 
view.knob = 11 
view.brightness = 15
view.spacer = 1.5

function view.increment_frame() 
  view.frame = (view.frame + 1) % view.width 
end

function view.waves(num_waves, wave_count)
    local f = view.frame
    local half = view.height/2
    
    screen.level(view.brightness - 1) 
    for j = 1,view.width do 
        screen.pixel(j,half - math.random(-1,1)) 
    end
    screen.fill()
    
    screen.level(view.brightness)
    for i = 1,num_waves do
        local n = i * 10
        
        if wave_count == 1 then
            screen.pixel(f - n, half - 3 + i) 
        elseif wave_count == 2 then 
            screen.pixel(f - n, half - 4 + i) 
            screen.pixel(f + 1 - n, half - 3 + i)
            screen.pixel(f - 1 - n, half - 3 + i)
        elseif wave_count == 3 then
            screen.pixel(f - n, half - 5 + i) 
            screen.pixel(f + 1 - n, half - 4 + i)
            screen.pixel(f - 1 - n, half - 4 + i)
            screen.pixel(f + 2 - n, half - 3 + i)
            screen.pixel(f - 2 - n, half - 3 + i)
        elseif wave_count == 4 then
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

return view
