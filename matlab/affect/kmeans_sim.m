function [clu,min_dist] = kmeans_sim(W,k,varargin)
% kmeans_sim(W,k) performs k-means clustering on a data set represented by
% a matrix of pairwise similarities W into k clusters.
% 
% kmeans_sim(W,k,init_clu) is used to specify an initial set of clusters
% given by the vector init_clu.
% 
% kmeans_sim(W,k,init_clu,max_iter) is used to specify the maximum number
% of iterations to run the algorithm (default 100).
% 
% [clu,min_dist] = kmeans_sim(...) outputs the squared distance
% between each point and its closest centroid.
% 
% Author: Kevin Xu

% Check validity of similarity matrix
n = size(W,1);
assert(max(max(abs(W-W')))<1e-6,'W must be a symmetric matrix')
W = (W+W')/2;
% if ~isequal(W,W')
% 	disp('W must be a symmetric matrix')
% 	clu = 0;
% 	min_dist = 0;
% 	return
% end

% % Check that number of clusters is valid (non-negative and integer)
% if (k < 0) || (k ~= floor(k))
% 	disp('k must be a non-negative integer. Set k=0 to see an eigenvalue plot')
% 	clu = 0;
% 	min_dist = 0;
% 	return
% end
k_len = length(k);

num_opt_args = size(varargin,2);
if num_opt_args > 0
	clu = repmat(reshape(varargin{1},n,1),1,k_len);
else
	clu = zeros(n,k_len);
	% Random initialization for each k
	for cand = 1:k_len
		k_cand = min(n,k(cand));	% Can't have more clusters than nodes
		clu(:,cand) = random('unid',k_cand,n,1);
	end
end

if num_opt_args > 1
	max_iter = varargin{2};
% 	if (max_iter <= 0) || (max_iter ~= floor(max_iter))
% 		disp('max_iter must be a positive integer')
% 		clu = 0;
% 		min_dist = 0;
% 		return
% 	end
else
	max_iter = 100;
end

min_dist = zeros(n,k_len);
% Keep iterating k-means algorithm until converged or exceeded max. # of
% iterations.
for cand = 1:k_len
	k_cand = min(n,k(cand));	% Can't have more clusters than nodes
	clu_prev = zeros(n,1);
	% Matrix of squared distances from each centroid
	dist_mat = zeros(n,k_cand);
	iter = 0;
	
	while (~isequal(clu(:,cand),clu_prev)) && (iter < max_iter)
		clu_prev = clu(:,cand);
		iter = iter+1;

		% Compute updated squared distances to each centroid
		for i = 1:n
			for c = 1:k_cand
				in_clu = (clu(:,cand)==c);
				num_in_clu = sum(in_clu);
				dist_mat(i,c) = W(i,i) - 2*sum(W(i,in_clu))/num_in_clu ...
					+ sum(sum(W(in_clu,in_clu)))/num_in_clu^2;
			end
		end

		% Update clusters
		[min_dist(:,cand),clu(:,cand)] = min(dist_mat,[],2);
	end

	if iter >= max_iter
		disp(['k = ' int2str(k_cand) ': Maximum number of iterations reached'])
	end
end
