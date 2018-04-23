# -*- mode: python -*-

block_cipher = None


a = Analysis(['minxss_pass_automation_exe_gen.py'],
             pathex=['C:\\Users\\Colden\\IDLWorkspace85\\minxss\\src\\pass_planning_tool\\python'],
             binaries=None,
             datas=None,
             hiddenimports=[],
             hookspath=[],
             runtime_hooks=[],
             excludes=[],
             win_no_prefer_redirects=False,
             win_private_assemblies=False,
             cipher=block_cipher)
pyz = PYZ(a.pure, a.zipped_data,
             cipher=block_cipher)
exe = EXE(pyz,
          a.scripts,
          a.binaries,
          a.zipfiles,
          a.datas,
          name='minxss_pass_automation_1.1',
          debug=False,
          strip=False,
          upx=True,
          console=True )
