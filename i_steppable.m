classdef i_steppable < i_tf
    
methods(Abstract)
    
    y = output(this, x)
        
    reset_state(this)

end
    
end