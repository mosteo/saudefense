classdef sdconst < handle
    
    properties(Constant)                
        
    end
    
    methods(Access=public)
        
        function str = onoff(bool)
            if bool
                str = 'ON';
            else
                str = 'off';
            end
        end
        
    end
    
end