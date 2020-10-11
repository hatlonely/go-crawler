package executor

type Consumer interface {
	Consume(vals <-chan interface{})
}
