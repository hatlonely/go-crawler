package shicimingju

import (
	"fmt"
	"testing"

	"github.com/hatlonely/go-kit/strex"
	. "github.com/smartystreets/goconvey/convey"
)

func TestBookAnalyst(t *testing.T) {
	Convey("TestBookAnalyst", t, func() {
		a := NewBookAnalyst("/Users/hatlonely/hatlonely/github.com/hatlonely/go-rpc/crawler/data/www.shicimingju.com")
		{
			meta, err := a.AnalystBookMeta("sanguoyanyi")
			So(err, ShouldBeNil)
			fmt.Println(strex.MustJsonMarshal(meta))
		}

		{
			section, err := a.AnalystBookSection("sanguoyanyi", "1.html")
			So(err, ShouldBeNil)
			fmt.Println(strex.MustJsonMarshal(section))
			fmt.Println(section.Content)
		}

		{
			sections, err := a.AnalystBookSections("sanguoyanyi")
			So(err, ShouldBeNil)
			for _, section := range sections {
				fmt.Println(section.Index)
				fmt.Println(section.Section)
				fmt.Println(section.Content)
			}
		}

		//{
		//	books, err := a.Analyst()
		//	So(err, ShouldBeNil)
		//	for _, book := range books {
		//		fmt.Println(strex.MustJsonMarshal(book))
		//	}
		//}
	})
}
