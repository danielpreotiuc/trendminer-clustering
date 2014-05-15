function [ids,W,labels] = generate_Gaussians_data(prox)
% [ids,W,labels] = generate_Gaussians_data(prox) creates proximity matrices
% for samples from a 2-component Gaussian mixture model with the two
% components getting closer over time.
% 
% prox can be one of the following:
%	- 'dot_prod': Creates matrices of consisting of all pairs of dot
%	  products between samples (used for k-means).
%	- 'euclidean': Creates matrices of pairwise Euclidean distances between
%	  samples (used for linkage-based hierarchical clustering).
% 
% Author: Kevin Xu

% Experiment parameters
t_max = 25;	% Number of time steps in each simulation run
change_step_1 = 11;	% First time step to switch samples to component 1
change_step_2 = 12;	% Second time step to switch samples to component 1
num_samples = 40;	% Total number of samples to generate from GMM
mu_1 = [3 3];	% Mean of component 1
init_mu_2 = [-3 -3];	% Initial location of mean of component 2
init_Sigma_1 = eye(2);	% Initial covariance matrix of component 1
init_Sigma_2 = eye(2);	% Initial covariance matrix of component 2
delta = [0.4 0.4];	% Amount to move component 2 at each time step
num_transfer = 5;	% Number of samples to switch to component 1

ids = cell(1,t_max);
W = cell(1,t_max);
X = cell(1,t_max);
labels = cell(1,t_max);

% Initial parameters
mu_2 = init_mu_2;
Sigma_1 = init_Sigma_1;
Sigma_2 = init_Sigma_2;

% Number of samples in components initially
num_samples_1 = floor(num_samples/2);
num_samples_2 = num_samples - num_samples_1;

for t = 1:t_max
	% Update parameters
	if (t > 1) && (t < change_step_1)
		% Move component 2 by the step size
		mu_2 = mu_2 + delta;
	elseif (t >= change_step_1) && (t <= change_step_2)
		% Transfer 5 samples from component 2 to component 1 and adjust
		% covariance matrices to be proportional to new cluster sizes
		num_samples_1 = num_samples_1 + num_transfer;
		num_samples_2 = num_samples_2 - num_transfer;
		Sigma_1 = (1 + num_transfer/num_samples)*Sigma_1;
		Sigma_2 = (1 - num_transfer/num_samples)*Sigma_2;
	end
	clu_1_samples = 1:num_samples_1;
	clu_2_samples = num_samples_1+1:num_samples;

	% Generate new sample
	ids{t} = cellstr(num2str((1:num_samples)'));
	X{t} = zeros(num_samples,2);
	X{t}(clu_1_samples,:) = mvnrnd(mu_1,Sigma_1,num_samples_1);
	X{t}(clu_2_samples,:) = mvnrnd(mu_2,Sigma_2,num_samples_2);
	if strcmp(prox,'dot_prod')
		W{t} = X{t}*X{t}';
	else
		W{t} = squareform(pdist(X{t},prox));
	end
	labels{t} = zeros(num_samples,1);
	labels{t}(clu_1_samples) = 1;
	labels{t}(clu_2_samples) = 2;
end
