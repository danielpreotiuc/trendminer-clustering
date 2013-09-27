function [WN] = knnmatrix(W,k)

n=size(W,1);
indi=zeros(1,k*n);
indj=zeros(1,k*n);
inds=zeros(1,k*n);
for ii=1:n
	[s,o]=sort(W(ii,1:n),'descend');
	indi(1,(ii-1)*k+1:ii*k)=ii;
	indj(1,(ii-1)*k+1:ii*k)=o(1:k);
	inds(1,(ii-1)*k+1:ii*k)=s(1:k);
end
WN=sparse(indi,indj,inds,n,n);

end
