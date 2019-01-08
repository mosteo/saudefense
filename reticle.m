%   Authors: Alejandro R. Mosteo, Danilo Tardioli, Eduardo Montijano
%   Copyright 2018-9999 Monmostar
%   Licensed under GPLv3 https://www.gnu.org/licenses/gpl-3.0.en.html
%
classdef reticle < handle
    
properties(Constant)
    X = [0 0 -1 -2 -1 0 0 0 1 2 1 0]*3;
    Y = [2 1 0 0 0 -1 -2 -1 0 0 0 1]*3;
end

properties
    id    = 0  % last target id to detect changes    
    flash = 0  % counter to flash the reticle on target change
    h          % drawer()
end
    
methods    
    
    function this = reticle()
        this.h = drawer();
    end
    
    function draw(this, fig, id, x, y, scale, color)
        if id ~= this.id
            this.flash = 5;
            this.id    = id;
        end
        
        should_draw = mod(this.flash, 2) == 0 && id ~=0;
        this.flash = max(0, this.flash - 1);
            
        if should_draw          
            this.h.plot(fig, (x+reticle.X)'*scale, (y+reticle.Y)'*scale, ...
                'Color', color, 'LineWidth', 1);
            this.h.show;
            this.h.bring_to_front;
        else
            this.h.show(false);
        end
    end    
end
    
end