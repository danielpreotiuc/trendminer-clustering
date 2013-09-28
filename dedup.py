import json
import sys
import re

# normal RT
regnrt=re.compile(r"\(*RT[\s!.-:]*@\w+([\)\s:]|$)")
# only RT at the start
regrt=re.compile(r"^RT[\s!.-:]+")
# username on twitter
reguser=re.compile(r"@\w+")
# in straight brackets
regbr=re.compile(r"\[.*\]")
# via retweets
regv1=re.compile(r"\(via @\w+\)")
regv2=re.compile(r" via @\w+")

def rttext(text):
# TO ADD remove chained RTs RT @user1 RT @user2 .... text
  rt=''
  com=''
  c=regnrt.search(text)
  if c:
    # RT[:] [comment] @user: rt-text , removing possible ':' after username
    rt=text[c.span()[1]:].strip().strip(':').strip()
    com=text[:c.span()[0]].strip().strip(':').strip()
    # (some users do) RT @user: rt-text \[comment\], but i'm not 100% sure so skipping for now
#      if com=='':
#        if regbr.search(text):
#          pass
    # if RT is at the end of the tweet the RT is the entire tweet
    if c.span()[1]==len(text):
      aux=com
      com=rt
      rt=aux
  else:
    # RT comment @user rt-text
    d=regrt.search(text)
    e=reguser.search(text)
    if d and e:
      com=text[d.span()[1]:e.span()[0]]
      rt=text[e.span()[1]:]
    # via with paranthesis
  a=regv1.search(text)
    # via without paranthesis
  if not a:
    a=regv2.search(text)
  if a:
    if a.span()[0]==0:
      # via @user[:] rt-text
      b=regbr.search(text)
      rt=re.sub('^:','',text[a.span()[1]:b.span()[0]].strip()).strip()
      com=b.group()[1:len(b.group())-1]
    else:
      # rt-text via @user, remove punctuation before via like | via or \via
      rt=re.sub('[|,.//]$','',text[:a.span()[0]].strip()).strip()
      com=re.sub('^:','',text[a.span()[1]:].strip()).strip()
  return rt,com

bf=[]
for line in sys.stdin:
  try:
    tweet=json.loads(line)
#    if '...' in tweet['analysis']['tokens']['all']:
#      print json.dumps(tweet['text'])
    text=tweet['text']
    texto=text
    textrt=''
# use Twitters RT detection
    try:
      textrt=tweet['retweeted_status']['text']
# use my Twitter detection
    except:
      textrt=rttext(text)[0]
    if not textrt=='':
      text=textrt
      continue
# deduplicate aggresive based on first 6 unprotected tokens
# youtube is an exception because of I liked/favourited/subscribed a YouTube video and deduplication is only based on the first 5 tokens
    utok=tweet['analysis']['tokens']['unprotected']
    text=' '.join(utok).lower()
    if len(utok)>=6:
      if 'YouTube' in utok:
        text=' '.join(utok[0:5])
      else:
        text=' '.join(utok[0:6])
# add to bloom filter
    if text in bf:
# add the commentary only if this exists
      pass
    else:
      print json.dumps(tweet)
      bf.append(text)
#      print json.dumps(tweet)
  except:
    continue
