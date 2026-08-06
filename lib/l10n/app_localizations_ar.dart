// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'CardGame';

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
  String get retryConnection => 'إعادة الاتصال';

  @override
  String get howToPlay => 'طريقة اللعب';

  @override
  String get deck => 'الورق';

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
  String get points => 'نقطة';

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
}
