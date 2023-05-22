package runtime

import (
	"github.com/nextlinux/docker-inspect/docker-inspect"
	"github.com/spf13/viper"
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
