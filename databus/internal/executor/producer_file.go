package executor

import (
	"bufio"
	"encoding/json"
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
	fp, err := os.Open(p.filename)
	if err != nil {
		panic(err)
	}
	scanner := bufio.NewScanner(fp)
	line := 0
	for scanner.Scan() {
		line++
		v := map[string]interface{}{}
		if err := json.Unmarshal(scanner.Bytes(), &v); err != nil {
			errs <- errors.WithMessagef(err, "json.Unmarshal failed, line: [%v]", line)
			continue
		}
		vals <- scanner.Bytes()
	}
}
