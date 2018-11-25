classdef sdfunc
   
    methods(Static)
        
        function update_difficulty_panel(h)
            h.panel_difficulty.Title = ...
                sprintf('Difficulty: %5.3f', h.difficulty.Value);
        end
        
        function update_texts(h, sau)
            h.load.String = ...
                sprintf('CPU Load: %5.1f%%', mean(sau.load)*100);
            h.cooldown.String = ...
                sprintf('Cooldown: %3.1f', sau.cooldown);
            h.hits.String = ...
                sprintf('Hits: %d', sau.hits);
            h.accel.String = ...
                sprintf('Acceleration: %5.3f', sau.ax);
            if abs(sau.ax) > sau.a_arm
                h.accel.ForegroundColor = [1 0 0];
            else
                h.accel.ForegroundColor = [0 0 0];
            end
        end
        
    end
    
end