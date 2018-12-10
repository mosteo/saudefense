% Anything that can return a ideal S-TF

classdef(Abstract) i_tf_generator < handle
    
methods(Abstract)
    
   tf = get_tf(this)        
    
end

    
end
    