function [clu_best,Q] = select_clu_modularity(W,clu,tol)
% select_clu_modularity(W,clu,tol) finds the clustering result for the graph
% W with the highest modularity among the columns of clu, up to a tolerance
% parameter tol. The clustering result with the lowest number of clusters
% that is within tol of the maximum modularity will be returned.
% 
% [clu_best,Q] = select_clu_modularity(W,clu,tol) also returns the vector
% of modularities Q for each clustering result.
% 
% Author: Kevin Xu

k_cand = size(clu,2);
Q = zeros(k_cand,1);	% Modularity for each k

for cand = 1:k_cand
	Q(cand) = modularity(W,clu(:,cand));
end

Q_max = max(Q);
best_cand = find(Q >= Q_max-tol,1);
clu_best = clu(:,best_cand);
