function [clu_perm,max_agree] = permute_clusters_greedy(ids,clu, ...
	ids_prev,clu_prev,unmatched)
% permute_clusters_greedy(ids,clu,ids_prev,clu_prev,unmatched) permutes the
% clusters in clu for maximum agreement with those in clu_prev, where ids
% and ids_prev specify the object IDs (names) for clu and clu_prev,
% respectively. unmatched specifies the lowest cluster index to name
% clusters in clu that do not match any clusters in clu_prev.
% 
% Unlike permute_clusters_opt, permute_clusters_greedy uses a greedy
% matching strategy and does not always return the optimal permutation.
% 
% [clu_perm,max_agree] = permute_clusters_greedy(ids,clu,ids_prev,
% clu_prev,unmatched) also returns the maximum number of agreements given
% by the best permutation.
% 
% Author: Kevin Xu

n = length(ids);

% Assign new objects (not present at previous time) to have previous
% cluster of 0
[both_tf,both_loc] = ismember(ids,ids_prev);
clu_prev_ids = clu_prev;	% Clusters at previous time with previous IDs
clu_prev = zeros(n,1);
clu_prev(both_tf) = clu_prev_ids(both_loc(both_tf));

clu_names = unique(clu);
k = length(clu_names);	% Number of clusters at current time

clu_prev_names = unique(clu_prev);
% 0 is used to denote not present at previous time so don't match to that
clu_prev_names(clu_prev_names == 0) = [];
k_old = length(clu_prev_names);	% Number of clusters at previous time

% Compute confusion matrix where entry C(i,j) dentoes fraction of points
% in cluster i at time t found in cluster j at time t-1.
C = zeros(k,k_old);
for i = 1:k
	in_clu_i = (clu == clu_names(i));
% 	num_in_clu_i = sum(in_clu_i);
	for j = 1:k_old
		prev_in_clu_j = (clu_prev == clu_prev_names(j));
% 		prev_num_in_clu_j = sum(prev_in_clu_j);

		% Choose confusion to be either raw agreement or agreement fraction
		C(i,j) = sum(in_clu_i & prev_in_clu_j);
% 		C(i,j) = sum(in_clu_i & prev_in_clu_j)/num_in_clu_i;
% 		C(i,j) = (sum(in_clu_i & prev_in_clu_j)/num_in_clu_i ...
% 			+ sum(in_clu_i & prev_in_clu_j)/prev_num_in_clu_j)/2;
	end
end

% Permutation vector. perm_vect(i) = j means that cluster i at time t is
% matched with cluster j at time t-1.
perm_vect = zeros(k,1);

% Match clusters by picking max. entry in confusion matrix then zeroing out
% rows and columns corresponding to already matched clusters.
max_agree = 0;
for match = 1:min(k,k_old)
	% If no more agreements left to match, move on to the next step
	if sum(sum(C)) == 0
		break
	end
	[max_rows,rows] = max(C,[],1);
	[max_frac,col] = max(max_rows);
	max_agree = max_agree + max_frac;
	perm_vect(rows(col)) = col;
	C(rows(col),:) = 0;
	C(:,col) = 0;
end

clu_perm = zeros(n,1);
for clust = 1:k	
	% If permuted cluster is not matched with any previous cluster, then
	% name the cluster by any unused name.
	if perm_vect(clust) == 0
		clu_perm(clu==clu_names(clust)) = unmatched;
		unmatched = unmatched + 1;
	else
		clu_perm(clu==clu_names(clust)) = clu_prev_names(perm_vect(clust));
	end
end
