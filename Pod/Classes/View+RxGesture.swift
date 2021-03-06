// Copyright (c) RxSwiftCommunity

// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import RxSwift
import RxCocoa

extension Reactive where Base: View {

    /**
     Reactive wrapper for multiple view gesture recognizers.
     It automatically attaches the gesture recognizers to the receiver view.
     The value the `Observable` emits is the gesture recognizer itself.

     rx.anyGesture can't error and is subscribed/observed on main scheduler.
     - parameter factories: a `(GestureRecognizerFactory + state)` collection you want to use to create the `GestureRecognizers` to add and observe
     - returns: a `ControlEvent<G>` that re-emit the gesture recognizer itself
     */
    public func anyGesture(_ factories: (AnyGestureRecognizerFactory, when: GestureRecognizerState)...) -> ControlEvent<GestureRecognizer> {
        let observables = factories.map { gesture, state in
            self.gesture(gesture).when(state).asObservable() as Observable<GestureRecognizer>
        }
        let source = Observable.from(observables).merge()
        return ControlEvent(events: source)
    }

    /**
     Reactive wrapper for multiple view gesture recognizers.
     It automatically attaches the gesture recognizers to the receiver view.
     The value the `Observable` emits is the gesture recognizer itself.

     rx.anyGesture can't error and is subscribed/observed on main scheduler.
     - parameter factories: a `GestureRecognizerFactory` collection you want to use to create the `GestureRecognizers` to add and observe
     - returns: a `ControlEvent<G>` that re-emit the gesture recognizer itself
     */
    public func anyGesture(_ factories: AnyGestureRecognizerFactory...) -> ControlEvent<GestureRecognizer> {
        let observables = factories.map { gesture in
            self.gesture(gesture).asObservable() as Observable<GestureRecognizer>
        }
        let source = Observable.from(observables).merge()
        return ControlEvent(events: source)
    }

    /**
     Reactive wrapper for a single view gesture recognizer.
     It automatically attaches the gesture recognizer to the receiver view.
     The value the `Observable` emits is the gesture recognizer itself.

     rx.gesture can't error and is subscribed/observed on main scheduler.
     - parameter factory: a `GestureRecognizerFactory` you want to use to create the `GestureRecognizer` to add and observe
     - returns: a `ControlEvent<G>` that re-emit the gesture recognizer itself
     */
    public func gesture<GF: GestureRecognizerFactory, G: GestureRecognizer>(_ factory: GF) -> ControlEvent<G>
        where GF.Gesture == G {
        return self.gesture(factory.make())
    }

    /**
     Reactive wrapper for a single view gesture recognizer.
     It automatically attaches the gesture recognizer to the receiver view.
     The value the `Observable` emits is the gesture recognizer itself.

     rx.gesture can't error and is subscribed/observed on main scheduler.
     - parameter gesture: a `GestureRecognizer` you want to add and observe
     - returns: a `ControlEvent<G>` that re-emit the gesture recognizer itself
     */
    public func gesture<G: GestureRecognizer>(_ gesture: G) -> ControlEvent<G> {

        let control = self.base
        let genericGesture = gesture as GestureRecognizer

        #if os(iOS)
            control.isUserInteractionEnabled = true
        #endif

        gesture.delegate = gesture.delegate ?? PermissiveGestureRecognizerDelegate.shared

        let source: Observable<G> = Observable
            .create { [weak control] observer in
                MainScheduler.ensureExecutingOnScheduler()

                control?.addGestureRecognizer(gesture)

                let disposable = genericGesture.rx.event
                    .map { $0 as! G }
                    .bind(onNext: observer.onNext)

                return Disposables.create {
                    control?.removeGestureRecognizer(gesture)
                    disposable.dispose()
                }
            }
            .takeUntil(deallocated)

        return ControlEvent(events: source)
    }
}
