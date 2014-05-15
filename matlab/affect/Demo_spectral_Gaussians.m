% Demo of AFFECT spectral clustering on simulated data set consisting of
% samples from a 2-component Gaussian mixture model with mixture components
% getting closer over time. For more details on the experimental setup, see
% Readme.pdf or the following paper.
% 
% K. S. Xu, M. Kliger, and A. O. Hero III (2011), "Adaptive Evolutionary
% Clustering", available at http://arxiv.org/abs/1104.1990.
% 
% Author: Kevin Xu

sigma2 = 5;	% Gaussian kernel scaling parameter

disp('Creating two Gaussians simulated data')
[ids,W,labels] = generate_Gaussians_data('euclidean');
t_max = length(W);
for t = 1:t_max
	W{t} = exp(-W{t}.^2/sigma2);
end

disp('Clustering data using AFFECT spectral clustering')
[clu_est,W_bar_est,alpha_est] = batch_affect_spectral(ids,W,2,'output',1);

disp('Clustering data using static spectral clustering')
clu_sta = batch_affect_spectral(ids,W,2,'output',1,'alpha',0);

disp('Computing adjusted Rand indices')
rand_est = zeros(1,t_max);
rand_sta = zeros(1,t_max);
for t = 1:t_max
	rand_est(t) = valid_RandIndex(labels{t},clu_est{t});
	rand_sta(t) = valid_RandIndex(labels{t},clu_sta{t});
end

figure
plot(1:t_max,rand_est,'b*-',1:t_max,rand_sta,'go--');
xlabel('Time step')
ylabel('Adjusted Rand index')
title('Comparison of clustering accuracy (higher is better)')
legend('AFFECT','Static','Location','SouthEast')
set(gca,'Position',[0.13 0.21 0.775 0.725])
h = annotation('textbox');
set(h,'String',{['AFFECT mean adjusted Rand index: ' ...
	num2str(mean(rand_est))]; 
	['Static clustering mean adjusted Rand index: ' ...
	num2str(mean(rand_sta))]})
set(h,'LineStyle','none')
set(h,'HorizontalAlignment','center')
set(h,'VerticalAlignment','middle')
set(h,'FontSize',14)
set(h,'FontWeight','bold')
set(h,'Position',[0.08 0 0.875 0.13])
