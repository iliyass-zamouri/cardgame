// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'ShadowHand';

  @override
  String authError(String error) {
    return 'خطأ في المصادقة: $error';
  }

  @override
  String get signInToPlay => 'سجّل الدخول للعب عبر الإنترنت';

  @override
  String get continueWithGoogle => 'المتابعة مع Google';

  @override
  String get continueWithApple => 'المتابعة مع Apple';

  @override
  String get signingIn => 'جارٍ تسجيل الدخول…';

  @override
  String get playAsGuest => 'اللعب كضيف';

  @override
  String get entering => 'جارٍ الدخول…';

  @override
  String get guestSignInServerDown => 'فشل دخول الضيف. هل الخادم يعمل؟';

  @override
  String get guestSignInConnection => 'فشل دخول الضيف. تحقق من الاتصال.';

  @override
  String get googleSignInFailed => 'فشل تسجيل الدخول عبر Google. حاول مجددًا.';

  @override
  String get appleSignInFailed => 'فشل تسجيل الدخول عبر Apple. حاول مجددًا.';

  @override
  String get tagline => 'لاعبان. طاولة واحدة.';

  @override
  String get findMatch => 'البحث عن مباراة';

  @override
  String get createRoom => 'إنشاء غرفة';

  @override
  String get joinRoom => 'الانضمام لغرفة';

  @override
  String get playVsRobot => 'تمرين ضد الروبوت';

  @override
  String get robotName => 'روبوت';

  @override
  String get retryConnection => 'إعادة الاتصال';

  @override
  String get howToPlay => 'طريقة اللعب';

  @override
  String get home => 'الرئيسية';

  @override
  String get shop => 'المتجر';

  @override
  String get collection => 'المجموعة';

  @override
  String get collectionCards => 'البطاقات';

  @override
  String get collectionAvatars => 'الصور الرمزية';

  @override
  String ownedCount(int owned, int total) {
    return '$owned/$total مملوكة';
  }

  @override
  String get getMoreInShop => 'احصل على المزيد من المتجر';

  @override
  String get deck => 'الورق';

  @override
  String get settings => 'الإعدادات';

  @override
  String get language => 'اللغة';

  @override
  String get changeLanguage => 'تغيير اللغة';

  @override
  String get signOut => 'تسجيل الخروج';

  @override
  String get guest => 'ضيف';

  @override
  String get google => 'Google';

  @override
  String get apple => 'Apple';

  @override
  String get player => 'لاعب';

  @override
  String get online => 'متصل';

  @override
  String get connecting => 'جارٍ الاتصال';

  @override
  String get offline => 'غير متصل';

  @override
  String get joinRoomTitle => 'الانضمام لغرفة';

  @override
  String get joinRoomHint => 'أدخل الرمز المكوّن من 6 أحرف من صديقك.';

  @override
  String get codeHint => 'الرمز';

  @override
  String get cancel => 'إلغاء';

  @override
  String get join => 'انضمام';

  @override
  String get findingOpponent => 'البحث عن خصم';

  @override
  String get matchmakingHint => 'انتظر قليلًا — جارٍ مطابقتك مع لاعب.';

  @override
  String get privateTable => 'طاولة خاصة';

  @override
  String get shareCodeWithFriend => 'شارك هذا الرمز مع صديق';

  @override
  String waitingForOpponentNamed(String name) {
    return 'بانتظار $name…';
  }

  @override
  String opponentIsReady(String name) {
    return '$name جاهز';
  }

  @override
  String get bothPlayersJoined => 'انضم اللاعبان';

  @override
  String get codeCopied => 'تم نسخ الرمز';

  @override
  String get tapToCopy => 'اضغط للنسخ';

  @override
  String get ready => 'جاهز';

  @override
  String get waitingEllipsis => 'بانتظار…';

  @override
  String get leaveRoom => 'مغادرة الغرفة';

  @override
  String get vs => 'ضد';

  @override
  String get you => 'أنت';

  @override
  String get notReady => 'غير جاهز';

  @override
  String get waitingEllipsisShort => 'بانتظار…';

  @override
  String get endGame => 'إنهاء اللعبة';

  @override
  String get menu => 'القائمة';

  @override
  String get endGameTitle => 'إنهاء اللعبة؟';

  @override
  String get endGameMessage => 'تُكشف الأوراق وتُحسب النقاط.';

  @override
  String get reveal => 'كشف';

  @override
  String get peek => 'اطّلاع';

  @override
  String get shuffle => 'خلط';

  @override
  String get replace => 'استبدال';

  @override
  String get waitingOpponentReveal => 'بانتظار اطّلاع الخصم على أوراقه…';

  @override
  String get gameOver => 'انتهت اللعبة';

  @override
  String get victory => 'فوز';

  @override
  String get defeat => 'هزيمة';

  @override
  String get draw => 'تعادل';

  @override
  String seriesScore(int yours, int theirs) {
    return 'السلسلة  $yours – $theirs';
  }

  @override
  String get opponent => 'الخصم';

  @override
  String get waitingRematch => 'بانتظار إعادة المباراة من الخصم…';

  @override
  String opponentAskingRematch(String name) {
    return '$name يطلب إعادة المباراة';
  }

  @override
  String get leave => 'مغادرة';

  @override
  String get rematch => 'إعادة';

  @override
  String get points => 'نقاط';

  @override
  String get roomInfo => 'معلومات الغرفة';

  @override
  String roomCodePlaying(String roomId, String turn) {
    return '$roomId · $turn';
  }

  @override
  String codeRoomId(String roomId) {
    return 'الرمز $roomId';
  }

  @override
  String roomToastPlaying(String roomId, String turn) {
    return 'الغرفة $roomId · $turn';
  }

  @override
  String roomToast(String roomId) {
    return 'الغرفة $roomId';
  }

  @override
  String get yourTurn => 'دورك';

  @override
  String get opponentTurn => 'دور الخصم';

  @override
  String get leaveRoomTitle => 'مغادرة الغرفة؟';

  @override
  String get leaveRoomMessage => 'ستغادر هذه اللعبة.';

  @override
  String stepOf(int current, int total) {
    return 'الخطوة $current من $total';
  }

  @override
  String get back => 'رجوع';

  @override
  String get next => 'التالي';

  @override
  String get gotIt => 'حسنًا';

  @override
  String get ruleGoalTitle => 'الهدف';

  @override
  String get ruleGoalBody =>
      'أنهِ بأقل مجموع. تنتهي اللعبة عندما تنفد أوراق لاعب أو يضغط أحدهم على إنهاء اللعبة.';

  @override
  String get ruleSetupTitle => 'الإعداد';

  @override
  String get ruleSetupBody =>
      'لاعبان. يحصل كل منهما على أربع أوراق مقلوبة في صف.';

  @override
  String get ruleOpeningPeekTitle => 'اطّلاع البداية';

  @override
  String get ruleOpeningPeekBody =>
      'قبل اللعب، اضغط على كشف لرؤية ورقتيك على اليسار لبضع ثوانٍ. تذكّرهما — ثم تُقلبان مجددًا.';

  @override
  String get ruleYourTurnTitle => 'دورك';

  @override
  String get ruleYourTurnBody =>
      'قبل السحب، إذا طابقت الورقة العليا في كومة الرمي ورقة تعرفها، اضغط عليها لرميها (يستمر دورك). الخطأ = ورقة عقوبة. ثم اسحب من الرزمة.';

  @override
  String get ruleAfterDrawTitle => 'بعد السحب';

  @override
  String get ruleAfterDrawBody =>
      'اضغط على إحدى أوراقك للتبديل (رتبة مختلفة) أو للرمي المزدوج (نفس الرتبة)، أو اضغط على الورقة المسحوبة لرميها. ثم ينتهي دورك.';

  @override
  String get ruleSpecialTitle => 'أوراق خاصة';

  @override
  String get ruleSpecialBody =>
      'عند سحب هذه الأوراق يمكنك استخدام قدرتها. بعدها تُرمى الورقة.';

  @override
  String get ruleJackLabel => 'جندي';

  @override
  String get ruleJackDesc => 'اطّلع على ورقة — لك أو للخصم — ثم يُرمى الجندي.';

  @override
  String get ruleQueenLabel => 'ملكة';

  @override
  String get ruleQueenDesc =>
      'اخلط يدًا، أو بدّل ورقة منك بورقة منهم، ثم تُرمى الملكة.';

  @override
  String get ruleScoringTitle => 'النقاط';

  @override
  String get ruleScoringBody =>
      'عندما تنفد أوراق لاعب أو يضغط أحدهم على إنهاء اللعبة، تُكشف كل الأوراق وتُجمع. الآس = 1، الولد = 11، الملكة = 12. الأقل يفوز؛ التساوي = تعادل.';

  @override
  String get ruleJokerLabel => 'جوكر';

  @override
  String get ruleJokerDesc => 'يحسب −1 نقطة.';

  @override
  String get ruleBlackKingLabel => 'ملك أسود';

  @override
  String get ruleBlackKingDesc =>
      'ملك البستوني أو السباتي = 0. الملوك الحمر تحسب 13.';

  @override
  String get hintPeek => 'المس أي ورقة للاطّلاع…';

  @override
  String get hintShufflePick => 'المس «خلط» فوق إحدى اليدين…';

  @override
  String get hintReplaceFirst => 'المس ورقة من كل يد…';

  @override
  String get hintReplaceSecond => 'المس ورقة من اليد الأخرى…';

  @override
  String get errConnectionLost => 'فُقد الاتصال';

  @override
  String get errEnterRoomCode => 'أدخل رمز الغرفة';

  @override
  String get errServerNotConnected => 'الخادم غير متصل';

  @override
  String get errCommandFailed => 'فشل الأمر';

  @override
  String get errRoomFull => 'الغرفة ممتلئة بلاعبين';

  @override
  String get errWaitingForPlayer => 'يلزم لاعبان';

  @override
  String get errAlreadyStarted => 'اللعبة بدأت بالفعل';

  @override
  String get errNotEnded => 'اللعبة لم تنتهِ بعد';

  @override
  String get errAlreadyLaunched => 'الأوراق كُشفت بالفعل';

  @override
  String get errAlreadyDrew => 'ارْمِ أو بدّل الورقة المسحوبة أولًا';

  @override
  String get errDeckEmpty => 'لا أوراق متاحة';

  @override
  String get errNoJack => 'الاطّلاع يتطلب جنديًا مسحوبًا';

  @override
  String get errPeekUsed => 'اطّلاع الجندي مستخدم بالفعل';

  @override
  String get errInvalidSide => 'جانب غير صالح';

  @override
  String get errInvalidCard => 'فهرس الورقة غير صالح';

  @override
  String get errCannotShuffle => 'لا تكفي الأوراق للخلط';

  @override
  String get errDrawFirst => 'اسحب ورقة أولًا';

  @override
  String get errNoHandCard => 'اسحب ورقة أولًا';

  @override
  String get errNotInRoom => 'انضم لغرفة أولًا';

  @override
  String get errNotYourTurn => 'ليس دورك';

  @override
  String get errRevealFirst => 'يجب أن يكشف كلا اللاعبين أولًا';

  @override
  String get errNotPlaying => 'اللعبة غير جارية';

  @override
  String get errPeekInProgress => 'انتظر انتهاء الاطّلاع';

  @override
  String get errQueenInProgress => 'انتظر انتهاء قدرة الملكة';

  @override
  String get errNoQueen => 'قدرة الملكة تتطلب ملكة مسحوبة';

  @override
  String get errQueenUsed => 'قدرة الملكة مستخدمة بالفعل';

  @override
  String get errInvalidCommand => 'نوع الأمر مطلوب';

  @override
  String get errRoomNotFound => 'الغرفة غير موجودة';

  @override
  String get errUnknownCommand => 'أمر غير معروف';

  @override
  String get errTooManyCommands => 'أوامر كثيرة جدًا';

  @override
  String get globalRanking => 'الترتيب العالمي';

  @override
  String get marketplace => 'المتجر';

  @override
  String get comingSoon => 'قريبًا';

  @override
  String get marketplaceComingSoonBody => 'ستظهر هنا تصاميم الورق والإضافات.';

  @override
  String get leaderboard => 'لوحة الصدارة';

  @override
  String get matchHistory => 'سجل المباريات';

  @override
  String get elo => 'إيلو';

  @override
  String get colWins => 'ف';

  @override
  String get colLosses => 'خ';

  @override
  String get colDraws => 'ت';

  @override
  String get rankingEmpty => 'لا لاعبين مصنّفين بعد. العب مباراة عشوائية!';

  @override
  String get matchHistoryEmpty => 'لا مباريات مصنّفة بعد.';

  @override
  String get rankingLoadError => 'تعذّر تحميل الترتيب. هل الخادم يعمل؟';

  @override
  String get matchResultWin => 'فوز';

  @override
  String get matchResultLoss => 'خسارة';

  @override
  String get matchResultDraw => 'تعادل';

  @override
  String recordWinsLossesDraws(int wins, int losses, int draws) {
    return '$winsف · $lossesخ · $drawsت';
  }

  @override
  String matchScoreLine(int myScore, int oppScore) {
    return 'أنت $myScore · الخصم $oppScore';
  }

  @override
  String get friends => 'الأصدقاء';

  @override
  String get friendsComingSoonBody =>
      'تواصل مع الأصدقاء وادعهم للمباريات قريبًا.';

  @override
  String get requests => 'الطلبات';

  @override
  String get addFriend => 'إضافة صديق';

  @override
  String get searchByUsername => 'ابحث باسم المستخدم أو الاسم...';

  @override
  String get noFriendsYet => 'لا يوجد أصدقاء بعد.';

  @override
  String get noFriendsHint =>
      'ابحث عن أسماء المستخدمين في تبويب إضافة صديق للتواصل!';

  @override
  String get noRequests => 'لا توجد طلبات صداقة معلقة.';

  @override
  String get incomingRequests => 'الطلبات الواردة';

  @override
  String get outgoingRequests => 'الطلبات المرسلة';

  @override
  String get accept => 'قبول';

  @override
  String get decline => 'رفض';

  @override
  String get removeFriend => 'إزالة صديق';

  @override
  String removeFriendConfirm(String name) {
    return 'هل أنت متأكد من رغبتك في إزالة $name من الأصدقاء؟';
  }

  @override
  String get friendRequestSent => 'تم إرسال طلب الصداقة!';

  @override
  String get friendRequestAccepted => 'تم قبول طلب الصداقة!';

  @override
  String friendRequestFrom(String name) {
    return '$name أرسل لك طلب صداقة';
  }

  @override
  String friendRequestAcceptedBy(String name) {
    return '$name قبل طلب الصداقة';
  }

  @override
  String get friendRemoved => 'تمت إزالة الصديق.';

  @override
  String get requestSent => 'تم الإرسال';

  @override
  String get youTag => 'أنت';

  @override
  String get alreadyFriends => 'أصدقاء';

  @override
  String get changeUsername => 'تغيير اسم المستخدم';

  @override
  String get usernameHint => 'اسم_مستخدم_فريد';

  @override
  String get usernameAvailable => 'اسم المستخدم متاح';

  @override
  String get usernameTaken => 'اسم المستخدم مأخوذ بالفعل';

  @override
  String get usernameInvalidFormat => '3-20 حرف: حروف صغيرة، أرقام، _';

  @override
  String get save => 'حفظ';

  @override
  String get displayName => 'الاسم الظاهر';

  @override
  String get editProfile => 'تعديل الملف الشخصي';

  @override
  String get profileUpdated => 'تم تحديث الملف الشخصي بنجاح!';

  @override
  String get searching => 'جارٍ البحث...';

  @override
  String get noPlayersFound => 'لم يتم العثور على لاعبين مطابقين للبحث.';

  @override
  String get profile => 'الملف الشخصي';

  @override
  String level(int lvl) {
    return 'المستوى $lvl';
  }

  @override
  String levelNumber(int lvl) {
    return 'المستوى $lvl';
  }

  @override
  String get xp => 'خبرة';

  @override
  String get winRate => 'نسبة الفوز';

  @override
  String get matchesPlayed => 'المباريات';

  @override
  String get totalXp => 'إجمالي الخبرة';

  @override
  String get copiedToClipboard => 'تم النسخ إلى الحافظة';

  @override
  String get rankTitleNovice => 'المبتدئ';

  @override
  String get rankTitleCardShark => 'قرش الورق';

  @override
  String get rankTitleHighRoller => 'المقامر المحترف';

  @override
  String get rankTitleTableMaster => 'سيد الطاولة';

  @override
  String get rankTitleGrandAce => 'الآس العظيم';

  @override
  String get rankTitleShadowLegend => 'أسطورة الظل';

  @override
  String get inviteFriends => 'دعوة الأصدقاء';

  @override
  String get invite => 'دعوة';

  @override
  String get invited => 'تمت الدعوة';

  @override
  String get inviteSent => 'تم إرسال الدعوة!';

  @override
  String tableInviteFrom(String name, String code) {
    return 'دعاك $name للانضمام إلى طاولة خاصة $code';
  }

  @override
  String get joinTable => 'انضم للطاولة';

  @override
  String get ignore => 'تجاهل';

  @override
  String get noFriendsToInvite => 'لم يتم إضافة أصدقاء بعد لدعوتهم.';

  @override
  String get customizeAvatar => 'تخصيص الصورة الرمزية';

  @override
  String get locked => 'مغلق';

  @override
  String get equipped => 'مفعل';

  @override
  String get equip => 'استخدام';

  @override
  String unlockAtLevel(int lvl) {
    return 'يُفتح عند المستوى $lvl';
  }

  @override
  String get defaultAvatar => 'الافتراضي';

  @override
  String get blueAvatar => 'الياقوت الأزرق';

  @override
  String get redAvatar => 'الياقوت الأحمر';

  @override
  String get bronzeAvatar => 'برونزي';

  @override
  String get silverAvatar => 'فضي';

  @override
  String get jokerGirlAvatar => 'فتاة الجوكر';

  @override
  String get violetJokerGirlAvatar => 'الجوكر البنفسجي';

  @override
  String get violetQueenAvatar => 'الملكة البنفسجية';

  @override
  String get queenOfHeartAvatar => 'ملكة القلوب';

  @override
  String get goldenKingAvatar => 'الملك الذهبي';

  @override
  String get queenAvatar => 'الملكة';

  @override
  String get kingAvatar => 'الملك';

  @override
  String get money => 'نقود';

  @override
  String get chips => 'رقائق';

  @override
  String get exchange => 'تبديل';

  @override
  String get avatarShop => 'الصور الرمزية';

  @override
  String get deckShop => 'أوراق اللعب';

  @override
  String get selectMatchStake => 'اختر الرهان';

  @override
  String get stake => 'الرهان';

  @override
  String get pot => 'المجموع';

  @override
  String get winnerTakesAll => 'الفائز يأخذ المجموع';

  @override
  String get getMoreMoney => 'الحصول على نقود';

  @override
  String get insufficientChips => 'الرقائق غير كافية';

  @override
  String get insufficientMoney => 'النقود غير كافية';

  @override
  String get exchangedSuccess => 'تم التبديل بنجاح';

  @override
  String get exchangeFailed => 'فشل التبديل';

  @override
  String get watchAdForMoney => 'مشاهدة إعلان';

  @override
  String get freeStashBonus => 'مكافأة نقود مجانية';

  @override
  String get adRewardEarned => 'تم الحصول على المكافأة!';

  @override
  String get adNotAvailable => 'الإعلان غير متوفر حالياً';

  @override
  String get chipsToMoney => 'تحويل الرقائق إلى نقود';

  @override
  String get moneyToChips => 'تحويل النقود إلى رقائق';

  @override
  String get convert => 'تحويل';

  @override
  String get claim => 'استلام';

  @override
  String get buy => 'شراء';

  @override
  String get owned => 'مملوك';

  @override
  String get unlocked => 'متاح';

  @override
  String get purchaseFailed => 'فشلت عملية الشراء';

  @override
  String get classicDeck => 'الأزرق الكلاسيكي';

  @override
  String get classicDeckDesc => 'أوراق كازينو قياسية';

  @override
  String get onyxBlackDeck => 'أونيكس أسود';

  @override
  String get onyxBlackDeckDesc => 'ظهر أسود أونيكس بزخارف ذهبية';

  @override
  String get sapphireFrostDeck => 'تنين الياقوت';

  @override
  String get sapphireFrostDeckDesc =>
      'زخارف سلتية بالياقوت والذهب حول تنينين متشابكين';

  @override
  String get imperialJadeDeck => 'الفيكتوري الرفيع';

  @override
  String get imperialJadeDeckDesc => 'زخرفة زمردية في إطار ذهبي فيكتوري';

  @override
  String get royalCrimsonDeck => 'القرمزي الملكي';

  @override
  String get royalCrimsonDeckDesc => 'زخرفة ذهبية ووجه متوج على قرمزي';

  @override
  String get neonNightsDeck => 'ليالي النيون';

  @override
  String get neonNightsDeckDesc => 'غروب سينثويف فوق شبكة نيون متوهجة';

  @override
  String get gildedDeck => 'ذهب عيار 24';

  @override
  String get gildedDeckDesc => 'ذهب خالص منقوش مع ماسة مقطوعة ببراعة';

  @override
  String get rarityRare => 'نادر';

  @override
  String get rarityEpic => 'ملحمي';

  @override
  String get rarityLegendary => 'أسطوري';

  @override
  String get price => 'السعر';

  @override
  String get play => 'لعب';

  @override
  String get cityLondon => 'لندن';

  @override
  String get cityParis => 'باريس';

  @override
  String get cityMoscow => 'موسكو';

  @override
  String get cityCairo => 'القاهرة';

  @override
  String get cityMarrakech => 'مراكش';

  @override
  String get cityToronto => 'تورونتو';

  @override
  String get cityNewYork => 'نيويورك';

  @override
  String get cityTokyo => 'طوكيو';

  @override
  String get prize => 'الجائزة';

  @override
  String get entryFee => 'رسوم الدخول';

  @override
  String get linkGoogleAccount => 'ربط حساب Google';

  @override
  String get linkingGoogle => 'جارٍ الربط…';

  @override
  String get linkAppleAccount => 'ربط حساب Apple';

  @override
  String get linkGoogleSuccess => 'تم ربط حساب Google. تم حفظ تقدمك.';

  @override
  String get linkGoogleSwitched => 'تم تسجيل الدخول بحساب Google.';

  @override
  String get linkAppleSuccess => 'تم ربط حساب Apple. تم حفظ تقدمك.';

  @override
  String get linkAppleSwitched => 'تم تسجيل الدخول بحساب Apple.';

  @override
  String get saveProgressTitle => 'احفظ تقدمك';

  @override
  String get saveProgressBody =>
      'اربط حساب Google للاحتفاظ بأموالك ورقائقك وترتيبك عند تغيير الجهاز.';

  @override
  String get saveProgressBodyIos =>
      'اربط حساب Apple أو Google للاحتفاظ بأموالك ورقائقك وترتيبك عند تغيير الجهاز.';

  @override
  String get googleAccountInUseTitle => 'حساب Google مستخدم';

  @override
  String get appleAccountInUseTitle => 'حساب Apple مستخدم';

  @override
  String googleAccountInUseBody(String username) {
    return 'حساب Google هذا ينتمي بالفعل إلى @$username. التبديل إلى ذلك الحساب؟ ستفقد تقدم الضيف على هذا الجهاز.';
  }

  @override
  String appleAccountInUseBody(String username) {
    return 'حساب Apple هذا ينتمي بالفعل إلى @$username. التبديل إلى ذلك الحساب؟ ستفقد تقدم الضيف على هذا الجهاز.';
  }

  @override
  String get switchToGoogleAccount => 'تبديل الحساب';

  @override
  String get dontAskAgain => 'لا تسأل مرة أخرى';

  @override
  String get later => 'لاحقاً';

  @override
  String get youQuit => 'لقد انسحبت';

  @override
  String get opponentQuit => 'انسحب الخصم';

  @override
  String get turnTimedOut => 'انتهى الوقت وتم لعب دورك تلقائيًا.';

  @override
  String turnTimedOutWarning(int remaining) {
    return 'انتهى الوقت وتم لعب دورك تلقائيًا. الأدوار المتبقية قبل الانسحاب: $remaining.';
  }

  @override
  String get youTimedOut => 'انتهى وقتك';

  @override
  String get opponentTimedOut => 'انتهى وقت الخصم';

  @override
  String get matchResultQuit => 'انسحاب';

  @override
  String get leaveMatchPenaltyMessage =>
      'المغادرة الآن تُحتسب خسارة: ستخسر رهانك و15 نقطة.';

  @override
  String get notEnoughMoneyTitle => 'المال غير كافٍ';

  @override
  String notEnoughMoneyMessage(int required, int money) {
    return 'الرهان $required ولديك $money. استبدل الرقائق أو اشترِ المزيد لإعادة المباراة.';
  }

  @override
  String get stakeCovered => 'رصيدك كافٍ — جاهز لإعادة المباراة.';

  @override
  String get exchangeChips => 'استبدال الرقائق';

  @override
  String get buyMoney => 'شراء المال';

  @override
  String get rematchStarting => 'جارٍ خصم الرهانات…';

  @override
  String opponentCantAffordRematch(String name) {
    return '$name لا يستطيع تغطية الرهان';
  }

  @override
  String get offlineReconnecting => 'غير متصل · جارٍ إعادة الاتصال…';

  @override
  String get getMoreChips => 'الحصول على رقائق';

  @override
  String get notEnoughChipsTitle => 'الرقائق غير كافية';

  @override
  String notEnoughChipsMessage(int required, int chips) {
    return 'الرهان $required رقائق ولديك $chips. اشترِ المزيد من الرقائق لإعادة المباراة.';
  }

  @override
  String get buyChips => 'شراء رقائق';

  @override
  String get tutLessonValuesTitle => 'الهدف وقيم الأوراق';

  @override
  String get tutLessonDealTitle => 'التوزيع والنظرة الأولى';

  @override
  String get tutLessonSwapTitle => 'السحب والتبديل';

  @override
  String get tutLessonThrowTitle => 'رمي ورقة';

  @override
  String get tutLessonDoubleTitle => 'الرمي المزدوج';

  @override
  String get tutLessonMatchTitle => 'مطابقة ورقة الرمي';

  @override
  String get tutLessonJackTitle => 'الولد: النظرة';

  @override
  String get tutLessonQueenTitle => 'الملكة: تبديل أو خلط';

  @override
  String get tutLessonEndTitle => 'نهاية اللعبة والنقاط';

  @override
  String get tutLessonTipsTitle => 'نصائح للفوز';

  @override
  String get tutValuesIntro =>
      'ShadowHand لعبة ذاكرة لشخصين. لكل لاعب أوراق مقلوبة. عند نهاية اللعبة يجمع كل لاعب أوراقه — صاحب أقل مجموع يفوز.';

  @override
  String get tutValuesChart =>
      'لكل ورقة نقاط. الآس = 1، أوراق الأرقام = رقمها، الولد = 11، الملكة = 12، الملك الأحمر = 13. أفضل الأوراق: الملك الأسود = 0 والجوكر = −1!';

  @override
  String get tutValuesQuizLowest =>
      'اختبار سريع: اضغط على الورقة الأقل نقاطًا.';

  @override
  String get tutValuesQuizLowestWrong =>
      'ليس تمامًا. الجوكر يساوي −1 — أقل حتى من الآس.';

  @override
  String get tutValuesQuizKing => 'هنا ملكان. اضغط على الملك الذي يساوي 0.';

  @override
  String get tutValuesQuizKingWrong =>
      'الملوك السوداء فقط (♠ ♣) تساوي 0. الملوك الحمراء (♥ ♦) تساوي 13 — أسوأ ورقة في الرزمة!';

  @override
  String get tutValuesDone =>
      'ممتاز! هدفك: احتفظ بالأوراق المنخفضة وتخلّص من المرتفعة.';

  @override
  String get tutDealIntro =>
      'يحصل كل لاعب على 4 أوراق مقلوبة في صف واحد. لا تعرف ما هي بعد — وخصمك أيضًا.';

  @override
  String get tutDealReveal =>
      'قبل بدء اللعب، لديك نظرة سريعة واحدة. اضغط على كشف.';

  @override
  String get tutDealMemorize =>
      'تظهر ورقتاك على اليسار لبضع ثوانٍ. تذكّرهما: 2 و 8!';

  @override
  String get tutDealQuiz => 'أصبحتا مقلوبتين مجددًا. أين الـ 2؟ اضغط عليها.';

  @override
  String get tutDealQuizWrong =>
      'كانت الـ 2 ورقتك الأولى في أقصى اليسار. الذاكرة هي كل شيء في هذه اللعبة!';

  @override
  String get tutDealDone =>
      'صحيح! ورقتاك الأخريان ما زالتا لغزًا — ستعرف المزيد أثناء اللعب.';

  @override
  String get tutDrawPrompt => 'دورك الآن. اضغط على الرزمة لسحب ورقة.';

  @override
  String get tutSwapIntro =>
      'تتذكر ورقتيك الأوليين: 2 و 9. الـ 9 نقاطها كثيرة — لنستبدلها.';

  @override
  String get tutSwapPick =>
      'سحبت 3. إنها أفضل من الـ 9! اضغط على الـ 9 (الورقة الثانية) لتبديلهما.';

  @override
  String get tutSwapPickWrong =>
      'اضغط على الـ 9 — الورقة الثانية من اليسار. تبديل ورقة لا تعرفها مخاطرة.';

  @override
  String get tutSwapDone =>
      'توضع الـ 3 مقلوبة مكان الـ 9، وتذهب الـ 9 إلى كومة الرمي. انتهى دورك — ووفّرت 6 نقاط.';

  @override
  String get tutThrowPick =>
      'آه — ملك أحمر قيمته 13. لا تريده! اضغط على الورقة المسحوبة لرميها في كومة الرمي.';

  @override
  String get tutThrowWrong =>
      'لا تحتفظ بورقة سيئة. اضغط على الورقة المسحوبة (أسفل اليسار) لرميها.';

  @override
  String get tutThrowDone =>
      'تم الرمي! لم تتغير أوراقك وانتهى دورك. ارمِ أي ورقة لا تحسّن يدك.';

  @override
  String get tutDoubleIntro => 'تتذكر أن ورقتك الأولى هي 5.';

  @override
  String get tutDoublePick =>
      '5 أخرى! عندما تكون الورقة المسحوبة بنفس رتبة إحدى أوراقك، اضغط على ورقتك: تُرمى الورقتان معًا.';

  @override
  String get tutDoubleWrong => 'اضغط على الـ 5 — الورقة الأولى على اليسار.';

  @override
  String get tutDoubleDone =>
      'ذهبت الخمستان وأصبح لديك ورقة أقل. أوراق أقل تعني نقاطًا أقل — وإذا نفدت أوراقك تنتهي اللعبة.';

  @override
  String get tutMatchIntro => 'تتذكر أن ورقتك الأولى هي 7. الآن دور خصمك…';

  @override
  String get tutMatchPick =>
      'رمى خصمك 7! في دورك، وقبل السحب، يمكنك الضغط على ورقة بنفس رتبة الورقة العليا في كومة الرمي للتخلص منها. اضغط على الـ 7.';

  @override
  String get tutMatchWrong => 'اضغط على الـ 7 — الورقة الأولى على اليسار.';

  @override
  String get tutMatchContinue =>
      'رمي مجاني! المطابقة لا تنهي دورك: يمكنك المطابقة مجددًا ثم تسحب كالمعتاد. اضغط على الرزمة.';

  @override
  String get tutMatchThrow => '8 — ليست جيدة. اضغط عليها لرميها وإنهاء دورك.';

  @override
  String get tutMatchGuess =>
      'في الدور التالي، الورقة العليا 4. تظن أن ورقتك الوسطى قد تكون 4… لكنك لست متأكدًا. لنرَ ما يحدث عند الخطأ: اضغط عليها.';

  @override
  String get tutMatchPenalty =>
      'خطأ — لم تكن 4. تحصل على ورقة عقوبة مقلوبة من الرزمة، وتبقى الورقة التي ضغطتها. طابق فقط عندما تكون متأكدًا!';

  @override
  String get tutJackPeekButton =>
      'ولد! عند سحب الولد يمكنك النظر إلى ورقة واحدة — من أوراقك أو أوراق خصمك. اضغط على اطّلاع.';

  @override
  String get tutJackPick =>
      'اضغط الآن على الورقة التي تريد رؤيتها. لنتجسس على الورقة الثانية لخصمك.';

  @override
  String get tutJackPickWrong => 'اضغط على الورقة الثانية لخصمك من اليسار.';

  @override
  String get tutJackReveal =>
      'إنها ملكة — 12 نقطة له. تذكّر مكانها: ستختفي بعد لحظة.';

  @override
  String get tutJackDone =>
      'بعد النظرة يُرمى الولد تلقائيًا وينتهي دورك. القدرة اختيارية: يمكنك أيضًا الاحتفاظ بالولد أو رميه كأي ورقة.';

  @override
  String get tutQueenIntro => 'تتذكر أن ورقتك الثانية هي 10. لنعطها لخصمك.';

  @override
  String get tutQueenButtons =>
      'ملكة! لديك خيار. خلط يمزج أوراق أحد اللاعبين. استبدال يبدّل ورقة من أوراقك بورقة من أوراقه. اضغط على استبدال.';

  @override
  String get tutQueenButtonsWrong => 'في هذا الدرس، اضغط على استبدال.';

  @override
  String get tutQueenPickYours =>
      'اضغط أولًا على الورقة التي تريد التخلي عنها: الـ 10، الورقة الثانية.';

  @override
  String get tutQueenPickYoursWrong =>
      'اضغط على الـ 10 — ورقتك الثانية من اليسار.';

  @override
  String get tutQueenPickTheirs =>
      'اضغط الآن على ورقة الخصم التي تريد أخذها: ورقته الأولى.';

  @override
  String get tutQueenPickTheirsWrong =>
      'اضغط على الورقة الأولى لخصمك على اليسار.';

  @override
  String get tutQueenDone =>
      'تم التبديل! الـ 10 أصبحت لخصمك. لا ترى الورقة التي حصلت عليها، لكن معظم الأوراق أقل من 10 — صفقة جيدة. تُرمى الملكة بعد استخدامها.';

  @override
  String get tutQueenShuffle =>
      'الخلط هو الخيار الآخر: امزج أوراق خصمك فيصبح كل ما تذكّره بلا فائدة. يمكنك أيضًا خلط أوراقك.';

  @override
  String get tutEndIntro =>
      'تنتهي اللعبة بطريقتين: لاعب نفدت أوراقه، أو ضغط أحدهم على إنهاء اللعبة.';

  @override
  String get tutEndPress =>
      'تظن أن مجموعك أقل؟ يمكن لأي لاعب الضغط على إنهاء اللعبة في أي وقت. جرّب.';

  @override
  String get tutEndCount =>
      'كُشفت كل الأوراق. اجمع أوراقك: 3 + 2 + ملك أسود + جوكر. كم مجموعك؟';

  @override
  String get tutEndCountWrong =>
      'تذكّر: الملك الأسود = 0 والجوكر = −1. إذن 3 + 2 + 0 − 1 = 4.';

  @override
  String get tutEndWinner => 'مجموع خصمك 9 + 5 + 7 + 1 = 22. من الفائز؟';

  @override
  String get tutEndWinnerWrong => 'أقل مجموع يفوز: 4 تهزم 22.';

  @override
  String get tutEndDone => 'فزت! إذا تساوى المجموعان فهي تعادل.';

  @override
  String get tutTipMemory =>
      'نصيحة 1 — تذكّر كل شيء. كل ورقة تراها — في البداية، عند التبديل، بالولد — معلومة. احفظها.';

  @override
  String get tutTipKeepLow =>
      'نصيحة 2 — احتفظ بالملوك السوداء والجوكر. قيمتها 0 و −1: لا تبدّلها أبدًا.';

  @override
  String get tutTipDiscard =>
      'نصيحة 3 — راقب كومة الرمي. كل ورقة يرميها خصمك فرصة لمطابقة إحدى أوراقك مجانًا.';

  @override
  String get tutTipQueen =>
      'نصيحة 4 — استخدم الملكات بذكاء. تخلَّ عن أعلى ورقة لديك، أو اخلط لتفسد ذاكرة خصمك.';

  @override
  String get tutTipEnd =>
      'نصيحة 5 — أنهِ في الوقت المناسب. إذا ظننت أن مجموعك أقل، اضغط على إنهاء اللعبة قبل أن يلحق بك خصمك.';

  @override
  String get tutChoiceYou => 'أنت';

  @override
  String get tutChoiceOpponent => 'الخصم';

  @override
  String get tutChoiceTie => 'تعادل';

  @override
  String get tutDeckLabel => 'الرزمة';

  @override
  String get tutDiscardLabel => 'الرمي';

  @override
  String get tutDrawnLabel => 'المسحوبة';

  @override
  String get tutAceLabel => 'آس';

  @override
  String get tutNumberCardsLabel => '2 إلى 10';

  @override
  String get tutRedKingLabel => 'ملك أحمر';

  @override
  String get tutTapHighlighted => 'اضغط على العنصر المضيء للمتابعة.';

  @override
  String tutLessonProgress(int current, int total) {
    return 'الدرس $current من $total';
  }

  @override
  String get tutSkip => 'تخطٍّ';

  @override
  String get tutLessonDone => 'اكتمل الدرس!';

  @override
  String get tutReplay => 'إعادة';

  @override
  String get tutFinish => 'إنهاء';

  @override
  String get tutNextLesson => 'الدرس التالي';

  @override
  String get tutCompleteTitle => 'أنت جاهز!';

  @override
  String get tutCompleteBody =>
      'تعرف الآن كل القواعد. تدرّب ضد الروبوت ثم واجه لاعبين حقيقيين.';

  @override
  String get tutHubIntro =>
      'تعلّم ShadowHand باللعب. كل درس قصير يضع الأوراق بين يديك ويشرح قاعدة واحدة.';

  @override
  String get tutStartAll => 'ابدأ الدرس التعليمي';

  @override
  String get tutContinue => 'تابع الدرس التعليمي';

  @override
  String get tutLessonsHeader => 'الدروس';

  @override
  String get tutQuickRules => 'قواعد سريعة';

  @override
  String get tutQuickRulesSubtitle => 'كل القواعد في 7 بطاقات';

  @override
  String get tutPromptTitle => 'جديد في ShadowHand؟';

  @override
  String get tutPromptBody =>
      'تعلّم اللعب عبر درس تفاعلي سريع. يستغرق نحو 3 دقائق.';

  @override
  String get tutPromptLater => 'ليس الآن';

  @override
  String get chat => 'الدردشة';

  @override
  String get chatHint => 'اكتب رسالة…';

  @override
  String get chatEmpty => 'لا توجد رسائل بعد. قل مرحبًا!';

  @override
  String get quickPhrases => 'عبارات سريعة';

  @override
  String get phraseHello => 'مرحبًا!';

  @override
  String get phraseGoodLuck => 'حظًا موفقًا';

  @override
  String get phraseWellPlayed => 'أحسنت اللعب';

  @override
  String get phrasePlayFast => 'العب بسرعة!';

  @override
  String get phraseOops => 'أوبس';

  @override
  String get phraseThanks => 'شكرًا';

  @override
  String get phraseUnlucky => 'سحبة سيئة';

  @override
  String get phraseHehe => 'هههه';

  @override
  String get phraseGg => 'لعبة جيدة';

  @override
  String get micOn => 'الميكروفون مفعّل';

  @override
  String get micOff => 'الميكروفون مغلق';

  @override
  String get micPermissionDenied =>
      'الوصول إلى الميكروفون متوقف. فعّله من إعدادات الهاتف لتتحدث.';

  @override
  String get voiceOpponentTalking => 'الصوت مفعّل';

  @override
  String get muteOpponent => 'كتم اللاعب';

  @override
  String get unmuteOpponent => 'إلغاء كتم اللاعب';

  @override
  String opponentMutedToast(String name) {
    return 'تم كتم $name';
  }

  @override
  String get reportPlayer => 'الإبلاغ عن اللاعب';

  @override
  String reportPlayerConfirm(String name) {
    return 'هل تريد الإبلاغ عن $name بسبب سلوك سيئ؟';
  }

  @override
  String get reportedToast => 'شكرًا، سنراجع هذا اللاعب';

  @override
  String get recentForm => 'الأداء الأخير';

  @override
  String get noRecentMatches => 'لا توجد مباريات بعد';

  @override
  String get tableChatSettings => 'دردشة الطاولة';

  @override
  String get showOpponentChat => 'إظهار دردشة الخصم';

  @override
  String get voiceChatSetting => 'الدردشة الصوتية';

  @override
  String get errChatRateLimited => 'تمهّل، أنت ترسل الرسائل بسرعة كبيرة';

  @override
  String get errChatInvalid => 'تعذّر إرسال الرسالة';

  @override
  String get phraseNiceSwap => 'تبديل رائع!';

  @override
  String get phraseSharpMemory => 'يا لها من ذاكرة!';

  @override
  String get phraseStopPeeking => 'توقف عن التلصص!';

  @override
  String get phraseGiveCardBack => 'أعد لي ورقتي!';

  @override
  String get phraseBlackKingPlease => 'ملكًا أسود من فضلك!';

  @override
  String get phraseLowTotal => 'مجموعي صغير جدًا';

  @override
  String get phraseFoundJoker => 'وجدت جوكر!';

  @override
  String get phraseKnowMyCards => 'أعرف كل أوراقي';

  @override
  String get phraseEndingNextTurn => 'سأنهيها في الدور القادم!';

  @override
  String get dailyStreakTitle => 'السلسلة اليومية';

  @override
  String dailyDay(int day) {
    return 'اليوم $day';
  }

  @override
  String dailyDayOfWeek(int day) {
    return 'اليوم $day من 7';
  }

  @override
  String get dailyToday => 'اليوم';

  @override
  String get dailyTomorrow => 'غدًا';

  @override
  String get dailyJackpot => 'الجائزة الكبرى';

  @override
  String dailyStreakCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'سلسلة $count يوم',
      many: 'سلسلة $count يومًا',
      few: 'سلسلة $count أيام',
      two: 'سلسلة يومين',
      one: 'سلسلة يوم واحد',
      zero: 'ابدأ سلسلتك',
    );
    return '$_temp0';
  }

  @override
  String dailyBest(int best) {
    return 'الأفضل $best';
  }

  @override
  String dailyNextIn(String time) {
    return 'المكافأة التالية بعد $time';
  }

  @override
  String get dailyComeBackTomorrow => 'عُد غدًا';

  @override
  String get dailyShortAd => 'إعلان قصير';

  @override
  String dailyBoostedBadge(int multiplier) {
    return 'مضاعفة ×$multiplier بالإعلان';
  }

  @override
  String get dailyStreakBrokenTitle => 'انقطعت سلسلتك';

  @override
  String dailyStreakBrokenBody(int day) {
    return 'استعدها لتكمل من اليوم $day، أو ابدأ سلسلة جديدة من اليوم 1.';
  }

  @override
  String get dailyRestore => 'استعادة';

  @override
  String get dailyStartOver => 'البدء من جديد';

  @override
  String get dailyGraceForgiven => 'سامحناك على اليوم الفائت';

  @override
  String get dailyFreezeSaves => 'تجميد السلسلة يحمي سلسلتك';

  @override
  String get dailyNewStreak => 'تبدأ سلسلة جديدة اليوم';

  @override
  String dailyEventEnds(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'ينتهي بعد $days يوم',
      many: 'ينتهي بعد $days يومًا',
      few: 'ينتهي بعد $days أيام',
      two: 'ينتهي بعد يومين',
      one: 'ينتهي غدًا',
      zero: 'ينتهي اليوم',
    );
    return '$_temp0';
  }

  @override
  String get dailyCoinBoost => 'معزز العملات';

  @override
  String dailyCoinBoostBody(int percent) {
    return '+$percent% نقود عند الفوز بالمباريات';
  }

  @override
  String get dailyStreakFreeze => 'تجميد السلسلة';

  @override
  String get dailyStreakFreezeBody => 'يحفظ سلسلتك إذا فاتك يوم';

  @override
  String get dailyMysteryChest => 'صندوق غامض';

  @override
  String get dailyChestInside => 'ماذا قد تجد';

  @override
  String get dailyChestNote => 'مكافأة واحدة تُختار عشوائيًا عند الاستلام.';

  @override
  String get dailyMysteryGift => 'هدية غامضة';

  @override
  String get dailyNew => 'جديد!';

  @override
  String get dailyAlreadyOwned => 'تملكه بالفعل';

  @override
  String get dailyCollect => 'اجمع';

  @override
  String get dailyCollected => 'تم الاستلام';

  @override
  String dailyDayReward(int day) {
    return 'مكافأة اليوم $day';
  }

  @override
  String get dailyJackpotWon => 'الجائزة الكبرى!';

  @override
  String get dailyWelcomeBack => 'مرحبًا بعودتك!';

  @override
  String get dailyWelcomeBackBody => 'احتفظنا لك بهدية أثناء غيابك.';

  @override
  String get dailyClaimFailed => 'تعذّر الاستلام الآن. حاول مرة أخرى.';

  @override
  String get dailyLoadFailed => 'تعذّر تحميل سلسلتك.';

  @override
  String get dailyRetry => 'إعادة المحاولة';

  @override
  String dailyEntryReady(int day) {
    return 'مكافأة اليوم $day جاهزة';
  }

  @override
  String get dailyEntryBroken => 'انقطعت السلسلة · استعدها';

  @override
  String get dailyEntryComeback => 'هدية العودة بانتظارك';

  @override
  String get boostsTitle => 'المعززات';

  @override
  String boostReady(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count معززات جاهزة',
      one: 'معزز واحد جاهز',
    );
    return '$_temp0';
  }

  @override
  String boostWinsPay(int percent, String max) {
    return 'انتصارات المال تمنحك +$percent% (حتى $max)';
  }

  @override
  String boostTimeLeft(String time) {
    return 'متبقٍ $time';
  }

  @override
  String get boostActive => 'نشط';

  @override
  String get boostActivate => 'تفعيل';

  @override
  String boostAddTime(String time) {
    return 'أضف $time';
  }

  @override
  String boostWaitsFor(int percent) {
    return 'متاح عند انتهاء معزز +$percent%';
  }

  @override
  String get boostNoneActive => 'لا يوجد معزز نشط';

  @override
  String get boostNoneActiveBody => 'فعّل معززًا لتربح أكثر في كل مباراة مال.';

  @override
  String get boostInventoryEmpty =>
      'لا توجد معززات. سلسلتك اليومية تمنحك إياها.';

  @override
  String boostStarted(int percent) {
    return 'تم تفعيل معزز +$percent%!';
  }

  @override
  String boostExtended(String time) {
    return 'تم تمديد المعزز $time';
  }

  @override
  String get boostActivateFailed => 'تعذر تفعيل المعزز. حاول مجددًا.';

  @override
  String get boostActivateNow => 'فعّل الآن';

  @override
  String get boostInYourBoosts => 'حُفظ في معززاتك';

  @override
  String boostUpTo(String amount) {
    return 'حتى +$amount';
  }

  @override
  String boostPayout(int percent) {
    return 'معزز +$percent%';
  }

  @override
  String get boostMoneyOnly => 'مباريات المال فقط';

  @override
  String boostActiveSemantics(int percent, String time) {
    return 'معزز +$percent% نشط، متبقٍ $time';
  }

  @override
  String get boostOneAtATime =>
      'يعمل مستوى معزز واحد في كل مرة. المستوى نفسه يضيف وقته.';

  @override
  String get shopBadgeNew => 'جديد';

  @override
  String get shopBadgeHot => 'رائج';

  @override
  String get shopBadgePopular => 'شائع';

  @override
  String get shopBadgeBestValue => 'أفضل قيمة';

  @override
  String get shopBadgeLimited => 'محدود';

  @override
  String get shopFeatured => 'مميّز';

  @override
  String shopSaleOff(int percent) {
    return '−$percent٪';
  }

  @override
  String shopEndsIn(String time) {
    return 'ينتهي خلال $time';
  }

  @override
  String shopPackBonus(int amount) {
    return '+$amount مكافأة';
  }

  @override
  String get shopPriceChanged =>
      'تغيّرت الأسعار للتو. راجع السعر الجديد وحاول مرة أخرى.';

  @override
  String get shopOpen => 'افتح';

  @override
  String shopDaysHours(int days, int hours) {
    return '$days ي $hours س';
  }

  @override
  String shopChipPack(int amount) {
    final intl.NumberFormat amountNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String amountString = amountNumberFormat.format(amount);

    String _temp0 = intl.Intl.pluralLogic(
      amount,
      locale: localeName,
      other: '$amountString رقاقة',
      one: 'رقاقة واحدة',
    );
    return '$_temp0';
  }

  @override
  String shopCashPack(int amount) {
    final intl.NumberFormat amountNumberFormat = intl
        .NumberFormat.decimalPattern(localeName);
    final String amountString = amountNumberFormat.format(amount);

    String _temp0 = intl.Intl.pluralLogic(
      amount,
      locale: localeName,
      other: '$amountString نقود',
      one: '1 نقود',
    );
    return '$_temp0';
  }
}
