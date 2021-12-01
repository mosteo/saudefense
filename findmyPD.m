function [C, zc, ang_zc] = findmyPD(fdt, obj)

% FINDMYPD : dada una FdT y un punto del plano complejo,
% halla la posición del cero necesario en el controlador, 
% dibujando el lugar original y el lugar correspondiente a C(S)G(S)
%
%   FINDMYPOLE(FDT, OBJ, ZC)
%
%   FDT  es la FdT original a modificar (e.g., g=tf([1],[1 1])
%   OBJ es el punto por el que se desea que pase el LdlR (e.g., -1+1i)
%   ZC  es el cero del controlador (e.g., -2)
%
%   Ejemplo: findmypole (tf ([1], [1 1]), -1+1i, -2)
%
% Autor: Alejandro R. Mosteo, v1.0, 2012.05.31
% v1.1, 2013-05-27: return the controller as first output

if nargin < 2
    fprintf(2, 'Especifique FdT y s* como parámetros: findmyPD(fdt, s_star)\n');
    return
end

no_plot = true;

s =zpk ([0],[],[1]);

if ~exist('no_plot','var')
    % figure;
    subplot(2,1,1);
    hold on;

    color='red';

    plot (obj + 0.0001*1i,  'x', 'color', color);
    rlocus(fdt);
end
re = real(obj);
im = imag(obj);

f_poles = pole (fdt);
f_zeros = zero (fdt);

angp = 0;
angz = 0;
%gain = 1;

%dani
[num1 den1 k1] = zpkdata(fdt,'v');
gain = 1/k1;
%dani

for j = 1:length(f_poles)
    
    a = atan2 (im - imag (f_poles (j)), re - real (f_poles (j)));  
    k = abs(re - real (f_poles (j)) + 1i*(im - imag (f_poles (j))));
    
    disp (sprintf('Pole at %g has %5.1f degrees and %g modulus', f_poles (j),  (a * 180 / pi), k)); 
    
    angp = angp + a;
    gain = gain * k;
    
end;

for j = 1:length(f_zeros)
    
    a = atan2 (im - imag (f_zeros (j)), re - real (f_zeros (j)));
    k = abs(re - real (f_zeros (j)) + 1i*(im - imag (f_zeros (j))));
    
    disp (sprintf('Zero at %g has %5.1f degrees and %g modulus', f_zeros (j),  (a * 180 / pi), k)); 
    
    angz = angz + a;
    gain = gain / k;
    
end;

zca = pi + angp - angz; 

while (zca < 0)     zca = zca + 2*pi; end;
while (zca >= 2*pi) zca = zca - 2*pi; end;

ang_zc = zca;

if (zca <= 0) || (zca >= pi)
    disp (sprintf('Zero angle is %5.1f degrees', (zca * 180 / pi)));
    disp('Unable to find zero location');
    zc = NaN;
else
    if zca == pi/2
        zc = re;
    else 
        x = abs (im)/tan (zca);
        zc = re - x;
    end;
    k = abs(re - zc + 1i*im);
    disp (sprintf('Zero angle is %5.1f degrees with %g modulus', (zca * 180 / pi), k));
    gain = gain / k;
    disp(sprintf('Controller zero location is %g with system gain %g', zc, gain));
    if ~no_plot
        subplot(2,1,2);
        hold on;
        rlocus(fdt*(s-zc));
        plot (obj + 0.0001*1i, 'x', 'color', color);
        plot (zc  + 0.0001*1i, 'o', 'color', color);
    end
end;

C = gain*tf([1 -zc], [1]);
