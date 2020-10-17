package shicimingju

import (
	"fmt"
	"testing"

	"github.com/hatlonely/go-kit/strex"
	. "github.com/smartystreets/goconvey/convey"
)

func TestBookAnalyst(t *testing.T) {
	Convey("TestBookAnalyst", t, func() {
		a := NewBookAnalyst("/Users/hatlonely/hatlonely/github.com/hatlonely/go-crawler/data/www.shicimingju.com", "")
		bookName := "sanguoyanyi"
		{
			meta, err := a.AnalystBookMeta(bookName)
			So(err, ShouldBeNil)
			fmt.Println(strex.MustJsonMarshal(meta))
		}

		{
			section, err := a.AnalystBookSection(bookName, "2.html")
			So(err, ShouldBeNil)
			fmt.Println(strex.MustJsonMarshal(section))
			fmt.Println(section.Content)
		}

		{
			sections, err := a.AnalystBookSections(bookName)
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
