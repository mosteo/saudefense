% A whole control loop, with input/output being position
% See loop_single & loop_piecewise for implementations

classdef(Abstract) i_loop < i_steppable
    
methods(Abstract)
    
    v = get_v(this)
    % the velocity output after last call to output (position)
    
    a = get_a(this)
    % The acceleration output
    
end
    
end