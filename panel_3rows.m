classdef panel_3rows < i_tfwidget
    
properties
    edit_A      % The three values that can be edited
    edit_B
    edit_C
end

properties(Abstract)
    % Properties that must be supplied and initialized in inheritors
    visible_rows % How many of the three to be used (1-3)
    
    label_A % The three textual labels
    label_B
    label_C
    label_footer % and the explanation
    
    init_A % Default A, B, C values (strings)
    init_B
    init_C
end

methods(Abstract)
    stf = get_tf_from_ABC(this, A, B, C)
end
    
methods
    
    function prepare(this, panel)
        hei=0.25; %height of a row
        
        if this.visible_rows >= 1
            uicontrol('Parent', panel, 'Style', 'text','String', {'', this.label_A }, ...
                'Units', 'normalized', 'Position', [0, hei*3, 0.5, hei]);
        end
        if this.visible_rows >= 2
            uicontrol('Parent', panel, 'Style', 'text','String', {'',this.label_B}, ...
                'Units', 'normalized', 'Position', [0, hei*2, 0.5, hei]);
        end
        if this.visible_rows >= 3
            uicontrol('Parent', panel, 'Style', 'text','String', {'',this.label_C}, ...
                'Units', 'normalized', 'Position', [0, hei*1, 0.5, hei]);
        end
        uicontrol('Parent', panel, 'Style', 'text','String', {'',this.label_footer}, ...
            'Units', 'normalized', 'Position', [0, hei*0, 1, hei*1.1]);
        
        if this.visible_rows >= 1
            this.edit_A = uicontrol('Parent', panel, 'Style', 'edit','String',this.init_A, ...
                'Units', 'normalized', 'Position', [0.5, hei*3, 0.5, hei], ...
                'Callback', @sdfunc.common_callback);
        end
        if this.visible_rows >= 2
            this.edit_B = uicontrol('Parent', panel, 'Style', 'edit','String',this.init_B, ...
                'Units', 'normalized', 'Position', [0.5, hei*2, 0.5, hei], ...
                'Callback', @sdfunc.common_callback);
        end
        if this.visible_rows >= 3
            this.edit_C = uicontrol('Parent', panel, 'Style', 'edit','String',this.init_C, ...
                'Units', 'normalized', 'Position', [0.5, hei*1, 0.5, hei], ...
                'Callback', @sdfunc.common_callback);
        end
    end
    
    
    function stf = get_tf(this)
        if this.visible_rows >= 1
            A = str2double(this.edit_A.String);
        else
            A = str2double(this.init_A);
        end
        
        if this.visible_rows >= 2
            B = str2double(this.edit_B.String);
        else
            B = str2double(this.init_B);
        end
        
        if this.visible_rows >= 3
            C = str2double(this.edit_C.String);
        else
            C = str2double(this.init_C);
        end
        
        stf = this.get_tf_from_ABC(A, B, C);
    end
    
end
    
end