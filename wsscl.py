import cherrypy
import simplejson
import json
import pickle
from collections import Counter
import numpy as np
import math

class Topics:
  exposed = True

  def __init__(self):
    self.stopw=pickle.load(open("stopwords.p","rb"))
    self.loadwords()

  def loadwords(self, cluster_file='cl-sora-200w-ncen'):
    f=open(cluster_file,'r')
    wo={};
    sc={};
    for line in f:
      l=line.strip().split()
      wo[l[0]]=int(l[1])
      sc[l[0]]=float(l[2])
    f.close()
    self.words=wo
    self.scores=sc

  @cherrypy.tools.json_out()
  def POST(self,t=10):
    cl=cherrypy.request.headers['Content-Length']
    raw_body=cherrypy.request.body.read(int(cl))
    lines=raw_body.splitlines()
    s=np.zeros(shape=(201,1))
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
            noc=noc+1
            lst.append(tok)
            cls.append(i)
          except:
            pass
      if noc>0:
#        s=np.zeros(shape=(201,1))
        for i in lst:
          s[self.words[i]]=s[self.words[i]]+self.scores[i]
#        scfin=max(s)/math.sqrt(notok)
#        cid=np.where(scfin==max(scfin))[0][0]
#        ts[cid]=ts[cid]+1
    sf=s/sum(s)
    ts={}
    for i in sorted(range(len(sf)), key=lambda i: sf[i], reverse=True)[:int(t)]:
      ts[i]=sf[i][0]
#      if int(ss[i][0])<10:
#        s1[i]=float(s[i][0])
#      for i in range(1,10):
#        s1[ss[i][0]]=int(s[ss[i]])
    return ts

class Cluster:
  def __init__(self, cluster_file = "cl-sora-200w-ncen"):
    self.loadcl(cluster_file)
    self.loadlab(cluster_file)

  def loadcl(self, cluster_file):
    f=open('cl-sora-200w-ncen','r') 
    cl=[];
    for line in f:
      l=line.strip().split()
      cl.append((l[0],int(l[1]),float(l[2])))
    f.close()
    self.cluster=cl

  def loadlab(self, labels_file):
    f=open('cl-sora-200-labels','r')
    lab={};
    k=1
    for line in f:
      l=line.strip()
      lab[k]=l
      k=k+1
    f.close()
    self.labels=lab

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
    return top

class Words:
  def  __init__(self, cluster_file = "cl-sora-200w-ncen"):
    self.loadwords(cluster_file)

  def loadwords(self, cluster_file):
    f=open('cl-sora-200w-ncen','r')
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
  cherrypy.tree.mount(Topics(), '/topics',{'/': {'request.dispatch': cherrypy.dispatch.MethodDispatcher()} })
  cherrypy.tree.mount(Cluster(), '/cluster',{'/': {'request.dispatch': cherrypy.dispatch.MethodDispatcher()} })
  cherrypy.tree.mount(Words(), '/words',{'/': {'request.dispatch': cherrypy.dispatch.MethodDispatcher()} })
  cherrypy.engine.start()
  cherrypy.engine.block()

