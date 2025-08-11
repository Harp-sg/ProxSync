import Foundation
import HealthKit
import ProxSyncCore

@MainActor
public final class HealthWriter {
    public static let shared = HealthWriter()
    private init() {}

    public let store = HKHealthStore()

    public func requestAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else { completion(false, nil); return }
        var toWrite: Set<HKSampleType> = [HKObjectType.workoutType()]
        if let h = HKObjectType.categoryType(forIdentifier: .headache) { toWrite.insert(h) }
        if let d = HKObjectType.categoryType(forIdentifier: .dizziness) { toWrite.insert(d) }
        if let n = HKObjectType.categoryType(forIdentifier: .nausea) { toWrite.insert(n) }
        store.requestAuthorization(toShare: toWrite, read: []) { ok, err in
            completion(ok, err)
        }
    }

    public func saveWorkoutAndSymptoms(
        start: Date, end: Date,
        externalID: String,
        metrics: [String: Double],
        symptoms: [(type: String, severity: String)],
        completion: @escaping (Bool, Error?) -> Void
    ) {
        var metadata: [String: Any] = [HKMetadataKeyExternalUUID: externalID]
        metrics.forEach { metadata["metric_\($0.key)"] = $0.value }

        let workout = HKWorkout(
            activityType: .other, start: start, end: end,
            workoutEvents: nil, totalEnergyBurned: nil, totalDistance: nil,
            device: .local(), metadata: metadata
        )

        var samples: [HKSample] = []
        for s in symptoms {
            let sev: HKCategoryValueSeverity =
                (s.severity.lowercased() == "mild") ? .mild :
                (s.severity.lowercased() == "severe") ? .severe : .moderate

            let id: HKCategoryTypeIdentifier? = {
                switch s.type.lowercased() {
                case "headache": return .headache
                case "dizziness": return .dizziness
                case "nausea":    return .nausea
                default:          return nil
                }
            }()

            if let id, let type = HKObjectType.categoryType(forIdentifier: id) {
                samples.append(
                    HKCategorySample(
                        type: type, value: sev.rawValue,
                        start: start, end: end,
                        metadata: [HKMetadataKeyExternalUUID: externalID]
                    )
                )
            }
        }

        store.save(workout) { [weak self] ok, err in
            guard ok, err == nil, let self else { completion(ok, err); return }
            guard !samples.isEmpty else { completion(true, nil); return }
            self.store.add(samples, to: workout) { ok2, err2 in completion(ok2, err2) }
        }
    }
}
