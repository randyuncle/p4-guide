P4BIN=/usr/local/bin
P4TEST=$(P4BIN)/p4test
P4TESTGEN=$(P4BIN)/p4testgen

%.p4i: %.p4
	mkdir -p tmp
	$(P4TEST) --dump tmp --top4 FrontEndLast,FrontEndDump,MidEndLast $<

all-good: \
	loop-var-can-be-declared-before-loop1.p4i \
	loop-var-exprs-not-constant1.p4i \
	loop-var-exprs-not-constant2.p4i \
	loop-var-modifiable-in-body1.p4i \
	loop-var-modifiable-in-body2.p4i \
	loop-var-modifiable-in-body3.p4i \
	loop-vars-multiple-in-initializer1.p4i \
	loop-var-in-list-const-list1.p4i \
	loop-var-in-list-elems-variable1.p4i \
	loop-var-in-list-elems-modified1.p4i \
	loop-var-in-list-elems-modified2.p4i \
	loop-var-in-list4.p4i \
	loop-var-in-list-elems-variable2.p4i \
	loop-var-in-list-elems-modified3.p4i \
	loop-var-in-range-const-range1.p4i \
	loop-var-in-range-var-range1.p4i \
	loop-var-in-range-var-range2.p4i \
	loop-var-in-range-bounds-modified1.p4i \
	loop-var-in-range-modifiable-in-body1.p4i \
	loop-var-in-range-modifiable-in-body2.p4i \
	loop-var-in-range-modifiable-in-body3.p4i \
	loop-var-in-range-modifiable-in-body4.p4i \
	var-shadowing-test1.p4i \
	var-shadowing-test2.p4i

ct-known: \
	const-treated-as-compile-time-known-value1.p4i

all-errors: \
	err-var-is-not-compile-time-known-value1.p4i \
	err-loop-var-not-in-scope-outside-of-loop1.p4i \
	err-loop-var-cannot-be-used-in-slice1.p4i \
	err-loop-var-in-range-no-typeref1.p4i \
	err-loop-var-in-range-no-typeref2.p4i

var-shadowing-test2-p4testgen: var-shadowing-test2.p4
	$(P4TESTGEN) --target bmv2 --arch v1model --max-tests 10 --out-dir out-p4testgen --test-backend ptf $<
