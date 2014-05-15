function [b,wordsix] = centrality(c,M,P)
  a=[];
  simsum=zeros(1,length(c));
  for k = 1:length(c)
    val=0;
    for kk = 1:length(c)
      val=val+M(c(k),c(kk));
    end
    a=[a; val];
  end
  wordsix=P(c);  
  b=a/sum(a);
end
