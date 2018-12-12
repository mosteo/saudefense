% Class to encapsulate updates instead of drawing from scratch

classdef drawer < handle
    
properties
    h = []
end

methods        
    
    function text(this, axis, x, y, txt, varargin)
        if isempty(this.h)
            this.h = text(axis, x, y, txt, varargin{:});
        else
            this.h.Position(1) = x;
            this.h.Position(2) = y;
            this.h.String = txt;
            this.update(varargin{:});
        end
    end
    
    function update(this, varargin)       
        for i = 1:2:numel(varargin)
            this.h.(varargin{i}) = varargin{i+1};
        end
    end
    
end
    
end