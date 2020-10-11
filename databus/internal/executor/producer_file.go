package executor

import (
	"bufio"
	"encoding/json"
	"fmt"
	"io"
	"os"

	"github.com/pkg/errors"
)

type FileProducer struct {
	filename string
}

func NewFileProducer(filename string) *FileProducer {
	return &FileProducer{filename: filename}
}

func (p *FileProducer) Produce(vals chan<- interface{}, errs chan<- error) {
	var fp *os.File
	if p.filename == "stdin" {
		fp = os.Stdin
	} else {
		var err error
		fp, err = os.Open(p.filename)
		if err != nil {
			panic(err)
		}
	}
	defer fp.Close()
	reader := bufio.NewReader(fp)
	count := 0
	for {
		count++
		v := map[string]interface{}{}
		line, err := reader.ReadBytes('\n')
		if err != nil {
			if err != io.EOF {
				errs <- errors.Wrapf(err, "bufio.Reader.ReadBytes failed")
			}
			break
		}
		if err := json.Unmarshal(line, &v); err != nil {
			errs <- errors.Wrapf(err, "json.Unmarshal failed, line: [%v]", count)
			continue
		}
		vals <- v
	}
	fmt.Println("produce done", count)
}
