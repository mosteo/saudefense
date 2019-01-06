classdef panel_motor_2nd_zpk < panel_3rows

properties   
    visible_rows = 3
    
    label_A = 'K'
    label_B = 'p1'
    label_C = 'p2'
    label_footer = 'G(s) = K/(s(s+p1)(s+p2))'
    
    init_A = '100000'
    init_B = '-10'
    init_C = '-20'
end
    
methods
        
    function stf = get_tf_from_ABC(~, A, B, C)
        s=tf('s');        
        stf = A/(s-B)/(s-C)/s;
    end
    
end
    
end