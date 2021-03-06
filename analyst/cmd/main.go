package main

import (
	"fmt"

	"github.com/hatlonely/go-kit/binding"
	"github.com/hatlonely/go-kit/config"
	"github.com/hatlonely/go-kit/flag"
	"github.com/hatlonely/go-kit/logger"
	"github.com/hatlonely/go-kit/strx"

	"github.com/hatlonely/go-crawler/analyst/internal/shicimingju"
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
	if options.ConfigPath == "" {
		options.ConfigPath = "config/go-crawler-analyst.json"
	}
	cfg, err := config.NewSimpleFileConfig(options.ConfigPath)
	if err != nil {
		panic(err)
	}

	Must(binding.Bind(&options, flag.Instance(), binding.NewEnvGetter(), cfg))

	log := logger.NewLogger(logger.LevelInfo, logger.NewStdoutWriter())
	log.Info(strx.JsonMarshal(options))

	Must(shicimingju.NewBookAnalystWithOptions(&options.Book).AnalystAndSaveResult())
	Must(shicimingju.NewShiCiAnalystWithOptions(&options.ShiCi).AnalystAndSaveResult())
}
