% Root abstract class for TF implementations
% Check tf_z for discrete (Z-space) impl
% Check tf_ss for continuous (state vector) impl

classdef i_tf < i_tf_generator
    
properties    
    ctf     % continuous original TF
    tf      % whatever TF it actually uses (Z, SS, S...)
    period
end   

methods(Access=public)
    
    function this = i_tf(ctf, period)    
        this.ctf    = ctf;
        this.period = period;
    end
    
    function set_tf_impl(this, tf)
        this.tf = tf;
    end
    
    function tf = get_tf_impl(this)
        tf = this.tf;
    end
    
    function tf = get_tf(this)
        tf = this.ctf;
    end
    
end    
        
end