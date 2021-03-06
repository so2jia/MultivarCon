function [mim,imcoh_svd,mvlagcoh,lagcoh_svd]=data2lagconn(X,Y,opt);
% It calculates the multivariate interaction measure (MIM) between two multivariate time series
% as described in Ewald et al.(2012), the imaginary part of coherency approach on the first SVs,
% and the multivariate and univariate (on the first SVs) lagged coherence 
% (Pascual-Marqui et al. 2007a; 2007b). Part of the code (e.g. the function to compute the cross-spectral matrix)
% was taken from http://doc.ml.tu-berlin.de/causality/ and it is also
% included in the METH toolbox (UKE, https://www.uke.de/english/departments-institutes/institutes/neurophysiology-
% and-pathophysiology/research/research-groups/index.html).
% Input:
% X and Y:       two matrices of dimensions Tx(na) and Tx(nb), where T is the
%                number of time points and na (nb) is the number of scalar time series
%                within the region A (B).
% opt.segleng:   segment length in bins, (frequency resolution is determined by it) 
% opt.freqbins:  K vector. It contains the frequencies (in bins) over which  MIM is calculated.
%                By setting freqbins=[] MIM is calculated across all
%                frequencies (wide band). If the segleng is interpreted e.g. as
%                a 1 second acquisition, then a freqbins=[9:13] calculates the
%                methods in alpha frequency band 8-12Hz.
% 
% Output: 
% mim:           MIM value.
% imcoh_svd:     ImCoh value on the first SVs
% mvlagcoh:      MVlagcoh value.
% lagcoh:        LagCoh value on the first SVs
% Alessio Basti 
% version: 04/07/2019

opt.number=1;
for irun=1:length(X)
    [ndat na]=size(X{irun});
    [ndat nb]=size(Y{irun});
    data=[X{irun}';Y{irun}']';
    data_univ=[mean(X{irun},2)';mean(Y{irun},2)']';
    [C1_a{irun}]=dimreduction(X{irun},'svd_ndir',opt);
    [C1_b{irun}]=dimreduction(Y{irun},'svd_ndir',opt);
    data_univ_svd=[C1_a{irun}';C1_b{irun}']';
    segshift=opt.segleng/2;
    epleng=2*opt.segleng;

    if length(epleng)==0
        method='none';
        epleng=ndat;
    end
    if length(opt.freqbins)==0
        maxfreqbin=floor(opt.segleng/2)+1;
        opt.freqbins=1:maxfreqbin;
    else
        maxfreqbin=max(max(opt.freqbins));
    end

    para.segave=1;
    para.subave=0;

    % compute the cross-spectral matrices
    [cs,nave]          =data2cs_event(data,opt.segleng,segshift,epleng,maxfreqbin,para);
    [cs_univ_svd,nave] =data2cs_event(data_univ_svd,opt.segleng,segshift,epleng,maxfreqbin,para);

    % compute MIM, ImCoh on the first SVs
    mim(irun)       =cs2mim(cs(:,:,opt.freqbins(1,:)),na,nb);
    imcoh_svd(irun) =cs2mim(cs_univ_svd(:,:,opt.freqbins(1,:)),1,1);
    
    % compute MVlagcoh and lagcoh on the first SVs
    mvlagcoh(irun)   =cs2mvlagcoh(cs(:,:,opt.freqbins(1,:)),na,nb);
    lagcoh_svd(irun) =cs2lagcoh(cs_univ_svd(:,:,opt.freqbins(1,:))); 
end

mim=mean(mim);
imcoh_svd=mean(imcoh_svd);

mvlagcoh=mean(mvlagcoh);
lagcoh_svd=mean(lagcoh_svd);

return

function[mim]=cs2mim(cs,na,nb); 
    
mim=zeros(2,2);
% cross-spectral matrices within (sa, sb) and between the two data spaces (sab)
sa=cs(1:na,1:na,:);
sb=cs(na+1:na+nb,na+1:na+nb,:);
sab=cs(1:na,na+1:na+nb,:);

% start calculation of MIM
F=length(cs(1,1,:));
for f=1:F
    tol1=max(size(real(sa(:,:,f))))*norm(real(sa(:,:,f)))*10^(-10);
    tol2=max(size(real(sb(:,:,f))))*norm(real(sb(:,:,f)))*10^(-10);
    mim(1,2)=mim(1,2)+trace(pinv(real(sa(:,:,f)),tol1)*imag(sab(:,:,f))*pinv(real(sb(:,:,f)),tol2)*(imag(sab(:,:,f))'));
end
mim=mim(1,2)/(min([na,nb])*F);

return

function[mvlagcoh]=cs2mvlagcoh(cs,na,nb); 
    
mvlagcoh=zeros(2,2);
% cross-spectral matrices within (sa, sb) and between the two data spaces (sab)
sa=cs(1:na,1:na,:);
sb=cs(na+1:na+nb,na+1:na+nb,:);
sab=cs(1:na,na+1:na+nb,:);
sba=cs(na+1:na+nb,1:na,:);

% start calculation of MVlagcoh
F=length(cs(1,1,:));
for f=1:F
    mat1=[squeeze(sb(:,:,f)),squeeze(sba(:,:,f));squeeze(sab(:,:,f)),squeeze(sa(:,:,f))];
    mat2=[squeeze(sb(:,:,f)),zeros(size(squeeze(sba(:,:,f))));zeros(size(squeeze(sab(:,:,f)))),squeeze(sa(:,:,f))];
    %mvlagcoh(1,2)=mvlagcoh(1,2)+real(log((det(real(mat1))/det(real(mat2)))/(det(mat1)/det(mat2))));
    %to allow the method to lie in the range [0,1]
    mvlagcoh(1,2)=mvlagcoh(1,2)+1-1/real((det(real(mat1))/det(real(mat2)))/(det(mat1)/det(mat2)));
end
mvlagcoh=mvlagcoh(1,2)/F;

return

function[lagcoh]=cs2lagcoh(cs); 
    
lagcoh=zeros(2,2);
% power and cross-spectrum
sa=cs(1,1,:);
sb=cs(2,2,:);
sab=cs(1,2,:);

% start calculation of lagcoh
F=length(cs(1,1,:));
for f=1:F
    lagcoh(1,2)=lagcoh(1,2)+imag(sab(:,:,f))^2/(sa(:,:,f)*sb(:,:,f)-real(sab(:,:,f))^2);
end
lagcoh=real(lagcoh(1,2))/F;

return

function [cs,nave]=data2cs_event(data,segleng,segshift,epleng,maxfreqbin,para);
% usage: [cs,nave]=data2cs_event(data,segleng,segshift,epleng,maxfreqbin,para)
% 
% calculates cross-spectra from data for event-related measurement
% input: 
% data: ndat times nchan matrix each colum is the time-series in one
%             channel;
% segleng: length of each segment in bins, e.g. segleng=1000;  
% segshift: numer of bins by which neighboring segments are shifted;
%           e.g. segshift=segleng/2 makes overlapping segments
% epleng: length of each epoch
% maxfreqbin: max frequency in bins
% para: optional structure:
%       para.segave=0  -> no averaging across segments 
%       para.segave neq 0 -> averaging across segments (default is 0)% \
%       para.subave =1 subtracts the average across epochs,  
%       para.subave ~= 1 -> no subtraction (default is 1) 
%       IMPORTANT: if you just one epoch (e.g. for continuous data)
%         set para.subave=0 
%         
%       -> averaging across segments (default is 0)
%       para.proj must be a set of vector in channel space,  
%       if it exists then the output raw contains the single trial 
%       Fourier-transform in that channel   
%     
%         
% output: 
% cs: nchan by chan by maxfreqbin by nseg tensor cs(:,:,f,i) contains 
%     the cross-spectrum at frequency f and segment i
%     
% nave: number of averages

subave=1; 

if nargin<6
    para=[];
end

maxfreqbin=min([maxfreqbin,floor(segleng/2)+1]);

segave=0;
mydetrend=0;
proj=[];
  if isfield(para,'segave')
    segave=para.segave;
  end 
   if isfield(para,'detrend')
    mydetrend=para.detrend;
  end 
  if isfield(para,'proj')
    proj=para.proj;
  end 
  if isfield(para,'subave')
    subave=para.subave;
  end 

[ndum,npat]=size(proj);

[ndat,nchan]=size(data);
if npat>0 
   data=data*proj;
   nchan=npat;
end

nep=floor(ndat/epleng);

nseg=floor((epleng-segleng)/segshift)+1; %total number of segments



if segave==0
 cs=zeros(nchan,nchan,maxfreqbin,nseg); 
 av=zeros(nchan,maxfreqbin,nseg);
else
 cs=zeros(nchan,nchan,maxfreqbin); 
 av=zeros(nchan,maxfreqbin);
end

if npat>0
  if segave==0
    cs=zeros(nchan,nchan,maxfreqbin,nep,nseg); 
    av=zeros(nchan,maxfreqbin,nep,nseg);
  else
    cs=zeros(nchan,nchan,maxfreqbin,nep); 
    av=zeros(nchan,maxfreqbin,nep);
  end
end


mywindow=repmat(hanning(segleng),1,nchan);
if isfield(para,'mywindow');
    mywindow=repmat(para.mywindow,1,nchan);
end

 %figure;plot(mywindow);
nave=0;
for j=1:nep;
    dataep=data((j-1)*epleng+1:j*epleng,:);
    for i=1:nseg; %average over all segments;
        dataloc=dataep((i-1)*segshift+1:(i-1)*segshift+segleng,:);
        if mydetrend==1
           datalocfft=fft(detrend(dataloc,0).*mywindow);
        else
           datalocfft=fft(dataloc.*mywindow);
        end
        
         for f=1:maxfreqbin % for all frequencies
          if npat==0
             if segave==0
                 cs(:,:,f,i)=cs(:,:,f,i)+conj(datalocfft(f,:)'*datalocfft(f,:)); 
		 av(:,f,i)=av(:,f,i)+conj(datalocfft(f,:)');
             else 
                %disp([i,f,size(datalocfft)])
                cs(:,:,f)=cs(:,:,f)+conj(datalocfft(f,:)'*datalocfft(f,:)); 
		av(:,f)=av(:,f)+conj(datalocfft(f,:)');
             end
          else 
             if segave==0
                 cs(:,:,f,j,i)=conj(datalocfft(f,:)'*datalocfft(f,:));
                 av(:,f,j,i)=conj(datalocfft(f,:)');  
             else 
                %disp([i,f,size(datalocfft)])
                cs(:,:,f,j)=cs(:,:,f,j)+conj(datalocfft(f,:)'*datalocfft(f,:));
                av(:,f,j)=av(:,f,j)+conj(datalocfft(f,:)');  
             end
          end

        end
    end
    nave=nave+1;
end

if segave==0
  cs=cs/nave;
  av=av/nave;
else
  nave=nave*nseg;  
  cs=cs/nave;
  av=av/nave;
end

for f=1:maxfreqbin
  if subave==1
       if npat==0
          if segave==0
              for i=1:nseg;cs(:,:,f,i)=cs(:,:,f,i)-av(:,f,i)*av(:,f,i)';end;
          else 
              cs(:,:,f)=cs(:,:,f)-av(:,f)*av(:,f)';
          end
       else 
          if segave==0
              for i=1:nseg;for j=1:nep;
                  cs(:,:,f,j,i)=cs(:,:,f,j,i)-av(:,f,j,i)*av(:,f,j,i)';
              end;end;
          else 
              for j=1:nep;cs(:,:,f,j)=cs(:,:,f,j)-av(:,f,j)*av(:,f,j)';end
          end
       end
  end
end

return;
