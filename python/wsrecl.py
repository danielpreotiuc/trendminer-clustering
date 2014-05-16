import sys
import time
import cherrypy
import json
import pickle
import numpy as np
import math
import os
import datetime

class Recluster:
  exposed = True

  def __init__(self):
    pass
  
  @cherrypy.tools.json_out()
  def POST(self,voct=5,npmit=0.1,knn=30,nocl=100,outf='tmp'):
    cl=cherrypy.request.headers['Content-Length']
    raw_body=cherrypy.request.body.read(int(cl))
    lines=raw_body.splitlines()
    dnow=datetime.datetime.now()
#    fdir=outf+'-'+str(dnow.year)+'-'+str(dnow.month)+'-'+str(dnow.day)+'-'+str(dnow.hour)+'-'+str(dnow.minute)+'-'+str(dnow.second)
    fdir=outf+'-'+str(int(time.time()))
    os.mkdir(fdir)
    f=open(fdir+"/"+outf+'-raw','w')
    for line in lines:
      print >> f, line.strip()
    f.close()
    os.system('cat '+fdir+'/'+outf+'-raw | python dedup.py > '+fdir+'/'+outf+'-dedup')
    os.system('cat '+fdir+'/'+outf+'-dedup | python wc-map.sh | sort | python wc-red.sh > '+fdir+'/'+outf+'-dedup.wc')
    os.system('cat '+fdir+'/'+outf+'-dedup.wc | python wc-filter.py '+str(voct)+' | python makevoc.py > '+fdir+'/'+outf+'.dict')
    os.system('cat '+fdir+'/'+outf+'-dedup | python wc-map-dict.sh '+fdir+'/'+outf+'.dict | sort | python wc-red.sh > '+fdir+'/'+outf+'-dedup.wc')
    os.system('cat '+fdir+'/'+outf+'-dedup | python pmi-map-ml.sh '+fdir+'/'+outf+'.dict | sort | python wc-red.sh > '+fdir+'/'+outf+'-dedup.wco')
    os.system('python compute-npmi.py '+fdir+'/'+outf+'-dedup.wc '+fdir+'/'+outf+'-dedup.wco > '+fdir+'/'+outf+'-dedup.npmi')
    os.system('cat '+fdir+'/'+outf+'-dedup.npmi | python truncate.py '+str(npmit)+' | python sym.py > '+fdir+'/'+outf+'-dedup-sym-'+str(npmit)+'.npmi')
    os.system('python run_spectral.py -tweets '+fdir+' -npmi '+fdir+'/'+outf+'-dedup-sym-'+str(npmit)+'.npmi -dict  '+fdir+'/'+outf+'.dict -k '+str(knn)+' -c '+str(nocl))
    outstr='Finished clustering, results are in cl.'+fdir+'-'+str(nocl)
    return outstr
 
if __name__=='__main__':
  cherrypy.tree.mount(Recluster(), '/recluster',{'/': {'request.dispatch': cherrypy.dispatch.MethodDispatcher()} })
  cherrypy.config.update({'server.socket_port': 8088})
  cherrypy.engine.start()
  cherrypy.engine.block()

