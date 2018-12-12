% Class to encapsulate updates instead of drawing from scratch

classdef drawer < handle
    
properties
    h = []
end

methods   
    
    function bring_to_front(this)
        if ~isempty(this.h)
            uistack(this.h, 'top');
        end
    end
    
    function plot(this, axis, x, y, varargin)
        if isempty(this.h)
            this.h = plot(axis, x, y, varargin{:});
        else
            this.h.XData = x;
            this.h.YData = y;
            this.update(varargin{:});
        end
    end
    
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
    
    function show(this, visible)
        if nargin < 2
            visible = true;
        end
        
        if ~isempty(this.h)
            if visible
                this.h.Visible = 'On';
            else
                this.h.Visible = 'Off';
            end
        end
    end
    
    function update(this, varargin)       
        for i = 1:2:numel(varargin)
            this.h.(varargin{i}) = varargin{i+1};
        end
    end
    
end
    
end