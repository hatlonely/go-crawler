package executor

import (
	"bufio"
	"encoding/json"
	"fmt"
	"os"

	"github.com/pkg/errors"
)

type FileConsumer struct {
	filename string
}

func NewFileConsumer(filename string) *FileConsumer {
	return &FileConsumer{filename: filename}
}

func (c *FileConsumer) Consume(vals <-chan interface{}, errs chan<- error) {
	var fp *os.File
	if c.filename == "stdout" {
		fp = os.Stdout
	} else {
		var err error
		fp, err = os.OpenFile(c.filename, os.O_WRONLY|os.O_APPEND, 0644)
		if err != nil {
			panic(err)
		}
	}
	defer fp.Close()

	writer := bufio.NewWriter(fp)
	for val := range vals {
		kvs := val.(map[string]interface{})
		buf, _ := json.Marshal(kvs)
		if _, err := writer.Write(buf); err != nil {
			errs <- errors.Wrapf(err, "bufio.Writer.Write failed")
		}
		if err := writer.WriteByte('\n'); err != nil {
			errs <- errors.Wrapf(err, "bufio.Writer.WriteByte failed")
		}
		_ = writer.Flush()
	}
	fmt.Println("consume done")
}
