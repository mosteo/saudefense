classdef props < handle
% Ref class to avoid updating the handles every time

properties(Access=public)  
    competing = false % SET TO TRUE TO AVOID STUDENTS CHANGING CERTAIN THINGS
    % Currently: no effect
    
    running = false % Simulation is running
    
    sau     % of class saudefense
    
    widget_controller
    widget_plant        % Widgets of class i_tfwidget
    
    h_r
    h_y  % Drawers for history
    
    tff = @tf_factory.ss;    
end

methods(Static)
    function this = props
        this.h_r = drawer();
        this.h_y = drawer();
    end
end

end