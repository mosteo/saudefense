classdef gun < i_body & i_drawable
    
properties(Constant)
    txt_armed={'disarmed', 'armed', 'cooling down', 'firing'}
    mark_armed={'o','^', 'v', '^'}
    
    size = 12;
end
    
properties
    loop            % gun dynamics (with controller)
    
    firing   = 0;
    cooldown = 0;
    armed    = true;     
    
    vx       = 0     % gun speed
    vx_1     = 0     % previoux speed
    ax       = 0     % gun acceleration
end
    
methods(Static)
    function this = gun(loop)
        % set dynamics        
        this.loop = loop;        
        
        this.x = 0;
        this.y = 0;
    end
end
    
methods
   
    function draw(this, axis, scale)
        % Gun status
        if this.firing > 0
            gs = 4;
        elseif this.cooldown > 0
            gs = 3;
        elseif this.armed
            gs = 2;
        else
            gs = 1;
        end
        
        plot(axis, ...
            this.x*scale, 0, this.mark_armed{gs}, 'MarkerSize', this.size)
        
        if (this.firing > 0)
            rayX = [this.x this.x]*scale;
            rayY = [0 saudefense.H]*scale;
            plot(this.fig, rayX', rayY', 'r-');
        end        
    end
    
    function done = update(this, period)
        done = false;
    end
    
end

end