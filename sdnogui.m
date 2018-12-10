% Script to test saudefense without the gui

function sdnogui(T, C, G)   
    if nargin < 1
        T = 0.05;
    end
    
    if nargin < 2
        PID = controller_pid_ideal;
        PID.set_PID(0.4, 0, 0); 
        C = PID.get_tf;
    end
    
    if nargin < 3
    end
    
    tff = @tf_factory.z;           
    
    %G = motor_1st(tff, 10, 0.1);
    
    %loop = loop_z(C.ctf, G.ctf);

    figure(33);
    sau = saudefense(gca);
    %sau.update_loop(loop);
    
end
