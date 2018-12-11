classdef loop_single < i_loop
    
properties
    stf, dtf
end
    
methods(Static)
    function this = loop_single(tff, T, G, H)
    % requires a tf factory and period 
    % requires direct and back continuous TFs                
    
        this.stf = feedback(G, H);
        this.dtf = tff(this.stf, T);
    
    end
end
    
methods
    
    function y = output(this, x)
        y = 0;
    end            
    
    function v = get_v(this)
    % the velocity output after last call to output (position)
        v = 0;
    end
    
    function a = get_a(this)
    % The acceleration output
        a = 0;
    end
    
    function stf = get_tf(this)
        stf = this.stf;
    end
    
    function dtf = get_discrete_tf(this)
        dtf = this.dtf;
    end
    
    function reset_state(this)
    end
    
end
    
end