%   Authors: Alejandro R. Mosteo, Danilo Tardioli, Eduardo Montijano
%   Copyright 2018-9999 Monmostar
%   Licensed under GPLv3 https://www.gnu.org/licenses/gpl-3.0.en.html
%
classdef controller_lead_net < i_tf    
% A lead network

properties    
    K, z, p    
end

methods
    
    function this = controller_lead_net(K, z, p)
        this.K = K;
        this.z = z;
        this.p = p;
    end
    
    function stf = get_tf(this)
        s=tf('s');
        stf = this.K*(s+this.z)/(s+this.p);
    end
    
end

end