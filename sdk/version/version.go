package version

import (
	"bytes"
	"fmt"
)

// VersionInfo
type VersionInfo struct {
	Revision  string `json:"revision,omitempty"`
	Version   string `json:"version,omitempty"`
	BuildDate string `json:"build_date,omitempty"`
}

func GetVersion() *VersionInfo {
	ver := Version
	if GitDescribe != "" {
		ver = GitDescribe
	}

	return &VersionInfo{
		Revision:  GitCommit,
		Version:   ver,
		BuildDate: BuildDate,
	}
}

func (c *VersionInfo) VersionNumber() string {

	version := c.Version

	return version
}

func (c *VersionInfo) FullVersionNumber(rev bool) string {
	var versionString bytes.Buffer

	fmt.Fprintf(&versionString, "Vault v%s", c.Version)
	if rev && c.Revision != "" {
		fmt.Fprintf(&versionString, " (%s)", c.Revision)
	}

	if c.BuildDate != "" {
		fmt.Fprintf(&versionString, ", built %s", c.BuildDate)
	}

	return versionString.String()
}
