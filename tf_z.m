% A discretized transfer function
%   to be used in step-by-step fashion

classdef dtf < i_tf
    
properties(Access=public)
    state
    tf
end

methods(Access=public)
    
    function this = dtf(ctf, period)
        this@i_tf(ctf, period);
        this.tf    = c2d(ctf, period);
        this.state = zeros(numel(this.tf.den{1})-1, 1);
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