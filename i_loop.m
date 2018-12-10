% Implements a whole control loop, with input/output being position

classdef(Abstract) i_loop < i_tf
    
methods(Abstract)
    
    v = get_v(this)
    % the velocity output after last call to output (position)
    
    a = get_a(this)
    % The acceleration output
    
end

methods
    
    function this = i_loop(G, H)
    % Closed-loop TF for the given direct and back tfs
    end    
    
end
    
end