package version

var (
	// The git commit that was compiled. This will be filled in by the compiler.
	GitCommit   string
	GitDescribe string

	// The compilation date. This will be filled in by the compiler.
	BuildDate string

	// Whether cgo is enabled or not; set at build time
	CgoEnabled bool

	// Default values - used when building locally
	Version           = "0.0.0"
	VersionPrerelease = "dev"
	VersionMetadata   = ""
)
