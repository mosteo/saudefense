% Something that knows how to draw itself
% TODO: keep track of drawn piece and update instead of full erase?  

%   Authors: Alejandro R. Mosteo, Danilo Tardioli, Eduardo Montijano
%   Copyright 2018-9999 Monmostar
%   Licensed under GPLv3 https://www.gnu.org/licenses/gpl-3.0.en.html

classdef(Abstract) i_drawable < handle   
    
methods(Abstract)
    
    draw(this, axis, scale)
    % Draw yourself
    
end

end