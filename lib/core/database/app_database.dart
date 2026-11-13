import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

// ==============================================================================
// ETOLE CLEAN SLATE DATABASE (SCHEMA VERSION 1)
// Clean single-identity schema for Brian Etole (Hybrid Filmmaker & Photographer)
// ==============================================================================

class Brands extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get logoPath => text().nullable()();
  TextColumn get accentColorHex =>
      text().withDefault(const Constant('#38B6DB'))();
  TextColumn get address => text().nullable()();
  TextColumn get phone => text().nullable()();
  TextColumn get email => text().nullable()();
  TextColumn get website => text().nullable()();
  TextColumn get kraPin => text().nullable()();
  TextColumn get vatNumber => text().nullable()();
  TextColumn get mpesaDetails => text().nullable()();
  TextColumn get bankDetails => text().nullable()();
  TextColumn get signaturePath => text().nullable()();
  TextColumn get stampPath => text().nullable()();
  TextColumn get footerNote => text().nullable()();
  TextColumn get defaultPdfTemplate =>
      text().withDefault(const Constant('classic'))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get registrationNumber => text().nullable()();
  TextColumn get shortDescription => text().nullable()();
  TextColumn get servicesList => text().nullable()();
  TextColumn get defaultPageSize => text().withDefault(const Constant('A4'))();
  TextColumn get defaultRoundingRule =>
      text().withDefault(const Constant('none'))();
}

class PaymentProfiles extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get brandId =>
      integer().references(Brands, #id, onDelete: KeyAction.cascade)();
  TextColumn get currencyCode => text().withLength(min: 3, max: 5)();
  TextColumn get profileName => text()();
  TextColumn get mpesaPaybillNumber => text().nullable()();
  TextColumn get mpesaPaybillAccount => text().nullable()();
  TextColumn get mpesaTillNumber => text().nullable()();
  TextColumn get bankName => text().nullable()();
  TextColumn get bankBranch => text().nullable()();
  TextColumn get accountName => text().nullable()();
  TextColumn get accountNumber => text().nullable()();
  TextColumn get swiftBic => text().nullable()();
  TextColumn get iban => text().nullable()();
  TextColumn get bankAddress => text().nullable()();
  TextColumn get intermediaryBankDetails => text().nullable()();
  TextColumn get onlinePaymentType => text().nullable()();
  TextColumn get onlinePaymentLinkOrEmail => text().nullable()();
  TextColumn get paymentLink => text().nullable()();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class NumberingSequences extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get brandId =>
      integer().references(Brands, #id, onDelete: KeyAction.cascade)();
  TextColumn get docType => text()();
  TextColumn get prefix => text()();
  IntColumn get currentNumber => integer().withDefault(const Constant(0))();
  IntColumn get nextNumber => integer().withDefault(const Constant(1))();
  IntColumn get numberPadding => integer().withDefault(const Constant(3))();
  TextColumn get formatPattern =>
      text().withDefault(const Constant('{PREFIX}-{YEAR}-{NUM}'))();
  TextColumn get separator => text().withDefault(const Constant('-'))();
  BoolColumn get includeYear => boolean().withDefault(const Constant(false))();
  BoolColumn get resetYearly => boolean().withDefault(const Constant(false))();
  IntColumn get lastResetYear => integer().nullable()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

class Clients extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 150)();
  TextColumn get organization => text().nullable()();
  TextColumn get email => text().nullable()();
  TextColumn get phone => text().nullable()();
  TextColumn get address => text().nullable()();
  TextColumn get kraPin => text().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get cardPhotoPath => text().nullable()();
  TextColumn get preferredCurrency =>
      text().withDefault(const Constant('KES'))();
  RealColumn get defaultWhtRate => real().withDefault(const Constant(0.0))();
  BoolColumn get calculateWhtPostVat =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class ItemsLibrary extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 1, max: 150)();
  TextColumn get description => text().nullable()();
  TextColumn get category =>
      text().withDefault(const Constant('Cinematography'))();
  RealColumn get unitPrice => real().withDefault(const Constant(0.0))();
  TextColumn get unit => text().withDefault(const Constant('Day'))();
  TextColumn get currencyCode => text().withDefault(const Constant('KES'))();
  BoolColumn get isTaxable => boolean().withDefault(const Constant(true))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class TextDefaults extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get brandId =>
      integer().references(Brands, #id, onDelete: KeyAction.cascade)();
  TextColumn get docType => text()();
  TextColumn get titleOverride => text().nullable()();
  TextColumn get introText => text().nullable()();
  TextColumn get closingNotes => text().nullable()();
  TextColumn get termsConditions => text().nullable()();
  TextColumn get footerOverride => text().nullable()();
}

class Documents extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get brandId =>
      integer().references(Brands, #id, onDelete: KeyAction.cascade)();
  IntColumn get clientId => integer().nullable().references(
    Clients,
    #id,
    onDelete: KeyAction.setNull,
  )();
  TextColumn get docType => text()();
  TextColumn get docNumber => text()();
  TextColumn get status => text().withDefault(const Constant('draft'))();
  DateTimeColumn get issueDate => dateTime()();
  DateTimeColumn get dueOrValidityDate => dateTime().nullable()();
  TextColumn get currencyCode => text().withDefault(const Constant('KES'))();
  RealColumn get subtotal => real().withDefault(const Constant(0.0))();
  RealColumn get discountAmount => real().withDefault(const Constant(0.0))();
  RealColumn get discountPercent => real().withDefault(const Constant(0.0))();
  RealColumn get taxPercent => real().withDefault(const Constant(16.0))();
  BoolColumn get isTaxInclusive =>
      boolean().withDefault(const Constant(false))();
  RealColumn get taxAmount => real().withDefault(const Constant(0.0))();
  RealColumn get depositAmount => real().withDefault(const Constant(0.0))();
  RealColumn get depositPercent => real().withDefault(const Constant(0.0))();
  RealColumn get totalAmount => real().withDefault(const Constant(0.0))();
  RealColumn get balanceDue => real().withDefault(const Constant(0.0))();
  TextColumn get titleOverride => text().nullable()();
  TextColumn get introText => text().nullable()();
  TextColumn get closingNotes => text().nullable()();
  TextColumn get termsConditions => text().nullable()();
  TextColumn get footerOverride => text().nullable()();
  TextColumn get pdfTemplate => text().withDefault(const Constant('classic'))();
  BoolColumn get showSignature => boolean().withDefault(const Constant(true))();
  BoolColumn get showStamp => boolean().withDefault(const Constant(true))();
  TextColumn get etimsNumber => text().nullable()();
  TextColumn get jobId => text().nullable()();
  IntColumn get convertedFromId => integer().nullable().references(
    Documents,
    #id,
    onDelete: KeyAction.setNull,
  )();
  RealColumn get whtPercent => real().withDefault(const Constant(0.0))();
  RealColumn get whtAmount => real().withDefault(const Constant(0.0))();
  RealColumn get netAmountPayable => real().withDefault(const Constant(0.0))();
  BoolColumn get isWhtPostVat => boolean().withDefault(const Constant(false))();
  BoolColumn get showAmountInWords =>
      boolean().withDefault(const Constant(true))();
  RealColumn get kesEquivalentRate => real().nullable()();
  RealColumn get kesEquivalentAmount => real().nullable()();
  DateTimeColumn get kesEquivalentDate => dateTime().nullable()();
  IntColumn get paymentProfileId => integer().nullable().references(
    PaymentProfiles,
    #id,
    onDelete: KeyAction.setNull,
  )();
  TextColumn get headerImagePath => text().nullable()();
  TextColumn get footerImagePath => text().nullable()();
  TextColumn get backgroundImagePath => text().nullable()();
  BoolColumn get hideGeneratedHeader =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get printWithoutLetterhead =>
      boolean().withDefault(const Constant(false))();
  TextColumn get pageSize => text().withDefault(const Constant('A4'))();
  TextColumn get roundingRule => text().withDefault(const Constant('none'))();
  BoolColumn get whtCalculateOnFeesOnly =>
      boolean().withDefault(const Constant(true))();
  TextColumn get extraJsonData => text().nullable()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get lastSentAt => dateTime().nullable()();
  DateTimeColumn get nextFollowUpDate => dateTime().nullable()();
  IntColumn get followUpCount => integer().withDefault(const Constant(0))();
}

class DocumentItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get documentId =>
      integer().references(Documents, #id, onDelete: KeyAction.cascade)();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  TextColumn get category => text().nullable()();
  TextColumn get description => text()();
  TextColumn get details => text().nullable()();
  RealColumn get quantity => real().withDefault(const Constant(1.0))();
  TextColumn get unit => text().withDefault(const Constant('Day'))();
  RealColumn get unitPrice => real().withDefault(const Constant(0.0))();
  RealColumn get discountPercent => real().withDefault(const Constant(0.0))();
  RealColumn get amount => real().withDefault(const Constant(0.0))();
  RealColumn get lineTotal => real().withDefault(const Constant(0.0))();
  BoolColumn get isTaxable => boolean().withDefault(const Constant(true))();
}

class DocumentAttachments extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get documentId =>
      integer().references(Documents, #id, onDelete: KeyAction.cascade)();
  TextColumn get filePath => text()();
  TextColumn get fileName => text().nullable()();
  TextColumn get caption => text().nullable()();
  TextColumn get fileType => text().withDefault(const Constant('image'))();
  IntColumn get fileSizeBytes => integer().withDefault(const Constant(0))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  BoolColumn get includeInPdf => boolean().withDefault(const Constant(true))();
  DateTimeColumn get uploadedAt => dateTime().withDefault(currentDateAndTime)();
}

class DocumentActivityLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get documentId =>
      integer().references(Documents, #id, onDelete: KeyAction.cascade)();
  TextColumn get action => text().withDefault(const Constant('update'))();
  TextColumn get actionType => text().withDefault(const Constant('update'))();
  TextColumn get description => text().nullable()();
  DateTimeColumn get timestamp => dateTime().withDefault(currentDateAndTime)();
}

class DocumentSignatures extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get documentId =>
      integer().references(Documents, #id, onDelete: KeyAction.cascade)();
  TextColumn get signerName => text()();
  TextColumn get signerTitle => text().nullable()();
  TextColumn get signerOrganization => text().nullable()();
  TextColumn get signerEmail => text().nullable()();
  TextColumn get signerRole => text().nullable()();
  TextColumn get signatureImagePath => text()();
  DateTimeColumn get signedAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get ipAddress => text().nullable()();
}

class ReusableClauses extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get brandId => integer().nullable().references(
    Brands,
    #id,
    onDelete: KeyAction.cascade,
  )();
  TextColumn get title => text().withLength(min: 1, max: 200)();
  TextColumn get category => text().withDefault(const Constant('General'))();
  TextColumn get bodyText => text().withDefault(const Constant(''))();
  TextColumn get content => text().withDefault(const Constant(''))();
  BoolColumn get isStandard => boolean().withDefault(const Constant(true))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class BusinessCards extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get brandId =>
      integer().references(Brands, #id, onDelete: KeyAction.cascade)();
  TextColumn get cardTitle => text().withLength(min: 1, max: 100)();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
  TextColumn get personName => text().withLength(min: 1, max: 150)();
  TextColumn get personRole => text().nullable()();
  TextColumn get companyName => text().nullable()();
  TextColumn get tagline => text().nullable()();
  TextColumn get photoPath => text().nullable()();
  TextColumn get primaryPhone => text().nullable()();
  TextColumn get secondaryPhone => text().nullable()();
  TextColumn get whatsappNumber => text().nullable()();
  TextColumn get email => text().nullable()();
  TextColumn get website => text().nullable()();
  TextColumn get address => text().nullable()();
  TextColumn get mapUrl => text().nullable()();
  TextColumn get showreelUrl => text().nullable()();
  TextColumn get portfolioUrl => text().nullable()();
  TextColumn get bookingUrl => text().nullable()();
  TextColumn get socialLinksJson => text().nullable()();
  TextColumn get designStyle => text().withDefault(const Constant('ember'))();
  TextColumn get accentColorOverride => text().nullable()();
  TextColumn get defaultQrMode => text().withDefault(const Constant('vcard'))();
  TextColumn get customQrUrl => text().nullable()();
  TextColumn get customQrLabel => text().nullable()();
  TextColumn get whatsappTemplate => text().nullable()();
  TextColumn get hostedLogoUrl => text().nullable()();
  TextColumn get nfcPayload => text().nullable()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

class NetworkingEvents extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get brandId =>
      integer().references(Brands, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text().withLength(min: 1, max: 150)();
  TextColumn get title => text().nullable()();
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime().nullable()();
  TextColumn get location => text().nullable()();
  TextColumn get description => text().nullable()();
  TextColumn get eventType =>
      text().withDefault(const Constant('networking'))();
  TextColumn get occasionType =>
      text().withDefault(const Constant('upcoming'))();
  TextColumn get notes => text().nullable()();
  IntColumn get reminderMinutesBefore =>
      integer().withDefault(const Constant(60))();
  TextColumn get coverPhotoPath => text().nullable()();
  TextColumn get eventPhotosJson => text().nullable()();
  TextColumn get ticketsPhotosJson => text().nullable()();
  RealColumn get latitude => real().nullable()();
  RealColumn get longitude => real().nullable()();
  BoolColumn get isCurrentMode =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get isEventModeActive =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class NetworkingLeads extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get brandId =>
      integer().references(Brands, #id, onDelete: KeyAction.cascade)();
  IntColumn get cardId => integer().nullable().references(
    BusinessCards,
    #id,
    onDelete: KeyAction.setNull,
  )();
  IntColumn get eventId => integer().nullable().references(
    NetworkingEvents,
    #id,
    onDelete: KeyAction.setNull,
  )();
  TextColumn get name => text().withLength(min: 1, max: 150)();
  TextColumn get title => text().nullable()();
  TextColumn get organization => text().nullable()();
  TextColumn get avatarPhotoPath => text().nullable()();
  TextColumn get phone => text().nullable()();
  TextColumn get whatsapp => text().nullable()();
  TextColumn get email => text().nullable()();
  TextColumn get website => text().nullable()();
  TextColumn get physicalAddress => text().nullable()();
  TextColumn get cardPhotoPath => text().nullable()();
  TextColumn get cardBackPhotoPath => text().nullable()();
  TextColumn get rawOcrText => text().nullable()();
  DateTimeColumn get dateMet => dateTime().withDefault(currentDateAndTime)();
  TextColumn get locationMet => text().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get whoIntroduced => text().nullable()();
  TextColumn get promisesJson => text().nullable()();
  TextColumn get socialLinksJson => text().nullable()();
  TextColumn get photosWithPersonJson => text().nullable()();
  TextColumn get voiceNotesJson => text().nullable()();
  TextColumn get flyersPhotosJson => text().nullable()();
  TextColumn get eventIdsJson => text().nullable()();
  TextColumn get interestTagsJson => text().nullable()();
  DateTimeColumn get followUpDate => dateTime().nullable()();
  TextColumn get followUpStatus =>
      text().withDefault(const Constant('pending'))();
  TextColumn get status => text().withDefault(const Constant('new'))();
  IntColumn get convertedClientId => integer().nullable().references(
    Clients,
    #id,
    onDelete: KeyAction.setNull,
  )();
  BoolColumn get isClient => boolean().withDefault(const Constant(false))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

class ProductionProjects extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get brandId =>
      integer().references(Brands, #id, onDelete: KeyAction.cascade)();
  IntColumn get clientId => integer().nullable().references(
    Clients,
    #id,
    onDelete: KeyAction.setNull,
  )();
  TextColumn get title => text().withLength(min: 1, max: 200)();
  TextColumn get clientName => text().withLength(min: 1, max: 200)();
  TextColumn get projectType =>
      text().withDefault(const Constant('Commercial'))();
  TextColumn get stage =>
      text().withDefault(const Constant('pre_production'))(); // pre_production, production, post_production, client_review, delivered, archived
  DateTimeColumn get shootDate => dateTime().nullable()();
  DateTimeColumn get deliveryDueDate => dateTime().nullable()();
  TextColumn get location => text().nullable()();
  RealColumn get budgetAmount => real().withDefault(const Constant(0.0))();
  IntColumn get linkedDocumentId => integer().nullable().references(
    Documents,
    #id,
    onDelete: KeyAction.setNull,
  )();
  TextColumn get notes => text().nullable()();
  TextColumn get coverPhotoPath => text().nullable()();
  TextColumn get deliveryLinksJson =>
      text().nullable()(); // JSON list of {platform, url, notes}
  TextColumn get milestonesJson =>
      text().nullable()(); // JSON list of {id, name, isDone, dueDate}
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

class CallSheets extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get brandId =>
      integer().references(Brands, #id, onDelete: KeyAction.cascade)();
  IntColumn get projectId => integer().nullable().references(
    ProductionProjects,
    #id,
    onDelete: KeyAction.setNull,
  )();
  TextColumn get title => text().withLength(min: 1, max: 200)();
  DateTimeColumn get shootDate => dateTime().withDefault(currentDateAndTime)();
  TextColumn get callTime => text().withDefault(const Constant('06:30 AM'))();
  TextColumn get sunriseTime => text().nullable()();
  TextColumn get sunsetTime => text().nullable()();
  TextColumn get weatherForecast => text().nullable()();
  TextColumn get locationName => text()();
  TextColumn get locationAddress => text().nullable()();
  TextColumn get locationGps => text().nullable()();
  TextColumn get nearestHospital => text().nullable()();
  TextColumn get crewJson =>
      text().nullable()(); // JSON list of {role, name, phone, callTime}
  TextColumn get talentJson =>
      text().nullable()(); // JSON list of {character, actor, phone, callTime}
  TextColumn get scheduleJson =>
      text().nullable()(); // JSON list of {time, scene, description, location}
  TextColumn get gearRequiredJson =>
      text().nullable()(); // JSON list of gear items required
  TextColumn get generalNotes => text().nullable()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class GearItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get brandId =>
      integer().references(Brands, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text().withLength(min: 1, max: 150)();
  TextColumn get category => text().withDefault(
    const Constant('Camera'),
  )(); // Camera, Lens, Drone, Lighting, Audio, Support, Power, Media
  TextColumn get serialNumber => text().nullable()();
  BoolColumn get isPacked => boolean().withDefault(const Constant(false))();
  BoolColumn get isCheckedOut => boolean().withDefault(const Constant(false))();
  TextColumn get notes => text().nullable()();
  TextColumn get photoPath => text().nullable()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Meetings extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 1, max: 200)();
  DateTimeColumn get meetingDate =>
      dateTime().withDefault(currentDateAndTime)();
  TextColumn get locationOrLink => text().nullable()();
  TextColumn get meetingType => text().withDefault(
    const Constant('Client'),
  )(); // Client, Team, Partner, Personal
  TextColumn get projectName => text().nullable()(); // Roots, TICAH, etc.
  TextColumn get peopleJson =>
      text().nullable()(); // JSON array of person names
  BoolColumn get consentNoted => boolean().withDefault(const Constant(false))();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

class MeetingRecordings extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get meetingId =>
      integer().references(Meetings, #id, onDelete: KeyAction.cascade)();
  TextColumn get audioFilePath => text()();
  IntColumn get durationSeconds => integer().withDefault(const Constant(0))();
  BoolColumn get isTranscribed =>
      boolean().withDefault(const Constant(false))();
  TextColumn get transcriptJson => text().nullable()();
  TextColumn get languageUsed => text().withDefault(const Constant('en'))();
  TextColumn get modelUsed => text().withDefault(const Constant('base'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class MeetingBookmarks extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get meetingId =>
      integer().references(Meetings, #id, onDelete: KeyAction.cascade)();
  IntColumn get timestampMs => integer().withDefault(const Constant(0))();
  TextColumn get bookmarkType => text().withDefault(
    const Constant('Important'),
  )(); // Important, Decision, Task for Me
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class MeetingNotes extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get meetingId =>
      integer().references(Meetings, #id, onDelete: KeyAction.cascade)();
  IntColumn get timestampMs => integer().withDefault(const Constant(0))();
  TextColumn get noteText => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class MeetingTasks extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get meetingId => integer().nullable().references(
    Meetings,
    #id,
    onDelete: KeyAction.setNull,
  )();
  IntColumn get audioTimestampMs => integer().nullable()();
  TextColumn get taskDescription => text()();
  TextColumn get assignedBy => text().nullable()();
  DateTimeColumn get dueDate => dateTime().nullable()();
  BoolColumn get isDone => boolean().withDefault(const Constant(false))();
  DateTimeColumn get doneAt => dateTime().nullable()();
  TextColumn get projectName => text().nullable()();
  TextColumn get meetingType => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class MeetingAgendas extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get meetingId =>
      integer().references(Meetings, #id, onDelete: KeyAction.cascade)();
  TextColumn get pointText => text()();
  BoolColumn get isChecked => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
}

// --- DATABASE CLASS ---

@DriftDatabase(
  tables: [
    Brands,
    PaymentProfiles,
    NumberingSequences,
    Clients,
    ItemsLibrary,
    TextDefaults,
    Documents,
    DocumentItems,
    DocumentAttachments,
    DocumentSignatures,
    DocumentActivityLogs,
    ReusableClauses,
    BusinessCards,
    NetworkingEvents,
    NetworkingLeads,
    ProductionProjects,
    CallSheets,
    GearItems,
    Meetings,
    MeetingRecordings,
    MeetingBookmarks,
    MeetingNotes,
    MeetingTasks,
    MeetingAgendas,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e]) : super(e ?? _openConnection());

  @override
  int get schemaVersion => 4;

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'creative_os_db');
  }

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
      await _seedCleanCreativeOsData(this);
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 2) {
        await m.addColumn(networkingEvents, networkingEvents.coverPhotoPath);
        await m.addColumn(networkingEvents, networkingEvents.eventPhotosJson);
        await m.addColumn(networkingEvents, networkingEvents.ticketsPhotosJson);
        await m.addColumn(networkingEvents, networkingEvents.latitude);
        await m.addColumn(networkingEvents, networkingEvents.longitude);
        await m.addColumn(networkingLeads, networkingLeads.avatarPhotoPath);
        await m.addColumn(networkingLeads, networkingLeads.whoIntroduced);
        await m.addColumn(networkingLeads, networkingLeads.promisesJson);
        await m.addColumn(networkingLeads, networkingLeads.socialLinksJson);
        await m.addColumn(
          networkingLeads,
          networkingLeads.photosWithPersonJson,
        );
        await m.addColumn(networkingLeads, networkingLeads.voiceNotesJson);
        await m.addColumn(networkingLeads, networkingLeads.flyersPhotosJson);
        await m.addColumn(networkingLeads, networkingLeads.eventIdsJson);
      }
      if (from < 3) {
        await m.createTable(productionProjects);
        await m.createTable(callSheets);
        await m.createTable(gearItems);
      }
      if (from < 4) {
        await m.createTable(meetings);
        await m.createTable(meetingRecordings);
        await m.createTable(meetingBookmarks);
        await m.createTable(meetingNotes);
        await m.createTable(meetingTasks);
        await m.createTable(meetingAgendas);
      }
    },
    beforeOpen: (details) async {
      // Set official themed logo if unset or pointing to a missing local path
      final allActiveBrands = await (select(
        brands,
      )..where((t) => t.isActive.equals(true))).get();
      for (final b in allActiveBrands) {
        if (b.logoPath == null ||
            b.logoPath!.isEmpty ||
            (!b.logoPath!.startsWith('assets/') &&
                !File(b.logoPath!).existsSync())) {
          await (update(brands)..where((t) => t.id.equals(b.id))).write(
            const BrandsCompanion(
              logoPath: Value('assets/icon/app_icon.png'),
            ),
          );
        }
      }

      // Self-heal document numbering sequences and repair any literal "{PREFIX}-{NUM}" placeholder text
      try {
        // 1. Upgrade legacy format patterns to include YEAR and clean tokens
        await (update(numberingSequences)
              ..where((t) => t.formatPattern.equals('{PREFIX}-{NUM}')))
            .write(
          const NumberingSequencesCompanion(
            formatPattern: Value('{PREFIX}-{YEAR}-{NUM}'),
          ),
        );

        // 2. Find any documents saved with unexpanded placeholder numbers (e.g. "{PREFIX}-{NUM}")
        final brokenDocs = await (select(documents)
              ..where((t) => t.docNumber.like('%{%') | t.docNumber.like('%PREFIX%') | t.docNumber.like('%NUM%')))
            .get();

        if (brokenDocs.isNotEmpty) {
          final prefixMap = {
            'quotation': 'COS-QT',
            'invoice': 'COS-INV',
            'receipt': 'COS-REC',
            'rate_card': 'COS-RC',
            'contract': 'COS-CON',
          };

          // Group by doc_type and assign clean sequential numbers
          final typeCounters = <String, int>{};
          for (final doc in brokenDocs) {
            final type = doc.docType.toLowerCase();
            final count = (typeCounters[type] ?? 0) + 1;
            typeCounters[type] = count;

            final prefix = prefixMap[type] ?? 'COS-DOC';
            final year = doc.issueDate.year;
            final cleanNum = '$prefix-$year-${count.toString().padLeft(3, '0')}';

            await (update(documents)..where((t) => t.id.equals(doc.id))).write(
              DocumentsCompanion(
                docNumber: Value(cleanNum),
              ),
            );
          }

          // Update numbering_sequences counters to ensure future numbers don't conflict
          for (final entry in typeCounters.entries) {
            final seq = await (select(numberingSequences)
                  ..where((t) => t.docType.equals(entry.key)))
                .getSingleOrNull();
            if (seq != null && seq.currentNumber < entry.value) {
              await (update(numberingSequences)
                    ..where((t) => t.id.equals(seq.id)))
                  .write(
                NumberingSequencesCompanion(
                  currentNumber: Value(entry.value),
                  nextNumber: Value(entry.value + 1),
                ),
              );
            }
          }
        }
      } catch (_) {
        // Silent safety fallback
      }
    },
  );
}

/// Pre-fills clean identity data for Creative OS.
/// Payment details (bank & M-Pesa) are deliberately left empty for the creative entrepreneur to fill in.
Future<void> _seedCleanCreativeOsData(AppDatabase db) async {
  // 1. Single Brand Identity: Creative Studio
  final brandId = await db
      .into(db.brands)
      .insert(
        BrandsCompanion.insert(
          name: 'Creative Studio',
          email: const Value('hello@brianetole.com'),
          phone: const Value('+254 718 013 579'),
          address: const Value('Nairobi, Kenya'),
          website: const Value('brianetole.com'),
          accentColorHex: const Value('#38B6DB'),
          logoPath: const Value('assets/icon/app_icon.png'),
          shortDescription: const Value('CREATIVE ENTREPRENEUR'),
          servicesList: const Value(
            'Cinematography, Commercial Photography, Drone Operations, Color Grading, Creative Direction',
          ),
          defaultPdfTemplate: const Value('classic'),
          defaultPageSize: const Value('A4'),
          defaultRoundingRule: const Value('none'),
          isActive: const Value(true),
          mpesaDetails: const Value(null),
          bankDetails: const Value(null),
        ),
      );

  // 2. Empty Payment Profile for user to configure
  await db
      .into(db.paymentProfiles)
      .insert(
        PaymentProfilesCompanion.insert(
          brandId: brandId,
          currencyCode: 'KES',
          profileName: 'Standard Payment Profile',
          isDefault: const Value(true),
        ),
      );

  // 3. Numbering Sequences for the 5 Clean Document Types
  final docTypes = [
    {'type': 'quotation', 'prefix': 'COS-QT'},
    {'type': 'invoice', 'prefix': 'COS-INV'},
    {'type': 'receipt', 'prefix': 'COS-REC'},
    {'type': 'rate_card', 'prefix': 'COS-RC'},
    {'type': 'contract', 'prefix': 'COS-CON'},
  ];

  for (final dt in docTypes) {
    await db
        .into(db.numberingSequences)
        .insert(
          NumberingSequencesCompanion.insert(
            brandId: brandId,
            docType: dt['type']!,
            prefix: dt['prefix']!,
            currentNumber: const Value(0),
            nextNumber: const Value(1),
            numberPadding: const Value(3),
            formatPattern: const Value('{PREFIX}-{YEAR}-{NUM}'),
          ),
        );
  }

  // 4. Five Production Day Rates / Services
  final services = [
    {
      'title': 'Cinematography Day Rate',
      'desc': 'Full-day principal photography with cinema camera package, lighting & prime optics.',
      'category': 'Cinematography',
      'price': 45000.0,
      'unit': 'Day',
    },
    {
      'title': 'Commercial Photography Day Rate',
      'desc': 'Editorial, portraiture, or commercial still capture with tethered studio lighting.',
      'category': 'Photography',
      'price': 35000.0,
      'unit': 'Day',
    },
    {
      'title': 'Drone Aerial Cinematography',
      'desc': 'Licensed aerial capture in 4K/60fps ProRes / D-Log M with FAA/KCAA compliant piloting.',
      'category': 'Drone',
      'price': 30000.0,
      'unit': 'Day',
    },
    {
      'title': 'Video Post-Production & Color Grade',
      'desc': 'DaVinci Resolve film emulation grading, pacing cut, sound design, and master export.',
      'category': 'Post-Production',
      'price': 25000.0,
      'unit': 'Day',
    },
    {
      'title': 'Half-Day Production Rate',
      'desc': 'Up to 5 hours on-set production or single-location interview session.',
      'category': 'Cinematography',
      'price': 25000.0,
      'unit': 'Half-Day',
    },
  ];

  for (var i = 0; i < services.length; i++) {
    final s = services[i];
    await db
        .into(db.itemsLibrary)
        .insert(
          ItemsLibraryCompanion.insert(
            title: s['title'] as String,
            description: Value(s['desc'] as String),
            category: Value(s['category'] as String),
            unitPrice: Value(s['price'] as double),
            unit: Value(s['unit'] as String),
            currencyCode: const Value('KES'),
            sortOrder: Value(i),
          ),
        );
  }

  // 5. Standard Film & Photography Contract Clauses
  final clauses = [
    {
      'title': 'Copyright & Usage Rights',
      'category': 'Legal',
      'content': 'The Service Provider retains worldwide copyright and authorship rights to all original footage and still works. The Client is granted an exclusive, non-transferable, commercial license to broadcast, publish, and distribute the final approved deliverables across all media upon full settlement of all outstanding invoices.',
    },
    {
      'title': 'Payment Terms & Milestone Schedule',
      'category': 'Payment',
      'content': 'A 50% non-refundable production advance is required to secure project dates. The remaining 50% balance is due strictly within fourteen (14) days upon delivery of the final master cut or high-resolution stills gallery.',
    },
    {
      'title': 'Turnaround & Revisions Policy',
      'category': 'Production',
      'content': 'First cut delivery is scheduled within 7 business days following wrap. Up to two (2) rounds of consolidation feedback revisions are included. Subsequent creative revisions or scope deviations will be billed at standard day rates.',
    },
    {
      'title': 'Weather & Rescheduling Contingency',
      'category': 'Production',
      'content': 'Outdoor shoots disrupted by inclement weather or force majeure will be rescheduled to the earliest mutually agreed date. Any non-recoverable direct vendor or location costs incurred remain payable by the Client.',
    },
    {
      'title': 'Cancellation & Retainer',
      'category': 'Legal',
      'content': 'Cancellations initiated less than forty-eight (48) hours prior to call time forfeit the initial 50% advance retainer to cover reserved crew dates and gear logistics commitments.',
    },
    {
      'title': 'Raw Footage & Archival Storage',
      'category': 'Deliverables',
      'content': 'Project camera master rushes and project files are archived securely for six (6) months following project wrap. Raw camera source files are not delivered unless explicitly commissioned under a separate archive licensing buyout agreement.',
    },
  ];

  for (var i = 0; i < clauses.length; i++) {
    final c = clauses[i];
    await db
        .into(db.reusableClauses)
        .insert(
          ReusableClausesCompanion.insert(
            brandId: Value(brandId),
            title: c['title']!,
            category: Value(c['category']!),
            bodyText: Value(c['content']!),
            content: Value(c['content']!),
            isStandard: const Value(true),
            sortOrder: Value(i),
          ),
        );
  }

  // 6. Default Primary Digital Business Card
  await db
      .into(db.businessCards)
      .insert(
        BusinessCardsCompanion.insert(
          brandId: brandId,
          cardTitle: 'Studio Card',
          personName: 'Creative Director',
          personRole: const Value('Director & Creative Entrepreneur'),
          companyName: const Value('Creative Studio'),
          tagline: const Value('DESIGNED FOR IMPACT.'),
          email: const Value('hello@brianetole.com'),
          primaryPhone: const Value('+254 718 013 579'),
          website: const Value('https://brianetole.com'),
          showreelUrl: const Value('https://brianetole.com/films'),
          portfolioUrl: const Value('https://brianetole.com/photography'),
          address: const Value('Nairobi, Kenya'),
          designStyle: const Value('ember'),
          defaultQrMode: const Value('vcard'),
          isDefault: const Value(true),
        ),
      );
}
