% A discretized transfer function
%   to be used in step-by-step fashion

classdef tf_ss < i_steppable
    
properties(Access=public)
    state
    stf
    sstf
    
    % Keep for derivatives
    x = 0;
    v = 0;
    a = 0;
end

methods(Access=public)
    
    function this = tf_ss(ctf, period)
        this.period= period;
        this.stf   = ctf;
        [A,B,C,D]  = tf2ss(cell2mat(ctf.Numerator), cell2mat(ctf.Denominator));
        this.sstf  = ss(A,B,C,D); 
        this.state = zeros(size(A,1), 1);
    end
    
    function dtf = get_discrete_tf(this)
        dtf = this.sstf;
    end
    
    function stf = get_tf(this)
        stf = this.stf;
    end
        
    function y = output(this, x)
        x_1 = this.x;
        v_1 = this.v;
        
        [Y,~,X]=lsim(this.sstf,x*[1 0],0:this.period:this.period,this.state);
        this.state = X(end,:);
        y = Y(end);
        
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