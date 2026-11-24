import json,sys,re,html,os,datetime
idxf,outdir=sys.argv[1],sys.argv[2]
for line in open(idxf,encoding='utf-8'):
    tid,board,comm,date,title=line.rstrip('\n').split('\t')[:5]
import glob
S=sys.argv[3]
seen=set()
for f in glob.glob(S+'/web/research/**/*.json',recursive=True)+glob.glob(S+'/work/**/*.json',recursive=True)+glob.glob(S+'/mdb/raw/forum/*.json'):
    try: d=json.load(open(f,encoding='utf-8'))
    except Exception: continue
    if not(isinstance(d,dict) and 'threadId' in d and 'content' in d): continue
    tid=d['threadId']
    if tid in seen: continue
    seen.add(tid)
    c=d['content'] or ''
    c=re.sub(r'<br\s*/?>|</p>|</div>|</li>|</tr>|</h\d>','\n',c)
    c=re.sub(r'<t[dh][^>]*>',' | ',c)
    c=re.sub(r'<[^>]+>','',c); c=html.unescape(c)
    c=re.sub(r'[ \t\xa0]+',' ',c); c=re.sub(r'\n\s*\n+','\n',c)
    date=datetime.datetime.utcfromtimestamp(d.get('createDate',0)).strftime('%Y-%m-%d')
    open(f"{outdir}/{d.get('boardId')}_{tid}.txt",'w',encoding='utf-8').write(f"TITLE: {d.get('title')}\nDATE: {date}\nBOARD: {d.get('boardId')}\nCOMMUNITY: {d.get('communityId')}\n\n{c}")
print(len(seen))
