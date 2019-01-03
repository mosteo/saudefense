classdef panel_pid < i_tfwidget
    
properties
    edit_kp
    edit_ki
    edit_kd
end
    
methods
    
    function prepare(this, panel)
        uicontrol('Parent', panel, 'Style', 'text','String','Kp', ...
            'Units', 'normalized', 'Position', [0, 0.66, 0.5, 0.3]);
        uicontrol('Parent', panel, 'Style', 'text','String','Ki', ...
            'Units', 'normalized', 'Position', [0, 0.33, 0.5, 0.3]);
        uicontrol('Parent', panel, 'Style', 'text','String','Kd', ...
            'Units', 'normalized', 'Position', [0, 0, 0.5, 0.3]);
        
        this.edit_kp = uicontrol('Parent', panel, 'Style', 'edit','String','0.1', ...
            'Units', 'normalized', 'Position', [0.5, 0.66, 0.5, 0.3], ...
            'Callback', @sdfunc.common_callback);
        this.edit_ki = uicontrol('Parent', panel, 'Style', 'edit','String','0', ...
            'Units', 'normalized', 'Position', [0.5, 0.33, 0.5, 0.3]);
        this.edit_kd = uicontrol('Parent', panel, 'Style', 'edit','String','0', ...
            'Units', 'normalized', 'Position', [0.5, 0, 0.5, 0.3]);
    end
    
    
    function stf = get_tf(this)
        pid = controller_pid_ideal();
        pid.set_PID(str2double(this.edit_kp.String), ...
            str2double(this.edit_ki.String), ...
            str2double(this.edit_kd.String));
        stf = pid.get_tf();
    end
    
end
    
end