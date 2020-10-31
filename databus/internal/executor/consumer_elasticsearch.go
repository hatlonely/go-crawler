package executor

import (
	"context"
	"time"

	"github.com/hatlonely/go-kit/cli"
	"github.com/hatlonely/go-kit/config"
	"github.com/hatlonely/go-kit/refx"
	"github.com/olivere/elastic/v7"
	"github.com/pkg/errors"
	"github.com/spf13/cast"
)

type ElasticsearchConsumer struct {
	options *ElasticsearchConsumerOptions

	esCli *elastic.Client
}

type ElasticsearchConsumerOptions struct {
	Index   string
	IDField string
	Timeout time.Duration
	Fields  []string
	KeyMap  map[string]string
}

func NewElasticsearchConsumerWithConfig(cfg *config.Config, opts ...refx.Option) (*ElasticsearchConsumer, error) {
	esCli, err := cli.NewElasticSearchWithConfig(cfg.Sub("elasticsearch"), opts...)
	if err != nil {
		return nil, err
	}
	var options ElasticsearchConsumerOptions
	if err := cfg.Unmarshal(&options, opts...); err != nil {
		return nil, errors.WithMessage(err, "cfg.Unmarshal to ElasticsearchConsumerOptions failed")
	}
	return NewElasticsearchConsumerWithOptions(esCli, &options)
}

func NewElasticsearchConsumerWithOptions(esCli *elastic.Client, options *ElasticsearchConsumerOptions) (*ElasticsearchConsumer, error) {
	keyMap := options.KeyMap
	for _, field := range options.Fields {
		if _, ok := keyMap[field]; !ok {
			keyMap[field] = field
		}
	}

	return &ElasticsearchConsumer{
		esCli:   esCli,
		options: options,
	}, nil
}

func (c *ElasticsearchConsumer) Consume(vals <-chan interface{}, errs chan<- error) {
	for val := range vals {
		kvs := val.(map[string]interface{})
		obj := map[string]interface{}{}
		for _, k := range c.options.Fields {
			obj[k] = kvs[c.options.KeyMap[k]]
		}

		ctx, cancel := context.WithTimeout(context.Background(), c.options.Timeout)
		if _, err := c.esCli.Index().Index(c.options.Index).Id(cast.ToString(kvs[c.options.IDField])).BodyJson(obj).Do(ctx); err != nil {
			errs <- errors.WithMessagef(err, "elasticsearch.PutDocument failed")
			cancel()
			continue
		}
		cancel()
	}
}
