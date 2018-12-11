% Something that knows how to draw itself
% TODO: keep track of drawn piece and update instead of full erase?

classdef(Abstract) i_drawable < handle 
    
methods(Abstract)
    
    draw(this, axis, scale)
    % Draw yourself
    
end

end