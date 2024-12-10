#[test_only]
module gororo::gororo_tests;
use gororo::gororo;

const ENotImplemented: u64 = 0;

#[test]
fun test_template() {
    // pass
}

#[test, expected_failure(abort_code = ::gororo::gororo_tests::ENotImplemented)]
fun test_template_fail() {
    abort ENotImplemented
}
