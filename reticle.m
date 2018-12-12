classdef reticle < handle
    
properties(Constant)
    X = [0 0 -1 -2 -1 0 0 0 1 2 1 0]*3;
    Y = [2 1 0 0 0 -1 -2 -1 0 0 0 1]*3;
end

properties
    id    = 0  % last target id to detect changes    
    flash = 0  % counter to flash the reticle on target change
    h_reticle=[];
end
    
methods
    
    function this=reticle()
            this.h_reticle=[];
    end
    
    function draw(this, fig, id, x, y, scale, color)
        if id ~= this.id
            this.flash = 5;
            this.id    = id;
        end
        
        should_draw = mod(this.flash, 2) == 0 && id ~=0;
        this.flash = max(0, this.flash - 1);
            
        if should_draw            
            if isempty(this.h_reticle)
                this.h_reticle = plot(fig, (x+reticle.X)'*scale, (y+reticle.Y)'*scale, ...
                    color, 'LineWidth', 1);
            else
                set(this.h_reticle,'Visible','on')
                this.h_reticle.XData= (x+reticle.X)'*scale;
                this.h_reticle.YData= (y+reticle.Y)'*scale;
            end
        else
            if ~isempty(this.h_reticle)
                set(this.h_reticle,'Visible','off')
            end
        end
    end    
end
    
end