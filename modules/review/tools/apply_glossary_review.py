"""Reapply editor-approved definitions after regenerating course vocabulary."""
import json
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]

def apply():
    target = ROOT/'content/glossary.json'
    overlay = ROOT/'content/glossary_review.json'
    if not overlay.exists():
        return
    entries = json.loads(target.read_text(encoding='utf-8'))
    review = json.loads(overlay.read_text(encoding='utf-8'))
    indexed = {e['id']:e for e in entries}
    for update in review['entries']:
        if update['id'] in indexed:
            old = indexed[update['id']]
            aliases = list(dict.fromkeys(old['aliases'] + update['aliases']))
            old.update(update)
            old['aliases'] = aliases
        else:
            entries.append(update)
            indexed[update['id']] = update
    for alias, lemma, _ in review['alias_transfers']:
        for e in entries:
            if e['ru'] != lemma and alias in e['aliases']:
                e['aliases'].remove(alias)
    target.write_text(json.dumps(entries,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')

if __name__ == '__main__':
    apply()
