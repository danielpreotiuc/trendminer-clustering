function [clu,eigenvectors,eigenvalues] = spectral_cluster(W,k,varargin)
% spectral_cluster(W,k) performs normalized cut spectral clustering on the
% graph given by adjacency matrix W into k clusters. k can be a scalar or a
% vector of length p (in which case p sets of clustering results are
% returned).
% 
% If the number of clusters is not known a priori, set k to 0 to see a
% plot of m leading eigenvalues, after which the user will be prompted
% to enter the desired number of clusters. m is specified through the
% optional parameter num_ev_plot, described below.
% 
% Additional parameters are specified in ('name',value) pairs, e.g.
% spectral_cluster(data,num_clust,'name1',value1,'name2',value2) and
% are as follows:
%	- objective (default: 'NC'): The spectral clustering objective function
%	  to optimize. Choices are average association ('AA'), ratio cut
%	  ('RC'), and normalized cut ('NC').
%	- eig_type (default: 'lanczos'): The method of eigendecomposition to
%	  use. Choices are full eigendecomposition ('full') or Lanczos
%	  iteration ('lanczos'), which is recommended for sparse matrices.
%	- disc_type (default: 'kmeans'): The method of discretization to use.
%	  Choices are k-means ('kmeans') and Yu and Shi's (2003) method of
%	  orthogonal transformations ('ortho'). 'kmeans' requires the
%	  Statistics Toolbox, and 'ortho' requires Yu and Shi's (2003) NCut
%	  clustering toolbox.
%	- num_reps (default: 1): The number of times the k-means algorithm
%	  should be run to determine the final clustering. Has no effect when
%	  discretizing by orthogonal transformations.
%	- norm_ev (default: true): Whether to row-normalize eigenvectors before
%	  performing k-means. Typically this is done only when using the
%	  normalized cut criterion. Has no effect when discretizing by
%	  orthogonal transformations.
%	- num_ev_plot (default: 10): The number of leading eigenvalues to plot
%	  if k is set to 0.
%	- remove_cc (default: false): Set to true to remove all connected
%	  components aside from the giant connected component before performing
%	  eigendecomposition. The clustering result would then contain k + c
%	  clusters, where c is the number of connected components. It is
%	  recommended to set remove_cc to true if there are a lot of such
%	  components, because they will be identified much more quickly than by
%	  eigendecomposition. Requires the Bioinformatics Toolbox.
%
% Additional outputs can be obtained by specifying them as follows: 
% [clu,eigenvectors,eigenvalues] = spectral_cluster(...)
%	- eigenvectors: matrix of leading eigenvectors.
%	- eigenvalues: vector of leading eigenvalues.
% 
% Author: Kevin Xu

ip = inputParser;
ip.addRequired('W');
ip.addRequired('k');
ip.addParamValue('objective','NC');
ip.addParamValue('eig_type','lanczos');
ip.addParamValue('disc_type','kmeans');
ip.addParamValue('num_reps',1);
ip.addParamValue('norm_ev',true,@islogical);
ip.addParamValue('num_ev_plot',10);
ip.addParamValue('remove_cc',false,@islogical);
ip.parse(W,k,varargin{:});
objective = ip.Results.objective;
eig_type = ip.Results.eig_type;
disc_type = ip.Results.disc_type;
num_reps = ip.Results.num_reps;
norm_ev = ip.Results.norm_ev;
num_ev_plot = ip.Results.num_ev_plot;
remove_cc = ip.Results.remove_cc;

% Check validity of adjacency matrix
n = size(W,1);
assert(max(max(abs(W-W')))<1e-6,'W must be a symmetric matrix')
W = (W+W')/2;

% Check that number of clusters is valid (non-negative and integer)
if (sum(k < 0) > 0) || ~isequal(k,floor(k))
	error(['k must be a vector of non-negative integers. ' ...
		'Set k=0 to see an eigenvalue plot'])
end

% Validate other inputs
if ~(strcmp(objective,'AA') || strcmp(objective,'RC') ...
		|| strcmp(objective,'NC'))
	error('objective must be one of ''AA'',''RC'', or ''NC''')
end
if ~(strcmp(eig_type,'full') || strcmp(eig_type,'lanczos'))
	error('eig_type must be either ''full'' or ''lanczos''')
end
if ~(strcmp(disc_type,'kmeans') || strcmp(disc_type,'ortho'))
	error('disc_type must be either ''kmeans'' or ''ortho''')
end
if (num_reps <= 0) || ~isequal(num_reps,floor(num_reps))
	error('num_reps must be a positive integer')
end
if (num_ev_plot <= 0) || ~isequal(num_ev_plot,floor(num_ev_plot))
	error('num_ev_plot must be a positive integer')
end
assert(islogical(norm_ev),'norm_ev must be true or false')
assert(islogical(remove_cc),'remove_cc must be true or false')

% Convert between full and sparse matrix if necessary
if strcmp(eig_type,'lanczos')
	if ~issparse(W)
		W = sparse(W);
	end
elseif strcmp(eig_type,'full')
	if issparse(W)
		W = full(W);
	end
end

% Calculate leading eigenvectors of adjacency or Laplacian matrix depending
% on the objective function.
if isequal(k,0)
	num_ev = min(n,num_ev_plot);
else
	num_ev = max(k);
end

% Pre-processing: removing all nodes not in giant connected component (GCC)
if remove_cc == true
	[num_cc,cc_memb] = graphconncomp(sparse(W));
% 	disp([int2str(num_cc) ' connected components in the graph'])
	% Calculate the # of nodes in each connected component
	cc_sizes = histc(cc_memb,1:num_cc);
	[gcc_size, gcc_idx] = max(cc_sizes);
	obj_in_gcc = (cc_memb == gcc_idx);
	n_all = n;
	n = sum(obj_in_gcc);
	W_all = W;
	W = W(obj_in_gcc,obj_in_gcc);
end

if strcmp(objective,'AA')
	if strcmp(eig_type,'full')
		[eigenvectors,eigenvalues] = eig(W); %#ok<SPEIG>
	else
		[eigenvectors,eigenvalues] = eigs(W,num_ev,'LA');
	end
	eigenvalues = diag(eigenvalues);
	[eigenvalues,idx] = sort(eigenvalues,'descend');
	eigenvectors = eigenvectors(:,idx);
else
	if strcmp(objective,'NC')
		% Add eps to prevent zero entries, which cannot be inverted
		d = sum(abs(W),2) + eps;
		if strcmp(eig_type,'full')
			D = diag(d);
			L = eye(n) - D^-0.5*W*D^-0.5;
		else
			D_inv_sqrt = spdiags(1./sqrt(d),0,n,n);
			L = speye(n) - D_inv_sqrt*W*D_inv_sqrt;
		end
	elseif strcmp(objective,'RC')
		% Add eps to prevent zero entries, which cannot be inverted
		
		d = sum(abs(W),2) + eps;

		if strcmp(eig_type,'full')
			D = diag(d);
		else
			D = spdiags(d,0,n,n);
		end
		L = D - W;
                D = spdiags(1./degs, 0, size(D, 1), size(D, 2));
                L = D * L;
	end
	L = (L+L')/2;
	
	if strcmp(eig_type,'full')
		[eigenvectors,eigenvalues] = eig(L);
	else
		[eigenvectors,eigenvalues] = eigs(L,num_ev,'SA');
	end
	eigenvalues = diag(eigenvalues);
	[eigenvalues,idx] = sort(eigenvalues);
	eigenvectors = eigenvectors(:,idx);
end

% Let user select number of clusters if k = 0 by plotting num_ev leading
% eigenvalues
if isequal(k,0)
	plot(real(eigenvalues(1:min(n,num_ev))),'x')
	k = input('Enter the number of clusters: ');
end

eigenvectors = eigenvectors(:,1:min(max(k),n)) + eps;
k_len = length(k);
clu = zeros(n,k_len);
warning('off','stats:kmeans:EmptyCluster')
for cand = 1:k_len
	k_cand = min(n,k(cand));	% Can't have more clusters than nodes
	eigenvectors_cand = eigenvectors(:,1:k_cand);
	if strcmp(disc_type,'kmeans')
		if norm_ev
			% Normalize rows of eigenvector matrix to have norm 1
			eigenvector_norms = repmat(sqrt(sum(eigenvectors_cand.^2,2)), ...
				1,k_cand);
			eigenvectors_cand = eigenvectors_cand./eigenvector_norms;
		end

		% Run k-means on the rows of the eigenvector matrix to obtain the
		% clusters
		clu(:,cand) = kmeans(eigenvectors_cand,k_cand,'EmptyAction', ...
			'singleton','Replicates',num_reps);
	else
		% Use Yu and Shi (2003)'s method of finding orthonormal
		% transformations
		[nc_disc,nc_eigenvectors] = discretisation(eigenvectors_cand);
		clu(:,cand) = clumat2cluvect(full(nc_disc));
	end
end
warning('on','stats:kmeans:EmptyCluster')

% Assign small connected components to their own clusters then merge with
% GCC
if remove_cc == true
	% Indices of small connected components
	small_cc = setdiff(1:num_cc,gcc_idx);
	clu_gcc = clu;
	clu = zeros(n_all,k_len);
	current_clu = 0;
	for cc = small_cc
		current_clu = current_clu + 1;
		obj_in_cc = (cc_memb==cc);
		clu(obj_in_cc,:) = current_clu;
	end
	clu(obj_in_gcc,:) = clu_gcc + current_clu;
end
