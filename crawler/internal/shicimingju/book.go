package shicimingju

import (
	"bufio"
	"bytes"
	"fmt"
	"io/ioutil"
	"os"
	"sort"
	"strconv"
	"strings"

	"github.com/PuerkitoBio/goquery"

	"github.com/hatlonely/go-rpc/crawler/pkg/strex"
)

func NewBookAnalyst(root string) *BookAnalyst {
	return &BookAnalyst{
		Root: root,
	}
}

type BookAnalyst struct {
	Root string
}

type BookMeta struct {
	Name    string
	Title   string
	Dynasty string
	Author  string
	Brief   string
}

type BookSection struct {
	Index   int
	Section string
	Content string
}

type Book struct {
	Meta     *BookMeta
	Sections []*BookSection
}

func (a *BookAnalyst) Analyst() ([]*Book, error) {
	infos, err := ioutil.ReadDir(fmt.Sprintf("%v/book/", a.Root))
	if err != nil {
		return nil, err
	}
	var books []*Book
	for _, info := range infos {
		if !info.IsDir() {
			continue
		}
		bookName := info.Name()
		meta, err := a.AnalystBookMeta(bookName)
		if err != nil {
			return nil, err
		}
		sections, err := a.AnalystBookSections(bookName)
		books = append(books, &Book{
			Meta:     meta,
			Sections: sections,
		})
	}
	return books, nil
}

func (a *BookAnalyst) AnalystBookMeta(bookName string) (*BookMeta, error) {
	fp, err := os.Open(fmt.Sprintf("%v/book/%v.html", a.Root, bookName))
	if err != nil {
		return nil, err
	}
	doc, err := goquery.NewDocumentFromReader(bufio.NewReader(fp))
	if err != nil {
		return nil, err
	}

	return &BookMeta{
		Name:    bookName,
		Title:   strings.Trim(strings.Trim(strex.FormatSpace(doc.Find("#main_left > div > h1").Text()), "《"), "》"),
		Dynasty: strex.FormatSpace(doc.Find("#main_left > div > div:nth-child(2) > p:nth-child(2)").Text()),
		Author:  strex.FormatSpace(doc.Find("#main_left > div > div:nth-child(2) > p:nth-child(3)").Text()),
		Brief:   strex.FormatSpace(doc.Find("#main_left > div > div:nth-child(2) > p.des").Text()),
	}, nil
}

func (a *BookAnalyst) AnalystBookSections(bookName string) ([]*BookSection, error) {
	infos, err := ioutil.ReadDir(fmt.Sprintf("%v/book/%v", a.Root, bookName))
	if err != nil {
		return nil, err
	}

	var sections []*BookSection
	for _, info := range infos {
		if info.IsDir() {
			continue
		}
		section, err := a.AnalystBookSection(bookName, info.Name())
		if err != nil {
			return nil, err
		}
		sections = append(sections, section)
	}

	sort.Slice(sections, func(i, j int) bool {
		return sections[i].Index < sections[j].Index
	})

	return sections, nil
}

func (a *BookAnalyst) AnalystBookSection(bookName string, section string) (*BookSection, error) {
	fp, err := os.Open(fmt.Sprintf("%v/book/%v/%v", a.Root, bookName, section))
	if err != nil {
		return nil, err
	}
	doc, err := goquery.NewDocumentFromReader(bufio.NewReader(fp))
	if err != nil {
		return nil, err
	}

	buf := bytes.Buffer{}
	doc.Find("#main_left > div.card.bookmark-list > div > p").Each(func(i int, s *goquery.Selection) {
		text := strings.TrimSpace(s.Text())
		if text == "" {
			return
		}
		buf.WriteString(text)
		buf.WriteString("\n")
	})

	idx, err := strconv.Atoi(strings.Split(section, ".")[0])
	if err != nil {
		return nil, err
	}
	return &BookSection{
		Index:   idx,
		Section: strex.FormatSpace(doc.Find("#main_left > div.card.bookmark-list > h1").Text()),
		Content: buf.String(),
	}, nil
}
