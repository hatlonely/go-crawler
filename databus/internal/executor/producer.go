package executor

import (
	"fmt"

	"github.com/hatlonely/go-kit/config"
)

type Producer interface {
	Produce(vals chan<- interface{}, errs chan<- error)
}

func NewProducer(cfg *config.Config) (Producer, error) {
	switch cfg.GetString("type") {
	case "file":
		return NewFileProducer(cfg.GetString("filename")), nil
	}
	return nil, fmt.Errorf("unsupport producer type. type: [%v]", cfg.GetString("Type"))
}
