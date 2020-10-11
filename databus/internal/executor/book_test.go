package executor

import (
	"testing"

	"github.com/hatlonely/go-kit/cli"
	. "github.com/smartystreets/goconvey/convey"
)

func TestCreateTable(t *testing.T) {
	Convey("TestCreateTable", t, func() {
		mysql, err := cli.NewMysql(
			cli.WithMysqlAuth("root", ""),
			cli.WithMysqlDatabase("ancient"),
		)
		So(err, ShouldBeNil)
		So(CreateTables(mysql), ShouldBeNil)
	})
}
