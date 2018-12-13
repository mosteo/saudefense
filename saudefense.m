classdef saudefense < handle
    
properties(Constant)            
    scale   = 0.1   % scale to window
    W       = 90    % world width
    H       = 160   % world height
    Vr_max  = 5    
    
    foe_lambda = 1/4 % Incomings per second (lambda for poisson)
    % initial rate, that increases with difficulty
    
    foe_manual_dist = 16 % Distance for a target to be considered (in manual targeting)                
    
    difficulty_period = 5*60; % Time until max diff
    initial_lives     = 3;
end

properties        
    % Timing
    T       = 1/20  % period
    start           % of each cycle (for load computation)
    
    load    = zeros(1, 10)  % CPU use in %1
    load_len= 10      % Samples to avg        
    
    % Drawing
    fig             % world handle
    
    % Vars
    Vr_man   = 0     % reference instantaneous manual input      
    
    target     = 0   % Current targeted foe index
    man_target = 0   % Current foe under mouse index
    
    target_reticle
    
    difficulty = 0;
    
    hits  = 0 % Foes destroyed   
    lives = saudefense.initial_lives;    
    
    foes = {}
    
    gun         % see gun.m class
    
    numpad4  = false
    numpad6  = false
    
    auto_aim  = true
        
    % SAU things
    loop        % Main loop TF, see i_loop.m
    
    U_auto
    
    % History
    max_hist_time = 10 % Seconds of history to keep
    hist_vx = []
    hist_Vr = []
    hist_Cr = []
    
    nogui = false; % if this.forever is used, this will be true
    
    txt_score   % Drawers
    txt_status
    frame      
    
    h_lives = cell(saudefense.initial_lives, 1);
end

methods(Static)
    function demo(T, C, G)
    % Function to test/demo saudefense without a GUI

        if nargin < 1
            T = 0.01;
        end

        if nargin < 2
            PID = controller_pid_ideal;
            PID.set_PID(0.4, 0, 0); 
            C = PID.get_tf;
        end

        if nargin < 3
            motor = motor_1st(10, 0.1);
            G = motor.get_tf;
        end

        tff = @tf_factory.ss;

        loop = loop_single(tff, T, C*G, 1);

        figure(33);
        sau = saudefense(gca, loop);
        sau.forever;
    end
    
    function demo_ss(T, C, G)
    % Function to test/demo saudefense with SS model without a GUI

        if nargin < 1
            T = 0.01;
        end

        if nargin < 2
            PID = controller_pid_ideal;
            PID.set_PID(0.4, 0, 0); 
            C = PID.get_tf;
        end

        if nargin < 3
            motor = motor_mbk(0.001, 0.01, 0.0);
            G = 30 * motor.get_tf;
        end

        tff = @tf_factory.ss;   

        loop = loop_single(tff, T, C*G, 1);

        figure(33);
        sau = saudefense(gca, loop);
        sau.forever;
    end
    
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
    
    function this = saudefense(battle_handle, loop)                     
        if nargin >= 2
            this.loop = loop;
        else
            % Default dumb gun
            s=tf('s');
            this.loop = loop_single(tff.z, 2/(0.1*s+1)/s, 1);
        end
        
        this.txt_score  = drawer();
        this.txt_status = drawer();
        this.frame      = drawer();
        this.target_reticle=reticle();
        this.gun = gun(loop);        
        this.fig = battle_handle;
        
        for i=1:numel(this.h_lives)
            this.h_lives{i} = drawer();
        end
        
        this.draw_init();
    end
    
    function compute(this)
        
        % Difficulty
        this.difficulty = ...
            min(1, this.difficulty + 1/this.difficulty_period*this.T);
        
        this.foeing();
        
        this.fire();
                
        this.dynamics();        
        
        % HISTORY
        samples = floor(this.max_hist_time / this.T);
        this.hist_vx = [this.hist_vx; this.gun.get_v()*this.T];
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
        if this.auto_aim && this.target > 0 && this.gun.firing <= 0
            this.gun.set_target(this.foes{this.target});
        else
            this.gun.set_target([]);                        
        end 
        
        this.gun.update();
    end
    
    function foeing(this)
        % Generate?
        if rand < poisspdf(1, (this.foe_lambda + this.difficulty/2)*this.T)
            this.foes{end+1} = foe(this.T, 2-(rand>this.difficulty*0.9), this.difficulty);
        end
        
        % Move 
        i = 1;        
        while i <= numel(this.foes)
            done = this.foes{i}.update();
            
            % Gun hit?
            hit_me = this.foes{i}.alive && (this.foes{i}.y <= 0);                
            
            % Hit by us?
            if this.gun.firing > 0 
                hit_it = this.foes{i}.check_hit(this.gun.x, this.gun.y, pi/2, true);
            else
                hit_it = false;
            end
            
            this.lives = this.lives - hit_me;
            this.hits  = this.hits  + hit_it;
            
            % adjust target if going away
            if done || hit_it
                if this.target == i
                    this.target = 0;
                elseif this.target > i
                    this.target = this.target - 1;
                end
            end
            
            % list housekeeping
            if done
                this.foes(i) = [];
            else 
                i = i + 1;
            end
        end         
        
        % Find closest to mouse
        mouse   = this.fig.CurrentPoint/this.scale;        
        cl_dist = Inf;
        this.man_target = 0;        
        for i = 1:numel(this.foes)
            if ~this.foes{i}.alive; continue; end % disintegrating
            d = norm([mouse(1,1) - this.foes{i}.x; ...
                      mouse(1,2) - this.foes{i}.y]);
            if d < this.foe_manual_dist && d < cl_dist
                this.man_target = i;
                cl_dist = d;
            end
        end
        
        % Targeting        
        if this.man_target > 0 
            this.target = this.man_target;
        else
            best = Inf;
            for i = 1:numel(this.foes)                                                                
                if ~this.foes{i}.alive; continue; end 
                % already dead

                if this.foes{i}.y > this.H - this.foes{i}.size; continue; end
                % Barely visible, do not consider yet

                score = norm([this.gun.x - this.foes{i}.x; this.foes{i}.y]);

                if score < best
                    best = score;
                    this.target = i;
                end
            end
        end
    end
    
    function fire(this)
        this.gun.fire;
    end
    
    function draw_init(this)
        % 1st initialization
        axes(this.fig)            
        set(this.fig, 'DefaultLineLineWidth', 2);
        axis(this.fig, 'off');           
        hold(this.fig, 'on');
        cla(this.fig);
        axis(this.fig, 'equal');
        axis(this.fig, [-this.W/2 this.W/2 0 this.H]*this.scale)        
        fill(this.fig, ...
            [-this.W/2; this.W/2; this.W/2; -this.W/2]*this.scale, ...
            [0; 0; this.H; this.H], 'w');
        boxX = [-this.W/2 this.W/2 this.W/2 -this.W/2 -this.W/2]'.*this.scale;
        boxY = [0 0 this.H this.H 0]'.*this.scale;
        this.frame.plot(this.fig, boxX, boxY, 'Color', [0, 0, 0]);       
    end
    
    function draw(this)                  
        for i=1:this.lives
            this.h_lives{i}.plot(this.fig, ...
                [-this.W/2 this.W/2]'*this.scale, ...
                 ones(2,1)*i*2*this.scale, 'Color', [0 1 0]);
             this.h_lives{i}.show();
        end

        for i=(this.lives+1):numel(this.h_lives)
            if i>0 && i<= length(this.h_lives)
                this.h_lives{i}.show(false);
            end
        end
        
        % Foes
        for i = 1:numel(this.foes)
            this.foes{i}.draw(this.fig)
        end
        
        % Reticle
        red = [1 0 0];
        if this.target > 0 
            this.target_reticle.draw(this.fig, this.foes{this.target}.id, ...
                this.foes{this.target}.x, this.foes{this.target}.y, ...
                this.scale, red);
        else
            this.target_reticle.draw(this.fig, 0, 0, 0, this.scale, red);
        end
%         if this.man_target > 0 
%             this.manual_reticle.draw(this.fig, this.foes{this.man_target}.id, ...
%                 this.foes{this.man_target}.x, this.foes{this.man_target}.y, ...
%                 this.scale, 'r:');
%         end                
        
        if this.nogui
            this.txt_score.text(this.fig, (2-this.W/2)*this.scale, (this.H-4)*this.scale, ...
                sprintf('%d', this.hits));
            
            this.txt_status.text(this.fig, -this.W/2*this.scale, -16*this.scale, ...
                sprintf('CPU: %5.1f%%\nGun: %s\nCooldown: %3.1f', ...
                        mean(this.load)*100, ...,                
                        this.gun.get_ready_txt(), ...
                        this.gun.cooldown));
        end

        this.gun.draw(this.fig, this.scale);     
        
        this.frame.bring_to_front;
        
        return
    end   
    
    function forever(this)
        this.nogui = true;
        
        done = false;
        while ~done
            this.tic;            
            done    = this.iterate;                       
            pause(this.T - this.toc);
%             this.toc;
        end
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
        this.gun.hard_stop();
    end
    
    function update_LTI(this, C, G)        
    % Update things on the fly... yikes!
    % For changes in PID parameters, T, ...
    % Receives ideal s-tf Controller and Plant
        this.loop = loop_single(@tf_factory.ss, this.T, C*G, 1);          
    end        
    
    function tic(this)
        this.start = tic;
    end
    
    function elapsed = toc(this)
        % Load
        elapsed = toc(this.start);                        
        this.load = [this.load elapsed/this.T];
        if numel(this.load) > this.load_len
            this.load = this.load(2:end);
        end    
    end
        
end
   
    
end