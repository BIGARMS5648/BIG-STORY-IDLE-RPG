import re,sys,html
for f in sys.argv[1:]:
    t=open(f,encoding='utf-8',errors='replace').read()
    m=re.search(r'<main.*?</main>',t,re.S)
    if m: t=m.group(0)
    t=re.sub(r'<script.*?</script>|<style.*?</style>|<nav.*?</nav>|<footer.*?</footer>','',t,flags=re.S)
    t=re.sub(r'</(p|div|h\d|li|tr|section|table)>','\n',t)
    t=re.sub(r'<(td|th)[^>]*>',' | ',t)
    t=re.sub(r'<[^>]+>',' ',t); t=html.unescape(t)
    t=re.sub(r'[ \t]+',' ',t); t=re.sub(r'\n\s*\n+','\n',t)
    print('#####',f); print(t.strip())
