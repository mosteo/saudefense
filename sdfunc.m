classdef sdfunc
% Contains our own GUI-related things, to isolate them somehow from
% the automatic callbacks created by Matlab
   
methods(Static)
    
    function common_callback(~, ~) % hObject, eventdata
        sdfunc.update_LTI(guidata(gcf));
    end

    function h = init(handles)        
        
        handles.initializing.Position = [0 0 1 1];
        %drawnow

        handles.props = props();

        % Control diagram
        axes(handles.diagram);
        diagram = imread('diagram2.jpg');
        dpos    = handles.diagram.Position;
        diagram = imresize(diagram, [dpos(4) dpos(3)]);
        imshow(diagram);
        
        % Initialize panels
        sdfunc.init_tfpanels(handles);

        % Get TFs
        [C, G] = sdfunc.gui_LTI_config(handles);        
        
        handles.props.sau = saudefense(handles.battle, ...
            loop_single(handles.props.tff, sdconst.default_period, C*G, 1));

        sau = handles.props.sau;

        sau.plot_hist = handles.do_siso.Value;
        
        handles.difficulty.Value = sau.difficulty;
        sdfunc.update_difficulty_panel(handles);

        handles.autoaim.Value = sau.auto_aim;
        handles.autofire.Value = sau.gun.autofire;

        handles.period.String = sprintf('%g', sau.T);

        sdfunc.update_LTI(handles);

        handles.start.Enable = 'on';
        handles.initializing.Visible = 'off';
        
%         hold(handles.siso, 'on');
%         axis(handles.siso, [-sau.max_hist_time 0 -sau.W/2, sau.W/2]);
        
        h = handles;
        disp('Ready');
    end
    
    function reset(h)
    % Reinitializes minimal things to start a new competition
        % Get TFs
        [C, G] = sdfunc.gui_LTI_config(h);        
        
        % Fresh SAU
        period = str2double(h.period.String);
        h.props.sau = saudefense(h.battle, ...
            loop_single(h.props.tff, period, C*G, 1));
        
        h.difficulty.Value = h.props.sau.difficulty;
    end
    
    function init_tfpanels(handles)
        % Clean previous
        delete(allchild(handles.p_controller));
        delete(allchild(handles.p_plant));        
        
        % Controller
        switch handles.pop_controller.Value
            case 1
                handles.props.widget_controller = panel_p();
            case 2
                handles.props.widget_controller = panel_pd();
            case 3
                handles.props.widget_controller = panel_pid();
            case 4
                handles.props.widget_controller = panel_pid_kzz();
            case 5
                handles.props.widget_controller = panel_lead_net();
            otherwise
                error('Unknown controller: %s', handles.pop_controller.Value)
        end
        handles.props.widget_controller.prepare(handles.p_controller);
                
        % Plant
        switch handles.pop_plant.Value
            case 1
                handles.props.widget_plant = panel_motor_mbk();
            case 2
                handles.props.widget_plant = panel_motor_1st();
            case 3
                handles.props.widget_plant = panel_motor_2nd();
            case 4
                handles.props.widget_plant = panel_motor_2nd_zpk();

            otherwise
                error('Unknown plant: %s', handles.pop_plant.Value)
        end
        handles.props.widget_plant.prepare(handles.p_plant);
        
    end
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function done = looper(h)      
        h.props.sau.tic()
        done = h.props.sau.iterate();

        sdfunc.update_difficulty_panel(h);
        sdfunc.update_texts(h, h.props.sau);    

        drawnow limitrate

        spare = h.props.sau.T - h.props.sau.toc();
        if spare > 0.001
            pause(spare);
%         else
%             fprintf(2,'falling behing!\n');
        end
    end        
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    function enable_all(h, enable)
        enabled = sdconst.onoff(enable);
        
        h.difficulty.Enable = enabled;
        h.pop_controller.Enable = enabled;
        h.pop_plant.Enable = enabled;
        
        for w=[allchild(h.p_controller); allchild(h.p_plant)]'
            if isprop(w, 'Enable')
                w.Enable = enabled;
            end
        end
    end

    function start_stop(h, compete)        
        h.props.running   = ~h.props.running;
        if h.props.running
            disp('Running...');
        else
            disp('Stopped.');
        end
        
        % Disable contrary
        if compete
            h.start.Enable = sdconst.onoff(~h.props.running);            
        else
            h.compete.Enable = sdconst.onoff(~h.props.running);
        end
                
        if h.props.running
            if compete
                h.compete.String = 'Pause';
                sdfunc.enable_all(h, false);
            else
                h.start.String = 'Pause';
                sdfunc.enable_all(h, true);
            end            
        else
            h.start.String = 'Test';
            h.compete.String = 'Competition';
            sdfunc.enable_all(h, true);
        end
        
        % Reset if competing for the first time after test
        if ~h.props.competing && h.props.running && compete
            sdfunc.reset(h);
            seed = mod(idivide(int64(round(now*100000)), int64(60), 'floor'), 10000);
            % Changes once per minute            
            rng(seed);
            h.text_seed.String = sprintf('Random seed: %d', seed);
        end
        
        if ~compete && h.props.running
            seed = mod(round(now*1000000), 10000);
            rng(seed);
            h.text_seed.String = sprintf('Random seed: %d', seed);
        end                        
        
        h.props.competing = compete;

        while h.props.running
            done = sdfunc.looper(h);
            
            if done && h.props.competing
                sdfunc.enable_all(h, true);
                msgbox({sprintf('Final score: %d points', h.props.sau.score), ...
                        sprintf('Time survived: %.2f seconds', ...
                            h.props.sau.iterations * h.props.sau.T)});                
                sdfunc.start_stop(h, true);
                h.props.competing = false;
                break
            end
        end
    end

    function [C, G] = gui_LTI_config(h)
        C = h.props.widget_controller.get_tf();
        G = h.props.widget_plant.get_tf();
    end
    
    function update_difficulty_panel(h)
        h.panel_difficulty.Title = ...
            sprintf('Difficulty: %5.3f', h.props.sau.difficulty);
        h.difficulty.Value = h.props.sau.difficulty;
    end

    function update_texts(h, sau)
        h.load.String = ...
            sprintf('CPU Load: %.0f%%', mean(sau.load)*100);
        if sau.load > 1
            h.load.ForegroundColor = [1 0 0];
        else
            h.load.ForegroundColor = [0 0 0];
        end

        h.cooldown.String = ...
            sprintf('Arming time (Tₛ): %.2f/%.2f', sau.gun.cooldown, sau.gun.ts);
        if sau.gun.cooldown > 0
            h.cooldown.ForegroundColor = [1 0 0];
        else
            h.cooldown.ForegroundColor = [0 0 0];
        end

        h.hits.String  = sprintf('Hits: %d', sau.hits);
        h.score.String = sprintf('Score: %d', sau.score);
        h.alive.String = sprintf('Alive: %.2f"', sau.iterations*sau.T);

        h.accel.String = ...
            sprintf('Acceleration: %5.3f', sau.gun.get_a());
        
        if abs(sau.gun.get_a()) > sau.gun.a_break
            h.accel.ForegroundColor = [1 0 0];
        elseif abs(sau.gun.get_a()) > sau.gun.a_arm
            h.accel.ForegroundColor = [1 0.5 0];
        else
            h.accel.ForegroundColor = [0 0 0];
        end
    end
    
    function update_error_plot(axe, C, G, tend)
        axes(axe);
        
        s=tf('s');
 
        % error responses
        [y1,t1] = step(feedback(1, C*G), tend);
        [y2,t2] = step(1/s/(1 + C*G), tend);
        plot(axe, t1, y1, 'b', t2, y2, 'r');
            
        %title('Manual response')
        
        title(axe, '');
        xlabel(axe, '');
        ylabel(axe, '');
        
        legend(axe, 'step error', 'ramp error', 'Location', 'northwest');
        %drawnow
    end    
    
    function update_response_plot(axe, C, G, tend)        
        axes(axe);
        cla(axe);
        hold(axe, 'on');
        
        % Use compensated as axis for when uncompensated is unstable
        [y2,t2] = step(feedback(C*G, 1), tend);
        plot(axe, t2, y2, 'b');
        ax = axis(axe);
        
        [y1,t1] = step(feedback(G, 1), tend);
        plot(axe, t1, y1, 'r');
        axis(axe, ax);
        
%         step(axe, feedback(G, 1), tplot, 'r');   % uncompensated         
%         step(axe, feedback(C*G, 1), tplot, 'b'); % compensated
        
        legend(axe, 'compensated', 'uncompensated', 'Location', 'southwest');
        
        title(axe, '');
        ylabel(axe, '');     
        %drawnow
    end
    
    function update_siso_plot(handles)               
        sau   = handles.props.sau;
        axe   = handles.siso;
        
        if numel(sau.hist_r) > 1
            X=(-numel(sau.hist_r)+1:0)' * sau.T;
            handles.props.h_r.plot(axe, X, sau.hist_r, 'Color', [1 0 0]);
            handles.props.h_y.plot(axe, X, sau.hist_y, 'Color', [0 0 1]);                 
%             axis(axe, [-sau.max_hist_time 0 -1.05 1.05])
        end
        
%         title(axe, '');
%         xlabel(axe, '');
%         ylabel(axe, '');
        % %drawnow
    end    
    
    function update_rlocus(axe, C, G, info) %#ok
        axes(axe);
        cla(axe);
        hold(axe, 'on');
        
        set(axe, 'DefaultLineMarkerSize', 10);
        set(axe, 'DefaultLineLineWidth', 2);
        
        % r-locus:
        rlocus(axe, C*G, 'b');

        % closed-loop poles:
        poles = pole(feedback(C*G, 1)) + 0.000001i;
        plot(axe, poles, 'rx'); % maybe faster
        %rlocus(axe, feedback(C*G, 1), 'r', 0);
        
        axis auto
        
        % Try to adjust around response time
%         if ~isnan(info.SettlingTime)
%             ranges    = axis(axe);
%             ranges(1) = -ceil(4/info.SettlingTime)*1.1;
%             ranges(2) = abs(ceil(max(real(poles))))*1.1;
%             axis(axe, ranges);
%         end
        
        h = zeros(2, 1);
        h(1) = plot(NaN,NaN,'xb');
        h(2) = plot(NaN,NaN,'xr');
        legend(h, 'open-loop C(s)·G(s)', 'closed-loop poles');
        
        title(axe, '');
        %drawnow
    end
    
    function update_LTI(h)        
        sdfunc.enable_all(h, false);
        h.start.Enable = 'off';
        h.compete.Enable = 'off';
        
        h.props.competing = false; % Since we just messed settings up...
        
        h.updating.String = 'Updating.';
        h.updating.Visible = 'on';
        drawnow

        [C, G] = sdfunc.gui_LTI_config(h);
        
        info = stepinfo(feedback(C*G, 1));
        if ~isnan(info.SettlingTime) % < sdconst.max_plot_ts            
            tend = ceil(info.SettlingTime+2);
            %tplot=0:0.5:ceil(info.SettlingTime+2);
        else
            tend = sdconst.max_plot_ts;                 
        end

        h.props.sau.update_LTI(h.props.tff, C, G);
        
        h.period.String = sprintf('%.3f', h.props.sau.T);
        % May have changed after sau.update_LTI

        % TODO: obtain C, G, from sau as it is being used (if discretized)

        sdfunc.update_response_plot(h.response, C, G, tend);
        h.updating.String = 'Updating..';
        sdfunc.update_error_plot(h.error, C, G, tend);
        h.updating.String = 'Updating...';
        sdfunc.update_rlocus(h.rlocus, C, G, info);

        h.updating.Visible = 'off';
        drawnow
        sdfunc.enable_all(h, ~h.props.competing);
        h.start.Enable   = sdconst.onoff(~h.props.running || ~h.props.competing);
        h.compete.Enable = sdconst.onoff(~h.props.running || h.props.competing);
    end

end
    
end