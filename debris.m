%   Authors: Alejandro R. Mosteo, Danilo Tardioli, Eduardo Montijano
%   Copyright 2018-9999 Monmostar
%   Licensed under GPLv3 https://www.gnu.org/licenses/gpl-3.0.en.html
%
classdef debris < i_body & i_drawable

properties
    vx, vy
    
    vx_max = 20
    vy_max = 40
    ay     = 25
    
    h % Drawer
end    

methods(Static)
    function list = create(n, x, y)
        % Create a bunch of debris at a point, returned as horizontal list
        list = cell(1, n);
        for i=1:n
            list{i} = debris(x, y);
        end
    end
end

methods
    
    function this = debris(x, y)
        this.h = drawer();
        this.x = x;
        this.y = y;
        
        this.vx = (rand - 0.5)*this.vx_max;
        this.vy = rand*this.vy_max;
    end
   
    function draw(this, axis, scale)
        this.h.plot(axis, this.x*scale, this.y*scale, 'Color', [0 0 0], 'Marker', '.');
    end
    
    function done = update(this, period)
        this.x = this.x + this.vx*period;
        if abs(this.x) > saudefense.W/2
            this.vx = -this.vx;
        end
        
        this.y = this.y + this.vy*period;
        this.vy = this.vy - this.ay*period;
        
        done = this.y < 0 || abs(this.x) > saudefense.W/1.5;
    end    
    
end    
    
end