clear all; close all; clc;

%% generate sample continues data
size1 = 200; 
mean1 = [2,-1];
cov1 = [1,0.1; 0.1,1];
mean2 = [8,3];
cov2 = [1 .2; 0.2,1];
X = [mvnrnd(mean1, cov1, size1); mvnrnd(mean2, cov2, size1)];
Y = [ones(size1,1)  ; -1*ones(size1,1)]; 
order = randperm(400); 
X = X(order,:); 
Y = Y(order,:); 
k = 2;


%% cluster : k-means 
[centroid, pointsInCluster, assignment]= kmeans2(X, k); 
Xtmp = X(Y ==1, :);
plot(Xtmp(:, 1), Xtmp(:, 2), 'xr')
hold on;
Xtmp = X(Y ==-1, :);
plot(Xtmp(:, 1), Xtmp(:, 2), 'xb')
for i = 1:k 
    plot(centroid(i,1), centroid(i,2),'--rs','LineWidth',2,...
                    'MarkerEdgeColor','k',...
                    'MarkerFaceColor','g',...
                    'MarkerSize',10)
end 


%% cluster: dp-means: 
% lambda = 10; 
T = mean(X);
[dist, ind] = sort( sqrt(sum((repmat(T,size(X,1),1)-X).^2,2)), 'descend' );

lambda = dist(k); 

% figure; 
[centroid, pointsInCluster, assignment, clusterSize]= dpmeans(X, lambda); 
figure; 
% Xtmp = X(Y ==1, :);
% plot(Xtmp(:, 1), Xtmp(:, 2), 'xr')
hold on;
% Xtmp = X(Y ==-1, :);
% plot(Xtmp(:, 1), Xtmp(:, 2), 'xb')
for i = 1:clusterSize 
    plot(centroid(i,1), centroid(i,2),'--rs','LineWidth',2,...
                    'MarkerEdgeColor','k',...
                    'MarkerFaceColor','g',...
                    'MarkerSize',10)
    Xtmp = X(assignment ==i, :);
    plot(Xtmp(:, 1), Xtmp(:, 2), 'x',  'color', rand(1,3))
end


%% cluster : dpm 
T = 50; % maximum number of clusters
[gamma, phi, m, beta, s, p] = variational_dpm(X, 20, T, 1);
[maxVal, clusters] = max(phi);
centers = []; 
figure;
Xtmp = X(Y ==1, :);
plot(Xtmp(:, 1), Xtmp(:, 2), 'xr')
hold on;
Xtmp = X(Y ==-1, :);
plot(Xtmp(:, 1), Xtmp(:, 2), 'xb')

for t = 1:T
    xt = X(clusters == t, :);
    if size(xt) ~= 0
        disp( ['T = ' num2str(t) ' size(xt,1) = ' num2str(size(xt,1)) ' m(t,:) ' num2str(m(t,:)) ])
        centers = [centers ; m(t,:)];
    end
end

for i = 1:size(centers, 1) 
    plot(centers(i,1), centers(i,2),'--rs','LineWidth',2,...
                    'MarkerEdgeColor','k',...
                    'MarkerFaceColor','g',...
                    'MarkerSize',10)
end



%% cluster : dpm-gibs sampling  : 
% Daniel: which algorithm is this? 
dirich = DirichMix; % construct an object of the class
dirich.SetDimension(size(X,2));
dirich.InputData(X);
dirich.DoIteration(50); % 100 iterations
%dirich.PlotData
clusters = unique(dirich.c);
for i=1:1:size(clusters,1)
   pts = dirich.data(find(dirich.c == clusters(i,1)),:);
   plot(pts(:, 1), pts(:, 2), 'x', 'color', rand(1,3));
   hold on
end

for i=1:1:size(clusters,1)
   pts = dirich.data(find(dirich.c == clusters(i,1)),:);
   m = mean(pts);
   plot(m(:, 1), m(:, 2),'--rs','LineWidth',2,...
                    'MarkerEdgeColor','k',...
                    'MarkerFaceColor','g',...
                    'MarkerSize',10);
   hold on
end

%% Constrained Gibbs sampling

E = zeros(size(Y, 1), size(Y, 1)); 
Checked = zeros(size(Y, 1), size(Y, 1)); 
randSize = 0.01 * size(Y, 1) * size(Y, 1); 
iterAll = 1;
while(1)
    i1 = randi(size(Y, 1)); 
    i2 = randi(size(Y, 1)); 
    if Checked(i1, i2) == 0   
        Checked(i1, i2) = 1;
        if Y(i1) == Y(i2)
            E(i1, i2) = 1; 
            E(i2, i1) = 1; 
        else 
            E(i1, i2) = -1; 
            E(i2, i1) = -1; 
        end
        iterAll = iterAll + 1;
    end 
    if( iterAll > randSize) 
        break;
    end
end

dirich = DirichMixConstrained; % construct an object of the class
dirich.SetDimension(size(X,2));
dirich.SetE(E);
dirich.InputData(X);
dirich.DoIteration(10); % 100 iterations

clusters = unique(dirich.c);
for i=1:1:size(clusters,1)
   pts = dirich.data(find(dirich.c == clusters(i,1)),:);
   plot(pts(:, 1), pts(:, 2), 'x', 'color', rand(1,3));
   hold on
end

for i=1:1:size(clusters,1)
   pts = dirich.data(find(dirich.c == clusters(i,1)),:);
   m = mean(pts);
   plot(m(:, 1), m(:, 2),'--rs','LineWidth',2,...
                    'MarkerEdgeColor','k',...
                    'MarkerFaceColor','g',...
                    'MarkerSize',10);
   hold on
end


%% constrained bp-means : fast 
E = zeros(size(Y, 1), size(Y, 1)); 
Checked = zeros(size(Y, 1), size(Y, 1)); 
randSize = 0.01 * size(Y, 1) * size(Y, 1); 
iterAll = 1;
while(1)
    i1 = randi(size(Y, 1)); 
    i2 = randi(size(Y, 1)); 
    if Checked(i1, i2) == 0   
        Checked(i1, i2) = 1;
        if Y(i1) == Y(i2)
            E(i1, i2) = 1; 
            E(i2, i1) = 1; 
        else 
            E(i1, i2) = -1; 
            E(i2, i1) = -1; 
        end
        iterAll = iterAll + 1;
    end 
    if( iterAll > randSize) 
        break;
    end
end

lambda = 7; 
xi = 1; 
% figure; 
[centroid, pointsInCluster, assignment, clusterSize] = constrained_dpmeans_fast(X, lambda, E, xi); 
figure; 
% Xtmp = X(Y ==1, :);
% plot(Xtmp(:, 1), Xtmp(:, 2), 'xr')
hold on;
% Xtmp = X(Y ==-1, :);
% plot(Xtmp(:, 1), Xtmp(:, 2), 'xb')
for i = 1:clusterSize 
    plot(centroid(i,1), centroid(i,2),'--rs','LineWidth',2,...
                    'MarkerEdgeColor','k',...
                    'MarkerFaceColor','g',...
                    'MarkerSize',10)
    Xtmp = X(assignment ==i, :);
    plot(Xtmp(:, 1), Xtmp(:, 2), 'x',  'color', rand(1,3))
end

%% constrained bp-means : slow 
E = zeros(size(Y, 1), size(Y, 1)); 
Checked = zeros(size(Y, 1), size(Y, 1)); 
randSize = 0.01 * size(Y, 1) * size(Y, 1); 
iterAll = 1;
while(1)
    i1 = randi(size(Y, 1)); 
    i2 = randi(size(Y, 1)); 
    if Checked(i1, i2) == 0   
        Checked(i1, i2) = 1;
        if Y(i1) == Y(i2)
            E(i1, i2) = 1; 
            E(i2, i1) = 1; 
        else 
            E(i1, i2) = -1; 
            E(i2, i1) = -1; 
        end
        iterAll = iterAll + 1;
    end 
    if( iterAll > randSize) 
        break;
    end
end

lambda = 6.1; 
xi = 1; 
% figure; 
[centroid, pointsInCluster, assignment, clusterSize] = constrained_dpmeans_slow(X, lambda, E, xi); 
figure; 
% Xtmp = X(Y ==1, :);
% plot(Xtmp(:, 1), Xtmp(:, 2), 'xr')
hold on;
% Xtmp = X(Y ==-1, :);
% plot(Xtmp(:, 1), Xtmp(:, 2), 'xb')
for i = 1:clusterSize 
    plot(centroid(i,1), centroid(i,2),'--rs','LineWidth',2,...
                    'MarkerEdgeColor','k',...
                    'MarkerFaceColor','g',...
                    'MarkerSize',10)
    Xtmp = X(assignment ==i, :);
    plot(Xtmp(:, 1), Xtmp(:, 2), 'x',  'color', rand(1,3))
end

