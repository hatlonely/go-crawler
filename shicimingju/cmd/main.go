package main

import (
	"fmt"

	"github.com/hatlonely/go-kit/binding"
	"github.com/hatlonely/go-kit/config"
	"github.com/hatlonely/go-kit/flag"
	"github.com/hatlonely/go-kit/strex"

	"github.com/hatlonely/go-crawler/shicimingju/internal/shicimingju"
)

var Version string

type Options struct {
	flag.Options
	Book  shicimingju.BookOptions
	ShiCi shicimingju.ShiCiOptions
}

func Must(err error) {
	if err != nil {
		panic(err)
	}
}

func main() {
	var options Options
	Must(flag.Struct(&options))
	Must(flag.Parse())
	if options.Help {
		fmt.Println(flag.Usage())
		return
	}
	if options.Version {
		fmt.Println(Version)
		return
	}
	var cfg *config.Config
	if options.ConfigPath != "" {
		var err error
		cfg, err = config.NewSimpleFileConfig(options.ConfigPath)
		if err != nil {
			panic(err)
		}
	}

	Must(binding.Bind(&options, flag.Instance(), binding.NewEnvGetter(), cfg))
	fmt.Println(strex.MustJsonMarshal(options))

	Must(shicimingju.NewBookAnalystWithOptions(&options.Book).AnalystAndSaveResult())
	Must(shicimingju.NewShiCiAnalystWithOptions(&options.ShiCi).AnalystAndSaveResult())
}
