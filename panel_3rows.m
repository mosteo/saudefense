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

methods(Static)
    function Y = value(A)
        ME = MException('saudefense:panel_3rows', 'Format error');
        
        if strcmp(A, '')
            fprintf(2, 'Valor en blanco\n');
            opts = struct('WindowStyle','modal', 'Interpreter','none');
            errordlg(sprintf('Error: celda vacía'), ...
                'Error', opts);
            throw(ME);
        elseif contains(A, ',') || isnan(str2double(A))
            fprintf(2, 'Error en los valores introducidos\n');
            opts = struct('WindowStyle','modal', 'Interpreter','none');
            errordlg(sprintf('Formato de número incorrecto: %s', A), ...
                'Error', opts);
            throw(ME);
        end
        Y = str2double(A);
    end
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
        try
            if this.visible_rows >= 1
                A = this.value(this.edit_A.String);
            else
                A = this.value(this.init_A);
            end

            if this.visible_rows >= 2
                B = this.value(this.edit_B.String);
            else
                B = this.value(this.init_B);
            end

            if this.visible_rows >= 3
                C = this.value(this.edit_C.String);
            else
                C = this.value(this.init_C);
            end

            if isnan(A) || isnan(B) || isnan(C)
                fprintf(2, 'Error en los valores introducidos\n');
                opts = struct('WindowStyle','modal', 'Interpreter','none');
                errordlg('Formato de número incorrecto', 'Error', opts);
                stf = 0;
            else
                stf = this.get_tf_from_ABC(A, B, C);
            end
        catch
            stf = 0;
        end
    end
    
end
    
end