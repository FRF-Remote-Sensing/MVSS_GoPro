function y = recursivelowpass(x,alpha)
% x_k = alpha * x_k-1 + (1-alpha)*x_k
y = x;
for i=2:numel(x)
    y(i) = alpha * y(i-1) + (1-alpha)*y(i);    
end

end