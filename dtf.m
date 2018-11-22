% A discretized transfer function
%   to be used in step-by-step fashion

classdef dtf < handle
    
properties(Access=private)
    tf
    state
end

methods(Access=public)
    
    function this = dtf(ctf, period)
        this.tf    = c2d(ctf, period);
        this.state = zeros(numel(this.tf.den{1})-1, 1);
    end
    
    function y = output(this, x)
        [y, this.state] = filter(this.tf.num{1}', this.tf.den{1}', x, this.state);
    end
    
end

end