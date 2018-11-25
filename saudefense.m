classdef saudefense < handle

% TO DO:
% Plot position input/output
% Plot controlled position response
% Plot controlled rlocus
    
properties(Constant)        
    %Ts      = 2     % Motor response time
    %OS      = 0.1   % Motor overshoot        
    
    scale   = 0.1   % scale to window
    W       = 90    % world width
    H       = 160   % world height
    Vr_max  = 5
    v_arm   = 1   % max speed allowing fire
    
    foe_lambda = 2/4 % Incomings per second (lambda for poisson)
    
    txt_armed={'disarmed', 'armed', 'cooling down', 'firing'}
    mark_armed={'o','^', 'v', '^'}
end

properties        
    % Timing
    T       = 1/20  % period
    
    load    = zeros(1, 10)  % CPU use in %1
    load_len= 10      % Samples to avg        
    
    % Drawing
    fig             % world handle
    fig_signals
    window
    
    % Vars
    x        = 0     % gun position
    vx       = 0     % gun speed
    Vr_man   = 0     % reference instantaneous manual input  
    armed    = true        
    firing   = 0     % time left in current firing
    firing_len = 0.5 % time a firing lasts
    
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
    tau     = 0.25  % 1st order gun model
    speed   = 10    % Gun m/s (static motor gain)
    
    G_Gun           % gun's TF    
    G_C             % controller
    G_I             % sensor (integrator)        
    
    C_Kp = 0.1 % PID constants    
    C_Ki = 0.0       
    C_Kd = 0.0
    C_Kn = 1/20   % Filter freq (hf pole)
    
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
        %axes(battle_handle, 'xtick',[],'ytick',[],'ztick',[]);                
        %set(battle_handle, 'color', 'w');
        cla(battle_handle);
        axis(battle_handle, [-this.W/2 this.W/2 0 this.H]*this.scale)        
        drawnow
        this.fig = battle_handle;
        
        return;        
        
%         this.fig_signals = this.select_history;
%         ylabel('Motor speed')
%         xlabel('Seconds from now')
%         title('\Omega(s) Input/Output')
%         
%         this.select_analysis;
%         hold on
%         % motor speed response
%         step(this.G_Gun.tf/this.speed); % normalized to unity        
%         % controlled position response
%         step(feedback(this.G_C.tf * this.G_Gun.tf * this.G_I.tf, 1));
%         % ramp error response
%         impulse(c2d(1/s^2, this.T) - ...
%                 c2d(1/s^2, this.T)*feedback(this.G_C.tf * this.G_Gun.tf * this.G_I.tf, 1));
%         %title('Manual response')
    end
    
    function compute(this)
        
        % FOES
        if rand < poisspdf(1, this.foe_lambda*this.T)
            this.foes{end+1} = foe(this, 2-(rand<0.8));%, foe.BOMB);
        end
        
        closer_foe = 0;
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
                        (closer_foe == 0 || ...                         
                         this.foes{i}.y < this.foes{closer_foe}.y)
                    closer_foe = i;
                end
                i = i + 1;
            end
        end
                
        % DYNAMICS
        
        % Control input
        E = 0;
        if this.auto_aim && closer_foe > 0
            Xr      = this.foes{closer_foe}.x;
            E = Xr - this.x;                        
        end       
        
        % Control output
        U_auto = this.G_C.output(E);        
        
        % Mixed motor input (saturated)
        U = U_auto + this.Vr_man;        
        if abs(U) > this.Vr_max
            U = this.Vr_max*sign(U);
        end
        
        % Gun speed
        this.vx = this.G_Gun.output(U);

        % Gun position
        this.x = this.G_I.output(this.vx);
        
        % FIRING
        
        if this.cooldown > 0
            this.cooldown = this.cooldown - this.T;
            if this.cooldown < 0 
                this.cooldown = 0;
            end
        end
        
        if this.firing > 0
            this.firing = this.firing - this.T;
            
            if abs(this.vx) > this.v_arm % Abort firing and start coldown
                this.firing = -1;
            end
                
            if this.firing < 0 
                this.cooldown = this.cooldown_len;
            end
        end        
        
        this.armed = this.firing<=0 && this.cooldown<=0 && abs(this.vx)<=this.v_arm;
        
        % Collision
        if abs(this.x) > this.W/2
            this.x = this.W/2 * sign(this.x);
            this.hard_stop();
        end
        %fprintf('%6.3f %6.3f\n', this.x, this.G_I.state);
        
        % Autofire (once armed is computed)
        if this.auto_fire && this.armed && closer_foe > 0 && ...
                abs(this.x - this.foes{closer_foe}.x) <= this.foes{closer_foe}.size/2
            this.firing = this.firing_len;
            this.armed  = false;
        end
        
        % HISTORY
        samples = floor(this.max_hist_time / this.T);
        this.hist_vx = [this.hist_vx; this.vx*this.T];
        this.hist_Vr = [this.hist_Vr; this.Vr_man];
        this.hist_Cr = [this.hist_Cr; U_auto];
        
        if numel(this.hist_vx) > samples
            this.hist_vx = this.hist_vx(2:end);
            this.hist_Vr = this.hist_Vr(2:end);
            this.hist_Cr = this.hist_Cr(2:end);
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
        
        text((2-this.W/2)*this.scale, (this.H-4)*this.scale, sprintf('%d', this.hits));
        
        text(-this.W/2*this.scale, -16*this.scale, ...
            sprintf('CPU: %5.1f%%\nGun: %s\nCooldown: %3.1f', ...
                mean(this.load)*100, ...,                
                this.txt_armed{gs}, ...
                this.cooldown))
        
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
        % SIGNALS
%         if numel(this.hist_vx) > 1
%             cla(this.fig_signals);
%             this.select_history;
%             hold on
%             X=(-numel(this.hist_vx)+1:0)' * this.T;
%             plot(X, this.hist_vx/this.speed, ...
%                  X, this.hist_Vr/this.Vr_max, ...
%                  X, this.hist_Cr/this.Vr_max);
%             axis([-this.max_hist_time 0 -1.05 1.05])
%             drawnow
%         end
    end   
    
    function done = iterate(this)
        done = this.lives < 0;
        
        start = tic;

        % Compute
        this.compute;

        % Draw
        this.draw;

        % Load
        elapsed = toc(start);                        
        this.load = [this.load elapsed / this.T];
        if numel(this.load) > this.load_len
            this.load = this.load(2:end);
        end        
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
        this.G_C.ctf
        
        % Integrator
        this.G_I = dtf(1/s, this.T);   
    
        this.hard_stop();
    end
        
end
   
    
end