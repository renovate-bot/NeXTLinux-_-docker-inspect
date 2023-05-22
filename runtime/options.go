package runtime

import (
	"github.com/spf13/viper"
	"github.com/nextlinux/docker-inspect/docker-inspect"
)

type Options struct {
	Ci           bool
	Image        string
	Source       dinspectImage.ImageSource
	IgnoreErrors bool
	ExportFile   string
	CiConfig     *viper.Viper
	BuildArgs    []string
}
