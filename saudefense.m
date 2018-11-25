classdef saudefense < handle
    
properties(Constant)        
    %Ts      = 2     % Motor response time
    %OS      = 0.1   % Motor overshoot        
    
    scale   = 0.1   % scale to window
    W       = 90    % world width
    H       = 160   % world height
    Vr_max  = 5
    v_arm   = 10  % max speed allowing fire
    a_arm   = 10  % max accel allowing fire
    
    foe_lambda = 1/4 % Incomings per second (lambda for poisson)
    % initial rate, that increases with difficulty
    
    txt_armed={'disarmed', 'armed', 'cooling down', 'firing'}
    mark_armed={'o','^', 'v', '^'}
    
    difficulty_period = 5*60; % Time until max diff
end

properties        
    % Timing
    T       = 1/20  % period
    start           % of each cycle (for load computation)
    
    load    = zeros(1, 10)  % CPU use in %1
    load_len= 10      % Samples to avg        
    
    % Drawing
    fig             % world handle
    fig_signals
    window
    
    % Vars
    x        = 0     % gun position
    vx       = 0     % gun speed
    vx_1     = 0     % previoux speed
    ax       = 0     % gun acceleration
    Vr_man   = 0     % reference instantaneous manual input  
    armed    = true        
    firing   = 0     % time left in current firing
    firing_len = 0.5 % time a firing lasts
    
    target = 0
    
    difficulty = 0;
    
    hits  = 0 % Foes destroyed   
    lives = 3;    
    
    foes = {}
    
    cooldown = 0
    cooldown_len = 1 % time until next shot ready
    
    numpad4  = false
    numpad6  = false
    
    auto_aim  = true
    auto_fire = true
        
    % SAU things
    tau     = 0.05  % 1st order gun model
    speed   = 10    % Gun m/s (static motor gain)
    
    G_Gun           % gun's TF    
    G_C             % controller
    G_I             % sensor (integrator)        
    
    C_Kp = 0.1 % PID constants    
    C_Ki = 0.0       
    C_Kd = 0.0
    C_Kn = 1/20   % Filter freq (hf pole)
    
    U_auto
    
    % History
    max_hist_time = 10 % Seconds of history to keep
    hist_vx = []
    hist_Vr = []
    hist_Cr = []
end

methods(Access=private)
    
    function axis = select_world(~)
        axis = subplot(2, 2, [1 3]);
    end
    
    function axis = select_history(~)
        axis = subplot(2, 2, 2);
    end
    
    function axis = select_analysis(~)
        axis = subplot(2, 2, 4);
    end        
    
end

methods(Access=public)
    
    function this = saudefense(battle_handle)                
        this.update_LTI();                             
        
        % BATTLE SETUP
        set(battle_handle, 'DefaultLineLineWidth', 2);
        axes(battle_handle);
        axis off
        hold on
        cla(battle_handle);
        axis(battle_handle, [-this.W/2 this.W/2 0 this.H]*this.scale)        
        drawnow
        this.fig = battle_handle;
        
        return;        
        
%         this.fig_signals = this.select_history;
%         ylabel('Motor speed')
%         xlabel('Seconds from now')
%         title('\Omega(s) Input/Output')
    end
    
    function compute(this)
        
        % Difficulty
        this.difficulty = ...
            min(1, this.difficulty + 1/this.difficulty_period*this.T);
        
        % FOES
        if rand < poisspdf(1, (this.foe_lambda + this.difficulty/2)*this.T)
            this.foes{end+1} = foe(this, 2-(rand>this.difficulty*0.9), this.difficulty);
        end
        
        this.target = 0;
        i = 1;        
        while i <= numel(this.foes)
            [alive, hit, destroyed] = this.foes{i}.update();
            
            this.lives = this.lives - hit;
            this.hits  = this.hits + destroyed;
            
            if ~alive || hit
                this.foes(i) = [];
            else 
                if this.foes{i}.alive && ...
                   this.foes{i}.y < this.H - this.foes{i}.size && ...
                        (this.target == 0 || ...                         
                         this.foes{i}.y < this.foes{this.target}.y)
                    this.target = i;
                end
                i = i + 1;
            end
        end
        
        this.fire();
                
        this.dynamics();        
        
        % HISTORY
        samples = floor(this.max_hist_time / this.T);
        this.hist_vx = [this.hist_vx; this.vx*this.T];
        this.hist_Vr = [this.hist_Vr; this.Vr_man];
        this.hist_Cr = [this.hist_Cr; this.U_auto];
        
        if numel(this.hist_vx) > samples
            this.hist_vx = this.hist_vx(2:end);
            this.hist_Vr = this.hist_Vr(2:end);
            this.hist_Cr = this.hist_Cr(2:end);
        end
    end
    
    function dynamics(this)
        % Control input
        E = 0;
        if this.auto_aim && this.target > 0 && this.firing <= 0
            Xr      = this.foes{this.target}.x;
            E = Xr - this.x;                        
        end       
        
        % Control output
        this.U_auto = this.G_C.output(E);        
        
        % Mixed motor input (saturated)
        U = this.U_auto + this.Vr_man;        
        if abs(U) > this.Vr_max
            U = this.Vr_max*sign(U);
        end
        
        % Gun speed
        this.vx_1 = this.vx;
        this.vx   = this.G_Gun.output(U);
        
        % Gun acceleration
        this.ax = (this.vx - this.vx_1) / this.T;

        % Gun position
        this.x = this.G_I.output(this.vx);                       
        
        % Collision
        if abs(this.x) > this.W/2
            this.x = this.W/2 * sign(this.x);
            this.hard_stop();
        end
        %fprintf('%6.3f %6.3f\n', this.x, this.G_I.state);
    end
    
    function fire(this)
        % Cooldown
        if this.cooldown > 0
            this.cooldown = this.cooldown - this.T;
            if this.cooldown < 0 
                this.cooldown = 0;
            end
        end
        
        % Firing
        if this.firing > 0
            this.firing = this.firing - this.T;
            
            if abs(this.ax) > this.a_arm || abs(this.vx) > this.v_arm
                % Abort firing and start cooldown
                this.firing = -1;
            end
                
            if this.firing < 0 
                this.cooldown = this.cooldown_len;
            end
        end        
        
        % Arming
        this.armed = this.firing<=0 && this.cooldown<=0 && ...
            abs(this.ax)<=this.a_arm && abs(this.vx)<=this.v_arm;
        
        % Autofire (once armed is computed)
        if this.auto_fire && this.armed && this.target > 0 && ...
                abs(this.x - this.foes{this.target}.x) <= this.foes{this.target}.size/2
            this.firing = this.firing_len;
            this.armed  = false;
        end 
    end
    
    function draw(this)   
        % WORLD
        cla(this.fig)
        axes(this.fig)
        fill(this.fig, ...
            [-this.W/2; this.W/2; this.W/2; -this.W/2]*this.scale, ...
            [0; 0; this.H; this.H], 'w');
        
        % lives
        for i=1:this.lives
            plot([-this.W/2 this.W/2]'*this.scale, ...
                 ones(2,1)*i*2*this.scale, 'g');
        end
        
        % Foes
        for i = 1:numel(this.foes)
            this.foes{i}.draw()
        end
        
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
        
        %text((2-this.W/2)*this.scale, (this.H-4)*this.scale, sprintf('%d', this.hits));
        
%         text(-this.W/2*this.scale, -16*this.scale, ...
%             sprintf('CPU: %5.1f%%\nGun: %s\nCooldown: %3.1f', ...
%                 mean(this.load)*100, ...,                
%                 this.txt_armed{gs}, ...
%                 this.cooldown))
        
        boxX = [-this.W/2 this.W/2 this.W/2 -this.W/2 -this.W/2]'.*this.scale;
        boxY = [0 0 this.H this.H 0]'.*this.scale;
        plot(boxX, boxY, 'k');
        
        plot(this.x*this.scale, 0, this.mark_armed{gs}, 'MarkerSize', foe.size*4)
        
        if (this.firing > 0)
            rayX = [this.x this.x]*this.scale;
            rayY = [0 this.H]*this.scale;
            plot(rayX', rayY', 'r-');
        end        
        
        %axis([-this.W/2 this.W/2 0 this.H]*this.scale)
        drawnow
        
        return
    end   
    
    function done = iterate(this)
        done = this.lives < 0;
        
        % Compute
        this.compute;

        % Draw
        this.draw;           
    end    
    
    function keyPress(this, eventdata)
        if strcmp(eventdata.Key, 'numpad6')
            this.Vr_man      = this.Vr_max;
            this.numpad6 = true;
        elseif strcmp(eventdata.Key, 'numpad4')
            this.Vr_man      = -this.Vr_max;
            this.numpad4 = true;
        elseif strcmp(eventdata.Key, 'numpad8')
            if this.armed
                this.firing = this.firing_len;
                this.armed  = false;
            end
        end
    end       

    function keyRelease(this, eventdata)
        if strcmp(eventdata.Key, 'numpad6')
            this.numpad6 = false;
            if this.numpad4 
                this.Vr_man = -this.Vr_max;
            else
                this.Vr_man = 0;
            end
        elseif strcmp(eventdata.Key, 'numpad4')
            this.numpad4 = false;
            if this.numpad6
                this.Vr_man = this.Vr_max;
            else
                this.Vr_man = 0;
            end
        end
    end
    
    function hard_stop(this)
    % When stopping abruptly or reconfiguring
        this.G_C.reset_state();
        this.G_Gun.reset_state();
        % integrator stated fixed to next value
        this.G_I.set_state(this.x);
    end
    
    function update_LTI(this)
    % Update things on the fly... yikes!
    % For changes in PID parameters, T, ...
        s=tf('s');
        
        % 2nd order gun
        %zwn=4/this.Ts;       
        %z=-log(this.OS)/sqrt(pi^2 + log(this.OS)^2);
        %wn=zwn/z;                
        %this.G_Gun = dtf(wn^2/(s^2+2*zwn*s+wn^2)*this.speed, this.T);                
        
        % 1st order gun
        this.G_Gun = dtf(this.speed/(this.tau*s+1), this.T);

        % Controller
        this.C_Kn = 1/this.T;
        this.G_C = dtf(this.C_Kp + this.C_Ki/s + ...
            this.C_Kd*this.C_Kn*s/(s+this.C_Kn), this.T);
        this.G_C.ctf;
        
        % Integrator
        this.G_I = dtf(1/s, this.T);   
    
        this.hard_stop();                
    end
    
    function update_error_plot(this, axe)
        axes(axe);
        cla
        hold on
        
        s=tf('s');
 
        % step error response
        impulse(c2d(1/s, this.T) - ...
                c2d(1/s, this.T)*feedback(this.G_C.tf * this.G_Gun.tf * this.G_I.tf, 1));
        % ramp error response
        impulse(c2d(1/s^2, this.T) - ...
                c2d(1/s^2, this.T)*feedback(this.G_C.tf * this.G_Gun.tf * this.G_I.tf, 1));
        %title('Manual response')
        
        title('');
        xlabel('');
        ylabel('');
    end    
    
    function update_response_plot(this, axe)        
        axes(axe);
        cla
        hold on        
        
        % motor speed response
        step(this.G_Gun.tf/this.speed); % normalized to unity        
        % controlled position response
        stepplot(feedback(this.G_C.tf * this.G_Gun.tf * this.G_I.tf, 1));
        axis auto
        
        title('');
        ylabel('');        
    end
    
    function update_siso_plot(this, axe)
        axes(axe);
        cla
        hold on
        
        if numel(this.hist_vx) > 1
            X=(-numel(this.hist_vx)+1:0)' * this.T;
            plot(X, this.hist_vx/this.speed, ...
                 X, this.hist_Vr/this.Vr_max, ...
                 X, this.hist_Cr/this.Vr_max);
            axis([-this.max_hist_time 0 -1.05 1.05])
        end
        
        title('');
        xlabel('');
        ylabel('');
        drawnow
    end    
    
    function update_rlocus(this, axe, continuous)
        axes(axe);
        cla
        hold on
        
        if continuous
            % r-locus:
            rlocus(this.G_C.ctf * this.G_Gun.ctf * this.G_I.ctf);
            % poles/zeros:
            rlocus(this.G_C.ctf, 'r', this.G_Gun.ctf * this.G_I.ctf, 'k', 0);
            % closed-loop poles:
            rlocus(feedback(this.G_C.ctf * this.G_Gun.ctf * this.G_I.ctf, 1), 'g', 0);
        else
            % r-locus:
            rlocus(this.G_C.tf * this.G_Gun.tf * this.G_I.tf);
            % poles/zeros:
            rlocus(this.G_C.tf, 'r', this.G_Gun.tf * this.G_I.tf, 'k', 0);
            % closed-loop poles:
            rlocus(feedback(this.G_C.tf * this.G_Gun.tf * this.G_I.tf, 1), 'g', 0);
        end
        
        title('');
    end
    
    function tic(this)
        this.start = tic;
    end
    
    function toc(this)
        % Load
        elapsed = toc(this.start);                        
        this.load = [this.load elapsed / this.T];
        if numel(this.load) > this.load_len
            this.load = this.load(2:end);
        end    
    end
        
end
   
    
end