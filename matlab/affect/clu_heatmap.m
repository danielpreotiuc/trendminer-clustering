function varargout = clu_heatmap(ids,clu,cg)
% clu_heatmap(ids,clu) creates a heat map of cluster evolution over time for
% the clustering result specified by the length T cell array clu with object
% IDs stored in the length T cell array ids.
% 
% clu_heatmap(ids,clu,true) uses clustergram instead of imagesc to display the
% cluster evolution. The rows are re-ordered by hierarchical clustering.
% Requires the Bioinformatics toolbox.
% 
% [clu_mat,ids_all] = clu_heatmap(...) stores the heat map in clu_mat and
% the list of all node IDs in ids_all. The heat map can be plotted using
% imagesc(clu_mat).
% 
% Author: Kevin Xu

if nargin < 2
	error('At least two inputs, ids and clu, must be specified.')
elseif nargin == 2
	cg = false;
end

t_max = length(clu);

% First pass: cycle through all time steps and store all object IDs
% disp('First pass: collecting all object IDs')
ids_all = {};
for t = 1:t_max
	ids_all = union(ids_all,ids{t});
end

% Second pass: build matrix of clustering results
% disp('Second pass: building matrix of clustering results')
n = length(ids_all);
clu_mat = zeros(n,t_max);
for t = 1:t_max
	% Insert clustering result at time t into proper rows of clu_mat
	[~,loc] = ismember(ids{t},ids_all);
	clu_mat(loc,t) = clu{t};
end

if nargout > 0
	varargout{1} = clu_mat;
	varargout{2} = ids_all;
else
	if cg == true
		clustergram(clu_mat,'Cluster',1,'Standardize',3,'DisplayRange', ...
			max(max(clu_mat)),'Symmetric',false,'RowPDist','Hamming', ...
			'Colormap','jet')
	else
		imagesc(clu_mat);
	end
end
