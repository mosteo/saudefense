% base for a thing in the battlefield

classdef(Abstract) i_body < handle 
    
methods(Abstract)
    
    hit = check_hit(this, fx, fy, fa)
    % Check if hit by a laser fired at fx, fy, with angle fa
    
    draw(this, axis, scale)
    % Draw yourself
    
    done = update(this, period)
    % Update dynamics, with given elapsed time (period)
    % If done, it has ceased to ex ist
    
end

end