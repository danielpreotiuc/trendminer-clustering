function [sm,sv] = clu_sample_stats(W,clu)
% [sm,sv] = clu_sample_stats(W,clu) calculates the sample means and
% variances entries of W by sampling over the clusters specified by the
% cluster vector clu. The sample variance is the unbiased (corrected) type.
% 
% Author: Kevin Xu

n = size(W,1);	% Number of realizations
clu_names = unique(clu);
k = length(clu_names);

% Matrix of sample means across all points in cluster
sm = zeros(n,n);
% Matrix of unbiased sample variances across all points in cluster
sv = zeros(n,n);

% First calculate sample means for all combinations (i,j) by iterating
% across the clusters
for c1 = 1:k
	c1_obj = find(clu==clu_names(c1));
	c1_length = length(c1_obj);
	% Calculate sample mean for i = j (diagonals)
	diag_sm = trace(W(c1_obj,c1_obj)) / c1_length;
	% Calculate sample mean for i ~= j (off-diagonals)
	offdiag_sm = (sum(sum(W(c1_obj,c1_obj))) - diag_sm*c1_length) ...
		/ (c1_length*(c1_length-1));
	for i = c1_obj'
		for j = c1_obj'
			if (i == j)
				sm(i,i) = diag_sm;
			else
				sm(i,j) = offdiag_sm;
			end
		end
	end
	
	for c2 = c1+1:k
		c2_obj = find(clu==clu_names(c2));
		c2_length = length(c2_obj);
		% Calculate sample mean
		cross_sm = sum(sum(W(c1_obj,c2_obj))) / (c1_length*c2_length);
		for i = c1_obj'
			for j = c2_obj'
				sm(i,j) = cross_sm;
				sm(j,i) = cross_sm;
			end
		end
	end
end

% Now calculate sample variances
for c1 = 1:k
	c1_obj = find(clu==clu_names(c1));
	c1_length = length(c1_obj);
	% Calculate sample variance for i = j (diagonals)
	diag_sv = trace((W(c1_obj,c1_obj) - sm(c1_obj,c1_obj)).^2) ...
		/ (c1_length - 1);
	% Calculate sample variance for i ~= j (off-diagonals)
	offdiag_sv = (sum(sum((W(c1_obj,c1_obj) - sm(c1_obj,c1_obj)).^2)) ...
		- diag_sv*(c1_length-1)) / (c1_length*(c1_length-1)-2);
	
	% If only one node is in this component, then we cannot
	% calculate variance so set it to 0. If there are two nodes, we can
	% calculate variance along the diagonal but not on the off-diagonal so
	% set the off-diagonal variance to 0.
	if c1_length == 1
		sv(c1_obj,c1_obj) = 0;
	elseif c1_length == 2
		node_1 = c1_obj(1);
		node_2 = c1_obj(2);
		sv(node_1,node_1) = diag_sv;
		sv(node_2,node_2) = diag_sv;
		sv(node_1,node_2) = 0;
		sv(node_2,node_1) = 0;
	else
		for i = c1_obj'
			for j = c1_obj'
				if (i == j)
					sv(i,i) = diag_sv;
				else
					sv(i,j) = offdiag_sv;
				end
			end
		end
	end
	
	for c2 = c1+1:k
		c2_obj = find(clu==clu_names(c2));
		c2_length = length(c2_obj);
		% Calculate sample variance
		cross_sv = sum(sum((W(c1_obj,c2_obj) - sm(c1_obj,c2_obj)).^2)) ...
			/ (c1_length*c2_length - 1);
		for i = c1_obj'
			for j = c2_obj
				% If only one node is in each component then we cannot
				% calculate variance so set it to 0.
				if c1_length*c2_length == 1
					sv(i,j) = 0;
				else
					sv(i,j) = cross_sv;
					sv(j,i) = cross_sv;
				end
			end
		end
	end
end
