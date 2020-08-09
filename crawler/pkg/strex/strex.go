package strex

import (
	"regexp"
	"strings"
)

var spacePattern = regexp.MustCompile(`\s+`)

func FormatSpace(str string) string {
	return strings.TrimSpace(spacePattern.ReplaceAllString(str, " "))
}
