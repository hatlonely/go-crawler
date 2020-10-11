package executor

type Producer interface {
	Produce(vals chan<- interface{}, errs chan<- error)
}
