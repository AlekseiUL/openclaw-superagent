# Offline verification boundary

Additive install preserves local scripts and user .tmp files. Personalization is limited to copied paths and backups have unique names.

## Reproduce

`python3 -m unittest discover -s tests -v`

Tests decline watchdog/voice installation. Existing destination trees must be trusted. Force/merge overwrite modes require a full operator snapshot, including scripts and skills; the built-in backup is not a complete uninstall snapshot.

## Rollback

Review the commit diff and use a new checkout of the pre-change commit for source rollback. Keep user data and live installations untouched. A source rollback is not permission to restore unsafe network exposure or bypass approval.
