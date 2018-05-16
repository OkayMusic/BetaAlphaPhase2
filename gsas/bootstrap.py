#!/usr/bin/env python
import os, stat, sys, platform, subprocess
home = 'https://subversion.xray.aps.anl.gov/EXPGUI/'
proxycmds = []
if os.path.exists("proxyinfo.txt"):
    os.remove("proxyinfo.txt")
print(70*"=")
print(70*"=")
ans = raw_input("Enter the proxy address [none needed]: ")
if ans.strip() != "":
    proxycmds.append('--config-option')
    proxycmds.append('servers:global:http-proxy-host='+ans.strip())
    fp = open("proxyinfo.txt",'w')
    fp.write(ans.strip()+'\n')
    ans = raw_input("Enter the proxy port [8080]: ")
    if ans.strip() == "": ans="8080"
    proxycmds.append('--config-option')
    proxycmds.append('servers:global:http-proxy-port='+ans.strip())
    fp.write(ans.strip()+'\n')
    fp.close()
gsaspath = os.path.split(sys.argv[0])[0]
gsaspath = os.path.abspath(os.path.expanduser(gsaspath))
print 'GSAS is being bootstrapped from repository to '+gsaspath
print 'Determining system type...',
if sys.platform.startswith('linux'):
    if platform.processor().find('86') <= -1:
        ans = raw_input("Note, GSAS requires an Intel-compatible processor and 32-bit"
                        "libraries.\nAre you sure want to continue? [Yes]/no: ")
        if ans.lower().find('no') > -1: sys.exit()
    repos = 'linux'
    print 'Linux, Intel-compatible'
elif sys.platform == "darwin" and platform.processor() == 'i386':
    repos = 'osxi86'
    print 'Mac OS X, Intel-compatible'
elif sys.platform == "darwin":
    repos = 'osxppc'
    print 'Mac OS X, PowerPC'
else:
    raise Exception('Undefined system type')
print 'OK'

print 'Checking for subversion...',
try: 
    p = subprocess.Popen(['svn','help','switch'],stdout=subprocess.PIPE)
except:
    if sys.platform.startswith('linux'):
        print('Use "yum install svn" or "dpkg",... to install svn/subversion')
    elif sys.platform == "darwin":
        print('See https://subversion.xray.aps.anl.gov/trac/EXPGUI/wiki/InstallOSX for info on installing svn/subversion')
    raise Exception('Subversion (svn) not found')
res = p.stdout.read()
if res.find('--ignore-ancestry') == -1:
    print ' svn <=1.6 OK'
    svnopt = ''
else:
    svnopt = '--ignore-ancestry'
    print ' svn >=1.7 OK'

if os.path.exists(os.path.join(gsaspath,'.svn')):
    p = subprocess.Popen(['svn','info',gsaspath],stdout=subprocess.PIPE)
    res = p.stdout.read()
else:
    res = ''

cmds = [
    (['svn', 'co', home+ 'gsas/all', gsaspath],'loading GSAS common'),
    (['svn', 'switch', home+ 'trunk/', gsaspath+'/expgui'],'loading EXPGUI'),
    (['svn', 'switch', home+ 'gsas/' + repos+ '/exe/', gsaspath+'/exe'],'loading GSAS programs'),
    (['svn', 'switch', home+ 'gsas/' + repos+ '/pgl/', gsaspath+'/pgl'],'loading PGPLOT files'),
]

if res.find('.xor.aps.') != -1:
    cmds.insert(0,
               (['svn', 'switch', '--relocate',
                 'https://subversion.xor.aps.anl.gov/EXPGUI', home, gsaspath],
                'Switching EXPGUI repository to xray.aps')
               )

for cmd,msg in cmds: 
    print 70*'*'
    print msg
    if proxycmds: cmd += proxycmds
    if svnopt and cmd[1] == 'switch': cmd += [svnopt]
    for item in cmd: print item,
    print ""
    p = subprocess.call(cmd)

if sys.platform.startswith('darwin'):
    appmaker = os.path.join(gsaspath,'expgui','makeMacApp.py')
    if os.path.exists(appmaker):
        execfile(appmaker)
    else:
        print("file "+str(appmaker)+" not found")

elif sys.platform.startswith('linux'):
    os.chmod(gsaspath + "/expgui/expgui", 
             stat.S_IXUSR | stat.S_IRUSR | stat.S_IRGRP | stat.S_IXGRP | stat.S_IXOTH) 
    if not os.path.exists(os.path.join(gsaspath,'EXPGUI.png')):
        import shutil
        shutil.copy(os.path.join(gsaspath,'expgui','EXPGUI.png'),
                    os.path.join(gsaspath,'EXPGUI.png'))
        shutil.copy(os.path.join(gsaspath,'expgui','GSAS.png'),
                    os.path.join(gsaspath,'GSAS.png'))
    if os.path.exists(os.path.expanduser('~/Desktop/')):
        open(os.path.expanduser('~/Desktop/EXPGUI.desktop'),'w').write('''
[Desktop Entry]
Encoding=UTF-8
Version=1.0
Type=Application
Terminal=false
Exec=%s/expgui/expgui
Name=EXPGUI
Icon=%s/EXPGUI.png
''' % (gsaspath,gsaspath))
        os.chmod(os.path.expanduser('~/Desktop/EXPGUI.desktop'),
                 stat.S_IWUSR | stat.S_IXUSR | stat.S_IRUSR | stat.S_IRGRP | stat.S_IXGRP | stat.S_IXOTH) 
        open(os.path.expanduser('~/Desktop/GSAS.desktop'),'w').write('''
[Desktop Entry]
Encoding=UTF-8
Version=1.0
Type=Application
Terminal=true
Exec=%s/GSAS
Name=GSAS
Icon=%s/GSAS.png
''' % (gsaspath,gsaspath))
        os.chmod(os.path.expanduser('~/Desktop/GSAS.desktop'),
                 stat.S_IWUSR | stat.S_IXUSR | stat.S_IRUSR | stat.S_IRGRP | stat.S_IXGRP | stat.S_IXOTH)
    else:
        print 'No Desktop directory found, are you running this as root?'
        #print 'Run '+str(os.path.join(gsaspath,'mkGnomeIcon.py'))+' from your user account(s)'
