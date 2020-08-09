package shicimingju

import (
	"bufio"
	"os"

	"github.com/jinzhu/gorm"
)

type ShiCi struct {
	ID      int    `gorm:"type:bigint(20);primary_key" json:"id"`
	Title   string `gorm:"type:varchar(64);index:title_idx;not null" json:"title,omitempty"`
	Author  string `gorm:"type:varchar(64);index:author_idx;not null" json:"author,omitempty"`
	Dynasty string `gorm:"type:varchar(32);index:dynasty_idx;not null" json:"dynasty,omitempty"`
	Content string `gorm:"type:longtext COLLATE utf8mb4_unicode_520_ci;not null" json:"content,omitempty"`
}

type ShiCiStorage struct {
	mysqlCli *gorm.DB
	in       string
	ch       chan *ShiCi
	parallel int
}

func NewShiCiStorage(mysqlCli *gorm.DB, in string, parallel int) (*ShiCiStorage, error) {
	if !mysqlCli.HasTable(&ShiCi{}) {
		if err := mysqlCli.Set("gorm:table_options", "ENGINE=InnoDB DEFAULT CHARSET=utf8").CreateTable(&ShiCi{}).Error; err != nil {
			return nil, err
		}
	}
	return &ShiCiStorage{
		mysqlCli: mysqlCli,
		in:       in,
		ch:       make(chan *ShiCi, parallel),
		parallel: parallel,
	}, nil
}

func (s *ShiCiStorage) Producer() {
	fp, err := os.Open(s.in)
	if err != nil {
		panic(err)
	}
	scanner := bufio.NewScanner(fp)
	for scanner.Scan() {
		//shiCi := &ShiCi{}
	}
}
