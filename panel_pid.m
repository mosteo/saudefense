%   Authors: Alejandro R. Mosteo, Danilo Tardioli, Eduardo Montijano
%   Copyright 2018-9999 Monmostar
%   Licensed under GPLv3 https://www.gnu.org/licenses/gpl-3.0.en.html
%
classdef panel_pid < panel_3rows
    
properties
    visible_rows = 3
    
    label_A = 'Kp'
    label_B = 'Ki'
    label_C = 'Kd'
    label_footer = 'Kp + Ki/s + Kd·s'
    
    init_A = '0.1'
    init_B = '0'
    init_C = '0'
end
    
methods    
    
    function stf = get_tf_from_ABC(~, A, B, C)
        pid = controller_pid_ideal();
        pid.set_PID(A, B, C);
        stf = pid.get_tf();
    end
    
end
    
end