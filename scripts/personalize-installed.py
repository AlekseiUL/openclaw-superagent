"""Personalize only newly copied paths; never scan or clean the user workspace."""
import os
from pathlib import Path
import socket
import sys


def main(argv):
    agent, owner, owner_id, telegram, timezone, emoji, *paths = argv
    replacements = dict(zip(
        ['AGENT_NAME', 'OWNER_NAME', 'OWNER_ID', 'OWNER_TELEGRAM', 'TIMEZONE', 'EMOJI'],
        [agent, owner, owner_id, '@' + telegram, timezone, emoji],
    ))
    replacements.update(GMT_OFFSET=timezone, HOSTNAME=socket.gethostname(),
                        HOST_MACHINE=socket.gethostname(), HOME_DIR=os.environ['HOME'])
    for key in ['TRUSTED_USER_ID', 'PROJECT_NAME', 'CHANNEL_NAME', 'OTHER_AGENT',
                'TRUSTED_USER_NAME', 'DOCTOR_BOT_NAME']:
        replacements[key] = '[не задан]'
    for item in paths:
        path = Path(item)
        files = path.rglob('*') if path.is_dir() else [path]
        for file in files:
            if file.is_symlink() or not file.is_file() or file.suffix not in {'.md', '.sh'}:
                continue
            text = file.read_text(encoding='utf-8')
            mapping = {'OWNER_ID': owner_id} if file.suffix == '.sh' else replacements
            for key, value in mapping.items():
                text = text.replace('[' + key + ']', value)
            file.write_text(text, encoding='utf-8')


if __name__ == '__main__':
    main(sys.argv[1:])
