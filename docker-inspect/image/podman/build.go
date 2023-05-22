//go:build linux
// +build linux

package podman

import (
	"io/ioutil"
	"os"
)

func buildImageFromCli(buildArgs []string) (string, error) {
	iidfile, err := ioutil.TempFile("/tmp", "docker-inspect.*.iid")
	if err != nil {
		return "", err
	}
	defer os.Remove(iidfile.Name())

	allArgs := append([]string{"--iidfile", iidfile.Name()}, buildArgs...)
	err = runPodmanCmd("build", allArgs...)
	if err != nil {
		return "", err
	}

	imageId, err := ioutil.ReadFile(iidfile.Name())
	if err != nil {
		return "", err
	}

	return string(imageId), nil
}
