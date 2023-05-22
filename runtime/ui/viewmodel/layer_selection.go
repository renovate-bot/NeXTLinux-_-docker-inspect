package viewmodel

import (
	"github.com/nextlinux/docker-inspect/docker-inspect/image"
)

type LayerSelection struct {
	Layer                                                      *image.Layer
	BottomTreeStart, BottomTreeStop, TopTreeStart, TopTreeStop int
}
