%   Authors: Alejandro R. Mosteo, Danilo Tardioli, Eduardo Montijano
%   Copyright 2018-9999 Monmostar
%   Licensed under GPLv3 https://www.gnu.org/licenses/gpl-3.0.en.html
%
% base for a thing that moves

classdef(Abstract) i_body < handle 
    
properties
    x, y    % At a minimum it exists in the world
end
    
methods(Abstract)
    
    done = update(this, period)
    % Update dynamics, with given elapsed time (period)
    % If done, it has ceased to exist
    
end

end