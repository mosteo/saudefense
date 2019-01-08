%   Authors: Alejandro R. Mosteo, Danilo Tardioli, Eduardo Montijano
%   Copyright 2018-9999 Monmostar
%   Licensed under GPLv3 https://www.gnu.org/licenses/gpl-3.0.en.html
%
classdef panel_motor_mbk < panel_3rows

properties  
    visible_rows = 3
    
    label_A = 'M'
    label_B = 'B'
    label_C = 'K'
    label_footer = 'K/(Ms² + Bs + K)'
    
    init_A = '1'
    init_B = '1'
    init_C = '1'
end
    
methods
        
    function stf = get_tf_from_ABC(~, A, B, C)
        motor = motor_mbk(A, B, C);
        stf = motor.get_tf();
    end
    
end
    
end