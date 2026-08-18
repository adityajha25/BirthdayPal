//
//  AppleIntelligence.swift
//  Birthday
//

import Foundation
import FoundationModels

/// Why the on-device model can or cannot be used right now.
enum AppleIntelligenceStatus: Equatable {
    case available

    /// Running below iOS 26, so Foundation Models does not exist.
    case unsupportedOS

    /// Hardware cannot run Apple Intelligence. Nothing the user can do.
    case deviceNotEligible

    /// Eligible hardware, but the user has not switched Apple Intelligence on.
    case notEnabled

    /// Enabled, but the model is still downloading or initializing.
    case modelNotReady

    case unknown

    /// The only state worth prompting about: the device supports Apple
    /// Intelligence and the user just has not turned it on yet.
    var canBeFixedInSettings: Bool {
        self == .notEnabled
    }

    var logDescription: String {
        switch self {
        case .available:
            return "Foundation Models available; using the on-device model."
        case .unsupportedOS:
            return "Foundation Models unavailable: running below iOS 26."
        case .deviceNotEligible:
            return "Foundation Models unavailable: device is not eligible for Apple Intelligence."
        case .notEnabled:
            return "Foundation Models unavailable: Apple Intelligence is not enabled in Settings."
        case .modelNotReady:
            return "Foundation Models unavailable: the model is still downloading or initializing."
        case .unknown:
            return "Foundation Models unavailable: unrecognized availability state."
        }
    }
}

enum AppleIntelligence {

    /// Single place that maps `SystemLanguageModel.availability` to our status.
    static var status: AppleIntelligenceStatus {
        guard #available(iOS 26.0, *) else {
            return .unsupportedOS
        }

        switch SystemLanguageModel.default.availability {
        case .available:
            return .available

        case .unavailable(let reason):
            switch reason {
            case .deviceNotEligible:
                return .deviceNotEligible

            case .appleIntelligenceNotEnabled:
                return .notEnabled

            case .modelNotReady:
                return .modelNotReady

            @unknown default:
                return .unknown
            }

        @unknown default:
            return .unknown
        }
    }
}
