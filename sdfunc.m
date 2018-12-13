classdef sdfunc
% Contains our own GUI-related things, to isolate them somehow from
% the automatic callbacks created by Matlab
   
methods(Static)

    function h = init(handles)        
        handles.initializing.Position = [0 0 1 1];
        drawnow

        handles.props = props;
        handles.props.busy = true;

        axes(handles.diagram);
        diagram = imread('diagram.jpg');
        dpos    = handles.diagram.Position;
        diagram = imresize(diagram, [dpos(4) dpos(3)]);
        imshow(diagram);

        [C, G] = sdfunc.gui_LTI_config(handles);        
        
        handles.sau = saudefense(handles.battle, ...
            loop_single(@tf_factory.ss, 0.05, C*G, 1));
        sau = handles.sau;

        handles.closing = false; % True after figure starts closing

        handles.difficulty.Value = sau.difficulty;
        sdfunc.update_difficulty_panel(handles);

        handles.looper = timer;
        handles.looper.ExecutionMode = 'fixedRate';
        handles.looper.Period = handles.sau.T;
        handles.looper.UserData = handles.sau;
        handles.looper.TimerFcn = @(~,~)sdfunc.looper(handles);
        handles.looper.StartDelay = 0.2;

        handles.autoaim.Value = sau.auto_aim;
        handles.autofire.Value = sau.gun.autofire;

        handles.period.String = sprintf('%g', sau.T);

        sdfunc.update_LTI(handles);

        handles.props.busy   = false;
        handles.start.Enable = 'on';
        handles.initializing.Visible = 'off';
        
        h = handles;
        disp('Ready');
    end
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function looper(handles)
        if handles.props.pending
            handles.props.pending = false;
            sdfunc.update_LTI(handles, true);
        end
        
        if ~handles.props.closing && ~handles.props.busy            
            if handles.props.diff_changed
                handles.sau.difficulty = handles.props.difficulty;
                handles.props.diff_changed = false;
            else
                handles.difficulty.Value = handles.sau.difficulty;
            end
            sdfunc.update_difficulty_panel(handles);

            handles.sau.tic()
            handles.sau.iterate();

            if handles.siso_enabled.Value
                handles.sau.update_siso_plot(handles.siso);
            end
            
            sdfunc.update_texts(handles, handles.sau);    
            
            handles.sau.toc()
        end
    end        
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    function [C, G] = gui_LTI_config(h)
        tau   = str2double(h.tau.String);
        motor = motor_1st(10, tau);

        Kp = str2double(h.Kp.String);
        Ki = str2double(h.Ki.String);
        Kd = str2double(h.Kd.String);
        PID = controller_pid_ideal();
        PID.set_PID(Kp, Ki, Kd);
        
        C = PID.get_tf();
        G = motor.get_tf();
    end
    
    function update_difficulty_panel(h)
        h.panel_difficulty.Title = ...
            sprintf('Difficulty: %5.3f', h.props.difficulty);
    end

    function update_texts(h, sau)
        h.load.String = ...
            sprintf('CPU Load: %3.0f%%', mean(sau.load)*100);
        if sau.load > 1
            h.load.ForegroundColor = [1 0 0];
        else
            h.load.ForegroundColor = [0 0 0];
        end

        h.cooldown.String = ...
            sprintf('Cooldown: %3.1f', sau.gun.cooldown);
        if sau.gun.cooldown > 0
            h.cooldown.ForegroundColor = [1 0 0];
        else
            h.cooldown.ForegroundColor = [0 0 0];
        end

        h.hits.String = ...
            sprintf('Hits: %d', sau.hits);

        h.accel.String = ...
            sprintf('Acceleration: %5.3f', sau.gun.get_a());
        if abs(sau.gun.get_a()) > sau.gun.a_arm
            h.accel.ForegroundColor = [1 0 0];
        else
            h.accel.ForegroundColor = [0 0 0];
        end
    end
    
    function update_error_plot(axe, C, G)
        axes(axe);
        cla(axe);
        hold(axe, 'on');
        
        s=tf('s');
 
        % step error response
        step(axe, feedback(1, C*G), 'b');
        
        % ramp error response
        step(axe, 1/s/(1 + C*G), 'r');
            
        %title('Manual response')
        
        title(axe, '');
        xlabel(axe, '');
        ylabel(axe, '');
        drawnow
    end    
    
    function update_response_plot(axe, C, G)        
        axes(axe);
        cla(axe);
        hold(axe, 'on');   
        
        % motor position response
        step(axe, feedback(G, 1), 'r');
        
        % controlled position response
        step(axe, feedback(C*G, 1), 'b');
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
    
    function update_rlocus(axe, C, G)
        axes(axe);
        cla(axe);
        hold(axe, 'on');
        
        % r-locus:
        rlocus(axe, C*G);

        % closed-loop poles:
        rlocus(axe, feedback(C*G, 1), 'r', 0);
        
        title(axe, '');
        drawnow
    end
    
    function update_LTI(h, force)
        if nargin < 2
            force = false;
        end
        if h.props.running && ~force
            h.props.pending = true;
            return
        end

        h.updating.Visible = 'on';
        drawnow

        [C, G] = sdfunc.gui_LTI_config(h);

        h.sau.update_LTI(C, G);
        
        % TODO: obtain C, G, from sau as it is being used (if discretized)

        sdfunc.update_response_plot(h.response, C, G);
        sdfunc.update_error_plot(h.error, C, G);
        sdfunc.update_rlocus(h.rlocus, C, G);

        h.updating.Visible = 'off';
        drawnow
    end

end
    
end