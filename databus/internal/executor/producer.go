package executor

import (
	"fmt"

	"github.com/hatlonely/go-kit/config"
	"github.com/hatlonely/go-kit/refx"
)

type Producer interface {
	Produce(vals chan<- interface{}, errs chan<- error)
}

func NewProducerWithConfig(cfg *config.Config, opts ...refx.Option) (Producer, error) {
	switch cfg.GetString("type") {
	case "file":
		return NewFileProducer(cfg.GetString("filename")), nil
	}
	return nil, fmt.Errorf("unsupport producer type. type: [%v]", cfg.GetString("Type"))
}
