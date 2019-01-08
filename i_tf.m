%   Authors: Alejandro R. Mosteo, Danilo Tardioli, Eduardo Montijano
%   Copyright 2018-9999 Monmostar
%   Licensed under GPLv3 https://www.gnu.org/licenses/gpl-3.0.en.html
%
% Anything that can return a ideal S-TF

classdef(Abstract) i_tf < handle
    
methods(Abstract)
    
   stf = get_tf(this)        
    
end

    
end
    