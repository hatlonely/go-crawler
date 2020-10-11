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
	var wg sync.WaitGroup
	wg.Add(1)
	go func() {
		e.producer.Produce(e.vals, e.errs)
		wg.Done()
	}()
	for i := 0; i < e.parallel; i++ {
		wg.Add(1)
		go func() {
			e.consumer.Consume(e.vals, e.errs)
			wg.Done()
		}()
	}
	wg.Add(1)
	go func() {
		for err := range e.errs {
			fmt.Println(err)
		}
		wg.Done()
	}()
	wg.Wait()
}
