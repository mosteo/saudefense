% base for a thing in the battlefield

classdef(Abstract) i_killable < handle 
    
methods(Abstract)
    
    hit = check_hit(this, fx, fy, fa)
    % Check if hit by a laser fired at fx, fy, with angle fa   
    
    die(this)
    % Actually die
    
    % TODO: migrate to polyshapes when R2017b+
    
    points = score(this)
    % How much for killing it now
    
end

end