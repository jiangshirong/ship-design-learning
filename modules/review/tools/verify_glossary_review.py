"""Offline regression checks; coverage is not a linguistic correctness proof."""
import json
import re
from audit_lookup import ROOT, OUT, read, write, scan, norm
from apply_glossary_review import apply

path=ROOT/'content/glossary.json'
data=read(path)
before=read(OUT/'glossary-before-review.json')
assert len({e['id'] for e in data})==len(data)
assert {e['id'] for e in before}<={e['id'] for e in data}
original_bytes=path.read_bytes()
apply()
assert original_bytes==path.read_bytes(), 'Editorial overlay must be idempotent'

# Reproduce the builder's habit of adding obsolete inflection aliases.
try:
    simulated=read(path)
    simulated[0]['aliases'].append('меняться')
    write(path,simulated)
    apply()
    assert not any('меняться' in e['aliases'] and norm(e['ru'])!='меняться' for e in read(path))
finally:
    path.write_bytes(original_bytes)

coverage=scan()
symbols={'х','рк','т','к','рсэу','сэу','рсэз','сэз','кг','ч','гр','н','м'}
assert set(coverage['missing'])<=symbols, coverage['missing']
# The remaining к only occurs inside mixed Latin/Cyrillic pк, not as a word.
for text in coverage['missing'].get('к',[]):
    assert 'pк' in norm(text)
write(OUT/'coverage-after-review.json',coverage)
old={e['id']:e for e in before}
runtime=read(ROOT.parent.parent/'qa/lookup-review.json')
assert all(item['passed'] for item in runtime)
stats={
    'scope':'reading.json + topics.json; both runtime dictionaries',
    'cards':len(read(ROOT/'content/reading.json')),
    'topics':len(read(ROOT/'content/topics.json')),
    'excluded_notation_forms_in_original_audit':12,
    'sentence_occurrences':len(coverage['sentences']),
    'unique_texts':len({row['text'] for row in coverage['sentences']}),
    'uncovered_ordinary_words':0,
    'entries_before':len(before),'entries_after':len(data),
    'added_entries':len(data)-len(before),
    'updated_existing_entries':sum(e['id'] in old and e!=old[e['id']] for e in data),
    'original_ids_preserved':True,
    'runtime_assertions':len(runtime),'runtime_failures':0,
    'overlay_idempotent':True,'obsolete_alias_reintroduction_blocked':True,
    'api_calls_this_review':0,
}
write(OUT/'review-verification.json',stats)
print(json.dumps(stats,ensure_ascii=False,indent=2))
