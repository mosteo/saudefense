%   Authors: Alejandro R. Mosteo, Danilo Tardioli, Eduardo Montijano
%   Copyright 2018-9999 Monmostar
%   Licensed under GPLv3 https://www.gnu.org/licenses/gpl-3.0.en.html
%
classdef sdconst < handle
    
properties(Constant)                
    default_period = 0.05
    
    max_plot_ts = 10 % Max time to plot for steps
end

methods(Static)

    function str = onoff(bool)
        if bool
            str = 'on';
        else
            str = 'off';
        end
    end

end
    
end