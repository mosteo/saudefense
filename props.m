classdef props < handle
% Ref class to avoid updating the handles every time

properties(Access=public)  
    running % Simulation is running
    
    h_r
    h_y  % Drawers for history
    
    tff = @tf_factory.ss;    
end

methods(Static)
    function this = props
        this.h_r = drawer();
        this.h_y = drawer();
    end
end

end