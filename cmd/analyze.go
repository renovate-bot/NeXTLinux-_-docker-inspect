package cmd

import (
	"fmt"
	"github.com/nextlinux/docker-inspect/docker-inspect"
	"github.com/sirupsen/logrus"
	"github.com/spf13/viper"
	"os"

	"github.com/nextlinux/docker-inspect/runtime"
	"github.com/spf13/cobra"
)

// doAnalyzeCmd takes a docker image tag, digest, or id and displays the
// image analysis to the screen
func doAnalyzeCmd(cmd *cobra.Command, args []string) {

	if len(args) == 0 {
		printVersionFlag, err := cmd.PersistentFlags().GetBool("version")
		if err == nil && printVersionFlag {
			printVersion(cmd, args)
			return
		}

		fmt.Println("No image argument given")
		os.Exit(1)
	}

	userImage := args[0]
	if userImage == "" {
		fmt.Println("No image argument given")
		os.Exit(1)
	}

	initLogging()

	isCi, ciConfig, err := configureCi()

	if err != nil {
		fmt.Printf("ci configuration error: %v\n", err)
		os.Exit(1)
	}

	var sourceType dinspectImage.ImageSource
	var imageStr string

	sourceType, imageStr = dinspectImage.DeriveImageSource(userImage)

	if sourceType == dinspectImage.SourceUnknown {
		sourceStr := viper.GetString("source")
		sourceType = dinspectImage.ParseImageSource(sourceStr)
		if sourceType == dinspectImage.SourceUnknown {
			fmt.Printf("unable to determine image source: %v\n", sourceStr)
			os.Exit(1)
		}

		imageStr = userImage
	}

	ignoreErrors, err := cmd.PersistentFlags().GetBool("ignore-errors")
	if err != nil {
		logrus.Error("unable to get 'ignore-errors' option:", err)
	}

	runtime.Run(runtime.Options{
		Ci:           isCi,
		Source:       sourceType,
		Image:        imageStr,
		ExportFile:   exportFile,
		CiConfig:     ciConfig,
		IgnoreErrors: viper.GetBool("ignore-errors") || ignoreErrors,
	})
}
