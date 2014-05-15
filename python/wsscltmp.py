import sys
import cherrypy
import json
import pickle
import numpy as np
import math
import os

class Topics:
  exposed = True

  def __init__(self):
    self.stopw=pickle.load(open("stopwords.p","rb"))
    self.loadwords(fcl)
    self.loadlab(flab)

  def loadwords(self, cluster_file):
    f=open(cluster_file,'r')
    wo={};
    sc={};
    mcl=0
    for line in f:
      l=line.strip().split()
      wo[l[0]]=int(l[1])
      sc[l[0]]=float(l[2])
      if int(l[1])>mcl:
        mcl=int(l[1])
    f.close()
    self.maxcl=mcl+1
    self.words=wo
    self.scores=sc

  def loadlab(self, labels_file="cl.lab"):
    f=open(labels_file,'r')
    cohe={}
    k=1
    for line in f:
      l=line.strip().split()
      cohe[k]=int(l[0])
      k=k+1
    f.close()
    self.coherence=cohe

  @cherrypy.tools.json_out()
  def POST(self,t=10,coh=3):
    ccoh=int(coh)
    cl=cherrypy.request.headers['Content-Length']
    raw_body=cherrypy.request.body.read(int(cl))
    lines=raw_body.splitlines()
    s=np.zeros(shape=(self.maxcl,1))
    for line in lines:
      try:
        tweet=json.loads(line)
        toks=tweet['analysis']['tokens']['all']
      except:
        continue
      notok=len(toks)
      now=0
      noc=0
      cls=[]
      lst=[]
      for tok in toks:
        try: 
          ii=stopw[tok.lower()]
        except:
          try:
            now=now+1
            i=self.words[tok]
            if self.coherence[i]>=ccoh:
              noc=noc+1
              lst.append(tok)
              cls.append(i)
          except:
            pass
      if noc>0:
        for i in lst:
          s[self.words[i]]=s[self.words[i]]+self.scores[i]
    ss=s[1:]
    sf=ss/sum(ss)
    ts={}
    for i in sorted(range(len(sf)), key=lambda i: sf[i], reverse=True)[:int(t)]:
      ts[i+1]=sf[i][0] 
    return ts

class Recluster:
  exposed = True

  def __init__(self):
    pass
  
  @cherrypy.tools.json_out()
  def POST(self,voct=5,npmit=0.1,knn=30,nocl=100,outf='tmp1'):
    cl=cherrypy.request.headers['Content-Length']
    raw_body=cherrypy.request.body.read(int(cl))
    lines=raw_body.splitlines()
    f=open(outf+'-raw','w')
    for line in lines:
      print >> f, line.strip()
    f.close()
    os.system('cat '+outf+'-raw | python dedup.py > '+outf+'-dedup')
    os.system('cat '+outf+'-dedup | python wc-map.sh | sort | python wc-red.sh > wc.'+outf+'-dedup')
    os.system('cat wc.'+outf+'-dedup | python wc-filter.py '+str(voct)+' | python makevoc.py > '+outf+'.dict')
    os.system('cat '+outf+'-dedup | python wc-map-dict.sh '+outf+'.dict | sort | python wc-red.sh > '+outf+'-dedup.wc')
    os.system('cat '+outf+'-dedup | python pmi-map-ml.sh '+outf+'.dict | sort | python wc-red.sh > '+outf+'-dedup.wco')
    os.system('python compute-npmi.py '+outf+'-dedup.wc '+outf+'-dedup.wco > '+outf+'-dedup.npmi')
    os.system('cat '+outf+'-dedup.npmi | python truncate.py '+str(npmit)+' | python sym.py > '+outf+'-dedup-sym-'+str(npmit)+'.npmi')
    os.system('python run_spectral.py -tweets '+outf+'-raw -npmi '+outf+'-dedup-sym-'+str(npmit)+'.npmi -dict '+outf+'.dict -k '+str(knn)+' -c '+str(nocl))
    return 'Finished clustering, results are in cl.'+outf+' +'+str(nocl)
 

class Cluster:
  def __init__(self):
    self.loadcl(fcl)
    self.loadlab(flab)

  def loadcl(self,cluster_file):
    f=open(cluster_file,'r') 
    cl=[];
    for line in f:
      l=line.strip().split()
      cl.append((l[0],int(l[1]),float(l[2])))
    f.close()
    self.cluster=cl

  def loadlab(self, labels_file="cl.lab"):
    f=open(labels_file,'r')
    lab={};
    coh={}
    k=1
    for line in f:
      l=line.strip().split()
      coh[k]=int(l[0])
      lab[k]=' '.join(l[1:])
      k=k+1
    f.close()
    self.labels=lab
    self.coherence=coh

  exposed=True
  @cherrypy.tools.json_out()
  def GET(self,c=1,t=10):
    cl=[]
    for (i,j,k) in self.cluster:
      if int(j)==int(c):
        cl.append((i,k));
    cs=sorted(cl,key=lambda el:el[1],reverse=True)[0:int(t)]
    top={}
    top["words"]={}
    for (i,k) in cs:
      top["words"][i]=k
    top["label"]=self.labels[int(c)]
    top["coherence"]=self.coherence[int(c)]
    return top

class Words:
  def  __init__(self,):
    self.loadwords(fcl)

  def loadwords(self, cluster_file):
    f=open(cluster_file,'r')
    wo={};
    for line in f:
      l=line.strip().split()
      wo[l[0]]=int(l[1])
    f.close()
    self.words=wo

  exposed=True
  @cherrypy.tools.json_out()
  def GET(self,w='#'):
    try:
      wo=self.words[w.strip().lower()]
      return wo
    except:
      return 
        
if __name__=='__main__':
  if len(sys.argv)==1:
    fcl="cl"
    flab="cl.lab"
  elif len(sys.argv)==2:
    fcl=sys.argv[1]
    flab=sys.argv[1]+".lab"
  elif len(sys.argv)==3:
    fcl=sys.argv[1]
    flab=sys.argv[2]
  else:
    exit()
  cherrypy.tree.mount(Topics(), '/topics',{'/': {'request.dispatch': cherrypy.dispatch.MethodDispatcher()} })
  cherrypy.tree.mount(Recluster(), '/recluster',{'/': {'request.dispatch': cherrypy.dispatch.MethodDispatcher()} })
  cherrypy.tree.mount(Cluster(), '/cluster',{'/': {'request.dispatch': cherrypy.dispatch.MethodDispatcher()} })
  cherrypy.tree.mount(Words(), '/words',{'/': {'request.dispatch': cherrypy.dispatch.MethodDispatcher()} })
  cherrypy.config.update({'server.socket_port': 8080})
  cherrypy.engine.start()
  cherrypy.engine.block()

