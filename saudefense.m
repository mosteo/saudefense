classdef saudefense < handle
   
properties
    % Constants
    Ts      = 2     % Motor response time
    OS      = 0.05  % Motor overshoot
    
    scale   = 0.1   % scale to window
    W       = 90    % world width
    H       = 160   % world height
    Vr_max  = 5
    v_arm   = 0.5   % max speed allowing fire
    txt_armed={'disarmed', 'armed'}
    mark_armed={'o','^'}
    
    % Timing
    T       = 1/10  % period
    prev    = tic
    load    = 0     % CPU use in %1
    load_len= 10      % Samples to avg
    
    G_Gun           % gun's continuous TF
    D_Gun           % gun's discrete z-TF
    
    % Drawing
    fig             % world handle
    fig_signals
    window
    
    % Vars
    x        = 0     % gun position
    vx       = 0     % gun speed
    Vr       = 0     % reference instantaneous manual input  
    armed    = true
    numpad4  = false
    numpad6  = false
    
    % SAU things
    Z_Gun            % internal state of gun
    
    % History
    max_hist_time = 10 % Seconds of history to keep
    hist_vx = []
    hist_Vr = []
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
        this.G_Gun = wn^2/(s^2+2*zwn*s+wn^2);
        this.D_Gun = c2d(this.G_Gun, this.T);
        this.Z_Gun = zeros(numel(this.D_Gun.den{1})-1, 1);
        
        function keyPress(~, eventdata)
            if strcmp(eventdata.Key, 'numpad6')
                this.Vr      = this.Vr_max;
                this.numpad6 = true;
            elseif strcmp(eventdata.Key, 'numpad4')
                this.Vr      = -this.Vr_max;
                this.numpad4 = true;
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
        
        this.window = figure(1);
        this.fig = this.select_world;
        set(this.window, 'KeyPressFcn', @keyPress, 'KeyReleaseFcn', @keyRelease);
        
        this.fig_signals = this.select_history;
        ylabel('Motor speed')
        xlabel('Seconds from now')
        title('Input/Output')
        
        this.select_analysis;
        step(this.G_Gun);
        
        this.loop;
    end
    
    function compute(this)
        [this.vx, this.Z_Gun] = ...
            filter(this.D_Gun.num{1}', this.D_Gun.den{1}', this.Vr, this.Z_Gun);
        this.x = this.x + this.vx;
        
        this.armed = abs(this.vx) <= this.v_arm;
        
        if abs(this.x) > this.W/2
            this.x = this.W/2 * sign(this.x);
            this.Z_Gun = this.Z_Gun * 0;
        end
        
        samples = floor(this.max_hist_time / this.T);
        this.hist_vx = [this.hist_vx; this.vx];
        this.hist_Vr = [this.hist_Vr; this.Vr];
        
        if numel(this.hist_vx) > samples
            this.hist_vx = this.hist_vx(2:end);
            this.hist_Vr = this.hist_Vr(2:end);
        end
    end
    
    function draw(this)   
        % WORLD
        cla(this.fig)
        this.select_world;
        axis off
        hold on        
        text(-this.W/2*this.scale, this.H*this.scale, ...
            sprintf('CPU: %5.1f%%\nGun: %s\nCooldown: %3.1f', ...
                mean(this.load)*100, ...
                this.txt_armed{this.armed+1}, ...
                0))
        
        boxX = [-this.W/2 this.W/2 this.W/2 -this.W/2 -this.W/2]'.*this.scale;
        boxY = [0 0 this.H this.H 0]'.*this.scale;
        plot(boxX, boxY, 'k');
        
        plot(this.x*this.scale, 0, this.mark_armed{this.armed + 1})
        
        axis equal
        drawnow
        
        % SIGNALS
        if numel(this.hist_vx) > 1
            cla(this.fig_signals);
            this.select_history;
            hold on
            X=(-numel(this.hist_vx)+1:0)' * this.T;
            plot(X, this.hist_vx, X, this.hist_Vr);
            axis([-this.max_hist_time 0 -this.Vr_max*1.05 this.Vr_max*1.05])
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
            this.load = [this.load elapsed / this.T];
            if numel(this.load) > this.load_len
                this.load = this.load(2:end);
            end
            if elapsed < this.T
                pause(this.T - elapsed)
            end
        end
    end
    
end
   
    
end