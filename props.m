classdef props < handle
% Ref class to avoid updating the handles every time

properties(Access=public)
   
    busy    = false % GUI is doing something
    looping = false % Timer callback is running
    closing = false % Window close has been requested
    pending = false % An update to the sau things is pending    
                    % It should be executed by the next timed call
    running = false % The simulation is active
    
    diff_changed = false % Difficulty was manually changed and must be updated
    difficulty   = 0.0   % New diff toset
    
end

methods(Static)
    function this = props
    end
end

end