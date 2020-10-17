package shicimingju

import (
	"fmt"
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func TestChaXun(t *testing.T) {
	Convey("TestChaXun", t, func() {
		a := NewShiCiAnalyst("/Users/hatlonely/hatlonely/github.com/hatlonely/go-crawler/data/www.shicimingju.com", "")

		{
			chaxun, err := a.AnalystShiCi("3710.html")
			So(err, ShouldBeNil)
			fmt.Printf("%#v", chaxun)
		}
	})
}
