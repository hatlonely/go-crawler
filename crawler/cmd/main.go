package main

import (
	"fmt"
	"os"
	"path/filepath"
	"time"

	"github.com/gocolly/colly/v2"
	"github.com/hatlonely/go-kit/binding"
	"github.com/hatlonely/go-kit/config"
	"github.com/hatlonely/go-kit/flag"
)

var Version string

type Options struct {
	Directory    string `dft:"data"`
	Parallel     int    `dft:"100"`
	MaxDepth     int    `dft:"4"`
	Delay        time.Duration
	AllowDomains []string
	UserAgent    string
	StartPage    string
}

func main() {
	var options Options
	help := flag.Bool("help", false, "show help info")
	version := flag.Bool("version", false, "show version")
	configPath := flag.String("configPath", "config/crrawler.json", "config path")
	if *help {
		fmt.Println(flag.Usage())
		return
	}
	if *version {
		fmt.Println(Version)
		return
	}
	if err := flag.Struct(&options); err != nil {
		panic(err)
	}
	if err := flag.Parse(); err != nil {
		panic(err)
	}
	var cfg *config.Config
	if *configPath != "" {
		var err error
		cfg, err = config.NewSimpleFileConfig(*configPath)
		if err != nil {
			panic(err)
		}
	}
	if err := binding.Bind(&options, flag.Instance(), binding.NewEnvGetter(), cfg); err != nil {
		panic(err)
	}

	c := colly.NewCollector(
		//colly.Async(),
		colly.UserAgent(options.UserAgent),
		colly.MaxDepth(options.MaxDepth),
		colly.AllowedDomains(options.AllowDomains...),
	)

	c.Limit(&colly.LimitRule{
		DomainGlob:  `*.shicimingju.*`,
		Parallelism: options.Parallel,
		Delay:       options.Delay,
	})

	c.OnHTML("a[href]", func(e *colly.HTMLElement) {
		href := e.Attr("href")
		_, err := os.Stat(options.Directory + href)
		if os.IsExist(err) {
			return
		}
		if err := e.Request.Visit(href); err == colly.ErrMaxDepth || err == colly.ErrAlreadyVisited || err == colly.ErrForbiddenDomain {
		} else if err != nil {
			fmt.Println(err)
		}
	})

	c.OnRequest(func(req *colly.Request) {
		fmt.Println("Visiting", req.URL, req.ID, req.Depth)
	})

	c.OnError(func(r *colly.Response, err error) {
		fmt.Println("Request URL:", r.Request.URL, "failed with response:", r, "\nError:", err)
	})

	c.OnResponse(func(res *colly.Response) {
		fmt.Println("Visited", res.Request.URL, res.Request.ID, res.Request.Depth)
		path := fmt.Sprintf("%v/%v", options.Directory, res.Request.URL.Path)
		dir := filepath.Dir(path)
		if err := os.MkdirAll(dir, 0755); err != nil {
			fmt.Println(err)
			return
		}
		fp, err := os.Create(path)
		if err != nil {
			fmt.Println(err)
			return
		}
		if _, err := fp.Write(res.Body); err != nil {
			fmt.Println(err)
			return
		}
		_ = fp.Close()
	})

	c.Visit(options.StartPage)
	//c.Visit("https://www.shicimingju.com/book/sanguoyanyi.html")
	//c.Visit("https://www.shicimingju.com/book/sanguoyanyi/1.html")

	c.Wait()
}
