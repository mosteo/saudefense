classdef saudefense < handle

% TO DO:
% Migrate FdTs to own class
% Plot position input/output
% Implement non-K controllers
% Plot controlled position response
% Plot controlled rlocus
    
properties(Constant)
    T       = 1/20  % period
        
    Ts      = 2     % Motor response time
    OS      = 0.1   % Motor overshoot
    speed   = 10     % Gun m/s (static motor gain)
    
    scale   = 0.1   % scale to window
    W       = 90    % world width
    H       = 160   % world height
    Vr_max  = 5
    v_arm   = saudefense.speed/10   % max speed allowing fire
    
    foe_lambda = 2/4 % Incomings per second (lambda for poisson)
    
    txt_armed={'disarmed', 'armed', 'cooling down', 'firing'}
    mark_armed={'o','^', 'v', '^'}
end

properties        
    % Timing
    prev    = tic
    load    = zeros(1, 10)  % CPU use in %1
    load_len= 10      % Samples to avg
    
    G_Gun           % gun's continuous TF
    D_Gun           % gun's discrete z-TF
    C               % controller
    DC              % discrete controller
    
    % Drawing
    fig             % world handle
    fig_signals
    window
    
    % Vars
    x        = 0     % gun position
    vx       = 0     % gun speed
    Vr       = 0     % reference instantaneous manual input  
    armed    = true        
    firing   = 0     % time left in current firing
    firing_len = 0.5 % time a firing lasts
    
    foes = {}
    
    cooldown = 0
    cooldown_len = 1 % time until next shot ready
    
    numpad4  = false
    numpad6  = false
    
    % SAU things
    Z_Gun            % internal state of gun
    auto_aim  = true
    auto_fire = true
    
    C_Kp = 0.106 % PID constants
    C_Kd = 0
    C_Ki = 0
    
    C_Kir = 1   % Feedback integrator constant
    
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
    
    function this = saudefense
        close all
        s = tf('s');
        zwn=4/this.Ts;       
        z=-log(this.OS)/sqrt(pi^2 + log(this.OS)^2);
        wn=zwn/z;
        this.G_Gun = wn^2/(s^2+2*zwn*s+wn^2)*this.speed;
        this.D_Gun = c2d(this.G_Gun, this.T);
        this.Z_Gun = zeros(numel(this.D_Gun.den{1})-1, 1);
        
        this.G_Gun       
        
        function keyPress(~, eventdata)
            if strcmp(eventdata.Key, 'numpad6')
                this.Vr      = this.Vr_max;
                this.numpad6 = true;
            elseif strcmp(eventdata.Key, 'numpad4')
                this.Vr      = -this.Vr_max;
                this.numpad4 = true;
            elseif strcmp(eventdata.Key, 'numpad8')
                if this.armed
                    this.firing = this.firing_len;
                    this.armed  = false;
                end
            end
        end       
        
        function keyRelease(~, eventdata)
            if strcmp(eventdata.Key, 'numpad6')
                this.numpad6 = false;
                if this.numpad4 
                    this.Vr = -this.Vr_max;
                else
                    this.Vr = 0;
                end
            elseif strcmp(eventdata.Key, 'numpad4')
                this.numpad4 = false;
                if this.numpad6
                    this.Vr = this.Vr_max;
                else
                    this.Vr = 0;
                end
            end
        end
        
        set(0, 'DefaultLineLineWidth', 2);
        
        this.window = figure(1);
        this.fig = this.select_world;
        title('Battlefield')
        set(this.window, 'KeyPressFcn', @keyPress, 'KeyReleaseFcn', @keyRelease);
        
        this.fig_signals = this.select_history;
        ylabel('Motor speed')
        xlabel('Seconds from now')
        title('\Omega(s) Input/Output')
        
        this.select_analysis;
        step(this.G_Gun/this.speed); % normalized to unity
        hold on
        step(feedback(this.C_Kp * this.G_Gun / s, 1));
        %title('Manual response')
        
        this.loop;
    end
    
    function compute(this)
        
        % FOES
        if rand < poisspdf(1, this.foe_lambda*this.T)
            this.foes{end+1} = foe(this, foe.BOMB);
        end
        
        closer_foe = 0;
        i = 1;        
        while i <= numel(this.foes)
            [alive, hit] = this.foes{i}.update();
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
        
        % GUN CONTROL
        Vrauto = 0;
        if this.auto_aim && closer_foe > 0
            Xr = this.foes{closer_foe}.x;
            Vrauto = this.C_Kp*(Xr - this.x);
            
            % Saturation:
            if abs(Vrauto) > this.Vr_max
                Vrauto = this.Vr_max*sign(Vrauto);
            end
        end       
        
        U = Vrauto + this.Vr; % Control signal
        if abs(U) > this.Vr_max
            U = this.Vr_max*sign(U);
        end
        
        % GUN DYNAMICS & FIRING        
        [this.vx, this.Z_Gun] = ...
            filter(this.D_Gun.num{1}', this.D_Gun.den{1}', U, this.Z_Gun);

        this.x = this.x + this.vx*this.T;        
        
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
            this.Z_Gun = this.Z_Gun * 0;
        end
        
        % Autofire (once armed is computed)
        if this.auto_fire && this.armed && closer_foe > 0 && ...
                abs(this.x - this.foes{closer_foe}.x) <= this.foes{closer_foe}.size/2
            this.firing = this.firing_len;
            this.armed  = false;
        end
        
        % HISTORY
        samples = floor(this.max_hist_time / this.T);
        this.hist_vx = [this.hist_vx; this.vx*this.T];
        this.hist_Vr = [this.hist_Vr; this.Vr];
        this.hist_Cr = [this.hist_Cr; Vrauto];
        
        if numel(this.hist_vx) > samples
            this.hist_vx = this.hist_vx(2:end);
            this.hist_Vr = this.hist_Vr(2:end);
            this.hist_Cr = this.hist_Cr(2:end);
        end
    end
    
    function draw(this)   
        % WORLD
        cla(this.fig)
        this.select_world;
        axis off
        hold on 
        
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
        
        axis([-this.W/2 this.W/2 0 this.H]*this.scale)
        drawnow
        
        % SIGNALS
        if numel(this.hist_vx) > 1
            cla(this.fig_signals);
            this.select_history;
            hold on
            X=(-numel(this.hist_vx)+1:0)' * this.T;
            plot(X, this.hist_vx/this.speed, ...
                 X, this.hist_Vr/this.Vr_max, ...
                 X, this.hist_Cr/this.Vr_max);
            axis([-this.max_hist_time 0 -1.05 1.05])
            drawnow
        end
    end   
    
    function loop(this)
        while true
            % Compute
            this.compute;

            % Draw
            this.draw;

            % Wait
            elapsed   = toc(this.prev);
            this.prev = tic;            
            if elapsed < this.T
                pause(this.T - elapsed)
            end
            
            this.load = [this.load elapsed / this.T];
            if numel(this.load) > this.load_len
                this.load = this.load(2:end);
            end
        end
    end
    
end
   
    
end