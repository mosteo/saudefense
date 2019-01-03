classdef panel_pid_kzz < panel_3rows
    
properties
    visible_rows = 3
    
    label_A = 'gain (K)'
    label_B = '1st zero (z1)'
    label_C = '2nd zero (z2)'
    label_footer = 'K(s+z1)(s+z2)/s'
    
    init_A = '0.1'
    init_B = '10'
    init_C = '1'
end
    
methods    
    
    function stf = get_tf_from_ABC(~, A, B, C)
        pid = controller_pid_ideal();
        pid.set_KZZ(A, B, C);
        stf = pid.get_tf();
    end
    
end
    
end