function [clu,W_bar,alpha_est,min_dist] ...
	= batch_affect_kmeans(ids,W,num_clust,varargin)
% batch_affect_kmeans(ids,W,num_clust) performs AFFECT evolutionary k-means
% clustering with adaptively estimated forgetting factor.
% 
% ids is a length T cell array corresponding to the object IDs of the rows
% and columns of the similarity matrices specified by the length T cell
% array W. The object IDs at each time step must be stored in a cell array
% of strings. The similarity matrices should correspond to all pairs of dot
% products between objects.
% 
% num_clust specifies the number of clusters and can either be a scalar, 
% vector of length T, or a string specifying the name of a cluster selection
% heuristic to apply. The only choice for heuristic at this time is
%	- 'silhouette': perform clustering with 2 to m clusters, and select the
%	  number of clusters with the maximum average silhouette index.
% m is specified through the optional parameter max_clust, described below.
% 
% Additional parameters are specified in ('name',value) pairs, e.g.
% batch_affect_kmeans(ids,W,num_clust,'name1',value1,'name2',value2) and
% are as follows:
%	- max_clust (default: 10): Maximum number of clusters for cluster
%	  selection heuristics. Has no effect when number of clusters is
%	  specified by the user.
%	- alpha (default: 'estimate'): The choice of forgetting factor alpha
%	  can be a scalar between 0 and 1 (for constant forgetting factor) or 
%	  the string 'estimate' to adaptively estimate the forgetting factor at
%	  each time step.
%	- num_iter (default: 3): Number of iterations to use when estimating
%	  forgetting factor. Has no effect for constant forgetting factor.
%	- initialize (default: 'previous'): How to initialize iterative
%	  estimation of alpha. Choices are to initialize with the previous
%	  clusters ('previous') or to first perform clustering with alpha = 0
%	  ('ordinary'). Has no effect for constant forgetting factor.
%	- output (default: 0): Set to 0 to suppress most output messages and to
%	  higher numbers to display progressively more output.
%
% Additional outputs can be obtained by specifying them as follows: 
% [clu,W_bar,alpha_est,min_dist] = batch_affect_kmeans(...)
%	- W_bar: Length T cell array of smoothed similarity matrices.
%	- alpha_est: M-by-T matrix of estimated forgetting factor at each
%	  iteration. M is specified in the second cell of input parameter alpha.
%	- min_dist: Length T cell array of distances from each object to nearest
%	  centroid.
% 
% Author: Kevin Xu

ip = inputParser;
ip.addRequired('ids',@iscell);
ip.addRequired('W',@iscell);
ip.addRequired('num_clust');
ip.addParamValue('max_clust',10,@(x)floor(x)==x);
ip.addParamValue('alpha','estimate');
ip.addParamValue('num_iter',3,@(x)floor(x)==x);
ip.addParamValue('initialize','previous');
ip.addParamValue('output',0,@(x)(floor(x)==x) && (x>=0));
ip.parse(ids,W,num_clust,varargin{:});
max_clust = ip.Results.max_clust;
alpha = ip.Results.alpha;
num_iter = ip.Results.num_iter;
initialize = ip.Results.initialize;
output = ip.Results.output;

t_max = length(W);
% Validate number of clusters
if isnumeric(num_clust)
	% Scalar or vector specifying number of clusters at each time step
	if isscalar(num_clust)
		num_clust = num_clust*ones(1,t_max);
	end
	assert(length(num_clust) == t_max, ...
		'Length of num_clust must equal the number of time steps');
else
	% Use specified heuristic for choosing number of clusters
	if strcmp(num_clust,'silhouette')
		m = 2:max_clust;
	else
		error('num_clust must be either numeric or ''silhouette''')
	end
end

% Validate alpha and other parameters related to forgetting factor
if isnumeric(alpha)
	num_iter = 0;
	assert((alpha>=0) && (alpha<=1),'alpha must be between 0 and 1');
else
	if ~strcmp(alpha,'estimate')
		error('alpha must either be a number or ''estimate''');
	end
	if ~(strcmp(initialize,'previous') || strcmp(initialize,'ordinary'))
		error('initialize must either be ''previous'' or ''ordinary''')
	end
end

% Initialize variable sizes
alpha_est = zeros(num_iter,t_max);
clu = cell(1,t_max);
W_bar = cell(1,t_max);
min_dist = cell(1,t_max);

for t = 1:t_max
	if output > 0
		disp(['Processing time step ' int2str(t)])
	end
	
	if isnumeric(num_clust)
		m = num_clust(t);
	end
	
	n = length(ids{t});	
	% Only do temporal smoothing if not the first time step
	if t > 1
		% Identify rows and columns of new objects in current similarity
		% matrix
		[both_tf,both_loc] = ismember(ids{t},ids{t-1});
		W_prev = W_bar{t-1}(both_loc(both_tf),both_loc(both_tf));
		clu_prev = zeros(n,1);
		clu_prev(both_tf) = clu{t-1}(both_loc(both_tf));
		new_tf = ~both_tf;
		
		% Initialize smoothed similarity matrix
		W_bar{t} = zeros(n,n);
		
		% No smoothing for new objects
		W_bar{t}(new_tf,:) = W{t}(new_tf,:);
		W_bar{t}(:,new_tf) = W{t}(:,new_tf);
		if strcmp(alpha,'estimate')
			% Initialize current clustering result to be previous clustering
			% result or the result of one run of ordinary clustering
			if strcmp(initialize,'previous')
				clu{t} = clu_prev;
			else
				clu{t} = kmeans_sim(W{t},m,clu_prev);
			end
		
			% Estimate alpha iteratively
			for iter = 1:num_iter
				alpha_est(iter,t) = estimate_alpha(W{t}(both_tf,both_tf), ...
					W_prev,clu{t}(both_tf));
				W_bar{t}(both_tf,both_tf) = alpha_est(iter,t)*W_prev ...
					+ (1-alpha_est(iter,t))*W{t}(both_tf,both_tf);
				[clu{t},min_dist{t}] = kmeans_sim(W_bar{t},m,clu_prev);
			end
		else
			W_bar{t}(both_tf,both_tf) = alpha*W_prev + (1-alpha) ...
				*W{t}(both_tf,both_tf);
			
			% Perform ordinary k-means on W_bar
			[clu{t},min_dist{t}] = kmeans_sim(W_bar{t},m,clu_prev);
		end
	else
		W_bar{t} = W{t};
		
		% Perform ordinary k-means
		[clu{t},min_dist{t}] = kmeans_sim(W_bar{t},m);
	end
	
	% Select optimal number of clusters
	if ~isnumeric(num_clust)
		if strcmp(num_clust,'silhouette')
			[clu{t},avg_width] = select_clu_silhouette(W_bar{t}, ...
				clu{t},'similarity');
			[~,midx] = min(avg_width);
			min_dist{t} = min_dist{t}(:,midx);
		end
	end
		
	if t > 1
		% Match clusters (using greedy method if more than 4 clusters)
		k = length(unique(clu{t}));
		if k > 4
			clu{t} = permute_clusters_greedy(ids{t},clu{t},ids{t-1}, ...
				clu{t-1},unmatched);
		else
			clu{t} = permute_clusters_opt(ids{t},clu{t},ids{t-1}, ...
				clu{t-1},unmatched);
		end
		unmatched = max(unmatched,max(clu{t})+1);
	else
		unmatched = max(clu{t})+1;
	end
end
