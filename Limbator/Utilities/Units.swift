import Foundation

/// Les unités qui s'écrivent différemment selon la langue de l'interface.
///
/// Le français abrège l'octet en « o » — 12 Mo, 3 Go ; le roumain et l'anglais
/// écrivent « B » — 12 MB, 3 GB. Une seule forme pour les trois affichait une
/// unité étrangère à deux lecteurs sur trois, dans le bandeau de
/// téléchargement comme dans les réglages.
enum Units {

    /// « Mo » ou « MB », selon la langue affichée.
    static var megabyte: String { L.lang == "fr" ? "Mo" : "MB" }

    /// Une taille en mégaoctets, arrondie, avec son unité.
    static func megabytes(_ bytes: Int64) -> String {
        String(format: "%.0f", Double(bytes) / 1_048_576) + " " + megabyte
    }

    /// Un débit, avec l'unité par seconde.
    static func megabytesPerSecond(_ bytes: Int64) -> String {
        String(format: "%.1f", Double(bytes) / 1_048_576) + " " + megabyte + "/s"
    }
}
