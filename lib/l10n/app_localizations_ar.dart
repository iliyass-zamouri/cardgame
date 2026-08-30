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
  String get deck => 'الورق';

  @override
  String get settings => 'الإعدادات';

  @override
  String get language => 'اللغة';

  @override
  String get signOut => 'تسجيل الخروج';

  @override
  String get guest => 'ضيف';

  @override
  String get google => 'Google';

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
      'أفرغ أوراقك الأربع، أو احصل على أقل مجموع عند انتهاء اللعبة. الأقل مجموعًا يفوز.';

  @override
  String get ruleSetupTitle => 'الإعداد';

  @override
  String get ruleSetupBody => 'لاعبان. يحصل كل منهما على أربع أوراق مقلوبة.';

  @override
  String get ruleOpeningPeekTitle => 'اطّلاع البداية';

  @override
  String get ruleOpeningPeekBody =>
      'قبل اللعب، يطّلع كلا اللاعبين على ورقتين من أوراقهما (الصف السفلي) لبضع ثوانٍ. تذكّرهما — ثم تُقلبان مجددًا.';

  @override
  String get ruleYourTurnTitle => 'دورك';

  @override
  String get ruleYourTurnBody =>
      'اسحب من الكومة، أو إذا طابقت أعلى ورقة في المرمى ورقة تعرفها، المسها لرميها (يستمر دورك). تخمين خاطئ = ورقة جزاء في صفّك.';

  @override
  String get ruleAfterDrawTitle => 'بعد السحب';

  @override
  String get ruleAfterDrawBody =>
      'المس إحدى أوراقك للتبديل (رتبة مختلفة) أو الرمي المزدوج (نفس الرتبة)، أو ارْمِ الورقة المسحوبة إلى المرمى. ثم ينتهي دورك.';

  @override
  String get ruleSpecialTitle => 'أوراق خاصة';

  @override
  String get ruleSpecialBody =>
      'هذه الرتب تفعّل قدرة عند سحبها. بعد القدرة تُرمى الورقة.';

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
      'عندما يفرغ أحد صفّه (أو تنتهي اللعبة)، اجمع الأوراق المتبقية. الأقل مجموعًا يفوز؛ التساوي = تعادل.';

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
  String get goldLuxuryDeck => 'الذهب الفاخر';

  @override
  String get goldLuxuryDeckDesc => 'حزمة أوراق ذهبية فاخرة';

  @override
  String get shadowNeonDeck => 'نيون الظل';

  @override
  String get shadowNeonDeckDesc => 'حزمة أوراق سايبربانك مشعة';

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
  String get prize => 'الجائزة';

  @override
  String get entryFee => 'رسوم الدخول';
}
