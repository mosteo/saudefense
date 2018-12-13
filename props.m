classdef props < handle
% Ref class to avoid updating the handles every time

properties(Access=public)
   
    busy    = false % GUI is doing something
    closing = false % Window close has been requested
    pending = false % An update from the GUI for saudefense LTI is pending    
                    % It should be applied at the next timed call
    running = false % The simulation is active
    
    diff_changed = false % Difficulty was manually changed and must be updated
    difficulty   = 0.0   % New diff to set
    
end

methods(Static)
    function this = props
    end
end

end