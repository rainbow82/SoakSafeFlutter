abstract final class AppStrings {
  static const appName = 'SoakSafe';
  static const homeSubtitle = 'Pool maintenance, simplified.';
  static const signIn = 'Sign in';
  static const createAccount = 'Create account';
  static const saveAccount = 'Save account';
  static const saveProfile = 'Save changes';
  static const saveMaintenance = 'Save';
  static const maintenanceSaved = 'Maintenance saved.';
  static const signedInWelcome = 'Welcome back.';
  static const biometricEnableLabel = 'Use fingerprint to sign in';
  static const biometricSignIn = 'Sign in with fingerprint';
  static const biometricEnabled = 'Fingerprint sign-in enabled for this account.';
  static const biometricDisabled = 'Fingerprint sign-in turned off.';
  static const biometricEnableRequiresPassword =
      'Sign in with your password first to enable fingerprint.';
  static const biometricAccountMissing =
      'Saved account no longer exists. Sign in with your password.';
  static const accountCreated = 'Account created. You can sign in now.';
  static const taskVacuum = 'Vacuum';
  static const taskCleanSkimmer = 'Clean skimmer';
  static const taskAddWater = 'Add water';
  static const taskBrushWalls = 'Brush walls';
  static const chemicalChlorine = 'Chlorine';
  static const chemicalPhUp = 'pH up';
  static const chemicalPhDown = 'pH down';
  static const chemicalNoPhos = 'No phos';
  static const sectionTasks = 'Tasks';
  static const sectionChemicals = 'Chemicals';
  static const poolSizeLabel = 'Pool size (gallons, optional)';
  static const hotTubSizeLabel = 'Hot tub size (gallons, optional)';
  static const poolTypeFresh = 'Fresh water';
  static const poolTypeSalt = 'Salt water';
  static const waterBodyPool = 'Pool';
  static const waterBodyHotTub = 'Hot tub';
  static const poolAboveGround = 'Above ground';
  static const poolInGround = 'In-ground';
  static const errorLoginEmpty = 'Enter your username and password.';
  static const errorInvalidCredentials =
      'No account matches that username and password.';
  static const errorUsernameTaken = 'That username is already in use.';
  static const errorCreateEmpty = 'Enter your full name, username, and password.';
  static const errorPoolSize = 'Enter your pool size as a whole number greater than zero.';
  static const errorNoWaterBody =
      'Enter a pool size or a hot tub size (at least one is required).';
  static const maintenanceReportTitle = 'Maintenance Report';
  static const reportNoEvents = 'No maintenance events saved yet.';
  static const reportCardSubtitle = 'Logged maintenance snapshot';
  static const editReportTitle = 'Edit report';
  static const deleteReport = 'Delete report';
  static const deleteReportConfirm =
      'Remove this report entry permanently? This cannot be undone.';
  static const profileTitle = 'Profile';
  static const profileSaved = 'Profile updated.';
  static const profilePhotoAdd = 'Add photo';
  static const profilePhotoChange = 'Change photo';
  static const profilePhotoRemove = 'Remove photo';
  static const profilePhotoSaveFailed = 'Could not save your photo. Try another image.';
  static const menuProfile = 'Profile';
  static const logout = 'Log out';
  static const pdfExportMenu = 'Export PDF';
  static const pdfReportDocumentTitle = 'SoakSafe — Maintenance Report';
  static String pdfReportGeneratedLine(String when) => 'Generated: $when';
  static String pdfReportOwnerLine(String owner) => 'Owner: $owner';
  static const pdfOwnerFallback = 'Pool owner';
  static const pdfColDatetime = 'Date & time';
  static const pdfColItem = 'Item';
  static const pdfColValueStatus = 'Amount / status';
  static const pdfValueCompleted = 'Done';
  static const pdfShareSubject = 'SoakSafe maintenance report';
  static const pdfShareBody = 'Attached: SoakSafe maintenance report (PDF).';
  static const pdfExportReadyTitle = 'Report ready';
  static const pdfActionShare = 'Share or email…';
  static const pdfActionSave = 'Save to device…';
  static const pdfSaved = 'Report saved.';
  static const pdfExportNoData = 'No maintenance entries to export yet.';
  static const pdfExportFailed = 'Could not create the PDF. Try again.';
}
