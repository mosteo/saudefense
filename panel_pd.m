classdef panel_pd < i_tfwidget
    
properties
    edit_k
    edit_z
end
    
methods
    
    function prepare(this, panel)
        uicontrol('Parent', panel, 'Style', 'text','String','Gain (K)', ...
            'Units', 'normalized', 'Position', [0, 0.66, 0.5, 0.3]);
        uicontrol('Parent', panel, 'Style', 'text','String','Zero (z)', ...
            'Units', 'normalized', 'Position', [0, 0.33, 0.5, 0.3]);
        uicontrol('Parent', panel, 'Style', 'text','String','C(s) = K(s+z)', ...
            'Units', 'normalized', 'Position', [0, 0, 1, 0.25]);
        
        this.edit_k = uicontrol('Parent', panel, 'Style', 'edit','String','0.1', ...
            'Units', 'normalized', 'Position', [0.5, 0.66, 0.5, 0.3], ...
            'Callback', @sdfunc.common_callback);
        this.edit_z = uicontrol('Parent', panel, 'Style', 'edit','String','0', ...
            'Units', 'normalized', 'Position', [0.5, 0.33, 0.5, 0.3], ...
            'Callback', @sdfunc.common_callback);
    end
    
    
    function stf = get_tf(this)
        s = tf('s');
        k = str2double(this.edit_k.String);
        z = str2double(this.edit_z.String);
        stf = k*(s + z);
    end
    
end
    
end