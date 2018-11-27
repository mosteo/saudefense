classdef reticle < handle
    
properties(Constant)
    X = [0 0 -1 -2 -1 0 0 0 1 2 1 0]*3;
    Y = [2 1 0 0 0 -1 -2 -1 0 0 0 1]*3;
end

properties
    id    = 0  % last target id to detect changes    
    flash = 0  % counter to flash the reticle on target change
end
    
methods
    
    function draw(this, fig, id, x, y, scale, color)
        if id ~= this.id
            this.flash = 5;
            this.id    = id;
        end
        
        draw       = mod(this.flash, 2) == 0;
        this.flash = max(0, this.flash - 1);
            
        if draw
            plot(fig, (x+reticle.X)'*scale, (y+reticle.Y)'*scale, ...
                color, 'LineWidth', 1);
        end
    end
    
end
    
end