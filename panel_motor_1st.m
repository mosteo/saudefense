classdef panel_motor_1st < panel_3rows

properties   
    visible_rows = 2
    
    label_A = 'μ'
    label_B = 'τ'
    label_C = 'unused'
    label_footer = 'μ/(s(τs + 1))'
    
    init_A = '10'
    init_B = '0.1'
    init_C = '0'
end
    
methods
        
    function stf = get_tf_from_ABC(~, A, B, ~)
        s=tf('s');
        motor = motor_1st(A, B);
        stf = motor.get_tf()/s;
    end
    
end
    
end