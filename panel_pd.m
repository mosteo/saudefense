

classdef panel_pd < panel_3rows
    
properties
    visible_rows = 2
    
    label_A = 'gain (K)'
    label_B = 'zero (z)'
    label_C = 'XXX'
    label_footer = 'C(s) = K·(s + z)'
    
    init_A = '0.1'
    init_B = '10'
    init_C = '0'
end
    
methods    
    
    function stf = get_tf_from_ABC(~, K, z, ~)
        s=tf('s');
        stf = K*(s + z);
    end
    
end
    
end