/// Reproducible source identity for Reach's immutable SwiftTerm fork.
///
/// Upstream 1.19 generates this value through a build-tool plug-in. Xcode
/// requires each developer to approve that executable before resolving a
/// package, which makes an otherwise source-only library interactive and
/// breaks unattended app builds. Reach instead binds the same XT_VERSION
/// identity to its exact semantic-version tag at source time.
public enum SwiftTermBuildInfo {
    public static let branch: String? = nil
    public static let tag: String? = "v1.19.0-reach.3"
    public static let commit: String? = nil
    public static let hasUncommittedChanges: Bool? = nil
    public static let version = "v1.19.0-reach.3"
}
