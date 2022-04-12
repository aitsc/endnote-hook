from tqdm import tqdm
import pyperclip
import itertools
from tsc_base import fr_letter, fr_en_letter, replace
import re
import jieba
import stanza

len_top_k = 3  # 最多统计多少个词的排列组合, 越大速度越慢
group_top_k = 20  # 每种排列组合最多展示前多少个group统计结果
use_lemma = True  # 是否使用词性还原, 不使用词性还原速度会很快

stop_words = set()
with open('stopwords', 'r', encoding='utf-8') as r:
    for line in r:
        line = line.strip()
        if line:
            stop_words.add(line)


def jieba_cut(text):
    if not text:
        return ''
    zh_rule = re.compile(u'[\u4e00-\u9fa5]')
    if zh_rule.search(text) is None:
        return text
    seg_ = list(jieba.cut(text))
    seg = [seg_[0]]
    for i in range(1, len(seg_)):
        f_zh = bool(zh_rule.search(seg_[i - 1]))
        b_zh = bool(zh_rule.search(seg_[i]))
        if f_zh and b_zh or f_zh and seg_[i][0].strip() or b_zh and seg_[i - 1][-1].strip():
            seg.append(' ')
        seg.append(seg_[i])
    return ''.join(seg)


class NLP:
    def __init__(self) -> None:
        try:
            self._nlp = stanza.Pipeline(lang='en', processors='tokenize,mwt,pos,lemma')
        except:
            print('下载词性还原的模型...')
            stanza.download('en')
            self._nlp = stanza.Pipeline(lang='en', processors='tokenize,mwt,pos,lemma')

    def __call__(self, doc: str):
        words = []
        lemmas = []
        for i in self._nlp(doc).to_dict()[0]:
            words.append(i['text'])
            lemmas.append(i['lemma'])
        return words, lemmas


def stat_group(papers, key, n=3, group_sort=False, id='_id'):
    group_url_D = {}
    keys_L = []
    for paper in papers:
        keys, _id = paper[key], paper[id]
        if not isinstance(keys, list):
            keys = [keys]
        if group_sort:
            keys = list(tuple(keys))
        keys_L.append(keys)
        for k in keys:
            group_url_D.setdefault((k,), set()).add(_id)
    for i in range(2, n + 1):
        group_url_D_ = {}
        for keys in keys_L:
            for group in itertools.combinations(keys, i):
                x = group_url_D_.setdefault(group, set())
                x |= group_url_D[group[:-1]] & group_url_D[(group[-1],)]
        group_url_D.update(group_url_D_)
    return group_url_D


def jieba_lemma(title: str, lemma_origin=None, nlp=None):
    if lemma_origin is None:
        lemma_origin = {}

    title = re.sub('&[a-z]+?;|&#[0-9]+?;', ' ', title.lower())
    title = re.sub(f'[^a-z一-龥{fr_letter}]+', ' ', title).strip()
    if title == '':
        return [], [], lemma_origin
    title = jieba_cut(title)

    def fr_to_origin_f(fr_word):
        origin = replace(f"[{fr_letter}]", lambda x: fr_en_letter[x], fr_word)
        origin_fr.setdefault(origin, set()).add(fr_word)
        return origin
    origin_fr = {}
    title = replace(f'([a-z]*[{fr_letter}]+[a-z]*)', lambda fr_word: fr_to_origin_f(fr_word), title).strip()
    words, lemmas = [], []
    if nlp is None:
        bar = re.split(r'[\s]+', title)
        bar = bar, bar
    else:
        bar = nlp(title)
    for w, l in zip(*bar):
        if w in stop_words or l in stop_words:
            continue
        words.append(w)
        lemmas.append(l)
        origin_S = lemma_origin.setdefault(l, set())
        origin_S.add(w)
        if w in origin_fr:
            origin_S |= origin_fr[w]
        origin_S -= {l}
    return lemmas, words, lemma_origin


def stat_word_frequency(titles, len_top_k=2, group_top_k=20, use_lemma=True):
    nlp = NLP() if use_lemma else None
    lemma_origin = {}
    papers = []
    for title in tqdm(titles, '中文分词' + ('与英文词性还原' if use_lemma else '')):
        lemmas = jieba_lemma(title, lemma_origin, nlp)[0]
        if len(lemmas) == 0:
            continue
        papers.append({'key': sorted(set(lemmas)), '_id': title})
    len_group_num_D = {}
    group_url_D = stat_group(papers, key='key', n=len_top_k)
    for group, url_S in group_url_D.items():
        len_group_num_D.setdefault(len(group), {}).setdefault(group, len(url_S))
    len_group_info_L = []
    for l, group_num_D in sorted(len_group_num_D.items(), key=lambda t: t[0]):
        len_group_info_L.append([l, []])
        for group, num in sorted(group_num_D.items(), key=lambda t: (-t[1], t[0])):
            origin_S = set()
            for i in group:
                if i in lemma_origin:
                    origin_S |= lemma_origin[i]
            origin_S -= set(group)
            len_group_info_L[-1][1].append([group, num, sorted(origin_S)])
    group_show = []
    indent = '    '
    for len_, group_info_L in len_group_info_L:
        group_show.append([])
        for i, group_info in enumerate(group_info_L[:group_top_k]):
            group_show[-1].append(f'{i+1}: ' + str(group_info)[1:-1])
        group_show[-1] = f'{len_}个词排列组合, 总组合数: {len(group_info_L)}\n{indent}'\
            + f'\n{indent}'.join(group_show[-1])
    group_show = f'{indent}序号: (出现词), 论文数, [词性还原或注音符号还原前的词]\n' + '\n'.join(group_show)
    group_show = f'计算最多组词数: {len_top_k}, 返回最多组数量: {group_top_k}, 论文数量(去重): {len(set(titles))}, 词性还原: {use_lemma}\n'\
        + group_show
    return group_show, len_group_info_L


print('\n' + stat_word_frequency(re.split('[\r\n]+', pyperclip.paste()), len_top_k, group_top_k, use_lemma)[0])
