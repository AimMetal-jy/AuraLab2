/// 翻译练习数据模型
class TranslationPractice {
  final String id;
  final String title;
  final String description;
  final String category;
  final String difficulty;
  final String sourceLanguage;
  final String targetLanguage;
  final List<TranslationExercise> exercises;
  final String iconPath;
  final String thumbnailColor;

  TranslationPractice({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.difficulty,
    required this.sourceLanguage,
    required this.targetLanguage,
    required this.exercises,
    required this.iconPath,
    required this.thumbnailColor,
  });
}

/// 翻译练习题目
class TranslationExercise {
  final String id;
  final String sourceText;
  final String targetText;
  final String? context;
  final List<String>? hints;
  final String? explanation;

  TranslationExercise({
    required this.id,
    required this.sourceText,
    required this.targetText,
    this.context,
    this.hints,
    this.explanation,
  });
}

/// 翻译练习服务
class TranslationPracticeService {
  /// 获取所有练习
  static List<TranslationPractice> getAllPractices() {
    return [
      // 日常对话练习
      TranslationPractice(
        id: 'daily_conversation',
        title: '日常对话',
        description: '学习日常生活中的常用对话表达',
        category: '对话',
        difficulty: '初级',
        sourceLanguage: 'en',
        targetLanguage: 'zh',
        iconPath: '💬',
        thumbnailColor: 'blue',
        exercises: [
          TranslationExercise(
            id: 'greeting_1',
            sourceText: 'Good morning! How are you today?',
            targetText: '早上好！你今天怎么样？',
            context: '早晨问候',
            hints: ['Good morning = 早上好', 'How are you = 你怎么样'],
            explanation: '这是一个常见的早晨问候语，用于询问对方的近况。',
          ),
          TranslationExercise(
            id: 'greeting_2',
            sourceText: 'Nice to meet you. What\'s your name?',
            targetText: '很高兴见到你。你叫什么名字？',
            context: '初次见面',
            hints: ['Nice to meet you = 很高兴见到你', 'What\'s your name = 你叫什么名字'],
            explanation: '这是初次见面时的标准问候和自我介绍。',
          ),
          TranslationExercise(
            id: 'greeting_3',
            sourceText: 'Have a great day! See you later.',
            targetText: '祝你今天愉快！回头见。',
            context: '告别',
            hints: ['Have a great day = 祝你今天愉快', 'See you later = 回头见'],
            explanation: '这是告别时的祝福语，表达友好的道别。',
          ),
        ],
      ),

      // 商务英语练习
      TranslationPractice(
        id: 'business_english',
        title: '商务英语',
        description: '学习商务场合的专业表达',
        category: '商务',
        difficulty: '中级',
        sourceLanguage: 'en',
        targetLanguage: 'zh',
        iconPath: '💼',
        thumbnailColor: 'green',
        exercises: [
          TranslationExercise(
            id: 'business_1',
            sourceText:
                'I would like to schedule a meeting to discuss the project.',
            targetText: '我想安排一个会议来讨论这个项目。',
            context: '会议安排',
            hints: ['schedule = 安排', 'meeting = 会议', 'discuss = 讨论'],
            explanation: '商务环境中安排会议的正式表达方式。',
          ),
          TranslationExercise(
            id: 'business_2',
            sourceText: 'Could you please send me the report by Friday?',
            targetText: '您能在周五之前把报告发给我吗？',
            context: '工作请求',
            hints: [
              'Could you please = 您能...吗',
              'report = 报告',
              'by Friday = 在周五之前',
            ],
            explanation: '礼貌地请求同事或下属完成工作任务。',
          ),
          TranslationExercise(
            id: 'business_3',
            sourceText: 'The quarterly sales exceeded our expectations.',
            targetText: '季度销售额超过了我们的预期。',
            context: '业绩汇报',
            hints: [
              'quarterly = 季度的',
              'sales = 销售额',
              'exceeded = 超过',
              'expectations = 预期',
            ],
            explanation: '汇报业绩时使用的正式表达。',
          ),
        ],
      ),

      // 旅游英语练习
      TranslationPractice(
        id: 'travel_english',
        title: '旅游英语',
        description: '掌握旅行中的实用英语表达',
        category: '旅游',
        difficulty: '初级',
        sourceLanguage: 'en',
        targetLanguage: 'zh',
        iconPath: '✈️',
        thumbnailColor: 'orange',
        exercises: [
          TranslationExercise(
            id: 'travel_1',
            sourceText: 'Excuse me, where is the nearest subway station?',
            targetText: '打扰一下，最近的地铁站在哪里？',
            context: '问路',
            hints: [
              'Excuse me = 打扰一下',
              'nearest = 最近的',
              'subway station = 地铁站',
            ],
            explanation: '旅行时询问交通工具位置的常用表达。',
          ),
          TranslationExercise(
            id: 'travel_2',
            sourceText: 'I\'d like to check in. I have a reservation.',
            targetText: '我想办理入住。我有预订。',
            context: '酒店入住',
            hints: ['check in = 办理入住', 'reservation = 预订'],
            explanation: '在酒店办理入住手续时的标准表达。',
          ),
          TranslationExercise(
            id: 'travel_3',
            sourceText: 'How much does this souvenir cost?',
            targetText: '这个纪念品多少钱？',
            context: '购物',
            hints: ['How much = 多少钱', 'souvenir = 纪念品', 'cost = 花费'],
            explanation: '购买纪念品时询问价格的表达。',
          ),
        ],
      ),

      // 学术英语练习
      TranslationPractice(
        id: 'academic_english',
        title: '学术英语',
        description: '学习学术写作和研究中的表达',
        category: '学术',
        difficulty: '高级',
        sourceLanguage: 'en',
        targetLanguage: 'zh',
        iconPath: '📚',
        thumbnailColor: 'purple',
        exercises: [
          TranslationExercise(
            id: 'academic_1',
            sourceText:
                'The results of this study suggest that further research is needed.',
            targetText: '这项研究的结果表明需要进一步的研究。',
            context: '学术论文',
            hints: [
              'results = 结果',
              'study = 研究',
              'suggest = 表明',
              'further research = 进一步研究',
            ],
            explanation: '学术论文中总结研究发现的标准表达。',
          ),
          TranslationExercise(
            id: 'academic_2',
            sourceText:
                'According to the data analysis, there is a significant correlation.',
            targetText: '根据数据分析，存在显著的相关性。',
            context: '数据分析',
            hints: [
              'according to = 根据',
              'data analysis = 数据分析',
              'significant = 显著的',
              'correlation = 相关性',
            ],
            explanation: '描述研究数据分析结果的学术表达。',
          ),
          TranslationExercise(
            id: 'academic_3',
            sourceText:
                'This hypothesis requires empirical evidence to support it.',
            targetText: '这个假设需要实证证据来支持。',
            context: '研究方法',
            hints: [
              'hypothesis = 假设',
              'empirical evidence = 实证证据',
              'support = 支持',
            ],
            explanation: '学术研究中讨论假设验证的表达。',
          ),
        ],
      ),

      // 科技英语练习
      TranslationPractice(
        id: 'tech_english',
        title: '科技英语',
        description: '掌握科技和互联网相关词汇',
        category: '科技',
        difficulty: '中级',
        sourceLanguage: 'en',
        targetLanguage: 'zh',
        iconPath: '💻',
        thumbnailColor: 'red',
        exercises: [
          TranslationExercise(
            id: 'tech_1',
            sourceText: 'Please update the software to the latest version.',
            targetText: '请将软件更新到最新版本。',
            context: '软件操作',
            hints: ['update = 更新', 'software = 软件', 'latest version = 最新版本'],
            explanation: '计算机软件使用中的常见指令。',
          ),
          TranslationExercise(
            id: 'tech_2',
            sourceText:
                'The artificial intelligence algorithm can process large datasets.',
            targetText: '人工智能算法可以处理大型数据集。',
            context: 'AI技术',
            hints: [
              'artificial intelligence = 人工智能',
              'algorithm = 算法',
              'process = 处理',
              'datasets = 数据集',
            ],
            explanation: '描述人工智能技术能力的专业表达。',
          ),
          TranslationExercise(
            id: 'tech_3',
            sourceText:
                'Cloud computing enables remote access to applications.',
            targetText: '云计算使应用程序的远程访问成为可能。',
            context: '云技术',
            hints: [
              'cloud computing = 云计算',
              'enables = 使...成为可能',
              'remote access = 远程访问',
              'applications = 应用程序',
            ],
            explanation: '解释云计算技术特点和优势的表达。',
          ),
        ],
      ),
    ];
  }

  /// 根据ID获取练习
  static TranslationPractice? getPracticeById(String id) {
    try {
      return getAllPractices().firstWhere((practice) => practice.id == id);
    } catch (e) {
      return null;
    }
  }

  /// 根据难度筛选练习
  static List<TranslationPractice> getPracticesByDifficulty(String difficulty) {
    return getAllPractices()
        .where((practice) => practice.difficulty == difficulty)
        .toList();
  }

  /// 根据分类筛选练习
  static List<TranslationPractice> getPracticesByCategory(String category) {
    return getAllPractices()
        .where((practice) => practice.category == category)
        .toList();
  }
}
