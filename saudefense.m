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
%    manual_reticle = reticle()
    
    difficulty = 0;
    
    hits  = 0 % Foes destroyed   
    lives = 3;    
    
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
    
    h_text_1;
    h_text_2;
    h_lives={};
    
    init_done;
end

methods(Static)
    function demo(T, C, G)
    % Function to test/demo saudefense without a GUI
        if nargin < 1
            T = 0.05;
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

        tff = @tf_factory.z;                   

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
        this.target_reticle=reticle()
        this.gun = gun(loop);
        
        % BATTLE SETUP
        set(battle_handle, 'DefaultLineLineWidth', 2);
        axes(battle_handle);
        axis off
        hold on
        cla(battle_handle);
        axis(battle_handle, [-this.W/2 this.W/2 0 this.H]*this.scale)        
%        drawnow
        this.fig = battle_handle;
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
    
    function draw(this)   
        % WORLD
        %cla(this.fig)

        if isempty(this.init_done)
            axes(this.fig)
            axis equal
            fill(this.fig, ...
                [-this.W/2; this.W/2; this.W/2; -this.W/2]*this.scale, ...
                [0; 0; this.H; this.H], 'w');
                    boxX = [-this.W/2 this.W/2 this.W/2 -this.W/2 -this.W/2]'.*this.scale;
                boxY = [0 0 this.H this.H 0]'.*this.scale;
                plot(this.fig, boxX, boxY, 'k');       
                this.init_done = 1;
        end
        
        % lives
        if (isempty(this.h_lives))
            for i=1:this.lives
                this.h_lives{i}=plot(this.fig, ...
                [-this.W/2 this.W/2]'*this.scale, ...
                 ones(2,1)*i*2*this.scale, 'g');
            end
        else
            for i=(this.lives+1):length(this.h_lives)
                if i>0 && i<= length(this.h_lives)
                    set(this.h_lives{i},'Visible','off');
                end
            end
        end
        
        % Foes
        for i = 1:numel(this.foes)
            this.foes{i}.draw(this.fig)
        end
        
        % Reticle
        if this.target > 0 
            this.target_reticle.draw(this.fig, this.foes{this.target}.id, ...
                this.foes{this.target}.x, this.foes{this.target}.y, ...
                this.scale, 'r');
        else
            this.target_reticle.draw(this.fig, 0, 0, 0, this.scale, 'r');
        end
%         if this.man_target > 0 
%             this.manual_reticle.draw(this.fig, this.foes{this.man_target}.id, ...
%                 this.foes{this.man_target}.x, this.foes{this.man_target}.y, ...
%                 this.scale, 'r:');
%         end                
        
        if this.nogui
            if isempty(this.h_text_1)
                this.h_text_1 = text((2-this.W/2)*this.scale, (this.H-4)*this.scale, sprintf('%d', this.hits));
            else
                this.h_text_1.String=char(sprintf('%d', this.hits));
            end
            
            if isempty(this.h_text_2)
                this.h_text_2 = text(-this.W/2*this.scale, -16*this.scale, ...
                    sprintf('CPU: %5.1f%%\nGun: %s\nCooldown: %3.1f', ...
                        mean(this.load)*100, ...,                
                        this.gun.get_ready_txt(), ...
                        this.gun.cooldown))
            else
                this.h_text_2.String=char(sprintf('CPU: %5.1f%%\nGun: %s\nCooldown: %3.1f', ...
                        mean(this.load)*100, ...,                
                        this.gun.get_ready_txt(), ...
                        this.gun.cooldown));
            end
        end

        this.gun.draw(this.fig, this.scale);                          
%        drawnow
        
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
    
    function update_LTI(~)
    % Update things on the fly... yikes!
    % For changes in PID parameters, T, ...
%         s=tf('s');
%         
%         %this.C_Kn = 1/this.T;
%         
%         fprintf('P=%.2f I=%.2f D=%.2f N=%.2f\n', ...
%             this.C_Kp, this.C_Ki, this.C_Kd, this.C_Kn);
%                 
%         % 1st order gun
%         this.G_Gun = dtf(this.speed/(this.tau*s+1), this.T);
% 
%         % Controller
%         this.G_C = dtf(this.C_Kp + this.C_Ki/s + ...
%             this.C_Kd*this.C_Kn*s/(s+this.C_Kn), this.T);
%         this.G_C.ctf
%         
%         % Integrator
%         this.G_I = dtf(1/s, this.T);   
%         
%         disp('ZEROS');
%         zero(feedback(this.G_C.ctf*this.G_Gun.ctf*this.G_I.ctf, 1))
%         disp('POLES');
%         pole(feedback(this.G_C.ctf*this.G_Gun.ctf*this.G_I.ctf, 1))
%     
%         this.hard_stop();                
    end
    
    function update_error_plot(this, axe)
        axes(axe);
        cla(axe);
        hold(axe, 'on');
        
        s=tf('s');
 
        % step error response
        impulse(axe, ...
                c2d(1/s, this.T) - ...
                c2d(1/s, this.T)*feedback(this.G_C.tf * this.G_Gun.tf * this.G_I.tf, 1));
        % ramp error response
        impulse(axe, ...
                c2d(1/s^2, this.T) - ...
                c2d(1/s^2, this.T)*feedback(this.G_C.tf * this.G_Gun.tf * this.G_I.tf, 1));
        %title('Manual response')
        
        title(axe, '');
        xlabel(axe, '');
        ylabel(axe, '');
        drawnow
    end    
    
    function update_response_plot(this, axe)        
        axes(axe);
        cla(axe);
        hold(axe, 'on');   
        
        % motor speed response
        step(axe, this.G_Gun.tf/this.speed); % normalized to unity        
        % controlled position response
        step(axe, feedback(this.G_C.tf * this.G_Gun.tf * this.G_I.tf, 1));
        axis auto
        
        title(axe, '');
        ylabel(axe, '');     
        drawnow
    end
    
    function update_siso_plot(this, axe)
        axes(axe);
        cla(axe);
        hold(axe, 'on');
        
        if numel(this.hist_vx) > 1
            X=(-numel(this.hist_vx)+1:0)' * this.T;
            plot(axe, ...
                 X, this.hist_vx/this.speed, ...
                 X, this.hist_Vr/this.Vr_max, ...
                 X, this.hist_Cr/this.Vr_max);
            axis([-this.max_hist_time 0 -1.05 1.05])
        end
        
        title(axe, '');
        xlabel(axe, '');
        ylabel(axe, '');
        drawnow
    end    
    
    function update_rlocus(this, axe, continuous)
        axes(axe);
        cla(axe);
        hold(axe, 'on');
        
        if continuous
            % r-locus:
            rlocus(axe, this.G_C.ctf * this.G_Gun.ctf * this.G_I.ctf);
            % poles/zeros:
            rlocus(axe, this.G_C.ctf, 'r', this.G_Gun.ctf * this.G_I.ctf, 'k', 0);
            % closed-loop poles:
            rlocus(axe, feedback(this.G_C.ctf * this.G_Gun.ctf * this.G_I.ctf, 1), 'g', 0);
        else
            % r-locus:
            rlocus(axe, this.G_C.tf * this.G_Gun.tf * this.G_I.tf);
            % poles/zeros:
            rlocus(axe, this.G_C.tf, 'r', this.G_Gun.tf * this.G_I.tf, 'k', 0);
            % closed-loop poles:
            rlocus(axe, feedback(this.G_C.tf * this.G_Gun.tf * this.G_I.tf, 1), 'g', 0);
        end
        
        title(axe, '');
    end
    
    function update_loop(this, loop)
        this.i_loop = loop;
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