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
        motor = motor_1st(10, 0.1);
        G = motor.get_tf;
    end
    
    tff = @tf_factory.z;                   
    
    loop = loop_single(tff, T, C*G, 1);

    figure(33);
    sau = saudefense(gca, loop);
    sau.forever;
    
end
