classdef loop_single < i_loop
    
properties
    stf, dtf    
    G, H
end
    
methods(Static)
    function this = loop_single(tff, T, G, H)
    % requires a tf factory and period 
    % requires direct and back continuous TFs   
    
        this.G = G;
        this.H = H;
    
        this.stf = feedback(G, H);
        this.dtf = tff(this.stf, T);
        
        this.period = T;
    
    end
end
    
methods
    
    function y = output(this, x)        
        y = this.dtf.output(x);
    end            
    
    function v = get_v(this)
    % the velocity output after last call to output (position)
        v = this.dtf.get_v();
    end
    
    function a = get_a(this)
    % The acceleration output
        a = this.dtf.get_a();
    end
    
    function stf = get_tf(this)
        stf = this.stf;
    end
    
    function dtf = get_discrete_tf(this)
        dtf = this.dtf;
    end
    
    function reset_state(this)
        this.dtf.reset_state();
    end
    
end
    
end