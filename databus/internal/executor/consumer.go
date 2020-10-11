package executor

import (
	"fmt"

	"github.com/hatlonely/go-kit/config"
)

type Consumer interface {
	Consume(vals <-chan interface{}, errs chan<- error)
}

func NewConsumer(cfg *config.Config) (Consumer, error) {
	switch cfg.GetString("type") {
	case "file":
		return NewFileConsumer(cfg.GetString("filename")), nil
	case "mysql":
		return NewMysqlConsumerWithConfig(cfg)
	}

	return nil, fmt.Errorf("unsupport consumer type. type: [%v]", cfg.GetString("Type"))
}
