function [MVconn,MVconn_null] = computeMVconn(Ya,Yb,opt)

if ~isfield(opt,'nRandomisation')
    opt.nRandomisation = 1;
end


% Calculate connectivity on data given
for s=1:length(Ya)
    if ~isfield(opt,'segleng') 
        [mvpd(s,1),gof(s,1),fc(s,1),fc_pc(s,1)] = data2mvpd_gof_fc(Ya{s},Yb{s},opt); 
        [dcor(s,1),dcor_u(s,1)] = data2dCor(Ya{s},Yb{s});
        [rc(s,1),~] = data2rc(Ya{s},Yb{s},'Correlation');
    else
       [mim(s,1),imcoh(s,1),imcoh_pc(s,1)] = data2mim(Ya{s},Yb{s},opt);
    end
end

% Calculate connectivity when Ya and Yb independent random noise (since
% some connectivity measures, eg Dcor, not bounded by 0 or -1)
if length(Ya)<20
    warning('Insufficient subjects (<20) to estimate baseline error')
else
    for iter = 1:opt.nRandomisation
        if opt.nRandomisation > 1
            fprintf('iteration %d from %d \n',iter,opt.nRandomisation)
        end
        for s=1:length(Ya) % Ensure reasonably accurate estimate
            bYa = {}; bYb = {};
            for r=1:length(Ya{s})
                bYa{r} = Ya{s}{r}(randperm(size(Ya{s}{r},1)),:);
                bYb{r} = Yb{s}{r}(randperm(size(Yb{s}{r},1)),:);
            end
            if ~isfield(opt,'segleng') 
                [bmvpd(s,iter),bgof(s,iter),bfc(s,iter),bfc_pc(s,iter)] = data2mvpd_gof_fc(bYa,bYb,opt);
                [bdcor(s,iter),bdcor_u(s,iter)] = data2dCor(bYa,bYb);
                [brc(s,iter),~] = data2rc(bYa,bYb,'Correlation');
            else
               [bmim(s,iter),bimcoh(s,iter),bimcoh_pc(s,iter)] = data2mim(bYa,bYb,opt);
            end
        end
    end
end

if ~isfield(opt,'segleng')
    MVconn.FC = fc;
    MVconn.FCPC = fc_pc;
    MVconn.MVPD = mvpd;
    MVconn.GOF = gof;
    MVconn.dCor = dcor;
    MVconn.RCA = rc;
else
    MVconn.MIM = mim;
    MVconn.ImCoh = imcoh;
    MVconn.ImCohPC = imcoh_pc;
end

if ~isfield(opt,'segleng')
    MVconn_null.FC = bfc;
    MVconn_null.FCPC = bfc_pc;
    MVconn_null.MVPD = bmvpd;
    MVconn_null.GOF = bgof;
    MVconn_null.dCor = bdcor;
    MVconn_null.RCA = brc;
else
    MVconn_null.MIM = bmim;
    MVconn_null.ImCoh = bimcoh;
    MVconn_null.ImCohPC = bimcoh_pc;
end

return










