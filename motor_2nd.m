% A motor that has 2nd order response

classdef motor_2nd < i_tf
    
properties    
    mu, tau, wn
end

methods
    
    function this = motor_2nd(mu, tau, wn)
    % NOTE: tau = 1/zwn
    % To provide M, B, K:
    % mu  = 1/K
    % tau = 2*M/B
    % wn  = sqrt(K/M)
        this.mu = mu;
        this.tau = tau;
        this.wn = wn;
    end
    
    function ctf = get_tf(this)
        s   = tf('s');
        ctf = this.mu*this.wn^2/(s^2 + 2*s/this.tau + this.wn^2);
    end
    
end
    
end