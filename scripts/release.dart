
import 'dart:convert';
import 'dart:io';

const String pubspecFile = 'pubspec.yaml';

void main() async {
  stdout.writeln('');
  stdout.writeln('==============================================');
  stdout.writeln('       CYRUS TOURIST RELEASE BUILDER');
  stdout.writeln('==============================================');
  stdout.writeln('');

  final pubspec = File(pubspecFile);

  if (!pubspec.existsSync()) {
    stderr.writeln('ERROR: pubspec.yaml پیدا نشد.');
    exitCode = 1;
    return;
  }

  final originalContent = await pubspec.readAsString();

  final versionMatch = RegExp(
    r'^version:\s*([0-9]+)\.([0-9]+)\.([0-9]+)\+([0-9]+)\s*$',
    multiLine: true,
  ).firstMatch(originalContent);

  if (versionMatch == null) {
    stderr.writeln(
      'ERROR: نسخه در pubspec.yaml با فرمت مورد انتظار پیدا نشد.',
    );
    stderr.writeln(
      'فرمت صحیح مثال: version: 5.7.1+5710',
    );
    exitCode = 1;
    return;
  }

  final currentMajor = int.parse(versionMatch.group(1)!);
  final currentMinor = int.parse(versionMatch.group(2)!);
  final currentPatch = int.parse(versionMatch.group(3)!);
  final currentCode = int.parse(versionMatch.group(4)!);

  stdout.writeln(
    'نسخه فعلی: '
    '$currentMajor.$currentMinor.$currentPatch+$currentCode',
  );

  /*
   * منطق افزایش نسخه:
   *
   * 5.7.1 -> 5.8.0
   *
   * سپس:
   * 5.8.0 -> 5.8.1
   * 5.8.1 -> 5.8.2
   * ...
   * 5.8.9 -> 5.9.0
   *
   * versionCode نیز افزایش پیدا می‌کند.
   */

  int newMajor = currentMajor;
  int newMinor = currentMinor;
  int newPatch = currentPatch;

  if (currentMajor == 5 &&
      currentMinor == 7 &&
      currentPatch == 1) {
    // اولین Release جدید پروژه
    newMajor = 5;
    newMinor = 8;
    newPatch = 0;
  } else if (currentPatch >= 9) {
    newMinor++;
    newPatch = 0;
  } else {
    newPatch++;
  }

  /*
   * تضمین می‌کنیم versionCode همیشه بیشتر از قبلی باشد.
   *
   * الگوی پیشنهادی:
   * 5.8.0 -> 5800
   * 5.8.1 -> 5801
   * ...
   */
  int newCode =
      (newMajor * 1000) +
      (newMinor * 100) +
      newPatch;

  if (newCode <= currentCode) {
    newCode = currentCode + 1;
  }

  final newVersion =
      '$newMajor.$newMinor.$newPatch+$newCode';

  stdout.writeln('نسخه جدید:  $newVersion');
  stdout.writeln('');

  /*
   * دریافت مسیر Keystore
   *
   * اگر چیزی وارد نشود، فرض می‌کنیم فایل در:
   *
   * android/app/cyrus-tourist.jks
   */
  stdout.write(
    'مسیر Keystore را وارد کنید '
    '(Enter = android/app/cyrus-tourist.jks): ',
  );

  final keystoreInput = stdin.readLineSync()?.trim() ?? '';

  final keystorePath = keystoreInput.isEmpty
      ? 'android/app/cyrus-tourist.jks'
      : keystoreInput;

  final keystore = File(keystorePath);

  if (!keystore.existsSync()) {
    stderr.writeln('');
    stderr.writeln('ERROR: Keystore پیدا نشد:');
    stderr.writeln(keystorePath);
    stderr.writeln('');
    stderr.writeln('Build متوقف شد.');
    exitCode = 1;
    return;
  }

  stdout.writeln('');
  stdout.writeln('Keystore: $keystorePath');
  stdout.writeln('Alias: CyrusTourist');
  stdout.writeln('');

  /*
   * دریافت رمز Store
   */
  stdout.write('Keystore Password: ');
  final storePassword =
      stdin.readLineSync() ?? '';

  if (storePassword.isEmpty) {
    stderr.writeln('ERROR: رمز Keystore خالی است.');
    exitCode = 1;
    return;
  }

  /*
   * در صورت یکسان بودن رمز Store و Key
   * می‌توان همان رمز را استفاده کرد.
   *
   * اگر رمز Key متفاوت است، مقدار آن را وارد کنید.
   */
  stdout.write(
    'Key Password '
    '(اگر همان رمز Keystore است، Enter بزنید): ',
  );

  final keyPasswordInput =
      stdin.readLineSync() ?? '';

  final keyPassword =
      keyPasswordInput.isEmpty
          ? storePassword
          : keyPasswordInput;

  /*
   * قبل از Build نسخه جدید را موقتاً اعمال می‌کنیم.
   */
  final newContent = originalContent.replaceFirst(
    versionMatch.group(0)!,
    'version: $newVersion',
  );

  await pubspec.writeAsString(newContent);

  stdout.writeln('');
  stdout.writeln('----------------------------------------------');
  stdout.writeln('Version updated temporarily: $newVersion');
  stdout.writeln('Starting Flutter Release Build...');
  stdout.writeln('----------------------------------------------');
  stdout.writeln('');

  /*
   * Environment Variables
   *
   * رمزها فقط برای همین Process وجود دارند.
   */
  final environment =
      Map<String, String>.from(Platform.environment);

  environment['CT_KEYSTORE_FILE'] =
      keystorePath;

  environment['CT_KEYSTORE_PASSWORD'] =
      storePassword;

  environment['CT_KEY_PASSWORD'] =
      keyPassword;

  environment['CT_KEY_ALIAS'] =
      'CyrusTourist';

  /*
   * Build APK Release
   */
  final result = await Process.run(
    'flutter',
    [
      'build',
      'apk',
      '--release',
    ],
    environment: environment,
    runInShell: true,
  );

  stdout.write(result.stdout);

  if (result.stderr.toString().isNotEmpty) {
    stderr.write(result.stderr);
  }

  /*
   * اگر Build موفق نبود:
   *
   * نسخه قبلی را برمی‌گردانیم.
   */
  if (result.exitCode != 0) {
    await pubspec.writeAsString(originalContent);

    stdout.writeln('');
    stdout.writeln('==============================================');
    stdout.writeln('BUILD FAILED');
    stdout.writeln('==============================================');
    stdout.writeln('');
    stdout.writeln(
      'نسخه به مقدار قبلی برگشت:',
    );
    stdout.writeln(
      '$currentMajor.$currentMinor.$currentPatch+$currentCode',
    );
    stdout.writeln('');
    stdout.writeln(
      'هیچ نسخه‌ای ثبت نشد.',
    );

    exitCode = result.exitCode;
    return;
  }

  /*
   * Build موفق شده است.
   *
   * نسخه جدید حفظ می‌شود.
   */
  stdout.writeln('');
  stdout.writeln('==============================================');
  stdout.writeln('BUILD SUCCESSFUL');
  stdout.writeln('==============================================');
  stdout.writeln('');
  stdout.writeln('نسخه جدید: $newVersion');
  stdout.writeln('Application ID: cyrustourist.ir.app');
  stdout.writeln('Alias: CyrusTourist');
  stdout.writeln('');
  stdout.writeln(
    'APK:',
  );
  stdout.writeln(
    'build/app/outputs/flutter-apk/app-release.apk',
  );
  stdout.writeln('');
  stdout.writeln(
    'نسخه جدید با موفقیت ثبت شد.',
  );
  stdout.writeln('');
}
