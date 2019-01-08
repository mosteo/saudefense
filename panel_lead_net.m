%   Authors: Alejandro R. Mosteo, Danilo Tardioli, Eduardo Montijano
%   Copyright 2018-9999 Monmostar
%   Licensed under GPLv3 https://www.gnu.org/licenses/gpl-3.0.en.html
%
classdef panel_lead_net < panel_3rows
    
properties
    visible_rows = 3
    
    label_A = 'gain (K)'
    label_B = 'zero (z)'
    label_C = 'pole (p)'
    label_footer = 'K(s+z)/(s+p)'
    
    init_A = '0.1'
    init_B = '6'
    init_C = '12'
end
    
methods    
    
    function stf = get_tf_from_ABC(~, K, z, p)
        net = controller_lead_net(K, z, p);
        stf = net.get_tf();
    end
    
end
    
end