function [mvpd,gof,fc,fc_pc]=data2mvpd_gof_fc(Ya,Yb,options);
% calculates the MultiVariate Pattern Dependence (MVPD) between two
% multivariate time series (Anzellotti et al. 2017, Plos Comput Biol), the 
% goodness-of-fit (GOF) metric (Basti et al. 2019), the Pearson correlation
% between the average time series and the one between the first two
% principal components (PCs).
%
% Input:
% Ya and Yb:  two cell arrays. The number of cells represents the number of runs, 
%             and the dimension of each cell is equal to ntxna, for the ROI1,
%             and ntxnb, for the ROI2.
% options     method: either pca_exvar or pca_ndir; either percentage or number:  
%             the percentage of variance that we want to explain by applying 
%             dimensionality reduction approach or the number ofICs to be considered.            
% Output: 
% mvpd:       MVPD value.
% gof:        GOF value (correlation between estimated and actual RDMs)
% fc:         Pearson correlation coefficient between average time series.
% fc:         Pearson correlation coefficient between first two PCs.
% Alessio Basti 
% version: 16/07/2019

for irun=1:length(Ya)
    %Ya_zs{irun} = zscore(Ya{irun},0,2);
    %Yb_zs{irun} = zscore(Yb{irun},0,2);
    Ya_zs{irun} = Ya{irun};
    Yb_zs{irun} = Yb{irun};
    % get the voxel-average ts
    ts_a{irun} = mean(Ya{irun},2);
    ts_b{irun} = mean(Yb{irun},2);
    % compute the pearson correlation
    fc_app(irun) = corr(ts_a{irun},ts_b{irun});
    [PC1_a{irun}]=dimreduction(Ya{irun},'pca_ndir',options);
    [PC1_b{irun}]=dimreduction(Yb{irun},'pca_ndir',options);
    fc_PCs_app(irun) = corr(PC1_a{irun},PC1_b{irun});
end

method=zeros(2,1);
for jmet=1:1
    if(jmet==1)
       Ya_app=Ya_zs; 
       Yb_app=Yb_zs;
    else
       Ya_app=ts_a; 
       Yb_app=ts_b;
    end
    for irun=1:length(Ya_app)

        % let us divide the training set from the testing set
        Yatrain=Ya_app;
        Ybtrain=Yb_app;
        Yatrain{irun}=[];
        Ybtrain{irun}=[];
        Yatrain=vertcat(Yatrain{:});
        Ybtrain=vertcat(Ybtrain{:});
        Yatest=Ya_app{irun};
        Ybtest=Yb_app{irun};

        % application of the dimensionality reduction, e.g. selection of the directions which explain
        % a sufficient amount of variance (coded by the input parameter 'percentage')
        [Yatrain_red,Va,SVa]=dimreduction(Yatrain,options.method,options);
        [Ybtrain_red,Vb,SVb]=dimreduction(Ybtrain,options.method,options);

        % linear model estimate (least-squares)
        [B,~]=ridgeregmethod(Yatrain_red,Ybtrain_red,0);
        Yatest_red=(Yatest-repmat(mean(Yatest),length(Yatest(:,1)),1))*Va;
        Ybtest_red=(Ybtest-repmat(mean(Ybtest),length(Ybtest(:,1)),1))*Vb;
        
        % correlation between the forecasted and the test data
        Ybtest_for_red=Yatest_red*B';
        for icomp=1:length(Ybtest_for_red(1,:))
            M=corrcoef(Ybtest_red(:,icomp),Ybtest_for_red(:,icomp));
            method(jmet)=method(jmet)+(SVb(icomp)/sum(SVb))*M(1,2);
        end
        
        % linear model estimate (ridge regression)
        zYa{1}=zscore(Ya{irun},0,2);
        zYb{1}=zscore(Yb{irun},0,2);
        [B,~]=ridgeregmethod(zYa{1},zYb{1},options.regularisation);
        zYb_for{1}=zYa{1}*B';
        
        % correlation between the estimated and the actual RDM for the ROI2
        [gof(irun,jmet),~] = data2rc(zYb,zYb_for,'Correlation');
    end
end

mvpd=method(1)/length(Ya_app);
gof=mean(gof(:,1));
fc=mean(fc_app);
fc_pc=mean(fc_PCs_app);

end
