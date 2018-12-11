% A discretized transfer function
%   to be used in step-by-step fashion

classdef tf_z < i_steppable
    
properties(Access=public)
    state
    stf
    dtf
end

methods(Access=public)
    
    function this = tf_z(ctf, period)
        this.stf   = ctf;
        this.dtf   = c2d(ctf, period);
        this.state = zeros(numel(this.dtf.den{1})-1, 1);
    end
    
    function stf = get_tf(this)
        stf = this.stf;
    end
    
    function dtf = get_discrete_tf(this)
        dtf = this.dtf;
    end
    
    function y = output(this, x)
        [y, this.state] = filter(this.tf.num{1}', this.tf.den{1}', x, this.state);
    end
    
    function reset_state(this)
        this.state = this.state * 0;
    end
    
    function set_state(this, state)
        this.state = state;
    end
    
end

end