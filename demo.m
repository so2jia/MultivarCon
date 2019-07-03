close all
clear;
clc;
rng('default')

% Parameter settings
nSubj = 20;         % number of subjects (replications)
nTime = 200;        % number of time poinTimes
nVoxs = [50 60];    % number of voxels in ROI1 and ROI2
mVoxs = min(nVoxs);
nRuns = 2;          % number of runs. MVPD requires at least 2 runs.
Noise = 1;          % std of Noise in ROI2

% MVPD parameters
opt.method='pca_exvar';
opt.percentage=99;

%% First example: positively correlated voxel activities within ROI1 (where both UniConn and MultiConn work)

fnam = 'Positively correlated voxel activities within a ROI';
%T = rand(nVoxs);
T = zeros(nVoxs); for j=1:mVoxs; T(j,j)=1; end
cc = 0.5;
C = ones(nVoxs(1))*cc + eye(nVoxs(1))*(1-cc); % correlation within ROI
Ya = {}; Yb = {};
for g=1:nSubj
    for r=1:nRuns
        Ya{g}{r} = mvnrnd(zeros(nTime,nVoxs(1)),C);
        Yb{g}{r} = Ya{g}{r}*T + Noise*randn(nTime,nVoxs(2));
    end
end
vis = [1 2 1 2];
%vis = 2;
[MVconn,MVconn_null] = computeMVconn(Ya,Yb,opt);
plotmv(fnam,T,C,Ya,Yb,MVconn,MVconn_null,vis)

saveas(gcf,'Graphics/mvcon_example1.png','png')

%% Second example: anticorrelated voxel activities within ROI1 (where MulitCon work better)

fnam = 'Negatively correlated voxel activities within a ROI';
%T = rand(nVoxs);
T = zeros(nVoxs); for j=1:mVoxs; T(j,j)=1; end
cc = 0.9;
C = kron([cc -cc; -cc cc],ones(nVoxs(1)/2)) + (1-cc)*eye(nVoxs(1));
Ya = {}; Yb = {};
for g=1:nSubj
    for r=1:nRuns
        Ya{g}{r} = mvnrnd(zeros(nTime,nVoxs(1)),C);
        Yb{g}{r} = Ya{g}{r}*T + Noise*randn(nTime,nVoxs(2));
    end
end
vis = 2;
%vis = [1 nVoxs(1)/2+1 1 nVoxs(2)/2+1];
[MVconn,MVconn_null] = computeMVconn(Ya,Yb,opt);
plotmv(fnam,T,C,Ya,Yb,MVconn,MVconn_null,vis)
saveas(gcf,'Graphics/mvcon_example2.png','png')

%% Third example: anticorrelation in ROI2 induced by the functional mapping (where MulitCon work better)

fnam = 'Negative correlations induced by the functional mapping';
%T = rand(nVoxs)-0.5;
T = zeros(nVoxs); for j=1:mVoxs/2; T(j,j)=1; T(j+mVoxs/2,j+mVoxs/2)=-1; end
cc = 0.5;
C = ones(nVoxs(1))*cc + eye(nVoxs(1))*(1-cc); % correlation within ROI
Ya = {}; Yb = {};
for g=1:nSubj
    for r=1:nRuns
        Ya{g}{r} = mvnrnd(zeros(nTime,nVoxs(1)),C);
        Yb{g}{r} = Ya{g}{r}*T + Noise*randn(nTime,nVoxs(2));
    end
end
vis = 2;
[MVconn,MVconn_null] = computeMVconn(Ya,Yb,opt);
plotmv(fnam,T,C,Ya,Yb,MVconn,MVconn_null,vis)
saveas(gcf,'Graphics/mvcon_example3.png','png')

%% Fourth example: run-dependent linear mapping (where MVPD fails)

fnam = 'Run-dependent linear connectivity';
cc = 0.5;
C = kron([cc -cc; -cc cc],ones(nVoxs(1)/2)) + cc*eye(nVoxs(1));
%C = eye(nVoxs);
Ya = {}; Yb = {};
for g=1:nSubj
    for r=1:nRuns
       Ya{g}{r} = mvnrnd(zeros(nTime,nVoxs(1)),C);
       T = rand(nVoxs)-0.5;
       Yb{g}{r} = Ya{g}{r}*T + Noise*randn(nTime,nVoxs(2));
    end
end
vis = 2;
[MVconn,MVconn_null] = computeMVconn(Ya,Yb,opt);
plotmv(fnam,T,C,Ya,Yb,MVconn,MVconn_null,vis)
saveas(gcf,'Graphics/mvcon_example4.png','png')

%% Fifth example: the functional mapping is nonlinear (where Dcor works best)

fnam = 'Nonlinear connectivity';
%T = rand(nVoxs);
T = zeros(nVoxs); for j=1:mVoxs; T(j,j)=1; end
cc = 0.5;
C = ones(nVoxs(1))*cc + eye(nVoxs(1))*(1-cc); % correlation within ROI
%C = kron([cc -cc; -cc cc],ones(nVoxs(1)/2)) + cc*eye(nVoxs(1));
Ya = {}; Yb = {};
Noise = 0.5;
for g=1:nSubj
    for r=1:nRuns
       Ya{g}{r} = mvnrnd(zeros(nTime,nVoxs(1)),C);
       Yb{g}{r} = abs(Ya{g}{r}*T) + Noise*randn(nTime,nVoxs(2));
    end
end
%vis = [1 nVoxs(1)/2+1 1 nVoxs(2)/2+1];
vis = 2;
[MVconn,MVconn_null] = computeMVconn(Ya,Yb,opt);
plotmv(fnam,T,C,Ya,Yb,MVconn,MVconn_null,vis)
saveas(gcf,'Graphics/mvcon_example5.png','png')

%% Sixth example: the presence of structured noise in ROI2 (where PCA works best)

fnam = 'Structured Noise in ROI2'; 
%T = rand(nVoxs);
T = zeros(nVoxs); for j=1:mVoxs; T(j,j)=1; end
cc = 0.5;
%C = ones(nVoxs(1))*cc + eye(nVoxs(1))*(1-cc); % correlation within ROI
C = kron([cc -cc; -cc cc],ones(nVoxs(1)/2)) + cc*eye(nVoxs(1));
Ya = {}; Yb = {};
Noise = 1;
for g=1:nSubj
    for r=1:nRuns
        Ya{g}{r} = mvnrnd(zeros(nTime,nVoxs(1)),C);
        Yb{g}{r} = Ya{g}{r}*T + Noise*randn(nTime,nVoxs(2));
        Yb{g}{r} = Yb{g}{r}   + 5*Noise*repmat(randn(nTime,1),1,nVoxs(2));
    end
end
vis = 2;
[MVconn,MVconn_null] = computeMVconn(Ya,Yb,opt);
plotmv(fnam,T,C,Ya,Yb,MVconn,MVconn_null,vis)
saveas(gcf,'Graphics/mvcon_example6.png','png')

%% Seventh example: averaging timepoints (trials) with same stimulus improves RCA

fnam = 'Negative correlations induced by the functional mapping; averaging across stimuli of same type';
%T = rand(nVoxs)-0.5;
T = zeros(nVoxs); for j=1:mVoxs/2; T(j,j)=1; T(j+mVoxs/2,j+mVoxs/2)=-1; end
Noise = 1;
nStim = 20;
nRep  = nTime/nStim;  % Assumes a factor of nTime
stimuli = repmat([1:nStim],1,nRep);

cc = 0;
C = ones(nVoxs(1))*cc + eye(nVoxs(1))*(1-cc); % correlation within ROI

Ya = {}; Yb = {};
for s=1:nSubj
    for r=1:nRuns
        Ya{s}{r} = mvnrnd(zeros(nStim,nVoxs(1)),C);
        Ya{s}{r} = repmat(Ya{s}{r},nRep,1);  % Repeat same pattern 
        Yb{s}{r} = Ya{s}{r}*T + Noise*randn(nTime,nVoxs(2));
%        Ya{g}{r} = Ya{g}{r} + Noise*randn(nTime,nVoxs(1));  % independent noise
    end
end

vis = 2;
%vis = [1 nVoxs(1)/2+1 1 nVoxs(2)/2+1];
[MVconn,MVconn_null] = computeMVconn(Ya,Yb,opt);
plotmv(fnam,T,C,Ya,Yb,MVconn,MVconn_null,vis)
saveas(gcf,'Graphics/mvcon_example7a.png','png')
mean(MVconn.RCA)

sYa = {}; sYb = {};
for s=1:nSubj
    for r=1:nRuns
        for stim = 1:nStim
            sYa{s}{r}(stim,:) = mean(Ya{s}{r}(find(stimuli==stim),:));
            sYb{s}{r}(stim,:) = mean(Yb{s}{r}(find(stimuli==stim),:));
        end
    end
end

vis = 2;
%vis = [1 nVoxs(1)/2+1 1 nVoxs(2)/2+1];
[sMVconn,sMVconn_null] = computeMVconn(sYa,sYb,opt);
plotmv(fnam,T,C,Ya,Yb,MVconn,MVconn_null,vis)
saveas(gcf,'Graphics/mvcon_example7b.png','png')
mean(sMVconn.RCA)

return

