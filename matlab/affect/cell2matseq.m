function [X_seq,ids_all_row,ids_all_col] = cell2matseq(ids_row,ids_col,X,type)
% [X_seq,ids_all_row,ids_all_col] = cell2matseq(ids_row,ids_col,X,type)
% converts a cell array of matrices with different row and column IDs for
% each matrix in the array into a sequence of matrices with a single set
% of row and column IDs for each matrix.
% 
% ids_row and ids_col should be a cell array with the same dimensions as
% the cell array of matrices X. Each element of ids_row and ids_col should
% be a cell array of strings representing the IDs for each row and column.
% If row and column IDs are the same, set ids_col to [] to avoid processing
% two sets of IDs.
% 
% X can either be a cell array of full or sparse matrices. If X is a cell
% array of full matrices, X_seq will be a 3-D full matrix; otherwise, X_seq
% will be a cell array of sparse matrices. ids_all_row and ids_all_col
% specify the row and column IDs for all of X_seq.
% 
% type can either be 'union' or 'intersect' to denote whether to perform
% the union or intersection over all sets of IDs in ids_row and ids_col.
% 
% Author: Kevin Xu

t_max = length(X);

% First pass: cycle through all time steps and store all row and column IDs
ids_all_row = {};
ids_all_col = {};
for t = 1:t_max
	if strcmp(type,'union')
		ids_all_row = union(ids_all_row,ids_row{t});
		if ~isempty(ids_col)
			ids_all_col = union(ids_all_col,ids_col{t});
		end
	elseif strcmp(type,'intersect')
		ids_all_row = intersect(ids_all_row,ids_row{t});
		if ~isempty(ids_col)
			ids_all_col = intersect(ids_all_col,ids_col{t});
		end
	end
end
m = length(ids_all_row);
if ~isempty(ids_col)
	n = length(ids_all_col);
else
	n = m;
end

% Second pass: build sequence of matrices of union or intersection of rows
% and columns. If the matrices are full matrices, then use a 3-D matrix;
% otherwise, use a cell array.
if issparse(X{1})
	X_seq = cell(1,t_max);
	for t = 1:t_max
		X_seq{t} = sparse(m,n);
		[~,loc_r] = ismember(ids_row{t},ids_all_row);
		if ~isempty(ids_col)
			[~,loc_c] = ismember(ids_col{t},ids_all_col);
		else
			loc_c = loc_r;
		end
		X_seq{t}(loc_r,loc_c) = X{t};
	end
else
	X_seq = zeros(m,n,t_max);
	for t = 1:t_max
		[~,loc_r] = ismember(ids_row{t},ids_all_row);
		if ~isempty(ids_col)
			[~,loc_c] = ismember(ids_col{t},ids_all_col);
		else
			loc_c = loc_r;
		end
		X_seq(loc_r,loc_c,t) = X{t};
	end
end
