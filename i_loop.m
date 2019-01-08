%   Authors: Alejandro R. Mosteo, Danilo Tardioli, Eduardo Montijano
%   Copyright 2018-9999 Monmostar
%   Licensed under GPLv3 https://www.gnu.org/licenses/gpl-3.0.en.html
%
% A whole control loop, with input/output being position
% See loop_single & loop_piecewise for implementations

classdef(Abstract) i_loop < i_steppable
    
properties(Abstract)
    G   % Forward path TF
    H   % Feedback path TF
end
    
end