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
        
        handles.sau = saudefense(handles.battle, ...
            loop_single(handles.props.tff, 0.05, C*G, 1));

        sau = handles.sau;

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
            otherwise
                error('Unknown plant: %s', handles.pop_plant.Value)
        end
        handles.props.widget_plant.prepare(handles.p_plant);
        
    end
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function looper(h)      
        h.sau.tic()
        h.sau.iterate();

%         if h.do_siso.Value
%             sdfunc.update_siso_plot(h);
%         end

        sdfunc.update_difficulty_panel(h);
        sdfunc.update_texts(h, h.sau);    

        drawnow limitrate

        spare = h.sau.T - h.sau.toc();
        if spare > 0.001
            pause(spare);
%         else
%             fprintf(2,'falling behing!\n');
        end
    end        
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    function [C, G] = gui_LTI_config(h)
        C = h.props.widget_controller.get_tf();
        G = h.props.widget_plant.get_tf();
    end
    
    function update_difficulty_panel(h)
        h.panel_difficulty.Title = ...
            sprintf('Difficulty: %5.3f', h.sau.difficulty);
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
        
        legend(axe, 'step error', 'ramp error', 'Location', 'northwest');
        %drawnow
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
        
        legend(axe, 'uncompensated', 'compensated', 'Location', 'southwest');
        
        title(axe, '');
        ylabel(axe, '');     
        %drawnow
    end
    
    function update_siso_plot(handles)               
        sau   = handles.sau;
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
    
    function update_rlocus(axe, C, G)
        axes(axe);
        cla(axe);
        hold(axe, 'on');
        
        set(axe, 'DefaultLineMarkerSize', 10);
        set(axe, 'DefaultLineLineWidth', 2);
        
        % r-locus:
        rlocus(axe, C*G, 'b');

        % closed-loop poles:
        rlocus(axe, feedback(C*G, 1), 'r', 0);
        
        h = zeros(2, 1);
        h(1) = plot(NaN,NaN,'xb');
        h(2) = plot(NaN,NaN,'xr');
        legend(h, 'open-loop C(s)·G(s)', 'closed-loop poles');
        
        title(axe, '');
        %drawnow
    end
    
    function update_LTI(h)        
        h.updating.Visible = 'on';
        drawnow

        [C, G] = sdfunc.gui_LTI_config(h);

        h.sau.update_LTI(h.props.tff, C, G);
        
        % TODO: obtain C, G, from sau as it is being used (if discretized)

        sdfunc.update_response_plot(h.response, C, G);
        sdfunc.update_error_plot(h.error, C, G);
        sdfunc.update_rlocus(h.rlocus, C, G);

        h.updating.Visible = 'off';
        drawnow
    end

end
    
end