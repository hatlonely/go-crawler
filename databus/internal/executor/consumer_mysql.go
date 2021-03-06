package executor

import (
	"bytes"
	"fmt"
	"strings"

	"github.com/hatlonely/go-kit/cli"
	"github.com/hatlonely/go-kit/config"
	"github.com/hatlonely/go-kit/refx"
	"github.com/jinzhu/gorm"
	"github.com/pkg/errors"
)

type MysqlConsumer struct {
	mysqlCli *gorm.DB
	table    string
	fields   []string
	keyMap   map[string]string

	sql string
}

type MysqlConsumerOptions struct {
	Table  string
	Fields []string
	KeyMap map[string]string
}

func NewMysqlConsumerWithConfig(cfg *config.Config, opts ...refx.Option) (*MysqlConsumer, error) {
	mysqlCli, err := cli.NewMysqlWithConfig(cfg.Sub("mysql"), opts...)
	if err != nil {
		return nil, err
	}
	var options MysqlConsumerOptions
	if err := cfg.Unmarshal(&options, opts...); err != nil {
		return nil, err
	}
	return NewMysqlConsumerWithOptions(mysqlCli, &options)
}

func NewMysqlConsumerWithOptions(mysqlCli *gorm.DB, options *MysqlConsumerOptions) (*MysqlConsumer, error) {
	keyMap := options.KeyMap
	for _, field := range options.Fields {
		if _, ok := keyMap[field]; !ok {
			keyMap[field] = field
		}
	}

	var buf1, buf2 bytes.Buffer
	for _, field := range options.Fields {
		buf1.WriteByte('`')
		buf1.WriteString(field)
		buf1.WriteByte('`')
		buf1.WriteByte(',')

		buf2.WriteString("?,")
	}

	sql := fmt.Sprintf(
		"INSERT INTO `%v` (%v) VALUES (%v)", options.Table,
		strings.TrimRight(buf1.String(), ","),
		strings.TrimRight(buf2.String(), ","),
	)
	fmt.Println(sql)

	return &MysqlConsumer{
		mysqlCli: mysqlCli,
		table:    options.Table,
		fields:   options.Fields,
		keyMap:   keyMap,
		sql:      sql,
	}, nil
}

func (c *MysqlConsumer) Consume(vals <-chan interface{}, errs chan<- error) {
	for val := range vals {
		kvs := val.(map[string]interface{})
		var vs []interface{}
		for _, field := range c.fields {
			vs = append(vs, kvs[c.keyMap[field]])
		}
		if err := c.mysqlCli.Exec(c.sql, vs...).Error; err != nil {
			errs <- errors.WithMessagef(err, "gorm.DB.Exec failed")
			continue
		}
	}
}
