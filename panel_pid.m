classdef panel_pid < i_tfwidget
    
properties
    edit_kp
    edit_ki
    edit_kd
end
    
methods
    
    function prepare(this, panel)
        hei=0.25; %height of a row
        uicontrol('Parent', panel, 'Style', 'text','String','Kp', ...
            'Units', 'normalized', 'Position', [0, hei*3, 0.5, hei]);
        uicontrol('Parent', panel, 'Style', 'text','String','Ki', ...
            'Units', 'normalized', 'Position', [0, hei*2, 0.5, hei]);
        uicontrol('Parent', panel, 'Style', 'text','String','Kd', ...
            'Units', 'normalized', 'Position', [0, hei*1, 0.5, hei]);
        uicontrol('Parent', panel, 'Style', 'text','String','C(s) = Kp+Ki/s+Kd·s', ...
            'Units', 'normalized', 'Position', [0, hei*0, 1, hei*0.75]);
        
        this.edit_kp = uicontrol('Parent', panel, 'Style', 'edit','String','0.1', ...
            'Units', 'normalized', 'Position', [0.5, hei*3, 0.5, hei], ...
            'Callback', @sdfunc.common_callback);
        this.edit_ki = uicontrol('Parent', panel, 'Style', 'edit','String','0', ...
            'Units', 'normalized', 'Position', [0.5, hei*2, 0.5, hei], ...
            'Callback', @sdfunc.common_callback);
        this.edit_kd = uicontrol('Parent', panel, 'Style', 'edit','String','0', ...
            'Units', 'normalized', 'Position', [0.5, hei*1, 0.5, hei], ...
            'Callback', @sdfunc.common_callback);
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