%   Authors: Alejandro R. Mosteo, Danilo Tardioli, Eduardo Montijano
%   Copyright 2018-9999 Monmostar
%   Licensed under GPLv3 https://www.gnu.org/licenses/gpl-3.0.en.html
%
% Static methods to create {z/ss}-TFs from a s-tf

classdef tf_factory < handle
    
methods(Static)
    
    function tf = z(ctf, period)
    % Obtain a z-transformed tf
    
        tf = tf_z(ctf, period);
    end
    
    function tf = ss(ctf, period)
    % Obtain a ss-transformed tf        
        tf = tf_ss(ctf, period);
    end
    
end
    
end