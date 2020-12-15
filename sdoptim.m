function sdoptim()

    s=tf('s');

    G=3000/s/(s+6)/(s+12);

    function ts = eval(x)
        K = x(1);
        z = x(2);
    
        C    = K*(s+z);
        info = stepinfo(feedback(C*G, 1));
        ts   = info.SettlingTime;        
    end
        
    [x, fval, code] = fminsearch(@eval, [rand, rand*3])        

end