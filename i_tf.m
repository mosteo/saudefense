% Anything that can return a ideal S-TF

classdef(Abstract) i_tf < handle
    
methods(Abstract)
    
   stf = get_tf(this)        
    
end

    
end
    