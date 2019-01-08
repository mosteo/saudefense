%   Authors: Alejandro R. Mosteo, Danilo Tardioli, Eduardo Montijano
%   Copyright 2018-9999 Monmostar
%   Licensed under GPLv3 https://www.gnu.org/licenses/gpl-3.0.en.html
%
classdef controller_pid_ideal < i_tf
% An ideal PID (improper)
    
properties
    
    Kp, Ki, Kd   
    K, z1, z2   % The two views of the controller
                % z1 is the D zero (NaN if no Kd)
                % Z2 is the I zero (NaN if no Ki)
    
    stf

end
    
methods
    
    function this = controller_pid_ideal()
        % Expects a TF factory function
        % Return an empty PID, see other functions to set values
    end
    
    function set_PID(this, Kp, Ki, Kd)
       this.Kp = Kp;
       this.Ki = Ki;
       this.Kd = Kd;
       
       if Kp == 0
           error('Kp cannot be zero')
           % It can be, but let's pretend it can't for now
       end
       
       if Ki == 0 && Kd ~= 0 % Just a zero
           this.K  = this.Kd;
           this.z1 = this.Kp/this.Kd;
           this.z2 = NaN;
       end
       
       if Kd == 0 && Ki ~= 0 % A zero and integrator
           this.K  = this.Kp;
           this.z2 = this.Ki/this.Kp;
           this.z1 = NaN;
       end
       
       if Kd == 0 && Ki == 0
           this.K  = Kp;
           this.z1 = NaN;
           this.z2 = NaN;
       end
       
       if Ki ~= 0 && Kd ~= 0
           this.K  = Kd;
           r       = roots([Kd Kp Ki]);
           this.z1 = -r(1);
           this.z2 = -r(2);
       end
       
       this.update_tf;
    end
    
    function set_KZZ(this, K, z1, z2)
    % This does not allow to specify only a PI
        this.K  = K;
        this.z1 = z1;
        this.z2 = z2;
        
        this.Kp = K*(z1 + z2);
        this.Ki = K*z1*z2;
        this.Kd = K;
        
        this.update_tf;
    end
    
    function tf = get_tf(this)
        tf = this.stf;
    end

end

methods(Access=private)
    
    function update_tf(this)
        s = tf('s');
        this.stf = this.Kp + this.Kd*s + this.Ki/s;
    end
    
end
    
end