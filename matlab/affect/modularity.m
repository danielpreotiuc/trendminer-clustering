function Q = modularity(W,clu)
% Calculate the modularity function Q of a clustering result.
% 
% modularity(W,clu) calculates the modularity of a clustering result
% represented by vector clu on the graph with adjacency matrix W.
% 
% Author: Kevin Xu

k = max(clu);
Q = 0;
sum_all_edges = full(sum(sum(W)));
for clust = 1:k
	clu_nodes = (clu == clust);
	assoc = full(sum(sum(W(clu_nodes,clu_nodes))));
	deg = full(sum(sum(W(clu_nodes,:))));
	Q = Q + assoc/sum_all_edges - (deg/sum_all_edges)^2;
end