% Root abstract class for TF implementations
% Check dtf for discrete (Z-space) impl
% Check ctf for continuous (state vector) impl

classdef(Abstract) i_tf < handle
    
properties    
    ctf     % continuous original TF
    period
end
    
methods(Access=public)
    
    function this = i_tf(ctf, period)    
        this.ctf    = ctf;
        this.period = period;
    end
    
end    

methods(Abstract)
    
    y = output(this, x)
        
    reset_state(this)

end
        
end