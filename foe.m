classdef foe < i_body & i_drawable & i_killable
% TODO: split bomb & missile into different classes    
    
properties(Constant)
    vy_max = 4;
    default_accel  = 9.8;
    dying_len = 2;
    
    missile_min_spd = 12;
    missile_max_spd = 18;
    
    BOMB = 1
    MISL = 2
    
    size = 3;
    
    bombY = ([0 1 2 3 4 4 3 2 1 0]' - 1.5)*foe.size/2;
    bombX = [0 1 1 0.2 1 -1 -0.2 -1 -1 0]'*foe.size/2;
    
    mslX = [0 1 2 1 -2 -4 -4 -2 0];
    mslY = [-1 -1 0 1 1 2 -2 -1 -1];    
    
    marker = {'rx', 'kv'}        
end

properties
    % x, y      % Those are inherited from i_body
    vx, vy        
    
    ay
        
    kind
    alive = true
    dying = 0
    
    spriteX
    spriteY
    
    T
    
    h_foe;  % Drawers
    h_fill;
end
    
methods(Access=public)
    
    function this = foe(period, kind, difficulty)                
        this.T = period;
        
        if nargin < 2
            kind = mod(tic, 2) + 1;
        end
        if nargin < 3
            difficulty = 0.5;
        end
        
        this.ay = this.default_accel + difficulty*3;
        
        this.kind = kind;
        
        this.id = rand;
        
        this.h_foe  = drawer();
        this.h_fill = drawer();
        
        switch kind 
            case this.BOMB
                fprintf('Incoming bomb!\n')
                this.x = (rand*saudefense.W-saudefense.W/2)*(1 - saudefense.OS);
                this.y = saudefense.H + 2.5;
                this.vy = -1;
                this.vx = 0;
                this.spriteX = this.bombX;
                this.spriteY = this.bombY;
                
            case this.MISL
                fprintf('Incoming missile!\n')
                this.x = round(rand)*saudefense.W - saudefense.W/2;
                this.y = rand*saudefense.H/2*(1-difficulty*0.9) + saudefense.H/2;                
                
                % Go to the opposite side
                tx  = rand*saudefense.W/2*(-sign(this.x));
                h   = sqrt((tx - this.x)^2 + this.y^2);
                spd = this.missile_min_spd + rand*(this.missile_max_spd - this.missile_min_spd);
                cs = (tx - this.x)/h;                
                sn = this.y/h;                
                this.vx = cs * spd;
                this.vy = sn * spd;
                
                % Drawing override
                cs = 0;
                sn = 1;
                
                rot = [cs -sn; sn cs];                
                sprite = [this.mslX' this.mslY']*rot;
                
                this.spriteX = sprite(:,1)';
                this.spriteY = sprite(:,2)';
        end                
        
    end
    
    function hit = check_hit(this, fx, ~, ~)
        % Firing angle not used right now (vertical fire assumed)        
        hit = this.alive && abs(this.x - fx)<=this.size/2;
    end
    
    function die(this)
        fprintf('Destroyed!\n');
        this.alive = false;
        this.dying = this.dying_len;
        this.vy = this.vy / 2;
        this.vx = this.vx / 2;
        % fix Y offset
        this.y = this.y + this.size*1/2;
    end
    
    function draw(this, fig, scale)     
        if this.alive     
            this.h_fill.fill(fig, (this.spriteX + this.x)*scale, ...
                  (this.spriteY + this.y)*scale, ...
                  'w');
                
                this.h_foe.plot(fig, ...
                     (this.spriteX + this.x)*scale, ...
                     (this.spriteY + this.y)*scale, ...
                      'Color', [0 0 0]);            
            this.h_fill.show;
        else
            this.h_fill.show(false);
            this.h_foe.plot(fig, this.x*scale, this.y*scale, ...
                'Marker', 'x', 'Color', [1 0 0]);
        end
    end
    
    function points = score(this)
        points = this.kind;
    end
    
    function done = update(this, ~)
        this.x  = this.x + this.vx*this.T;        
        if abs(this.x) > saudefense.W/2
            this.alive = false;
        end        
        
        if this.kind == this.BOMB || this.dying > 0
            this.vy = this.vy + this.ay*this.T;
        end
        
        this.y = this.y - this.vy*this.T;  
        if this.y < 0 
            this.y = 0;
        end        
        
        if this.dying > 0 
            this.dying = this.dying - this.T;
        end
        
        done = ~this.alive && this.dying<=0;
        done = done || this.y == 0;
    end
    
end
    
end