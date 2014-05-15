function [alpha,mean_curr,var_curr] = estimate_alpha(W_curr,W_prev,clu)
% estimate_alpha(W_curr,W_prev,clu) returns an estimate of the optimal
% forgetting factor alpha given the current proximity matrix W_curr, the
% shrinkage estimate at the previous time step W_prev, and the cluster
% membership vector clu.
%
% [alpha,mean_curr,var_curr] = estimate_alpha(W_curr,W_prev,clu) also 
% returns the matrices of sample means and sample variances used to
% calculate the forgetting factor alpha.
% 
% Author: Kevin Xu

[mean_curr,var_curr] = clu_sample_stats(W_curr,clu);
num = sum(sum(var_curr));
den = num + sum(sum((W_prev - mean_curr).^2));
alpha = num / den;
assert(~isnan(alpha),'alpha is NaN. Numerator = %f. Denominator = %f',num,den)
