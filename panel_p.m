%   Authors: Alejandro R. Mosteo, Danilo Tardioli, Eduardo Montijano
%   Copyright 2018-9999 Monmostar
%   Licensed under GPLv3 https://www.gnu.org/licenses/gpl-3.0.en.html
%
classdef panel_p < panel_3rows

properties   
    visible_rows = 1
    
    label_A = 'gain (K)'
    label_B = 'unused'
    label_C = 'unused'
    label_footer = 'C(s) = K'
    
    init_A = '0.075'
    init_B = '0'
    init_C = '0'
end
    
methods
        
    function stf = get_tf_from_ABC(~, A, ~, ~)
        stf = A;
    end
    
end
    
end