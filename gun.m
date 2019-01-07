classdef gun < i_body & i_drawable & i_loop & i_killer
% We could directly inherit from loop_single to save a few methods
% This way we make the gun reusable for different loop implementations.
    
properties(Constant)
    txt_armed={'disarmed', 'armed', 'cooling down', 'firing', 'destroyed'}
    mark_armed={'o','^', 'v', '^', 'x'}
    
    DISARMED=1
    ARMED=2
    COOLING=3
    FIRING=4
    DESTROYED=5
    
    size = 12;
    
    v_arm   = 10  % max speed allowing fire
    a_arm   =  2  % max accel allowing fire
    a_break = 5000 % max accel allowed
    
    firing_len   = 0.5  % time a firing lasts   
    cooldown_len = 1    % time until next shot ready       
    wave_len     = 1    % time exploding
    
    MODE_COOL = 1   % Cooldown after firing
    MODE_TS   = 2   % Cooldown after targeting (response time)
    mode      = gun.MODE_TS
end
    
properties
    loop            % gun dynamics (with controller)
    
    firing   = 0;
    cooldown = 0;
    exploding = 0;
    armed    = true;         
    autofire = true;
    
    ts = Inf; % Response time
    
    G, H
    
    state = 2;   % (disarmed, armed, cooling, firing) (positive)
    
    target   = []    % An instance of i_killable
    
    h_gun   % Drawers 
    h_ray
    h_wave
    
    x_wave
    y_wave % For explosion
end
    
methods
    
    function this = gun(loop)
        % set dynamics        
        this.G    = loop.G;
        this.H    = loop.H;
        this.set_loop(loop);                
        
        this.x = 0;
        this.y = 0;
        
        this.h_gun = drawer();
        this.h_ray = drawer();
        this.h_wave = drawer();
        
        a=0:pi/16:pi;
        this.x_wave=cos(a)';
        this.y_wave=sin(a)';
    end
    
    function die(this)
        % When hit, do a rising waveshock and suspend normal actions
        this.exploding = this.wave_len;
        this.firing    = 0;
        this.cooldown  = 0;
    end
   
    function draw(this, axis, scale)
        % Gun status
        if this.exploding > 0
            gs = this.DESTROYED;
        elseif this.firing > 0
            gs = this.FIRING;
        elseif this.cooldown > 0
            gs = this.COOLING;
        elseif this.armed
            gs = this.ARMED;
        else
            gs = this.DISARMED;
        end
        
        this.state = gs;
        
        if this.state == this.DESTROYED
            % Draw shockwave
            r = this.radius();
            this.h_wave.plot(axis, ...
                (this.x + this.x_wave.*r)*scale, ...
                (this.y + this.y_wave.*r)*scale, ...
                'Color', [0 1 0]);
            this.h_wave.show();
        else
            this.h_wave.show(false);
        end        
            
        % Draw gun
        this.h_gun.plot(axis, ...
            this.x*scale, 0, 'Marker', this.mark_armed{gs}, ...
            'MarkerSize', this.size, 'Color', [0 0 0.7]);
        this.h_gun.show;
        
        if (this.firing > 0)
            rayX = [this.x this.x]*scale;
            rayY = [0 saudefense.H]*scale;
                        
            this.h_ray.plot(axis, rayX', rayY', 'Color', [1 0 0]);
            this.h_ray.show;            
        else
            this.h_ray.show(false);
        end        
    end
    
    function fire(this)
        if this.exploding > 0
            return
        end
        
        % Cooldown
        if this.cooldown > 0
            this.cooldown = this.cooldown - this.loop.period;
            if this.cooldown < 0 
                this.cooldown = 0;
            end
        end
        
        % Firing
        if this.firing > 0
            this.firing = this.firing - this.loop.period;
            
            if abs(this.get_a()) > this.a_arm || abs(this.get_v()) > this.v_arm
                % Abort firing and start cooldown
                this.firing = -1;
            end
                
            if this.firing < 0 
                this.cooldown = this.cooldown_len;
            end
        end        
        
        % Arming
        this.armed = this.firing<=0 && this.cooldown<=0 && ...
            abs(this.get_a())<=this.a_arm && abs(this.get_v())<=this.v_arm;
        
        % Autofire (once armed is computed)
        if this.autofire && this.armed && this.has_target() && ...
                this.target.check_hit(this.x, this.y, pi/2)
            this.firing = this.firing_len;
            this.armed  = false;
        end 
    end
    
    function r = radius(this)
        r = saudefense.H/2*(1-this.exploding/this.wave_len);
    end
    
    function txt = get_ready_txt(this)
        txt = this.txt_armed{this.state};
    end
    
    function a = get_a(this)
        a = this.loop.get_a();
    end
    
    function v = get_v(this)
        v = this.loop.get_v();
    end
    
    function stf = get_tf(this)
        stf = this.loop.get_tf();
    end
    
    function dtf = get_discrete_tf(this)
        dtf = this.loop.get_discrete_tf();
    end
    
    function bool = has_target(this)
        bool = isa(this.target, 'i_killable');
    end
    
    function set_loop(this, loop)
        this.loop = loop;
        this.reset_state();
        
        info    = stepinfo(loop.get_tf());        
        this.ts = info.SettlingTime;
        fprintf('Gun has %.2f s response time\n', this.ts);
    end
    
    function set_target(this, target)
        prev_target = this.target;        
        this.target = target;
        
        if this.mode == this.MODE_TS
            if isa(target, 'i_killable')
                if ~isa(prev_target, 'i_killable') || prev_target.id ~= target.id
                    this.cooldown = this.ts;
                end
            end
        end
    end
    
    function y = output(this, x)
        y = this.loop.output(x);
    end
    
    function hard_stop(this)
        this.reset_state();
        % This is broken for now, we must somehow fix the position in the
        % loop
    end
    
    function reset_state(this)
        this.loop.reset_state();   
        this.x = 0;
    end
    
    function done = update(this, period)
        done = false;            
        
        if this.exploding > 0
            this.exploding = this.exploding - period;
            if this.exploding <= 0
                this.exploding = 0;
                this.reset_state();
            end
        else        
            if this.has_target()
                this.x = this.output(this.target.x);
            else
                this.x = this.output(this.x);
            end
        end
    end
    
end

end