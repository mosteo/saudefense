classdef sdconst < handle
    
properties(Constant)                
    default_period = 0.05
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