package view

import "github.com/nextlinux/docker-inspect/runtime/ui/viewmodel"

type LayerChangeListener func(viewmodel.LayerSelection) error
