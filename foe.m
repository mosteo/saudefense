classdef foe < handle
    
properties
    x, y, vx, vy
    
    vy_max = 4;
    accel  = 1;
    
    marker = {'rx', 'kv'}
    alive = true
    dying = 0
    dying_len = 2;
    
    hitbox = 3;

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
        plot(this.x*this.game.scale, this.y*this.game.scale, this.marker{this.alive+1});
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
        
        if this.alive && this.game.firing>0 && abs(this.x - this.game.x)<this.hitbox
            fprintf('Hit\n');
            this.alive = false;
            this.dying = this.dying_len;
            this.vy = this.vy / 2;
        end
        
        if this.dying > 0 
            this.dying = this.dying - this.game.T;
        end
        
        alive = this.alive || this.dying>0;
    end
    
end
    
end