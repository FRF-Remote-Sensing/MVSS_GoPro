function y = recursivelowpass(x,alpha)
% Perform a simple recursive lowpass filter on the vector x as defined by
% the equation: 
%
% x_k = alpha * x_(k-1) + (1-alpha)*x_k
%
% where alpha is constrained by: (0 1)
y = x;
for i=2:numel(x)
    y(i) = alpha * y(i-1) + (1-alpha)*y(i);    
end

end