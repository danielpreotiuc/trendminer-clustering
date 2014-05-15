% Demo of AFFECT spectral clustering on MIT Reality Mining data set. The
% data consists of a sequence of adjacency matrices with a time step of 1
% week. The adjacencies between two subjects correspond to time they spent
% in physical proximity of each other, measured by Bluetooth scans on their
% respective cell phones.
% 
% Data reference: N. Eagle, A. Pentland, and D. Lazer (2009), "Inferring
% Social Network Structure using Mobile Phone Data", Proceedings of the
% National Academy of Sciences, 106(36), pp. 15274-15278.
% The full data set can be obtained from http://reality.media.mit.edu/
% 
% Author: Kevin Xu

disp('Loading MIT Reality Mining data set')
load('reality.mat')

disp('Clustering data using AFFECT spectral clustering')
% 'remove_cc' is set to true because at some time steps, the graph is
% disconnected
[clu_est,W_bar_est,alpha_est] = batch_affect_spectral(ids,W,2,'output',1, ...
	'remove_cc',true);

disp('Clustering data using static spectral clustering')
clu_sta = batch_affect_spectral(ids,W,2,'output',1,'alpha',0, ...
	'remove_cc',true);

disp('Computing adjusted Rand indices')
t_max = length(W);
rand_est = zeros(1,t_max);
rand_sta = zeros(1,t_max);
for t = 1:t_max
	rand_est(t) = valid_RandIndex(labels{t},clu_est{t});
	rand_sta(t) = valid_RandIndex(labels{t},clu_sta{t});
end

disp('Creating cluster heat maps')
[clu_mat_est,ids_map] = clu_heatmap(ids,clu_est);
clu_mat_sta = clu_heatmap(ids,clu_sta);
% Add one extra row for participant who was never active
ids_map = [ids_map; setdiff(ids_all,ids_map)];
clu_mat_est = [clu_mat_est; zeros(1,t_max)];
clu_mat_sta = [clu_mat_sta; zeros(1,t_max)];
max_clu_num = max(max(clu_mat_est(:)),max(clu_mat_sta(:)));

% Sort rows of heat map according to ground truth labels (indicated by
% black horizontal line)
[labels_all_sorted,sidx] = sort(labels_all);
ids_all_sorted = ids_all(sidx);
ls_bound = find(labels_all_sorted(2:end) - labels_all_sorted(1:end-1)) + 0.5;
[~,loc] = ismember(ids_all_sorted,ids_map);
figure
imagesc(clu_mat_est(loc,:),[0 max_clu_num])
colorbar
map = colormap;
colormap([1 1 1; map])	% Show inactive participants as white rather than blue
line([0 t_max+1],[ls_bound ls_bound],'color','black','LineWidth',3)
xlabel('Time step')
ylabel('Participant')
title('AFFECT spectral clustering heat map (ground truth given by black line)')
set(gca,'Position',[0.13 0.17 0.6654 0.745])
h = annotation('textbox');
set(h,'String',{['Mean adjusted Rand index: ' num2str(mean(rand_est))]})
set(h,'LineStyle','none')
set(h,'HorizontalAlignment','center')
set(h,'VerticalAlignment','middle')
set(h,'FontSize',14)
set(h,'FontWeight','bold')
set(h,'Position',[0.13 0 0.6654 0.11])

figure
imagesc(clu_mat_sta(loc,:),[0 max_clu_num])
colorbar
map = colormap;
colormap([1 1 1; map])	% Show inactive participants as white rather than blue
line([0 t_max+1],[ls_bound ls_bound],'color','black','LineWidth',3)
xlabel('Time step')
ylabel('Participant')
title('Static spectral clustering heat map (ground truth given by black line)')
set(gca,'Position',[0.13 0.17 0.6654 0.745])
h = annotation('textbox');
set(h,'String',{['Mean adjusted Rand index: ' num2str(mean(rand_sta))]})
set(h,'LineStyle','none')
set(h,'HorizontalAlignment','center')
set(h,'VerticalAlignment','middle')
set(h,'FontSize',14)
set(h,'FontWeight','bold')
set(h,'Position',[0.13 0 0.6654 0.11])
