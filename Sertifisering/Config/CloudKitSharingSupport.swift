import CloudKit
import UIKit

enum CloudKitSharingSupport {
    private static let companyShareZoneName = "CompanyData"
    private static let companyRootRecordName = "company-dataset"
    private static let modifyRecordsBatchLimit = 400
    static let shareAcceptanceMessageDefaultsKey = "cloudkit.share.acceptance.message"

    struct UploadSummary {
        let recordCount: Int
        let targetDescription: String
    }

    struct DownloadedCompanyData {
        let inspections: [Inspection]
        let recordCount: Int
        let zoneCount: Int
        let sourceDescription: String
    }

    static var containerIdentifier: String {
        PersistenceController.configuredCloudKitContainerIdentifier ?? PersistenceController.defaultCloudKitContainerIdentifier
    }

    static var container: CKContainer {
        CKContainer(identifier: containerIdentifier)
    }

    static func makeCompanySharingController(share: CKShare) -> UICloudSharingController {
        let sharingController = UICloudSharingController(share: share, container: container)
        sharingController.availablePermissions = [.allowPrivate, .allowReadWrite]
        return sharingController
    }

    static func accountStatusText() async -> String {
        do {
            let status = try await container.accountStatus()
            switch status {
            case .available:
                return "iCloud-konto er tilgjengelig for CloudKit."
            case .couldNotDetermine:
                return "Kunne ikke avgjøre iCloud-status. Prøv igjen senere."
            case .noAccount:
                return "Ingen iCloud-konto er aktiv på denne enheten."
            case .restricted:
                return "iCloud-kontoen er begrenset og kan ikke bruke CloudKit."
            case .temporarilyUnavailable:
                return "iCloud er midlertidig utilgjengelig. Prøv igjen senere."
            @unknown default:
                return "Ukjent iCloud-status."
            }
        } catch {
            return "Kunne ikke sjekke iCloud-status: \(error.localizedDescription)"
        }
    }

    static func acceptShare(metadata: CKShare.Metadata) async -> String {
        do {
            _ = try await container.accept(metadata)
            let message = "Delt CloudKit-tilgang er akseptert. Trykk Hent delte firmadata."
            UserDefaults.standard.set(message, forKey: shareAcceptanceMessageDefaultsKey)
            return message
        } catch {
            let message = "Kunne ikke akseptere delt CloudKit-tilgang: \(error.localizedDescription)"
            UserDefaults.standard.set(message, forKey: shareAcceptanceMessageDefaultsKey)
            return message
        }
    }

    static func uploadCompanyData(
        inspections: [Inspection],
        completion: @escaping (Result<UploadSummary, Error>) -> Void
    ) {
        uploadToSharedCompanyDataIfAvailable(inspections: inspections) { sharedResult in
            switch sharedResult {
            case .success(let summary):
                completion(.success(summary))
            case .failure(let error):
                if case CloudKitSharingError.noSharedCompanyData = error {
                    uploadPrivateCompanyData(inspections: inspections, completion: completion)
                } else {
                    completion(.failure(error))
                }
            }
        }
    }

    private static func uploadPrivateCompanyData(
        inspections: [Inspection],
        completion: @escaping (Result<UploadSummary, Error>) -> Void
    ) {
        let database = container.privateCloudDatabase
        let zoneID = CKRecordZone.ID(zoneName: companyShareZoneName, ownerName: CKCurrentUserDefaultName)

        ensureZoneExists(zoneID: zoneID, database: database) { error in
            if let error {
                completion(.failure(error))
                return
            }

            let rootRecordID = CKRecord.ID(recordName: companyRootRecordName, zoneID: zoneID)
            fetchOrCreateCompanyRoot(recordID: rootRecordID, database: database) { rootRecord, error in
                if let error {
                    completion(.failure(error))
                    return
                }

                guard let rootRecord else {
                    completion(.failure(CloudKitSharingError.missingRootRecord))
                    return
                }

                let records = makeCompanyRecords(rootRecord: rootRecord, inspections: inspections, zoneID: zoneID)
                saveRecordsInBatches(records, database: database) { result in
                    switch result {
                    case .success(let recordCount):
                        completion(.success(UploadSummary(recordCount: recordCount, targetDescription: "privat firmadatasone")))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            }
        }
    }

    private static func uploadToSharedCompanyDataIfAvailable(
        inspections: [Inspection],
        completion: @escaping (Result<UploadSummary, Error>) -> Void
    ) {
        let database = container.sharedCloudDatabase

        fetchSharedCompanyRoot(database: database) { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let rootRecord):
                let records = makeCompanyRecords(
                    rootRecord: rootRecord,
                    inspections: inspections,
                    zoneID: rootRecord.recordID.zoneID
                )
                saveRecordsInBatches(records, database: database) { result in
                    switch result {
                    case .success(let recordCount):
                        completion(.success(UploadSummary(recordCount: recordCount, targetDescription: "delt firmadatasone")))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            }
        }
    }

    static func deletePrivateCompanyData(
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        let database = container.privateCloudDatabase
        let zoneID = CKRecordZone.ID(zoneName: companyShareZoneName, ownerName: CKCurrentUserDefaultName)

        database.fetch(withRecordZoneID: zoneID) { _, fetchError in
            if let fetchError {
                if let ckError = fetchError as? CKError, ckError.code == .zoneNotFound || ckError.code == .unknownItem {
                    completion(.success("Ingen private iCloud-testdata funnet."))
                    return
                }

                completion(.failure(fetchError))
                return
            }

            let operation = CKModifyRecordZonesOperation(recordZonesToSave: nil, recordZoneIDsToDelete: [zoneID])
            operation.modifyRecordZonesResultBlock = { result in
                switch result {
                case .success:
                    completion(.success("Private iCloud-testdata er slettet for denne Apple ID-en."))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
            database.add(operation)
        }
    }

    static func downloadSharedCompanyData(
        completion: @escaping (Result<DownloadedCompanyData, Error>) -> Void
    ) {
        let database = container.sharedCloudDatabase

        fetchSharedZoneIDs(database: database) { zoneResult in
            switch zoneResult {
            case .failure(let error):
                completion(.failure(error))
            case .success(let zoneIDs):
                if zoneIDs.isEmpty {
                    downloadPrivateCompanyData(completion: completion)
                    return
                }

                fetchSharedRecords(zoneIDs: zoneIDs, database: database) { recordResult in
                    switch recordResult {
                    case .failure(let error):
                        completion(.failure(error))
                    case .success(let records):
                        let inspectionRecords = records.filter { $0.recordType == "InspectionRecord" }
                        let machineRecords = records.filter { $0.recordType == "MachineRecord" }
                        let itemRecords = records.filter { $0.recordType == "ChecklistItemRecord" }
                        let inspections = makeInspections(
                            inspectionRecords: inspectionRecords,
                            machineRecords: machineRecords,
                            itemRecords: itemRecords
                        )
                        completion(.success(DownloadedCompanyData(
                            inspections: inspections,
                            recordCount: records.count,
                            zoneCount: zoneIDs.count,
                            sourceDescription: "delt firmadatasone"
                        )))
                    }
                }
            }
        }
    }

    private static func downloadPrivateCompanyData(
        completion: @escaping (Result<DownloadedCompanyData, Error>) -> Void
    ) {
        let database = container.privateCloudDatabase
        let zoneID = CKRecordZone.ID(zoneName: companyShareZoneName, ownerName: CKCurrentUserDefaultName)

        database.fetch(withRecordZoneID: zoneID) { _, error in
            if let error {
                if let ckError = error as? CKError, ckError.code == .zoneNotFound || ckError.code == .unknownItem {
                    completion(.success(DownloadedCompanyData(
                        inspections: [],
                        recordCount: 0,
                        zoneCount: 0,
                        sourceDescription: "ingen firmadatasone"
                    )))
                    return
                }

                completion(.failure(error))
                return
            }

            fetchSharedRecords(zoneIDs: [zoneID], database: database) { recordResult in
                switch recordResult {
                case .failure(let error):
                    completion(.failure(error))
                case .success(let records):
                    let inspectionRecords = records.filter { $0.recordType == "InspectionRecord" }
                    let machineRecords = records.filter { $0.recordType == "MachineRecord" }
                    let itemRecords = records.filter { $0.recordType == "ChecklistItemRecord" }
                    let inspections = makeInspections(
                        inspectionRecords: inspectionRecords,
                        machineRecords: machineRecords,
                        itemRecords: itemRecords
                    )
                    completion(.success(DownloadedCompanyData(
                        inspections: inspections,
                        recordCount: records.count,
                        zoneCount: 1,
                        sourceDescription: "privat firmadatasone"
                    )))
                }
            }
        }
    }

    static func prepareCompanyShare(
        completion: @escaping (Result<CKShare, Error>) -> Void
    ) {
        let database = container.privateCloudDatabase
        let zoneID = CKRecordZone.ID(zoneName: companyShareZoneName, ownerName: CKCurrentUserDefaultName)

        ensureZoneExists(zoneID: zoneID, database: database) { error in
            if let error {
                completion(.failure(error))
                return
            }

            let rootRecordID = CKRecord.ID(recordName: companyRootRecordName, zoneID: zoneID)
            fetchOrCreateCompanyRoot(recordID: rootRecordID, database: database) { rootRecord, error in
                if let error {
                    completion(.failure(error))
                    return
                }

                guard let rootRecord else {
                    completion(.failure(CloudKitSharingError.missingRootRecord))
                    return
                }

                if let existingShareReference = rootRecord.share {
                    database.fetch(withRecordID: existingShareReference.recordID) { record, error in
                        if let error {
                            completion(.failure(error))
                            return
                        }

                        guard let share = record as? CKShare else {
                            completion(.failure(CloudKitSharingError.missingShareRecord))
                            return
                        }

                        completion(.success(share))
                    }
                    return
                }

                let share = CKShare(rootRecord: rootRecord)
                share[CKShare.SystemFieldKey.title] = "Sertifisering firmadata" as CKRecordValue
                share.publicPermission = .none

                let operation = CKModifyRecordsOperation(recordsToSave: [rootRecord, share], recordIDsToDelete: nil)
                operation.modifyRecordsResultBlock = { result in
                    switch result {
                    case .success:
                        completion(.success(share))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
                database.add(operation)
            }
        }
    }

    private static func ensureZoneExists(
        zoneID: CKRecordZone.ID,
        database: CKDatabase,
        completion: @escaping (Error?) -> Void
    ) {
        database.fetch(withRecordZoneID: zoneID) { _, fetchError in
            if fetchError == nil {
                completion(nil)
                return
            }

            let zone = CKRecordZone(zoneID: zoneID)
            database.save(zone) { _, saveError in
                if let ckError = saveError as? CKError, ckError.code == .serverRecordChanged {
                    completion(nil)
                    return
                }
                completion(saveError)
            }
        }
    }

    private static func fetchOrCreateCompanyRoot(
        recordID: CKRecord.ID,
        database: CKDatabase,
        completion: @escaping (CKRecord?, Error?) -> Void
    ) {
        database.fetch(withRecordID: recordID) { record, error in
            if let record {
                completion(record, nil)
                return
            }

            if let ckError = error as? CKError, ckError.code != .unknownItem {
                completion(nil, ckError)
                return
            }

            let record = CKRecord(recordType: "CompanyDataset", recordID: recordID)
            record["title"] = "Sertifisering firmadata" as CKRecordValue
            record["createdAt"] = Date() as CKRecordValue
            completion(record, nil)
        }
    }

    static func cloudKitModifyBatchSizes(recordCount: Int) -> [Int] {
        guard recordCount > 0 else {
            return []
        }

        var sizes: [Int] = []
        var remainingCount = recordCount

        while remainingCount > 0 {
            let batchSize = min(modifyRecordsBatchLimit, remainingCount)
            sizes.append(batchSize)
            remainingCount -= batchSize
        }

        return sizes
    }

    private static func saveRecordsInBatches(
        _ records: [CKRecord],
        database: CKDatabase,
        completion: @escaping (Result<Int, Error>) -> Void
    ) {
        let batches = recordBatches(from: records)
        saveRecordBatch(at: 0, batches: batches, database: database, savedCount: 0, completion: completion)
    }

    private static func saveRecordBatch(
        at index: Int,
        batches: [[CKRecord]],
        database: CKDatabase,
        savedCount: Int,
        completion: @escaping (Result<Int, Error>) -> Void
    ) {
        guard index < batches.count else {
            completion(.success(savedCount))
            return
        }

        let batch = batches[index]
        let operation = CKModifyRecordsOperation(recordsToSave: batch, recordIDsToDelete: nil)
        operation.savePolicy = .allKeys
        operation.modifyRecordsResultBlock = { result in
            switch result {
            case .success:
                saveRecordBatch(
                    at: index + 1,
                    batches: batches,
                    database: database,
                    savedCount: savedCount + batch.count,
                    completion: completion
                )
            case .failure(let error):
                completion(.failure(error))
            }
        }
        database.add(operation)
    }

    private static func recordBatches(from records: [CKRecord]) -> [[CKRecord]] {
        var startIndex = records.startIndex

        return cloudKitModifyBatchSizes(recordCount: records.count).map { batchSize in
            let endIndex = records.index(startIndex, offsetBy: batchSize)
            let batch = Array(records[startIndex..<endIndex])
            startIndex = endIndex
            return batch
        }
    }

    private static func makeCompanyRecords(
        rootRecord: CKRecord,
        inspections: [Inspection],
        zoneID: CKRecordZone.ID
    ) -> [CKRecord] {
        rootRecord["title"] = "Sertifisering firmadata" as CKRecordValue
        rootRecord["updatedAt"] = Date() as CKRecordValue
        rootRecord["inspectionCount"] = inspections.count as CKRecordValue

        var records: [CKRecord] = [rootRecord]

        for inspection in inspections {
            let inspectionRecordID = CKRecord.ID(
                recordName: "inspection-\(inspection.id.uuidString)",
                zoneID: zoneID
            )
            let inspectionRecord = CKRecord(recordType: "InspectionRecord", recordID: inspectionRecordID)
            inspectionRecord.parent = CKRecord.Reference(recordID: rootRecord.recordID, action: .none)
            inspectionRecord["id"] = inspection.id.uuidString as CKRecordValue
            inspectionRecord["createdAt"] = inspection.createdAt as CKRecordValue
            inspectionRecord["updatedAt"] = inspection.updatedAt as CKRecordValue
            setOptionalDate(inspection.completedAt, forKey: "completedAt", on: inspectionRecord)
            setOptionalDate(inspection.processedAt, forKey: "processedAt", on: inspectionRecord)
            setOptionalDate(inspection.invoicedAt, forKey: "invoicedAt", on: inspectionRecord)
            inspectionRecord["certificateNumber"] = inspection.certificateNumber as CKRecordValue
            inspectionRecord["companyOwner"] = inspection.companyOwner as CKRecordValue
            inspectionRecord["contactPerson"] = inspection.contactPerson as CKRecordValue
            inspectionRecord["phone"] = inspection.phone as CKRecordValue
            inspectionRecord["address"] = inspection.address as CKRecordValue
            inspectionRecord["inspector"] = inspection.inspector as CKRecordValue
            inspectionRecord["location"] = inspection.location as CKRecordValue
            inspectionRecord["projectNumber"] = inspection.projectNumber as CKRecordValue
            inspectionRecord["overallNotes"] = inspection.overallNotes as CKRecordValue
            inspectionRecord["signatureCustomerName"] = inspection.signatureCustomerName as CKRecordValue
            inspectionRecord["signatureInspectorName"] = inspection.signatureInspectorName as CKRecordValue
            inspectionRecord["attachmentsCount"] = inspection.attachmentsCount as CKRecordValue
            inspectionRecord["statusRawValue"] = inspection.statusRawValue as CKRecordValue
            inspectionRecord["workflowStatusRawValue"] = inspection.workflowStatusRawValue as CKRecordValue
            inspectionRecord["customerSignatureData"] = inspection.customerSignatureData as CKRecordValue
            inspectionRecord["inspectorSignatureData"] = inspection.inspectorSignatureData as CKRecordValue
            records.append(inspectionRecord)

            for machine in inspection.machines ?? [] {
                let machineRecordID = CKRecord.ID(
                    recordName: "machine-\(machine.id.uuidString)",
                    zoneID: zoneID
                )
                let machineRecord = CKRecord(recordType: "MachineRecord", recordID: machineRecordID)
                machineRecord.parent = CKRecord.Reference(recordID: inspectionRecordID, action: .none)
                machineRecord["id"] = machine.id.uuidString as CKRecordValue
                machineRecord["inspectionID"] = inspection.id.uuidString as CKRecordValue
                machineRecord["createdAt"] = machine.createdAt as CKRecordValue
                machineRecord["updatedAt"] = machine.updatedAt as CKRecordValue
                machineRecord["name"] = machine.name as CKRecordValue
                machineRecord["categoryRawValue"] = machine.categoryRawValue as CKRecordValue
                machineRecord["machineType"] = machine.machineType as CKRecordValue
                machineRecord["serialNumber"] = machine.serialNumber as CKRecordValue
                machineRecord["annualControl"] = machine.annualControl as CKRecordValue
                machineRecord["fullService"] = machine.fullService as CKRecordValue
                machineRecord["manufacturer"] = machine.manufacturer as CKRecordValue
                machineRecord["hoistType"] = machine.hoistType as CKRecordValue
                machineRecord["craneNumber"] = machine.craneNumber as CKRecordValue
                machineRecord["hoistNumber"] = machine.hoistNumber as CKRecordValue
                machineRecord["internalLocation"] = machine.internalLocation as CKRecordValue
                machineRecord["hourMeter"] = machine.hourMeter as CKRecordValue
                machineRecord["loadIndicator"] = machine.loadIndicator as CKRecordValue
                machineRecord["certificateNumber"] = machine.certificateNumber as CKRecordValue
                machineRecord["notes"] = machine.notes as CKRecordValue
                machineRecord["looseObjectsFound"] = machine.looseObjectsFound as CKRecordValue
                machineRecord["looseObjectsRemoved"] = machine.looseObjectsRemoved as CKRecordValue
                machineRecord["remainingLifetimeDocumented"] = machine.remainingLifetimeDocumented as CKRecordValue
                machineRecord["remainingLifetimeSWP"] = machine.remainingLifetimeSWP as CKRecordValue
                machineRecord["usageCertificateValid"] = machine.usageCertificateValid as CKRecordValue
                records.append(machineRecord)

                for item in machine.checklistItems ?? [] {
                    let itemRecordID = CKRecord.ID(
                        recordName: "checklist-\(item.id.uuidString)",
                        zoneID: zoneID
                    )
                    let itemRecord = CKRecord(recordType: "ChecklistItemRecord", recordID: itemRecordID)
                    itemRecord.parent = CKRecord.Reference(recordID: machineRecordID, action: .none)
                    itemRecord["id"] = item.id.uuidString as CKRecordValue
                    itemRecord["machineID"] = machine.id.uuidString as CKRecordValue
                    itemRecord["updatedAt"] = item.updatedAt as CKRecordValue
                    itemRecord["sectionOrder"] = item.sectionOrder as CKRecordValue
                    itemRecord["sectionTitle"] = item.sectionTitle as CKRecordValue
                    itemRecord["itemOrder"] = item.itemOrder as CKRecordValue
                    itemRecord["code"] = item.code as CKRecordValue
                    itemRecord["title"] = item.title as CKRecordValue
                    itemRecord["resultRawValue"] = item.resultRawValue as CKRecordValue
                    itemRecord["note"] = item.note as CKRecordValue
                    records.append(itemRecord)
                }
            }
        }

        return records
    }

    private static func setOptionalDate(_ date: Date?, forKey key: String, on record: CKRecord) {
        if let date {
            record[key] = date as CKRecordValue
        }
    }

    private static func fetchSharedZoneIDs(
        database: CKDatabase,
        completion: @escaping (Result<[CKRecordZone.ID], Error>) -> Void
    ) {
        var zoneIDs: [CKRecordZone.ID] = []
        let operation = CKFetchDatabaseChangesOperation(previousServerChangeToken: nil)
        operation.recordZoneWithIDChangedBlock = { zoneID in
            zoneIDs.append(zoneID)
        }
        operation.fetchDatabaseChangesResultBlock = { result in
            switch result {
            case .success:
                completion(.success(zoneIDs))
            case .failure(let error):
                completion(.failure(error))
            }
        }
        database.add(operation)
    }

    private static func fetchSharedRecords(
        zoneIDs: [CKRecordZone.ID],
        database: CKDatabase,
        completion: @escaping (Result<[CKRecord], Error>) -> Void
    ) {
        let lock = NSLock()
        var records: [CKRecord] = []
        var firstError: Error?

        let configurations = Dictionary(uniqueKeysWithValues: zoneIDs.map { zoneID in
            (
                zoneID,
                CKFetchRecordZoneChangesOperation.ZoneConfiguration(
                    previousServerChangeToken: nil,
                    resultsLimit: nil,
                    desiredKeys: nil
                )
            )
        })
        let operation = CKFetchRecordZoneChangesOperation(
            recordZoneIDs: zoneIDs,
            configurationsByRecordZoneID: configurations
        )
        operation.fetchAllChanges = true
        operation.recordWasChangedBlock = { _, result in
            switch result {
            case .success(let record):
                lock.lock()
                records.append(record)
                lock.unlock()
            case .failure(let error):
                lock.lock()
                firstError = firstError ?? error
                lock.unlock()
            }
        }
        operation.recordZoneFetchResultBlock = { _, result in
            if case .failure(let error) = result {
                lock.lock()
                firstError = firstError ?? error
                lock.unlock()
            }
        }
        operation.fetchRecordZoneChangesResultBlock = { result in
            if case .failure(let error) = result {
                firstError = firstError ?? error
            }

            if let firstError {
                completion(.failure(firstError))
            } else {
                completion(.success(records))
            }
        }
        database.add(operation)
    }

    private static func fetchSharedCompanyRoot(
        database: CKDatabase,
        completion: @escaping (Result<CKRecord, Error>) -> Void
    ) {
        fetchSharedZoneIDs(database: database) { zoneResult in
            switch zoneResult {
            case .failure(let error):
                completion(.failure(error))
            case .success(let zoneIDs):
                guard !zoneIDs.isEmpty else {
                    completion(.failure(CloudKitSharingError.noSharedCompanyData))
                    return
                }

                fetchSharedRecords(zoneIDs: zoneIDs, database: database) { recordResult in
                    switch recordResult {
                    case .failure(let error):
                        completion(.failure(error))
                    case .success(let records):
                        guard let rootRecord = records.first(where: {
                            $0.recordType == "CompanyDataset" &&
                            $0.recordID.recordName == companyRootRecordName
                        }) else {
                            completion(.failure(CloudKitSharingError.noSharedCompanyData))
                            return
                        }

                        completion(.success(rootRecord))
                    }
                }
            }
        }
    }

    private static func makeInspections(
        inspectionRecords: [CKRecord],
        machineRecords: [CKRecord],
        itemRecords: [CKRecord]
    ) -> [Inspection] {
        let itemsByMachineID = Dictionary(grouping: itemRecords) { record in
            stringValue("machineID", in: record)
        }
        let machinesByInspectionID = Dictionary(grouping: machineRecords) { record in
            stringValue("inspectionID", in: record)
        }

        return inspectionRecords.compactMap { record in
            guard let id = uuidValue("id", in: record) else {
                return nil
            }

            let inspection = Inspection(
                id: id,
                createdAt: dateValue("createdAt", in: record) ?? .now,
                updatedAt: dateValue("updatedAt", in: record) ?? .now,
                completedAt: dateValue("completedAt", in: record),
                processedAt: dateValue("processedAt", in: record),
                invoicedAt: dateValue("invoicedAt", in: record),
                certificateNumber: stringValue("certificateNumber", in: record),
                companyOwner: stringValue("companyOwner", in: record),
                contactPerson: stringValue("contactPerson", in: record),
                phone: stringValue("phone", in: record),
                address: stringValue("address", in: record),
                inspector: stringValue("inspector", in: record),
                location: stringValue("location", in: record),
                projectNumber: stringValue("projectNumber", in: record),
                overallNotes: stringValue("overallNotes", in: record),
                signatureCustomerName: stringValue("signatureCustomerName", in: record),
                signatureInspectorName: stringValue("signatureInspectorName", in: record),
                attachmentsCount: stringValue("attachmentsCount", in: record),
                customerSignatureData: dataValue("customerSignatureData", in: record),
                inspectorSignatureData: dataValue("inspectorSignatureData", in: record),
                status: InspectionStatus(rawValue: stringValue("statusRawValue", in: record)) ?? .approved,
                workflowStatus: InspectionWorkflowStatus(rawValue: stringValue("workflowStatusRawValue", in: record)) ?? .draft
            )

            inspection.machines = (machinesByInspectionID[id.uuidString] ?? []).compactMap { machineRecord in
                makeMachine(from: machineRecord, itemRecords: itemsByMachineID)
            }
            return inspection
        }
    }

    private static func makeMachine(
        from record: CKRecord,
        itemRecords: [String: [CKRecord]]
    ) -> Machine? {
        guard let id = uuidValue("id", in: record) else {
            return nil
        }

        let machine = Machine(
            id: id,
            createdAt: dateValue("createdAt", in: record) ?? .now,
            updatedAt: dateValue("updatedAt", in: record) ?? .now,
            name: stringValue("name", in: record),
            category: MachineCategory(rawValue: stringValue("categoryRawValue", in: record)) ?? .crane,
            machineType: stringValue("machineType", in: record),
            serialNumber: stringValue("serialNumber", in: record),
            annualControl: boolValue("annualControl", in: record),
            fullService: boolValue("fullService", in: record),
            manufacturer: stringValue("manufacturer", in: record),
            hoistType: stringValue("hoistType", in: record),
            craneNumber: stringValue("craneNumber", in: record),
            hoistNumber: stringValue("hoistNumber", in: record),
            internalLocation: stringValue("internalLocation", in: record),
            hourMeter: stringValue("hourMeter", in: record),
            loadIndicator: stringValue("loadIndicator", in: record),
            certificateNumber: stringValue("certificateNumber", in: record),
            notes: stringValue("notes", in: record),
            looseObjectsFound: boolValue("looseObjectsFound", in: record),
            looseObjectsRemoved: boolValue("looseObjectsRemoved", in: record),
            remainingLifetimeDocumented: boolValue("remainingLifetimeDocumented", in: record),
            remainingLifetimeSWP: stringValue("remainingLifetimeSWP", in: record),
            usageCertificateValid: boolValue("usageCertificateValid", in: record)
        )

        machine.checklistItems = (itemRecords[id.uuidString] ?? []).compactMap { makeChecklistItem(from: $0) }
        return machine
    }

    private static func makeChecklistItem(from record: CKRecord) -> MachineChecklistItem? {
        guard let id = uuidValue("id", in: record) else {
            return nil
        }

        return MachineChecklistItem(
            id: id,
            updatedAt: dateValue("updatedAt", in: record) ?? .now,
            sectionOrder: intValue("sectionOrder", in: record),
            sectionTitle: stringValue("sectionTitle", in: record),
            itemOrder: intValue("itemOrder", in: record),
            code: stringValue("code", in: record),
            title: stringValue("title", in: record),
            result: ChecklistResult(rawValue: stringValue("resultRawValue", in: record)) ?? .ok,
            note: stringValue("note", in: record)
        )
    }

    private static func stringValue(_ key: String, in record: CKRecord) -> String {
        record[key] as? String ?? ""
    }

    private static func uuidValue(_ key: String, in record: CKRecord) -> UUID? {
        UUID(uuidString: stringValue(key, in: record))
    }

    private static func dateValue(_ key: String, in record: CKRecord) -> Date? {
        record[key] as? Date
    }

    private static func dataValue(_ key: String, in record: CKRecord) -> Data {
        record[key] as? Data ?? Data()
    }

    private static func boolValue(_ key: String, in record: CKRecord) -> Bool {
        record[key] as? Bool ?? false
    }

    private static func intValue(_ key: String, in record: CKRecord) -> Int {
        record[key] as? Int ?? 0
    }
}

enum CloudKitSharingError: LocalizedError {
    case missingRootRecord
    case missingShareRecord
    case noSharedCompanyData

    var errorDescription: String? {
        switch self {
        case .missingRootRecord:
            return "Mangler CloudKit-rotpost for firmadata."
        case .missingShareRecord:
            return "Fant ikke eksisterende CloudKit-deling for firmadata."
        case .noSharedCompanyData:
            return "Fant ingen delt CloudKit-sone for firmadata."
        }
    }
}

final class CloudKitSharingAppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        let configuration = UISceneConfiguration(
            name: connectingSceneSession.configuration.name,
            sessionRole: connectingSceneSession.role
        )
        configuration.delegateClass = CloudKitSharingSceneDelegate.self
        return configuration
    }

    func application(
        _ application: UIApplication,
        userDidAcceptCloudKitShareWith cloudKitShareMetadata: CKShare.Metadata
    ) {
        Task {
            let message = await CloudKitSharingSupport.acceptShare(metadata: cloudKitShareMetadata)
            print(message)
        }
    }
}

final class CloudKitSharingSceneDelegate: NSObject, UIWindowSceneDelegate {
    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        if let metadata = connectionOptions.cloudKitShareMetadata {
            accept(metadata)
        }
    }

    func windowScene(
        _ windowScene: UIWindowScene,
        userDidAcceptCloudKitShareWith cloudKitShareMetadata: CKShare.Metadata
    ) {
        accept(cloudKitShareMetadata)
    }

    private func accept(_ metadata: CKShare.Metadata) {
        Task {
            let message = await CloudKitSharingSupport.acceptShare(metadata: metadata)
            print(message)
        }
    }
}
