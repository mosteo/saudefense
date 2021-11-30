%   Authors: Alejandro R. Mosteo, Danilo Tardioli, Eduardo Montijano
%   Copyright 2018-9999 Monmostar
%   Licensed under GPLv3 https://www.gnu.org/licenses/gpl-3.0.en.html
%
classdef props < handle
% Ref class to avoid updating the handles every time

properties(Access=public)  
    cmd_line  = false
    % When true, we disable all panels to configure controller/plant and
    % rely on the C, G passed to sdgui: sdgui(C, G)
    
    arg_C, arg_G
    % When cmd_line, we store here the parameters received
    
    competing = false % SET TO TRUE TO AVOID STUDENTS CHANGING CERTAIN THINGS
    % Currently: no effect
    
    running = false % Simulation is running
    
    sau     % of class saudefense
    
    widget_controller
    widget_plant        % Widgets of class i_tfwidget
    
    h_r
    h_y  % Drawers for history
    
    tff = @tf_factory.ss;    
    
    league = true 
    % When league, plant is fixed and always disabled, so final scores can
    % be submitted with guarantees
end

methods(Static)
    function this = props
        this.h_r = drawer();
        this.h_y = drawer();
    end
end

end