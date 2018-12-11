% A discretized transfer function
%   to be used in step-by-step fashion

classdef tf_z < i_steppable
    
properties(Access=public)
    state
    stf
    dtf
    
    % Keep for derivatives
    x = 0;
    v = 0;
    a = 0;
end

methods(Access=public)
    
    function this = tf_z(ctf, period)
        this.period= period;
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
        x_1 = this.x;
        v_1 = this.v;
        
        [y, this.state] = filter(this.dtf.num{1}', this.dtf.den{1}', x, this.state);
        
        this.x = y;
        this.v = (this.x - x_1)/this.period;
        this.a = (this.v - v_1)/this.period;
    end
    
    function v = get_v(this)
    	v = this.v;
    end
    
    function a = get_a(this)
        a = this.a;
    end
    
    function reset_state(this)
        this.state = this.state * 0;
    end
    
    function set_state(this, state)
        this.state = state;
    end
    
end

end