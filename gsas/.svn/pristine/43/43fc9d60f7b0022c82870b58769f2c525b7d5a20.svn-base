if os.path.exists(os.path.expanduser('~/Desktop/')):
    os.chmod(gsaspath + "/expgui/expgui", 
             stat.S_IXUSR | stat.S_IRUSR | stat.S_IRGRP | stat.S_IXGRP | stat.S_IXOTH) 
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
