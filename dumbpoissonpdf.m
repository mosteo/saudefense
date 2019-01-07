function y = dumbpoissonpdf(k,l)
% get a single value drawn from a poisson distribution l(ambda)

if ~isfloat(k)
   k = double(k);
end

y = (l^k)*exp(-l)/factorial(k);
