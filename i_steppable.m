% A discrete implementation of a TF, be it SS/Z/whatever based

classdef i_steppable < i_tf    
    
methods(Abstract)
    
    dtf = get_discrete_tf(this)
    
    y = output(this, x)
        
    reset_state(this)

end
    
end