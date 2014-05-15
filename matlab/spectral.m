function c = spectral(tweetfile,npmifile,dictfile,k,noc)
Ptmp=textscan(fopen(npmifile),'%f %f %f');
PP=textscan(fopen(dictfile),'%d %s');
PMI=sparse(Ptmp{1},Ptmp{2},Ptmp{3},size(PP{1},1),size(PP{1},1));
W=knnmatrix(PMI,k);
W=min(W,W');
[s,comp]=graphconncomp(W,'Directed','false');
WW=W(comp==mode(comp),comp==mode(comp));
P=PP{2}(comp==mode(comp));
ids{1}=P;
X{1}=WW;
clear Ptmp
clear PMI 
clear W
clear s
addpath('affect')
[c,W_bar,alpha]=batch_affect_spectral(ids,X,noc);
save(strcat('vars.',tweetfile,'-',int2str(noc)))
idssub=PP{1}(comp==mode(comp));
fid=fopen(strcat('cl.',tweetfile,'-',int2str(noc)),'w');
for i=1:max(c{1})
  cl=find(c{1}==i);
  [b,wordsix] = centralityn(cl,X{1},ids{1});
  for j=1:length(b)
    word=wordsix(j);
    fprintf(fid,'%s %d %.5f\n',word{1},i,b(j));
  end
end
fclose(fid);
