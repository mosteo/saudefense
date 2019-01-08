%   Authors: Alejandro R. Mosteo, Danilo Tardioli, Eduardo Montijano
%   Copyright 2018-9999 Monmostar
%   Licensed under GPLv3 https://www.gnu.org/licenses/gpl-3.0.en.html
%
% base for a thing in the battlefield

classdef(Abstract) i_killable < handle 
    
properties
    id % unique id so change of target is easier to keep track of
end
    
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