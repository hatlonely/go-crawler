package executor

import (
	"fmt"

	"github.com/hatlonely/go-kit/config"
	"github.com/hatlonely/go-kit/refx"
)

type Consumer interface {
	Consume(vals <-chan interface{}, errs chan<- error)
}

func NewConsumerWithConfig(cfg *config.Config, opts ...refx.Option) (Consumer, error) {
	switch cfg.GetString("type") {
	case "file":
		return NewFileConsumer(cfg.GetString("filename")), nil
	case "mysql":
		return NewMysqlConsumerWithConfig(cfg, opts...)
	case "elasticsearch":
		return NewElasticsearchConsumerWithConfig(cfg, opts...)
	}

	return nil, fmt.Errorf("unsupport consumer type. type: [%v]", cfg.GetString("Type"))
}
