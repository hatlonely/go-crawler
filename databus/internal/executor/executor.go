package executor

import (
	"fmt"
	"sync"
)

type Executor struct {
	vals     chan interface{}
	errs     chan error
	parallel int
	producer Producer
	consumer Consumer
}

func NewExecutor(producer Producer, consumer Consumer, parallel int) *Executor {
	vals := make(chan interface{}, parallel)
	errs := make(chan error, parallel)
	return &Executor{
		vals:     vals,
		errs:     errs,
		parallel: parallel,
		producer: producer,
		consumer: consumer,
	}
}

func (e *Executor) Execute() {
	var valWg sync.WaitGroup
	var errWg sync.WaitGroup
	valWg.Add(1)
	go func() {
		e.producer.Produce(e.vals, e.errs)
		valWg.Done()
		close(e.vals)
	}()
	for i := 0; i < e.parallel; i++ {
		valWg.Add(1)
		go func() {
			e.consumer.Consume(e.vals, e.errs)
			valWg.Done()
		}()
	}

	errWg.Add(1)
	go func() {
		for err := range e.errs {
			fmt.Println(err)
		}
		errWg.Done()
	}()
	valWg.Wait()
	close(e.errs)
	errWg.Wait()
}
