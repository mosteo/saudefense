% A motor that has 2nd order response (plus integrator!)

classdef motor_mbk < i_tf
    
properties    
    M, B, K
end

methods
    
    function this = motor_mbk(M, B, K)
    % NOTE: tau = 1/zwn
    % To provide M, B, K:
    % mu  = 1/K
    % tau = 2*M/B
    % wn  = sqrt(K/M)
        this.M = M;
        this.B = B;
        this.K = K;
    end
    
    function ctf = get_tf(this)
        s   = tf('s');
        if this.K > 0
            ctf = this.K/(this.M*s^2 + this.B*s + this.K);
        elseif this.B > 0
            ctf = this.B/(this.M*s^2 + this.B*s);
        else
            ctf = this.M/(this.M*s^2);
        end
    end
    
end
    
end