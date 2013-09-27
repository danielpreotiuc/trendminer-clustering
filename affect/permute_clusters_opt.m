function [clu_perm,max_agree] = permute_clusters_opt(ids,clu,ids_prev, ...
	clu_prev,unmatched)
% permute_clusters_opt(ids,clu,ids_prev,clu_prev,unmatched) permutes the
% clusters in clu for maximum agreement with those in clu_prev, where ids
% and ids_prev specify the object IDs (names) for clu and clu_prev,
% respectively. unmatched specifies the lowest cluster index to name 
% clusters in clu that do not match any clusters in clu_prev.
% 
% This function searches all possible permutations and is not recommended
% for more than 4 clusters! Use permute_clusters_greedy instead.
% 
% [clu_perm,max_agree] = permute_clusters_opt(ids,clu,ids_prev,clu_prev,
% unmatched) also returns the maximum number of agreements given by the
% best permutation.
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
if k > 4
	disp('Warning: k > 4 so the number of permutations is extremely large.')
	disp('Consider using permute_clusters_greedy instead.')
end

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

all_perms = perms(1:max(k,k_old));
num_perms = size(all_perms,1);
num_agree = zeros(num_perms,1);
clu_all_perms = zeros(n,num_perms);

for i = 1:num_perms
	perm = all_perms(i,:);
	unmatched_perm = unmatched;
	
	% Cluster 1 is permuted to perm(1), cluster 2 is permuted to
	% perm(2), etc.
	for c = 1:k		
		% If permuted cluster exceeds the number of clusters at the
		% previous time, then we are not matching this cluster to a
		% previous cluster. Name the cluster by a new name.
		if perm(c) > k_old
			clu_all_perms(clu == clu_names(c),i) = unmatched_perm;
			unmatched_perm = unmatched_perm + 1;
		else
			clu_all_perms(clu == clu_names(c),i) ...
				= clu_prev_names(perm(c));
		end
	end
	
	% Max. sum of agreements or agreement fractions
	for row = 1:k
		if perm(row) <= k_old
			num_agree(i) = num_agree(i) + C(row,perm(row));
		end
	end
end

[max_agree,idx] = max(num_agree);
clu_perm = clu_all_perms(:,idx);
