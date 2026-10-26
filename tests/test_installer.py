import json, os, pathlib, subprocess, tempfile, unittest
ROOT=pathlib.Path(__file__).resolve().parents[1]
class Install(unittest.TestCase):
    def test_additive_preserves_customizations_and_tmp(self):
        with tempfile.TemporaryDirectory() as td:
            home=pathlib.Path(td); ws=home/'workspace'; ws.mkdir(); config=home/'.openclaw'; config.mkdir()
            (config/'openclaw.json').write_text(json.dumps({'agents':{'defaults':{'workspace':str(ws)}}}))
            env={**os.environ,'HOME':td}
            def run(repeat):
                data=('1\n' if repeat else '')+'Atlas\nUser\n\n\nUTC\n\ny\nn\nn\n'
                p=subprocess.run(['bash',str(ROOT/'install.sh')],env=env,input=data,text=True,capture_output=True,timeout=30)
                self.assertEqual(p.returncode,0,p.stdout+p.stderr)
            run(False)
            script=next((ws/'scripts').glob('*.sh')); script.write_text('# local customization\n')
            (ws/'user.tmp').write_text('user data')
            (ws/'SOUL.md').write_text('User [AGENT_NAME] content')
            run(True)
            self.assertEqual(script.read_text(),'# local customization\n')
            self.assertEqual((ws/'user.tmp').read_text(),'user data')
            self.assertEqual((ws/'SOUL.md').read_text(),'User [AGENT_NAME] content')
if __name__=='__main__': unittest.main()
