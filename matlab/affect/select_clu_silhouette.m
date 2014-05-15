function [clu_best,avg_width] = select_clu_silhouette(S,clu,type)
% select_clu_silhouette(S,clu,type) finds the clustering result for the
% current proximity matrix S with highest average silhouette width among
% the columns of clu. type must be either 'similarity' or 'dissimilarity'
% to indicate the type of proximity matrix.
% 
% [clu_best,avg_width] = select_clu_silhouette(S,clu,type) also returns the
% vector of average silhouette widths for each clustering result.
% 
% Author: Kevin Xu

[n,k_cand] = size(clu);
avg_width = zeros(k_cand,1);	% Average silhouette width for each k

for cand = 1:k_cand
	k = max(clu(:,cand));
	
	avg_sim = zeros(n,k);	% Average dissimilarity to all clusters
	sil_width = zeros(n,1);	% Silhouette values
	for obj = 1:n
		% Indicator vector for current object
		obj_indic = false(n,1);
		obj_indic(obj) = true;
		for clust = 1:k
			% Identify all objects in cluster except the one being
			% considered
			clust_nodes = xor(clu(:,cand) == clust,obj_indic);
			avg_sim(obj,clust) = mean(S(obj,clust_nodes));
		end
		
		% Calculate silhouette values for each object. If only one object
		% is in a cluster (avg_sim will be NaN in this case), consider
		% silhouette value to be 0.
		if sum(sum(isnan(avg_sim))) > 0
			sil_width(obj) = 0;
		else
			a = avg_sim(obj,clu(obj,cand));
			if strcmp(type,'similarity')
				b = max(avg_sim(obj,setdiff(1:k,clu(obj,cand))));
				if (a > b)
					sil_width(obj) = 1 - b/a;
				else
					sil_width(obj) = a/b - 1;
				end
			elseif strcmp(type,'dissimilarity')
				b = min(avg_sim(obj,setdiff(1:k,clu(obj,cand))));
				sil_width(obj) = (b-a) / max(a,b);
			else
				error('type must be ''similarity'' or ''dissimilarity''')
			end
		end
	end
	avg_width(cand) = mean(sil_width);
end

[~,best_cand] = max(avg_width);
clu_best = clu(:,best_cand);
