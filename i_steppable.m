%   Authors: Alejandro R. Mosteo, Danilo Tardioli, Eduardo Montijano
%   Copyright 2018-9999 Monmostar
%   Licensed under GPLv3 https://www.gnu.org/licenses/gpl-3.0.en.html
%
% A discrete implementation of a TF, be it SS/Z/whatever based

classdef i_steppable < i_tf    
    
properties
    period
end
    
methods(Abstract)
    
    dtf = get_discrete_tf(this)
    
    y = output(this, x)
        
    reset_state(this)
    
    v = get_v(this)
    % 1st derivative after last call to output (position)
    
    a = get_a(this)
    % 2nd derivative after last call to output (position)

end
    
end