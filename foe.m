classdef foe < handle
    
properties(Constant)
    vy_max = 4;
    accel  = 1;
    dying_len = 2;
    
    missile_min_spd = 8;
    missile_max_spd = 12;
    
    BOMB = 1
    MISL = 2
    
    size = 3;
    
    bombY = [0 1 2 3 4 4 3 2 1 0]'*foe.size/2;
    bombX = [0 1 1 0.2 1 -1 -0.2 -1 -1 0]'*foe.size/2;
    
    mslX = [0 1 2 1 -2 -4 -4 -2 0];
    mslY = [-1 -1 0 1 1 2 -2 -1 -1];    
    
    marker = {'rx', 'kv'}        
end

properties
    x, y, vx, vy    
        
    kind
    alive = true
    dying = 0
    
    spriteX
    spriteY
        
    game        
end
    
methods(Access=public)
    
    function this = foe(game, kind)        
        this.game = game;
        
        if nargin < 2
            kind = mod(tic, 2) + 1;
        end
        
        this.kind = kind;
        
        switch kind 
            case this.BOMB
                fprintf('Incoming bomb!\n')
                this.x = rand*game.W-game.W/2;
                this.y = game.H;
                this.vy = 0;
                this.vx = 0;
                this.spriteX = this.bombX;
                this.spriteY = this.bombY;
                
            case this.MISL
                fprintf('Incoming missile!\n')
                this.x = round(rand)*game.W - game.W/2;
                this.y = rand*game.H/2 + game.H/2;                
                
                % Go to the opposite side
                tx  = rand*game.W/2*(-sign(this.x));
                h   = sqrt((tx - this.x)^2 + this.y^2);
                spd = this.missile_min_spd + rand*(this.missile_max_spd - this.missile_min_spd);
                cs = (tx - this.x)/h;
                sn = this.y/h;
                this.vx = cs * spd;
                this.vy = sn * spd;
                
                rot = [cs -sn; sn cs];                
                sprite = [this.mslX' this.mslY']*rot;
                
                this.spriteX = sprite(:,1)';
                this.spriteY = sprite(:,2)';
        end                
        
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
    
    function [alive, hit, destroyed] = update(this)
        this.x  = this.x + this.vx*this.game.T;        
        if abs(this.x) > this.game.W/2
            this.alive = false;
        end        
        
        if this.kind == this.BOMB
            this.vy = this.vy + this.accel*this.game.T;
        end
        
        this.y = this.y - this.vy*this.game.T;  
        if this.y < 0 
            this.y = 0;
        end
        
        hit    = this.alive && (this.y <= 0);
        
        if this.alive && this.game.firing>0 && abs(this.x - this.game.x)<this.size/2
            fprintf('Hit\n');
            destroyed = true;
            this.alive = false;
            this.dying = this.dying_len;
            this.vy = this.vy / 2;
            % fix Y offset
            this.y = this.y + this.size*1/2;
        else
            destroyed = false;
        end
        
        if this.dying > 0 
            this.dying = this.dying - this.game.T;
        end
        
        alive = this.alive || this.dying>0;
    end
    
end
    
end