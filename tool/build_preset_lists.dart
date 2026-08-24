// ignore_for_file: avoid_print
//
// Generates assets/preset_lists.json (教材生字 / 生活主题 / 练字入门).
// Run: dart run tool/build_preset_lists.dart

import 'dart:convert';
import 'dart:io';

String dedupeHanzi(String raw) {
  final clean = raw.replaceAll(RegExp(r'[^\u4e00-\u9fff\s]'), '');
  final seen = <String>{};
  final buf = StringBuffer();
  for (final rune in clean.runes) {
    final ch = String.fromCharCode(rune);
    if (ch.trim().isEmpty) continue;
    if (seen.add(ch)) buf.write(ch);
  }
  return buf.toString();
}

List<String> chunkText(String text, {int size = 36}) {
  if (text.isEmpty) return const [];
  final chunks = <String>[];
  for (var i = 0; i < text.length; i += size) {
    final end = (i + size).clamp(0, text.length);
    if (i >= text.length) break;
    chunks.add(text.substring(i, end));
  }
  return chunks;
}

Map<String, String> section(String zh, String en, [String? zhHant]) => {
      'zh': zh,
      'en': en,
      'zh_Hant': zhHant ?? zh,
    };

Map<String, String> label(String zh, [String? en, String? zhHant]) => {
      'zh': zh,
      if (en != null) 'en': en,
      'zh_Hant': zhHant ?? zh,
    };

Map<String, dynamic> listEntry({
  required String id,
  required int sortOrder,
  required Map<String, String> section,
  required Map<String, String> title,
  required String text,
  String? descZh,
  List<String> tags = const [],
}) {
  return {
    'id': id,
    'sortOrder': sortOrder,
    'section': section,
    'title': title,
    if (descZh != null)
      'description': label(descZh, descZh, descZh),
    'text': text,
    if (tags.isNotEmpty) 'tags': tags,
  };
}

List<Map<String, dynamic>> buildGradeLists({
  required String idPrefix,
  required Map<String, String> sectionLabel,
  required String gradeTag,
  required String gradeTitlePrefix,
  required String hanzi,
  required int sortStart,
  int chunkSize = 32,
}) {
  final text = dedupeHanzi(hanzi);
  final chunks = chunkText(text, size: chunkSize);
  return [
    for (var i = 0; i < chunks.length; i++)
      listEntry(
        id: '${idPrefix}_${i + 1}',
        sortOrder: sortStart + i,
        section: sectionLabel,
        title: label('$gradeTitlePrefix · 第${i + 1}组', '$gradeTitlePrefix · Set ${i + 1}'),
        descZh: '${chunks[i].length} 字 · 统编版参考',
        text: chunks[i],
        tags: [gradeTag, 'textbook'],
      ),
  ];
}

void main() {
  var sort = 1;
  final textbookLists = <Map<String, dynamic>>[];

  void addGrade(String prefix, Map<String, String> sec, String tag, String title, String hanzi) {
    final lists = buildGradeLists(
      idPrefix: prefix,
      sectionLabel: sec,
      gradeTag: tag,
      gradeTitlePrefix: title,
      hanzi: hanzi,
      sortStart: sort,
    );
    sort += lists.length;
    textbookLists.addAll(lists);
  }

  // 统编版（2024）小学识字表参考，按课序去重分组；非官方教材。
  addGrade(
    'textbook_g1',
    section('一年级', 'Grade 1'),
    'grade1',
    '一年级',
    _grade1,
  );
  addGrade(
    'textbook_g2',
    section('二年级', 'Grade 2'),
    'grade2',
    '二年级',
    _grade2,
  );
  addGrade(
    'textbook_g3',
    section('三年级', 'Grade 3'),
    'grade3',
    '三年级',
    _grade3,
  );

  final lifeLists = <Map<String, dynamic>>[];
  sort = 1;
  for (final item in _lifeEntries) {
    lifeLists.add(listEntry(
      id: item.id,
      sortOrder: sort++,
      section: item.section,
      title: label(item.titleZh, item.titleEn, item.titleZh),
      descZh: item.desc,
      text: dedupeHanzi(item.text),
      tags: item.tags,
    ));
  }

  final practiceLists = <Map<String, dynamic>>[];
  sort = 1;
  for (final item in _practiceEntries) {
    practiceLists.add(listEntry(
      id: item.id,
      sortOrder: sort++,
      section: item.section,
      title: label(item.titleZh, item.titleEn, item.titleZh),
      descZh: item.desc,
      text: dedupeHanzi(item.text),
      tags: item.tags,
    ));
  }

  final output = {
    'schemaVersion': 1,
    'categories': [
      {
        'id': 'textbook',
        'sortOrder': 2,
        'icon': 'school',
        'title': label('教材生字', 'Textbook characters', '教材生字'),
        'lists': textbookLists,
      },
      {
        'id': 'life',
        'sortOrder': 3,
        'icon': 'eco',
        'title': label('生活主题', 'Daily life', '生活主題'),
        'lists': lifeLists,
      },
      {
        'id': 'practice',
        'sortOrder': 4,
        'icon': 'edit',
        'title': label('练字入门', 'Writing basics', '練字入門'),
        'lists': practiceLists,
      },
    ],
  };

  const outPath = 'assets/preset_lists.json';
  File(outPath).writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(output)}\n',
  );
  print('Wrote $outPath');
  print('  textbook: ${textbookLists.length} lists');
  print('  life: ${lifeLists.length} lists');
  print('  practice: ${practiceLists.length} lists');
}

class _Entry {
  _Entry({
    required this.id,
    required this.section,
    required this.titleZh,
    required this.titleEn,
    required this.text,
    this.desc,
    this.tags = const [],
  });

  final String id;
  final Map<String, String> section;
  final String titleZh;
  final String titleEn;
  final String text;
  final String? desc;
  final List<String> tags;
}

// --- 统编版 1–3 年级识字（2024 参考，去重） ---

const _grade1 = '''
天地人你我他一二三四五上下口耳目手足站坐日月水火山石田禾六七八十大马路土
本学校班级姓名王哥弟画花打棋积木字词句子桌纸读书鱼鸭乌鸦午星期语文数写会
秋气树叶片从来飞江女采莲北尖说春青蛙夏弯皮地就冬男女开关先远色近听无声还惊有去
对云雨风花鸟虫明力尘从众双木林森条心升国旗中红歌起么美丽立
船弯儿两头在里看见闪影前常黑狗左右它好朋友比尾巴谁长短把伞兔最公
喝处找办旁许法放进点彩半空问回回答方
霜吹落降飘游池入氏李张弓古胡吴言孙晴清请情旁动万无多行各钟处响伙伴着招呼
那海亮像淘牵走挂填披吃忘纪以织饭饮物住主广门书听点乐也习远粗近义相
知器善教迁贵专幼玉珠摇躺亮机展透腰阴沉闷消息响呢吧具铅新平盒些此仔检查
所钟啊决定已经位表物虎熊通注意百遍脸准第块非常往瓜进跳爬
病医别干奇期棉姑娘治燕咕咚熟掉湖吓啦鹿象野拦命领
''';

const _grade2 = '''
塘映带收饿孤舟影晴晚湖莲戏满帆房遇闲优淡浅底波景弯绕眼瞧影
植旅备纷刺底啪炸离识粗得曹称根柱底杆秤做岁站船然
玲详幅评奖催脏伤另及懒并封另支圆珠笔灯句电影
哄先闭脸发沉呼吸窗沙依尽黄层照烟直似
南部闻名景区部省致状尤巨著胜岛央绕迹丽展现
产份坡枝起客老收城市果些种纷布刘抗苦志
沿答渴喝话弄错际面阵朗枯却将难纷夜降
葫藤谢啊蚜盯赛怪慢数晚爷变昌铺调硬卧限乘售
孩于论岸屋切久散步唱赶旺旁浑候谁汽食随柴省
诗首望思床疑举低故胆敢外勇讲窗乱拉样笑
节扫除洗澡盆采尖圆粒棵飘鲜波披粗浮浪珠摇
痛快乐接供给串句免告造运过
''';

const _grade3 = '''
坝汉艳扮扬读摔跤凤洁轰荒笛功罚假裳背诵例圈糊涂呆戒厉挨楚
径斜赠残犹傲君橙橘挑洼印凌增棕靴钥匙缤枚勾油频曲丰梨
抖振韵掠吟辽烛焰胀互换径霜降紫晨绒球落
备等暴哦钻爬漂晒搭翠嘴捕望吞张合拢
亦抹宜庭未磨盘富优浅错岩武栖粪辈滨灰飘洁
封严挡坛显材软妙演琴柔感击器激滴敲鸣
册宝幻仰群翔序读重息黎明深腾爽
司庭登跌众弃持雀郊养粒男或斗刚烈离血仍取匆
陈缸还顿侦担融燕鸳鸯惠崇芦芽梅耕宋释冀
骄谦懦弱提尘讶捧鹿腿颈配喂狮追池河海
守株待兔宋耕释冀陶罐骄谦懦弱讶捧
''';

final _lifeEntries = [
  _Entry(
    id: 'life_season_spring',
    section: section('时令自然', 'Seasons & nature'),
    titleZh: '春天',
    titleEn: 'Spring',
    text: '春天花草风雨温暖萌芽',
    desc: '季节 · 8 字',
    tags: ['life', 'season', 'spring'],
  ),
  _Entry(
    id: 'life_season_summer',
    section: section('时令自然', 'Seasons & nature'),
    titleZh: '夏天',
    titleEn: 'Summer',
    text: '夏暑荷花荷叶炎热雷雨',
    tags: ['life', 'season', 'summer'],
  ),
  _Entry(
    id: 'life_season_autumn',
    section: section('时令自然', 'Seasons & nature'),
    titleZh: '秋天',
    titleEn: 'Autumn',
    text: '秋黄叶果实收获凉爽',
    tags: ['life', 'season', 'autumn'],
  ),
  _Entry(
    id: 'life_season_winter',
    section: section('时令自然', 'Seasons & nature'),
    titleZh: '冬天',
    titleEn: 'Winter',
    text: '冬雪寒冷冰雪温暖',
    tags: ['life', 'season', 'winter'],
  ),
  _Entry(
    id: 'life_nature_land',
    section: section('时令自然', 'Seasons & nature'),
    titleZh: '山水天地',
    titleEn: 'Land & sky',
    text: '山河湖海云霞日月星辰',
    tags: ['life', 'nature'],
  ),
  _Entry(
    id: 'life_nature_plants',
    section: section('时令自然', 'Seasons & nature'),
    titleZh: '花草树木',
    titleEn: 'Plants',
    text: '花草树木森林枝叶果实',
    tags: ['life', 'nature', 'plants'],
  ),
  _Entry(
    id: 'life_animals',
    section: section('时令自然', 'Seasons & nature'),
    titleZh: '常见动物',
    titleEn: 'Animals',
    text: '猫狗鸟鱼兔马牛羊鸡鸭',
    tags: ['life', 'animals'],
  ),
  _Entry(
    id: 'life_weather',
    section: section('时令自然', 'Seasons & nature'),
    titleZh: '天气',
    titleEn: 'Weather',
    text: '晴雨阴风雪雷电温暖',
    tags: ['life', 'weather'],
  ),
  _Entry(
    id: 'life_colors',
    section: section('时令自然', 'Seasons & nature'),
    titleZh: '颜色',
    titleEn: 'Colors',
    text: '红黄蓝绿白黑紫橙灰',
    tags: ['life', 'colors'],
  ),
  _Entry(
    id: 'life_family',
    section: section('日常交流', 'Daily life'),
    titleZh: '家庭成员',
    titleEn: 'Family',
    text: '爸妈爷爷奶奶哥姐弟妹',
    tags: ['life', 'family'],
  ),
  _Entry(
    id: 'life_school',
    section: section('日常交流', 'Daily life'),
    titleZh: '校园',
    titleEn: 'School',
    text: '学校老师同学读书写字',
    tags: ['life', 'school'],
  ),
  _Entry(
    id: 'life_food',
    section: section('日常交流', 'Daily life'),
    titleZh: '食物',
    titleEn: 'Food',
    text: '米饭面包鸡蛋牛奶水果蔬菜',
    tags: ['life', 'food'],
  ),
  _Entry(
    id: 'life_home',
    section: section('日常交流', 'Daily life'),
    titleZh: '家居',
    titleEn: 'Home',
    text: '门窗床桌灯书房间厨房',
    tags: ['life', 'home'],
  ),
  _Entry(
    id: 'life_body',
    section: section('日常交流', 'Daily life'),
    titleZh: '身体',
    titleEn: 'Body',
    text: '头脸眼鼻口牙手足心',
    tags: ['life', 'body'],
  ),
  _Entry(
    id: 'life_clothes',
    section: section('日常交流', 'Daily life'),
    titleZh: '衣着',
    titleEn: 'Clothing',
    text: '衣裤鞋帽袜穿戴',
    tags: ['life', 'clothes'],
  ),
  _Entry(
    id: 'life_transport',
    section: section('日常交流', 'Daily life'),
    titleZh: '交通',
    titleEn: 'Transport',
    text: '车路桥船飞机行走',
    tags: ['life', 'transport'],
  ),
  _Entry(
    id: 'life_greetings',
    section: section('日常交流', 'Daily life'),
    titleZh: '问候礼貌',
    titleEn: 'Greetings',
    text: '你好谢谢对不起再见请',
    tags: ['life', 'daily', 'greetings'],
  ),
  _Entry(
    id: 'life_polite',
    section: section('日常交流', 'Daily life'),
    titleZh: '礼貌用语',
    titleEn: 'Polite words',
    text: '请坐慢走欢迎打扰',
    tags: ['life', 'daily', 'polite'],
  ),
  _Entry(
    id: 'life_time',
    section: section('日常交流', 'Daily life'),
    titleZh: '时间',
    titleEn: 'Time',
    text: '早晚中午今天明天年月',
    tags: ['life', 'daily', 'time'],
  ),
  _Entry(
    id: 'life_weekdays',
    section: section('日常交流', 'Daily life'),
    titleZh: '星期',
    titleEn: 'Weekdays',
    text: '一二三四五六日',
    desc: '周一至周日',
    tags: ['life', 'daily', 'weekdays'],
  ),
  _Entry(
    id: 'life_festival_spring',
    section: section('节日祝福', 'Festivals'),
    titleZh: '春节',
    titleEn: 'Spring Festival',
    text: '春节福红包团圆饺子',
    tags: ['life', 'festival', 'spring_festival'],
  ),
  _Entry(
    id: 'life_festival_lantern',
    section: section('节日祝福', 'Festivals'),
    titleZh: '元宵',
    titleEn: 'Lantern Festival',
    text: '元宵灯笼汤圆',
    tags: ['life', 'festival', 'lantern'],
  ),
  _Entry(
    id: 'life_festival_qingming',
    section: section('节日祝福', 'Festivals'),
    titleZh: '清明',
    titleEn: 'Qingming',
    text: '清明踏青祭祖',
    tags: ['life', 'festival', 'qingming'],
  ),
  _Entry(
    id: 'life_festival_dragon',
    section: section('节日祝福', 'Festivals'),
    titleZh: '端午',
    titleEn: 'Dragon Boat',
    text: '端午粽子龙舟',
    tags: ['life', 'festival', 'dragon_boat'],
  ),
  _Entry(
    id: 'life_festival_midautumn',
    section: section('节日祝福', 'Festivals'),
    titleZh: '中秋',
    titleEn: 'Mid-Autumn',
    text: '中秋月亮月饼团圆',
    tags: ['life', 'festival', 'mid_autumn'],
  ),
  _Entry(
    id: 'life_festival_wishes',
    section: section('节日祝福', 'Festivals'),
    titleZh: '祝福用语',
    titleEn: 'Festive wishes',
    text: '新年快乐恭喜发财身体健康',
    tags: ['life', 'festival', 'wishes'],
  ),
];

final _practiceEntries = [
  _Entry(
    id: 'practice_strokes',
    section: section('基础笔画', 'Basic strokes'),
    titleZh: '基本笔画字',
    titleEn: 'Stroke examples',
    text: '永一二三十木口手',
    desc: '永字八法常用例字',
    tags: ['practice', 'strokes'],
  ),
  _Entry(
    id: 'practice_numbers',
    section: section('基础笔画', 'Basic strokes'),
    titleZh: '数字汉字',
    titleEn: 'Chinese numerals',
    text: '零一二三四五六七八九十百千万',
    tags: ['practice', 'numbers'],
  ),
  _Entry(
    id: 'practice_directions',
    section: section('基础笔画', 'Basic strokes'),
    titleZh: '方位',
    titleEn: 'Directions',
    text: '东南西北前后左右上下',
    tags: ['practice', 'directions'],
  ),
  _Entry(
    id: 'practice_size',
    section: section('基础笔画', 'Basic strokes'),
    titleZh: '大小多少',
    titleEn: 'Size & quantity',
    text: '大小多少长短高低',
    tags: ['practice', 'size'],
  ),
  _Entry(
    id: 'practice_radicals',
    section: section('基础笔画', 'Basic strokes'),
    titleZh: '常见偏旁',
    titleEn: 'Common radicals',
    text: '单人旁三点水木字旁口字旁',
    desc: '偏旁部首练习',
    tags: ['practice', 'radicals'],
  ),
  _Entry(
    id: 'practice_study',
    section: section('词语佳句', 'Phrases'),
    titleZh: '学习励志',
    titleEn: 'Study & motivation',
    text: '好好学习天天向上',
    tags: ['practice', 'phrase', 'study'],
  ),
  _Entry(
    id: 'practice_nature',
    section: section('词语佳句', 'Phrases'),
    titleZh: '自然风光',
    titleEn: 'Nature scenery',
    text: '山清水秀鸟语花香',
    tags: ['practice', 'phrase', 'nature'],
  ),
  _Entry(
    id: 'practice_happy',
    section: section('词语佳句', 'Phrases'),
    titleZh: '开心快乐',
    titleEn: 'Happiness',
    text: '开心快乐高兴',
    tags: ['practice', 'phrase', 'emotion'],
  ),
  _Entry(
    id: 'practice_diligence',
    section: section('词语佳句', 'Phrases'),
    titleZh: '勤奋努力',
    titleEn: 'Diligence',
    text: '认真努力坚持进步',
    tags: ['practice', 'phrase'],
  ),
  _Entry(
    id: 'practice_friendship',
    section: section('词语佳句', 'Phrases'),
    titleZh: '友爱互助',
    titleEn: 'Friendship',
    text: '团结友爱互相帮助',
    tags: ['practice', 'phrase'],
  ),
];
