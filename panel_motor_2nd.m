%   Authors: Alejandro R. Mosteo, Danilo Tardioli, Eduardo Montijano
%   Copyright 2018-9999 Monmostar
%   Licensed under GPLv3 https://www.gnu.org/licenses/gpl-3.0.en.html
%
classdef panel_motor_2nd < panel_3rows

properties   
    visible_rows = 3
    
    label_A = 'μ'
    label_B = 'ζωₙ'
    label_C = 'ωₙ'
    label_footer = 'μωₙ²/(s(s²+2ζωₙs+ωₙ²))'
    
    init_A = '1'
    init_B = '10'
    init_C = '1'
end
    
methods
        
    function stf = get_tf_from_ABC(~, A, B, C)
        s=tf('s');
        motor = motor_2nd(A, 1/B, C);
        stf = motor.get_tf()/s;
    end
    
end
    
end