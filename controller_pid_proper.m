%   Authors: Alejandro R. Mosteo, Danilo Tardioli, Eduardo Montijano
%   Copyright 2018-9999 Monmostar
%   Licensed under GPLv3 https://www.gnu.org/licenses/gpl-3.0.en.html
%
classdef controller_pid_proper < controller_pid_ideal
% A PID with high freq filter

properties
    
    N % Frequency of filter (rad/s) (position of hifreq pole)
    
end

methods
    
    function set_filter_freq(this, N)
    end
    
end

end