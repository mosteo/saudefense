%   Authors: Alejandro R. Mosteo, Danilo Tardioli, Eduardo Montijano
%   Copyright 2018-9999 Monmostar
%   Licensed under GPLv3 https://www.gnu.org/licenses/gpl-3.0.en.html
%
% A motor that has 1st order response

classdef motor_1st < i_tf
    
properties
    mu, tau
end
    
methods
    
    function this = motor_1st(mu, tau)
    % To use M and B:
    % mu=1/B, tau=M/B
        this.mu  = mu;
        this.tau = tau;
    end
    
    function ctf = get_tf(this)
        s = tf('s');
        ctf = this.mu/(this.tau*s + 1);
    end
    
end
    
end