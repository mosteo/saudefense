classdef foe < handle
    
properties(Constant)
    vy_max = 4;
    accel  = 1;
    dying_len = 2;
    
    size = 3;
    spriteY = [0 1 2 3 4 4 3 2 1 0]'*foe.size/2;
    spriteX = [0 1 1 0.2 1 -1 -0.2 -1 -1 0]'*foe.size/2;
    
    marker = {'rx', 'kv'}
end

properties
    x, y, vx, vy
        
    alive = true
    dying = 0
        
    game        
end
    
methods(Access=public)
    
    function this = foe(game)
        fprintf('Incoming!\n')
        this.game = game;
        this.x = rand*game.W-game.W/2;
        this.y = game.H;
        this.vy = 0;
        this.vx = 0;
    end
    
    function draw(this)     
        if this.alive
            plot((this.spriteX + this.x)*this.game.scale, ...
                 (this.spriteY + this.y)*this.game.scale, ...
                  'k');
        else
            plot(this.x*this.game.scale, ...
                 this.y*this.game.scale, ...
                  'xr');
        end
    end
    
    function [alive, hit] = update(this)
        this.x  = this.x + this.vx;        
        if abs(this.x) > this.game.W/2
            this.alive = false;
        end
        
        this.vy = this.vy + this.accel*this.game.T;
        this.y = this.y - this.vy*this.game.T;  
        if this.y < 0 
            this.y = 0;
        end
        
        hit    = this.alive && (this.y <= 0);
        
        if this.alive && this.game.firing>0 && abs(this.x - this.game.x)<this.size/2
            fprintf('Hit\n');
            this.alive = false;
            this.dying = this.dying_len;
            this.vy = this.vy / 2;
            % fix Y offset
            this.y = this.y + this.size*1/2;
        end
        
        if this.dying > 0 
            this.dying = this.dying - this.game.T;
        end
        
        alive = this.alive || this.dying>0;
    end
    
end
    
end