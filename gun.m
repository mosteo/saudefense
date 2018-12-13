classdef gun < i_body & i_drawable & i_loop & i_killer
% We could directly inherit from loop_single to save a few methods
% This way we make the gun reusable for different loop implementations.
    
properties(Constant)
    txt_armed={'disarmed', 'armed', 'cooling down', 'firing'}
    mark_armed={'o','^', 'v', '^'}
    
    size = 12;
    
    v_arm   = 10  % max speed allowing fire
    a_arm   =  2  % max accel allowing fire
    
    firing_len   = 0.5  % time a firing lasts   
    cooldown_len = 1    % time until next shot ready        
end
    
properties
    loop            % gun dynamics (with controller)
    
    firing   = 0;
    cooldown = 0;
    armed    = true;         
    autofire = true;
    
    G, H
    
    gun_ready = 2;   % (disarmed, armed, cooling, firing) (positive)
    
    target   = []    % An instance of i_killable
    
    h_gun   % Drawers 
    h_ray
end
    
methods
    
    function this = gun(loop)
        % set dynamics        
        this.loop = loop;
        this.G    = loop.G;
        this.H    = loop.H;
        
        this.x = 0;
        this.y = 0;
        
        this.h_gun = drawer();
        this.h_ray = drawer();
    end
   
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
        
        this.gun_ready = gs;
        
        this.h_gun.plot(axis, ...
            this.x*scale, 0, 'Marker', this.mark_armed{gs}, ...
            'MarkerSize', this.size, 'Color', [0 0 0.5]);
        
        
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
                this.target.check_hit(this.x, this.y, pi/2, false)
            this.firing = this.firing_len;
            this.armed  = false;
        end 
    end
    
    function txt = get_ready_txt(this)
        txt = this.txt_armed{this.gun_ready};
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
    
    function set_target(this, target)
        this.target = target;
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
    end
    
    function done = update(this)
        done = false;                
        
        if this.has_target()
            this.x = this.output(this.target.x);
        else
            this.x = this.output(this.x);
        end
    end
    
end

end