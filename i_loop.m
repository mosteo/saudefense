% A whole control loop, with input/output being position
% See loop_single & loop_piecewise for implementations

classdef(Abstract) i_loop < i_steppable
    
properties(Abstract)
    G   % Forward path TF
    H   % Feedback path TF
end
    
end