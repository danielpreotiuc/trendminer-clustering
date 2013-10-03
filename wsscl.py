import sys
import cherrypy
import json
import pickle
import numpy as np
import math

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
    coh={}
    k=1
    for line in f:
      l=line.strip().split()
      coh[k]=int(l[0])
      k=k+1
    f.close()
    self.coherence=coh

  @cherrypy.tools.json_out()
  def POST(self,t=10,coh=3):
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
            if self.coherence[i]>=coh:
              noc=noc+1
              lst.append(tok)
              cls.append(i)
          except:
            pass
      if noc>0:
        for i in lst:
          s[self.words[i]]=s[self.words[i]]+self.scores[i]
    sf=s/sum(s)
    ts={}
    for i in sorted(range(len(sf)), key=lambda i: sf[i], reverse=True)[:int(t)]:
      ts[i]=sf[i][0]
    return ts

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
  cherrypy.tree.mount(Cluster(), '/cluster',{'/': {'request.dispatch': cherrypy.dispatch.MethodDispatcher()} })
  cherrypy.tree.mount(Words(), '/words',{'/': {'request.dispatch': cherrypy.dispatch.MethodDispatcher()} })
  cherrypy.config.update({'server.socket_port': 8080})
  cherrypy.engine.start()
  cherrypy.engine.block()

