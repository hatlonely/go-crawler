package executor

import (
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
	ch := make(chan interface{}, parallel)
	return &Executor{vals: ch, parallel: parallel, producer: producer, consumer: consumer}
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
			e.consumer.Consume(e.vals)
			wg.Done()
		}()
	}
	wg.Wait()
}
