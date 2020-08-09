package shicimingju

import (
	"bufio"
	"bytes"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"os"
	"strings"

	"github.com/PuerkitoBio/goquery"
)

type ShiCiOptions struct {
	Root string
	Out  string
}

func NewShiCiAnalystWithOptions(options *ShiCiOptions) *ShiCiAnalyst {
	return NewShiCiAnalyst(options.Root, options.Out)
}

func NewShiCiAnalyst(root string, out string) *ShiCiAnalyst {
	return &ShiCiAnalyst{
		Root: root,
		Out:  out,
	}
}

type ShiCiAnalyst struct {
	Root string
	Out  string
}

type ShiCi struct {
	Source        string
	Title         string
	Author        string
	Dynasty       string
	Content       string
	DynastyAuthor string
}

func (a *ShiCiAnalyst) AnalystAndSaveResult() error {
	fp, err := os.Create(a.Out)
	if err != nil {
		return err
	}
	w := bufio.NewWriter(fp)

	vs, err := a.Analyst()
	if err != nil {
		return err
	}
	for _, v := range vs {
		buf, _ := json.Marshal(v)
		_, _ = w.Write(buf)
		_, _ = w.WriteString("\n")
	}
	_ = w.Flush()
	return nil
}

func (a *ShiCiAnalyst) Analyst() ([]*ShiCi, error) {
	infos, err := ioutil.ReadDir(fmt.Sprintf("%v/chaxun/list/", a.Root))
	if err != nil {
		return nil, err
	}

	var shiCis []*ShiCi
	for _, info := range infos {
		if info.IsDir() {
			continue
		}
		shiCi, err := a.AnalystShiCi(info.Name())
		if err != nil {
			return nil, err
		}
		shiCis = append(shiCis, shiCi)
	}

	return shiCis, nil
}

func (a *ShiCiAnalyst) AnalystShiCi(source string) (*ShiCi, error) {
	fp, err := os.Open(fmt.Sprintf("%v/chaxun/list/%v", a.Root, source))
	if err != nil {
		return nil, err
	}
	doc, err := goquery.NewDocumentFromReader(bufio.NewReader(fp))
	if err != nil {
		return nil, err
	}

	buf := bytes.Buffer{}
	doc.Find("#zs_content").Each(func(i int, s *goquery.Selection) {
		s.Contents().Each(func(i int, s *goquery.Selection) {
			text := strings.TrimSpace(s.Text())
			buf.WriteString(text)
			if !s.Is("br") {
				buf.WriteString("\n")
			}
		})
	})

	dynastyAuthor := strings.TrimSpace(doc.Find("#item_div > div.niandai_zuozhe").Text())

	return &ShiCi{
		Source:        fmt.Sprintf("/chaxun/list/%v", source),
		Title:         doc.Find("#zs_title").Text(),
		Author:        strings.Join(strings.Split(dynastyAuthor, " ")[1:], " "),
		DynastyAuthor: dynastyAuthor,
		Dynasty:       strings.TrimRight(strings.TrimLeft(strings.Split(dynastyAuthor, " ")[0], "["), "]"),
		Content:       buf.String(),
	}, nil
}
