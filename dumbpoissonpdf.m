%   Authors: Alejandro R. Mosteo, Danilo Tardioli, Eduardo Montijano
%   Copyright 2018-9999 Monmostar
%   Licensed under GPLv3 https://www.gnu.org/licenses/gpl-3.0.en.html
%
function y = dumbpoissonpdf(k,l)
% get a single value drawn from a poisson distribution l(ambda)

if ~isfloat(k)
   k = double(k);
end

y = (l^k)*exp(-l)/factorial(k);
