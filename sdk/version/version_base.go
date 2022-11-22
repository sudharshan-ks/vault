package version

import (
	"io"
	"os"
	"strings"
)

var (
	// The git commit that was compiled. This will be filled in by the compiler.
	GitCommit   string
	GitDescribe string

	// The compilation date. This will be filled in by the compiler.
	BuildDate string

	// Whether cgo is enabled or not; set at build time
	CgoEnabled bool

	Version = ReadVersion()
)

func ReadVersion() string {
	f, err := os.Open("../../.release/VERSION")
	if err != nil {
		panic(err)
	}
	defer f.Close()
	b := new(strings.Builder)
	io.Copy(b, f)
	return b.String()
}
