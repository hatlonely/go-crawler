package executor

import (
	"github.com/jinzhu/gorm"
)

type ShiCi struct {
	ID      int    `gorm:"type:bigint(20);primary_key" json:"id"`
	Title   string `gorm:"type:varchar(64);index:title_idx;not null" json:"title,omitempty"`
	Author  string `gorm:"type:varchar(64);index:author_idx;not null" json:"author,omitempty"`
	Dynasty string `gorm:"type:varchar(32);index:dynasty_idx;not null" json:"dynasty,omitempty"`
	Content string `gorm:"type:longtext COLLATE utf8mb4_unicode_520_ci;not null" json:"content,omitempty"`
}

func (ShiCi) TableName() string {
	return "shici"
}

func CreateTables(mysqlCli *gorm.DB) error {
	if !mysqlCli.HasTable(&ShiCi{}) {
		if err := mysqlCli.Set("gorm:table_options", "ENGINE=InnoDB DEFAULT CHARSET=utf8").CreateTable(&ShiCi{}).Error; err != nil {
			return err
		}
	}
	return nil
}
