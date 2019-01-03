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