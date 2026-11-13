"""Generate getuname's fi-FI.rc from en-US.rc.

tools/getuname-fi/gen.py <en-US.rc> <out fi-FI.rc> [--report [N]]

Run it again when upstream changes en-US.rc, and commit the result in
LiberNT; tests/real-upstream.sh requires the two to be the same.

Unicode character names are built from a small vocabulary: a script, the
kind of character, the letter's own name (a transliteration, kept), and
modifiers. English and Finnish both put an adjective before its noun, so
the words are translated in place by the glossary in gloss.py, with rules
for the parts where Finnish differs: "with X" becomes ", jossa X", a
diacritic's "Above"/"Below" follows it, and a few prepositions.
"""
import re, sys, collections
sys.path.insert(0, __import__('os').path.dirname(__file__))
from gloss import G, PHRASE, SCRIPT, KIND, NAMEMOD, OVERRIDE, NUM

HEADER = """/*
 * PROJECT:     Unicode name dll
 * FILE:        dll/win32/getuname/lang/fi-FI.rc
 * PURPOSE:     Finnish fi-FI resource file
 * TRANSLATOR:  Copyright 2026 Lauri Ojansivu <x@xet7.org>
 * REFERENCE:   en-US.rc, in the terms of Finnish typography (akuutti, gravis,
 *              treema, hattu, sedilji, makron) and of Finnish Windows
 */"""
ENTRY = re.compile(r'^(\s*)(0x[0-9A-Fa-f]+|\d+)(\s+)"([^"]*)"(.*)$')
STRUCT = {'with', 'and', 'or'}
FORMS = {'Isolated', 'Final', 'Initial', 'Medial'}
SYLLABARY = {
    ('Hangul', 'Syllable'): 'Hangul-tavu',
    ('Yi', 'Syllable'): 'Yi-tavu',
    ('Yi', 'Radical'): 'Yi-radikaali',
    ('Vai', 'Syllable'): 'Vai-tavu',
    ('Ethiopic', 'Syllable'): 'etiopialainen tavu',
}

left = collections.Counter()


def cap(s):
    return s[:1].upper() + s[1:] if s else s


NAMEKINDS = {'kirjain', 'tavu', 'ligatuuri', 'vokaali', 'vokaalimerkki', 'konsonantti',
             'konsonanttimerkki', 'iso kirjain', 'pieni kirjain', 'alaliitetty kirjain',
             'itsenäinen vokaali', 'muunninkirjain', 'yhdistävä kirjain', 'kirjain kapiteeli',
             'toonikirjain', 'mediaali', 'loppu', 'alkukonsonantti', 'keskivokaali',
             'loppukonsonantti', 'täytemerkki'}


def word(t, slot=False):
    """One English word: the glossary, a hyphenated compound, or as it is.
    slot='name': a letter's own name, only its modifiers are translated."""
    if slot == 'name':
        if t in NAMEMOD:
            return NAMEMOD[t]
        return NUM.get(t, t)
    if t in NUM:
        return NUM[t]
    if slot == 'meaning' and t in NAMEMOD and t not in G:
        return NAMEMOD[t]
    if t in G:
        return G[t]
    low = t.lower()
    if len(t) > 2 and t[0].isupper() and low in G:
        return G[low]
    if '-' in t and not t.startswith('-'):
        parts = t.split('-')
        if all(p in NUM for p in parts):
            return ''.join(NUM[p] for p in parts)
        if all(p in G or p.lower() in G or p in NUM for p in parts):
            return '-'.join(word(p) for p in parts)
    if re.fullmatch(r'[A-Za-z-]+', t) and len(t) > 2 and slot != 'meaning':
        left[t] += 1
    return t


def phrase(ws, slot=False):
    """Translate a list of words, longest PHRASE match first."""
    out, i = [], 0
    ws = [w for t in ws for w in (t.split() if '\n' in t else [t])]
    while i < len(ws):
        for n in range(min(6, len(ws) - i), 0, -1):
            key = ' '.join(ws[i:i + n])
            if slot != 'name' and key in PHRASE:
                out.append(PHRASE[key]); i += n; break
        else:
            out.append(word(ws[i], slot)); i += 1
    return join(out)


TENS = {NUM[k] for k in ('Twenty', 'Thirty', 'Forty', 'Fifty', 'Sixty', 'Seventy', 'Eighty', 'Ninety')}
UNITS = {NUM[k] for k in ('One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight', 'Nine')}
HEADS = {'merkki', 'merkit', 'symboli', 'operaattori', 'kuvio', 'välilyönti', 'merkkiä', 'näppäin', 'laatikko'}
ADJ = {'pitkä', 'lyhyt', 'iso', 'pieni', 'kova', 'pehmeä', 'musta', 'valkoinen', 'uusi', 'vanha',
       'korkea', 'matala', 'leveä', 'kapea', 'vasen', 'oikea', 'täysi', 'tyhjä', 'raskas', 'kevyt',
       'paksu', 'ohut', 'vino', 'terävä', 'avoin', 'suljettu', 'ylempi', 'alempi', 'pyöreä', 'yhdistävä',
       'ja', 'tai', 'ei', 'eikä', 'kaikki', 'muu', 'sama', 'eri', 'yksi', 'kaksi', 'kolme', 'neljä', 'viisi',
       'kuusi', 'seitsemän', 'kahdeksan', 'yhdeksän', 'kymmenen', 'toinen', 'kolmas', 'neljäs', 'erillinen',
       'harmaa', 'punainen', 'sininen', 'vihreä', 'keltainen', 'tumma', 'vaalea', 'kuin'}
ADJ_END = ('inen', 'va', 'vä', 'ttu', 'tty', 'tu', 'ty', 'ton', 'tön', 'ava', 'ävä', 'llinen', 'mpi')


def join(parts):
    """Join words; a word ending in '-' is the first half of a compound, and
    a noun before merkki/symboli/... forms one with it (toonimerkki)."""
    ps = [x for x in parts if x]
    out = []
    for x in ps:
        if out and x.split(' ')[0] in HEADS and ' ' not in out[-1] and not out[-1].endswith('-'):
            prev = out[-1]
            if prev.islower() and prev.isalpha() and prev not in ADJ and not prev.endswith(ADJ_END):
                out[-1] = prev + x
                continue
            if prev.isalnum() and not prev.islower() and prev not in ADJ:
                out[-1] = prev + '-' + x
                continue
        out.append(x)
    r = ''
    for x in out:
        if r.endswith('-'):
            a, b = r[-2:-1], x[:1]
            keep = not b.islower() or (a == b and a in 'aeiouyäö')
            r = (r if keep else r[:-1]) + x
        elif r and r.split(' ')[-1] in TENS and x in UNITS:
            r += x
        else:
            r += x if not r else ' ' + x
    return r[:-1] if r.endswith('-') else r


POST = {'Above': 'yläpuolella', 'Below': 'alapuolella'}
PREP = {  # "A <prep> B": Finnish says it without a case form
    'Over': ('{a}, alla {b}'), 'Under': ('{a}, yllä {b}'),
    'Above': ('{a}, alla {b}'), 'Below': ('{a}, yllä {b}'),
    'To': ('{a} kohti: {b}'), 'from': ('{a}, lähtöisin: {b}'),
    'of': ('{a}: {b}'), 'Of': ('{a}: {b}'), 'for': ('{a}: {b}'), 'For': ('{a}: {b}'),
    'In': ('{a}, sisällä {b}'), 'On': ('{a}, alla {b}'),
    'Through': ('{a}, läpi {b}'), 'Beside': ('{a}, vieressä {b}'),
    'By': ('{a}, ja {b}'), 'At': ('{a}: {b}'), 'Around': ('{a}, ympärillä {b}'),
    'Without': ('{a} ilman: {b}'), 'Between': ('{a}, välissä {b}'),
}


def clause(ws):
    """A run of words with no 'with' in it: phrases, postpositions, prepositions."""
    if not ws:
        return ''
    key = ' '.join(ws)
    if key in PHRASE:
        return PHRASE[key]
    if len(ws) > 2 and ws[-1] == 'Form' and ws[-2] in FORMS:
        return clause(ws[:-2]) + ', ' + PHRASE[' '.join(ws[-2:])]
    # a trailing Above/Below follows its noun: "Dot Above" -> "piste yläpuolella"
    if len(ws) > 1 and ws[-1] in POST and ' '.join(ws) not in PHRASE:
        return (clause(ws[:-1]) + ' ' + POST[ws[-1]]).strip()
    if ws[-1] == 'To' and len(ws) > 1:
        return clause(ws[:-1])
    for i in range(1, len(ws)):
        if ws[i] in PREP and ' '.join(ws[i:]) in PHRASE:
            return clause(ws[:i]) + ' ' + PHRASE[' '.join(ws[i:])]
    for i in range(1, len(ws) - 1):
        t = ws[i]
        if t in PREP and ' '.join(ws[max(0, i - 3):i + 3]) not in PHRASE:
            # keep a PHRASE that spans the preposition ("Equal To", "Start of")
            if any(' '.join(ws[a:b]) in PHRASE for a in range(0, i + 1) for b in range(i + 1, len(ws) + 1)):
                continue
            return PREP[t].format(a=clause(ws[:i]), b=clause(ws[i + 1:]))
    return phrase(ws)


def tail(ws):
    """'with X and Y', ', Isolated Form' ... after the head."""
    out = ''
    if ws and ws[0] in ('Isolated', 'Final', 'Initial', 'Medial') and 'Form' in ws:
        j = ws.index('Form') + 1
        out += ', ' + phrase(ws[:j])
        ws = ws[j:]
    if ws and ws[0] == 'with':
        rest = ws[1:]
        parts, cur = [], []
        for t in rest:
            if t in ('and', 'with'):
                parts.append(cur); cur = []
            else:
                cur.append(t)
        parts.append(cur)
        out += ', jossa ' + ' ja '.join(clause(p) for p in parts if p)
        return out
    if ws and ws[0] in ('and', 'or'):
        out += ' ' + G[ws[0]] + ' ' + clause(ws[1:])
        return out
    if ws and ws[0] in PREP and len(ws) > 1:
        return out + PREP[ws[0]].format(a='', b=clause(ws[1:])).rstrip()
    if ws:
        out += ' ' + clause(ws)
    return out


def script_at(ws, i):
    for n in range(min(4, len(ws) - i), 0, -1):
        k = ' '.join(ws[i:i + n])
        if k in SCRIPT:
            return k, n
    return None, 0


ADV = {'Rightwards': 'oikealle', 'Right': 'oikealle', 'Leftwards': 'vasemmalle', 'Left': 'vasemmalle',
       'Upwards': 'ylös', 'Up': 'ylös', 'Downwards': 'alas', 'Down': 'alas', 'North East': 'koilliseen'}
RULES = [
    (r'Recycling Symbol for Type-(\d) Plastics', lambda m: f'kierrätyssymboli: muovityyppi {m[1]}'),
    (r'Arrow Pointing (\w+) Then Curving (\w+)',
     lambda m: f'{ADV[m[1]]} osoittava ja sitten {ADV[m[2]].replace("ylös", "ylöspäin").replace("alas", "alaspäin")} kaartuva nuoli'),
    (r'(Short )?Bent Arrow Pointing (\w+) Then (North East)',
     lambda m: ('lyhyt ' if m[1] else '') + f'taivutettu nuoli, joka osoittaa {ADV[m[2]]} ja sitten {ADV[m[3]]}'),
    (r'Measured Angle with Open Arm Ending In Arrow Pointing (\w+) and (\w+)',
     lambda m: f'mitattu kulma, jonka avoin varsi päättyy {ADV[m[1]]} ja {ADV[m[2]]} osoittavaan nuoleen'),
    (r'Wave Arrow Pointing Directly (\w+)', lambda m: f'suoraan {ADV[m[1]]} osoittava aaltonuoli'),
]


def fi(name):
    if name in OVERRIDE:
        return OVERRIDE[name]
    for rx, f in RULES:
        m = re.fullmatch(rx, name)
        if m:
            return cap(f(m))
    name = re.sub(r'(Selector)-(\d+)', r'\1 \2', name)
    ws = [{'Of': 'of', 'With': 'with', 'And': 'and', 'Or': 'or', 'For': 'for', 'From': 'from'}.get(t, t)
          for t in name.split()]
    name = ' '.join(ws)
    if name in OVERRIDE:
        return OVERRIDE[name]
    key = name
    if key in PHRASE:
        return cap(PHRASE[key])
    if not ws:
        return name
    for (a, b), fin in SYLLABARY.items():
        if ws[:2] == [a, b]:
            return cap(fin + ' ' + ' '.join(ws[2:]))
    if ws[:2] == ['Canadian', 'Syllabics']:
        return cap(join(['kanadalainen tavumerkki', phrase(ws[2:], slot='name')]))
    if ws[:2] == ['Braille', 'Pattern']:
        r = ws[2:]
        if r == ['Blank']:
            return 'Pistekirjoituskuvio, tyhjä'
        return 'Pistekirjoituskuvio, pisteet ' + ' '.join(r).replace('Dots-', '')
    m = re.fullmatch(r'CJK Compatibility Ideograph-([0-9A-F]+)', name)
    if m:
        return 'CJK-yhteensopivuusideogrammi-' + m.group(1)
    # head: [modifiers] [script] [Capital|Small] <kind> <name slot> [tail]
    pre, i = [], 0
    scr = None
    while i < len(ws):
        k, n = script_at(ws, i)
        if k:
            scr = k; i += n
            break
        if ws[i] in KIND:
            break
        if ws[i] in ('Capital', 'Small') and not any(script_at(ws, k)[0] for k in range(i + 1, len(ws))):
            break
        pre.append(ws[i]); i += 1
    if scr is None:
        return cap(clause_with(ws))
    size = ''
    while i < len(ws) and ws[i] in ('Capital', 'Small'):
        size = {'Capital': 'iso', 'Small': 'pieni'}[ws[i]]; i += 1
    kind, mid = None, []
    for skip in range(0, 3):
        for n in (3, 2, 1):
            k = ' '.join(ws[i + skip:i + skip + n])
            if k in KIND and not (skip and ws[i] in ('with', 'and', 'or')):
                kind = KIND[k]; mid = ws[i:i + skip]; i += skip + n
                break
        if kind:
            break
    while i < len(ws) and ws[i] in ('Capital', 'Small') and not size:
        size = {'Capital': 'iso', 'Small': 'pieni'}[ws[i]]; i += 1
    adj, prefix = SCRIPT[scr]
    if kind is None:
        # "<Script> <whatever>": the script, then the rest as a phrase
        body = clause_with(ws[i:])
        name = adj if adj else prefix.rstrip(' -') if prefix.endswith((' ', '-')) else prefix
        if scr == 'Box Drawings':
            return cap(name + ', ' + body)
        return cap(join([phrase(pre), size, name, body]))
    j = i
    mode = 'name' if kind in NAMEKINDS and scr != 'Modifier' else 'meaning'
    while j < len(ws) and ws[j] not in STRUCT and not (ws[j] in FORMS and 'Form' in ws[j:]) \
            and not (ws[j] == 'for' or (mode == 'meaning' and ws[j] in PREP and ws[j] not in POST)):
        j += 1
    slot = phrase(ws[i:j], slot=mode)
    if adj:
        head = join([phrase(pre), adj, phrase(mid), size, kind])
    elif mid and prefix.endswith('-'):
        head = join([phrase(pre), size, prefix.rstrip(' -') + ' ' + phrase(mid) + ' -' + kind])
    else:
        head = join([phrase(pre), phrase(mid), size, prefix + kind])
    return cap(head + (' ' + slot if slot else '') + tail(ws[j:]))


def clause_with(ws):
    if 'with' in ws:
        j = ws.index('with')
        return clause(ws[:j]) + tail(ws[j:])
    if ws and ws[0] in ('and', 'or'):
        return tail(ws)
    return clause(ws)


def main():
    src, dst = sys.argv[1], sys.argv[2]
    out = []
    for line in open(src, encoding='utf-8').read().split('\n'):
        m = ENTRY.match(line)
        if not m:
            out.append(line)
            continue
        ind, code, sp, name, rest = m.groups()
        f = fi(name) if name else name
        assert '"' not in f, (name, f)
        out.append(f'{ind}{code}{sp}"{f}"{rest}')
    text = '\n'.join(out)
    text = text.replace('LANGUAGE LANG_ENGLISH, SUBLANG_ENGLISH_US', 'LANGUAGE LANG_FINNISH, SUBLANG_DEFAULT')
    text = HEADER + text[text.index('*/') + 2:]
    open(dst, 'w', encoding='utf-8').write(text)
    if '--report' in sys.argv:
        print(len(left), 'English-looking words left;', sum(left.values()), 'uses')
        print(left.most_common(int(sys.argv[sys.argv.index('--report') + 1]) if len(sys.argv) > sys.argv.index('--report') + 1 else 150))


if __name__ == '__main__':
    main()
